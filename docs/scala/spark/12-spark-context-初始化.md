[TOC]

# SparkContext的初始化

上篇提到SparkSession的初始化，在其初始化过程中，也创建了SparkContext，本篇就来分析一下SparkContext的初始化。

上篇回顾：

> org.apache.spark.sql.SparkSession.Builder#getOrCreate

```scala
// 函数进行了省略，只看关键部分
def getOrCreate(): SparkSession = synchronized {
	.....
      // Global synchronization so we will only set the default session once.
      SparkSession.synchronized {
        // No active nor global default session. Create a new one.
        val sparkContext = userSuppliedContext.getOrElse {
          // 创建 sparkConf
          val sparkConf = new SparkConf()
          // 把options中的配置 设置到 sparkConf中
          options.foreach { case (k, v) => sparkConf.set(k, v) }

          // set a random app name if not given.
          // 如果没有设置 app.name,则设置一个随机的name
          if (!sparkConf.contains("spark.app.name")) {
            sparkConf.setAppName(java.util.UUID.randomUUID().toString)
          }
          // 创建 sparkContext
          SparkContext.getOrCreate(sparkConf)
          // Do not update `SparkConf` for existing `SparkContext`, as it's shared by all sessions.
        }
	.....
      return session
    }
```

> org.apache.spark.SparkContext#getOrCreate

```scala
  def getOrCreate(config: SparkConf): SparkContext = {
    // Synchronize to ensure that multiple create requests don't trigger an exception
    // from assertNoOtherContextIsRunning within setActiveContext
    SPARK_CONTEXT_CONSTRUCTOR_LOCK.synchronized {
      // 如果全局的sparkContext 为null, 则创建一个,并保存到activeContext
      if (activeContext.get() == null) {
        setActiveContext(new SparkContext(config), allowMultipleContexts = false)
      } else {
        if (config.getAll.nonEmpty) {
          logWarning("Using an existing SparkContext; some configuration may not take effect.")
        }
      }
      // 获取全局的sparkContext
      activeContext.get()
    }
  }
```

sparkContext的构造函数： 这里很重要~~~~

```scala
class SparkContext(config: SparkConf) extends Logging {
    private val creationSite: CallSite = Utils.getCallSite()
    // If true, log warnings instead of throwing exceptions when multiple SparkContexts are active
    private val allowMultipleContexts: Boolean =
    config.getBoolean("spark.driver.allowMultipleContexts", false)
    SparkContext.markPartiallyConstructed(this, allowMultipleContexts)
    // 记录开始时间
    val startTime = System.currentTimeMillis()
    // 停止标志位
    private[spark] val stopped: AtomicBoolean = new AtomicBoolean(false)

    // 重要field 指定初始值
    // sparkConf
    private var _conf: SparkConf = _
    private var _eventLogDir: Option[URI] = None
    private var _eventLogCodec: Option[String] = None
    // 监听总线
    private var _listenerBus: LiveListenerBus = _
    // 
    private var _env: SparkEnv = _
    private var _statusTracker: SparkStatusTracker = _
    private var _progressBar: Option[ConsoleProgressBar] = None
    // ui
    private var _ui: Option[SparkUI] = None
    private var _hadoopConfiguration: Configuration = _
    // executor的内存
    private var _executorMemory: Int = _
    // 重要   driver的backend,driver就是通过此backend 来实现了对 executor的控制
    private var _schedulerBackend: SchedulerBackend = _
    // 重要   taskScheduler 
    private var _taskScheduler: TaskScheduler = _
    // 心跳检测
    private var _heartbeatReceiver: RpcEndpointRef = _
    // DAG scheduler , 此会分析提交的任务,并创建DAG图,并提交stage 到 driver
    @volatile private var _dagScheduler: DAGScheduler = _
    // 
    private var _applicationId: String = _
    private var _applicationAttemptId: Option[String] = None
    private var _eventLogger: Option[EventLoggingListener] = None
    private var _executorAllocationManager: Option[ExecutorAllocationManager] = None
    private var _cleaner: Option[ContextCleaner] = None
    private var _listenerBusStarted: Boolean = false
    // jar包
    private var _jars: Seq[String] = _
    private var _files: Seq[String] = _
    // shutdown 回调
    private var _shutdownHookRef: AnyRef = _
    private var _statusStore: AppStatusStore = _


    private[spark] val addedFiles = new ConcurrentHashMap[String, Long]().asScala
    private[spark] val addedJars = new ConcurrentHashMap[String, Long]().asScala

    // Keeps track of all persisted RDDs
    private[spark] val persistentRdds = {
        val map: ConcurrentMap[Int, RDD[_]] = new MapMaker().weakValues().makeMap[Int, RDD[_]]()
        map.asScala
    }
    // Environment variables to pass to our executors.
    private[spark] val executorEnvs = HashMap[String, String]()

    // Set SPARK_USER for user who is running SparkContext.
    val sparkUser = Utils.getCurrentUserName()

    private[spark] var checkpointDir: Option[String] = None

    // Thread Local variable that can be used by users to pass information down the stack
    protected[spark] val localProperties = new InheritableThreadLocal[Properties] {
        override protected def childValue(parent: Properties): Properties = {
            // Note: make a clone such that changes in the parent properties aren't reflected in
            // the those of the children threads, which has confusing semantics (SPARK-10563).
            SerializationUtils.clone(parent)
        }
        override protected def initialValue(): Properties = new Properties()
    }

    // 下一个shuffle 编号
    private val nextShuffleId = new AtomicInteger(0)
    // 下一个 RDD 编号
    private val nextRddId = new AtomicInteger(0)
    
    // todo ------重要------
    // 在此try中的初始化操作,有 dagSchedular 以及 taskSchedular的初始化
    // sparkContext 初始化的 精华全在这里了
  // 这里做了很多的工作, 一篇文章肯定是写不完了,所有重要的操作, 都会在这里点出来,后面文章会挨个分析各个点出的重点
    try {
        // 可以看到此 配置 就是构造函数传递进来的
        _conf = config.clone()
        // 校验 配置
        _conf.validateSettings()
		// 可见在 conf中是必须带 spark.master的
        if (!_conf.contains("spark.master")) {
            throw new SparkException("A master URL must be set in your configuration")
        }
        // app的name也是必须指定的
        if (!_conf.contains("spark.app.name")) {
            throw new SparkException("An application name must be set in your configuration")
        }

        // log out spark.app.name in the Spark driver logs
        logInfo(s"Submitted application: $appName")

        // System property spark.yarn.app.id must be set if user code ran by AM on a YARN cluster
        if (master == "yarn" && deployMode == "cluster" && !_conf.contains("spark.yarn.app.id")) {
            throw new SparkException("Detected yarn cluster mode, but isn't running on a cluster. " +
           "Deployment to YARN is not supported directly by SparkContext. Please use spark-submit.")
        }
        if (_conf.getBoolean("spark.logConf", false)) {
            logInfo("Spark configuration:\n" + _conf.toDebugString)
        }
        // Set Spark driver host and port system properties. This explicitly sets the configuration
        // instead of relying on the default value of the config constant.
        // driver地址的设置, 默认值是 本地主机的地址
        _conf.set(DRIVER_HOST_ADDRESS, _conf.get(DRIVER_HOST_ADDRESS))
        // 设置driver的 端口
        _conf.setIfMissing("spark.driver.port", "0")
		// 设置driver的 id
        _conf.set("spark.executor.id", SparkContext.DRIVER_IDENTIFIER)
        // jars 同样是从  conf中来读取
        _jars = Utils.getUserJars(_conf)
        // spark.files
        _files = _conf.getOption("spark.files").map(_.split(",")).map(_.filter(_.nonEmpty))
        .toSeq.flatten
		// 
        _eventLogDir =
        if (isEventLogEnabled) {
            val unresolvedDir = conf.get("spark.eventLog.dir", EventLoggingListener.DEFAULT_LOG_DIR)
            .stripSuffix("/")
            Some(Utils.resolveURI(unresolvedDir))
        } else {
            None
        }
		// log 压缩
        _eventLogCodec = {
            val compress = _conf.getBoolean("spark.eventLog.compress", false)
            if (compress && isEventLogEnabled) {
                Some(CompressionCodec.getCodecName(_conf)).map(CompressionCodec.getShortName)
            } else {
                None
            }
        }
		// 监听总线的初始化
        _listenerBus = new LiveListenerBus(_conf)

        // Initialize the app status store and listener before SparkEnv is created so that it gets
        // all events.
        _statusStore = AppStatusStore.createLiveStore(conf)
        listenerBus.addToStatusQueue(_statusStore.listener.get)

        // Create the Spark execution environment (cache, map output tracker, etc)
        // sparkEnv的创建
        // ******** 重要 重要  重要 *********
       // 在这里创建了所有需要的实例 并记录其引用; 如 blockManager  shuffleManager outputTracker 等重要模块
        _env = createSparkEnv(_conf, isLocal, listenerBus)
        SparkEnv.set(_env)

        // If running the REPL, register the repl's output dir with the file server.
        _conf.getOption("spark.repl.class.outputDir").foreach { path =>
            val replUri = _env.rpcEnv.fileServer.addDirectory("/classes", new File(path))
            _conf.set("spark.repl.class.uri", replUri)
        }
		// SparkStatusTracker 初始化
        _statusTracker = new SparkStatusTracker(this, _statusStore)

        _progressBar =
        if (_conf.get(UI_SHOW_CONSOLE_PROGRESS) && !log.isInfoEnabled) {
            Some(new ConsoleProgressBar(this))
        } else {
            None
        }
	// SparkUi的创建
        _ui =
        if (conf.getBoolean("spark.ui.enabled", true)) {
            Some(SparkUI.create(Some(this), _statusStore, _conf, _env.securityManager, appName, "",
                                startTime))
        } else {
            // For tests, do not enable the UI
            None
        }
        // Bind the UI before starting the task scheduler to communicate
        // the bound port to the cluster manager properly
        // SparkUi的地址的绑定
        _ui.foreach(_.bind())
		// hadoop相关配置的设置
        _hadoopConfiguration = SparkHadoopUtil.get.newConfiguration(_conf)

        // Add each JAR given through the constructor
        if (jars != null) {
            jars.foreach(addJar)
        }

        if (files != null) {
            files.foreach(addFile)
        }
        // 获取executor内存; 从这里可以看到 其获取配置的顺序
        _executorMemory = _conf.getOption("spark.executor.memory")
        .orElse(Option(System.getenv("SPARK_EXECUTOR_MEMORY")))
        .orElse(Option(System.getenv("SPARK_MEM"))
                .map(warnSparkMem))
        .map(Utils.memoryStringToMb)
        .getOrElse(1024)

        // Convert java options to env vars as a work around
        // since we can't set env vars directly in sbt.
        for { (envKey, propKey) <- Seq(("SPARK_TESTING", "spark.testing"))
             value <- Option(System.getenv(envKey)).orElse(Option(System.getProperty(propKey)))} {
            executorEnvs(envKey) = value
        }
        Option(System.getenv("SPARK_PREPEND_CLASSES")).foreach { v =>
            executorEnvs("SPARK_PREPEND_CLASSES") = v
        }
        // The Mesos scheduler backend relies on this environment variable to set executor memory.
        // TODO: Set this only in the Mesos scheduler.
        // 设置executorEnv的环境
        executorEnvs("SPARK_EXECUTOR_MEMORY") = executorMemory + "m"
        executorEnvs ++= _conf.getExecutorEnv
        executorEnvs("SPARK_USER") = sparkUser

        // We need to register "HeartbeatReceiver" before "createTaskScheduler" because Executor will
        // retrieve "HeartbeatReceiver" in the constructor. (SPARK-6640)
        // 检测心跳的 rpcEnv
        _heartbeatReceiver = env.rpcEnv.setupEndpoint(
            HeartbeatReceiver.ENDPOINT_NAME, new HeartbeatReceiver(this))

        // Create and start the scheduler
        //  重要 重要  重要
        // 创建 taskScheduler 和 driver的 backend
        val (sched, ts) = SparkContext.createTaskScheduler(this, master, deployMode)
        // driver的backend 的记录
        _schedulerBackend = sched
        // taskScheduler  的记录
        _taskScheduler = ts
        // 创建 DAGScheduler
        // 重要  重要  重要
        _dagScheduler = new DAGScheduler(this)
        _heartbeatReceiver.ask[Boolean](TaskSchedulerIsSet)

        // start TaskScheduler after taskScheduler sets DAGScheduler reference in DAGScheduler's
        // constructor
        // taskScheduler  开始运行  
        _taskScheduler.start()
        // 从taskScheduler 来获取 application的id 以及 attemptId
        _applicationId = _taskScheduler.applicationId()
        _applicationAttemptId = taskScheduler.applicationAttemptId()
        // 保存一下app.id
        _conf.set("spark.app.id", _applicationId)
        if (_conf.getBoolean("spark.ui.reverseProxy", false)) {
            System.setProperty("spark.ui.proxyBase", "/proxy/" + _applicationId)
        }
        _ui.foreach(_.setAppId(_applicationId))
        //
        _env.blockManager.initialize(_applicationId)

        // The metrics system for Driver need to be set spark.app.id to app ID.
        // So it should start after we get app ID from the task scheduler and set spark.app.id.
        // 指标系统启动
        _env.metricsSystem.start()
    // Attach the driver metrics servlet handler to the web ui after the metrics system is started.
        _env.metricsSystem.getServletHandlers.foreach(handler => ui.foreach(_.attachHandler(handler)))

        _eventLogger =
        if (isEventLogEnabled) {
            val logger =
            new EventLoggingListener(_applicationId, _applicationAttemptId, _eventLogDir.get,
                                     _conf, _hadoopConfiguration)
            logger.start()
            listenerBus.addToEventLogQueue(logger)
            Some(logger)
        } else {
            None
        }
        // Optionally scale number of executors dynamically based on workload. Exposed for testing.
        val dynamicAllocationEnabled = Utils.isDynamicAllocationEnabled(_conf)
        _executorAllocationManager =
        if (dynamicAllocationEnabled) {
            schedulerBackend match {
                case b: ExecutorAllocationClient =>
                Some(new ExecutorAllocationManager(
                    schedulerBackend.asInstanceOf[ExecutorAllocationClient], listenerBus, _conf,
                    _env.blockManager.master))
                case _ =>
                None
            }
        } else {
            None
        }
        _executorAllocationManager.foreach(_.start())

        _cleaner =
        if (_conf.getBoolean("spark.cleaner.referenceTracking", true)) {
            Some(new ContextCleaner(this))
        } else {
            None
        }
        _cleaner.foreach(_.start())
		// 设置并启动 listenerBus
        setupAndStartListenerBus()
        // 
        postEnvironmentUpdate()
        // 
        postApplicationStart()

        // Post init
        _taskScheduler.postStartHook()
        // 向指标系统中注册 指标资源
        _env.metricsSystem.registerSource(_dagScheduler.metricsSource)
        _env.metricsSystem.registerSource(new BlockManagerSource(_env.blockManager))
        _executorAllocationManager.foreach { e =>
            _env.metricsSystem.registerSource(e.executorAllocationManagerSource)
        }
        // Make sure the context is stopped if the user forgets about it. This avoids leaving
        // unfinished event logs around after the JVM exits cleanly. It doesn't help if the JVM
        // is killed, though.
        logDebug("Adding shutdown hook") // force eager creation of logger
        // 关闭的回调函数
        _shutdownHookRef = ShutdownHookManager.addShutdownHook(
            ShutdownHookManager.SPARK_CONTEXT_SHUTDOWN_PRIORITY) { () =>
            logInfo("Invoking stop() from shutdown hook")
            try {
                stop()
            } catch {
                case e: Throwable =>
                logWarning("Ignoring Exception while stopping SparkContext from shutdown hook", e)
            }
        }
    } catch {
        case NonFatal(e) =>
        logError("Error initializing SparkContext.", e)
        try {
            stop()
        } catch {
            case NonFatal(inner) =>
            logError("Error stopping SparkContext after init error.", inner)
        } finally {
            throw e
        }
    }  
}
```

此函数真的是干活满满，做了很多的工作，小结一下：

1. 保存sparkConf
2. driver地址的设置
3.  LiveListenerBus 的创建
4. 在createSparkEnv中创建了很多其他重要的模块，如: BlockManager  shuffleManager outputTracker 等，具体可以看代码
5.  SparkStatusTracker的创建
6.  sparkUI的创建
7.  HeartbeatReceiver 的创建及 注册
8. 在 SparkContext.createTaskScheduler中创建了 taskScheduler以及 schedulerbackend，这是两个非常重要的类，driver和executor通信就靠这个schedulerBackend以及 任务的调度 靠这个 taskScheduler；会在后面分析这两个类
9.  new DAGScheduler 类的初始化，此会根据提交的任务分析出DAG图，也就是切分 stage，并把 stage提交到driver
10. 当前还有 metricsSystem的 初始化 以及启动

到此sparkContext就初始化完成了，可见真的是做了好多工作，后面咱们在慢慢分析sparkContext中做的其他工作。





































