[TOC]

# producer发送(2)

上篇分析到数据追击Accumulator的操作，操作大体如下：

```java
// 追加消息到 accumlator中
public RecordAppendResult append(TopicPartition tp,
                                 long timestamp,
                                 byte[] key,
                                 byte[] value,
                                 Header[] headers,
                                 Callback callback,
                                 long maxTimeToBlock) throws InterruptedException {
    // We keep track of the number of appending thread to make sure we do not miss batches in
    // abortIncompleteBatches().
    // 等待处理的个数
    appendsInProgress.incrementAndGet();
    ByteBuffer buffer = null;
    if (headers == null) headers = Record.EMPTY_HEADERS;
    try {
        // check if we have an in-progress batch
        // 1. 获取 tp 对应的队列,此队列用于存储要发送的数据
        Deque<ProducerBatch> dq = getOrCreateDeque(tp);
        synchronized (dq) {
            // 如果关闭了,则抛出异常
            if (closed)
                throw new KafkaException("Producer closed while send in progress");
            // 2.尝试追加数据到 dq 队列中
            // 第一次一般是队列为null,故而第一次应该是在下面执行的
           RecordAppendResult appendResult = tryAppend(timestamp, key, value, headers, callback, dq);
            // 返回追加的结果
            if (appendResult != null)
                return appendResult;
        }

        // we don't have an in-progress record batch try to allocate a new batch
        byte maxUsableMagic = apiVersions.maxUsableProduceMagic();
        int size = Math.max(this.batchSize, AbstractRecords.estimateSizeInBytesUpperBound(maxUsableMagic, compression, key, value, headers));
        log.trace("Allocating a new {} byte message buffer for topic {} partition {}", size, tp.topic(), tp.partition());
        // 3. 内存分配
        // --- 重点 ---
        buffer = free.allocate(size, maxTimeToBlock);
        synchronized (dq) {
            // Need to check if producer is closed again after grabbing the dequeue lock.
            if (closed)
                throw new KafkaException("Producer closed while send in progress");
            // 再次尝试添加,添加成功后,就直接返回了
           RecordAppendResult appendResult = tryAppend(timestamp, key, value, headers, callback, dq);
            if (appendResult != null) {
                return appendResult;
            }
            // 4. 内存记录建造起   memoryRecordBuilder
            // 最终是使用此 builder 来把record 写入到  producerBatch 中的
            MemoryRecordsBuilder recordsBuilder = recordsBuilder(buffer, maxUsableMagic);
            // 5. 创建一个 ProducerBatch
            // 此producerBatch 主要就是用来存储一批的 record
            ProducerBatch batch = new ProducerBatch(tp, recordsBuilder, time.milliseconds());
            // 6.添加记录到  此创建的 producerBatch 中
            FutureRecordMetadata future = Utils.notNull(batch.tryAppend(timestamp, key, value, headers, callback, time.milliseconds()));
            // 7.记录此 producerBatch
            dq.addLast(batch);
            // 记录此batch到 未完成 容器中
            incomplete.add(batch);
            buffer = null;
            return new RecordAppendResult(future, dq.size() > 1 || batch.isFull(), true);
        }
    } finally {
        if (buffer != null)
            free.deallocate(buffer);
        appendsInProgress.decrementAndGet();
    }
}
```

1. 先尝试获取topicPartition对应的队列，此队列主要是存储要发送到此topic分区的数据
2. 尝试添加数据到此队列中，不过第一次一般队列为null
3. 分配内存，此内存是真实存储数据的，类型为byteBuffer
4.  创建MemoryRecordsBuilder， 此主要是实现了把数据记录到buffer的功能
5. 创建producerBathc
6. 添加数据到此 刚创建的 produceBatch
7. 记录此刚创建的 produceBatch

这里主要看一下3456步骤的操作.

## 分配内存

```java
// 分配内存
public ByteBuffer allocate(int size, long maxTimeToBlockMs) throws InterruptedException {
    if (size > this.totalMemory)
        throw new IllegalArgumentException("Attempt to allocate " + size
                                           + " bytes, but there is a hard limit of "
                                           + this.totalMemory
                                           + " on memory allocations.");

    ByteBuffer buffer = null;
    this.lock.lock();
    try {
        // check if we have a free buffer of the right size pooled
        if (size == poolableSize && !this.free.isEmpty())
            return this.free.pollFirst();

        // now check if the request is immediately satisfiable with the
        // memory on hand or if we need to block
        // 1. 剩余的 可用的 memory 大小
        int freeListSize = freeSize() * this.poolableSize;
        // 2. 如果总的内存 可以满足此次请求
        if (this.nonPooledAvailableMemory + freeListSize >= size) {
            // we have enough unallocated or pooled memory to immediately
            // satisfy the request, but need to allocate the buffer
            // 释放一些已经分配的内容,用于满足此次请求
            freeUp(size);
            this.nonPooledAvailableMemory -= size;
        } else {
            // 3. 内存不够, 阻塞
            // we are out of memory and will have to block
            int accumulated = 0;
            Condition moreMemory = this.lock.newCondition();
            try {
                // 剩余阻塞的时间
                long remainingTimeToBlockNs = TimeUnit.MILLISECONDS.toNanos(maxTimeToBlockMs);
                // 记录下 此 condition
                this.waiters.addLast(moreMemory);
                // loop over and over until we have a buffer or have reserved
                // enough memory to allocate one
                while (accumulated < size) {
                    // 开始时间
                    long startWaitNs = time.nanoseconds();
                    long timeNs;
                    boolean waitingTimeElapsed;
                    try {
                        // 3.1 开始超时等待 被唤醒
                        waitingTimeElapsed = !moreMemory.await(remainingTimeToBlockNs, TimeUnit.NANOSECONDS);
                    } finally {
                        // 被唤醒后  记录结束时间
                        long endWaitNs = time.nanoseconds();
                        timeNs = Math.max(0L, endWaitNs - startWaitNs);
                        recordWaitTime(timeNs);
                    }

                    if (waitingTimeElapsed) {
                        throw new TimeoutException("Failed to allocate memory within the configured max blocking time " + maxTimeToBlockMs + " ms.");
                    }

                    remainingTimeToBlockNs -= timeNs;

                    // check if we can satisfy this request from the free list,
                    // otherwise allocate memory
                    // 3.2 唤醒后 再次尝试查看 内存是否可以满足 此次的请求
                    if (accumulated == 0 && size == this.poolableSize && !this.free.isEmpty()) {
                        // just grab a buffer from the free list
                        buffer = this.free.pollFirst();
                        accumulated = size;
                    } else {
                        // we'll need to allocate memory, but we may only get
                        // part of what we need on this iteration
                        // 释放部分已分配的内存
                        freeUp(size - accumulated);
                        int got = (int) Math.min(size - accumulated, this.nonPooledAvailableMemory);
                        this.nonPooledAvailableMemory -= got;
                        // 累加可用的内存
                        accumulated += got;
                    }
                }
                // Don't reclaim memory on throwable since nothing was thrown
                accumulated = 0;
            } finally {
                // When this loop was not able to successfully terminate don't loose available memory
                this.nonPooledAvailableMemory += accumulated;
                this.waiters.remove(moreMemory);
            }
        }
    } finally {
        // signal any additional waiters if there is more memory left
        // over for them
        try {
            // 4. 尝试队列中等待内存分配的线程
            if (!(this.nonPooledAvailableMemory == 0 && this.free.isEmpty()) && !this.waiters.isEmpty())
                this.waiters.peekFirst().signal();
        } finally {
            // Another finally... otherwise find bugs complains
            lock.unlock();
        }
    }
    // 5.分配内存
    if (buffer == null)
        return safeAllocateByteBuffer(size);
    else
        return buffer;
}
```

这里大体步骤：

1. 查看free内存和可用的未分配内存(nonPooledAvailableMemory)能够满足此次需求，则释放一些已分配内存，然后再分配内存用于此次请求
2. 如果内存不够呢，则阻塞，当有人释放内存时，被唤醒
   1. 唤醒后，再次判断当前内存是否可满足此次需求，不满足释放一些已分配内存，如果还不能满足需求，扔阻塞
   2. 唤醒后，满足当前的内存需求，则尝试分配内存

这里看一下内存释放的操作和内存分配的操作。

内存释放：

> org.apache.kafka.clients.producer.internals.BufferPool#freeUp

```java
// 释放一些已经分配的内存, 直到可以满足此次请求
private void freeUp(int size) {
    while (!this.free.isEmpty() && this.nonPooledAvailableMemory < size)
        this.nonPooledAvailableMemory += this.free.pollLast().capacity();
}
```

看到这里的内存释放，其实就是消费 free中的buffer，可见最终的释放依赖于GC。

内存分配：

> org.apache.kafka.clients.producer.internals.BufferPool#safeAllocateByteBuffer

```java
// 分配内存
private ByteBuffer safeAllocateByteBuffer(int size) {
    boolean error = true;
    try {
        // 分配内存
        ByteBuffer buffer = allocateByteBuffer(size);
        error = false;
        return buffer;
    } finally {
        if (error) {
            this.lock.lock();
            try {
                // 如果分配失败呢, 回收刚才分配的内存大小
                this.nonPooledAvailableMemory += size;
                if (!this.waiters.isEmpty())
                    this.waiters.peekFirst().signal();
            } finally {
                this.lock.unlock();
            }
        }
    }
}
```



## 创建MemoryRecordsBuilder

> org.apache.kafka.clients.producer.internals.RecordAccumulator#recordsBuilder

```java
}
// 创建 MemoryRecordBuilder 此用于把记录写到 buffer中
private MemoryRecordsBuilder recordsBuilder(ByteBuffer buffer, byte maxUsableMagic) {
    if (transactionManager != null && maxUsableMagic < RecordBatch.MAGIC_VALUE_V2) {
        throw new UnsupportedVersionException("Attempting to use idempotence with a broker which does not " +"support the required message format (v2). The broker must be version 0.11 or later.");
    }
    // 创建
    return MemoryRecords.builder(buffer, maxUsableMagic, compression, TimestampType.CREATE_TIME, 0L);
}

```

> org.apache.kafka.common.record.MemoryRecords#builder

```java
public static MemoryRecordsBuilder builder(ByteBuffer buffer,
                                           byte magic,
                                           CompressionType compressionType,
                                           TimestampType timestampType,
                                           long baseOffset) {
    // 追加时间
    long logAppendTime = RecordBatch.NO_TIMESTAMP;
    // 如果是 LOG_APPEND_TIME
    if (timestampType == TimestampType.LOG_APPEND_TIME)
        logAppendTime = System.currentTimeMillis();
    // 创建
    return builder(buffer, magic, compressionType, timestampType, baseOffset, logAppendTime,
                   RecordBatch.NO_PRODUCER_ID, RecordBatch.NO_PRODUCER_EPOCH, RecordBatch.NO_SEQUENCE, false,RecordBatch.NO_PARTITION_LEADER_EPOCH);
}
```

```java
    public static MemoryRecordsBuilder builder(ByteBuffer buffer,
                                               byte magic,
                                               CompressionType compressionType,
                                               TimestampType timestampType,
                                               long baseOffset,
                                               long logAppendTime,
                                               long producerId,
                                               short producerEpoch,
                                               int baseSequence,
                                               boolean isTransactional,
                                               int partitionLeaderEpoch) {
        return builder(buffer, magic, compressionType, timestampType, baseOffset,
                logAppendTime, producerId, producerEpoch, baseSequence, isTransactional, false, partitionLeaderEpoch);
    }
```

```java
public static MemoryRecordsBuilder builder(ByteBuffer buffer,
                                           byte magic,
                                           CompressionType compressionType,
                                           TimestampType timestampType,
                                           long baseOffset,
                                           long logAppendTime,
                                           long producerId,
                                           short producerEpoch,
                                           int baseSequence,
                                           boolean isTransactional,
                                           boolean isControlBatch,
                                           int partitionLeaderEpoch) {
    // 创建 MemoryRecordsBuilder
    return new MemoryRecordsBuilder(buffer, magic, compressionType, timestampType, baseOffset,
                                    logAppendTime, producerId, producerEpoch, baseSequence, isTransactional, isControlBatch, partitionLeaderEpoch,
                                    buffer.remaining());
}
```

```java
        public MemoryRecordsBuilder(ByteBuffer buffer,
                                    byte magic,
                                    CompressionType compressionType,
                                    TimestampType timestampType,
                                    long baseOffset,
                                    long logAppendTime,
                                    long producerId,
                                    short producerEpoch,
                                    int baseSequence,
                                    boolean isTransactional,
                                    boolean isControlBatch,
                                    int partitionLeaderEpoch,
                                    int writeLimit) {
            // ByteBufferOutputStream(buffer) 输出流, 输出的目的为 buffer
            this(new ByteBufferOutputStream(buffer), magic, compressionType, timestampType, baseOffset, logAppendTime,producerId, producerEpoch, baseSequence, isTransactional, isControlBatch, partitionLeaderEpoch, writeLimit);
        }
```

```java
public MemoryRecordsBuilder(ByteBufferOutputStream bufferStream,
                            byte magic,
                            CompressionType compressionType,
                            TimestampType timestampType,
                            long baseOffset,
                            long logAppendTime,
                            long producerId,
                            short producerEpoch,
                            int baseSequence,
                            boolean isTransactional,
                            boolean isControlBatch,
                            int partitionLeaderEpoch,
                            int writeLimit) {
    if (magic > RecordBatch.MAGIC_VALUE_V0 && timestampType == TimestampType.NO_TIMESTAMP_TYPE)
        throw new IllegalArgumentException("TimestampType must be set for magic >= 0");
    if (magic < RecordBatch.MAGIC_VALUE_V2) {
        if (isTransactional)
  throw new IllegalArgumentException("Transactional records are not supported for magic " + magic);
        if (isControlBatch)
 throw new IllegalArgumentException("Control records are not supported for magic " + magic);
        if (compressionType == CompressionType.ZSTD)
 throw new IllegalArgumentException("ZStandard compression is not supported for magic " + magic);
    }

    this.magic = magic;
    // 时间戳类型
    this.timestampType = timestampType;
    // 压缩类型
    this.compressionType = compressionType;
    // base 偏移
    this.baseOffset = baseOffset;
    this.logAppendTime = logAppendTime;
    // 记录个数
    this.numRecords = 0;
    this.uncompressedRecordsSizeInBytes = 0;
    // 真实压缩比例
    this.actualCompressionRatio = 1;
    //
    this.maxTimestamp = RecordBatch.NO_TIMESTAMP;
    // producerId
    this.producerId = producerId;
    // producer epoch
    this.producerEpoch = producerEpoch;
    this.baseSequence = baseSequence;
    this.isTransactional = isTransactional;
    this.isControlBatch = isControlBatch;
    this.partitionLeaderEpoch = partitionLeaderEpoch;
    // 最大能写的 字节数
    this.writeLimit = writeLimit;
    // 开始位置
    this.initialPosition = bufferStream.position();
    // batchHeader 的size
    this.batchHeaderSizeInBytes = AbstractRecords.recordBatchHeaderSizeInBytes(magic, compressionType);
    // 设置 buffer的 开始位置
    bufferStream.position(initialPosition + batchHeaderSizeInBytes);
    this.bufferStream = bufferStream;
    // 输出流, 即把数据输出到 buffer中
    this.appendStream = new DataOutputStream(compressionType.wrapForOutput(this.bufferStream, magic));
}
```

这里看到输出流的目的位置为buffer，其中buffer就是上面内存分配的缓存。



## 创建producerBathc

```java
// 构建producerBatch
public ProducerBatch(TopicPartition tp, MemoryRecordsBuilder recordsBuilder, long createdMs) {
    this(tp, recordsBuilder, createdMs, false);
}

public ProducerBatch(TopicPartition tp, MemoryRecordsBuilder recordsBuilder, long createdMs, boolean isSplitBatch) {
    // 创建时间
    this.createdMs = createdMs;
    // 上次 attempt 时间
    this.lastAttemptMs = createdMs;
    // 写 record的 实现
    this.recordsBuilder = recordsBuilder;
    // topic partition
    this.topicPartition = tp;
    // 上次追加时间
    this.lastAppendTime = createdMs;
    this.produceFuture = new ProduceRequestResult(topicPartition);
    this.retry = false;
    // 是否分 batch
    this.isSplitBatch = isSplitBatch;
    float compressionRatioEstimation = CompressionRatioEstimator.estimation(topicPartition.topic(),
                                                                            recordsBuilder.compressionType());
    recordsBuilder.setEstimatedCompressionRatio(compressionRatioEstimation);
}
```



## 添加数据到此 刚创建的 produceBatch

添加记录到此 batch中，具体其中MemoryRecordsBuilder的操作，后面单独分析，这里就了解其作用就可以。

> org.apache.kafka.clients.producer.internals.ProducerBatch#tryAppend

```java
public FutureRecordMetadata tryAppend(long timestamp, byte[] key, byte[] value, Header[] headers, Callback callback, long now) {
    // 此 producerBatch 是否还有空间 记录此 record
    if (!recordsBuilder.hasRoomFor(timestamp, key, value, headers)) {
        return null;
    } else {
        // 追加 记录到 buffer 中
        // -- 重难 点------
        Long checksum = this.recordsBuilder.append(timestamp, key, value, headers);
        this.maxRecordSize = Math.max(this.maxRecordSize, AbstractRecords.estimateSizeInBytesUpperBound(magic(),recordsBuilder.compressionType(), key, value, headers));
        this.lastAppendTime = now;
        FutureRecordMetadata future = new FutureRecordMetadata(this.produceFuture, this.recordCount,
                                                               timestamp, checksum,
                                                               key == null ? -1 : key.length,
                                                               value == null ? -1 : value.length,
                                                               Time.SYSTEM);
        // we have to keep every future returned to the users in case the batch needs to be
        // split to several new batches and resent.
        thunks.add(new Thunk(callback, future));
        // 记录数 增加
        this.recordCount++;
        return future;
    }
}
```

此时数据就追加到了produceBatch中，到此produce -> send的工作就完成了。

这里只是把数据记录到了Accumulator中，并没有真正的网络IO，那么是谁真正的操作了网络IO呢？还记得前面创建了换一个sender实例，其是在一个daemon线程运行的，其执行了真正把数据发送的操作。下面看一下sender的工作把。







































