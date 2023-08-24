[TOC]

# master为application分配executor的分析

每当一个application注册，或者worker注册时master会进行一次schedule，本篇咱们来看一下当一个application注册时，master是如何为其进行资源分配的。

> org.apache.spark.deploy.master.Master#receive

```java
// 省略非关键代码
override def receive: PartialFunction[Any, Unit] = {
	.....
    // 接收到 AppClient发送过来的 注册Application消息
    case RegisterApplication(description, driver) =>
      // TODO Prevent repeated registrations from some driver
      if (state == RecoveryState.STANDBY) {
        // ignore, don't send response
      } else {
        logInfo("Registering app " + description.name)
        // 创建app
        val app = createApplication(description, driver)
        // 把创建好的app 记录下来
        registerApplication(app)
        logInfo("Registered app " + description.name + " with ID " + app.id)
        persistenceEngine.addApplication(app)
        // 回复 driver RegisteredApplication消息
        driver.send(RegisteredApplication(app.id, self))
        // 调度
        // 1.找合适的worker 来启动driver
        // 2.找合适的worker 来启动 executor 运行 application
        schedule()
      }
     ...
 }
```

> org.apache.spark.deploy.master.Master#schedule

```java
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

此函数上半部分主要是为application寻找worker，并启动driver；最后一行为调度那些worker需要启动executor以及分配的core的数量：

> org.apache.spark.deploy.master.Master#startExecutorsOnWorkers

```java
  private def startExecutorsOnWorkers(): Unit = {
    // Right now this is a very simple FIFO scheduler. We keep trying to fit in the first app
    // in the queue, then the second app, etc.
    // 遍历所有等待的app,把app分发到worker上运行
    for (app <- waitingApps) {
      // app 每个executor 需要的核数
      val coresPerExecutor = app.desc.coresPerExecutor.getOrElse(1)
      // If the cores left is less than the coresPerExecutor,the cores left will not be allocated
      //
      if (app.coresLeft >= coresPerExecutor) {
        // Filter out workers that don't have enough resources to launch an executor
        // 过滤 找出所有可用 且 资源足够的worker 并按照 可用核数排序
        val usableWorkers = workers.toArray.filter(_.state == WorkerState.ALIVE)
          .filter(worker => worker.memoryFree >= app.desc.memoryPerExecutorMB &&
            worker.coresFree >= coresPerExecutor)
          .sortBy(_.coresFree).reverse
        // 每个worker要分配的core
        val assignedCores = scheduleExecutorsOnWorkers(app, usableWorkers, spreadOutApps)

        // Now that we've decided how many cores to allocate on each worker, let's allocate them
        // 在worker上启动 executor
        for (pos <- 0 until usableWorkers.length if assignedCores(pos) > 0) {
          // 在worker上启动 executor
          // 重点  重点 重点
          allocateWorkerResourceToExecutors(
            app, assignedCores(pos), app.desc.coresPerExecutor, usableWorkers(pos))
        }
      }
    }
  }
```

这里主要的工作：

1. 为每一个worker分配的资源，以及要启动的executor的数量
2. 发送指令到worker，使其启动executor

这里看一下为worker分配资源的地方：

> org.apache.spark.deploy.master.Master#scheduleExecutorsOnWorkers

```java
    // 1. 调度那些worker要启动 executor
    // 2. 要启动executor的worker 分配的 core 数量
    // 分配core到worker时,有两个模式
    // 1. 尽量分配到多的worker上,也就是每个worker分配的 core数量比较少
    // 2. 尽量分配到少的worker上,也就是每个worker分配到尽量多的core
  private def scheduleExecutorsOnWorkers(
      app: ApplicationInfo,
      usableWorkers: Array[WorkerInfo],
      spreadOutApps: Boolean): Array[Int] = {
    // app配置的  每个 executor的核数
    val coresPerExecutor = app.desc.coresPerExecutor
    // 每个executor可用的最小核数
    val minCoresPerExecutor = coresPerExecutor.getOrElse(1)
    // 是否是每一个 worker启动一个 executor
    val oneExecutorPerWorker = coresPerExecutor.isEmpty
    // app设置的每个 executor的内存
    val memoryPerExecutor = app.desc.memoryPerExecutorMB
    // 可用的 worker的数量
    val numUsable = usableWorkers.length
    // 需要从 每个worker上获取的核数
    val assignedCores = new Array[Int](numUsable) // Number of cores to give to each worker
    // 每一个 worker需要需要启动的executor
      // assignedExecutors 记录对应的worker要启动的executor的数量
    val assignedExecutors = new Array[Int](numUsable) // Number of new executors on each worker
    // 在app要用的core数量 和 总的可用的core数量之间选一个比较小的
      // 可以是 待分配的core数 也可以是 可用的core数
    var coresToAssign = math.min(app.coresLeft, usableWorkers.map(_.coresFree).sum)

    /** Return whether the specified worker can launch an executor for this app. */
        // 定义一个内部函数
      // 判断一个worker能够 launch 此app
    def canLaunchExecutor(pos: Int): Boolean = {
        // 要分配的 核数 是否大于 最小核数
      val keepScheduling = coresToAssign >= minCoresPerExecutor
        // pos 位置的worker的 可用核数 是否大于 assignedCores
        // usableWorkers表示可用的worker
        // assignedCores 记录对应的worker 分配到的core数量
      val enoughCores = usableWorkers(pos).coresFree - assignedCores(pos) >= minCoresPerExecutor

      // If we allow multiple executors per worker, then we can always launch new executors.
      // Otherwise, if there is already an executor on this worker, just give it more cores.
      val launchingNewExecutor = !oneExecutorPerWorker || assignedExecutors(pos) == 0
      if (launchingNewExecutor) {
        // 要分配的内存
        val assignedMemory = assignedExecutors(pos) * memoryPerExecutor
        // pos位置的worker 的可用内存是否足够
        val enoughMemory = usableWorkers(pos).memoryFree - assignedMemory >= memoryPerExecutor
        // 已经分配的 executor和 app已经使用的 executor 是否在app的 executor 数量限制之下
        val underLimit = assignedExecutors.sum + app.executors.size < app.executorLimit
        keepScheduling && enoughCores && enoughMemory && underLimit
      } else {
        // We're adding cores to an existing executor, so no need
        // to check memory and executor limits
        keepScheduling && enoughCores
      }
    }

    // Keep launching executors until no more workers can accommodate any
    // more executors, or if we have reached this application's limits
    // 过滤出 可用的worker
    var freeWorkers = (0 until numUsable).filter(canLaunchExecutor)
    // 遍历可用的worker
    while (freeWorkers.nonEmpty) {
      freeWorkers.foreach { pos =>
        var keepScheduling = true
        while (keepScheduling && canLaunchExecutor(pos)) {
          coresToAssign -= minCoresPerExecutor
          assignedCores(pos) += minCoresPerExecutor

          // If we are launching one executor per worker, then every iteration assigns 1 core
          // to the executor. Otherwise, every iteration assigns cores to a new executor.
          // 如果是  每个worker只能启动一个 executor,则assignedExecutors(pos) 设置为1,表示pos对应的worker
          // 要启动的executor的数量
          if (oneExecutorPerWorker) {
            assignedExecutors(pos) = 1
          } else {
            // 如果不是只能启动一个 executor,则要准备启动的 数量增加1
            assignedExecutors(pos) += 1
          }

          // Spreading out an application means spreading out its executors across as
          // many workers as possible. If we are not spreading out, then we should keep
          // scheduling executors on this worker until we use all of its resources.
          // Otherwise, just move on to the next worker.
          /**
           * 首先注意这里的while循环是两层,第一层循环是对所有的worker进行遍历,第二层是对上一层遍历到的worker进行
           * 资源的分配
           * 重要点在这里:
           * 1. spreadOutApps 为true,则表示需要扩散 app到尽可能多的executor上.也就是为true,那么对一个worker就循环一次,之后
           * 就跳到外部的while循环,进行下一个worker的遍历
           * 2. spreadOutApps为false,则表示app的executor尽量集中到某些worker上,那么就持续对一个worker进行资源分配,直到此worker
           * 没有资源可用
           */
          if (spreadOutApps) {
            keepScheduling = false
          }
        }
      }
      // 过滤出 剩余可用的 worker
      freeWorkers = freeWorkers.filter(canLaunchExecutor)
    }
    assignedCores
  }
```

此函数的javadoc：

```java
  /**
   * Schedule executors to be launched on the workers.
   * 调度哪些worker要启动 executor
   * Returns an array containing number of cores assigned to each worker.
   * 返回一个数组,其包含了每一个worker要分配到的core的数量 
   *
   * There are two modes of launching executors. The first attempts to spread out an application's
   * executors on as many workers as possible, while the second does the opposite (i.e. launch them
   * on as few workers as possible). The former is usually better for data locality purposes and is
   * the default.
   * 有两种模式来启动executor: 1. 尝试把application的executor分配到尽量对的worker上,  2.第二种则相反,尽量把
   * app的executor分配到尽量少的worker上.  第一种凡是通次对于data locality purposes比较好,且是默认的.
   * The number of cores assigned to each executor is configurable. When this is explicitly set,
   * multiple executors from the same application may be launched on the same worker if the worker
   * has enough cores and memory. Otherwise, each executor grabs all the cores available on the
   * worker by default, in which case only one executor per application may be launched on each
   * worker during one single schedule iteration.
   * Note that when `spark.executor.cores` is not set, we may still launch multiple executors from
   * the same application on the same worker. Consider appA and appB both have one executor running
   * on worker1, and appA.coresLeft > 0, then appB is finished and release all its cores on worker1,
   * thus for the next schedule iteration, appA launches a new executor that grabs all the free
   * cores on worker1, therefore we get multiple executors from appA running on worker1.
   *
   * It is important to allocate coresPerExecutor on each worker at a time (instead of 1 core
   * at a time). Consider the following example: cluster has 4 workers with 16 cores each.
   * User requests 3 executors (spark.cores.max = 48, spark.executor.cores = 16). If 1 core is
   * allocated at a time, 12 cores from each worker would be assigned to each executor.
   * Since 12 < 16, no executors would launch [SPARK-8881].
   */
```

上面的函数注解还比较清晰，javadoc中也说的很清楚，分配资源有两种模式：

1. 把app的executor分配到尽量多的worker上，此操作对data locality 友好，此模式是默认的
2. 把app的executor分配到尽量少的worker上

通过代码，此实现由两层while循环实现，第二层关键代码如下，主要根据是否是分配到尽量多的worker上来控制循环是否退出。

```scala
if (spreadOutApps) {
    keepScheduling = false
}
```

小结一下这里：

1. 当spreadOutApps为true，则把executor分配到尽量多的worker上，那么第二层while循环对worker分配资源时，分配一次就会在这里退出
2. 当spreadOutApps为false，则把executor分配到尽量少的worker上，那么第二层while循环在这里就 不不会退出，那么第二层while循环就会对一个worker持续进行资源的分配，知道此worker没有资源可用。































































