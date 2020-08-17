[TOC]

# master的leader选举

本篇看一下spark基于zk的leader选举，spark使用了curator来进行对zk的操作，而不是使用zk的原生api。

## 基于zk的leader选举

创建选举器:

> org.apache.spark.deploy.master.Master#onStart

```scala
  override def onStart(): Unit = {
    ...  // 省略非关键代码
    // 序列化
    val serializer = new JavaSerializer(conf)
    // 根据选择的 RECOVERY_MODE(恢复模式) 的不同,创建不同的 序列化引擎(persistenceEngine_)
    // 以及leader选举客户端(leaderElectionAgent_)
    val (persistenceEngine_, leaderElectionAgent_) = RECOVERY_MODE match {
      case "ZOOKEEPER" =>
        logInfo("Persisting recovery state to ZooKeeper")
        val zkFactory =
          new ZooKeeperRecoveryModeFactory(conf, serializer)
        (zkFactory.createPersistenceEngine(), zkFactory.createLeaderElectionAgent(this))
      case "FILESYSTEM" =>
        val fsFactory =
          new FileSystemRecoveryModeFactory(conf, serializer)
        (fsFactory.createPersistenceEngine(), fsFactory.createLeaderElectionAgent(this))
      case "CUSTOM" =>
        val clazz = Utils.classForName(conf.get("spark.deploy.recoveryMode.factory"))
        val factory = clazz.getConstructor(classOf[SparkConf], classOf[Serializer])
          .newInstance(conf, serializer)
          .asInstanceOf[StandaloneRecoveryModeFactory]
        (factory.createPersistenceEngine(), factory.createLeaderElectionAgent(this))
      case _ =>
        (new BlackHolePersistenceEngine(), new MonarchyLeaderAgent(this))
    }
    persistenceEngine = persistenceEngine_
    leaderElectionAgent = leaderElectionAgent_
  }
```

> org.apache.spark.deploy.master.ZooKeeperRecoveryModeFactory

```scala
private[master] class ZooKeeperRecoveryModeFactory(conf: SparkConf, serializer: Serializer)
  extends StandaloneRecoveryModeFactory(conf, serializer) {

  def createPersistenceEngine(): PersistenceEngine = {
      // 序列化方式
    new ZooKeeperPersistenceEngine(conf, serializer)
  }

  def createLeaderElectionAgent(master: LeaderElectable): LeaderElectionAgent = {
      // leader选举的 agent
    new ZooKeeperLeaderElectionAgent(master, conf)
  }
}
```

leader选举客户端的agent ，构造器：

> org.apache.spark.deploy.master.ZooKeeperLeaderElectionAgent

```scala
private[master] class ZooKeeperLeaderElectionAgent(val masterInstance: LeaderElectable,
    conf: SparkConf) extends LeaderLatchListener with LeaderElectionAgent with Logging  {

  val WORKING_DIR = conf.get("spark.deploy.zookeeper.dir", "/spark") + "/leader_election"

  private var zk: CuratorFramework = _
  private var leaderLatch: LeaderLatch = _
  private var status = LeadershipStatus.NOT_LEADER

  start()
}
```

> org.apache.spark.deploy.master.ZooKeeperLeaderElectionAgent#start

```scala
  private def start() {
    logInfo("Starting ZooKeeper LeaderElection agent")
    // 创建 curator的客户端
    zk = SparkCuratorUtil.newClient(conf)
    // 创建一个 leaderLatch
    leaderLatch = new LeaderLatch(zk, WORKING_DIR)
    //添加 listener的回调函数
    leaderLatch.addListener(this)
    // 开始
    leaderLatch.start()
  }
```

可见ZooKeeperLeaderElectionAgent本身就是 leaderLatch的listener，看一下其实现：

```scala
  //  curator
  override def isLeader() {
    synchronized {
      // could have lost leadership by now.
      // 如果不是leader直接返回,是leader的更新状态
      if (!leaderLatch.hasLeadership) {
        return
      }

      logInfo("We have gained leadership")
      // 则更新 为master的状态
      updateLeadershipStatus(true)
    }
  }

  override def notLeader() {
    synchronized {
      // could have gained leadership by now.
      // 不是leader,返回; 是leader的更新状态
      if (leaderLatch.hasLeadership) {
        return
      }

      logInfo("We have lost leadership")
      updateLeadershipStatus(false)
    }
  }
```

更新master装填：

```scala
  // 更新master的状态
  private def updateLeadershipStatus(isLeader: Boolean) {
    if (isLeader && status == LeadershipStatus.NOT_LEADER) {
      status = LeadershipStatus.LEADER
      masterInstance.electedLeader()
    } else if (!isLeader && status == LeadershipStatus.LEADER) {
      status = LeadershipStatus.NOT_LEADER
      masterInstance.revokedLeadership()
    }
  }
```

看一下更新为master时的操作：

> org.apache.spark.deploy.master.Master#electedLeader

```scala
// master 给自己发送 ElectedLeader 消息
override def electedLeader() {
    self.send(ElectedLeader)
  }
```

看一下其处理：

> org.apache.spark.deploy.master.Master#receive

```scala
 override def receive: PartialFunction[Any, Unit] = {
    // leader选举的开始
    case ElectedLeader =>
      // 先使用序列化器,从zk中读取原来 保存的数据
      val (storedApps, storedDrivers, storedWorkers) = persistenceEngine.readPersistedData(rpcEnv)
      // 如果没有 保存数据,则直接更改状态为 Alive
      state = if (storedApps.isEmpty && storedDrivers.isEmpty && storedWorkers.isEmpty) {
        RecoveryState.ALIVE
      } else {
        // 有数据,则更改状态为 RECOVERING
        RecoveryState.RECOVERING
      }
      logInfo("I have been elected leader! New state: " + state)
      // 如果状态为RECOVERING,则 调用beginRecovery 开始进行获取
      // 并 启动一个延迟任务,延迟时间为conf.getLong("spark.worker.timeout", 60) * 1000
      // 此延迟任务主要是发送一个 CompleteRecovery 完成获取的消息给master自己
      if (state == RecoveryState.RECOVERING) {
        beginRecovery(storedApps, storedDrivers, storedWorkers)
        recoveryCompletionTask = forwardMessageThread.schedule(new Runnable {
          override def run(): Unit = Utils.tryLogNonFatalError {
            self.send(CompleteRecovery)
          }
        }, WORKER_TIMEOUT_MS, TimeUnit.MILLISECONDS)
      }
    // 完成 master恢复的操作
    case CompleteRecovery => completeRecovery()
....
 }
```

看一下读取zk数据的操作:

> org.apache.spark.deploy.master.PersistenceEngine#readPersistedData

```scala
    // 读取序列化的数据
  final def readPersistedData(
      rpcEnv: RpcEnv): (Seq[ApplicationInfo], Seq[DriverInfo], Seq[WorkerInfo]) = {
    rpcEnv.deserialize { () =>
        // 读取app   读取 deriver  读取 worker
      (read[ApplicationInfo]("app_"), read[DriverInfo]("driver_"), read[WorkerInfo]("worker_"))
    }
  }
```

> org.apache.spark.deploy.master.ZooKeeperPersistenceEngine#read

```java
  // 从zk中数据序列化的数据
  override def read[T: ClassTag](prefix: String): Seq[T] = {
    zk.getChildren.forPath(WORKING_DIR).asScala
      .filter(_.startsWith(prefix)).flatMap(deserializeFromFile[T])
  }
```

可见，只是从WORKING_DIR这个路径中读取数据，反进行返回。

```java
  // leader 读取完 序列化的备份数据, 开始进行恢复操作
  private def beginRecovery(storedApps: Seq[ApplicationInfo], storedDrivers: Seq[DriverInfo],
      storedWorkers: Seq[WorkerInfo]) {
    // 如果有存储的app,则尝试重新注册 app,并修改器状态为 UNKNOWN, 并向app的driver发送消息 MasterChanged
    for (app <- storedApps) {
      logInfo("Trying to recover app: " + app.id)
      try {
        // 重新注册app
        registerApplication(app)
        // 更新app状态
        app.state = ApplicationState.UNKNOWN
        // 向app的driver发送消息
        app.driver.send(MasterChanged(self, masterWebUiUrl))
      } catch {
        case e: Exception => logInfo("App " + app.id + " had exception on reconnect")
      }
    }
    // 有driver,则保存driver的信息
    for (driver <- storedDrivers) {
      // Here we just read in the list of drivers. Any drivers associated with now-lost workers
      // will be re-launched when we detect that the worker is missing.
      drivers += driver
    }
    // 有保存的worker信息,
    // 1. 重新注册worker
    // 2. 更新worker的状态为 UNKNOWN
    // 3. 向worker发送MasterChanged 的消息
    for (worker <- storedWorkers) {
      logInfo("Trying to recover worker: " + worker.id)
      try {
        // 重新注册worker
        registerWorker(worker)
        // 更新worker的状态为 UNKNOWN
        worker.state = WorkerState.UNKNOWN
        // 向worker 发送消息
        worker.endpoint.send(MasterChanged(self, masterWebUiUrl))
      } catch {
        case e: Exception => logInfo("Worker " + worker.id + " had exception on reconnect")
      }
    }
  }
```

上面就是针对读取的app，driver，worker来进行恢复操作。

定时任务：

```scala
// 默认是  60s; woker的超时时间
private val WORKER_TIMEOUT_MS = conf.getLong("spark.worker.timeout", 60) * 1000
// 提交一个定时任务,也就是说 worker app 在默认的60s内,没有恢复,则任务出错了.
recoveryCompletionTask = forwardMessageThread.schedule(new Runnable {
    override def run(): Unit = Utils.tryLogNonFatalError {
        self.send(CompleteRecovery)
    }
}, WORKER_TIMEOUT_MS, TimeUnit.MILLISECONDS)
```

最后，完成leader的恢复动作：

> org.apache.spark.deploy.master.Master#completeRecovery

```scala
  // 完成leader的恢复动作
  private def completeRecovery() {
    // Ensure "only-once" recovery semantics using a short synchronization period.
    // 如果 master的状态不是 RECOVERING,则退出
    if (state != RecoveryState.RECOVERING) { return }
    // 更新状态
    state = RecoveryState.COMPLETING_RECOVERY

    // Kill off any workers and apps that didn't respond to us.
    // 删除那些没有回复的 worker
    workers.filter(_.state == WorkerState.UNKNOWN).foreach(
      removeWorker(_, "Not responding for recovery"))
    // 把那些没有回复的 app标记为完成
    apps.filter(_.state == ApplicationState.UNKNOWN).foreach(finishApplication)

    // Update the state of recovered apps to RUNNING
    // 把等待的app标记为  RUNNING
    apps.filter(_.state == ApplicationState.WAITING).foreach(_.state = ApplicationState.RUNNING)

    // Reschedule drivers which were not claimed by any workers
    // 操作那些worker不为空的driver
    // 1. 如果设置了supervise, 表示重新启动driver
    // 2. 没有设置supervise,则 移除driver
    drivers.filter(_.worker.isEmpty).foreach { d =>
      logWarning(s"Driver ${d.id} was not found after master recovery")
      if (d.desc.supervise) {
        logWarning(s"Re-launching ${d.id}")
        relaunchDriver(d)
      } else {
        removeDriver(d.id, DriverState.ERROR, None)
        logWarning(s"Did not re-launch ${d.id} because it was not supervised")
      }
    }
    // 更新状态为 ALIVE
    state = RecoveryState.ALIVE
    // 进行一些 资源的调度
    schedule()
    // 打印 完成的 Recovery
    logInfo("Recovery complete - resuming operations!")
  }
```

此操作中可以看到，对于那些没有响应的app，worker就会标记为完成和和删除； 对于worker不是空的driver设置了supervise则重新launch，否则直接删除driver。



































