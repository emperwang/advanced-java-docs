[TOC]

# KafkaRDD的解析

上篇解析了DirectKafkaInputDStream，其中说到其在计算时，创建了KafkaRDD，这里就来分析一下此RDD的操作。

看一下其继承关系:

```scala
private[spark] class KafkaRDD[K, V](
    sc: SparkContext,
    val kafkaParams: ju.Map[String, Object],
    val offsetRanges: Array[OffsetRange],
    val preferredHosts: ju.Map[TopicPartition, String],
    useConsumerCache: Boolean
) extends RDD[ConsumerRecord[K, V]](sc, Nil) with Logging with HasOffsetRanges
```

直接继承RDD，并实现了HasOffsetRanges。

在看一下其初始化:

```scala
private[spark] class KafkaRDD[K, V](
    sc: SparkContext,
    val kafkaParams: ju.Map[String, Object],
    val offsetRanges: Array[OffsetRange],
    val preferredHosts: ju.Map[TopicPartition, String],
    useConsumerCache: Boolean
) extends RDD[ConsumerRecord[K, V]](sc, Nil) with Logging with HasOffsetRanges {
  // auto.offset.reset 是否自动reset
  require("none" ==
    kafkaParams.get(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG).asInstanceOf[String],
    ConsumerConfig.AUTO_OFFSET_RESET_CONFIG +
      " must be set to none for executor kafka params, else messages may not match offsetRange")
  // 是否自动提交额配置 enable.auto.commit
  require(false ==
    kafkaParams.get(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG).asInstanceOf[Boolean],
    ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG +
      " must be set to false for executor kafka params, else offsets may commit before processing")

  // TODO is it necessary to have separate configs for initial poll time vs ongoing poll time?
  // consumer poll 的超时时间
  private val pollTimeout = conf.getLong("spark.streaming.kafka.consumer.poll.ms",
    conf.getTimeAsSeconds("spark.network.timeout", "120s") * 1000L)
  // 缓存的初始大小
  private val cacheInitialCapacity =
    conf.getInt("spark.streaming.kafka.consumer.cache.initialCapacity", 16)
  // 缓存的最大 容量
  private val cacheMaxCapacity =
    conf.getInt("spark.streaming.kafka.consumer.cache.maxCapacity", 64)
  // 缓存的 factor
  private val cacheLoadFactor =
    conf.getDouble("spark.streaming.kafka.consumer.cache.loadFactor", 0.75).toFloat
  // 是否允许不连续的 offset
  private val compacted =
    conf.getBoolean("spark.streaming.kafka.allowNonConsecutiveOffsets", false)
}
```

前面都是铺垫，下面看一下其重要的几个操作： 分区数获取以及计算。

分区数计算：

> org.apache.spark.streaming.kafka010.KafkaRDD#getPartitions

```scala
  // 计算此RDD对应的分区
  override def getPartitions: Array[Partition] = {
      // zipWithIndex算子的操作
      // o为offsetRanges中额记录, i为index
      // 也就是为每一个分区设置了 一个 KafkaRDDPartition;简单说就是有多少个分区,就设置了多少个task
    offsetRanges.zipWithIndex.map { case (o, i) =>
        new KafkaRDDPartition(i, o.topic, o.partition, o.fromOffset, o.untilOffset)
    }.toArray
  }
```

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

这里主要是创建了Iterator，根据不同的情况，创建了三种：

1. startOffset == endOffset时，创建了空的Iterator
2. 允许不连续的offset时，创建了CompactedKafkaRDDIterator
3. 连续的offset时，创建了KafkaRDDIterator

真正计算时，就是从iterator中每次获取一条记录来进行计算。

看一下KafkaRDDIterator:

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

  def closeIfNeeded(): Unit = {
    if (consumer != null) {
      consumer.release()
    }
  }
  // 是否换有下一个,也就是开始的offset 小于 endoffset
  override def hasNext(): Boolean = requestOffset < part.untilOffset
  // 获取下一次数据
  override def next(): ConsumerRecord[K, V] = {
    if (!hasNext) {
      throw new ju.NoSuchElementException("Can't call getNext() once untilOffset has been reached")
    }
    // 获取下一条数据
    val r = consumer.get(requestOffset, pollTimeout)
    // startOffset 加1
    requestOffset += 1
    // 返回拉取到的数据
    r
  }
}
```

这里有几个操作：

1. 创建consumer
2. hasNext  当startOffset < endOffset 时，表名还有数据
3. next 就是使用consumer 来获取数据

先看一下consumer的创建：

```scala
// 创建一个新的consumer
  val consumer = {
    // 创建cache
    KafkaDataConsumer.init(cacheInitialCapacity, cacheMaxCapacity, cacheLoadFactor)
    KafkaDataConsumer.acquire[K, V](part.topicPartition(), kafkaParams, context, useConsumerCache)
  }
```

> org.apache.spark.streaming.kafka010.KafkaDataConsumer$#init

```scala
  def init(
      initialCapacity: Int,
      maxCapacity: Int,
      loadFactor: Float): Unit = synchronized {
    if (null == cache) {
      logInfo(s"Initializing cache $initialCapacity $maxCapacity $loadFactor")
      // 为缓存创建 容器
      cache = new ju.LinkedHashMap[CacheKey, InternalKafkaConsumer[_, _]](
        initialCapacity, loadFactor, true) {
          // 重载了 remove操作
          // 可见,当remove时,就进行关闭
        override def removeEldestEntry(
            entry: ju.Map.Entry[CacheKey, InternalKafkaConsumer[_, _]]): Boolean = {
          // Try to remove the least-used entry if its currently not in use.
          // If you cannot remove it, then the cache will keep growing. In the worst case,
          // the cache will grow to the max number of concurrent tasks that can run in the executor,
          // (that is, number of tasks slots) after which it will never reduce. This is unlikely to
          // be a serious problem because an executor with more than 64 (default) tasks slots is
          // likely running on a beefy machine that can handle a large number of simultaneously
          // active consumers.
          if (entry.getValue.inUse == false && this.size > maxCapacity) {
            logWarning(
                s"KafkaConsumer cache hitting max capacity of $maxCapacity, " +
                s"removing consumer for ${entry.getKey}")
               try {
              entry.getValue.close()
            } catch {
              case x: KafkaException =>
                logError("Error closing oldest Kafka consumer", x)
            }
            true
          } else {
            false
          }
        }
      }
    }
  }
```

> org.apache.spark.streaming.kafka010.KafkaDataConsumer$#acquire

```scala
  def acquire[K, V](
      topicPartition: TopicPartition,
      kafkaParams: ju.Map[String, Object],
      context: TaskContext,
      useCache: Boolean): KafkaDataConsumer[K, V] = synchronized {
    // 获取groupId
    val groupId = kafkaParams.get(ConsumerConfig.GROUP_ID_CONFIG).asInstanceOf[String]
    // 使用 groupId 和 topicPartition 最为缓存的key
    val key = new CacheKey(groupId, topicPartition)
    // 是否已经缓存了
    val existingInternalConsumer = cache.get(key)
    // lazy 懒加载
    // 创建了一个 executor端使用的 InternalKafkaConsumer
    lazy val newInternalConsumer = new InternalKafkaConsumer[K, V](topicPartition, kafkaParams)

    if (context != null && context.attemptNumber >= 1) {
      // If this is reattempt at running the task, then invalidate cached consumers if any and
      // start with a new one. If prior attempt failures were cache related then this way old
      // problematic consumers can be removed.
      logDebug(s"Reattempt detected, invalidating cached consumer $existingInternalConsumer")
      if (existingInternalConsumer != null) {
        // Consumer exists in cache. If its in use, mark it for closing later, or close it now.
        // 已经存在缓存,且正在使用
        if (existingInternalConsumer.inUse) {
          // 则标记为 markedForClose 为true
          existingInternalConsumer.markedForClose = true
        } else {
          // 如果缓存的不是正在使用了
          // 则关闭
          existingInternalConsumer.close()
          // Remove the consumer from cache only if it's closed.
          // Marked for close consumers will be removed in release function.
          // 并从缓存中删除
          cache.remove(key)
        }
      }
     // 创建非缓存的consumer
      logDebug("Reattempt detected, new non-cached consumer will be allocated " +
        s"$newInternalConsumer")
      NonCachedKafkaDataConsumer(newInternalConsumer)
      // 如果不适用cache,则创建不是cache的consumer
    } else if (!useCache) {
      // If consumer reuse turned off, then do not use it, return a new consumer
      logDebug("Cache usage turned off, new non-cached consumer will be allocated " +
        s"$newInternalConsumer")
      NonCachedKafkaDataConsumer(newInternalConsumer)
    } else if (existingInternalConsumer == null) {
      // If consumer is not already cached, then put a new in the cache and return it
      logDebug("No cached consumer, new cached consumer will be allocated " +
        s"$newInternalConsumer")
      cache.put(key, newInternalConsumer)
      CachedKafkaDataConsumer(newInternalConsumer)
    } else if (existingInternalConsumer.inUse) {
      // If consumer is already cached but is currently in use, then return a new consumer
      logDebug("Used cached consumer found, new non-cached consumer will be allocated " +
        s"$newInternalConsumer")
      NonCachedKafkaDataConsumer(newInternalConsumer)
    } else {
      // If consumer is already cached and is currently not in use, then return that consumer
      logDebug(s"Not used cached consumer found, re-using it $existingInternalConsumer")
      existingInternalConsumer.inUse = true
      // Any given TopicPartition should have a consistent key and value type
      CachedKafkaDataConsumer(existingInternalConsumer.asInstanceOf[InternalKafkaConsumer[K, V]])
    }
  }
```

可见真正使用的InternalKafkaConsumer来进行数据的消费.

看一下此类的初始化:

```scala
private[kafka010] class InternalKafkaConsumer[K, V](
    val topicPartition: TopicPartition,
    val kafkaParams: ju.Map[String, Object]) extends Logging {

    private[kafka010] val groupId = kafkaParams.get(ConsumerConfig.GROUP_ID_CONFIG)
    .asInstanceOf[String]
    // 创建 consumer
    private val consumer = createConsumer
    // 是否正在使用
    var inUse = true
    // 标记要 close
    var markedForClose = false
    // buffer中用于存储
    @volatile private var buffer = ju.Collections.emptyListIterator[ConsumerRecord[K, V]]()
    // 下一个要拉取的 消息的offset
    @volatile private var nextOffset = InternalKafkaConsumer.UNKNOWN_OFFSET
}


// 创建 consumer
private def createConsumer: KafkaConsumer[K, V] = {
    val c = new KafkaConsumer[K, V](kafkaParams)
    val topics = ju.Arrays.asList(topicPartition)
    c.assign(topics)
    c
}
```

下面看一下具体获取数据的操作:

```scala
  // 获取下一次数据
  override def next(): ConsumerRecord[K, V] = {
    if (!hasNext) {
      throw new ju.NoSuchElementException("Can't call getNext() once untilOffset has been reached")
    }
    // 获取下一条数据
    val r = consumer.get(requestOffset, pollTimeout)
    // startOffset 加1
    requestOffset += 1
    // 返回拉取到的数据
    r
  }
```

> org.apache.spark.streaming.kafka010.KafkaDataConsumer#get

```scala
    // 拉取数据
  def get(offset: Long, pollTimeoutMs: Long): ConsumerRecord[K, V] = {
    internalConsumer.get(offset, pollTimeoutMs)
  }
```

> org.apache.spark.streaming.kafka010.InternalKafkaConsumer#get

```scala
    // 拉取数据
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
      poll(timeout)
    }
    // 如果buffer中没有数据,则再拉取一次
    if (!buffer.hasNext()) {
      poll(timeout)
    }
    require(buffer.hasNext(),
      s"Failed to get records for $groupId $topicPartition $offset after polling for $timeout")
      // 获取到拉取的数据
    var record = buffer.next()
    // 如果获取到的数据的offset 和 指定的offset 不相等,则重新进行数据的拉取
    if (record.offset != offset) {
      logInfo(s"Buffer miss for $groupId $topicPartition $offset")
      // 重置offset
      seek(offset)
      // 数据拉取
      poll(timeout)
      require(buffer.hasNext(),
        s"Failed to get records for $groupId $topicPartition $offset after polling for $timeout")
      record = buffer.next()
      // 在进行对比
      require(record.offset == offset,
        s"Got wrong record for $groupId $topicPartition even after seeking to offset $offset " +
          s"got offset ${record.offset} instead. If this is a compacted topic, consider enabling " +
          "spark.streaming.kafka.allowNonConsecutiveOffsets"
      )
    }
    // 把下次要拉取的数据 offset 增加
    nextOffset = offset + 1
      // 返回拉取的数据
    record
  }
```

```scala
  private def seek(offset: Long): Unit = {
    logDebug(s"Seeking to $topicPartition $offset")
    // 设置 partiotion 的offset
    consumer.seek(topicPartition, offset)
  }

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

有上面来去数据获取可知，获取数据时是批量的获取 val p = consumer.poll(timeout)， 获取完成后在过滤得到自己当前分区的数据 val r = p.records(topicPartition)， 之后把此次批量的数据放入到buffer中：buffer = r.listIterator。而给用户数据时：

```scala
// 如果buffer中没有数据,则再拉取一次
if (!buffer.hasNext()) {
    poll(timeout)
}
var record = buffer.next()
record
```

是从buffer中一条一条的获取数据。此KafkaRDD的iterator操作就很清晰了，其使用是使用buffer来做了一个中间的缓冲。

KafkaRDD的操作就解析到这里。顺便看一下executor对kafkaConsumer的缓存和非缓存的实现。

缓存：

 ```scala
  // 缓存的kafka 会有多个consumer实例可以使用
  private case class CachedKafkaDataConsumer[K, V](internalConsumer: InternalKafkaConsumer[K, V])
    extends KafkaDataConsumer[K, V] {
    assert(internalConsumer.inUse)
    override def release(): Unit = KafkaDataConsumer.release(internalConsumer)
  }
 ```

其释放的操作:

```scala
// 缓存consumer情况下的 释放
private def release(internalConsumer: InternalKafkaConsumer[_, _]): Unit = synchronized {
    // Clear the consumer from the cache if this is indeed the consumer present in the cache
    // 创建cache的key
    val key = new CacheKey(internalConsumer.groupId, internalConsumer.topicPartition)
    // 获取缓存的 consumer
    val cachedInternalConsumer = cache.get(key)
    if (internalConsumer.eq(cachedInternalConsumer)) {
        // The released consumer is the same object as the cached one.
        // 如果标记了要 close,则进行关闭,并从缓存中移除
        if (internalConsumer.markedForClose) {
            internalConsumer.close()
            cache.remove(key)
        } else {
            // 否则只是标记 没有在使用
            internalConsumer.inUse = false
        }
    } else {
        // The released consumer is either not the same one as in the cache, or not in the cache
        // at all. This may happen if the cache was invalidate while this consumer was being used.
        // Just close this consumer.
        internalConsumer.close()
        logInfo(s"Released a supposedly cached consumer that was not found in the cache " +
                s"$internalConsumer")
    }
}
}
```

可见缓存的释放，最后是修改标志位，并放回到缓存中，下次可以直接使用。

非缓存：

```scala
  // 不缓存的情况下,每次使用后都关闭
  private case class NonCachedKafkaDataConsumer[K, V](internalConsumer: InternalKafkaConsumer[K, V])
    extends KafkaDataConsumer[K, V] {
    override def release(): Unit = internalConsumer.close()
  }
```

```scala
 def close(): Unit = consumer.close()
```

可见，非缓存就是使用完之后，直接关闭。









































































