[TOC]

#  socket接收处理

分析完tomcat的启动操作后，了解到了tomcat对于socket的处理方式，其和netty的模式很相似。本篇呢，分析一下tomcat对socket的接收处理。

前景回顾：

经过前面分析后，知道具体的接收处理是在NioEndpoint进行的，看一下NioEndpoint的启动操作：

> org.apache.tomcat.util.net.NioEndpoint#startInternal

```java
// socket接收的 后台线程
@Override
public void startInternal() throws Exception {

    if (!running) {
        running = true;
        paused = false;
        // 默认长度大小为 128
        // 三个缓存的 列表都是 128
        processorCache = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                                 socketProperties.getProcessorCache());
        eventCache = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                             socketProperties.getEventCache());
        nioChannels = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                              socketProperties.getBufferPool());

        // Create worker collection
        // 创建  executor
        if ( getExecutor() == null ) {
            createExecutor();
        }
        // 限流使用
        // 变相的限制 连接数
        initializeConnectionLatch();

        // Start poller threads
        // 控制pollers线程数量的是
        // pollerThreadCount = Math.min(2,Runtime.getRuntime().availableProcessors())
        // poller 用于进行 读写处理
        pollers = new Poller[getPollerThreadCount()];
        for (int i=0; i<pollers.length; i++) {
            // 看一下poller的run方法
            pollers[i] = new Poller();
            Thread pollerThread = new Thread(pollers[i], getName() + "-ClientPoller-"+i);
            pollerThread.setPriority(threadPriority);
            //pollerThread.setDaemon(true);
            // 同步
            pollerThread.setDaemon(false);
            pollerThread.start();
        }
        // 接收器 用于接收
        // 这里咱们分析接收线程的处理
        startAcceptorThreads();
    }
}
```

此函数功能比较清晰:

1. 创建了三个队列，processorCache缓存异步移除，eventCache事件缓存，nioChannels缓存接收到的socket
2. 创建线程池
3. 初始化 限流器
4. 创建 poller，此是对接收的socket的具体的处理
5. 启动接收线程

这里咱们主要分析一下接收线程.

> org.apache.tomcat.util.net.AbstractEndpoint#startAcceptorThreads

```java
// 开启接收线程
protected final void startAcceptorThreads() {
    // 默认的接收线程数 为1
    int count = getAcceptorThreadCount();
    acceptors = new Acceptor[count];
    // 创建并启动接收器
    for (int i = 0; i < count; i++) {
        acceptors[i] = createAcceptor();
        String threadName = getName() + "-Acceptor-" + i;
        acceptors[i].setThreadName(threadName);
        Thread t = new Thread(acceptors[i], threadName);
        t.setPriority(getAcceptorThreadPriority());
        //t.setDaemon(getDaemon());
        t.setDaemon(false);
        t.start();
    }
}


@Override
protected AbstractEndpoint.Acceptor createAcceptor() {
    return new Acceptor();
}
```

此处就创建篇接收线程Acceptor，并开始执行。

具体看一下此接收线程做的工作：

> org.apache.tomcat.util.net.NioEndpoint.Acceptor#run

```java
@Override
public void run() {

    int errorDelay = 0;

    // Loop until we receive a shutdown command
    while (running) {

        // Loop if endpoint is paused
        while (paused && running) {
            state = AcceptorState.PAUSED;
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                // Ignore
            }
        }

        if (!running) {
            break;
        }
        state = AcceptorState.RUNNING;

        try {
            //if we have reached max connections, wait
            // 限制连接数
            countUpOrAwaitConnection();
            SocketChannel socket = null;
            try {
                // Accept the next incoming connection from the server
                // socket  接收连接
                socket = serverSock.accept();
            } catch (IOException ioe) {
                // We didn't get a socket
                countDownConnection();
                if (running) {
                    // Introduce delay if necessary
                    errorDelay = handleExceptionWithDelay(errorDelay);
                    // re-throw
                    throw ioe;
                } else {
                    break;
                }
            }
            // Successful accept, reset the error delay
            errorDelay = 0;
            // Configure the socket
            if (running && !paused) {
                // setSocketOptions() will hand the socket off to
                // an appropriate processor if successful
                // todo 对socket进行处理
                if (!setSocketOptions(socket)) {
                    closeSocket(socket);
                }
            } else {
                closeSocket(socket);
            }
        } catch (Throwable t) {
            ExceptionUtils.handleThrowable(t);
            log.error(sm.getString("endpoint.accept.fail"), t);
        }
    }
    state = AcceptorState.ENDED;
}
```

对接收到socket的处理

> org.apache.tomcat.util.net.NioEndpoint#setSocketOptions

```java
// 把socket注册到selector上
protected boolean setSocketOptions(SocketChannel socket) {
    // Process the connection
    try {
        //disable blocking, APR style, we are gonna be polling it
        // 配置socket为非阻塞
        socket.configureBlocking(false);
        // 获取socket
        Socket sock = socket.socket();
        // socket的配置 设置到socket
        socketProperties.setProperties(sock);
        // 去缓存中获取一个 Niochannel
        NioChannel channel = nioChannels.pop();
        // 如果不存在可用的NioChannel
        // 则创建一个
        if (channel == null) {
            SocketBufferHandler bufhandler = new SocketBufferHandler(
                socketProperties.getAppReadBufSize(),
                socketProperties.getAppWriteBufSize(),
                socketProperties.getDirectBuffer());
            if (isSSLEnabled()) {
                // 如果使能了 ssl,则创建 SecureNioChannel
                channel = new SecureNioChannel(socket, bufhandler, selectorPool, this);
            } else {
                // 如果是正常的, 则创建NioChannel
                channel = new NioChannel(socket, bufhandler);
            }
        } else {
            // 存在 channel,则配置channel为新接收的socket
            channel.setIOChannel(socket);
            // reset此channel
            channel.reset();
        }
        // 获取一个poller,把此channel注册到 其中
        // 即 后面的读写操作 就由poller来进行处理了
        getPoller0().register(channel);
    } catch (Throwable t) {
        ExceptionUtils.handleThrowable(t);
        try {
            log.error("",t);
        } catch (Throwable tt) {
            ExceptionUtils.handleThrowable(tt);
        }
        // Tell to close the socket
        return false;
    }
    return true;
}
```

获取poller的方式：

```java
// 获取poller
// 轮询获取
public Poller getPoller0() {
    int idx = Math.abs(pollerRotater.incrementAndGet()) % pollers.length;
    return pollers[idx];
}
```

> org.apache.tomcat.util.net.NioEndpoint.Poller#register

```java
// 注册socket到poller中
public void register(final NioChannel socket) {
    // 更新 socket的poller
    socket.setPoller(this);
    // 使用NioSocketWrapper 封装一下 接收到的socket
    NioSocketWrapper ka = new NioSocketWrapper(socket, NioEndpoint.this);
    socket.setSocketWrapper(ka);
    ka.setPoller(this);
    // 设置 读写超时时间
    ka.setReadTimeout(getSocketProperties().getSoTimeout());
    ka.setWriteTimeout(getSocketProperties().getSoTimeout());
    // 设置是否keepalive
    ka.setKeepAliveLeft(NioEndpoint.this.getMaxKeepAliveRequests());
    // 是否是 ssl 打开
    ka.setSecure(isSSLEnabled());
    // 读写时间  超时, 设置为 connectionTimeout
    ka.setReadTimeout(getConnectionTimeout());
    ka.setWriteTimeout(getConnectionTimeout());
    // 这里对一个socket注册前, 会先去缓存中看是否有可复用的pollerEvent
    PollerEvent r = eventCache.pop();
    // 这里可以看到,当socket进行注册时,感兴趣事件是 OP_READ,而第一次注册的事件OP_REGISTER
    // 那么当下一次此socket准备好时,就会注册op_read事件
    ka.interestOps(SelectionKey.OP_READ);//this is what OP_REGISTER turns into.
    if ( r==null) r = new PollerEvent(socket,ka,OP_REGISTER);
    else r.reset(socket,ka,OP_REGISTER);
    // 发布一个 PollerEvent 事件到队列中
    addEvent(r);
}
```

> org.apache.tomcat.util.net.NioEndpoint.Poller#addEvent

```java
// 发布事件
private void addEvent(PollerEvent event) {
    events.offer(event);
    // 注册完socket后,就立即唤醒一个selector
    // 如果是第一次进行唤醒,则立即进行一次 唤醒操作
    if ( wakeupCounter.incrementAndGet() == 0 ) selector.wakeup();
}
```

到此，一个socket的注册事件就放入到了poller中的事件队列中，后面poller就会检测到此事件，并进行分析。











































































