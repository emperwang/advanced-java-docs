[TOC]

# DAGScheduler

前面分析了schedulerBackend 以及 TaskSchedulerImpl，启动了executor并进行了注册，现在拉回主线，继续看一下sparkContext初始化中对于DAGScheduler的初始化。

前景回顾:

```scala
    // 创建 taskScheduler 和 backend
    val (sched, ts) = SparkContext.createTaskScheduler(this, master, deployMode)
    _schedulerBackend = sched
    _taskScheduler = ts
    // 创建 DAGScheduler
    _dagScheduler = new DAGScheduler(this)
    // 发送一个 TaskSchedulerIsSet 的消息
    _heartbeatReceiver.ask[Boolean](TaskSchedulerIsSet)
    // start TaskScheduler after taskScheduler sets DAGScheduler reference in DAGScheduler's
    // constructor
    _taskScheduler.start()
```

DAGscheduler 的构造函数

```scala
private[spark] class DAGScheduler(
    private[scheduler] val sc: SparkContext,
    private[scheduler] val taskScheduler: TaskScheduler,
    listenerBus: LiveListenerBus,
    mapOutputTracker: MapOutputTrackerMaster,
    blockManagerMaster: BlockManagerMaster,
    env: SparkEnv,
    clock: Clock = new SystemClock())
extends Logging {
    // 辅助构造函数
    def this(sc: SparkContext, taskScheduler: TaskScheduler) = {
        this(
            sc,
            taskScheduler,
            sc.listenerBus,
            sc.env.mapOutputTracker.asInstanceOf[MapOutputTrackerMaster],
            sc.env.blockManager.master,
            sc.env)
    }
    // 辅助构造函数
    def this(sc: SparkContext) = this(sc, sc.taskScheduler)
    //  DAGSchedulerSource的创建
    private[spark] val metricsSource: DAGSchedulerSource = new DAGSchedulerSource(this)
    // 下一个job的ID生成 策略
    private[scheduler] val nextJobId = new AtomicInteger(0)
    // 总的job数量
    private[scheduler] def numTotalJobs: Int = nextJobId.get()
    // stageId的生成
    private val nextStageId = new AtomicInteger(0)
    // jobId 和 stageId的映射关系
    private[scheduler] val jobIdToStageIds = new HashMap[Int, HashSet[Int]]
    // stageId和 stage的映射关系
    private[scheduler] val stageIdToStage = new HashMap[Int, Stage]

    // shuffleId和mapStage的映射关系
    private[scheduler] val shuffleIdToMapStage = new HashMap[Int, ShuffleMapStage]
    // jobId 和 activeJob的映射关系
    private[scheduler] val jobIdToActiveJob = new HashMap[Int, ActiveJob]

    // Stages we need to run whose parents aren't done
    // 等待的 stage
    private[scheduler] val waitingStages = new HashSet[Stage]

    // Stages we are running right now
    // 正在运行的 stage
    private[scheduler] val runningStages = new HashSet[Stage]

    // Stages that must be resubmitted due to fetch failures
    // 失败的stage
    private[scheduler] val failedStages = new HashSet[Stage]
    // activeJobs 的记录
    private[scheduler] val activeJobs = new HashSet[ActiveJob]

    // 缓存的 localtion
    private val cacheLocs = new HashMap[Int, IndexedSeq[Seq[TaskLocation]]]

    // 失败的  epoch
    private val failedEpoch = new HashMap[String, Long]
    //
    private [scheduler] val outputCommitCoordinator = env.outputCommitCoordinator

    // A closure serializer that we reuse.
    // This is only safe because DAGScheduler runs in a single thread.
    // 闭包序列化 工具
    private val closureSerializer = SparkEnv.get.closureSerializer.newInstance()

    /** If enabled, FetchFailed will not cause stage retry, in order to surface the problem. */
    private val disallowStageRetryForTest = sc.getConf.getBoolean("spark.test.noStageRetry", false)

    private[scheduler] val unRegisterOutputOnHostOnFetchFailure =
    sc.getConf.get(config.UNREGISTER_OUTPUT_ON_HOST_ON_FETCH_FAILURE)

    /**
   * Number of consecutive stage attempts allowed before a stage is aborted.
   */
    private[scheduler] val maxConsecutiveStageAttempts =
    sc.getConf.getInt("spark.stage.maxConsecutiveAttempts",
                      DAGScheduler.DEFAULT_MAX_CONSECUTIVE_STAGE_ATTEMPTS)

    /**
   * Number of max concurrent tasks check failures for each barrier job.
   */
    private[scheduler] val barrierJobIdToNumTasksCheckFailures = new ConcurrentHashMap[Int, Int]

    /**
   * Time in seconds to wait between a max concurrent tasks check failure and the next check.
   */
    private val timeIntervalNumTasksCheck = sc.getConf
    .get(config.BARRIER_MAX_CONCURRENT_TASKS_CHECK_INTERVAL)

    /**
   * Max number of max concurrent tasks check failures allowed for a job before fail the job
   * submission.
   */
    private val maxFailureNumTasksCheck = sc.getConf
    .get(config.BARRIER_MAX_CONCURRENT_TASKS_CHECK_MAX_FAILURES)

    private val messageScheduler =
    ThreadUtils.newDaemonSingleThreadScheduledExecutor("dag-scheduler-message")
    //eventProcessLoop 是处理消息
    private[spark] val eventProcessLoop = new DAGSchedulerEventProcessLoop(this)
    taskScheduler.setDAGScheduler(this)

    // 注意这里哦，这是一个特别特别容易出错误，遗漏的一个地方,虽然不是难点,但是注意一些此 语句的位置
    // 此语句的位置,在此类的最后一句 
      // 在这里启动了消费消息的线程
  eventProcessLoop.start()
    
 ....   
}
```

在此构造函数中看一下此句:

```scala
//eventProcessLoop 是处理消息
    private[spark] val eventProcessLoop = new DAGSchedulerEventProcessLoop(this)
    taskScheduler.setDAGScheduler(this)
```

此DAGSchedulerEventProcessLoop是一个内部类，EventLoop的子类。

看一下EventLoop的内容：

```scala
// 省略部分内容,只看一下一些重要的方法
private[spark] abstract class EventLoop[E](name: String) extends Logging {
    // 事件的存储队列
    private val eventQueue: BlockingQueue[E] = new LinkedBlockingDeque[E]()
    // 是否停止
    private val stopped = new AtomicBoolean(false)
    // 事件处理线程
    // 此线程的主要任务就是消费 eventQueue中的消息,并调用子类的处理方法
    private[spark] val eventThread = new Thread(name) {
	// 设置为后台线程
        setDaemon(true)
        override def run(): Unit = {
            try {
                // 没有停止
                while (!stopped.get) {
                    // 获取消息
                    val event = eventQueue.take()
                    try {
                        // 具体消息处理方法
                        // 此处理在子类中实现 org.apache.spark.scheduler.DAGSchedulerEventProcessLoop
                        onReceive(event)
                    } catch {
                        case NonFatal(e) =>
                        try {
                            // 出现 error 就处理error
                            onError(e)
                        } catch {
                            case NonFatal(e) => logError("Unexpected error in " + name, e)
                        }
                    }
                }
            } catch {
                case ie: InterruptedException => // exit even if eventQueue is not empty
                case NonFatal(e) => logError("Unexpected error in " + name, e)
            }
        }

    }
	// 启动,就是启动eventThread这个消费的线程
    def start(): Unit = {
        if (stopped.get) {
            throw new IllegalStateException(name + " has already been stopped")
        }
        // Call onStart before starting the event thread to make sure it happens before onReceive
        onStart()
        // 启动线程
        eventThread.start()
    }

    /**
   * Put the event into the event queue. The event thread will process it later.
   */
    // 消息的发送
    def post(event: E): Unit = {
        // 可以看到发送消息就是 向队列中 添加消息
        eventQueue.put(event)
    }
    
....
}

```

可以看到此就很明显了，父类是一个线程，调用子类的具体的处理方法，熟悉不，嗯，对了，就是模板设计模式。

子线程的处理:

> org.apache.spark.scheduler.DAGSchedulerEventProcessLoop#onReceive

```scala
  override def onReceive(event: DAGSchedulerEvent): Unit = {
    val timerContext = timer.time()
    try {
      doOnReceive(event)
    } finally {
      timerContext.stop()
    }
  }
```

具体的处理函数:

```scala
// 可以看到这里，根据不同的事件，具体进行不同的处理
private def doOnReceive(event: DAGSchedulerEvent): Unit = event match {
      // 任务提交事件 ; 处理任务的提交
    // job的提交
    case JobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties) =>
      dagScheduler.handleJobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties)
	// MapStage的提交
    case MapStageSubmitted(jobId, dependency, callSite, listener, properties) =>
      dagScheduler.handleMapStageSubmitted(jobId, dependency, callSite, listener, properties)
	// stage取消
    case StageCancelled(stageId, reason) =>
      dagScheduler.handleStageCancellation(stageId, reason)
	// job取消事件
    case JobCancelled(jobId, reason) =>
      dagScheduler.handleJobCancellation(jobId, reason)
	// jobGroup 取消事件
    case JobGroupCancelled(groupId) =>
      dagScheduler.handleJobGroupCancelled(groupId)
	// alljob 取消事件
    case AllJobsCancelled =>
      dagScheduler.doCancelAllJobs()
	// executor添加事件
    case ExecutorAdded(execId, host) =>
      dagScheduler.handleExecutorAdded(execId, host)
	// executorLost 事件
    case ExecutorLost(execId, reason) =>
      val workerLost = reason match {
        case SlaveLost(_, true) => true
        case _ => false
      }
      dagScheduler.handleExecutorLost(execId, workerLost)
	// workerRemoved 事件
    case WorkerRemoved(workerId, host, message) =>
      dagScheduler.handleWorkerRemoved(workerId, host, message)
	// 
    case BeginEvent(task, taskInfo) =>
      dagScheduler.handleBeginEvent(task, taskInfo)
	// 
    case SpeculativeTaskSubmitted(task) =>
      dagScheduler.handleSpeculativeTaskSubmitted(task)
	// GettingResultEvent  事件
    case GettingResultEvent(taskInfo) =>
      dagScheduler.handleGetTaskResult(taskInfo)
	// 完成 事件
    case completion: CompletionEvent =>
      dagScheduler.handleTaskCompletion(completion)
	// taskSet 失败事件
    case TaskSetFailed(taskSet, reason, exception) =>
      dagScheduler.handleTaskSetFailed(taskSet, reason, exception)
	// ResubmitFailedStages 重新提交stage失败事件
    case ResubmitFailedStages =>
      dagScheduler.resubmitFailedStages()
  }
```

DAGSchedular初始化就先到这里，大概了解其中的事件，以及事件处理就可以了，因为事件处理后面会用到。





































