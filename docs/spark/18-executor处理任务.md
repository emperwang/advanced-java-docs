[TOC]

# executor处理任务

上篇分析到driver向executor发送LaunchTask消息，并附带序列化后的task，本篇就分析一下executor对此任务的一个处理。

>org.apache.spark.executor.CoarseGrainedExecutorBackend#receive

```scala
// 只看 重点
// executor 接收函数 
override def receive: PartialFunction[Any, Unit] = {
   ......
    // executor启动task 来执行任务
    case LaunchTask(data) =>
      if (executor == null) {
        exitExecutor(1, "Received LaunchTask command but executor was null")
      } else {
        // 解码任务
        val taskDesc = TaskDescription.decode(data.value)
        logInfo("Got assigned task " + taskDesc.taskId)
        // 启动任务
          // 在线程池中 执行任务
        executor.launchTask(this, taskDesc)
      }
    ....
}
```

> org.apache.spark.executor.Executor#launchTask

```scala
  def launchTask(context: ExecutorBackend, taskDescription: TaskDescription): Unit = {
    //  使用TaskRunner 包装一下 发送过来的任务
    val tr = new TaskRunner(context, taskDescription)
    // 记录此即将要运行的task
    runningTasks.put(taskDescription.taskId, tr)
    // 执行任务
    threadPool.execute(tr)
  }
```

> org.apache.spark.executor.Executor.TaskRunner#run

```scala
// 这个任务有点长, 下面有一个突出重点的删减版,可以看一下
// 具体运行 driver发送过来的任务的地方
override def run(): Unit = {
    threadId = Thread.currentThread.getId
    // 设置线程名字
    Thread.currentThread.setName(threadName)
    val threadMXBean = ManagementFactory.getThreadMXBean
    // 创建 TaskMemoryManager, 对task内存的管理
    val taskMemoryManager = new TaskMemoryManager(env.memoryManager, taskId)
    val deserializeStartTime = System.currentTimeMillis()
    val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
        threadMXBean.getCurrentThreadCpuTime
    } else 0L
    // classLoader 设置
    Thread.currentThread.setContextClassLoader(replClassLoader)
    val ser = env.closureSerializer.newInstance()
    logInfo(s"Running $taskName (TID $taskId)")
    // 向driver发送消息,来更新 task对应的任务
    execBackend.statusUpdate(taskId, TaskState.RUNNING, EMPTY_BYTE_BUFFER)
    var taskStartTime: Long = 0
    var taskStartCpu: Long = 0
    // 计算总的  gc时间
    startGCTime = computeTotalGcTime()

    try {
        // Must be set before updateDependencies() is called, in case fetching dependencies
        // requires access to properties contained within (e.g. for access control).
        Executor.taskDeserializationProps.set(taskDescription.properties)

        updateDependencies(taskDescription.addedFiles, taskDescription.addedJars)
        // 反序列化 处 task
        task = ser.deserialize[Task[Any]](
            taskDescription.serializedTask, Thread.currentThread.getContextClassLoader)
        task.localProperties = taskDescription.properties
        // 更新 task 的内存管理
        task.setTaskMemoryManager(taskMemoryManager)

        // If this task has been killed before we deserialized it, let's quit now. Otherwise,
        // continue executing the task.
        val killReason = reasonIfKilled
        if (killReason.isDefined) {
            // Throw an exception rather than returning, because returning within a try{} block
            // causes a NonLocalReturnControl exception to be thrown. The NonLocalReturnControl
            // exception will be caught by the catch block, leading to an incorrect ExceptionFailure
            // for the task.
            throw new TaskKilledException(killReason.get)
        }

        // The purpose of updating the epoch here is to invalidate executor map output status cache
        // in case FetchFailures have occurred. In local mode `env.mapOutputTracker` will be
        // MapOutputTrackerMaster and its cache invalidation is not based on epoch numbers so
        // we don't need to make any special calls here.
        // 在 outputTracker中更新信息
        if (!isLocal) {
            logDebug("Task " + taskId + "'s epoch is " + task.epoch)
            env.mapOutputTracker.asInstanceOf[MapOutputTrackerWorker].updateEpoch(task.epoch)
        }

        // Run the actual task and measure its runtime.
        // 记录任务开始时间
        taskStartTime = System.currentTimeMillis()
        taskStartCpu = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
            threadMXBean.getCurrentThreadCpuTime
        } else 0L
        var threwException = true
        // 任务的执行  todo  --- 任务开始执行
        // value为任务的结果值
        val value = Utils.tryWithSafeFinally {
            // 由此看见 taskAttemptId 就是 taskId发送过来的
            val res = task.run(
                taskAttemptId = taskId,
                attemptNumber = taskDescription.attemptNumber,
                metricsSystem = env.metricsSystem)
            threwException = false
            res
        } {
            // 释放此任务的锁  以及 清理内存
            val releasedLocks = env.blockManager.releaseAllLocksForTask(taskId)
            val freedMemory = taskMemoryManager.cleanUpAllAllocatedMemory()

            if (freedMemory > 0 && !threwException) {
      val errMsg = s"Managed memory leak detected; size = $freedMemory bytes, TID = $taskId"
                if (conf.getBoolean("spark.unsafe.exceptionOnMemoryLeak", false)) {
                    throw new SparkException(errMsg)
                } else {
                    logWarning(errMsg)
                }
            }

            if (releasedLocks.nonEmpty && !threwException) {
                val errMsg =
                s"${releasedLocks.size} block locks were not released by TID = $taskId:\n" +
                releasedLocks.mkString("[", ", ", "]")
                if (conf.getBoolean("spark.storage.exceptionOnPinLeak", false)) {
                    throw new SparkException(errMsg)
                } else {
                    logInfo(errMsg)
                }
            }
        }
        task.context.fetchFailed.foreach { fetchFailure =>
            // uh-oh.  it appears the user code has caught the fetch-failure without throwing any
            // other exceptions.  Its *possible* this is what the user meant to do (though highly
            // unlikely).  So we will log an error and keep going.
            logError(s"TID ${taskId} completed successfully though internally it encountered " +
                     s"unrecoverable fetch failures!  Most likely this means user code is incorrectly " + s"swallowing Spark's internal ${classOf[FetchFailedException]}", fetchFailure)
        }
        // 任务执行结束时间
        val taskFinish = System.currentTimeMillis()
        val taskFinishCpu = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
            threadMXBean.getCurrentThreadCpuTime
        } else 0L

        // If the task has been killed, let's fail it.
        task.context.killTaskIfInterrupted()
        // 获取一个 序列化器
        val resultSer = env.serializer.newInstance()
        // 记录序列化开始时间
        val beforeSerialization = System.currentTimeMillis()
        // 把task 运行完成后的结果值 序列化
        val valueBytes = resultSer.serialize(value)
        // 记录序列化的结束时间
        // 此用于获取 结果序列操作 花费的时间
        val afterSerialization = System.currentTimeMillis()

        // Deserialization happens in two parts: first, we deserialize a Task object, which
        // includes the Partition. Second, Task.run() deserializes the RDD and function to be run.
        // 记录 executor 反序列化的时间
        task.metrics.setExecutorDeserializeTime(
            (taskStartTime - deserializeStartTime) + task.executorDeserializeTime)
        // 记录 executor 反序列化的 cpu的时间
        task.metrics.setExecutorDeserializeCpuTime(
            (taskStartCpu - deserializeStartCpuTime) + task.executorDeserializeCpuTime)
        // We need to subtract Task.run()'s deserialization time to avoid double-counting
        // 记录 task的执行时间
        task.metrics.setExecutorRunTime((taskFinish - taskStartTime) - task.executorDeserializeTime)
        // 记录 task的 执行的 cpu时间
        task.metrics.setExecutorCpuTime(
            (taskFinishCpu - taskStartCpu) - task.executorDeserializeCpuTime)
        // 记录 gc 时间
        task.metrics.setJvmGCTime(computeTotalGcTime() - startGCTime)
        // 记录 task结果值 序列化时间
        task.metrics.setResultSerializationTime(afterSerialization - beforeSerialization)

        // Expose task metrics using the Dropwizard metrics system.
        // Update task metrics counters
        executorSource.METRIC_CPU_TIME.inc(task.metrics.executorCpuTime)
        executorSource.METRIC_RUN_TIME.inc(task.metrics.executorRunTime)
        executorSource.METRIC_JVM_GC_TIME.inc(task.metrics.jvmGCTime)
        executorSource.METRIC_DESERIALIZE_TIME.inc(task.metrics.executorDeserializeTime)
        executorSource.METRIC_DESERIALIZE_CPU_TIME.inc(task.metrics.executorDeserializeCpuTime)
        executorSource.METRIC_RESULT_SERIALIZE_TIME.inc(task.metrics.resultSerializationTime)
        executorSource.METRIC_SHUFFLE_FETCH_WAIT_TIME
        .inc(task.metrics.shuffleReadMetrics.fetchWaitTime)
        executorSource.METRIC_SHUFFLE_WRITE_TIME.inc(task.metrics.shuffleWriteMetrics.writeTime)
        executorSource.METRIC_SHUFFLE_TOTAL_BYTES_READ
        .inc(task.metrics.shuffleReadMetrics.totalBytesRead)
        executorSource.METRIC_SHUFFLE_REMOTE_BYTES_READ
        .inc(task.metrics.shuffleReadMetrics.remoteBytesRead)
        executorSource.METRIC_SHUFFLE_REMOTE_BYTES_READ_TO_DISK
        .inc(task.metrics.shuffleReadMetrics.remoteBytesReadToDisk)
        executorSource.METRIC_SHUFFLE_LOCAL_BYTES_READ
        .inc(task.metrics.shuffleReadMetrics.localBytesRead)
        executorSource.METRIC_SHUFFLE_RECORDS_READ
        .inc(task.metrics.shuffleReadMetrics.recordsRead)
        executorSource.METRIC_SHUFFLE_REMOTE_BLOCKS_FETCHED
        .inc(task.metrics.shuffleReadMetrics.remoteBlocksFetched)
        executorSource.METRIC_SHUFFLE_LOCAL_BLOCKS_FETCHED
        .inc(task.metrics.shuffleReadMetrics.localBlocksFetched)
        executorSource.METRIC_SHUFFLE_BYTES_WRITTEN
        .inc(task.metrics.shuffleWriteMetrics.bytesWritten)
        executorSource.METRIC_SHUFFLE_RECORDS_WRITTEN
        .inc(task.metrics.shuffleWriteMetrics.recordsWritten)
        executorSource.METRIC_INPUT_BYTES_READ
        .inc(task.metrics.inputMetrics.bytesRead)
        executorSource.METRIC_INPUT_RECORDS_READ
        .inc(task.metrics.inputMetrics.recordsRead)
        executorSource.METRIC_OUTPUT_BYTES_WRITTEN
        .inc(task.metrics.outputMetrics.bytesWritten)
        executorSource.METRIC_OUTPUT_RECORDS_WRITTEN
        .inc(task.metrics.outputMetrics.recordsWritten)
        executorSource.METRIC_RESULT_SIZE.inc(task.metrics.resultSize)
        executorSource.METRIC_DISK_BYTES_SPILLED.inc(task.metrics.diskBytesSpilled)
        executorSource.METRIC_MEMORY_BYTES_SPILLED.inc(task.metrics.memoryBytesSpilled)

        // Note: accumulator updates must be collected after TaskMetrics is updated
        // Accumulator值的更新
        val accumUpdates = task.collectAccumulatorUpdates()
        // TODO: do not serialize value twice
        // 对 Accumulator和 结果值 进行序列化
        val directResult = new DirectTaskResult(valueBytes, accumUpdates)
        val serializedDirectResult = ser.serialize(directResult)
        // 序列化的 limit值
        val resultSize = serializedDirectResult.limit()

        // directSend = sending directly back to the driver
        // 结果值的序列化, 此用于把结果发送给 driver
        val serializedResult: ByteBuffer = {
            // 如果结果值大小大于 maxResultSize 则drop it
            if (maxResultSize > 0 && resultSize > maxResultSize) {
                logWarning(s"Finished $taskName (TID $taskId). Result is larger than maxResultSize " +
                           s"(${Utils.bytesToString(resultSize)} > ${Utils.bytesToString(maxResultSize)}), " +
                           s"dropping it.")
                ser.serialize(new IndirectTaskResult[Any](TaskResultBlockId(taskId), resultSize))
            } else if (resultSize > maxDirectResultSize) {
                // 此是 把 结果序列化为 ChunkedByteBuffer
                val blockId = TaskResultBlockId(taskId)
                env.blockManager.putBytes(
                    blockId,
                    new ChunkedByteBuffer(serializedDirectResult.duplicate()),
                    StorageLevel.MEMORY_AND_DISK_SER)
                logInfo(
                    s"Finished $taskName (TID $taskId). $resultSize bytes result sent via BlockManager)")
                ser.serialize(new IndirectTaskResult[Any](blockId, resultSize))
            } else {
                logInfo(s"Finished $taskName (TID $taskId). $resultSize bytes result sent to driver")
                serializedDirectResult
            }
        }

        setTaskFinishedAndClearInterruptStatus()
        // executor向driver发送消息,更新task的状态
        // 其中 serializedResult是此task结果的序列化值
        // 也就是说 在这里把 task结果传递回 driver
        execBackend.statusUpdate(taskId, TaskState.FINISHED, serializedResult)

    } catch {
        case t: TaskKilledException =>
        logInfo(s"Executor killed $taskName (TID $taskId), reason: ${t.reason}")

        val (accums, accUpdates) = collectAccumulatorsAndResetStatusOnFailure(taskStartTime)
        val serializedTK = ser.serialize(TaskKilled(t.reason, accUpdates, accums))
        // 更新task 装填为 KILLED
        // 并发送 消息到 driver
        execBackend.statusUpdate(taskId, TaskState.KILLED, serializedTK)

        case _: InterruptedException | NonFatal(_) if
        task != null && task.reasonIfKilled.isDefined =>
        val killReason = task.reasonIfKilled.getOrElse("unknown reason")
        logInfo(s"Executor interrupted and killed $taskName (TID $taskId), reason: $killReason")

        val (accums, accUpdates) = collectAccumulatorsAndResetStatusOnFailure(taskStartTime)
        val serializedTK = ser.serialize(TaskKilled(killReason, accUpdates, accums))
        // 更新task为KILLED 并发送消息到driver
        execBackend.statusUpdate(taskId, TaskState.KILLED, serializedTK)

        case t: Throwable if hasFetchFailure && !Utils.isFatalError(t) =>
        val reason = task.context.fetchFailed.get.toTaskFailedReason
        if (!t.isInstanceOf[FetchFailedException]) {
            // there was a fetch failure in the task, but some user code wrapped that exception
            // and threw something else.  Regardless, we treat it as a fetch failure.
            val fetchFailedCls = classOf[FetchFailedException].getName
            logWarning(s"TID ${taskId} encountered a ${fetchFailedCls} and " +
                       s"failed, but the ${fetchFailedCls} was hidden by another " +
                       s"exception.  Spark is handling this like a fetch failure and ignoring the " +
                       s"other exception: $t")
        }
        setTaskFinishedAndClearInterruptStatus()
        // 更新task状态为 FAILED 并发送消息到 driver
        execBackend.statusUpdate(taskId, TaskState.FAILED, ser.serialize(reason))

        case CausedBy(cDE: CommitDeniedException) =>
        val reason = cDE.toTaskCommitDeniedReason
        setTaskFinishedAndClearInterruptStatus()
        execBackend.statusUpdate(taskId, TaskState.KILLED, ser.serialize(reason))

        case t: Throwable if env.isStopped =>
        logError(s"Exception in $taskName (TID $taskId): ${t.getMessage}")

        case t: Throwable =>
        logError(s"Exception in $taskName (TID $taskId)", t)
        if (!ShutdownHookManager.inShutdown()) {
            val (accums, accUpdates) = collectAccumulatorsAndResetStatusOnFailure(taskStartTime)

            val serializedTaskEndReason = {
                try {
                    ser.serialize(new ExceptionFailure(t, accUpdates).withAccums(accums))
                } catch {
                    case _: NotSerializableException =>
                    // t is not serializable so just send the stacktrace
                    ser.serialize(new ExceptionFailure(t, accUpdates, false).withAccums(accums))
                }
            }
            setTaskFinishedAndClearInterruptStatus()
            execBackend.statusUpdate(taskId, TaskState.FAILED, serializedTaskEndReason)
        } else {
            logInfo("Not reporting error to driver during JVM shutdown.")
        }
        if (!t.isInstanceOf[SparkOutOfMemoryError] && Utils.isFatalError(t)) {
            uncaughtExceptionHandler.uncaughtException(Thread.currentThread(), t)
        }
    } finally {
        // 移除此task
        runningTasks.remove(taskId)
    }
}
```

任务运行的删减版(为了突出重点):

```scala
    // 具体运行 driver发送过来的任务的地方
    override def run(): Unit = {
      threadId = Thread.currentThread.getId
      // 设置线程名字
      Thread.currentThread.setName(threadName)
      val threadMXBean = ManagementFactory.getThreadMXBean
      // 创建 TaskMemoryManager, 对task内存的管理
      val taskMemoryManager = new TaskMemoryManager(env.memoryManager, taskId)
      val deserializeStartTime = System.currentTimeMillis()
      val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
        threadMXBean.getCurrentThreadCpuTime
      } else 0L
      // classLoader 设置
      Thread.currentThread.setContextClassLoader(replClassLoader)
      val ser = env.closureSerializer.newInstance()
      logInfo(s"Running $taskName (TID $taskId)")
      // 向driver发送消息,来更新 task对应的任务
      execBackend.statusUpdate(taskId, TaskState.RUNNING, EMPTY_BYTE_BUFFER)
      var taskStartTime: Long = 0
      var taskStartCpu: Long = 0
      // 计算总的  gc时间
      startGCTime = computeTotalGcTime()

      try {
          // 任务反序列化
        Executor.taskDeserializationProps.set(taskDescription.properties)
        updateDependencies(taskDescription.addedFiles, taskDescription.addedJars)
        // 反序列化 处 task
        task = ser.deserialize[Task[Any]](
          taskDescription.serializedTask, Thread.currentThread.getContextClassLoader)
        task.localProperties = taskDescription.properties
        // 更新 task 的内存管理
        task.setTaskMemoryManager(taskMemoryManager)
        val killReason = reasonIfKilled
        // 在 outputTracker中更新信息
        if (!isLocal) {
          logDebug("Task " + taskId + "'s epoch is " + task.epoch)
          env.mapOutputTracker.asInstanceOf[MapOutputTrackerWorker].updateEpoch(task.epoch)
        }

        // Run the actual task and measure its runtime.
        // 记录任务开始时间
        taskStartTime = System.currentTimeMillis()
        taskStartCpu = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
          threadMXBean.getCurrentThreadCpuTime
        } else 0L
        var threwException = true
        // 任务的执行  todo  --- 任务开始执行
        // value为任务的结果值
        val value = Utils.tryWithSafeFinally {
          // 由此看见 taskAttemptId 就是 taskId发送过来的
           // 重点 
            // 这里才是任务的运行
          val res = task.run(
            taskAttemptId = taskId,
            attemptNumber = taskDescription.attemptNumber,
            metricsSystem = env.metricsSystem)
          threwException = false
          res
        } {
          // 释放此任务的锁  以及 清理内存
          val releasedLocks = env.blockManager.releaseAllLocksForTask(taskId)
          val freedMemory = taskMemoryManager.cleanUpAllAllocatedMemory()

          if (freedMemory > 0 && !threwException) {
            val errMsg = s"Managed memory leak detected; size = $freedMemory bytes, TID = $taskId"
            if (conf.getBoolean("spark.unsafe.exceptionOnMemoryLeak", false)) {
              throw new SparkException(errMsg)
            } else {
              logWarning(errMsg)
            }
          }

          if (releasedLocks.nonEmpty && !threwException) {
            val errMsg =
              s"${releasedLocks.size} block locks were not released by TID = $taskId:\n" +
                releasedLocks.mkString("[", ", ", "]")
            if (conf.getBoolean("spark.storage.exceptionOnPinLeak", false)) {
              throw new SparkException(errMsg)
            } else {
              logInfo(errMsg)
            }
          }
        }
        task.context.fetchFailed.foreach { fetchFailure =>
          logError(s"TID ${taskId} completed successfully though internally it encountered " +
            s"unrecoverable fetch failures!  Most likely this means user code is incorrectly " +
            s"swallowing Spark's internal ${classOf[FetchFailedException]}", fetchFailure)
        }
        // 任务执行结束时间
        val taskFinish = System.currentTimeMillis()
        val taskFinishCpu = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
          threadMXBean.getCurrentThreadCpuTime
        } else 0L

        // If the task has been killed, let's fail it.
        task.context.killTaskIfInterrupted()
        // 获取一个 序列化器
        val resultSer = env.serializer.newInstance()
        // 记录序列化开始时间
        val beforeSerialization = System.currentTimeMillis()
        // 把task 运行完成后的结果值 序列化
        val valueBytes = resultSer.serialize(value)
        // 记录序列化的结束时间
        // 此用于获取 结果序列操作 花费的时间
        val afterSerialization = System.currentTimeMillis()

        // Deserialization happens in two parts: first, we deserialize a Task object, which
        // includes the Partition. Second, Task.run() deserializes the RDD and function to be run.
        // 记录 executor 反序列化的时间
        task.metrics.setExecutorDeserializeTime(
          (taskStartTime - deserializeStartTime) + task.executorDeserializeTime)
        // 记录 executor 反序列化的 cpu的时间
        task.metrics.setExecutorDeserializeCpuTime(
          (taskStartCpu - deserializeStartCpuTime) + task.executorDeserializeCpuTime)
        // We need to subtract Task.run()'s deserialization time to avoid double-counting
        // 记录 task的执行时间
        task.metrics.setExecutorRunTime((taskFinish - taskStartTime) - task.executorDeserializeTime)
        // 记录 task的 执行的 cpu时间
        task.metrics.setExecutorCpuTime(
          (taskFinishCpu - taskStartCpu) - task.executorDeserializeCpuTime)
        // 记录 gc 时间
        task.metrics.setJvmGCTime(computeTotalGcTime() - startGCTime)
        // 记录 task结果值 序列化时间
        task.metrics.setResultSerializationTime(afterSerialization - beforeSerialization)

        // Note: accumulator updates must be collected after TaskMetrics is updated
        // Accumulator值的更新
        val accumUpdates = task.collectAccumulatorUpdates()
        // TODO: do not serialize value twice
        // 对 Accumulator和 结果值 进行序列化
        val directResult = new DirectTaskResult(valueBytes, accumUpdates)
        val serializedDirectResult = ser.serialize(directResult)
        // 序列化的 limit值
        val resultSize = serializedDirectResult.limit()

        // directSend = sending directly back to the driver
        // 结果值的序列化, 此用于把结果发送给 driver
        val serializedResult: ByteBuffer = {
          // 如果
          if (maxResultSize > 0 && resultSize > maxResultSize) {
            logWarning(s"Finished $taskName (TID $taskId). Result is larger than maxResultSize " +
              s"(${Utils.bytesToString(resultSize)} > ${Utils.bytesToString(maxResultSize)}), " +
              s"dropping it.")
            ser.serialize(new IndirectTaskResult[Any](TaskResultBlockId(taskId), resultSize))
          } else if (resultSize > maxDirectResultSize) {
            // 此是 把 结果序列化为 ChunkedByteBuffer
            val blockId = TaskResultBlockId(taskId)
            env.blockManager.putBytes(
              blockId,
              new ChunkedByteBuffer(serializedDirectResult.duplicate()),
              StorageLevel.MEMORY_AND_DISK_SER)
            logInfo(
              s"Finished $taskName (TID $taskId). $resultSize bytes result sent via BlockManager)")
            ser.serialize(new IndirectTaskResult[Any](blockId, resultSize))
          } else {
            logInfo(s"Finished $taskName (TID $taskId). $resultSize bytes result sent to driver")
            serializedDirectResult
          }
        }
        setTaskFinishedAndClearInterruptStatus()
        // executor向driver发送消息,更新task的状态
        // 其中 serializedResult是此task结果的序列化值
        // 也就是说 在这里把 task结果传递回 driver
        // 把结果返回给  driver  就算是完成任务了
        execBackend.statusUpdate(taskId, TaskState.FINISHED, serializedResult)

      } catch {
        ......
      } finally {
        // 移除此task
        runningTasks.remove(taskId)
      }
    }
```

任务的具体运行方式: 

> org.apache.spark.scheduler.Task#run

```scala
  // driver发送过来的任务的具体的执行
  final def run(
      taskAttemptId: Long,
      attemptNumber: Int,
      metricsSystem: MetricsSystem): T = {
      // 向 blockManager 注册 此task
    SparkEnv.get.blockManager.registerTask(taskAttemptId)
    // TODO SPARK-24874 Allow create BarrierTaskContext based on partitions, instead of whether
    // the stage is barrier.
    val taskContext = new TaskContextImpl(
      stageId,
      stageAttemptId, // stageAttemptId and stageAttemptNumber are semantically equal
      partitionId,
      taskAttemptId,
      attemptNumber,
      taskMemoryManager,
      localProperties,
      metricsSystem,
      metrics)
    context = if (isBarrier) {
      new BarrierTaskContext(taskContext)
    } else {
      taskContext
    }
    InputFileBlockHolder.initialize()
    TaskContext.setTaskContext(context)
    taskThread = Thread.currentThread()
    if (_reasonIfKilled != null) {
      kill(interruptThread = false, _reasonIfKilled)
    }

    new CallerContext(
      "TASK",
      SparkEnv.get.conf.get(APP_CALLER_CONTEXT),
      appId,
      appAttemptId,
      jobId,
      Option(stageId),
      Option(stageAttemptId),
      Option(taskAttemptId),
      Option(attemptNumber)).setCurrentContext()

    try {
      // 开始运行任务
      runTask(context)
    } catch {
      .....
        } finally {
          TaskContext.unset()
          InputFileBlockHolder.unset()
        }
      }
    }
  }
```

> org.apache.spark.scheduler.ResultTask#runTask

```scala
 // task的真实运行
  override def runTask(context: TaskContext): U = {
    // Deserialize the RDD and the func using the broadcast variables.
    val threadMXBean = ManagementFactory.getThreadMXBean
    // 反序列化的开始时间
    val deserializeStartTime = System.currentTimeMillis()
    // 反序列的cpu开始时间
    val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime
    } else 0L
    // 闭包的 反序列化
    val ser = SparkEnv.get.closureSerializer.newInstance()
    // taskBinary的反序列
    //
    val (rdd, func) = ser.deserialize[(RDD[T], (TaskContext, Iterator[T]) => U)](
      ByteBuffer.wrap(taskBinary.value), Thread.currentThread.getContextClassLoader)
    // 反序列的花费的时间
    _executorDeserializeTime = System.currentTimeMillis() - deserializeStartTime
    // 反序列化花费的cpu 时间
    _executorDeserializeCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime - deserializeStartCpuTime
    } else 0L
  // 使用定义的function 对rdd中内容进行执行
    func(context, rdd.iterator(partition, context))
  }
```

> org.apache.spark.scheduler.ShuffleMapTask#runTask

```scala
  // 具体的任务的执行
  override def runTask(context: TaskContext): MapStatus = {
    // Deserialize the RDD using the broadcast variable.
    val threadMXBean = ManagementFactory.getThreadMXBean
    // 反序列化的开始时间
    val deserializeStartTime = System.currentTimeMillis()
    val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime
    } else 0L
    val ser = SparkEnv.get.closureSerializer.newInstance()
    val (rdd, dep) = ser.deserialize[(RDD[_], ShuffleDependency[_, _, _])](
      ByteBuffer.wrap(taskBinary.value), Thread.currentThread.getContextClassLoader)
    // 记录序列化 花费的时间
    _executorDeserializeTime = System.currentTimeMillis() - deserializeStartTime
    // 反序列花费的 cpu时间
    _executorDeserializeCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime - deserializeStartCpuTime
    } else 0L
    var writer: ShuffleWriter[Any, Any] = null
    try {
      //  获取  shuffleManager
      val manager = SparkEnv.get.shuffleManager
      // 获取 shuffle的writer函数
      writer = manager.getWriter[Any, Any](dep.shuffleHandle, partitionId, context)
      // 开始把此 stage结果记录下来
      writer.write(rdd.iterator(partition, context).asInstanceOf[Iterator[_ <: Product2[Any, Any]]])
      writer.stop(success = true).get
    } catch {
      ......
    }
  }
```

从上面两个task的执行看出，其实最终也只有两种task，一个是ShuffleMapTask另一个是ResultTask。

executor对任务的运行就到这里吧。



















