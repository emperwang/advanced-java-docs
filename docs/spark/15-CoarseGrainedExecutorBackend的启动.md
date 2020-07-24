[TOC]

# CoarseGrainedExecutorBackend

接着上篇，咱们分析一下这个新启动的executor进程做了什么工作。

先看一下其启动方法:

> org.apache.spark.executor.CoarseGrainedExecutorBackend#main

```scala
// executor 真正启动的类
def main(args: Array[String]) {
    var driverUrl: String = null
    var executorId: String = null
    var hostname: String = null
    var cores: Int = 0
    var appId: String = null
    var workerUrl: Option[String] = None
    val userClassPath = new mutable.ListBuffer[URL]()

    var argv = args.toList
    // 参数的解析
    while (!argv.isEmpty) {
        argv match {
            case ("--driver-url") :: value :: tail =>
            driverUrl = value
            argv = tail
            case ("--executor-id") :: value :: tail =>
            executorId = value
            argv = tail
            case ("--hostname") :: value :: tail =>
            hostname = value
            argv = tail
            case ("--cores") :: value :: tail =>
            cores = value.toInt
            argv = tail
            case ("--app-id") :: value :: tail =>
            appId = value
            argv = tail
            case ("--worker-url") :: value :: tail =>
            // Worker url is used in spark standalone mode to enforce fate-sharing with worker
            workerUrl = Some(value)
            argv = tail
            case ("--user-class-path") :: value :: tail =>
            userClassPath += new URL(value)
            argv = tail
            case Nil =>
            case tail =>
            // scalastyle:off println
            System.err.println(s"Unrecognized options: ${tail.mkString(" ")}")
            // scalastyle:on println
            printUsageAndExit()
        }
    }
	// hostname校验
    if (hostname == null) {
        hostname = Utils.localHostName()
        log.info(s"Executor hostname is not provided, will use '$hostname' to advertise itself")
    }
    // 如果没有这三个参数, 打印帮助
    if (driverUrl == null || executorId == null || cores <= 0 || appId == null) {
        printUsageAndExit()
    }
    // executor运行
    // 重点  重点  重点
    run(driverUrl, executorId, hostname, cores, appId, workerUrl, userClassPath)
    System.exit(0)
}
```

> org.apache.spark.executor.CoarseGrainedExecutorBackend#run

```scala
private def run(
    driverUrl: String,
    executorId: String,
    hostname: String,
    cores: Int,
    appId: String,
    workerUrl: Option[String],
    userClassPath: Seq[URL]) {
    // 日志相关的初始化
    Utils.initDaemon(log)
    
    SparkHadoopUtil.get.runAsSparkUser { () =>
        // Debug code
        Utils.checkHost(hostname)

        // Bootstrap to fetch the driver's Spark properties.
        // sparkConf
        val executorConf = new SparkConf
        // 创建一个和driver 交流的 endPoint
        val fetcher = RpcEnv.create(
            "driverPropsFetcher",
            hostname,
            -1,
            executorConf,
            new SecurityManager(executorConf),
            clientMode = true)
        // 和driver交流的endPoint
        val driver = fetcher.setupEndpointRefByURI(driverUrl)
        // 向driver发送  RetrieveSparkAppConfig 消息,来获取app的配置
        val cfg = driver.askSync[SparkAppConfig](RetrieveSparkAppConfig)
        val props = cfg.sparkProperties ++ Seq[(String, String)](("spark.app.id", appId))
        fetcher.shutdown()
        // Create SparkEnv using properties we fetched from the driver.
        val driverConf = new SparkConf()
        for ((key, value) <- props) {
            // this is required for SSL in standalone mode
            if (SparkConf.isExecutorStartupConf(key)) {
                driverConf.setIfMissing(key, value)
            } else {
                driverConf.set(key, value)
            }
        }
        cfg.hadoopDelegationCreds.foreach { tokens =>
            SparkHadoopUtil.get.addDelegationTokens(tokens, driverConf)
        }
        // executor的 rpcEnv
        // 此操作和 SparkContext中创建SparkEnv的操作是一样的
      // 创建了很多重量级的 模块实例
      // 如 blockManager  outputTracker 等
        val env = SparkEnv.createExecutorEnv(
            driverConf, executorId, hostname, cores, cfg.ioEncryptionKey, isLocal = false)
        // 创建 executorBackend
        env.rpcEnv.setupEndpoint("Executor", new CoarseGrainedExecutorBackend(
            env.rpcEnv, driverUrl, executorId, hostname, cores, userClassPath, env))
        workerUrl.foreach { url =>
            env.rpcEnv.setupEndpoint("WorkerWatcher", new WorkerWatcher(env.rpcEnv, url))
        }
        // 防止退出
        env.rpcEnv.awaitTermination()
    }
}
```

> org.apache.spark.executor.CoarseGrainedExecutorBackend

```scala
// executorBackend 主类
private[spark] class CoarseGrainedExecutorBackend(
    override val rpcEnv: RpcEnv,
    driverUrl: String,
    executorId: String,
    hostname: String,
    cores: Int,
    userClassPath: Seq[URL],
    env: SparkEnv)
extends ThreadSafeRpcEndpoint with ExecutorBackend with Logging {
    // 启停标志
    private[this] val stopping = new AtomicBoolean(false)
    var executor: Executor = null
    // 记录此executor 对应的driver endpint
    @volatile var driver: Option[RpcEndpointRef] = None

  // If this CoarseGrainedExecutorBackend is changed to support multiple threads, then this may need
    // to be changed so that we don't share the serializer instance across threads
    private[this] val ser: SerializerInstance = env.closureSerializer.newInstance()

    override def onStart() {
        logInfo("Connecting to driver: " + driverUrl)
        // asyncSetupEndpointRefByURI 和driver的 联通的endpoint
        rpcEnv.asyncSetupEndpointRefByURI(driverUrl).flatMap { ref =>
            // This is a very fast action so we can use "ThreadUtils.sameThread"
            driver = Some(ref)
            // 向driver发送注册RegisterExecutor 的消息
            ref.ask[Boolean](RegisterExecutor(executorId, self, hostname, cores, extractLogUrls))
        }(ThreadUtils.sameThread).onComplete {
            // This is a very fast action so we can use "ThreadUtils.sameThread"
            case Success(msg) =>
            // Always receive `true`. Just ignore it
            case Failure(e) =>
            exitExecutor(1, s"Cannot register with driver: $driverUrl", e, notifyDriver = false)
        }(ThreadUtils.sameThread)
    }
    ... 
}
```

此时向driver发送了RegisterExecutor的消息，下面咱们看一下driver的处理:

> org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.DriverEndpoint#receiveAndReply

```scala
// 接收并回复的 方法
override def receiveAndReply(context: RpcCallContext): PartialFunction[Any, Unit] = {
    // executor 发送过来的 注册executor的消息
    case RegisterExecutor(executorId, executorRef, hostname, cores, logUrls) =>
    // 如果此executor已经注册过,则返回注册失败消息
    if (executorDataMap.contains(executorId)) {
        executorRef.send(RegisterExecutorFailed("Duplicate executor ID: " + executorId))
        context.reply(true)
        // executor所在的host,不在白名单中,则同样注册失败
    } else if (scheduler.nodeBlacklist.contains(hostname)) {
        // If the cluster manager gives us an executor on a blacklisted node (because it
        // already started allocating those resources before we informed it of our blacklist,
        // or if it ignored our blacklist), then we reject that executor immediately.
        logInfo(s"Rejecting $executorId as it has been blacklisted.")
        executorRef.send(RegisterExecutorFailed(s"Executor is blacklisted: $executorId"))
        context.reply(true)
    } else {
        // If the executor's rpc env is not listening for incoming connections, `hostPort`
        // will be null, and the client connection should be used to contact the executor.
        val executorAddress = if (executorRef.address != null) {
            executorRef.address
        } else {
            context.senderAddress
        }
        logInfo(s"Registered executor $executorRef ($executorAddress) with ID $executorId")
        addressToExecutorId(executorAddress) = executorId
        totalCoreCount.addAndGet(cores)
        totalRegisteredExecutors.addAndGet(1)
        val data = new ExecutorData(executorRef, executorAddress, hostname,
                                    cores, cores, logUrls)
        // This must be synchronized because variables mutated
        // in this block are read when requesting executors
        CoarseGrainedSchedulerBackend.this.synchronized {
            executorDataMap.put(executorId, data)
            if (currentExecutorIdCounter < executorId.toInt) {
                currentExecutorIdCounter = executorId.toInt
            }
            if (numPendingExecutors > 0) {
                numPendingExecutors -= 1
                logDebug(s"Decremented number of pending executors ($numPendingExecutors left)")
            }
        }
        // 向executor回复注册消息 RegisteredExecutor
        // 此也表示注册成功
        executorRef.send(RegisteredExecutor)
        // Note: some tests expect the reply to come after we put the executor in the map
        context.reply(true)
        // 向 listenerBus 中发出 SparkListenerExecutorAdded消息
        listenerBus.post(
            SparkListenerExecutorAdded(System.currentTimeMillis(), executorId, data))
  // executor注册了,说明此driver现在有了资源; 如果此driver现在有task则开始遍历task,尝试发送任务到 executor
   // 当时咱们一条龙分析下来,还没有进行任务的提交呢,所以这里 不会有任务
        //  不过可以先知道此处进行 task的分发, 后面也会用到
        makeOffers()
    }
....
}
```

那继续看一下executor对消息RegisteredExecutor的处理:

> org.apache.spark.executor.CoarseGrainedExecutorBackend#receive

```scala
  override def receive: PartialFunction[Any, Unit] = {
        // driver返回的 executor注册成功的消息
    case RegisteredExecutor =>
      logInfo("Successfully registered with driver")
      try {
        // 在这里创建了 线程池
        // 此executor 是具体执行任务的线程池
        // 可以看到,executor注册成功后才会创建线程池,而线程池就是用来真正执行driver发送过来的任务的
        executor = new Executor(executorId, hostname, env, userClassPath, isLocal = false)
      } catch {
        case NonFatal(e) =>
          exitExecutor(1, "Unable to create executor due to " + e.getMessage, e)
      }
.....
  }
```

到这里，executor就注册到driver中了，现在就等待driver来具体发送任务。

































































































