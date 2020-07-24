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

