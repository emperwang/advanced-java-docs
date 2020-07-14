[TOC]

# master-webUi启动

前面分析了master的启动流程，本篇分一下master的web相关的初始化以及启动。

在前面分析说到，会创建MasterEndpoint并进行注册，其实在注册MasterEndPoint时，就会创建好此masterEndpoint对应的Inbox(接收消息的队列)，并在此队列中添加一个OnStart消息，这就会导致Master启动后调用OnStart方法，来进行对应的处理。

下面在回顾一下注册MasterEndPoint的方法：

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
    // 就在此启动了webUI
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

>  val masterEndpoint = rpcEnv.setupEndpoint(ENDPOINT_NAME,
>       new Master(rpcEnv, rpcEnv.address, webUiPort, securityMgr, conf))

```scala
override def setupEndpoint(name: String, endpoint: RpcEndpoint): RpcEndpointRef = {
    dispatcher.registerRpcEndpoint(name, endpoint)
}

// 注册endpoint
def registerRpcEndpoint(name: String, endpoint: RpcEndpoint): NettyRpcEndpointRef = {
    val addr = RpcEndpointAddress(nettyEnv.address, name)
    val endpointRef = new NettyRpcEndpointRef(nettyEnv.conf, addr, nettyEnv)
    synchronized {
        if (stopped) {
            throw new IllegalStateException("RpcEnv has been stopped")
        }
        // 把信息存储到 endpoints中
        // 在创建 EndpointData 时,就会放入一个 OnStart消息
        // 注意就是这里，EndpointData 此包含了Inbox
        if (endpoints.putIfAbsent(name, new EndpointData(name, endpoint, endpointRef)) != null) {
            throw new IllegalArgumentException(s"There is already an RpcEndpoint called $name")
        }
        // 把存储后的信息取出
        val data = endpoints.get(name)
        // 在 endpointRefs放入一份
        endpointRefs.put(data.endpoint, data.ref)
        // 因为创建的新的data 是有消息的,故这里吧有消息的EndpointData 放入receivers中
        receivers.offer(data)  // for the OnStart message
    }
    endpointRef
}
```

```scala
  private class EndpointData(
      val name: String,
      val endpoint: RpcEndpoint,
      val ref: NettyRpcEndpointRef) {
    val inbox = new Inbox(ref, endpoint)
  }
```

Inbox的构造函数以及方法体：

```scala
// 构造函数
private[netty] class Inbox(
    val endpointRef: NettyRpcEndpointRef,
    val endpoint: RpcEndpoint)  extends Logging 

/// 方法体
  inbox =>  // Give this an alias so we can use it more clearly in closures.
  // messages 保存接收的消息
  @GuardedBy("this")
  protected val messages = new java.util.LinkedList[InboxMessage]()

  /** True if the inbox (and its associated endpoint) is stopped. */
  @GuardedBy("this")
  private var stopped = false

  /** Allow multiple threads to process messages at the same time. */
  @GuardedBy("this")
  private var enableConcurrent = false

  /** The number of threads processing messages for this inbox. */
  @GuardedBy("this")
  private var numActiveThreads = 0

  // OnStart should be the first message to process
  // 在Inbox初始化就添加了一个 OnStart的消息等待处理
// 注意喽, 就是在这里添加了消息*****************************
  inbox.synchronized {
    messages.add(OnStart)
  }
```

之后master启动， 就会调用OnStart方法：

> org.apache.spark.deploy.master.Master#onStart

```scala
// 初始化后 就会调用的方法; 因为Master是一个RpcEndpoint其对应有一个Inbox
  // 在Inbox初始化就会添加一个 InStart消息等待处理
  override def onStart(): Unit = {
    // 日志信息打印
    logInfo("Starting Spark master at " + masterUrl)
    logInfo(s"Running Spark version ${org.apache.spark.SPARK_VERSION}")
    // 添加webUi的一些handler; post关闭app 以及driver的servlet
    // webUi 的初始化**************************************
    webUi = new MasterWebUI(this, webUiPort)
    // 这里对web进行端口绑定时, 就会启动jetty server
    webUi.bind()
    masterWebUiUrl = "http://" + masterPublicAddress + ":" + webUi.boundPort
    if (reverseProxy) {
      masterWebUiUrl = conf.get("spark.ui.reverseProxyUrl", masterWebUiUrl)
      webUi.addProxy()
      logInfo(s"Spark Master is acting as a reverse proxy. Master, Workers and " +
       s"Applications UIs are available at $masterWebUiUrl")
    }
    // 这里启动一个定时线程
    // CheckForWorkerTimeOut 表示消息
    // self.send 发送检测 worker的消息; 默认定时 60s发送一次
    checkForWorkerTimeOutTask = forwardMessageThread.scheduleAtFixedRate(new Runnable {
      override def run(): Unit = Utils.tryLogNonFatalError {
        self.send(CheckForWorkerTimeOut)
      }
    }, 0, WORKER_TIMEOUT_MS, TimeUnit.MILLISECONDS)

    if (restServerEnabled) {
      val port = conf.getInt("spark.master.rest.port", 6066)
      restServer = Some(new StandaloneRestServer(address.host, port, conf, self, masterUrl))
    }
    // rest Server的启动， 通过REST api来提交任务
    restServerBoundPort = restServer.map(_.start())
    // 监测 系统的启动
    masterMetricsSystem.registerSource(masterSource)
    masterMetricsSystem.start()
    applicationMetricsSystem.start()
    // Attach the master and app metrics servlet handler to the web ui after the metrics systems are
    // started.
    masterMetricsSystem.getServletHandlers.foreach(webUi.attachHandler)
    applicationMetricsSystem.getServletHandlers.foreach(webUi.attachHandler)
    // 序列化
    val serializer = new JavaSerializer(conf)
    // 根据选择的 RECOVERY_MODE(恢复模式) 的不同,创建不同的 序列化引擎(persistenceEngine_)
    // 以及leader选举客户端(leaderElectionAgent_)
    val (persistenceEngine_, leaderElectionAgent_) = RECOVERY_MODE match {
      case "ZOOKEEPER" =>
        logInfo("Persisting recovery state to ZooKeeper")
        val zkFactory =
          new ZooKeeperRecoveryModeFactory(conf, serializer)
        (zkFactory.createPersistenceEngine(), zkFactory.createLeaderElectionAgent(this))
      case "FILESYSTEM" =>
        val fsFactory =
          new FileSystemRecoveryModeFactory(conf, serializer)
        (fsFactory.createPersistenceEngine(), fsFactory.createLeaderElectionAgent(this))
      case "CUSTOM" =>
        val clazz = Utils.classForName(conf.get("spark.deploy.recoveryMode.factory"))
        val factory = clazz.getConstructor(classOf[SparkConf], classOf[Serializer])
          .newInstance(conf, serializer)
          .asInstanceOf[StandaloneRecoveryModeFactory]
        (factory.createPersistenceEngine(), factory.createLeaderElectionAgent(this))
      case _ =>
        (new BlackHolePersistenceEngine(), new MonarchyLeaderAgent(this))
    }
    persistenceEngine = persistenceEngine_
    leaderElectionAgent = leaderElectionAgent_
  }
```

```scala
// 构造函数 以及 函数体
private[master]
class MasterWebUI(val master: Master,requestedPort: Int)  extends WebUI(master.securityMgr, master.securityMgr.getSSLOptions("standalone"), requestedPort, master.conf, name = "MasterUI") with Logging {
    // 函数体
  val masterEndpointRef = master.self
    // 是否是能 前台kill
  val killEnabled = master.conf.getBoolean("spark.ui.killEnabled", true)
  // webui的初始化
  initialize()

  /** Initialize all components of the server. */
    // 初始化时,会添加 html页面
  def initialize() {
      // master的 html页面的构造
    val masterPage = new MasterPage(this)
      // application html页面的构造
    attachPage(new ApplicationPage(this))
    attachPage(masterPage)
      // 添加一个Servlet来处理静态资源
    addStaticHandler(MasterWebUI.STATIC_RESOURCE_DIR)
      // 处理app-kill driver-kill 的servlet
    attachHandler(createRedirectHandler(
      "/app/kill", "/", masterPage.handleAppKillRequest, httpMethods = Set("POST")))
    attachHandler(createRedirectHandler(
      "/driver/kill", "/", masterPage.handleDriverKillRequest, httpMethods = Set("POST")))
  }
```

html页面的构建:

具体可以看一下类:

> org.apache.spark.deploy.master.ui.MasterPage
>
> org/apache/spark/deploy/master/ui/ApplicationPage.scala:31

里面是使用字符串组装的HTML页面。

handler创建，page绑定完，就可以对webUi进行端口的绑定了：

>  // 这里对web进行端口绑定时, 就会启动jetty server
>     webUi.bind()

```scala
def bind(): Unit = {
    assert(serverInfo.isEmpty, s"Attempted to bind $className more than once!")
    try {
      val host = Option(conf.getenv("SPARK_LOCAL_IP")).getOrElse("0.0.0.0")
      /** startJettyServer: jetty server started */
      // 启动jetty
      serverInfo = Some(startJettyServer(host, port, sslOptions, handlers, conf, name))
      logInfo(s"Bound $className to $host, and started at $webUrl")
    } catch {
      case e: Exception =>
        logError(s"Failed to bind $className", e)
        System.exit(1)
    }
  }
```

jettyServer的启动：

```scala
// jetty server的启动
// 大多都是  jetty的api,直接启动一个jetty
def startJettyServer(
    hostName: String,
    port: Int,
    sslOptions: SSLOptions,
    handlers: Seq[ServletContextHandler],
    conf: SparkConf,
    serverName: String = ""): ServerInfo = {
    // 添加过滤器
    addFilters(handlers, conf)
    // Start the server first, with no connectors.
    // 线程池
    val pool = new QueuedThreadPool
    if (serverName.nonEmpty) {
        pool.setName(serverName)
    }
    pool.setDaemon(true)
	// server的创建
    val server = new Server(pool)
	// 异常handler
    val errorHandler = new ErrorHandler()
    errorHandler.setShowStacks(true)
    errorHandler.setServer(server)
    server.addBean(errorHandler)

    val collection = new ContextHandlerCollection
    server.setHandler(collection)

    // Executor used to create daemon threads for the Jetty connectors.
    val serverExecutor = new ScheduledExecutorScheduler(s"$serverName-JettyScheduler", true)
    try {
        // sever启动
        server.start()
        // As each acceptor and each selector will use one thread, the number of threads should at
        // least be the number of acceptors and selectors plus 1. (See SPARK-13776)
        var minThreads = 1
        // 创建连接器connector 的方法
        def newConnector(
            connectionFactories: Array[ConnectionFactory],
            port: Int): (ServerConnector, Int) = {
            val connector = new ServerConnector(
                server,
                null,
                serverExecutor,
                null,
                -1,
                -1,
                connectionFactories: _*)
            connector.setPort(port)
            connector.setHost(hostName)
            connector.setReuseAddress(!Utils.isWindows)

            // Currently we only use "SelectChannelConnector"
            // Limit the max acceptor number to 8 so that we don't waste a lot of threads
            connector.setAcceptQueueSize(math.min(connector.getAcceptors, 8))
			// 连接器启动
            connector.start()
            // The number of selectors always equals to the number of acceptors
            minThreads += connector.getAcceptors * 2
            (connector, connector.getLocalPort())
        }
        // httpConfig
        val httpConfig = new HttpConfiguration()
        val requestHeaderSize = conf.get(UI_REQUEST_HEADER_SIZE).toInt
        logDebug(s"Using requestHeaderSize: $requestHeaderSize")
        httpConfig.setRequestHeaderSize(requestHeaderSize)
        // If SSL is configured, create the secure connector first.
        // SSL 相关配置
        val securePort = sslOptions.createJettySslContextFactory().map { factory =>
           val securePort = sslOptions.port.getOrElse(if (port > 0) Utils.userPort(port, 400) else 0)
            val secureServerName = if (serverName.nonEmpty) s"$serverName (HTTPS)" else serverName
            val connectionFactories = AbstractConnectionFactory.getFactories(factory,
                   new HttpConnectionFactory(httpConfig))
            def sslConnect(currentPort: Int): (ServerConnector, Int) = {
                newConnector(connectionFactories, currentPort)
            }
            val (connector, boundPort) = Utils.startServiceOnPort[ServerConnector](securePort,
                          sslConnect, conf, secureServerName)
            connector.setName(SPARK_CONNECTOR_NAME)
            server.addConnector(connector)
            boundPort
        }

        // Bind the HTTP port.
        // http的 connector创建
        def httpConnect(currentPort: Int): (ServerConnector, Int) = {
            newConnector(Array(new HttpConnectionFactory(httpConfig)), currentPort)
        }

        val (httpConnector, httpPort) = Utils.startServiceOnPort[ServerConnector](port, httpConnect,
                                                                          conf, serverName)
        // If SSL is configured, then configure redirection in the HTTP connector.
        securePort match {
            case Some(p) =>
            httpConnector.setName(REDIRECT_CONNECTOR_NAME)
            val redirector = createRedirectHttpsHandler(p, "https")
            collection.addHandler(redirector)
            redirector.start()
            case None =>
            httpConnector.setName(SPARK_CONNECTOR_NAME)
        }
		// 添加连接器
        server.addConnector(httpConnector)
        // Add all the known handlers now that connectors are configured.
        handlers.foreach { h =>
            h.setVirtualHosts(toVirtualHosts(SPARK_CONNECTOR_NAME))
            val gzipHandler = new GzipHandler()
            gzipHandler.setHandler(h)
            collection.addHandler(gzipHandler)
            gzipHandler.start()
        }
        pool.setMaxThreads(math.max(pool.getMaxThreads, minThreads))
        // 返回创建的server信息
        ServerInfo(server, httpPort, securePort, conf, collection)
    } catch {
        case e: Exception =>
        server.stop()
        if (serverExecutor.isStarted()) {
            serverExecutor.stop()
        }
        if (pool.isStarted()) {
            pool.stop()
        }
        throw e
    }
}
```

如果没有配置代理，到这里webUi就启动完成了。