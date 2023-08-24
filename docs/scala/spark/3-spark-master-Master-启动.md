[TOC]

# Master的启动

## Master的启动类

由上面两篇分析可知，最终Master启动是调用类：

> org.apache.spark.deploy.master.Master

类图:

![](master1.png)

下面咱们就可以master的启动流程：

```scala
private[deploy] object Master extends Logging {
  val SYSTEM_NAME = "sparkMaster"
  val ENDPOINT_NAME = "Master"
  // master启动入口
  def main(argStrings: Array[String]) {
      // 设置线程对于未处理线程的处理函数
    Thread.setDefaultUncaughtExceptionHandler(new SparkUncaughtExceptionHandler(
      exitOnUncaughtException = false))
      // 日志相关的处理
    Utils.initDaemon(log)
    // 创建一个 application config
    // 1.SparkConf构造器中加载了 System.getProperties中所有以 spark开头的配置
    val conf = new SparkConf
    // 包装命令行参数
    val args = new MasterArguments(argStrings, conf)
    //
    val (rpcEnv, _, _) = startRpcEnvAndEndpoint(args.host, args.port, args.webUiPort, conf)
    // 等待停止
    rpcEnv.awaitTermination()
  }
```

可以做了这么几件事：

1. 设置线程未捕获异常处理函数
2. 日志初始化
3. 创建SparkConf
4. 解析命令行参数
5. 创建RPCEndpoint并启动
6. 等待，防止线程退出

### SparkConf的创建

咱们就从第三步继续分析：

> org.apache.spark.SparkConf

```scala
// 主构造函数 
class SparkConf(loadDefaults: Boolean) extends Cloneable with Logging with Serializable
// 辅助构造器
def this() = this(true)
```

```scala
// 存储配置的容器
private val settings = new ConcurrentHashMap[String, String]()
 // 通过构造器 设置的是true
if (loadDefaults) {
    // 从System中加载配置
    loadFromSystemProperties(false)
}

// 加载配置
private[spark] def loadFromSystemProperties(silent: Boolean): SparkConf = {
    // Load any spark.* system properties
    // 遍历System.getProperties中所有以  spark开头的配置
    for ((key, value) <- Utils.getSystemProperties if key.startsWith("spark.")) {
        // 设置配置到 setting中
        set(key, value, silent)
    }
    this
}
// 存储配置
private[spark] def set(key: String, value: String, silent: Boolean): SparkConf = {
    if (key == null) {
      throw new NullPointerException("null key")
    }
    if (value == null) {
      throw new NullPointerException("null value for " + key)
    }
    // 对于已经废弃的配置,是否打印警告信息
    if (!silent) {
      logDeprecationWarning(key)
    }
    // 设置属性到 setting中
    settings.put(key, value)
    this
  }
```

对于已经废弃的配置打印井盖信息:

```scala
def logDeprecationWarning(key: String): Unit = {
    // 已经废弃配置
    deprecatedConfigs.get(key).foreach { cfg =>
      logWarning(
        s"The configuration key '$key' has been deprecated as of Spark ${cfg.version} and " +
        s"may be removed in the future. ${cfg.deprecationMessage}")
      return
    }
    // 打印可选的配置
    allAlternatives.get(key).foreach { case (newKey, cfg) =>
      logWarning(
        s"The configuration key '$key' has been deprecated as of Spark ${cfg.version} and " +
        s"may be removed in the future. Please use the new key '$newKey' instead.")
      return
    }
    // 如果key为 spark.akka开头 或 spark.ssl.akka,则直接打印warnning
    if (key.startsWith("spark.akka") || key.startsWith("spark.ssl.akka")) {
      logWarning(
        s"The configuration key $key is not supported anymore " +
          s"because Spark doesn't use Akka since 2.0")
    }
  }
```

```scala
// 已经废弃配置的初始化
private val deprecatedConfigs: Map[String, DeprecatedConfig] = {
    // 创建已经废弃配置的 序列
    val configs = Seq(
      DeprecatedConfig("spark.cache.class", "0.8",
        "The spark.cache.class property is no longer being used! Specify storage levels using " +
        "the RDD.persist() method instead."),
      DeprecatedConfig("spark.yarn.user.classpath.first", "1.3",
        "Please use spark.{driver,executor}.userClassPathFirst instead."),
      DeprecatedConfig("spark.kryoserializer.buffer.mb", "1.4",
        "Please use spark.kryoserializer.buffer instead. The default value for " +
          "spark.kryoserializer.buffer.mb was previously specified as '0.064'. Fractional values " +
          "are no longer accepted. To specify the equivalent now, one may use '64k'."),
      DeprecatedConfig("spark.rpc", "2.0", "Not used anymore."),
      DeprecatedConfig("spark.scheduler.executorTaskBlacklistTime", "2.1.0",
        "Please use the new blacklisting options, spark.blacklist.*"),
      DeprecatedConfig("spark.yarn.am.port", "2.0.0", "Not used anymore"),
      DeprecatedConfig("spark.executor.port", "2.0.0", "Not used anymore"),
      DeprecatedConfig("spark.shuffle.service.index.cache.entries", "2.3.0",
        "Not used anymore. Please use spark.shuffle.service.index.cache.size"),
      DeprecatedConfig("spark.yarn.credentials.file.retention.count", "2.4.0", "Not used anymore."),
      DeprecatedConfig("spark.yarn.credentials.file.retention.days", "2.4.0", "Not used anymore.")
    )
    // 把创建的序列转换为map,DeprecatedConfig.key, value为 DeprecatedConfig
    Map(configs.map { cfg => (cfg.key -> cfg) } : _*)
  }
```

有可替代的配置

```scala
// allAlternatives 是configsWithAlternatives转换后的结果
  private val allAlternatives: Map[String, (String, AlternateConfig)] = {
    configsWithAlternatives.keys.flatMap { key =>
      configsWithAlternatives(key).map { cfg => (cfg.key -> (key -> cfg)) }
    }.toMap
  }


private val configsWithAlternatives = Map[String, Seq[AlternateConfig]](
    "spark.executor.userClassPathFirst" -> Seq(
        AlternateConfig("spark.files.userClassPathFirst", "1.3")),
    "spark.history.fs.update.interval" -> Seq(
        AlternateConfig("spark.history.fs.update.interval.seconds", "1.4"),
        AlternateConfig("spark.history.fs.updateInterval", "1.3"),
        AlternateConfig("spark.history.updateInterval", "1.3")),
    "spark.history.fs.cleaner.interval" -> Seq(
        AlternateConfig("spark.history.fs.cleaner.interval.seconds", "1.4")),
    MAX_LOG_AGE_S.key -> Seq(
        AlternateConfig("spark.history.fs.cleaner.maxAge.seconds", "1.4")),
    "spark.yarn.am.waitTime" -> Seq(
        AlternateConfig("spark.yarn.applicationMaster.waitTries", "1.3",
                        // Translate old value to a duration, with 10s wait time per try.
                        translation = s => s"${s.toLong * 10}s")),
    "spark.reducer.maxSizeInFlight" -> Seq(
        AlternateConfig("spark.reducer.maxMbInFlight", "1.4")),
    "spark.kryoserializer.buffer" -> Seq(
        AlternateConfig("spark.kryoserializer.buffer.mb", "1.4",
                        translation = s => s"${(s.toDouble * 1000).toInt}k")),
    "spark.kryoserializer.buffer.max" -> Seq(
        AlternateConfig("spark.kryoserializer.buffer.max.mb", "1.4")),
    "spark.shuffle.file.buffer" -> Seq(
        AlternateConfig("spark.shuffle.file.buffer.kb", "1.4")),
    "spark.executor.logs.rolling.maxSize" -> Seq(
        AlternateConfig("spark.executor.logs.rolling.size.maxBytes", "1.4")),
    "spark.io.compression.snappy.blockSize" -> Seq(
        AlternateConfig("spark.io.compression.snappy.block.size", "1.4")),
    "spark.io.compression.lz4.blockSize" -> Seq(
        AlternateConfig("spark.io.compression.lz4.block.size", "1.4")),
    "spark.rpc.numRetries" -> Seq(
        AlternateConfig("spark.akka.num.retries", "1.4")),
    "spark.rpc.retry.wait" -> Seq(
        AlternateConfig("spark.akka.retry.wait", "1.4")),
    "spark.rpc.askTimeout" -> Seq(
        AlternateConfig("spark.akka.askTimeout", "1.4")),
    "spark.rpc.lookupTimeout" -> Seq(
        AlternateConfig("spark.akka.lookupTimeout", "1.4")),
    "spark.streaming.fileStream.minRememberDuration" -> Seq(
        AlternateConfig("spark.streaming.minRememberDuration", "1.5")),
    "spark.yarn.max.executor.failures" -> Seq(
        AlternateConfig("spark.yarn.max.worker.failures", "1.5")),
    MEMORY_OFFHEAP_ENABLED.key -> Seq(
        AlternateConfig("spark.unsafe.offHeap", "1.6")),
    "spark.rpc.message.maxSize" -> Seq(
        AlternateConfig("spark.akka.frameSize", "1.6")),
    "spark.yarn.jars" -> Seq(
        AlternateConfig("spark.yarn.jar", "2.0")),
    "spark.yarn.access.hadoopFileSystems" -> Seq(
        AlternateConfig("spark.yarn.access.namenodes", "2.2")),
    MAX_REMOTE_BLOCK_SIZE_FETCH_TO_MEM.key -> Seq(
        AlternateConfig("spark.reducer.maxReqSizeShuffleToMem", "2.3")),
    LISTENER_BUS_EVENT_QUEUE_CAPACITY.key -> Seq(
        AlternateConfig("spark.scheduler.listenerbus.eventqueue.size", "2.3")),
    DRIVER_MEMORY_OVERHEAD.key -> Seq(
        AlternateConfig("spark.yarn.driver.memoryOverhead", "2.3")),
    EXECUTOR_MEMORY_OVERHEAD.key -> Seq(
        AlternateConfig("spark.yarn.executor.memoryOverhead", "2.3"))
)
```

到这里，sparkConf的构建就完成了，咱们继续向下：

### 参数的解析

看第四步:  解析命令行参数;

> val args = new MasterArguments(argStrings, conf)

```scala
// 主构造函数
private[master] class MasterArguments(args: Array[String], conf: SparkConf) extends Logging

// 构造体
// 获取 local hostName
  var host = Utils.localHostName()
  // master 端口号
  var port = 7077
  // master web端口号
  var webUiPort = 8080
  // 记录参数中传递的配置文件路径
  var propertiesFile: String = null

  // Check for settings in environment variables
  if (System.getenv("SPARK_MASTER_IP") != null) {
    logWarning("SPARK_MASTER_IP is deprecated, please use SPARK_MASTER_HOST")
    // 如果设置了 SPARK_MASTER_IP,则覆盖host
    host = System.getenv("SPARK_MASTER_IP")
  }

  if (System.getenv("SPARK_MASTER_HOST") != null) {
    // 使用SPARK_MASTER_HOST 此配置设置 host
    host = System.getenv("SPARK_MASTER_HOST")
  }
  if (System.getenv("SPARK_MASTER_PORT") != null) {
    // 使用配置的 SPARK_MASTER_PORT作为port
    port = System.getenv("SPARK_MASTER_PORT").toInt
  }
  if (System.getenv("SPARK_MASTER_WEBUI_PORT") != null) {
    // 使用配置的 SPARK_MASTER_WEBUI_PORT 作为web prot
    webUiPort = System.getenv("SPARK_MASTER_WEBUI_PORT").toInt
  }
  // 解析参数
  parse(args.toList)

  // This mutates the SparkConf, so all accesses to it must be made after this line
  propertiesFile = Utils.loadDefaultSparkProperties(conf, propertiesFile)

  if (conf.contains("spark.master.ui.port")) {
    webUiPort = conf.get("spark.master.ui.port").toInt
  }
```

参数解析:

```scala
  @tailrec
// 参数的解析; 使用match来进行list的匹配
  private def parse(args: List[String]): Unit = args match {
    case ("--ip" | "-i") :: value :: tail =>
      Utils.checkHost(value)
      host = value
      parse(tail)
    case ("--host" | "-h") :: value :: tail =>
      Utils.checkHost(value)
      host = value
      parse(tail)
    case ("--port" | "-p") :: IntParam(value) :: tail =>
      port = value
      parse(tail)
    case "--webui-port" :: IntParam(value) :: tail =>
      webUiPort = value
      parse(tail)
    case ("--properties-file") :: value :: tail =>
      propertiesFile = value
      parse(tail)
    // 打印帮助信息
    case ("--help") :: tail =>
      printUsageAndExit(0)  // 打印帮助信息
    case Nil => // No-op
    case _ =>
      printUsageAndExit(1)
  }
```

### Rpc的初始化

参数就解析完了，继续向下看， 第五步： 创建Rpc

> ```scala
> val (rpcEnv, _, _) = startRpcEnvAndEndpoint(args.host, args.port, args.webUiPort, conf)
> ```

```scala
  /**
   * Start the Master and return a three tuple of:
   *   (1) The Master RpcEnv
   *   (2) The web UI bound port
   *   (3) The REST server bound port, if any
   *  此处 javadoc说最终返回一个三元组,内容为:(RpcEnv, webUiPort,rest-Server-port)
   */
  def startRpcEnvAndEndpoint(
      host: String,
      port: Int,
      webUiPort: Int,
      conf: SparkConf): (RpcEnv, Int, Option[Int]) = {
      // 创建securityManager; 此处先略过, 不做分析
    val securityMgr = new SecurityManager(conf)
    // 创建rpcEnv
    val rpcEnv = RpcEnv.create(SYSTEM_NAME, host, port, conf, securityMgr)
    // 设置 endPoint; 也就是把 Master注册到 dispatcher
    // 也可以看出, 此处是 Master的创建的地方
    val masterEndpoint = rpcEnv.setupEndpoint(ENDPOINT_NAME,
      new Master(rpcEnv, rpcEnv.address, webUiPort, securityMgr, conf))
    // 发送消息
    val portsResponse = masterEndpoint.askSync[BoundPortsResponse](BoundPortsRequest)
    (rpcEnv, portsResponse.webUIPort, portsResponse.restPort)
  }
```

此处主要的工作:

1. 创建SecurityManager
2. 创建RpcEnv
3. 创建的MasterEndpoint并进行注册
4. masterEndpoint 发送消息
5. 返回创建的RpcEnv  webUIPort  restPort

这里咱们就先不看securityManager(毕竟不是重点，先看具体的业务逻辑)，直接从第二步开始:

#### RpcEnv的创建

```scala
def create(
    name: String,
    host: String,
    port: Int,
    conf: SparkConf,
    securityManager: SecurityManager,
    clientMode: Boolean = false): RpcEnv = {
    // 调用另一个方法
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
    new NettyRpcEnvFactory().create(config) // 使用NettyRpcEnvFactory工厂类创建
}
// 封装配置
private[spark] case class RpcEnvConfig(
    conf: SparkConf,
    name: String,
    bindAddress: String,
    advertiseAddress: String,
    port: Int,
    securityManager: SecurityManager,
    numUsableCores: Int,
    clientMode: Boolean)
```

NettyRpcFactory创建NettyEnv的方式:

```scala
def create(config: RpcEnvConfig): RpcEnv = {
    val sparkConf = config.conf
    // Use JavaSerializerInstance in multiple threads is safe. However, if we plan to support
    // KryoSerializer in future, we have to use ThreadLocal to store SerializerInstance
    // 序列化的方式
    val javaSerializerInstance =
    new JavaSerializer(sparkConf).newInstance().asInstanceOf[JavaSerializerInstance]
    // RpcEnv的创建,此会创建Dispatcher(发送信息到对应的endpoint)
    // 绑定webUi
    val nettyEnv =
    new NettyRpcEnv(sparkConf, javaSerializerInstance, config.advertiseAddress,
                    config.securityManager, config.numUsableCores)
    // 此主要是创建一个启动server的 函数
    if (!config.clientMode) {
        val startNettyRpcEnv: Int => (NettyRpcEnv, Int) = { actualPort =>
            nettyEnv.startServer(config.bindAddress, actualPort)
            (nettyEnv, nettyEnv.address.port)
        }
        try {
            // 真正上面创建的启动server的地方; 启动master的Rpc
            // 换句话说,也就是启动master
            Utils.startServiceOnPort(config.port, startNettyRpcEnv, sparkConf, config.name)._1
        } catch {
            case NonFatal(e) =>
            nettyEnv.shutdown()
            throw e
        }
    }
    nettyEnv
}
```

这里对于webUi的启动及绑定，以及master的具体启动，后面单独拎出来讲，本篇主要说一下这个master的启动流程。

#### master的创建

>  val masterEndpoint = rpcEnv.setupEndpoint(ENDPOINT_NAME,
>       new Master(rpcEnv, rpcEnv.address, webUiPort, securityMgr, conf))

master的创建，以及创建masterEndpoint。

这里咱们看一下具体的master的创建：

```scala
/// 主构造函数
private[deploy] class Master(
    override val rpcEnv: RpcEnv,
    address: RpcAddress,
    webUiPort: Int,
    val securityMgr: SecurityManager,
    val conf: SparkConf)
  extends ThreadSafeRpcEndpoint with Logging with LeaderElectable 

/// 构造函数体---初始化一系列的容器 以及 环境变量
  // 创建了一个线程池
  private val forwardMessageThread =
    ThreadUtils.newDaemonSingleThreadScheduledExecutor("master-forward-message-thread")
  // hadoop相关的配置
  private val hadoopConf = SparkHadoopUtil.get.newConfiguration(conf)

  // For application IDs
  // 时间格式化 格式
  private def createDateFormat = new SimpleDateFormat("yyyyMMddHHmmss", Locale.US)
  // 默认是  60s; woker的超时时间
  private val WORKER_TIMEOUT_MS = conf.getLong("spark.worker.timeout", 60) * 1000
  // 保存的 application数量,默认是200
  private val RETAINED_APPLICATIONS = conf.getInt("spark.deploy.retainedApplications", 200)
  // 保存的driver数量,默认是200
  private val RETAINED_DRIVERS = conf.getInt("spark.deploy.retainedDrivers", 200)
  //
  private val REAPER_ITERATIONS = conf.getInt("spark.dead.worker.persistence", 15)
  // HA 恢复的模式
  private val RECOVERY_MODE = conf.get("spark.deploy.recoveryMode", "NONE")
  // executor 重试的次数
  private val MAX_EXECUTOR_RETRIES = conf.getInt("spark.deploy.maxExecutorRetries", 10)
  // 所有的worker 信息
  val workers = new HashSet[WorkerInfo]
  // id 到 app 的映射关系
  val idToApp = new HashMap[String, ApplicationInfo]
  // 等待中的app的信息
  private val waitingApps = new ArrayBuffer[ApplicationInfo]
  // 所有的app 信息
  val apps = new HashSet[ApplicationInfo]
  // id 和 worker之间的映射关系
  private val idToWorker = new HashMap[String, WorkerInfo]
  // rpc地址到 worker之间的映射关系
  private val addressToWorker = new HashMap[RpcAddress, WorkerInfo]
  // RpcEndPoint 到  applicaiton 的映射关系
  private val endpointToApp = new HashMap[RpcEndpointRef, ApplicationInfo]
  // rpc 地址到 application的映射关系
  private val addressToApp = new HashMap[RpcAddress, ApplicationInfo]
  // 完成的 application的容器
  private val completedApps = new ArrayBuffer[ApplicationInfo]
  // 下一个app的 序列号
  private var nextAppNumber = 0
  // 所有的driver的信息
  private val drivers = new HashSet[DriverInfo]
  // 所有完成的driver的信息
  private val completedDrivers = new ArrayBuffer[DriverInfo]
  // Drivers currently spooled for scheduling
  // 等待中的driver的信息
  private val waitingDrivers = new ArrayBuffer[DriverInfo]
  // 下一个driver的序列号
  private var nextDriverNumber = 0
  // host地址的检测
  Utils.checkHost(address.host)
  // 监测系统
  private val masterMetricsSystem = MetricsSystem.createMetricsSystem("master", conf, securityMgr)
  private val applicationMetricsSystem = MetricsSystem.createMetricsSystem("applications", conf,
    securityMgr)
  // masterSource 对当前Master的包装
  private val masterSource = new MasterSource(this)

  // After onStart, webUi will be set
  private var webUi: MasterWebUI = null
  // master的地址
  private val masterPublicAddress = {
    val envVar = conf.getenv("SPARK_PUBLIC_DNS")
    if (envVar != null) envVar else address.host
  }
  // master的url
  private val masterUrl = address.toSparkURL
  // _ 表示默认初始值;
  private var masterWebUiUrl: String = _
  // 初始状态,为 STANDBY
  private var state = RecoveryState.STANDBY
  // 序列化引擎
  private var persistenceEngine: PersistenceEngine = _
  // leader 选举
  private var leaderElectionAgent: LeaderElectionAgent = _
  // 恢复的 task
  private var recoveryCompletionTask: ScheduledFuture[_] = _
  // 检测 worker是否超时的 task
  private var checkForWorkerTimeOutTask: ScheduledFuture[_] = _

  // As a temporary workaround before better ways of configuring memory, we allow users to set
  // a flag that will perform round-robin scheduling across the nodes (spreading out each app
  // among all the nodes) instead of trying to consolidate each app onto a small # of nodes.
  // 在有更好配置内存方法前的临时方法, 允许用户设置一个flag, 该flag会使能在所有节点上循环调度app,
  // 而不是把app整合在一个小的 节点上
  private val spreadOutApps = conf.getBoolean("spark.deploy.spreadOut", true)

  // Default maxCores for applications that don't specify it (i.e. pass Int.MaxValue)
  // 默认可用的 core 核数
  private val defaultCores = conf.getInt("spark.deploy.defaultCores", Int.MaxValue)
  // 反向代理
  val reverseProxy = conf.getBoolean("spark.ui.reverseProxy", false)
  if (defaultCores < 1) {
    throw new SparkException("spark.deploy.defaultCores must be positive")
  }

  // Alternative application submission gateway that is stable across Spark versions
  // 是否使用 restServer; 提供给外部通过 REST api的方式来提交任务
  private val restServerEnabled = conf.getBoolean("spark.master.rest.enabled", false)
  // restServer
  private var restServer: Option[StandaloneRestServer] = None
  // restServer绑定的端口
  private var restServerBoundPort: Option[Int] = None

  {
    val authKey = SecurityManager.SPARK_AUTH_SECRET_CONF
    require(conf.getOption(authKey).isEmpty || !restServerEnabled,
      s"The RestSubmissionServer does not support authentication via ${authKey}.  Either turn " +
        "off the RestSubmissionServer with spark.master.rest.enabled=false, or do not use " +
        "authentication.")
  }
```

#### 注册创建的master endpoint

注册endpoint

> org.apache.spark.rpc.netty.NettyRpcEnv#setupEndpoint

```scala
  override def setupEndpoint(name: String, endpoint: RpcEndpoint): RpcEndpointRef = {
    dispatcher.registerRpcEndpoint(name, endpoint)
  }
```

```scala
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

#### masterEndpoint 消息发送

注册号endpoint之后，会发送消息：

```scala
 // 发送消息
 val portsResponse = masterEndpoint.askSync[BoundPortsResponse](BoundPortsRequest)
```

> org.apache.spark.rpc.RpcEndpointRef#askSync

```scala
def askSync[T: ClassTag](message: Any): T = askSync(message, defaultAskTimeout)

def askSync[T: ClassTag](message: Any, timeout: RpcTimeout): T = {
    val future = ask[T](message, timeout)
    timeout.awaitResult(future)
}

> org.apache.spark.rpc.netty.NettyRpcEndpointRef#ask

override def ask[T: ClassTag](message: Any, timeout: RpcTimeout): Future[T] = {
    nettyEnv.ask(new RequestMessage(nettyEnv.address, this, message), timeout)
}

// 发送消息 并等待回复
private[netty] def ask[T: ClassTag](message: RequestMessage, timeout: RpcTimeout): Future[T] = {
    val promise = Promise[Any]()
    val remoteAddr = message.receiver.address
    // 失败的回调函数
    def onFailure(e: Throwable): Unit = {
        if (!promise.tryFailure(e)) {
            e match {
                case e : RpcEnvStoppedException => logDebug (s"Ignored failure: $e")
                case _ => logWarning(s"Ignored failure: $e")
            }
        }
    }
    // 成的回调函数
    def onSuccess(reply: Any): Unit = reply match {
        case RpcFailure(e) => onFailure(e)
        case rpcReply =>
        if (!promise.trySuccess(rpcReply)) {
            logWarning(s"Ignored message: $reply")
        }
    }

    try {
        if (remoteAddr == address) {
            val p = Promise[Any]()
            p.future.onComplete {
                case Success(response) => onSuccess(response)
                case Failure(e) => onFailure(e)
            }(ThreadUtils.sameThread)
            // 发送消息
            dispatcher.postLocalMessage(message, p)
        } else {
            val rpcMessage = RpcOutboxMessage(message.serialize(this),
            onFailure,(client, response) => onSuccess(deserialize[Any](client, response)))
            // 发送消息到 Outbox
            postToOutbox(message.receiver, rpcMessage)
            promise.future.failed.foreach {
                case _: TimeoutException => rpcMessage.onTimeout()
                case _ =>
            }(ThreadUtils.sameThread)
        }
        // 定时 任务
        val timeoutCancelable = timeoutScheduler.schedule(new Runnable {
            override def run(): Unit = {
                onFailure(new TimeoutException(s"Cannot receive any reply from ${remoteAddr} " +
                                               s"in ${timeout.duration}"))
            }
        }, timeout.duration.toNanos, TimeUnit.NANOSECONDS)
        promise.future.onComplete { v =>
            timeoutCancelable.cancel(true)
        }(ThreadUtils.sameThread)
    } catch {
        case NonFatal(e) =>
        onFailure(e)
    }
    promise.future.mapTo[T].recover(timeout.addMessageIfTimeout)(ThreadUtils.sameThread)
}
```

> dispatcher.postLocalMessage

```scala
// 发送消息到 本地
def postLocalMessage(message: RequestMessage, p: Promise[Any]): Unit = {
    val rpcCallContext =
    new LocalNettyRpcCallContext(message.senderAddress, p)
    val rpcMessage = RpcMessage(message.senderAddress, message.content, rpcCallContext)
    // 发送消息
    postMessage(message.receiver.name, rpcMessage, (e) => p.tryFailure(e))
}

private def postMessage(
    endpointName: String,
    message: InboxMessage,
    callbackIfStopped: (Exception) => Unit): Unit = {
    val error = synchronized {
        val data = endpoints.get(endpointName)
        if (stopped) {
            Some(new RpcEnvStoppedException())
        } else if (data == null) {
            Some(new SparkException(s"Could not find $endpointName."))
        } else {
            // 把消息放到  inbox
            data.inbox.post(message)
            // 保存接收到消息的 data
            receivers.offer(data)
            None
        }
    }
    // We don't need to call `onStop` in the `synchronized` block
    error.foreach(callbackIfStopped)
}
```

发送消息到外部:

> // 发送消息到 Outbox
>             postToOutbox(message.receiver, rpcMessage)

```scala
// 发送消息到 Outbox
private def postToOutbox(receiver: NettyRpcEndpointRef, message: OutboxMessage): Unit = {
    // 如果已经有了 Client,则直接发送
    if (receiver.client != null) {
        message.sendWith(receiver.client)
    } else {
        require(receiver.address != null,
                "Cannot send message to client endpoint with no listen address.")
        // 创建outbox
        val targetOutbox = {
            val outbox = outboxes.get(receiver.address)
            if (outbox == null) {
                val newOutbox = new Outbox(this, receiver.address)
                val oldOutbox = outboxes.putIfAbsent(receiver.address, newOutbox)
                if (oldOutbox == null) {
                    newOutbox
                } else {
                    oldOutbox
                }
            } else {
                outbox
            }
        }
        // 如果已经停止,则进行停止
        if (stopped.get) {
            // It's possible that we put `targetOutbox` after stopping. So we need to clean it.
            outboxes.remove(receiver.address)
            targetOutbox.stop()
        } else {
            // 具体的发送消息
            targetOutbox.send(message)
        }
    }
}
```

```scala
// 发送消息到 外部的 box
def send(message: OutboxMessage): Unit = {
    val dropped = synchronized {
        if (stopped) {
            true
        } else {
            messages.add(message)
            false
        }
    }
    if (dropped) {
        message.onFailure(new SparkException("Message is dropped because Outbox is stopped"))
    } else {
        // 具体的消息发送
        drainOutbox()
    }
}
```

```scala
private def drainOutbox(): Unit = {
    var message: OutboxMessage = null
    synchronized {
      if (stopped) {
        return
      }
      if (connectFuture != null) {
        // We are connecting to the remote address, so just exit
        return
      }
      if (client == null) {
        // There is no connect task but client is null, so we need to launch the connect task.
        // 创建client
        launchConnectTask()
        return
      }
      if (draining) {
        // There is some thread draining, so just exit
        return
      }
      message = messages.poll()
      if (message == null) {
        return
      }
      draining = true
    }
    // 村换发送消息,直到把所有消息发送完毕
    while (true) {
      try {
        val _client = synchronized { client }
        if (_client != null) {
          // 发送消息
          message.sendWith(_client)
        } else {
          assert(stopped == true)
        }
      } catch {
        case NonFatal(e) =>
          handleNetworkFailure(e)
          return
      }
      synchronized {
        if (stopped) {
          return
        }
        message = messages.poll()
        if (message == null) {
          draining = false
          return
        }
      }
    }
  }
```

```scala
  private def launchConnectTask(): Unit = {
    connectFuture = nettyEnv.clientConnectionExecutor.submit(new Callable[Unit] {

      override def call(): Unit = {
        try {
          // 创建 netty客户端
          val _client = nettyEnv.createClient(address)
          outbox.synchronized {
            // 记录创建的客户端
            client = _client
            if (stopped) {
              closeClient()
            }
          }
        } catch {
          case ie: InterruptedException =>
            // exit
            return
          case NonFatal(e) =>
            outbox.synchronized { connectFuture = null }
            handleNetworkFailure(e)
            return
        }
        outbox.synchronized { connectFuture = null }
        // It's possible that no thread is draining now. If we don't drain here, we cannot send the
        // messages until the next message arrives.
        // 创建好了client 再次进行消息的发送
        drainOutbox()
      }
    })
  }

```



### master启动完成

到此master就启动完成了，最后就循环等待，防止程序退出：

> ```scala
> rpcEnv.awaitTermination()
> ```

```scala
override def awaitTermination(): Unit = {
    dispatcher.awaitTermination()
}

def awaitTermination(): Unit = {
    threadpool.awaitTermination(Long.MaxValue, TimeUnit.MILLISECONDS)
}
```

读者读到这里，真心不容易。现在可以放下心，master启动到这里就完成了。继续进行下面的源码之旅吧。





















