[TOC]

# consumer 网络IO实现(2)

本篇接着上篇继续。

上篇分析到尝试发送那些等到发送的请求：

> org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient#trySend

```java
// 尝试发送那些 等待发送的请求
private long trySend(long now) {
    long pollDelayMs = maxPollTimeoutMs;
    // send any requests that can be sent now
    // 遍历 所有 有请求等待发送的 node
    for (Node node : unsent.nodes()) {
        // 获取到 此 node 对应的要发送的请求
        Iterator<ClientRequest> iterator = unsent.requestIterator(node);
        if (iterator.hasNext())
            pollDelayMs = Math.min(pollDelayMs, client.pollDelayMs(node, now));
        // 遍历等待的请求
        while (iterator.hasNext()) {
            ClientRequest request = iterator.next();
            // ready 意思 是否和 node建立好了连接,没有建立好连接,则尝试建立一个连接
            // -- 重点 --
            if (client.ready(node, now)) {
                // 发送请求
                client.send(request, now);
                iterator.remove();
            }
        }
    }
    return pollDelayMs;
}
```

这里大体步骤:

1. 遍历unsent中所有的node，获取其对应的等待发送的request
2. 查看到此node(对应集群中的一个broker)的连接是否就绪，即连接是否正常连接了
   1. 如果连接建立，则尝试发送此node对应的那些请求
   2. 没有建立，则先建立连接，之后再发送数据

看一下此ready函数的操作：

> org.apache.kafka.clients.NetworkClient#ready

```java
// 检测 network client是否ready, 如果已经建立了连接,则返回true
// 没有建立连接,则建立一个连接
@Override
public boolean ready(Node node, long now) {
    // node 信息为空,直接报错
    if (node.isEmpty())
        throw new IllegalArgumentException("Cannot connect to empty node " + node);
    // 检测连接是否ready
    if (isReady(node, now))
        return true;
    // initiateConnect 建立一个连接
    if (connectionStates.canConnect(node.idString(), now))
    // if we are interested in sending to a node and we don't have a connection to it, initiate one
        initiateConnect(node, now);

    return false;
}
```

> org.apache.kafka.clients.NetworkClient#isReady

```java
@Override
public boolean isReady(Node node, long now) {
    // if we need to update our metadata now declare all requests unready to make metadata requests first
    // priority
    return !metadataUpdater.isUpdateDue(now) && canSendRequest(node.idString(), now);
}

// 能够发送请求, 即连接建立了, channel ready了, 就可以发送了
private boolean canSendRequest(String node, long now) {
    return connectionStates.isReady(node, now) && selector.isChannelReady(node) &&
        inFlightRequests.canSendMore(node);
}
```

建立连接:

> org.apache.kafka.clients.NetworkClient#initiateConnect

```java
// 建立一个连接到 给定的 node
private void initiateConnect(Node node, long now) {
    String nodeConnectionId = node.idString();
    try {
        // 记录 node 对应的一个连接的状态
        connectionStates.connecting(nodeConnectionId, now, node.host(), clientDnsLookup);
        InetAddress address = connectionStates.currentAddress(nodeConnectionId);
        log.debug("Initiating connection to node {} using address {}", node, address);
        // 真正连接的操作
        // --- 重点 ----
        selector.connect(nodeConnectionId,
                         new InetSocketAddress(address, node.port()),
                         this.socketSendBuffer,
                         this.socketReceiveBuffer);
    } catch (IOException e) {
        log.warn("Error connecting to node {}", node, e);
        /* attempt failed, we'll try again after the backoff */
        connectionStates.disconnected(nodeConnectionId, now);
        /* maybe the problem is our metadata, update it */
        metadataUpdater.requestUpdate();
    }
}
```

记录此正在连接的node的信息:

```java
// 记录一个 node 对应的连接的状态
public void connecting(String id, long now, String host, ClientDnsLookup clientDnsLookup) {
    NodeConnectionState connectionState = nodeState.get(id);
    if (connectionState != null && connectionState.host().equals(host)) {
        // 上次建立连接的时间
        connectionState.lastConnectAttemptMs = now;
        // 当前的连接状态
        connectionState.state = ConnectionState.CONNECTING;
        // Move to next resolved address, or if addresses are exhausted, mark node to be re-resolved
        connectionState.moveToNextAddress();
        return;
    } else if (connectionState != null) {
        log.info("Hostname for node {} changed from {} to {}.", id, connectionState.host(), host);
    }

    // Create a new NodeConnectionState if nodeState does not already contain one
    // for the specified id or if the hostname associated with the node id changed.
    // 记录下 此 node对应的状态
    nodeState.put(id, new NodeConnectionState(ConnectionState.CONNECTING, now,
                                              this.reconnectBackoffInitMs, host, clientDnsLookup));
}
```

> org.apache.kafka.common.network.Selector#connect

```java
// 连接操作
@Override
public void connect(String id, InetSocketAddress address, int sendBufferSize, int receiveBufferSize) throws IOException {
    // 确保此id 没有注册过
    ensureNotRegistered(id);
    // 1. 创建一个 socketChannel
    SocketChannel socketChannel = SocketChannel.open();
    SelectionKey key = null;
    try {
        // 2. 配置socket
        configureSocketChannel(socketChannel, sendBufferSize, receiveBufferSize);
        // 3. 连接
        boolean connected = doConnect(socketChannel, address);
        // 4. 注册 channel 到 selector中
        key = registerChannel(id, socketChannel, SelectionKey.OP_CONNECT);
        // 如果连接成功
        if (connected) {
            // OP_CONNECT won't trigger for immediately connected channels
            log.debug("Immediately connected to node {}", id);
            // 连接后,马上就连接成功了,则记录下来
            immediatelyConnectedKeys.add(key);
            // 更新 channel 感兴趣的时间
            key.interestOps(0);
        }
    } catch (IOException | RuntimeException e) {
        if (key != null)
            immediatelyConnectedKeys.remove(key);
        channels.remove(id);
        socketChannel.close();
        throw e;
    }
}
```

熟悉Nio的就可以看到，此处应该是真正的连接操作了：

1. 创建了socketChannel
2. 对socketChannel 以及 socket 进行了配置
3. 注册此channel到 selector中
4. 注入连接成功了，则记录下此channel对应的key，以及修改其 事件

> org.apache.kafka.common.network.Selector#configureSocketChannel

```java
// 对 socketChannel 进行的一些配置
private void configureSocketChannel(SocketChannel socketChannel, int sendBufferSize, int receiveBufferSize)
    throws IOException {
    // 非阻塞模式
    socketChannel.configureBlocking(false);
    Socket socket = socketChannel.socket();
    // keepalive
    socket.setKeepAlive(true);
    // 设置输入 输出 缓冲区
    if (sendBufferSize != Selectable.USE_DEFAULT_BUFFER_SIZE)
        socket.setSendBufferSize(sendBufferSize);
    if (receiveBufferSize != Selectable.USE_DEFAULT_BUFFER_SIZE)
        socket.setReceiveBufferSize(receiveBufferSize);
    // nodelay
    socket.setTcpNoDelay(true);
}
```

> org.apache.kafka.common.network.Selector#doConnect

```java
// 连接
protected boolean doConnect(SocketChannel channel, InetSocketAddress address) throws IOException {
    try {
        // 真实的连接动作
        return channel.connect(address);
    } catch (UnresolvedAddressException e) {
        throw new IOException("Can't resolve address: " + address, e);
    }
}
```

> org.apache.kafka.common.network.Selector#registerChannel

```java
// 注册 socketChannel到 selector的操作
protected SelectionKey registerChannel(String id, SocketChannel socketChannel, int interestedOps) throws IOException {
    // 注册 socketChannel 到 nioselector
    SelectionKey key = socketChannel.register(nioSelector, interestedOps);
    // 创建kafkaChannel
    KafkaChannel channel = buildAndAttachKafkaChannel(socketChannel, id, key);
    // 记录创建的channel
    this.channels.put(id, channel);
    // 如果有 idle 管理器,则更新此 channel的 时间
    if (idleExpiryManager != null)
        idleExpiryManager.update(channel.id(), time.nanoseconds());
    return key;
}
```

> org.apache.kafka.common.network.Selector#buildAndAttachKafkaChannel

```java
// 使用kafkaChannel 封装创建的socketChannel,并attch到 key上
private KafkaChannel buildAndAttachKafkaChannel(SocketChannel socketChannel, String id, SelectionKey key) throws IOException {
    try {
        // 使用指定的 builder 创建 kafkaChannel
        KafkaChannel channel = channelBuilder.buildChannel(id, key, maxReceiveSize, memoryPool);
        // 把创建的kafkaChannel attach 到 SelectionKey 上
        key.attach(channel);
        // 返回创建的 KafkaChannel
        return channel;
    } catch (Exception e) {
        try {
            socketChannel.close();
        } finally {
            key.cancel();
        }
        throw new IOException("Channel could not be created for socket " + socketChannel, e);
    }
}
```

> org.apache.kafka.common.network.PlaintextChannelBuilder#buildChannel

```java
// 创建 KafkaChannel, 并创建了真正的传输层 transportLayer
// transportLayer 是真正传输数据的操作层
@Override
public KafkaChannel buildChannel(String id, SelectionKey key, int maxReceiveSize, MemoryPool memoryPool) throws KafkaException {
    try {
        // 真正的传输层
        PlaintextTransportLayer transportLayer = new PlaintextTransportLayer(key);
        // 认证提供者
        Supplier<Authenticator> authenticatorCreator = () -> new PlaintextAuthenticator(configs, transportLayer, listenerName);
        // 创建一个 kafkaChannel 并返回
        return new KafkaChannel(id, transportLayer, authenticatorCreator, maxReceiveSize,
                                memoryPool != null ? memoryPool : MemoryPool.NONE);
    } catch (Exception e) {
        log.warn("Failed to create channel due to ", e);
        throw new KafkaException(e);
    }
}
```

```java
public PlaintextTransportLayer(SelectionKey key) throws IOException {
    // 记录事件key
    this.key = key;
    // 记录key 上attach 的 channel
    this.socketChannel = (SocketChannel) key.channel();
}
```

由此创建连接可以看到：

1. 真正的传输层为PlaintextTransportLayer，
2. KafkaChannel 封装了 PlaintextTransportLayer， 并且 kafkaChannel attach 到了 Selectionkey上
3. socketChannel 注册到了 nioselector中，这里强调nioselector是因为kafka抽象了一个 selector

连接创建完了，就可以开始传输数据了：

> org.apache.kafka.clients.NetworkClient#send

```java
    // 发送请求
    @Override
    public void send(ClientRequest request, long now) {
        doSend(request, false, now);
    }
```

```java
// 发送请求
private void doSend(ClientRequest clientRequest, boolean isInternalRequest, long now) {
    ensureActive();
    // 获取请求对应的 nodeId,即dest 地址
    String nodeId = clientRequest.destination();
    if (!isInternalRequest) {
        if (!canSendRequest(nodeId, now))
            throw new IllegalStateException("Attempt to send a request to node " + nodeId + " which is not ready.");
    }
    AbstractRequest.Builder<?> builder = clientRequest.requestBuilder();
    try {
        // 创建 version 版本
        NodeApiVersions versionInfo = apiVersions.get(nodeId);
        short version;
        // Note: if versionInfo is null, we have no server version information. This would be
        // the case when sending the initial ApiVersionRequest which fetches the version
        // information itself.  It is also the case when discoverBrokerVersions is set to false.
        if (versionInfo == null) {
            version = builder.latestAllowedVersion();
            if (discoverBrokerVersions && log.isTraceEnabled())
                log.trace("No version information found when sending {} with correlation id {} to node {}. " + "Assuming version {}.", clientRequest.apiKey(), clientRequest.correlationId(), nodeId, version);
        } else {
            version = versionInfo.latestUsableVersion(clientRequest.apiKey(), builder.oldestAllowedVersion(),builder.latestAllowedVersion());
        }
        // The call to build may also throw UnsupportedVersionException, if there are essential
        // fields that cannot be represented in the chosen version.
        // 发送请求
        // ---- 重点 ---
        doSend(clientRequest, isInternalRequest, now, builder.build(version));
    } catch (UnsupportedVersionException unsupportedVersionException) {
        // If the version is not supported, skip sending the request over the wire.
        // Instead, simply add it to the local queue of aborted requests.
        log.debug("Version mismatch when attempting to send {} with correlation id {} to {}", builder,clientRequest.correlationId(), clientRequest.destination(), unsupportedVersionException);
        ClientResponse clientResponse = new ClientResponse(clientRequest.makeHeader(builder.latestAllowedVersion()),clientRequest.callback(), clientRequest.destination(), now, now,false, unsupportedVersionException, null, null);
        abortedSends.add(clientResponse);
    }
}
```

> org.apache.kafka.clients.NetworkClient#doSend(org.apache.kafka.clients.ClientRequest, boolean, long, org.apache.kafka.common.requests.AbstractRequest)

```java
// 发送器请求
private void doSend(ClientRequest clientRequest, boolean isInternalRequest, long now, AbstractRequest request) {
    // 请求的 dest
    String destination = clientRequest.destination();
    // 请求的 header
    RequestHeader header = clientRequest.makeHeader(request.version());
    if (log.isDebugEnabled()) {
        int latestClientVersion = clientRequest.apiKey().latestVersion();
        if (header.apiVersion() == latestClientVersion) {
            log.trace("Sending {} {} with correlation id {} to node {}", clientRequest.apiKey(), request,clientRequest.correlationId(), destination);
        } else {
            log.debug("Using older server API v{} to send {} {} with correlation id {} to node {}",
                      header.apiVersion(), clientRequest.apiKey(), request, clientRequest.correlationId(), destination);
        }
    }
    // 把request 转换为send 对象,并把 header序列化
    Send send = request.toSend(destination, header);
    // 正在发送的请求为  inFlight 即正在飞翔的 request, 名字形象
    InFlightRequest inFlightRequest = new InFlightRequest(
        clientRequest,
        header,
        isInternalRequest,
        request,
        send,
        now);
    // 把要发送的请求 记录到 inFlightRequests
    this.inFlightRequests.add(inFlightRequest);
    // 发送请求
    selector.send(send);
}
```

继续向下看此selector的发送:

> org.apache.kafka.common.network.Selector#send

```java
// 请求发送
public void send(Send send) {
    // 获取目的地址
    String connectionId = send.destination();
    // 获取目的地址对应的 channel
    KafkaChannel channel = openOrClosingChannelOrFail(connectionId);
    // 如果此channel  正在关闭中,则 把此请求记录到 failedSends
    if (closingChannels.containsKey(connectionId)) {
// ensure notification via `disconnected`, leave channel in the state in which closing was triggered
        this.failedSends.add(connectionId);
    } else {
        try {
            // 设置send 到kafakChannel中
            channel.setSend(send);
        } catch (Exception e) {
            // 出现异常,则更新 kafkaChannel 装填为 FAILED_SEND
            // update the state for consistency, the channel will be discarded after `close`
            channel.state(ChannelState.FAILED_SEND);
      // ensure notification via `disconnected` when `failedSends` are processed in the next poll
            this.failedSends.add(connectionId);
            close(channel, CloseMode.DISCARD_NO_NOTIFY);
            if (!(e instanceof CancelledKeyException)) {
                log.error("Unexpected exception during send, closing connection {} and rethrowing exception {}",connectionId, e);
                throw e;
            }
        }
    }
}
```

这里吧要发送的数据封装为Send，并把send设置到此node对应的kafakChannel中。

> org.apache.kafka.common.network.KafkaChannel#setSend

```java
// 记录下要发送的数据
public void setSend(Send send) {
    if (this.send != null)
        throw new IllegalStateException("Attempt to begin a send operation with prior send operation still in progress, connection id is " + id);
    // 记录要发送的数据
    this.send = send;
    // 顺带更改了 此 真正发送层的事件
    this.transportLayer.addInterestOps(SelectionKey.OP_WRITE);
}

// org.apache.kafka.common.network.PlaintextTransportLayer#addInterestOps
// 增加感兴趣的事件 ops
@Override
public void addInterestOps(int ops) {
    key.interestOps(key.interestOps() | ops);
}
```

这里看到，每一个kafkaChannel对应一个node，其send 属性就是要发送的数据，transportLayer属性为真正连接到node的socketChannel即真正发送数据的地方。

这里连接创建完了，请求也发送了，不过请求仍然是记录下来，并没有真正的发生网络IO，那就继续看下去。

现在往回拉一下思路，刚才分析的一大段，其实都是org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient#poll 中的 trySend 函数，继续往下看此poll的处理，下面调用client.poll()  继续进行处理：

> org.apache.kafka.clients.NetworkClient#poll

```java
// 进行 network IO操作的地方
@Override
public List<ClientResponse> poll(long timeout, long now) {
    ensureActive();

    if (!abortedSends.isEmpty()) {
        // If there are aborted sends because of unsupported version exceptions or disconnects,
        // handle them immediately without waiting for Selector#poll.
        List<ClientResponse> responses = new ArrayList<>();
        handleAbortedSends(responses);
        completeResponses(responses);
        return responses;
    }
    // 发送一个metadata 请求
    long metadataTimeout = metadataUpdater.maybeUpdate(now);
    try {
        // 此处会进行真正的io 操作
        // -- 重点 ---
        this.selector.poll(Utils.min(timeout, metadataTimeout, defaultRequestTimeoutMs));
    } catch (IOException e) {
        log.error("Unexpected error during I/O", e);
    }

    // process completed actions
    long updatedNow = this.time.milliseconds();
    List<ClientResponse> responses = new ArrayList<>();
    handleCompletedSends(responses, updatedNow);
    handleCompletedReceives(responses, updatedNow);
    handleDisconnections(responses, updatedNow);
    handleConnections();
    handleInitiateApiVersionRequests(updatedNow);
    handleTimedOutRequests(responses, updatedNow);
    completeResponses(responses);
    return responses;
}
```

这里的重点在 那个poll函数中，继续看：

> org.apache.kafka.common.network.Selector#poll

```java
// 处理io 操作
@Override
public void poll(long timeout) throws IOException {
    if (timeout < 0)
        throw new IllegalArgumentException("timeout should be >= 0");
    // 防止内存不够时  频繁拉取数据
    boolean madeReadProgressLastCall = madeReadProgressLastPoll;
    // 对于上次处理时的资源的 释放
    // 以及移除那些 closing 的channel
    clear();

    boolean dataInBuffers = !keysWithBufferedRead.isEmpty();

    if (hasStagedReceives() || !immediatelyConnectedKeys.isEmpty() || (madeReadProgressLastCall && dataInBuffers))
        timeout = 0;

    if (!memoryPool.isOutOfMemory() && outOfMemory) {
//we have recovered from memory pressure. unmute any channel not explicitly muted for other reasons
        log.trace("Broker no longer low on memory - unmuting incoming sockets");
        for (KafkaChannel channel : channels.values()) {
            if (channel.isInMutableState() && !explicitlyMutedChannels.contains(channel)) {
                channel.maybeUnmute();
            }
        }
        outOfMemory = false;
    }
    /* check ready keys */
    // 开始执行时间
    long startSelect = time.nanoseconds();
    // ----- 重点 ----
    // select获取 就绪channel的数量
    int numReadyKeys = select(timeout);
    // 结束 select的时间
    long endSelect = time.nanoseconds();
    // 记录 select的时间
    this.sensors.selectTime.record(endSelect - startSelect, time.milliseconds());
    //
    if (numReadyKeys > 0 || !immediatelyConnectedKeys.isEmpty() || dataInBuffers) {
        // 获取到 有 ready 事件的key
        // ---- 重点 --- 
        Set<SelectionKey> readyKeys = this.nioSelector.selectedKeys();

        // Poll from channels that have buffered data (but nothing more from the underlying socket)
        // keysWithBufferedRead 记录已经缓存了数据的key
        if (dataInBuffers) {
            keysWithBufferedRead.removeAll(readyKeys); //so no channel gets polled twice
            Set<SelectionKey> toPoll = keysWithBufferedRead;
            keysWithBufferedRead = new HashSet<>(); //poll() calls will repopulate if needed
            pollSelectionKeys(toPoll, false, endSelect);
        }

        // Poll from channels where the underlying socket has more data
        pollSelectionKeys(readyKeys, false, endSelect);
        // Clear all selected keys so that they are included in the ready count for the next select
        readyKeys.clear();

        pollSelectionKeys(immediatelyConnectedKeys, true, endSelect);
        immediatelyConnectedKeys.clear();
    } else {
        madeReadProgressLastPoll = true; //no work is also "progress"
    }

    long endIo = time.nanoseconds();
    // 记录 io 操作的时间
    this.sensors.ioTime.record(endIo - endSelect, time.milliseconds());

    // Close channels that were delayed and are now ready to be closed
    completeDelayedChannelClose(endIo);

    // we use the time at the end of select to ensure that we don't close any connections that
    // have just been processed in pollSelectionKeys
    maybeCloseOldestConnection(endSelect);

    // Add to completedReceives after closing expired connections to avoid removing
    // channels with completed receives until all staged receives are completed.
    addToCompletedReceives();
}
```

看到这里看到了，真正调用nioselector 中 select和 selectedKeys的地方，获取到了有就绪事件的channel个数及其对应的selectionKey，然后进行处理。

```java
// 调用真正的 nioselector 来进行查询操作
private int select(long timeoutMs) throws IOException {
    if (timeoutMs < 0L)
        throw new IllegalArgumentException("timeout should be >= 0");

    if (timeoutMs == 0L)
        return this.nioSelector.selectNow();
    else
        return this.nioSelector.select(timeoutMs);
}
```

看一下处理：

> org.apache.kafka.common.network.Selector#pollSelectionKeys

```java
    // package-private for testing
    void pollSelectionKeys(Set<SelectionKey> selectionKeys,
                           boolean isImmediatelyConnected,  // 表示是否是 刚刚建立的连接
                           long currentTimeNanos) {
        // determineHandlingOrder 打乱 keys的顺序
        for (SelectionKey key : determineHandlingOrder(selectionKeys)) {
            // 获取此 key 上 attach的 kafkaChannel
            KafkaChannel channel = channel(key);
            // 记录 channel的开始时间
            long channelStartTimeNanos = recordTimePerConnection ? time.nanoseconds() : 0;
            boolean sendFailed = false;

            // register all per-connection metrics at once
            sensors.maybeRegisterConnectionMetrics(channel.id());
            // 如果设置了 idleExpireManager 则更新链接的时间
            if (idleExpiryManager != null)
                idleExpiryManager.update(channel.id(), currentTimeNanos);

            try {
                // 对于刚刚链接的 channel的操作
                if (isImmediatelyConnected || key.isConnectable()) {
                    // 是否完成了 连接
                    if (channel.finishConnect()) {
                        // 完成了连接,则记录下来
                        this.connected.add(channel.id());
                        this.sensors.connectionCreated.record();
                        // 获取key  对应的sockeChannel
                        SocketChannel socketChannel = (SocketChannel) key.channel();
   log.debug("Created socket with SO_RCVBUF = {}, SO_SNDBUF = {}, SO_TIMEOUT = {} to node {}",
                                socketChannel.socket().getReceiveBufferSize(),
                                socketChannel.socket().getSendBufferSize(),
                                socketChannel.socket().getSoTimeout(),
                                channel.id());
                    } else {
                        continue;
                    }
                }

                /* if channel is not ready finish prepare */
                if (channel.isConnected() && !channel.ready()) {
                    channel.prepare();
                    if (channel.ready()) {
                        long readyTimeMs = time.milliseconds();
                        boolean isReauthentication = channel.successfulAuthentications() > 1;
                        if (isReauthentication) {
                            sensors.successfulReauthentication.record(1.0, readyTimeMs);
                            if (channel.reauthenticationLatencyMs() == null)
                                log.warn(
                                    "Should never happen: re-authentication latency for a re-authenticated channel was null; continuing...");
                            else
                          sensors.reauthenticationLatency.record(channel.reauthenticationLatencyMs().doubleValue(), readyTimeMs);
                        } else {
                            sensors.successfulAuthentication.record(1.0, readyTimeMs);
                            if (!channel.connectedClientSupportsReauthentication())
                                sensors.successfulAuthenticationNoReauth.record(1.0, readyTimeMs);
                        }
                        log.debug("Successfully {}authenticated with {}", isReauthentication ?
                            "re-" : "", channel.socketDescription());
                    }
                    List<NetworkReceive> responsesReceivedDuringReauthentication = channel
                            .getAndClearResponsesReceivedDuringReauthentication();
                    responsesReceivedDuringReauthentication.forEach(receive -> addToStagedReceives(channel, receive));
                }
                // 尝试读取数据
                // -- 重点 ---
                // 这里尝试读取时, 首先channel对应的读事件 ready
                attemptRead(key, channel);
                // channel中是否有 缓存的数据
                if (channel.hasBytesBuffered()) {
                    // 如果有缓存的数据,则记录此key
                    keysWithBufferedRead.add(key);
                }

                // 对可写 事件的处理
                // -- ---
                if (channel.ready() && key.isWritable() && !channel.maybeBeginClientReauthentication(
                    () -> channelStartTimeNanos != 0 ? channelStartTimeNanos : currentTimeNanos)) {
                    Send send;
                    try {
                        // --- 重点 ----
                        // 发送数据
                        send = channel.write();
                    } catch (Exception e) {
                        sendFailed = true;
                        throw e;
                    }
                    if (send != null) {
                        // 记录完成发送的send
                        this.completedSends.add(send);
                        // 记录完成发送字节数
                        this.sensors.recordBytesSent(channel.id(), send.size());
                    }
                }
                /* cancel any defunct sockets */
                // key 不可用了,则进行关闭操作
                if (!key.isValid())
                    close(channel, CloseMode.GRACEFUL);

            } catch (Exception e) {
               /// 省略
            } finally {
                // 记录 network 时间
                maybeRecordTimePerConnection(channel, channelStartTimeNanos);
            }
        }
    }
```

这里是真正的读写处理的地方，分别看一下其读取是如何进行的。

读操作：

> org.apache.kafka.common.network.Selector#attemptRead

```java
// 尝试读取数据
private void attemptRead(SelectionKey key, KafkaChannel channel) throws IOException {
    //if channel is ready and has bytes to read from socket or buffer, and has no
    //previous receive(s) already staged or otherwise in progress then read from it
    if (channel.ready() && (key.isReadable() || channel.hasBytesBuffered()) && !hasStagedReceive(channel)
        && !explicitlyMutedChannels.contains(channel)) {
        NetworkReceive networkReceive;
        // 读取数据, 从channel中进行数据的读取
        // -- 重点 --
        while ((networkReceive = channel.read()) != null) {
            madeReadProgressLastPoll = true;
            // 记录下 接收到的数据
            addToStagedReceives(channel, networkReceive);
        }
        if (channel.isMute()) {
            outOfMemory = true; //channel has muted itself due to memory pressure.
        } else {
            madeReadProgressLastPoll = true;
        }
    }
}
```

这里进行了读取操作，如果读取到了数据，则把读取到的数据保存起来；如果channel把自己mute掉，则说明没有分配到缓存，即没有内存可用了，则设置outOfMemory为true。

看一下读取操作：

> org.apache.kafka.common.network.KafkaChannel#read

```java
// 读取数据
public NetworkReceive read() throws IOException {
    NetworkReceive result = null;
    // 接收数据的容器
    if (receive == null) {
        receive = new NetworkReceive(maxReceiveSize, id, memoryPool);
    }
    // 开始读取数据
    receive(receive);
    if (receive.complete()) {
        receive.payload().rewind();
        result = receive;
        receive = null;
        // 到这里,说明 receive没有分配到内存,则把自己 mute掉
    } else if (receive.requiredMemoryAmountKnown() && !receive.memoryAllocated() && isInMutableState()) {
        //pool must be out of memory, mute ourselves.
        // 如果没有分配到内存,
        mute();
    }
    // 返回 接收到数据的 receive
    return result;
}
```

接收数据:

> org.apache.kafka.common.network.KafkaChannel#receive

```java
// 开始接收数据,从 transportLayer 中读取数据
private long receive(NetworkReceive receive) throws IOException {
    return receive.readFrom(transportLayer);
}
```

> org.apache.kafka.common.network.NetworkReceive#readFrom

```java
// 进行数据的读取
public long readFrom(ScatteringByteChannel channel) throws IOException {
    int read = 0;
    // size buffer中还有空间,则进行数据的读取
    // 默认情况下,size就只有4个byte,即一个 int的长度
    // 也就是说 size 就是读取一个int值,此表示本次数据的长度,然后使用此长度去分配buffer
    // 然后使用此buffer来缓存读取到的数据
    if (size.hasRemaining()) {
        // 从channel 中读取数据到 size buffer中
        int bytesRead = channel.read(size);
        // 没有读取到数据,则 抛出异常
        if (bytesRead < 0)
            throw new EOFException();
        // 记录读取到的 数据个数
        read += bytesRead;
        // 如果size buffer中没有空间了,读满了
        if (!size.hasRemaining()) {
            // 开始读取
            size.rewind();
            // 接收到长度,读取一个 int
            int receiveSize = size.getInt();
            if (receiveSize < 0)
                throw new InvalidReceiveException("Invalid receive (size = " + receiveSize + ")");
            if (maxSize != UNLIMITED && receiveSize > maxSize)
                throw new InvalidReceiveException("Invalid receive (size = " + receiveSize + " larger than " + maxSize + ")");
            // 记录 reqeust的 大小
            requestedBufferSize = receiveSize; //may be 0 for some payloads (SASL)
            if (receiveSize == 0) {
                buffer = EMPTY_BUFFER;
            }
        }
    }
    if (buffer == null && requestedBufferSize != -1) { //we know the size we want but havent been able to allocate it yet
        // 尝试分配缓存
        buffer = memoryPool.tryAllocate(requestedBufferSize);
        if (buffer == null)
            log.trace("Broker low on memory - could not allocate buffer of size {} for source {}", requestedBufferSize, source);
    }
    // 分配成功了
    if (buffer != null) {
        // 继续从channel中读取数据到  buffer中
        int bytesRead = channel.read(buffer);
        if (bytesRead < 0)
            throw new EOFException();
        read += bytesRead;
    }

    return read;
}
```

> org.apache.kafka.common.network.PlaintextTransportLayer#read(java.nio.ByteBuffer)

```java
// 从channel中读取数据
@Override
public int read(ByteBuffer dst) throws IOException {
    // 读取数据到 此  dst  buffer中
    return socketChannel.read(dst);
}
```

此读取数据操作，先读取一个int值，此int值表示此处数据的总长度，使用此int值，去分配一个buffer，然后使用此buffer来记录读取到的数据。

本篇就分析到读取操作，具体写操作的处理，限于篇幅，新建一篇来分析。































