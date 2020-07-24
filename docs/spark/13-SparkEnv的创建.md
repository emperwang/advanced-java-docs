[TOC]

# SparkEnv创建

根据上篇sparkContext初始化操作中，有一个创建SparkEnv的操作，本篇咱们看一下这个操作做了什么工作。

回顾上篇:

```scala
// sparkEnv的创建
// 重点
// 在这里创建了所有需要的实例 并记录其引用; 如 blockManager  shuffleManager outputTracker 等重要模块
_env = createSparkEnv(_conf, isLocal, listenerBus)
SparkEnv.set(_env)
```

> org.apache.spark.SparkContext#createSparkEnv

```scala
// 重点, 在此创建了Driver中所有需要的其他模块的实例 并记录了其引用
private[spark] def createSparkEnv(
    conf: SparkConf,
    isLocal: Boolean,
    listenerBus: LiveListenerBus): SparkEnv = {
    SparkEnv.createDriverEnv(conf, isLocal, listenerBus, SparkContext.numDriverCores(master, conf))
}
```

> org.apache.spark.SparkEnv#createDriverEnv

```scala
private[spark] def createDriverEnv(
    conf: SparkConf,
    isLocal: Boolean,
    listenerBus: LiveListenerBus,
    numCores: Int,
    mockOutputCommitCoordinator: Option[OutputCommitCoordinator] = None): SparkEnv = {
    assert(conf.contains(DRIVER_HOST_ADDRESS),
           s"${DRIVER_HOST_ADDRESS.key} is not set on the driver!")
    assert(conf.contains("spark.driver.port"), "spark.driver.port is not set on the driver!")
    // driver的地址
    val bindAddress = conf.get(DRIVER_BIND_ADDRESS)
    val advertiseAddress = conf.get(DRIVER_HOST_ADDRESS)
    // driver的端口
    val port = conf.get("spark.driver.port").toInt
    val ioEncryptionKey = if (conf.get(IO_ENCRYPTION_ENABLED)) {
        Some(CryptoStreamUtils.createKey(conf))
    } else {
        None
    }
    create(
        conf,
        SparkContext.DRIVER_IDENTIFIER,
        bindAddress,
        advertiseAddress,
        Option(port),
        isLocal,
        numCores,
        ioEncryptionKey,
        listenerBus = listenerBus,
        mockOutputCommitCoordinator = mockOutputCommitCoordinator
    )
}
```



```scala
private def create(
    conf: SparkConf,
    executorId: String,
    bindAddress: String,
    advertiseAddress: String,
    port: Option[Int],
    isLocal: Boolean,
    numUsableCores: Int,
    ioEncryptionKey: Option[Array[Byte]],
    listenerBus: LiveListenerBus = null,
    mockOutputCommitCoordinator: Option[OutputCommitCoordinator] = None): SparkEnv = {

    val isDriver = executorId == SparkContext.DRIVER_IDENTIFIER

    // Listener bus is only used on the driver
    if (isDriver) {
        assert(listenerBus != null, "Attempted to create driver SparkEnv with null listener bus!")
    }

    val securityManager = new SecurityManager(conf, ioEncryptionKey)
    if (isDriver) {
        securityManager.initializeAuth()
    }

    ioEncryptionKey.foreach { _ =>
        if (!securityManager.isEncryptionEnabled()) {
            logWarning("I/O encryption enabled without RPC encryption: keys will be visible on the " +
                       "wire.")
        }
    }
    // 根据是driver还是 executor 来设置不同的名字
    val systemName = if (isDriver) driverSystemName else executorSystemName
    // rpcEnv的创建
    val rpcEnv = RpcEnv.create(systemName, bindAddress, advertiseAddress, port.getOrElse(-1), conf,
                               securityManager, numUsableCores, !isDriver)

    // Figure out which port RpcEnv actually bound to in case the original port is 0 or occupied.
    if (isDriver) {
        conf.set("spark.driver.port", rpcEnv.address.port.toString)
    }

    // Create an instance of the class with the given name, possibly initializing it with our conf
    def instantiateClass[T](className: String): T = {
        val cls = Utils.classForName(className)
        // Look for a constructor taking a SparkConf and a boolean isDriver, then one taking just
        // SparkConf, then one taking no arguments
        try {
            cls.getConstructor(classOf[SparkConf], java.lang.Boolean.TYPE)
            .newInstance(conf, new java.lang.Boolean(isDriver))
            .asInstanceOf[T]
        } catch {
            case _: NoSuchMethodException =>
            try {
                cls.getConstructor(classOf[SparkConf]).newInstance(conf).asInstanceOf[T]
            } catch {
                case _: NoSuchMethodException =>
                cls.getConstructor().newInstance().asInstanceOf[T]
            }
        }
    }

    // Create an instance of the class named by the given SparkConf property, or defaultClassName
    // if the property is not set, possibly initializing it with our conf
    def instantiateClassFromConf[T](propertyName: String, defaultClassName: String): T = {
        instantiateClass[T](conf.get(propertyName, defaultClassName))
    }

    val serializer = instantiateClassFromConf[Serializer](
        "spark.serializer", "org.apache.spark.serializer.JavaSerializer")
    logDebug(s"Using serializer: ${serializer.getClass}")
    // 序列化 管理器
    val serializerManager = new SerializerManager(serializer, conf, ioEncryptionKey)
    // 闭包序列化
    val closureSerializer = new JavaSerializer(conf)
    // 注册 或者 查找 endpoint
    def registerOrLookupEndpoint(
        name: String, endpointCreator: => RpcEndpoint):
    RpcEndpointRef = {
        if (isDriver) {
            logInfo("Registering " + name)
            rpcEnv.setupEndpoint(name, endpointCreator)
        } else {
            RpcUtils.makeDriverRef(name, conf, rpcEnv)
        }
    }
    //  ********重点******* BroadcastManager 管理器
    val broadcastManager = new BroadcastManager(isDriver, conf, securityManager)

    //  重点  mapOutputTracker 的创建  对任务信息的一些追踪
    val mapOutputTracker = if (isDriver) {
        new MapOutputTrackerMaster(conf, broadcastManager, isLocal)
    } else {
        new MapOutputTrackerWorker(conf)
    }

    // Have to assign trackerEndpoint after initialization as MapOutputTrackerEndpoint
    // requires the MapOutputTracker itself
    // outputTracker 的endpoint的注册
    mapOutputTracker.trackerEndpoint = registerOrLookupEndpoint(MapOutputTracker.ENDPOINT_NAME,
                                                                new MapOutputTrackerMasterEndpoint(
                                                                    rpcEnv, mapOutputTracker.asInstanceOf[MapOutputTrackerMaster], conf))

    // Let the user specify short names for shuffle managers
    // 获取 shuffleManger的类 并得到其实例
    val shortShuffleMgrNames = Map(
        "sort" -> classOf[org.apache.spark.shuffle.sort.SortShuffleManager].getName,
        "tungsten-sort" -> classOf[org.apache.spark.shuffle.sort.SortShuffleManager].getName)
    val shuffleMgrName = conf.get("spark.shuffle.manager", "sort")
    val shuffleMgrClass =
    shortShuffleMgrNames.getOrElse(shuffleMgrName.toLowerCase(Locale.ROOT), shuffleMgrName)
    val shuffleManager = instantiateClass[ShuffleManager](shuffleMgrClass)

    val useLegacyMemoryManager = conf.getBoolean("spark.memory.useLegacyMode", false)
    val memoryManager: MemoryManager =
    if (useLegacyMemoryManager) {
        new StaticMemoryManager(conf, numUsableCores)
    } else {
        UnifiedMemoryManager(conf, numUsableCores)
    }

    val blockManagerPort = if (isDriver) {
        conf.get(DRIVER_BLOCK_MANAGER_PORT)
    } else {
        conf.get(BLOCK_MANAGER_PORT)
    }
    // 数据传输的   重要
    val blockTransferService =
    new NettyBlockTransferService(conf, securityManager, bindAddress, advertiseAddress,
                                  blockManagerPort, numUsableCores)
    //  BlockManagerMaster 创建的地方,
    // 重要
    val blockManagerMaster = new BlockManagerMaster(registerOrLookupEndpoint(
        BlockManagerMaster.DRIVER_ENDPOINT_NAME,
        new BlockManagerMasterEndpoint(rpcEnv, isLocal, conf, listenerBus)),
                                                    conf, isDriver)

    // NB: blockManager is not valid until initialize() is called later.
    // 重要
    // blockManager 的创建
    val blockManager = new BlockManager(executorId, rpcEnv, blockManagerMaster,
                                        serializerManager, conf, memoryManager, mapOutputTracker, shuffleManager,
                                        blockTransferService, securityManager, numUsableCores)

    val metricsSystem = if (isDriver) {
        // Don't start metrics system right now for Driver.
        // We need to wait for the task scheduler to give us an app ID.
        // Then we can start the metrics system.
        MetricsSystem.createMetricsSystem("driver", conf, securityManager)
    } else {
        // We need to set the executor ID before the MetricsSystem is created because sources and
        // sinks specified in the metrics configuration file will want to incorporate this executor's
        // ID into the metrics they report.
        conf.set("spark.executor.id", executorId)
        val ms = MetricsSystem.createMetricsSystem("executor", conf, securityManager)
        ms.start()
        ms
    }
    // OutputCommitCoordinator 创建
    val outputCommitCoordinator = mockOutputCommitCoordinator.getOrElse {
        new OutputCommitCoordinator(conf, isDriver)
    }
    // 注册 OutputCommitCoordinator的 endpoint
    val outputCommitCoordinatorRef = registerOrLookupEndpoint("OutputCommitCoordinator",
                                                              new OutputCommitCoordinatorEndpoint(rpcEnv, outputCommitCoordinator))
    outputCommitCoordinator.coordinatorRef = Some(outputCommitCoordinatorRef)
    // 真正创建 SparkEnv的地方,其中包含了需要的各种 实例
    // 看到这些参数 真正大手笔,每一个都是一个模块
    //      executorId,    executor的id
    //      rpcEnv,        此drvier的rpcEnv
    //      serializer,      序列化
    //      closureSerializer,  闭包序列化
    //      serializerManager,   序列化管理器
    //      mapOutputTracker,    outputTracker
    //      shuffleManager,       shuffle管理器
    //      broadcastManager,     broadcase管理器
    //      blockManager,         block 管理器
    //      securityManager,      安全管理器
    //      metricsSystem,        监测系统
    //      memoryManager,        内存管理器
    //      outputCommitCoordinator,
    //      conf                  配置
    /// 具体的创建
    val envInstance = new SparkEnv(
        executorId,
        rpcEnv,
        serializer,
        closureSerializer,
        serializerManager,
        mapOutputTracker,
        shuffleManager,
        broadcastManager,
        blockManager,
        securityManager,
        metricsSystem,
        memoryManager,
        outputCommitCoordinator,
        conf)

    // Add a reference to tmp dir created by driver, we will delete this tmp dir when stop() is
    // called, and we only need to do it for driver. Because driver may run as a service, and if we
    // don't delete this tmp dir when sc is stopped, then will create too many tmp dirs.
    if (isDriver) {
        val sparkFilesDir = Utils.createTempDir(Utils.getLocalDir(conf), "userFiles").getAbsolutePath
        envInstance.driverTmpDir = Some(sparkFilesDir)
    }
    envInstance
}
```

不要被上面的重点，重点，重点吓到了，只能说明在这里同样也是干货满满，创建了很多的重量级模块实例，小结一下上面的工作：

1.  创建 new SecurityManager 实例
2.  创建RpcEnv ： RpcEnv.create
3.  创建  SerializerManager
4. 创建  closureSerializer
5.  创建 BroadcastManager
6. 创建 MapOutputTrackerMaster
7.  注册  MapOutputTrackerMasterEndpoint
8.  创建 shuffleManager实例 ： shortShuffleMgrNames
9.  创建 NettyBlockTransferService
10.  创建 BlockManagerMaster
11. 创建  BlockManager
12. 创建 OutputCommitCoordinator
13. 注册 OutputCommitCoordinatorEndpoint
14. 最后创建  SparkEnv

看完我只想说：喔噢，牛气。  一口气弄出来这么多的实例，每一个都相当于是一个模块，很多都还是比较重要的模块。当然了，这里也不会挨个去分析，留着后面分析把。

sparkEnv的构造函数

```scala
// sparkEnv的构造函数
// 这里其实就没有什么了, 重点全在上面的创建动作
class SparkEnv (
    val executorId: String,
    private[spark] val rpcEnv: RpcEnv,
    val serializer: Serializer,
    val closureSerializer: Serializer,
    val serializerManager: SerializerManager,
    val mapOutputTracker: MapOutputTracker,
    val shuffleManager: ShuffleManager,
    val broadcastManager: BroadcastManager,
    val blockManager: BlockManager,
    val securityManager: SecurityManager,
    val metricsSystem: MetricsSystem,
    val memoryManager: MemoryManager,
    val outputCommitCoordinator: OutputCommitCoordinator,
    val conf: SparkConf) extends Logging {

  @volatile private[spark] var isStopped = false
  private val pythonWorkers = mutable.HashMap[(String, Map[String, String]), PythonWorkerFactory]()

  // A general, soft-reference map for metadata needed during HadoopRDD split computation
  // (e.g., HadoopFileRDD uses this to cache JobConfs and InputFormats).
  private[spark] val hadoopJobMetadata = new MapMaker().softValues().makeMap[String, Any]()

  private[spark] var driverTmpDir: Option[String] = None
    ....
}
```















































