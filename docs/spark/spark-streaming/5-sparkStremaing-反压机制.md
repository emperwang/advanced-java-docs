[TOC]

# 解析反压机制-spark.streaming.backpressure.enabled

```properties
# 是否开启反压机制,即spark根据系统负载选择最优消费
# 最大速率等于: spark.streaming.kafka.maxRatePerPartition
spark.streaming.backpressure.enabled
# 
spark.streaming.kafka.consumer.poll.ms
```

使用到的地方：

> org.apache.spark.streaming.kafka010.DirectKafkaInputDStream#rateController

```scala
    // 速率控制器
  override protected[streaming] val rateController: Option[RateController] = {
      //是否开启了 反压机制
      // 即根据系统负载在决定 消费速率
    if (RateController.isBackPressureEnabled(ssc.conf)) {
      Some(new DirectKafkaRateController(id,
        RateEstimator.create(ssc.conf, context.graph.batchDuration)))
    } else {
      None
    }
  }
```

```scala
object RateController {
  def isBackPressureEnabled(conf: SparkConf): Boolean =
    conf.getBoolean("spark.streaming.backpressure.enabled", false)
}
```

如果开启了反压机制，则创建DirectKafkaRateController速率控制器.

看一下此速率控制器：

```scala
  private[streaming] class DirectKafkaRateController(id: Int, estimator: RateEstimator)
    extends RateController(id, estimator) {
    override def publish(rate: Long): Unit = ()
  }
```

在看一下其父类RateController：

```scala
private[streaming] abstract class RateController(val streamUID: Int, rateEstimator: RateEstimator)
    extends StreamingListener with Serializable {
  // 初始化
  init()

  @transient
  implicit private var executionContext: ExecutionContext = _
  // 记录速率
  @transient
  private var rateLimit: AtomicLong = _
       .... // 非关键代码
    }
```

```scala
  private def init() {
    // 设置一下后台线程池
    executionContext = ExecutionContext.fromExecutorService(
      ThreadUtils.newDaemonSingleThreadExecutor("stream-rate-update"))
    //第一次初始化速率为 -1
    rateLimit = new AtomicLong(-1L)
  }
```

同样看此此类是一个StreamingListener的子类，是一个监听器，看一下其监听器的工作：

> org.apache.spark.streaming.scheduler.RateController#onBatchCompleted

```scala
  // 每个批次完成后的  监听方法
  override def onBatchCompleted(batchCompleted: StreamingListenerBatchCompleted) {
    // 获取完成 批次的信息
    val elements = batchCompleted.batchInfo.streamIdToInputInfo
    for {
      // 完成的时间
      processingEnd <- batchCompleted.batchInfo.processingEndTime
      // 延迟的时间
      workDelay <- batchCompleted.batchInfo.processingDelay
      // 等待的延迟时间
      waitDelay <- batchCompleted.batchInfo.schedulingDelay
      // 计算的记录数
      elems <- elements.get(streamUID).map(_.numRecords)
    } computeAndPublish(processingEnd, elems, workDelay, waitDelay)
  }
```

可见每个批次完成后，会进行一次新的速率的计算。

> org.apache.spark.streaming.scheduler.RateController#computeAndPublish

```scala
  private def computeAndPublish(time: Long, elems: Long, workDelay: Long, waitDelay: Long): Unit =
    Future[Unit] {
      // 根据 处理的时间 以及 延迟时间 来计算新的速率
      val newRate = rateEstimator.compute(time, elems, workDelay, waitDelay)
      newRate.foreach { s =>
        rateLimit.set(s.toLong)
        publish(getLatestRate())
      }
    }
```

由此看此，新速率的计算委托给rateEstimator类计算，此rateEstimator有当时的构造器中创建：

```scala
Some(new DirectKafkaRateController(id,
        RateEstimator.create(ssc.conf, context.graph.batchDuration)))
```

看一下create的创建：

> org.apache.spark.streaming.scheduler.rate.RateEstimator#create

```scala
  def create(conf: SparkConf, batchInterval: Duration): RateEstimator =
    conf.get("spark.streaming.backpressure.rateEstimator", "pid") match {
      case "pid" =>
        val proportional = conf.getDouble("spark.streaming.backpressure.pid.proportional", 1.0)
        val integral = conf.getDouble("spark.streaming.backpressure.pid.integral", 0.2)
        val derived = conf.getDouble("spark.streaming.backpressure.pid.derived", 0.0)
        val minRate = conf.getDouble("spark.streaming.backpressure.pid.minRate", 100)
        // // batchInterval.milliseconds 表示每个批次的时间
        new PIDRateEstimator(batchInterval.milliseconds, proportional, integral, derived, minRate)

      case estimator =>
        throw new IllegalArgumentException(s"Unknown rate estimator: $estimator")
    }
```

然后看一下此方法是如何计算新速率的:

> org.apache.spark.streaming.scheduler.rate.PIDRateEstimator#compute

```scala
  // 是否是第一次执行
  private var firstRun: Boolean = true
  // 上此计算完时间
  private var latestTime: Long = -1L
  // 上此速率
  private var latestRate: Double = -1D
  // 上此 error数量
  private var latestError: Double = -1L


// time, elems, workDelay, waitDelay
  def compute(
      time: Long, // in milliseconds  // 处理的时间
      numElements: Long,
      processingDelay: Long, // in milliseconds  // workDelay
      schedulingDelay: Long // in milliseconds  // waitdelay
    ): Option[Double] = {
    logTrace(s"\ntime = $time, # records = $numElements, " +
      s"processing time = $processingDelay, scheduling delay = $schedulingDelay")
    this.synchronized {
      if (time > latestTime && numElements > 0 && processingDelay > 0) {

        // in seconds, should be close to batchDuration
        // 从更新 到完成的 延迟时间
        val delaySinceUpdate = (time - latestTime).toDouble / 1000

        // in elements/second
        // 每秒的元素数,即处理的速率
        val processingRate = numElements.toDouble / processingDelay * 1000

        // In our system `error` is the difference between the desired rate and the measured rate
        // based on the latest batch information. We consider the desired rate to be latest rate,
        // which is what this estimator calculated for the previous batch.
        // in elements/second
        // 表示上此处理速率 和 本次速率的差值
        val error = latestRate - processingRate

        // The error integral, based on schedulingDelay as an indicator for accumulated errors.
        // A scheduling delay s corresponds to s * processingRate overflowing elements. Those
        // are elements that couldn't be processed in previous batches, leading to this delay.
        // In the following, we assume the processingRate didn't change too much.
        // From the number of overflowing elements we can calculate the rate at which they would be
        // processed by dividing it by the batch interval. This rate is our "historical" error,
        // or integral part, since if we subtracted this rate from the previous "calculated rate",
        // there wouldn't have been any overflowing elements, and the scheduling delay would have
        // been zero.
        // (in elements/second)
        // schedulingDelay.toDouble * processingRate 因为调度延迟 而 没有被处理掉的 记录
        // schedulingDelay.toDouble * processingRate/ batchIntervalMillis 就表示一个没有被处理的 历史速率
        val historicalError = schedulingDelay.toDouble * processingRate / batchIntervalMillis

        // in elements/(second ^ 2)
        // error - latestError 本次速率差值 和 上此处理差值 的 差值
        // (error - latestError) / delaySinceUpdate  表示 delaySinceUpdate 段时间的 差值速率
        val dError = (error - latestError) / delaySinceUpdate
        // 新速率的计算方式
        // 最小为 minRate, 默认为100
        // delaySinceUpdate 默认为1   integral 默认为0.2  derivative默认为0  minRate默认为100
        // 可见主要作用是 proportional * error   微调作用为 integral * historicalError
        val newRate = (latestRate - proportional * error -
                                    integral * historicalError -
                                    derivative * dError).max(minRate)
        logTrace(s"""
            | latestRate = $latestRate, error = $error
            | latestError = $latestError, historicalError = $historicalError
            | delaySinceUpdate = $delaySinceUpdate, dError = $dError
            """.stripMargin)
        // 更新 记录
        latestTime = time
        if (firstRun) {
          latestRate = processingRate
          latestError = 0D
          firstRun = false
          logTrace("First run, rate estimation skipped")
          None
        } else {
          latestRate = newRate
          latestError = error
          logTrace(s"New rate = $newRate")
          Some(newRate)
        }
      } else {
        logTrace("Rate estimation skipped")
        None
      }
    }
  }
```

计算公式：

```scala
// 从更新 到完成的 延迟时间
val delaySinceUpdate = (time - latestTime).toDouble / 1000

// in elements/second
// 每秒的元素数,即处理的速率
val processingRate = numElements.toDouble / processingDelay * 1000
// 表示上此处理速率 和 本次速率的差值
val error = latestRate - processingRate
// schedulingDelay.toDouble * processingRate 因为调度延迟 而 没有被处理掉的 记录
// schedulingDelay.toDouble * processingRate/ batchIntervalMillis 就表示一个没有被处理的 历史速率
val historicalError = schedulingDelay.toDouble * processingRate / batchIntervalMillis
// error - latestError 本次速率差值 和 上此处理差值 的 差值
// (error - latestError) / delaySinceUpdate  表示 delaySinceUpdate 段时间的 差值速率
val dError = (error - latestError) / delaySinceUpdate
// 新速率的计算方式
// 最小为 minRate, 默认为100
// delaySinceUpdate 默认为1   integral 默认为0.2  derivative默认为0  minRate默认为100
// 可见主要作用是 proportional * error   微调作用为 integral * historicalError
val newRate = (latestRate - proportional * error -
               integral * historicalError -
               derivative * dError).max(minRate)
```

1. 当处理慢，有积压时，delaySinceUpdate变大 ， processingRate 变小  error为正数， historicalError为正 ，那newRate变小
2. 当处理快，每个批次时间很短，delaySinceUpdate变小，processingRate 变大，error为负数，newRate变大





































































