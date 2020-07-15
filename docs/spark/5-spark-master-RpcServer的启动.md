[TOC]

# master rpc的创建

rpcServer的启动：

```scala
  def startRpcEnvAndEndpoint(
      host: String,
      port: Int,
      webUiPort: Int,
      conf: SparkConf): (RpcEnv, Int, Option[Int]) = {
    val securityMgr = new SecurityManager(conf)
    // 创建rpcEnv
    // 1. dispatcher 用于分发消息
    // 2. 创建 master rpc server
    // ******** 重点 ***  rpc server的创建 以及 绑定
    val rpcEnv = RpcEnv.create(SYSTEM_NAME, host, port, conf, securityMgr)
    // 设置 endPoint; 也就是把 Master注册到 dispatcher
    // 这里真正创建了Master
    // 注册 master的RpcEndpoint 到 dispatcher
    val masterEndpoint = rpcEnv.setupEndpoint(ENDPOINT_NAME,
      new Master(rpcEnv, rpcEnv.address, webUiPort, securityMgr, conf))
    // MasterEndpoint 发送消息 BoundPortsRequest  端口绑定请求
    val portsResponse = masterEndpoint.askSync[BoundPortsResponse](BoundPortsRequest)
    (rpcEnv, portsResponse.webUIPort, portsResponse.restPort)
  }
```

```scala
def create(
      name: String,
      host: String,
      port: Int,
      conf: SparkConf,
      securityManager: SecurityManager,
      clientMode: Boolean = false): RpcEnv = {
    create(name, host, host, port, conf, securityManager, 0, clientMode)
  }

  def create(
      name: String,
      bindAddress: String,
      advertiseAddress: String,
      port: Int,
      conf: SparkConf,
      securityManager: SecurityManager,
      numUsableCores: Int,
      clientMode: Boolean): RpcEnv = {
    // 使用RpcEnvConfig吧参数封装起来
    val config = RpcEnvConfig(conf, name, bindAddress, advertiseAddress, port, securityManager,
      numUsableCores, clientMode)
    // 此处会创建 server-即 master的rpc
    new NettyRpcEnvFactory().create(config) // 使用NettyRpcEnvFactory工厂类创建
  }
```



```scala
def create(config: RpcEnvConfig): RpcEnv = {
    val sparkConf = config.conf
    // Use JavaSerializerInstance in multiple threads is safe. However, if we plan to support
    // KryoSerializer in future, we have to use ThreadLocal to store SerializerInstance
    // 序列化方式
    val javaSerializerInstance =
      new JavaSerializer(sparkConf).newInstance().asInstanceOf[JavaSerializerInstance]
    // NettyRpcEnv 其保存了各个RpcEndpoint 以及 Dispatcher(用于发送消息)
    val nettyEnv =
      new NettyRpcEnv(sparkConf, javaSerializerInstance, config.advertiseAddress,
        config.securityManager, config.numUsableCores)
    // 这里相当于定义了一个启动 server的函数
    if (!config.clientMode) {
      val startNettyRpcEnv: Int => (NettyRpcEnv, Int) = { actualPort =>
        nettyEnv.startServer(config.bindAddress, actualPort)
        (nettyEnv, nettyEnv.address.port)
      }
      try {
        // 此处才是真实调用上面 创建的启动server函数的地方
          // 也就是说 这里启动了 master rpc
        Utils.startServiceOnPort(config.port, startNettyRpcEnv, sparkConf, config.name)._1
      } catch {
        case NonFatal(e) =>
          nettyEnv.shutdown()
          throw e
      }
    }
    nettyEnv
  }
}
```

NettyRpcEnv的初始化

```scala
private[netty] class NettyRpcEnv(
    val conf: SparkConf,
    javaSerializerInstance: JavaSerializerInstance,
    host: String,
    securityManager: SecurityManager,
    numUsableCores: Int) extends RpcEnv(conf) with Logging {

  private[netty] val transportConf = SparkTransportConf.fromSparkConf(
    conf.clone.set("spark.rpc.io.numConnectionsPerPeer", "1"),
    "rpc",
    conf.getInt("spark.rpc.io.threads", numUsableCores))
  // 创建dispatcher,  保存各个 RpcEndpoint 并对消息进行路由
  private val dispatcher: Dispatcher = new Dispatcher(this, numUsableCores)

  private val streamManager = new NettyStreamManager(this)
  // TransportContext是和netty连接的关键类
   // NettyRpcHandler 对netty接收消息的具体处理类
  private val transportContext = new TransportContext(transportConf,
    new NettyRpcHandler(dispatcher, this, streamManager))

  private def createClientBootstraps(): java.util.List[TransportClientBootstrap] = {
    if (securityManager.isAuthenticationEnabled()) {
      java.util.Arrays.asList(new AuthClientBootstrap(transportConf,
        securityManager.getSaslUser(), securityManager))
    } else {
      java.util.Collections.emptyList[TransportClientBootstrap]
    }
  }
 // client 连接的工厂方法
  private val clientFactory = transportContext.createClientFactory(createClientBootstraps())

  @volatile private var fileDownloadFactory: TransportClientFactory = _
    // 单个后台定时线程池
  val timeoutScheduler = ThreadUtils.newDaemonSingleThreadScheduledExecutor("netty-rpc-env-timeout")

  // Because TransportClientFactory.createClient is blocking, we need to run it in this thread pool
  // 客户端的连接线程池
  // 和其他 节点连接的endpoint 都存储在这里
  private[netty] val clientConnectionExecutor = ThreadUtils.newDaemonCachedThreadPool(
    "netty-rpc-connection",
    conf.getInt("spark.rpc.connect.threads", 64))
	// master server
  @volatile private var server: TransportServer = _
    // 是否停止的标志
  private val stopped = new AtomicBoolean(false)

  /**
   * A map for [[RpcAddress]] and [[Outbox]]. When we are connecting to a remote [[RpcAddress]],
   * we just put messages to its [[Outbox]] to implement a non-blocking `send` method.
   */
    // 发送消息的队列
  private val outboxes = new ConcurrentHashMap[RpcAddress, Outbox]()
```

```scala
def startServiceOnPort[T](
    startPort: Int,
    startService: Int => (T, Int),
    conf: SparkConf,
    serviceName: String = ""): (T, Int) = {

    require(startPort == 0 || (1024 <= startPort && startPort < 65536),
            "startPort should be between 1024 and 65535 (inclusive), or 0 for a random free port.")

    val serviceString = if (serviceName.isEmpty) "" else s" '$serviceName'"
    // 端口的重试次数
    val maxRetries = portMaxRetries(conf)
    for (offset <- 0 to maxRetries) {
   // Do not increment port if startPort is 0, which is treated as a special port
   val tryPort = if (startPort == 0) {
            startPort
        } else {
            userPort(startPort, offset)
        }
        try {
            // 调用回调方法来启动 rpcServer
            val (service, port) = startService(tryPort)
            logInfo(s"Successfully started service$serviceString on port $port.")
            return (service, port)
        } catch {
            case e: Exception if isBindCollision(e) =>
            if (offset >= maxRetries) {
                val exceptionMessage = if (startPort == 0) {
                    s"${e.getMessage}: Service$serviceString failed after " +
                    s"$maxRetries retries (on a random free port)! " +
                    s"Consider explicitly setting the appropriate binding address for " +
                    s"the service$serviceString (for example spark.driver.bindAddress " +
                    s"for SparkDriver) to the correct binding address."
                } else {
                    s"${e.getMessage}: Service$serviceString failed after " +
                    s"$maxRetries retries (starting from $startPort)! Consider explicitly setting " +
                    s"the appropriate port for the service$serviceString (for example spark.ui.port " +
                    s"for SparkUI) to an available port or increasing spark.port.maxRetries."
                }
                val exception = new BindException(exceptionMessage)
                // restore original stack trace
                exception.setStackTrace(e.getStackTrace)
                throw exception
            }
            if (startPort == 0) {
                // As startPort 0 is for a random free port, it is most possibly binding address is
                // not correct.
                logWarning(s"Service$serviceString could not bind on a random free port. " + "You may check whether configuring an appropriate binding address.")
            } else {
           logWarning(s"Service$serviceString could not bind on port $tryPort. " +
                           s"Attempting port ${tryPort + 1}.")
            }
        }
    }
    // Should never happen
    throw new SparkException(s"Failed to start service$serviceString on port $startPort")
}
```

server的启动方法

```scala
def startServer(bindAddress: String, port: Int): Unit = {
    val bootstraps: java.util.List[TransportServerBootstrap] =
    if (securityManager.isAuthenticationEnabled()) {
        java.util.Arrays.asList(new AuthServerBootstrap(transportConf, securityManager))
    } else {
        java.util.Collections.emptyList()
    }
    // rpc的server,也是 master绑定的地址
    server = transportContext.createServer(bindAddress, port, bootstraps)
    // 注册一个 RpcEndpointVerifier 的endpoint
    dispatcher.registerRpcEndpoint(
        RpcEndpointVerifier.NAME, new RpcEndpointVerifier(this, dispatcher))
}
```



```scala
  public TransportServer createServer(
      String host, int port, List<TransportServerBootstrap> bootstraps) {
    // 创建 TransportServer,其下面是 bootstrapServer
    return new TransportServer(this, host, port, rpcHandler, bootstraps);
  }
```



```scala
  public TransportServer(
      TransportContext context,
      String hostToBind,
      int portToBind,
      RpcHandler appRpcHandler,
      List<TransportServerBootstrap> bootstraps) {
    this.context = context;
    this.conf = context.getConf();
    this.appRpcHandler = appRpcHandler;
    this.bootstraps = Lists.newArrayList(Preconditions.checkNotNull(bootstraps));
    boolean shouldClose = true;
    try {
      // 初始化
      init(hostToBind, portToBind);
      shouldClose = false;
    } finally {
      if (shouldClose) {
        JavaUtils.closeQuietly(this);
      }
    }
  }
```

```scala
  private void init(String hostToBind, int portToBind) {
      // IO的模型,是NIO还是Epoll
    IOMode ioMode = IOMode.valueOf(conf.ioMode());
      // boss线程
    EventLoopGroup bossGroup = NettyUtils.createEventLoop(ioMode, 1,
      conf.getModuleName() + "-boss");
      // 工作线程
    EventLoopGroup workerGroup =  NettyUtils.createEventLoop(ioMode, conf.serverThreads(),
      conf.getModuleName() + "-server");

    PooledByteBufAllocator allocator = NettyUtils.createPooledByteBufAllocator(
      conf.preferDirectBufs(), true /* allowCache */, conf.serverThreads());
    // netty Server的创建
    bootstrap = new ServerBootstrap()
      .group(bossGroup, workerGroup)
      .channel(NettyUtils.getServerChannelClass(ioMode))
      .option(ChannelOption.ALLOCATOR, allocator)
      .option(ChannelOption.SO_REUSEADDR, !SystemUtils.IS_OS_WINDOWS)
      .childOption(ChannelOption.ALLOCATOR, allocator);

    this.metrics = new NettyMemoryMetrics(
      allocator, conf.getModuleName() + "-server", conf);
	// 连接数配置
    if (conf.backLog() > 0) {
      bootstrap.option(ChannelOption.SO_BACKLOG, conf.backLog());
    }
	// 接收buffer
    if (conf.receiveBuf() > 0) {
      bootstrap.childOption(ChannelOption.SO_RCVBUF, conf.receiveBuf());
    }
	// 发送buffer
    if (conf.sendBuf() > 0) {
      bootstrap.childOption(ChannelOption.SO_SNDBUF, conf.sendBuf());
    }
    // 添加自定义的 处理函数
    bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
      @Override
      protected void initChannel(SocketChannel ch) {
        RpcHandler rpcHandler = appRpcHandler;
        for (TransportServerBootstrap bootstrap : bootstraps) {
          rpcHandler = bootstrap.doBootstrap(ch, rpcHandler);
        }
          // 重点  后面解析
        context.initializePipeline(ch, rpcHandler);
      }
    });
    // 创建地址
    InetSocketAddress address = hostToBind == null ?
        new InetSocketAddress(portToBind): new InetSocketAddress(hostToBind, portToBind);
    // 地址绑定 
      // 到此 master的rpc就启动了
    channelFuture = bootstrap.bind(address);
    channelFuture.syncUninterruptibly();
    port = ((InetSocketAddress) channelFuture.channel().localAddress()).getPort();
    logger.debug("Shuffle server started on port: {}", port);
  }
```

到这里，master的rpc就启动完成了。