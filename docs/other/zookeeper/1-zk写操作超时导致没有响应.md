[TOC]

# 记录一次zk写超时引起的问题

最近线程老是出现kafka和spark连接zk集群出问题，显示连接超时，看一下zk的日志，发现有一个注意点：

日志如下:

```shell
2016-04-11 15:00:58,981 [myid:] - WARN [SyncThread:0:FileTxnLog@334] - fsync-ing the write ahead log in SyncThread:0 took 13973ms which will adversely effect operation latency. See the ZooKeeper troubleshooting guide
```

发现是zk写操作超时，导致了对其他连接没有响应。





























































