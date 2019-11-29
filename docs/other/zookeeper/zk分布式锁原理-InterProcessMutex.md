# zk分布式锁 InterProcessMutex实现

![](../../image/zookeeper/zk-lock1.png)

从图中的包名可以看到其利用zk实现了分布式锁，计数器，队列等操作。本篇咱们解析一下分布式锁的实现。