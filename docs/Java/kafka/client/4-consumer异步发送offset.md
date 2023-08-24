[TOC]

# consumer异步发送offset

本篇看一下consumer异步发送offset时的操作。 前面分析了具体的网络操作，此就直接看实现把。

> org.apache.kafka.clients.consumer.KafkaConsumer#commitAsync

```java
// 异步提交offset
@Override
public void commitAsync(final Map<TopicPartition, OffsetAndMetadata> offsets, OffsetCommitCallback callback) {
    acquireAndEnsureOpen();
    try {
        // 必须有groupId
        maybeThrowInvalidGroupIdException();
        log.debug("Committing offsets: {}", offsets);
        // 更新为罪行的 epoch
        offsets.forEach(this::updateLastSeenEpochIfNewer);
        // 提交,可以看到 offset由 协调器来提交
        // ---  ----
        coordinator.commitOffsetsAsync(new HashMap<>(offsets), callback);
    } finally {
        release();
    }
}
```

这里看到offset的提交，其实是有coordinator来实现的。

> org.apache.kafka.clients.consumer.internals.ConsumerCoordinator#commitOffsetsAsync

```java
   // 异步提交offset
    public void commitOffsetsAsync(final Map<TopicPartition, OffsetAndMetadata> offsets, final OffsetCommitCallback callback) {
        invokeCompletedOffsetCommitCallbacks();

        if (!coordinatorUnknown()) {
            // --- 重点 ----
            // 这里发送了一次  OffsetCommitRequest到 协调器 coordinator
            doCommitOffsetsAsync(offsets, callback);
        } else {
            pendingAsyncCommits.incrementAndGet();
            lookupCoordinator().addListener(new RequestFutureListener<Void>() {
                @Override
                public void onSuccess(Void value) {
                    pendingAsyncCommits.decrementAndGet();
                    doCommitOffsetsAsync(offsets, callback);
                    client.pollNoWakeup();
                }

                @Override
                public void onFailure(RuntimeException e) {
                    pendingAsyncCommits.decrementAndGet();
                    completedOffsetCommits.add(new OffsetCommitCompletion(callback, offsets,
                            new RetriableCommitFailedException(e)));
                }
            });
        }
        // 立即执行一次 IO 操作
        // 也就是 对channel的读取操作
        // 如果这里coordinator已经找到,这里就立即执行一次 网络IO操作, 有可能就把数据发送出去了
        // 如果coordinator没有 则此次操作, 不会写出 offset 提交
        client.pollNoWakeup();
    }
```

这里提价offset前，需要先找到coordinator：

1. 如果已经找到了coordinator，那么直接发送
2. 如果没有找到，则发送一个 FindCoordinatorRequest 到负载最小的node中，查找当前groupid对应的coordinator； 并且注册了回调函数，成功找到时，再进行提交

查找coordinator的操作：

> org.apache.kafka.clients.consumer.internals.AbstractCoordinator#lookupCoordinator

```java
// 查找coordinator  协调器
protected synchronized RequestFuture<Void> lookupCoordinator() {
    if (findCoordinatorFuture == null) {
        // find a node to ask about the coordinator
        // 查找负载最小的node
        // 即请求数 最小的node
        Node node = this.client.leastLoadedNode();
        if (node == null) {
            log.debug("No broker available to send FindCoordinator request");
            return RequestFuture.noBrokersAvailable();
        } else  // 向这个node 发送查找Coordinator的请求,即 FindCoordinatorRequest
            findCoordinatorFuture = sendFindCoordinatorRequest(node);
    }
    return findCoordinatorFuture;
}
```

查找负载最下的node:

> org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient#leastLoadedNode

```java
// 查找请求数最下的node
public Node leastLoadedNode() {
    lock.lock();
    try {
        // 查找负载最小的node
        // 即请求数 最小的node
        return client.leastLoadedNode(time.milliseconds());
    } finally {
        lock.unlock();
    }
}
```

> org.apache.kafka.clients.NetworkClient#leastLoadedNode

```java
// 查找负载最小的 node
// 负载最下 即 此node对应的输出请求 比较少
@Override
public Node leastLoadedNode(long now) {
    // 获取到集群中的节点
    List<Node> nodes = this.metadataUpdater.fetchNodes();
    if (nodes.isEmpty())
        throw new IllegalStateException("There are no nodes in the Kafka cluster");
    int inflight = Integer.MAX_VALUE;
    Node found = null;
    // 这里产生了一个随机数,最为 node的起始点
    int offset = this.randOffset.nextInt(nodes.size());
    for (int i = 0; i < nodes.size(); i++) {
        // 得到一个 index
        int idx = (offset + i) % nodes.size();
        // 获取此 index 对应的 node
        Node node = nodes.get(idx);
        // 记录此 node对应的请求的数量
        int currInflight = this.inFlightRequests.count(node.idString());
        // 如果此 node没有请求数, 且已经建立了连接,则直接返回此node
        if (currInflight == 0 && isReady(node, now)) {
            // if we find an established connection with no in-flight requests we can stop right away
            log.trace("Found least loaded node {} connected with no in-flight requests", node);
            return node;
        } else if (!this.connectionStates.isBlackedOut(node.idString(), now) && currInflight < inflight) {
            // otherwise if this is the best we have found so far, record that
            // 记录下此次 node 对应的请求数
            // 如果没有找到 请求数为0,即currInflight==0的node, 全部遍历完之后,也能找到请求数最小的一个node
            inflight = currInflight;
            // 记录下此次的 node
            found = node;
        } else if (log.isTraceEnabled()) {
            log.trace("Removing node {} from least loaded node selection: is-blacked-out: {}, in-flight-requests: {}",node, this.connectionStates.isBlackedOut(node.idString(), now), currInflight);
        }
    }

    if (found != null)
        log.trace("Found least loaded node {}", found);
    else
        log.trace("Least loaded node selection failed to find an available node");
    // 返回请求数 最少的 node
    return found;
}
```

找到node后，发送请求：

> org.apache.kafka.clients.consumer.internals.AbstractCoordinator#sendFindCoordinatorRequest

```java
// 查找当前组的 coordinator, 即发送一个 FindCoordinatorRequest 请求到 node
private RequestFuture<Void> sendFindCoordinatorRequest(Node node) {
    // initiate the group metadata request
    log.debug("Sending FindCoordinator request to broker {}", node);
    FindCoordinatorRequest.Builder requestBuilder =
        new FindCoordinatorRequest.Builder(FindCoordinatorRequest.CoordinatorType.GROUP, this.groupId);
    // 发送 FindCoordinatorRequest 请求,查找 coordinator
    return client.send(node, requestBuilder)
        .compose(new FindCoordinatorResponseHandler());
}
```

找到后，继续提价offset，这里看一下offset的提交操作：

> org.apache.kafka.clients.consumer.internals.ConsumerCoordinator#doCommitOffsetsAsync

```java
// 异步提交 offset
private void doCommitOffsetsAsync(final Map<TopicPartition, OffsetAndMetadata> offsets, final OffsetCommitCallback callback) {
    // 发送 OffsetCommitRequest 到 coordinator
    // ---  重点  ---
    RequestFuture<Void> future = sendOffsetCommitRequest(offsets);
    final OffsetCommitCallback cb = callback == null ? defaultOffsetCommitCallback : callback;
    // 添加 回调函数
    future.addListener(new RequestFutureListener<Void>() {
        @Override
        public void onSuccess(Void value) {
            if (interceptors != null)
                interceptors.onCommit(offsets);
            completedOffsetCommits.add(new OffsetCommitCompletion(cb, offsets, null));
        }

        @Override
        public void onFailure(RuntimeException e) {
            Exception commitException = e;

            if (e instanceof RetriableException)
                commitException = new RetriableCommitFailedException(e);
            completedOffsetCommits.add(new OffsetCommitCompletion(cb, offsets, commitException));
        }
    });
}
```

> org.apache.kafka.clients.consumer.internals.ConsumerCoordinator#sendOffsetCommitRequest

```java
// 发送一个 offsetCommitRequest 到 coordinator
private RequestFuture<Void> sendOffsetCommitRequest(final Map<TopicPartition, OffsetAndMetadata> offsets) {
    if (offsets.isEmpty())
        return RequestFuture.voidSuccess();
    // 检测 并 获取到 coordinator 对应的node
    Node coordinator = checkAndGetCoordinator();
    // 如果没有 协调器,则直接返回
    if (coordinator == null)
        return RequestFuture.coordinatorNotAvailable();

    // create the offset commit request
    // 创建 offset commit request
    Map<TopicPartition, OffsetCommitRequest.PartitionData> offsetData = new HashMap<>(offsets.size());
    for (Map.Entry<TopicPartition, OffsetAndMetadata> entry : offsets.entrySet()) {
        OffsetAndMetadata offsetAndMetadata = entry.getValue();
        if (offsetAndMetadata.offset() < 0) {
            return RequestFuture.failure(new IllegalArgumentException("Invalid offset: " + offsetAndMetadata.offset()));
        }
        offsetData.put(entry.getKey(), new OffsetCommitRequest.PartitionData(offsetAndMetadata.offset(),
                                                                             offsetAndMetadata.leaderEpoch(), offsetAndMetadata.metadata()));
    }

    final Generation generation;
    if (subscriptions.partitionsAutoAssigned()) {
        generation = generationIfStable();
        // if the generation is null, we are not part of an active group (and we expect to be).
        // the only thing we can do is fail the commit and let the user rejoin the group in poll()
        if (generation == null) {
            log.info("Failing OffsetCommit request since the consumer is not part of an active group");
            return RequestFuture.failure(new CommitFailedException());
        }
    } else
        generation = Generation.NO_GENERATION;
    // 创建一个 OffsetCommitRequest builder
    OffsetCommitRequest.Builder builder = new OffsetCommitRequest.Builder(this.groupId, offsetData).
        setGenerationId(generation.generationId).
        setMemberId(generation.memberId);

    log.trace("Sending OffsetCommit request with {} to coordinator {}", offsets, coordinator);
    // 发送提交请求
    // 注册一个回调函数 OffsetCommitResponseHandler
    return client.send(coordinator, builder)
        .compose(new OffsetCommitResponseHandler(offsets));
}
```

可见这里的异步提交就是把offsetCommit的请求发送到的unsent的容器中，并注册一个回调函数，来进行后续处理。









































