[TOC]

# 解析spark.streaming.kafka.consumer.poll.ms

解析此spark.streaming.kafka.consumer.poll.ms配置参数的使用:

使用的地方:

> org.apache.spark.streaming.kafka010.KafkaRDD

```scala
  // consumer poll 的超时时间
  private val pollTimeout = conf.getLong("spark.streaming.kafka.consumer.poll.ms",
    conf.getTimeAsSeconds("spark.network.timeout", "120s") * 1000L)
```

可见此默认值是spark.network.timeout * 1000。如果spark.network.timeout没有设置，默认值为120s秒，也就是此spark.streaming.kafka.consumer.poll.ms的默认值为2000分钟。  所以还是要设置一下的。

使用此配置的地方：

> org.apache.spark.streaming.kafka010.KafkaRDD#compute

```scala
 // 开始计算
  override def compute(thePart: Partition, context: TaskContext): Iterator[ConsumerRecord[K, V]] = {
    // 转换为 KafkaRDDPartition
    val part = thePart.asInstanceOf[KafkaRDDPartition]
    require(part.fromOffset <= part.untilOffset, errBeginAfterEnd(part))
    if (part.fromOffset == part.untilOffset) {
      logInfo(s"Beginning offset ${part.fromOffset} is the same as ending offset " +
        s"skipping ${part.topic} ${part.partition}")
      Iterator.empty
    } else {
      logInfo(s"Computing topic ${part.topic}, partition ${part.partition} " +
        s"offsets ${part.fromOffset} -> ${part.untilOffset}")
      if (compacted) {
        new CompactedKafkaRDDIterator[K, V](
          part,
          context,
          kafkaParams,
          useConsumerCache,
          pollTimeout,
          cacheInitialCapacity,
          cacheMaxCapacity,
          cacheLoadFactor
        )
      } else {
        new KafkaRDDIterator[K, V](
          part,
          context,
          kafkaParams,
          useConsumerCache,
          pollTimeout,
          cacheInitialCapacity,
          cacheMaxCapacity,
          cacheLoadFactor
        )
      }
    }
  }
}
```

> org.apache.spark.streaming.kafka010.KafkaRDDIterator

```scala
// 连续 iterator的操作
private class KafkaRDDIterator[K, V](
  part: KafkaRDDPartition,
  context: TaskContext,
  kafkaParams: ju.Map[String, Object],
  useConsumerCache: Boolean,
  pollTimeout: Long,
  cacheInitialCapacity: Int,
  cacheMaxCapacity: Int,
  cacheLoadFactor: Float
) extends Iterator[ConsumerRecord[K, V]] {
  // 添加 监听器
  context.addTaskCompletionListener[Unit](_ => closeIfNeeded())
  // 创建一个新的consumer
  val consumer = {
    // 创建cache
    KafkaDataConsumer.init(cacheInitialCapacity, cacheMaxCapacity, cacheLoadFactor)
    KafkaDataConsumer.acquire[K, V](part.topicPartition(), kafkaParams, context, useConsumerCache)
  }
  // 获取开始 offset
  var requestOffset = part.fromOffset
		..... // 
}
```

> org.apache.spark.streaming.kafka010.KafkaRDDIterator#next

```scala
  // 获取下一次数据
  override def next(): ConsumerRecord[K, V] = {
    if (!hasNext) {
      throw new ju.NoSuchElementException("Can't call getNext() once untilOffset has been reached")
    }
    // 获取下一条数据
      // pollTimeout 此处使用
    val r = consumer.get(requestOffset, pollTimeout)
    // startOffset 加1
    requestOffset += 1
    // 返回拉取到的数据
    r
  }
```

继续看:

> org.apache.spark.streaming.kafka010.KafkaDataConsumer#get

```scala
    // 拉取数据
  def get(offset: Long, pollTimeoutMs: Long): ConsumerRecord[K, V] = {
    internalConsumer.get(offset, pollTimeoutMs)
  }
```

```scala
    // 拉取数据时是批量拉取,拉取完成后放入到buffer中
    // 返回给用户使用时,是从buffer中一条一条的获取
  def get(offset: Long, timeout: Long): ConsumerRecord[K, V] = {
    logDebug(s"Get $groupId $topicPartition nextOffset $nextOffset requested $offset")
      // offset 和 nextOffset不等
    if (offset != nextOffset) {
      logInfo(s"Initial fetch for $groupId $topicPartition $offset")
      // 则设置 partition的offset
      seek(offset)
      // 从此partition拉取数据
      // 并把数据放入到 buffer中
      poll(timeout)
    }
      ...... // 省略 非关键代码
  }
```

> org.apache.spark.streaming.kafka010.InternalKafkaConsumer#poll

```scala
  private def poll(timeout: Long): Unit = {
    // 真正获取数据的地方
    val p = consumer.poll(timeout)
    // 从获取到的数据中, 得到 topicPartition 对应的数据
    val r = p.records(topicPartition)
    logDebug(s"Polled ${p.partitions()}  ${r.size}")
    // 把数据添加到buffer中
    buffer = r.listIterator
  }
```

可见最终还是在 consumer.poll中使用，也就是配置了消费kafka记录的超时时间。













































