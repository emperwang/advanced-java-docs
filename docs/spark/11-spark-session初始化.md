[TOC]

# SparkSession的初始化

前面分析了Master以及Worker的启动，以及提交任务后，master会查找合适的worker来启动Driver，之后driver会运行用户的类，回顾一下driver的操作：

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

从上面的代码mainMethod.invoke看到，开始调用用户提交的任务，所以从本篇开始，咱们就开始从自己提交的任务为入口进行正向任务提交的分析。

回顾一下提交的任务代码:

```scala
object SparkPi {
    def main(args: Array[String]) {
        System.setProperty("spark.master", "local")
        val spark = SparkSession
        .builder
        .appName("Spark Pi")
        .getOrCreate()
        val slices = if (args.length > 0) args(0).toInt else 2
        val n = math.min(100000L * slices, Int.MaxValue).toInt // avoid overflow
        val count = spark.sparkContext.parallelize(1 until n, slices).map { i =>
            val x = random * 2 - 1
            val y = random * 2 - 1
            if (x*x + y*y <= 1) 1 else 0
        }.reduce(_ + _)
        println(s"Pi is roughly ${4.0 * count / (n - 1)}")
        spark.stop()
    }
}
```

嗯，很熟悉是吧，没错，就是spark自带的example。

本篇分析一下SparkSession的初始化：

```scala
val spark = SparkSession
        .builder
        .appName("Spark Pi")
        .getOrCreate()
// 创建一个builder
def builder(): Builder = new Builder
```

> org.apache.spark.sql.SparkSession.Builder

```scala
// builder 的构造函数
class Builder extends Logging {

    private[this] val options = new scala.collection.mutable.HashMap[String, String]

    private[this] val extensions = new SparkSessionExtensions
    // 用户提供了 sparkContext
    private[this] var userSuppliedContext: Option[SparkContext] = None
     
      ...
  }
```

> org.apache.spark.sql.SparkSession.Builder#appName

```scala
def appName(name: String): Builder = config("spark.app.name", name)

// 记录下配置属性
def config(key: String, value: String): Builder = synchronized {
    // 可以看到此处添加 option就是添加到 options那个容器中
    options += key -> value
    this
}
```

> org.apache.spark.sql.SparkSession.Builder#getOrCreate

```scala
// threadLocal中保存的 sparkSession
private val activeThreadSession = new InheritableThreadLocal[SparkSession]
// 保存sparkSession
private val defaultSession = new AtomicReference[SparkSession]

def getOrCreate(): SparkSession = synchronized {
    assertOnDriver()
    // Get the session from current thread's active session.
    // 从threadLocal中获取 sparkSession
    var session = activeThreadSession.get()
    // 如果sparkSession存在,且没有关闭,则把options中配置,配置到此sparkSession的配置中
    if ((session ne null) && !session.sparkContext.isStopped) {
        applyModifiableSettings(session)
        return session
    }
    // Global synchronization so we will only set the default session once.
    SparkSession.synchronized {
        // If the current thread does not have an active session, get it from the global session.
        session = defaultSession.get()
        if ((session ne null) && !session.sparkContext.isStopped) {
            applyModifiableSettings(session)
            return session
        }
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

        // Initialize extensions if the user has defined a configurator class.
        val extensionConfOption = sparkContext.conf.get(StaticSQLConf.SPARK_SESSION_EXTENSIONS)
        if (extensionConfOption.isDefined) {
            val extensionConfClassName = extensionConfOption.get
            try {
                val extensionConfClass = Utils.classForName(extensionConfClassName)
                val extensionConf = extensionConfClass.newInstance()
                .asInstanceOf[SparkSessionExtensions => Unit]
                extensionConf(extensions)
            } catch {
                // Ignore the error if we cannot find the class or when the class has the wrong type.
                case e @ (_: ClassCastException |
                          _: ClassNotFoundException |
                          _: NoClassDefFoundError) =>
                logWarning(s"Cannot use $extensionConfClassName to configure session extensions.", e)
            }
        }
        // 创建sparkSession
        session = new SparkSession(sparkContext, None, None, extensions)
        options.foreach { case (k, v) => session.initialSessionOptions.put(k, v) }
        // 保存创建的 sparkSession
        setDefaultSession(session)
        // sparkSession放入到 threadLocal中
        setActiveSession(session)
        // Register a successfully instantiated context to the singleton. This should be at the
        // end of the class definition so that the singleton is updated only if there is no
        // exception in the construction of the instance.
        sparkContext.addSparkListener(new SparkListener {
            override def onApplicationEnd(applicationEnd: SparkListenerApplicationEnd): Unit = {
                defaultSession.set(null)
            }
        })
    }
    return session
}
```

简单总结一下此函数功能：

1. 如果已经有sparkSession，则直接返回
2. 创建SparkConf，并把builder中的option设置到sparkConf
3. 创建sparkContext
4. 创建sparkSession
5. 向sparkContext中注册一个监听器，当应用结束时，清空 defaultSesion

sparkContext的初始化下篇讲，本篇对此就不深入说了。

> org.apache.spark.sql.SparkSession#SparkSession

```scala
// sparkSession 的构造函数
class SparkSession private(
    @transient val sparkContext: SparkContext,
    @transient private val existingSharedState: Option[SharedState],
    @transient private val parentSessionState: Option[SessionState],
    @transient private[sql] val extensions: SparkSessionExtensions)
extends Serializable with Closeable with Logging { self =>
    // The call site where this SparkSession was constructed.
    private val creationSite: CallSite = Utils.getCallSite()
    // sparkSession的辅助构造函数
    private[sql] def this(sc: SparkContext) {
        this(sc, None, None, new SparkSessionExtensions)
    }
    // 判断sparkContext是否停止
    sparkContext.assertNotStopped()
    // If there is no active SparkSession, uses the default SQL conf. Otherwise, use the session's.
    SQLConf.setSQLConfGetter(() => {
        SparkSession.getActiveSession.filterNot(_.sparkContext.isStopped).map(_.sessionState.conf)
        .getOrElse(SQLConf.getFallbackConf)
    })

    // 记录版本号
    def version: String = SPARK_VERSION
    // 
    lazy val sharedState: SharedState = {
        existingSharedState.getOrElse(new SharedState(sparkContext))
    }
	//
    private[sql] val initialSessionOptions = new scala.collection.mutable.HashMap[String, String]
    // 
    lazy val sessionState: SessionState = {
        parentSessionState
        .map(_.clone(this))
        .getOrElse {
            val state = SparkSession.instantiateSessionState(
                SparkSession.sessionStateClassName(sparkContext.conf),
                self)
            initialSessionOptions.foreach { case (k, v) => state.conf.setConfString(k, v) }
            state
        }
    }
    // 
    val sqlContext: SQLContext = new SQLContext(this)
    // 
    lazy val conf: RuntimeConfig = new RuntimeConfig(sessionState.conf)
    // 
    lazy val emptyDataFrame: DataFrame = {
        createDataFrame(sparkContext.emptyRDD[Row].setName("empty"), StructType(Nil))
    }
    // 
    lazy val catalog: Catalog = new CatalogImpl(self)
```

创建好之后，保存一下，就返回创建的sparkSession了。重点功能是创建了SparkContext。















