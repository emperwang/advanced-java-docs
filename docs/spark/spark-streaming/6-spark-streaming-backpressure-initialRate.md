[TOC]

# 分析配置参数spark.streaming.backpressure.initialRate

本篇主要看一下参数在源码中如何使用:

```properties
spark.streaming.backpressure.initialRate
```

主要在类DirectKakfaInputDStream中使用到该参数，定义如下：

```scala
  // 初始拉取消息数
  private val initialRate = context.sparkContext.getConf.getLong(
    "spark.streaming.backpressure.initialRate", 0)
```

由此可见默认值是0.

下面看此的使用：

> org.apache.spark.streaming.kafka010.DirectKafkaInputDStream#maxMessagesPerPartition

```scala
 // 每个分区数能获得的 最大消息数
  protected[streaming] def maxMessagesPerPartition(
    offsets: Map[TopicPartition, Long]): Option[Map[TopicPartition, Long]] = {
      // 1.根据配置的 速率控制器来获取要使用的速率控制
    val estimatedRateLimit = rateController.map { x => {
      val lr = x.getLatestRate()
      if (lr > 0) lr else initialRate
    }}

    // calculate a per-partition rate limit based on current lag
      // 此处注释写的也很清楚
      // 2.根据 当前的Lag值,类计算每一个分区的 rate limit
    val effectiveRateLimitPerPartition = estimatedRateLimit.filter(_ > 0) match {
      case Some(rate) =>
        //  first_set_____________other message______________________latest
        // 此时计算 没有消费过的消息,即lag
        val lagPerPartition = offsets.map { case (tp, offset) =>
          tp -> Math.max(offset - currentOffsets(tp), 0)
        }
        // 总共的lag,各个分区的相加
        val totalLag = lagPerPartition.values.sum

        lagPerPartition.map { case (tp, lag) =>
          // 得到每个分区最大的值
          val maxRateLimitPerPartition = ppc.maxRatePerPartition(tp)
          // 计算每个分区的速率
          val backpressureRate = lag / totalLag.toDouble * rate
          // 如果maxRateLimitPerPartition 存在,取 maxRateLimitPerPartition和backpressureRate中比较小的
          // 如果不存在,则使用backpressureRate
          tp -> (if (maxRateLimitPerPartition > 0) {
            Math.min(backpressureRate, maxRateLimitPerPartition)} else backpressureRate)
        }
        // 没有合适的速率,则使用默认的速率 val maxRate = conf.getLong("spark.streaming.kafka.maxRatePerPartition", 0)
      case None => offsets.map { case (tp, offset) => tp -> ppc.maxRatePerPartition(tp).toDouble }
    }
	// 3. 以防没有设置的情况
      // 如果 spark.streaming.kafka.maxRatePerPartition没有设置,
      // spark.streaming.backpressure.initialRate也没有设置,上面得到的速率可能就是0
      // 默认spark.streaming.kafka.minRatePerPartition 是1,也就是说如果 控制的速率 比
      // spark.streaming.kafka.minRatePerPartition 还小,则使用
      // spark.streaming.kafka.minRatePerPartition 最为最终的速率
    if (effectiveRateLimitPerPartition.values.sum > 0) {
      // 每个批次是几秒
      val secsPerBatch = context.graph.batchDuration.milliseconds.toDouble / 1000
      Some(effectiveRateLimitPerPartition.map {
            // 再次计算 每个分区的 最大速率
            // 如果这里最大速率没有最小速率大,则使用最小速率minRate
            // val minRate = conf.getLong("spark.streaming.kafka.minRatePerPartition", 1)
        case (tp, limit) => tp -> Math.max((secsPerBatch * limit).toLong,
          ppc.minRatePerPartition(tp))
      })
    } else {
      None
    }
  }
```

这里计算分区速率主要分为三个部分:

1. 根据设置的 rateController 来获取速率
2. 根据当前的 lag值 以及 配置的速率，来计算每个分区的速率
3. 最后的一个设置，以防没有进行配置的情况

分步来看，第一步从速率控制器获取配置的速率，如果没有配置或者当前的速率控制器值小于0，第一次使用速率控制器时，其值就为-1，然后则使用initialRate，即spark.streaming.backpressure.initialRate。

```scala
// 1.根据配置的 速率控制器来获取要使用的速率控制
val estimatedRateLimit = rateController.map { x => {
    val lr = x.getLatestRate()
    if (lr > 0) lr else initialRate
}}
```

速率控制器第一次：

> org.apache.spark.streaming.scheduler.RateController#getLatestRate

```scala
@transient
private var rateLimit: AtomicLong = _
def getLatestRate(): Long = rateLimit.get()

private def init() {
    executionContext = ExecutionContext.fromExecutorService(
        ThreadUtils.newDaemonSingleThreadExecutor("stream-rate-update"))
    //第一次初始化速率为 -1
    rateLimit = new AtomicLong(-1L)
}
```

可见第一次的 rateController 的速率为-1，所以第一次使用的就是initialRate，即spark.streaming.backpressure.initialRate。

第二部分:

```scala
   // calculate a per-partition rate limit based on current lag
    // 2. 根据当前的lag 使用获取到的速率 设置每一个分区的速率
    val effectiveRateLimitPerPartition = estimatedRateLimit.filter(_ > 0) match {
      case Some(rate) =>
        //  first_set_____________other message______________________latest
        // 此时计算 没有消费过的消息,即lag
        val lagPerPartition = offsets.map { case (tp, offset) =>
          tp -> Math.max(offset - currentOffsets(tp), 0)
        }
        // 总共的lag,各个分区的相加
        val totalLag = lagPerPartition.values.sum

        lagPerPartition.map { case (tp, lag) =>
          // 得到每个分区最大的值
          val maxRateLimitPerPartition = ppc.maxRatePerPartition(tp)
          // 计算每个分区的速率
          val backpressureRate = lag / totalLag.toDouble * rate
          // 如果maxRateLimitPerPartition 存在,取 maxRateLimitPerPartition和backpressureRate中比较小的
          // 如果不存在,则使用backpressureRate
          tp -> (if (maxRateLimitPerPartition > 0) {
            Math.min(backpressureRate, maxRateLimitPerPartition)} else backpressureRate)
        }
        // 没有合适的速率,则使用默认的速率 val maxRate = conf.getLong("spark.streaming.kafka.maxRatePerPartition", 0)
      case None => offsets.map { case (tp, offset) => tp -> ppc.maxRatePerPartition(tp).toDouble }
    }
```

有两个情况：

1. 在第一步中获取了有效的速率（大于0）
2. 在第一步中没有获取到速率

第一种情况就是 case Some(rate) 的执行了，其根据每个分区的lag以及设置的rate来计算到每个分区速率，并和spark.streaming.kafka.maxRatePerPartition比较，获取两个中的小的一个。

第二种情况就是case None，直接使用 spark.streaming.kafka.maxRatePerPartition的值，其默认值为0.



第三步：

```scala
  // 3. 最终设置,防止没有设置
    if (effectiveRateLimitPerPartition.values.sum > 0) {
      // 每个批次是几秒
      val secsPerBatch = context.graph.batchDuration.milliseconds.toDouble / 1000
      Some(effectiveRateLimitPerPartition.map {
            // 再次计算 每个分区的 最大速率
            // 如果这里最大速率没有最小速率大,则使用最小速率minRate
            // val minRate = conf.getLong("spark.streaming.kafka.minRatePerPartition", 1)
        case (tp, limit) => tp -> Math.max((secsPerBatch * limit).toLong,
          ppc.minRatePerPartition(tp))
      })
    } else {
      None
    }
```

最终一次计算，取第二步获取到的值和spark.streaming.kafka.minRatePerPartition两个中比较大的。



































































































