[TOC]

# reduce 任务提交

经过前面分析SparkContext就初始化完成了，接下来咱们看一下提交的任务操作。

回顾一下提交的任务主类：

```scala
object SparkPi {
  def main(args: Array[String]) {
    System.setProperty("spark.master", "local")
    val spark = SparkSession
      .builder
      .appName("Spark Pi")
      .getOrCreate()
    val slices = if (args.length > 0) args(0).toInt else 2
    val n = math.min(100000L * slices, Int.MaxValue).toInt // avoid overflow
    val count = spark.sparkContext.parallelize(1 until n, slices).map { i =>
      val x = random * 2 - 1
      val y = random * 2 - 1
      if (x*x + y*y <= 1) 1 else 0
    }.reduce(_ + _)
    println(s"Pi is roughly ${4.0 * count / (n - 1)}")
    spark.stop()
  }
}
```

spark.sparkContext.parallelize(1 until n, slices).map  这些操作只是创建了RDD，真正的提交在reduce中：

> org.apache.spark.rdd.RDD#reduce

```scala
  def reduce(f: (T, T) => T): T = withScope {
    // 对function做一些清理 ---  作用 ??
    val cleanF = sc.clean(f)
    // reduce的分区
    val reducePartition: Iterator[T] => Option[T] = iter => {
      if (iter.hasNext) {
        Some(iter.reduceLeft(cleanF))
      } else {
        None
      }
    }
    // jobResult 存储最终的结果
    var jobResult: Option[T] = None
    // 定义一个函数,最后合并结果的函数
    val mergeResult = (index: Int, taskResult: Option[T]) => {
      if (taskResult.isDefined) {
        jobResult = jobResult match {
          case Some(value) => Some(f(value, taskResult.get))
          case None => taskResult
        }
      }
    }
    // 提交任务
    sc.runJob(this, reducePartition, mergeResult)
    // Get the final result out of our Option, or throw an exception if the RDD was empty
    // 获取最终的结果
    jobResult.getOrElse(throw new UnsupportedOperationException("empty collection"))
  }
```



































