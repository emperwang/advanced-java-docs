[TOC]

# reduce 任务提交

经过前面分析SparkContext就初始化完成了，接下来咱们看一下提交的任务操作。

回顾一下提交的任务主类：

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

spark.sparkContext.parallelize(1 until n, slices).map  这些操作只是创建了RDD，真正的提交在reduce中：

> org.apache.spark.rdd.RDD#reduce

```scala
  def reduce(f: (T, T) => T): T = withScope {
    // 对function做一些清理 ---  作用 ??
    val cleanF = sc.clean(f)
    // reduce的分区
    val reducePartition: Iterator[T] => Option[T] = iter => {
      if (iter.hasNext) {
        Some(iter.reduceLeft(cleanF))
      } else {
        None
      }
    }
    // jobResult 存储最终的结果
    var jobResult: Option[T] = None
    // 定义一个函数,最后合并结果的函数
    val mergeResult = (index: Int, taskResult: Option[T]) => {
      if (taskResult.isDefined) {
        jobResult = jobResult match {
          case Some(value) => Some(f(value, taskResult.get))
          case None => taskResult
        }
      }
    }
    // 提交任务
    sc.runJob(this, reducePartition, mergeResult)
    // Get the final result out of our Option, or throw an exception if the RDD was empty
    // 获取最终的结果
    jobResult.getOrElse(throw new UnsupportedOperationException("empty collection"))
  }
```

> org.apache.spark.SparkContext#runJob

```scala
  def runJob[T, U: ClassTag](
      rdd: RDD[T],
      processPartition: Iterator[T] => U,
      resultHandler: (Int, U) => Unit)
  {
    val processFunc = (context: TaskContext, iter: Iterator[T]) => processPartition(iter)
    // 提交job
    // resultHandler  用于合并结果的函数
    // rdd.partitions.length rdd的分区数
    // processPartition  传递进来的对分区的处理
    // rdd   具体要处理的结果集
    runJob[T, U](rdd, processFunc, 0 until rdd.partitions.length, resultHandler)
  }
```

> org.apache.spark.SparkContext#runJob

```scala
def runJob[T, U: ClassTag](
    rdd: RDD[T],
    func: (TaskContext, Iterator[T]) => U,
    partitions: Seq[Int],
    resultHandler: (Int, U) => Unit): Unit = {
    // 如果已经停止了, 则抛错
    if (stopped.get()) {
        throw new IllegalStateException("SparkContext has been shutdown")
    }
    val callSite = getCallSite
    val cleanedFunc = clean(func)
    logInfo("Starting job: " + callSite.shortForm)
    if (conf.getBoolean("spark.logLineage", false)) {
        logInfo("RDD's recursive dependencies:\n" + rdd.toDebugString)
    }
    // 任务提交
    // 使用 sparkContext -> dagScheduler 提交任务
    // 到这里先看一下 sparkContext中 dagScheduler的初始化, 看起初始化的具体的哪一个类,做了哪些工作
    // 在这里就用到了前面初始化的 DagScheduler 来进行任务的提交
    dagScheduler.runJob(rdd, cleanedFunc, partitions, callSite, resultHandler, localProperties.get)
    progressBar.foreach(_.finishAll())
    // checkPoint
    rdd.doCheckpoint()
}
```

> org.apache.spark.scheduler.DAGScheduler#runJob

```scala
def runJob[T, U](
    rdd: RDD[T],
    func: (TaskContext, Iterator[T]) => U,
    partitions: Seq[Int],
    callSite: CallSite,
    resultHandler: (Int, U) => Unit,
    properties: Properties): Unit = {
    // 记录任务的开始时间
    val start = System.nanoTime
    // 提交任务  重点在这里
    val waiter = submitJob(rdd, func, partitions, callSite, resultHandler, properties)
    // 等待任务完成
    ThreadUtils.awaitReady(waiter.completionFuture, Duration.Inf)
    // 根据任务完成后的结果,来进行打印
    waiter.completionFuture.value.get match {
        case scala.util.Success(_) =>
        logInfo("Job %d finished: %s, took %f s".format
                (waiter.jobId, callSite.shortForm, (System.nanoTime - start) / 1e9))
        case scala.util.Failure(exception) =>
        logInfo("Job %d failed: %s, took %f s".format
                (waiter.jobId, callSite.shortForm, (System.nanoTime - start) / 1e9))
        // SPARK-8644: Include user stack trace in exceptions coming from DAGScheduler.
        val callerStackTrace = Thread.currentThread().getStackTrace.tail
        exception.setStackTrace(exception.getStackTrace ++ callerStackTrace)
        throw exception
    }
}
```

> org.apache.spark.scheduler.DAGScheduler#submitJob

```scala
def submitJob[T, U](
    rdd: RDD[T],
    func: (TaskContext, Iterator[T]) => U,
    partitions: Seq[Int],
    callSite: CallSite,
    resultHandler: (Int, U) => Unit,
    properties: Properties): JobWaiter[U] = {
    // Check to make sure we are not launching a task on a partition that does not exist.
    val maxPartitions = rdd.partitions.length
    partitions.find(p => p >= maxPartitions || p < 0).foreach { p =>
        throw new IllegalArgumentException(
            "Attempting to access a non-existent partition: " + p + ". " +
            "Total number of partitions: " + maxPartitions)
    }

    val jobId = nextJobId.getAndIncrement()
    if (partitions.size == 0) {
        // Return immediately if the job is running 0 tasks
        return new JobWaiter[U](this, jobId, 0, resultHandler)
    }

    assert(partitions.size > 0)
    val func2 = func.asInstanceOf[(TaskContext, Iterator[_]) => _]
    val waiter = new JobWaiter(this, jobId, partitions.size, resultHandler)
    // 发送一个任务提交事件 JobSubmitted
    // 看到了哦,这里提交任务,其实就是发送了一个事件到 eventProcessLoop中
    // 所以下面要看一下  eventLoop对这个事件的处理 
    eventProcessLoop.post(JobSubmitted(
        jobId, rdd, func2, partitions.toArray, callSite, waiter,
        SerializationUtils.clone(properties)))
    waiter
}
```

> org.apache.spark.scheduler.DAGSchedulerEventProcessLoop#doOnReceive

```scala
// 这里省略了部分函数体,  只看主要的
private def doOnReceive(event: DAGSchedulerEvent): Unit = event match {
    // 任务提交事件 ; 处理任务的提交
    case JobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties) =>
    // 处理任务,并进行提交
    dagScheduler.handleJobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties)
    
    .....
}
```

> org.apache.spark.scheduler.DAGScheduler#handleJobSubmitted

```scala
// 处理任务的提交
private[scheduler] def handleJobSubmitted(jobId: Int,
                                          finalRDD: RDD[_],
                                          func: (TaskContext, Iterator[_]) => _,
                                          partitions: Array[Int],
                                          callSite: CallSite,
                                          listener: JobListener,
                                          properties: Properties) {
    var finalStage: ResultStage = null
    try {
        // New stage creation may throw an exception if, for example, jobs are run on a
        // HadoopRDD whose underlying HDFS files have been deleted.
        // 创建 ResultStage
        // 重要 
        // 这里进行了 stage的划分
        finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)
    } catch {
        case e: BarrierJobSlotsNumberCheckFailed =>
        logWarning(s"The job $jobId requires to run a barrier stage that requires more slots " +
                   "than the total number of slots in the cluster currently.")
        // If jobId doesn't exist in the map, Scala coverts its value null to 0: Int automatically.
        val numCheckFailures = barrierJobIdToNumTasksCheckFailures.compute(jobId,
        new BiFunction[Int, Int, Int] {override def apply(key: Int, value: Int): Int = value + 1})
        if (numCheckFailures <= maxFailureNumTasksCheck) {
            messageScheduler.schedule(
                new Runnable {
                    override def run(): Unit = eventProcessLoop.post(JobSubmitted(jobId, finalRDD, 				func,partitions, callSite, listener, properties))
                },
                timeIntervalNumTasksCheck,
                TimeUnit.SECONDS
            )
            return
        } else {
            // Job failed, clear internal data.
            barrierJobIdToNumTasksCheckFailures.remove(jobId)
            listener.jobFailed(e)
            return
        }
        case e: Exception =>
        logWarning("Creating new stage failed due to exception - job: " + jobId, e)
        listener.jobFailed(e)
        return
    }
    // Job submitted, clear internal data.
    barrierJobIdToNumTasksCheckFailures.remove(jobId)

    val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)
    clearCacheLocs()
    logInfo("Got job %s (%s) with %d output partitions".format(
        job.jobId, callSite.shortForm, partitions.length))
    logInfo("Final stage: " + finalStage + " (" + finalStage.name + ")")
    logInfo("Parents of final stage: " + finalStage.parents)
    logInfo("Missing parents: " + getMissingParentStages(finalStage))

    val jobSubmissionTime = clock.getTimeMillis()
    jobIdToActiveJob(jobId) = job
    activeJobs += job
    finalStage.setActiveJob(job)
    val stageIds = jobIdToStageIds(jobId).toArray
    val stageInfos = stageIds.flatMap(id => stageIdToStage.get(id).map(_.latestInfo))
    // 向消息总线发送消息  SparkListenerJobStart
    listenerBus.post(
        SparkListenerJobStart(job.jobId, jobSubmissionTime, stageInfos, properties))

    // 重点
    // 提交stage
    submitStage(finalStage)
}
```

> org.apache.spark.scheduler.DAGScheduler#createResultStage

```scala
 private def createResultStage(
      rdd: RDD[_],
      func: (TaskContext, Iterator[_]) => _,
      partitions: Array[Int],
      jobId: Int,
      callSite: CallSite): ResultStage = {
    checkBarrierStageWithDynamicAllocation(rdd)
    checkBarrierStageWithNumSlots(rdd)
    checkBarrierStageWithRDDChainPattern(rdd, partitions.toSet.size)
    // 获取 或 创建 parent  RDD
    // **************重点************8
    // 创建 DAG以及 划分 stage的操作
    val parents = getOrCreateParentStages(rdd, jobId)
    val id = nextStageId.getAndIncrement()
    // 创建一个 resultStage
    val stage = new ResultStage(id, rdd, func, partitions, parents, jobId, callSite)
    stageIdToStage(id) = stage
    updateJobIdStageIdMaps(jobId, stage)
    stage
  }
```

> org.apache.spark.scheduler.DAGScheduler#getOrCreateParentStages

```scala
  private def getOrCreateParentStages(rdd: RDD[_], firstJobId: Int): List[Stage] = {
    getShuffleDependencies(rdd).map { shuffleDep =>
      getOrCreateShuffleMapStage(shuffleDep, firstJobId)
    }.toList
  }
```

这里先画一个重点，具体的stage划分，后面开一篇讲一下，本篇还要紧跟主题，提交任务。

> org.apache.spark.scheduler.DAGScheduler#submitStage

```scala
 // 提交stage
    // 如果stage有父stage 则先提交父stage
  private def submitStage(stage: Stage) {
    val jobId = activeJobForStage(stage)
    if (jobId.isDefined) {
      logDebug(s"submitStage($stage (name=${stage.name};" +
        s"jobs=${stage.jobIds.toSeq.sorted.mkString(",")}))")
      if (!waitingStages(stage) && !runningStages(stage) && !failedStages(stage)) {
        val missing = getMissingParentStages(stage).sortBy(_.id)
        logDebug("missing: " + missing)
        if (missing.isEmpty) {
          logInfo("Submitting " + stage + " (" + stage.rdd + "), which has no missing parents")
          // *********重点*************
            // 提交
          submitMissingTasks(stage, jobId.get)
        } else {
          for (parent <- missing) {
            // 如果有缺失的parent 则再次提交parent任务
            submitStage(parent)
          }
          // 把本次 stage 添加到 等待执行的stage中
          waitingStages += stage
        }
      }
    } else {
      abortStage(stage, "No active job for stage " + stage.id, None)
    }
  }
```

> org.apache.spark.scheduler.DAGScheduler#submitMissingTasks

```scala
// 提交任务
private def submitMissingTasks(stage: Stage, jobId: Int) {
    logDebug("submitMissingTasks(" + stage + ")")
    // First figure out the indexes of partition ids to compute.
    val partitionsToCompute: Seq[Int] = stage.findMissingPartitions()

    // Use the scheduling pool, job group, description, etc. from an ActiveJob associated
    // with this Stage
    val properties = jobIdToActiveJob(jobId).properties

    runningStages += stage
    // 从这里可以看到 stage只有两种
    stage match {
        case s: ShuffleMapStage =>
        outputCommitCoordinator.stageStart(stage = s.id, maxPartitionId = s.numPartitions - 1)
        case s: ResultStage =>
        outputCommitCoordinator.stageStart(
            stage = s.id, maxPartitionId = s.rdd.partitions.length - 1)
    }
    val taskIdToLocations: Map[Int, Seq[TaskLocation]] = try {
        stage match {
            case s: ShuffleMapStage =>
            partitionsToCompute.map { id => (id, getPreferredLocs(stage.rdd, id))}.toMap
            case s: ResultStage =>
            partitionsToCompute.map { id =>
                val p = s.partitions(id)
                (id, getPreferredLocs(stage.rdd, p))
            }.toMap
        }
    } catch {
        case NonFatal(e) =>
        stage.makeNewStageAttempt(partitionsToCompute.size)
        listenerBus.post(SparkListenerStageSubmitted(stage.latestInfo, properties))
        abortStage(stage, s"Task creation failed: $e\n${Utils.exceptionString(e)}", Some(e))
        runningStages -= stage
        return
    }
    stage.makeNewStageAttempt(partitionsToCompute.size, taskIdToLocations.values.toSeq)
    if (partitionsToCompute.nonEmpty) {
        stage.latestInfo.submissionTime = Some(clock.getTimeMillis())
    }
    // 消息总线发送消息 SparkListenerStageSubmitted
    listenerBus.post(SparkListenerStageSubmitted(stage.latestInfo, properties))

    // 下面开始 对任务开始 序列化
    var taskBinary: Broadcast[Array[Byte]] = null
    var partitions: Array[Partition] = null
    try {
        var taskBinaryBytes: Array[Byte] = null
        RDDCheckpointData.synchronized {
            taskBinaryBytes = stage match {
                case stage: ShuffleMapStage =>
                JavaUtils.bufferToArray(
                    closureSerializer.serialize((stage.rdd, stage.shuffleDep): AnyRef))
                case stage: ResultStage =>
                JavaUtils.bufferToArray(closureSerializer.serialize((stage.rdd, stage.func): AnyRef))
            }

            partitions = stage.rdd.partitions
        }

        taskBinary = sc.broadcast(taskBinaryBytes)
    } catch {
        // In the case of a failure during serialization, abort the stage.
        case e: NotSerializableException =>
        abortStage(stage, "Task not serializable: " + e.toString, Some(e))
        runningStages -= stage

        // Abort execution
        return
        case e: Throwable =>
        abortStage(stage, s"Task serialization failed: $e\n${Utils.exceptionString(e)}", Some(e))
        runningStages -= stage

        // Abort execution
        return
    }
    // task 的组建
    val tasks: Seq[Task[_]] = try {
        val serializedTaskMetrics = closureSerializer.serialize(stage.latestInfo.taskMetrics).array()
        stage match {
            case stage: ShuffleMapStage =>
            stage.pendingPartitions.clear()
            partitionsToCompute.map { id =>
                val locs = taskIdToLocations(id)
                val part = partitions(id)
                stage.pendingPartitions += id
                new ShuffleMapTask(stage.id, stage.latestInfo.attemptNumber,
              taskBinary, part, locs, properties, serializedTaskMetrics, Option(jobId),
             Option(sc.applicationId), sc.applicationAttemptId, stage.rdd.isBarrier())}

            case stage: ResultStage =>
            partitionsToCompute.map { id =>
                val p: Int = stage.partitions(id)
                val part = partitions(p)
                val locs = taskIdToLocations(id)
                new ResultTask(stage.id, stage.latestInfo.attemptNumber,
                               taskBinary, part, locs, id, properties, serializedTaskMetrics,
                               Option(jobId), Option(sc.applicationId), sc.applicationAttemptId,
                               stage.rdd.isBarrier())
            }
        }
    } catch {
        case NonFatal(e) =>
        abortStage(stage, s"Task creation failed: $e\n${Utils.exceptionString(e)}", Some(e))
        runningStages -= stage
        return
    }
    // 如果有任务,则进行提交
    if (tasks.size > 0) {
        logInfo(s"Submitting ${tasks.size} missing tasks from $stage (${stage.rdd}) (first 15 " +
                s"tasks are for partitions ${tasks.take(15).map(_.partitionId)})")
        // tasks的提交
        // *************重点 **************
        // 提交任务 前面由 sparkContext 转交给 dagScheduler,现在由转交给 tashScheduler
        // sparkContext --> dagScheduler --> taskScheduler
        taskScheduler.submitTasks(new TaskSet(
            tasks.toArray, stage.id, stage.latestInfo.attemptNumber, jobId, properties))
    } else {
        // Because we posted SparkListenerStageSubmitted earlier, we should mark
        // the stage as completed here in case there are no tasks to run
        markStageAsFinished(stage, None)

        stage match {
            case stage: ShuffleMapStage =>
            logDebug(s"Stage ${stage} is actually done; " +
                     s"(available: ${stage.isAvailable}," +
                     s"available outputs: ${stage.numAvailableOutputs}," +
                     s"partitions: ${stage.numPartitions})")
            markMapStageJobsAsFinished(stage)
            case stage : ResultStage =>
            logDebug(s"Stage ${stage} is actually done; (partitions: ${stage.numPartitions})")
        }
        submitWaitingChildStages(stage)
    }
}
```

> org.apache.spark.scheduler.TaskSchedulerImpl#submitTasks

```scala
// 提交任务
override def submitTasks(taskSet: TaskSet) {
    val tasks = taskSet.tasks
    logInfo("Adding task set " + taskSet.id + " with " + tasks.length + " tasks")
    this.synchronized {
        val manager = createTaskSetManager(taskSet, maxTaskFailures)
        val stage = taskSet.stageId
        val stageTaskSets =
        taskSetsByStageIdAndAttempt.getOrElseUpdate(stage, new HashMap[Int, TaskSetManager])
        
        stageTaskSets.foreach { case (_, ts) =>
            ts.isZombie = true
        }
        stageTaskSets(taskSet.stageAttemptId) = manager
        // 添加任务到队列中,来等待task调度执行
        // 可以看到: 当dagSchedular提交任务到 taskScheduler时,taskScheduler只是把任务添加到了
        // queue中
        schedulableBuilder.addTaskSetManager(manager, manager.taskSet.properties)
        if (!isLocal && !hasReceivedTask) {
            starvationTimer.scheduleAtFixedRate(new TimerTask() {
                override def run() {
                    if (!hasLaunchedTask) {
                        logWarning("Initial job has not accepted any resources; " +
                                   "check your cluster UI to ensure that workers are registered " +
                                   "and have sufficient resources")
                    } else {
                        this.cancel()
                    }
                }
            }, STARVATION_TIMEOUT_MS, STARVATION_TIMEOUT_MS)
        }
        hasReceivedTask = true
    }
    //  *** 重点 ***
    // 分发task 到各个 executor
    // 现在 dagscheduler 提交任务到 tashschedler了,tashschedler把任务放到 queue中后
    // taskScheduler又会 调用 driver backend来进行一次任务的分发
    backend.reviveOffers()
}

```

> org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend#reviveOffers

```scala
 // 向CoarseGrainedSchedulerBackend 内部类 DriverEndpoint发送消息
  // 向driver发送消息, 开始执行一次资源调度
  // 也就是driver自己向自己发送了ReviveOffers消息
  override def reviveOffers() {
    driverEndpoint.send(ReviveOffers)
  }
```

向driver发送消息了，那么看一下driver对这个消息的处理把：

> org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.DriverEndpoint#receive

```scala
// 省略 不重要的 
// driver endpoint的消息接收
override def receive: PartialFunction[Any, Unit] = {
    ... 
    // 发送task到worker执行
    // 当提交任务时, driver也会向自己发送 ReviveOffers消息
    case ReviveOffers =>
    makeOffers()
    ..
}
```

> org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.DriverEndpoint#makeOffers

```scala
 // 尝试把 待处理的任务 发送到 executor
    private def makeOffers() {
      // Make sure no executor is killed while some task is launching on it
      val taskDescs = withLock {
        // Filter out executors under killing
        // 过滤出 active executor
        val activeExecutors = executorDataMap.filterKeys(executorIsAlive)
        val workOffers = activeExecutors.map {
          case (id, executorData) =>
            new WorkerOffer(id, executorData.executorHost, executorData.freeCores,
              Some(executorData.executorAddress.hostPort))
        }.toIndexedSeq
        // 重点 --
        scheduler.resourceOffers(workOffers)
      }
      // 如果存在任务,则启动 task执行任务
      // 让 executor 启动task
      if (!taskDescs.isEmpty) {
        // 向executor 发送 启动task的消息
        launchTasks(taskDescs)
      }
    }
```

> org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.DriverEndpoint#launchTasks

```scala
    // driver 发送 task到 executor
    private def launchTasks(tasks: Seq[Seq[TaskDescription]]) {
      for (task <- tasks.flatten) {
        val serializedTask = TaskDescription.encode(task)
        // 如果任务的序列化大小 大于了 maxRpcMessageSize,则放弃此任务, 并打印消息
        if (serializedTask.limit() >= maxRpcMessageSize) {
          Option(scheduler.taskIdToTaskSetManager.get(task.taskId)).foreach { taskSetMgr =>
            try {
              var msg = "Serialized task %s:%d was %d bytes, which exceeds max allowed: " +
                "spark.rpc.message.maxSize (%d bytes). Consider increasing " +
                "spark.rpc.message.maxSize or using broadcast variables for large values."
              msg = msg.format(task.taskId, task.index, serializedTask.limit(), maxRpcMessageSize)
              // abort 消息
              taskSetMgr.abort(msg)
            } catch {
              case e: Exception => logError("Exception in error callback", e)
            }
          }
        }
          // 正常发送LaunchTask消息到  executor
        else {
          val executorData = executorDataMap(task.executorId)
          executorData.freeCores -= scheduler.CPUS_PER_TASK
          logDebug(s"Launching task ${task.taskId} on executor id: ${task.executorId} hostname: " +
            s"${executorData.executorHost}.")
          // 发送 LaunchTask 的消息到executor,让executor来执行任务
          // 消息的参数是 序列化的任务
          executorData.executorEndpoint.send(LaunchTask(new SerializableBuffer(serializedTask)))
        }
      }
    }
```

这里可以看到driver向executor发送LaunchTask消息了，后面就是executor来具体对task进行处理了。

下篇咱们分析一下executor对具体任务的处理过程。





