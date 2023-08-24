[TOC]

# consumer 同步提交offset的操作

上篇看过了offset异步提交的操作，本篇来看一下offset同步提交的实现。

> org.apache.kafka.clients.consumer.KafkaConsumer#commitSync()

```java
// 同步提交offset
@Override
public void commitSync() {
    commitSync(Duration.ofMillis(defaultApiTimeoutMs));
}
```

看到，同步提交也设置了超时时间。

> org.apache.kafka.clients.consumer.KafkaConsumer#commitSync(java.time.Duration)

```java
// 同步提交offset
@Override
public void commitSync(Duration timeout) {
    acquireAndEnsureOpen();
    try {
        maybeThrowInvalidGroupIdException();
        if (!coordinator.commitOffsetsSync(subscriptions.allConsumed(), time.timer(timeout))) {
            throw new TimeoutException("Timeout of " + timeout.toMillis() + "ms expired before successfully " +"committing the current consumed offsets");
        }
    } finally {
        release();
    }
}
```

其他先不分析，直接看这里的同步offset提交操作；

> org.apache.kafka.clients.consumer.internals.ConsumerCoordinator#commitOffsetsSync

```java
// 同步提交 offset 操作
public boolean commitOffsetsSync(Map<TopicPartition, OffsetAndMetadata> offsets, Timer timer) {
    invokeCompletedOffsetCommitCallbacks();
    // 如果offset 参数为空,直接返回
    if (offsets.isEmpty())
        return true;

    do {
        // coordinator 协调器不知
        // 如果 coordinator unknown,且没有找到 FindCoordinatorRequest,则返回false, 表示提交失败
        if (coordinatorUnknown() && !ensureCoordinatorReady(timer)) {
            return false;
        }
        // 发送一个 OffsetCommitRequest的请求
        RequestFuture<Void> future = sendOffsetCommitRequest(offsets);
        // 这里紧接着就进行 io 操作,保证请求能 输出出去
        client.poll(future, timer);

        // the offset commits were applied.
        // 调用 完成offset 提交的回调函数
        invokeCompletedOffsetCommitCallbacks();
        // 提交完成, 调用拦截器对 offset 进行处理
        if (future.succeeded()) {
            if (interceptors != null)
                interceptors.onCommit(offsets);
            return true;
        }
        // 如果失败了, 并且不能再次请求,则抛出异常
        if (future.failed() && !future.isRetriable())
            throw future.exception();
        // 睡眠 retryBackoffMs 毫秒, 避免持续请求
        timer.sleep(retryBackoffMs);
    } while (timer.notExpired());

    return false;
}
```

这里同步咋实现的呢?

1. 查找coordinator
2. 发送提交请求
3. 执行一次io
4. 如果不超时，则继续执行上述操作

可见，这里再一个循环里面，执行了多次的发送以及网络io发送请求，来最大程度的保存能够发送成功，不过也不能保证100%成功。



































