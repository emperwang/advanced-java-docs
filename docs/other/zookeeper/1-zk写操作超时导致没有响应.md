[TOC]

# 记录一次zk写超时引起的问题

最近线程老是出现kafka和spark连接zk集群出问题，显示连接超时，看一下zk的日志，发现有一个注意点：

日志如下:

```shell
# 错误日志
2016-04-11 15:00:58,981 [myid:] - WARN [SyncThread:0:FileTxnLog@334] - fsync-ing the write ahead log in SyncThread:0 took 13973ms which will adversely effect operation latency. See the ZooKeeper troubleshooting guide

# reason 分析
FOLLOWER 和 LEADER 同步时, fsync操作时间过长,导致超时。
第一步:  分析服务器原因
查看服务器IO和负载高不高，内存实际使用率
```

发现是zk写操作超时，导致了对其他连接没有响应。

解决方法：

```properties
# 第一
dataDir 和 dataLogDir 分开，采用单独的存储设备。
# 官方解析
Having a dedicated log devicehas a large impact on throughput and stable latencies. It is highly recommenedto dedicate a log device and set dataLogDir to point to a directory on thatdevice, and then make sure to point dataDir to a directory not residing on thatdevice.

# 第二种  关闭强制更新操作
forceSync=no
默认是开启的,为避免同步延迟问题,ZK接收导数据后会立刻去将当前状态信息同步到磁盘文件中,同步完成后才会应答.

# 第三种 
把tickTime 和 initLimit 和 syncLimit 参数调大
```



```properties
# 参数解析
## zk服务器或客户端之间维持心跳的间隔,也就是每个tick时间就会发送心跳
tickTime=2000
# tickTime的倍数.用于配置允许followers连接并同步到leader的最大时间.
initLimit=5
# 用于配置leader和follower间进行心跳检测的最大延迟时间,如果在设置的事件内follower无法与leader进行通信,那么follower将会被丢弃
syncLimit=2
```





























































