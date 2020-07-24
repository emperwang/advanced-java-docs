[TOC]

# spark driverWrapper的启动

本篇讲述一下提交任务后driver的启动，从启动命令看可知，真实的driver启动来其实就是org.apache.spark.deploy.worker.DriverWrapper。咱们从sparkSubmit来作为入口点，看一下此driver是如何启动的。

任务提交最终的命令:

```shell
java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*'  -Xmx1g org.apache.spark.deploy.SparkSubmit --master spark://name2:7077  --class org.apache.spark.examples.SparkPi ../examples/jars/spark-examples_2.11-2.4.6.jar 10
```



入口函数:

> org.apache.spark.deploy.SparkSubmit

```scala
object SparkSubmit extends CommandLineUtils with Logging {

  // Cluster managers
  private val YARN = 1
  private val STANDALONE = 2
  private val MESOS = 4
  private val LOCAL = 8
  private val KUBERNETES = 16
  private val ALL_CLUSTER_MGRS = YARN | STANDALONE | MESOS | LOCAL | KUBERNETES

  // Deploy modes
  private val CLIENT = 1
  private val CLUSTER = 2
  private val ALL_DEPLOY_MODES = CLIENT | CLUSTER

  // Special primary resource names that represent shells rather than application jars.
  private val SPARK_SHELL = "spark-shell"
  private val PYSPARK_SHELL = "pyspark-shell"
  private val SPARKR_SHELL = "sparkr-shell"
  private val SPARKR_PACKAGE_ARCHIVE = "sparkr.zip"
  private val R_PACKAGE_ARCHIVE = "rpkg.zip"

  private val CLASS_NOT_FOUND_EXIT_STATUS = 101

  // Following constants are visible for testing.
  private[deploy] val YARN_CLUSTER_SUBMIT_CLASS =
    "org.apache.spark.deploy.yarn.YarnClusterApplication"
  private[deploy] val REST_CLUSTER_SUBMIT_CLASS = classOf[RestSubmissionClientApp].getName()
  private[deploy] val STANDALONE_CLUSTER_SUBMIT_CLASS = classOf[ClientApp].getName()
  private[deploy] val KUBERNETES_CLUSTER_SUBMIT_CLASS =
    "org.apache.spark.deploy.k8s.submit.KubernetesClientApplication"
  // 创建sparkSubmit
  override def main(args: Array[String]): Unit = {
    // 创建submit; 复写了其中的部分方法
      // 先创建了 submit实例
    val submit = new SparkSubmit() {
      self =>
      override protected def parseArguments(args: Array[String]): SparkSubmitArguments = {
        new SparkSubmitArguments(args) {
          override protected def logInfo(msg: => String): Unit = self.logInfo(msg)

          override protected def logWarning(msg: => String): Unit = self.logWarning(msg)
        }
      }
      override protected def logInfo(msg: => String): Unit = printMessage(msg)
      override protected def logWarning(msg: => String): Unit = printMessage(s"Warning: $msg")
      override def doSubmit(args: Array[String]): Unit = {
        try {
          super.doSubmit(args)
        } catch {
          case e: SparkUserAppException =>
            exitFn(e.exitCode)
        }
      }

    }
    // 真正的提交动作
    submit.doSubmit(args)
  }
```

代码很清晰，没有啥多余操作，直接创建SparkSubmit实例，之后调用其doSubmit进行提交的动作。

```scala
  def doSubmit(args: Array[String]): Unit = {
    // Initialize logging if it hasn't been done yet. Keep track of whether logging needs to
    // be reset before the application starts.
    // 日志相关的初始化
    val uninitLog = initializeLogIfNecessary(true, silent = true)
    // 解析参数
    val appArgs = parseArguments(args)
    if (appArgs.verbose) {
      logInfo(appArgs.toString)
    }
    // 根据action的不同,来做不同的操作
    appArgs.action match {
      case SparkSubmitAction.SUBMIT => submit(appArgs, uninitLog)   // 提交任务
      case SparkSubmitAction.KILL => kill(appArgs)                  // kill 任务
      case SparkSubmitAction.REQUEST_STATUS => requestStatus(appArgs)
      case SparkSubmitAction.PRINT_VERSION => printVersion()
    }
  }
```

这里就做了还是比较都的动作：

1. 日志的初始化
2. 参数额解析
3. 根据动作不同，来执行不同的操作
   1. SUBMIT
   2. KILL
   3. REQUEST_STATUS
   4. PRINT_VERSION

## 参数解析

```scala
  protected def parseArguments(args: Array[String]): SparkSubmitArguments = {
    new SparkSubmitArguments(args)
  }
```

```scala
// 构造函数 以及 方法体
// 这里的参数解析 还是做了很多的操作的,不过总体来说代码比较简单,了解流程就可以,细节可以自己看
// 这里就不贴出来了
private[deploy] class SparkSubmitArguments(args: Seq[String], env: Map[String, String] = sys.env)
  extends SparkSubmitArgumentsParser with Logging {
  var master: String = null
  var deployMode: String = null
  var executorMemory: String = null
  var executorCores: String = null
  var totalExecutorCores: String = null
  var propertiesFile: String = null
  var driverMemory: String = null
  var driverExtraClassPath: String = null
  var driverExtraLibraryPath: String = null
  var driverExtraJavaOptions: String = null
  var queue: String = null
  var numExecutors: String = null
  var files: String = null
  var archives: String = null
  var mainClass: String = null
  var primaryResource: String = null
  var name: String = null
  var childArgs: ArrayBuffer[String] = new ArrayBuffer[String]()
  var jars: String = null
  var packages: String = null
  var repositories: String = null
  var ivyRepoPath: String = null
  var ivySettingsPath: Option[String] = None
  var packagesExclusions: String = null
  var verbose: Boolean = false
  var isPython: Boolean = false
  var pyFiles: String = null
  var isR: Boolean = false
  var action: SparkSubmitAction = null
  val sparkProperties: HashMap[String, String] = new HashMap[String, String]()
  var proxyUser: String = null
  var principal: String = null
  var keytab: String = null
  private var dynamicAllocationEnabled: Boolean = false
  // Standalone cluster mode only
  var supervise: Boolean = false
  var driverCores: String = null
  var submissionToKill: String = null
  var submissionToRequestStatusFor: String = null
  var useRest: Boolean = false // used internally
  /** Default properties present in the currently defined defaults file. */
  lazy val defaultSparkProperties: HashMap[String, String] = {
    val defaultProperties = new HashMap[String, String]()
    if (verbose) {
      logInfo(s"Using properties file: $propertiesFile")
    }
    Option(propertiesFile).foreach { filename =>
      val properties = Utils.getPropertiesFromFile(filename)
      properties.foreach { case (k, v) =>
        defaultProperties(k) = v
      }
      // Property files may contain sensitive information, so redact before printing
      if (verbose) {
        Utils.redact(properties).foreach { case (k, v) =>
          logInfo(s"Adding default property: $k=$v")
        }
      }
    }
    defaultProperties
  }
  // Set parameters from command line arguments
  // 解析命令行传递的参数
  parse(args.asJava)
  // Populate `sparkProperties` map from properties file
  // 加载 使用--conf指定的配置文件, 或者加载配置目录中 spark-default.conf
  mergeDefaultSparkProperties()
  // Remove keys that don't start with "spark." from `sparkProperties`.
  // 去除那些 不是以 spark.开头的配置
  ignoreNonSparkProperties()
  // Use `sparkProperties` map along with env vars to fill in any missing parameters
  // 加载 env中的配置
  loadEnvironmentArguments()

  useRest = sparkProperties.getOrElse("spark.master.rest.enabled", "false").toBoolean
  // 参数校验
  validateArguments()

```



## 提交动作

```scala
  private def submit(args: SparkSubmitArguments, uninitLog: Boolean): Unit = {
    // 定义一个 run启动类的函数
    def doRunMain(): Unit = {
      if (args.proxyUser != null) {
        val proxyUser = UserGroupInformation.createProxyUser(args.proxyUser,
          UserGroupInformation.getCurrentUser())
        try {
          proxyUser.doAs(new PrivilegedExceptionAction[Unit]() {
            override def run(): Unit = {
              runMain(args, uninitLog)
            }
          })
        } catch {
          case e: Exception =>
            // Hadoop's AuthorizationException suppresses the exception's stack trace, which
            // makes the message printed to the output by the JVM not very helpful. Instead,
            // detect exceptions with empty stack traces here, and treat them differently.
            if (e.getStackTrace().length == 0) {
              error(s"ERROR: ${e.getClass().getName()}: ${e.getMessage()}")
            } else {
              throw e
            }
        }
      } else {
        runMain(args, uninitLog)
      }
    }
    // In standalone cluster mode, there are two submission gateways:
    //   (1) The traditional RPC gateway using o.a.s.deploy.Client as a wrapper
    //   (2) The new REST-based gateway introduced in Spark 1.3
    // The latter is the default behavior as of Spark 1.3, but Spark submit will fail over
    // to use the legacy gateway if the master endpoint turns out to be not a REST server.
    if (args.isStandaloneCluster && args.useRest) {
      try {
        logInfo("Running Spark using the REST application submission protocol.")
        doRunMain()
      } catch {
        // Fail over to use the legacy submission gateway
        case e: SubmitRestConnectionException =>
          logWarning(s"Master endpoint ${args.master} was not a REST server. " +
            "Falling back to legacy submission gateway instead.")
          args.useRest = false
          submit(args, false)
      }
    // In all other modes, just run the main class as prepared
    } else {
      doRunMain()
    }
  }
```

```scala
   /* 启动 任务的main函数
   * 分为两步:
   * 1. 准备运行环境
   *  2. 调用main method  
    */
private def runMain(args: SparkSubmitArguments, uninitLog: Boolean): Unit = {
    // 配置子程序的 运行环境
    val (childArgs, childClasspath, sparkConf, childMainClass) = prepareSubmitEnvironment(args)
    // Let the main class re-initialize the logging system once it starts.
    if (uninitLog) {
      Logging.uninitialize()
    }
    // 如果设置了详细输出  则打印信息
    if (args.verbose) {
      logInfo(s"Main class:\n$childMainClass")
      logInfo(s"Arguments:\n${childArgs.mkString("\n")}")
      // sysProps may contain sensitive information, so redact before printing
      logInfo(s"Spark config:\n${Utils.redact(sparkConf.getAll.toMap).mkString("\n")}")
      logInfo(s"Classpath elements:\n${childClasspath.mkString("\n")}")
      logInfo("\n")
    }
	// 类加载器
    val loader =
      if (sparkConf.get(DRIVER_USER_CLASS_PATH_FIRST)) {
        new ChildFirstURLClassLoader(new Array[URL](0),
          Thread.currentThread.getContextClassLoader)
      } else {
        new MutableURLClassLoader(new Array[URL](0),
          Thread.currentThread.getContextClassLoader)
      }
    Thread.currentThread.setContextClassLoader(loader)
	// 添加jar 到classpath
    for (jar <- childClasspath) {
      addJarToClasspath(jar, loader)
    }

    var mainClass: Class[_] = null
    try {
      // 加载 要运行的类
        // 这里是 org.apache.spark.deploy.SparkSubmit
      mainClass = Utils.classForName(childMainClass)
    } catch {
      case e: ClassNotFoundException =>
        logWarning(s"Failed to load $childMainClass.", e)
        if (childMainClass.contains("thriftserver")) {
          logInfo(s"Failed to load main class $childMainClass.")
          logInfo("You need to build Spark with -Phive and -Phive-thriftserver.")
        }
        throw new SparkUserAppException(CLASS_NOT_FOUND_EXIT_STATUS)
      case e: NoClassDefFoundError =>
        logWarning(s"Failed to load $childMainClass: ${e.getMessage()}")
        if (e.getMessage.contains("org/apache/hadoop/hive")) {
          logInfo(s"Failed to load hive class.")
          logInfo("You need to build Spark with -Phive and -Phive-thriftserver.")
        }
        throw new SparkUserAppException(CLASS_NOT_FOUND_EXIT_STATUS)
    }
    // 创建 application
    val app: SparkApplication = if (classOf[SparkApplication].isAssignableFrom(mainClass)) {
      mainClass.newInstance().asInstanceOf[SparkApplication]
    } else {
      // SPARK-4170
      if (classOf[scala.App].isAssignableFrom(mainClass)) {
        logWarning("Subclasses of scala.App may not work correctly. Use a main() method instead.")
      }
      new JavaMainApplication(mainClass)
    }

    @tailrec
    def findCause(t: Throwable): Throwable = t match {
      case e: UndeclaredThrowableException =>
        if (e.getCause() != null) findCause(e.getCause()) else e
      case e: InvocationTargetException =>
        if (e.getCause() != null) findCause(e.getCause()) else e
      case e: Throwable =>
        e
    }
    try {
      // 如果是 client,此时就是直接启动 目标任务
        // 如果是 cluster, 此时app为 org.apache.spark.deploy.ClientApp
      app.start(childArgs.toArray, sparkConf)
    } catch {
      case t: Throwable =>
        throw findCause(t)
    }
  }
```

这里咱们继续看  ClientApp

```scala
private[spark] class ClientApp extends SparkApplication {

  override def start(args: Array[String], conf: SparkConf): Unit = {
    val driverArgs = new ClientArguments(args)
    if (!conf.contains("spark.rpc.askTimeout")) {
      conf.set("spark.rpc.askTimeout", "10s")
    }
    Logger.getRootLogger.setLevel(driverArgs.logLevel)
    // 熟悉的感觉,和master worker一样,创建 RPcRnv环境
    val rpcEnv =
      RpcEnv.create("driverClient", Utils.localHostName(), 0, conf, new SecurityManager(conf))
    val masterEndpoints = driverArgs.masters.map(RpcAddress.fromSparkURL).
      map(rpcEnv.setupEndpointRef(_, Master.ENDPOINT_NAME))
    // new ClientEndpoint 中 driver 的启动
    // 重点 ClientEndpoint
    rpcEnv.setupEndpoint("client", new ClientEndpoint(rpcEnv, driverArgs, masterEndpoints, conf))
    rpcEnv.awaitTermination()
  }
}
```

> org.apache.spark.deploy.ClientEndpoint#onStart

```scala
override def onStart(): Unit = {
    // 启动driver
    driverArgs.cmd match {
      case "launch" =>
        // TODO: We could add an env variable here and intercept it in `sc.addJar` that would
        //       truncate filesystem paths similar to what YARN does. For now, we just require
        //       people call `addJar` assuming the jar is in the same directory.
        val mainClass = "org.apache.spark.deploy.worker.DriverWrapper"

        val classPathConf = "spark.driver.extraClassPath"
        val classPathEntries = getProperty(classPathConf, conf).toSeq.flatMap { cp =>
          cp.split(java.io.File.pathSeparator)
        }

        val libraryPathConf = "spark.driver.extraLibraryPath"
        val libraryPathEntries = getProperty(libraryPathConf, conf).toSeq.flatMap { cp =>
          cp.split(java.io.File.pathSeparator)
        }

        val extraJavaOptsConf = "spark.driver.extraJavaOptions"
        val extraJavaOpts = getProperty(extraJavaOptsConf, conf)
          .map(Utils.splitCommandString).getOrElse(Seq.empty)

        val sparkJavaOpts = Utils.sparkJavaOpts(conf)
        val javaOpts = sparkJavaOpts ++ extraJavaOpts
        val command = new Command(mainClass,
          Seq("{{WORKER_URL}}", "{{USER_JAR}}", driverArgs.mainClass) ++ driverArgs.driverOptions,
          sys.env, classPathEntries, libraryPathEntries, javaOpts)
        // driver 的描述
        val driverDescription = new DriverDescription(
          driverArgs.jarUrl,
          driverArgs.memory,
          driverArgs.cores,
          driverArgs.supervise,
          command)
        // 这里发送消息给master,让master选择worker来启动 driver
        asyncSendToMasterAndForwardReply[SubmitDriverResponse](
          RequestSubmitDriver(driverDescription))
      // 停止 driver
      case "kill" =>
        val driverId = driverArgs.driverId
        asyncSendToMasterAndForwardReply[KillDriverResponse](RequestKillDriver(driverId))
    }
  }

```

```scala
  private def asyncSendToMasterAndForwardReply[T: ClassTag](message: Any): Unit = {
    for (masterEndpoint <- masterEndpoints) {
      masterEndpoint.ask[T](message).onComplete {
        case Success(v) => self.send(v)
        case Failure(e) =>
          logWarning(s"Error sending messages to master $masterEndpoint", e)
      }(forwardMessageExecutionContext)
    }
  }
```

下面看一下master对消息RequestSubmitDriver 的处理:

```scala
  override def receiveAndReply(context: RpcCallContext): PartialFunction[Any, Unit] = {
        // client向master 发送的 提交drive的消息
    case RequestSubmitDriver(description) =>
      if (state != RecoveryState.ALIVE) {
        val msg = s"${Utils.BACKUP_STANDALONE_MASTER_PREFIX}: $state. " +
          "Can only accept driver submissions in ALIVE state."
        context.reply(SubmitDriverResponse(self, false, None, msg))
      } else {
        logInfo("Driver submitted " + description.command.mainClass)
        // 创建driver
        val driver = createDriver(description)
        // 持久化引擎 添加  driver
        persistenceEngine.addDriver(driver)
        // 此driver只是创建好了,并没有启动运行,所以先记录到 waitingDrivers
        waitingDrivers += driver
        // 并把此driver 记录到 drivers
        drivers.add(driver)
        // 调度; 也就是在 worker中查找合适的worker 来启动driver
        schedule()

        // TODO: It might be good to instead have the submission client poll the master to determine
        //       the current status of the driver. For now it's simply "fire and forget".
        // 回复消息
        context.reply(SubmitDriverResponse(self, true, Some(driver.id),
          s"Driver successfully submitted as ${driver.id}"))
      }
      ....
      // 省略部分函数体,只看重点
  }
```

```scala
// 创建 driver  
private def createDriver(desc: DriverDescription): DriverInfo = {
    val now = System.currentTimeMillis()
    val date = new Date(now)
    new DriverInfo(now, newDriverId(date), desc, date)
  }
```



```scala
  private def schedule(): Unit = {
    // 如果状态不是  ALIVE,则不进行调度工作
    if (state != RecoveryState.ALIVE) {
      return
    }
    // Drivers take strict precedence over executors
    // 获取ALIVE 的 worker
    val shuffledAliveWorkers = Random.shuffle(workers.toSeq.filter(_.state == WorkerState.ALIVE))
    // 存活的 worker的 数量
    val numWorkersAlive = shuffledAliveWorkers.size
    var curPos = 0
    // 遍历所有正在等待的 driver
    for (driver <- waitingDrivers.toList) { // iterate over a copy of waitingDrivers
      // We assign workers to each waiting driver in a round-robin fashion. For each driver, we
      // start from the last worker that was assigned a driver, and continue onwards until we have
      // explored all alive workers.
      var launched = false
      var numWorkersVisited = 0
        // 查找 合适的worker
      while (numWorkersVisited < numWorkersAlive && !launched) {
        val worker = shuffledAliveWorkers(curPos)
        numWorkersVisited += 1
        if (worker.memoryFree >= driver.desc.mem && worker.coresFree >= driver.desc.cores) {
          // 启动driver
          launchDriver(worker, driver)
          waitingDrivers -= driver
          launched = true
        }
        curPos = (curPos + 1) % numWorkersAlive
      }
    }
    // 在worker上启动 executors
    startExecutorsOnWorkers()
  }
```

```scala
  private def launchDriver(worker: WorkerInfo, driver: DriverInfo) {
    logInfo("Launching driver " + driver.id + " on worker " + worker.id)
    worker.addDriver(driver)
    // 记录此driver 要在哪里运行
    driver.worker = Some(worker)
    // 发送LaunchDriver 消息到 worker
    // 向要运行driver的 worker发送消息
    worker.endpoint.send(LaunchDriver(driver.id, driver.desc))
    driver.state = DriverState.RUNNING
  }
```

下面咱们看 worker对消息 LaunchDriver的处理:

```scala
// 省略部分的函数体, 只看关键部分
override def receive: PartialFunction[Any, Unit] = synchronized {
    ....
	// master发送过来的启动 driver的消息
    case LaunchDriver(driverId, driverDesc) =>
      logInfo(s"Asked to launch driver $driverId")
      // 使用DriverRunner 封装要运行的driver的信息
      val driver = new DriverRunner(
        conf,
        driverId,
        workDir,
        sparkHome,
        driverDesc.copy(command = Worker.maybeUpdateSSLSettings(driverDesc.command, conf)),
        self,
        workerUri,
        securityMgr)
      // 保存创建的 DriverRunner
      drivers(driverId) = driver
      // driverde启动
      driver.start()
      // 已经的核数 和 内存 增加
      coresUsed += driverDesc.cores
      memoryUsed += driverDesc.mem
    ....
}
```

```scala
 // driver的启动
  private[worker] def start() = {
    new Thread("DriverRunner for " + driverId) {
      override def run() {
        var shutdownHook: AnyRef = null
        try {
          shutdownHook = ShutdownHookManager.addShutdownHook { () =>
            logInfo(s"Worker shutting down, killing driver $driverId")
            kill()
          }
          // prepare driver jars and run driver
          // 运行 driver
          // 重点
          val exitCode = prepareAndRunDriver()
          // set final state depending on if forcibly killed and process exit code
          finalState = if (exitCode == 0) {
            Some(DriverState.FINISHED)
          } else if (killed) {
            Some(DriverState.KILLED)
          } else {
            Some(DriverState.FAILED)
          }
        } catch {
          case e: Exception =>
            kill()
            finalState = Some(DriverState.ERROR)
            finalException = Some(e)
        } finally {
          if (shutdownHook != null) {
            ShutdownHookManager.removeShutdownHook(shutdownHook)
          }
        }
        // notify worker of final driver state, possible exception
        worker.send(DriverStateChanged(driverId, finalState.get, finalException))
      }
    }.start()
  }
```

```scala
  private[worker] def prepareAndRunDriver(): Int = {
    // 常见driver的工作目录
    val driverDir = createWorkingDirectory()
    // 下载 jar包到本地
    val localJarFilename = downloadUserJar(driverDir)

    def substituteVariables(argument: String): String = argument match {
      case "{{WORKER_URL}}" => workerUrl
      case "{{USER_JAR}}" => localJarFilename
      case other => other
    }
    // TODO: If we add ability to submit multiple jars they should also be added here
    // 重点 buildProcessBuilder 使用java.lang.ProcessBuilder 来构建启动操作系统进程的命令
    val builder = CommandUtils.buildProcessBuilder(driverDesc.command, securityManager,
      driverDesc.mem, sparkHome.getAbsolutePath, substituteVariables)
    // 运行 driver
    // 运行上面 创建的进程的命令
    runDriver(builder, driverDir, driverDesc.supervise)
  }
```

```scala
  // 启动driver
  private def runDriver(builder: ProcessBuilder, baseDir: File, supervise: Boolean): Int = {
    builder.directory(baseDir)
    // 初始化函数
    def initialize(process: Process): Unit = {
      // Redirect stdout and stderr to files
      val stdout = new File(baseDir, "stdout")
      CommandUtils.redirectStream(process.getInputStream, stdout)

      val stderr = new File(baseDir, "stderr")
      val formattedCommand = builder.command.asScala.mkString("\"", "\" \"", "\"")
      val header = "Launch Command: %s\n%s\n\n".format(formattedCommand, "=" * 40)
      Files.append(header, stderr, StandardCharsets.UTF_8)
      CommandUtils.redirectStream(process.getErrorStream, stderr)
    }
    runCommandWithRetry(ProcessBuilderLike(builder), initialize, supervise)
  }
```

```scala
private[deploy] object ProcessBuilderLike {
  def apply(processBuilder: ProcessBuilder): ProcessBuilderLike = new ProcessBuilderLike {
    override def start(): Process = processBuilder.start()
    override def command: Seq[String] = processBuilder.command().asScala
  }
}
```

```scala
  private[worker] def runCommandWithRetry(
      command: ProcessBuilderLike, initialize: Process => Unit, supervise: Boolean): Int = {
    var exitCode = -1
    // Time to wait between submission retries.
    var waitSeconds = 1
    // A run of this many seconds resets the exponential back-off.
    val successfulRunDuration = 5
    var keepTrying = !killed

    while (keepTrying) {
      logInfo("Launch Command: " + command.command.mkString("\"", "\" \"", "\""))

      synchronized {
        if (killed) { return exitCode }
        // driver的启动  command.start()
        // 重点  driver的启动
        // drive的启动类 org.apache.spark.deploy.worker.DriverWrapper
          // 就在这里真正启动了
        process = Some(command.start())
        // driver的初始化
        initialize(process.get)
      }
      val processStart = clock.getTimeMillis()
      exitCode = process.get.waitFor()

      // check if attempting another run
      keepTrying = supervise && exitCode != 0 && !killed
      if (keepTrying) {
        if (clock.getTimeMillis() - processStart > successfulRunDuration * 1000L) {
          waitSeconds = 1
        }
        logInfo(s"Command exited with status $exitCode, re-launching after $waitSeconds s.")
        sleeper.sleep(waitSeconds)
        waitSeconds = waitSeconds * 2 // exponential back-off
      }
    }
    exitCode
  }
}
```

到这里driver的启动工作就准备完毕了，下面是真正的启动，看一下driver操作吧:

```scala
// driver的启动类 入口
object DriverWrapper extends Logging {
  def main(args: Array[String]) {
    args.toList match {
        // workerUrl 要WorkerWatcher 监视的 worker
      case workerUrl :: userJar :: mainClass :: extraArgs =>
        val conf = new SparkConf()
        val host: String = Utils.localHostName()
        val port: Int = sys.props.getOrElse("spark.driver.port", "0").toInt
        // 熟悉不?  到这里创建  RpcEnv
        // 嗯,就是消息的分发, 以及 和netty的联系
        val rpcEnv = RpcEnv.create("Driver", host, port, conf, new SecurityManager(conf))
        logInfo(s"Driver address: ${rpcEnv.address}")
        // 这里创建 WorkerWatcher
        rpcEnv.setupEndpoint("workerWatcher", new WorkerWatcher(rpcEnv, workerUrl))
        val currentLoader = Thread.currentThread.getContextClassLoader
        val userJarUrl = new File(userJar).toURI().toURL()
        val loader =
          if (sys.props.getOrElse("spark.driver.userClassPathFirst", "false").toBoolean) {
            new ChildFirstURLClassLoader(Array(userJarUrl), currentLoader)
          } else {
            new MutableURLClassLoader(Array(userJarUrl), currentLoader)
          }
        Thread.currentThread.setContextClassLoader(loader)
        setupDependencies(loader, userJar)

        // Delegate to supplied main class
        // 这里才是 用于声明的 任务类
        // 也就是在 加载 用户定义的任务类
        val clazz = Utils.classForName(mainClass)
        // 获取人物类的入口函数  main
        val mainMethod = clazz.getMethod("main", classOf[Array[String]])
        // 调用main  方法
        // 也就是在这里 开始执行 用户任务
        // 也就是说,最终的application 是由用户的程序提价的
        // 在详细点说,是否具体的 action RDD 来进行的任务提交
        mainMethod.invoke(null, extraArgs.toArray[String])
        rpcEnv.shutdown()
      case _ =>
        // scalastyle:off println
        System.err.println("Usage: DriverWrapper <workerUrl> <userJar> <driverMainClass> [options]")
        // scalastyle:on println
        System.exit(-1)
    }
  }
```

好的，到这里cluster模式下的driver就启动完成了。下篇总结下application任务的提交的总体轮廓。

从这里也看出了driver和application的关系，在cluster模式下，driver启动了用户的任务(application)，然后用户的任务找worker来启动具体的任务。