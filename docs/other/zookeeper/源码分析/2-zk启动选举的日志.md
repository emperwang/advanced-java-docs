[TOC]

# 分析zk启动时的一段选举日志

本日志的zk版本为3.5.8,当前最新的稳定 版本。

配置：

```properties
# The number of milliseconds of each tick
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/mnt/zookeeper-3.5.8-bin/data
clientPort=2181
autopurge.purgeInterval=1
server.1=name2:2888:3888
server.2=name3:2888:3888
server.3=name4:2888:3888
```

server1.1日志:

```shell
2020-07-09 14:28:17,499 [myid:] - INFO  [main:QuorumPeerConfig@135] - Reading configuration from: /mnt/zookeeper-3.5.8-bin/bin/../conf/zoo.cfg
2020-07-09 14:28:17,533 [myid:] - INFO  [main:QuorumPeerConfig@387] - clientPortAddress is 0.0.0.0:2181
2020-07-09 14:28:17,534 [myid:] - INFO  [main:QuorumPeerConfig@391] - secureClientPort is not set
2020-07-09 14:28:17,562 [myid:1] - INFO  [main:DatadirCleanupManager@78] - autopurge.snapRetainCount set to 3
2020-07-09 14:28:17,564 [myid:1] - INFO  [main:DatadirCleanupManager@79] - autopurge.purgeInterval set to 1
2020-07-09 14:28:17,577 [myid:1] - INFO  [main:ManagedUtil@45] - Log4j 1.2 jmx support found and enabled.
2020-07-09 14:28:17,584 [myid:1] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@138] - Purge task started.
2020-07-09 14:28:17,591 [myid:1] - INFO  [PurgeTask:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:17,642 [myid:1] - INFO  [main:QuorumPeerMain@141] - Starting quorum peer
2020-07-09 14:28:17,659 [myid:1] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@144] - Purge task completed.
2020-07-09 14:28:17,677 [myid:1] - INFO  [main:ServerCnxnFactory@135] - Using org.apache.zookeeper.server.NIOServerCnxnFactory as server connection factory
2020-07-09 14:28:17,684 [myid:1] - INFO  [main:NIOServerCnxnFactory@673] - Configuring NIO connection handler with 10s sessionless connection timeout, 1 selector thread(s), 2 worker threads, and 6
4 kB direct buffers.
2020-07-09 14:28:17,696 [myid:1] - INFO  [main:NIOServerCnxnFactory@686] - binding to port 0.0.0.0/0.0.0.0:2181
2020-07-09 14:28:17,823 [myid:1] - INFO  [main:Log@169] - Logging initialized @1809ms to org.eclipse.jetty.util.log.Slf4jLog
2020-07-09 14:28:18,333 [myid:1] - WARN  [main:ContextHandler@1520] - o.e.j.s.ServletContextHandler@3327bd23{/,null,UNAVAILABLE} contextPath ends with /*
2020-07-09 14:28:18,334 [myid:1] - WARN  [main:ContextHandler@1531] - Empty contextPath
2020-07-09 14:28:18,398 [myid:1] - INFO  [main:X509Util@79] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
2020-07-09 14:28:18,400 [myid:1] - INFO  [main:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:18,400 [myid:1] - INFO  [main:QuorumPeer@1470] - Local sessions disabled
2020-07-09 14:28:18,401 [myid:1] - INFO  [main:QuorumPeer@1481] - Local session upgrading disabled
2020-07-09 14:28:18,401 [myid:1] - INFO  [main:QuorumPeer@1448] - tickTime set to 2000
2020-07-09 14:28:18,401 [myid:1] - INFO  [main:QuorumPeer@1492] - minSessionTimeout set to 4000
2020-07-09 14:28:18,401 [myid:1] - INFO  [main:QuorumPeer@1503] - maxSessionTimeout set to 40000
2020-07-09 14:28:18,404 [myid:1] - INFO  [main:QuorumPeer@1518] - initLimit set to 10
2020-07-09 14:28:18,434 [myid:1] - INFO  [main:ZKDatabase@117] - zookeeper.snapshotSizeFactor = 0.33
2020-07-09 14:28:18,438 [myid:1] - INFO  [main:QuorumPeer@1763] - Using insecure (non-TLS) quorum communication
2020-07-09 14:28:18,438 [myid:1] - INFO  [main:QuorumPeer@1769] - Port unification disabled
2020-07-09 14:28:18,438 [myid:1] - INFO  [main:QuorumPeer@2137] - QuorumPeer communication is not secured! (SASL auth disabled)
2020-07-09 14:28:18,439 [myid:1] - INFO  [main:QuorumPeer@2166] - quorum.cnxn.threads.size set to 20
2020-07-09 14:28:18,440 [myid:1] - INFO  [main:FileSnap@83] - Reading snapshot /mnt/zookeeper-3.5.8-bin/data/version-2/snapshot.0
2020-07-09 14:28:18,488 [myid:1] - INFO  [main:Server@359] - jetty-9.4.24.v20191120; built: 2019-11-20T21:37:49.771Z; git: 363d5f2df3a8a28de40604320230664b9c793c16; jvm 1.8.0_232-b09
2020-07-09 14:28:18,636 [myid:1] - INFO  [main:DefaultSessionIdManager@333] - DefaultSessionIdManager workerName=node0
2020-07-09 14:28:18,637 [myid:1] - INFO  [main:DefaultSessionIdManager@338] - No SessionScavenger set, using defaults
2020-07-09 14:28:18,644 [myid:1] - INFO  [main:HouseKeeper@140] - node0 Scavenging every 660000ms
2020-07-09 14:28:18,678 [myid:1] - INFO  [main:ContextHandler@825] - Started o.e.j.s.ServletContextHandler@3327bd23{/,null,AVAILABLE}
2020-07-09 14:28:18,701 [myid:1] - INFO  [main:AbstractConnector@330] - Started ServerConnector@724af044{HTTP/1.1,[http/1.1]}{0.0.0.0:8080}
2020-07-09 14:28:18,702 [myid:1] - INFO  [main:Server@399] - Started @2689ms
2020-07-09 14:28:18,703 [myid:1] - INFO  [main:JettyAdminServer@112] - Started AdminServer on address 0.0.0.0, port 8080 and command URL /commands
2020-07-09 14:28:18,721 [myid:1] - INFO  [main:QuorumCnxManager$Listener@878] - Election port bind maximum retries is 3
2020-07-09 14:28:18,743 [myid:1] - INFO  [QuorumPeerListener:QuorumCnxManager$Listener@929] - 1 is accepting connections now, my election bind port: name2/192.168.72.35:3888
2020-07-09 14:28:18,763 [myid:1] - INFO  [QuorumPeer[myid=1](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1175] - LOOKING
2020-07-09 14:28:18,765 [myid:1] - INFO  [QuorumPeer[myid=1](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@903] - New election. My id =  1, proposed zxid=0x0
# 发送自己的选票,即先选举自己为 leader
2020-07-09 14:28:18,790 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 1 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 1 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)2020-07-09 14:28:18,792 [myid:1] - INFO  [name2/192.168.72.35:3888:QuorumCnxManager$Listener@936] - Received connection request from /192.168.72.36:52848
# 开始关闭 小到大的连接
2020-07-09 14:28:18,804 [myid:1] - INFO  [QuorumConnectionThread-[myid=1]-1:QuorumCnxManager@481] - Have smaller server identifier, so dropping the connection: (myId:1 --> sid:2)
2020-07-09 14:28:18,808 [myid:1] - INFO  [QuorumConnectionThread-[myid=1]-2:QuorumCnxManager@481] - Have smaller server identifier, so dropping the connection: (myId:1 --> sid:3)
## 接受新的连接
2020-07-09 14:28:18,811 [myid:1] - INFO  [name2/192.168.72.35:3888:QuorumCnxManager$Listener@936] - Received connection request from /192.168.72.37:42188
# 开始接收选票
# 接收sid 2发送的选票,选举sid 3为leader
2020-07-09 14:28:18,814 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 2 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# 接收sid 1发送的选票,选举sid 3为leader, 此即自己发送给自己的选票,也就是更新了自己的选票
2020-07-09 14:28:18,816 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 1 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# 接收sid 2发送的选票,选举sid 3为leader, 此时sid 2的状态为 FOLLOWING
2020-07-09 14:28:18,820 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), FOLLOWING (n.state), 2 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# sid 3发送选举自己的选票, 状态为 LOOKING
2020-07-09 14:28:18,828 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# sid 2发送的选举 sid 3为leader的选票, sid 2状态为 FOLLOWING
2020-07-09 14:28:18,830 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), FOLLOWING (n.state), 2 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# sid 3选举sid 3为leader的选票, 当前sid 3的状态为 LEADING
2020-07-09 14:28:18,832 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LEADING (n.state), 3 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# sid 3的选票, sid 3的状态为 LEADING
2020-07-09 14:28:18,835 [myid:1] - INFO  [WorkerReceiver[myid=1]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LEADING (n.state), 3 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
# 更新的自己的状态为 FOLLOWING
2020-07-09 14:28:19,036 [myid:1] - INFO  [QuorumPeer[myid=1](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1251] - FOLLOWING
2020-07-09 14:28:19,050 [myid:1] - INFO  [QuorumPeer[myid=1](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Learner@91] - TCP NoDelay set to: true
2020-07-09 14:28:19,061 [myid:1] - INFO  [QuorumPeer[myid=1](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:zookeeper.version=3.5.8-f439ca583e70862c3068a1f2a7d4d068eec33315, built on 05/04/2020 15:07 GMT

```

server.2日志:

```shell
2020-07-09 14:28:16,198 [myid:] - INFO  [main:QuorumPeerConfig@135] - Reading configuration from: /mnt/zookeeper-3.5.8-bin/bin/../conf/zoo.cfg
2020-07-09 14:28:16,236 [myid:] - INFO  [main:QuorumPeerConfig@387] - clientPortAddress is 0.0.0.0:2181
2020-07-09 14:28:16,237 [myid:] - INFO  [main:QuorumPeerConfig@391] - secureClientPort is not set
2020-07-09 14:28:16,270 [myid:2] - INFO  [main:DatadirCleanupManager@78] - autopurge.snapRetainCount set to 3
2020-07-09 14:28:16,271 [myid:2] - INFO  [main:DatadirCleanupManager@79] - autopurge.purgeInterval set to 1
2020-07-09 14:28:16,287 [myid:2] - INFO  [main:ManagedUtil@45] - Log4j 1.2 jmx support found and enabled.
2020-07-09 14:28:16,293 [myid:2] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@138] - Purge task started.
2020-07-09 14:28:16,301 [myid:2] - INFO  [PurgeTask:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:16,356 [myid:2] - INFO  [main:QuorumPeerMain@141] - Starting quorum peer
2020-07-09 14:28:16,385 [myid:2] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@144] - Purge task completed.
2020-07-09 14:28:16,391 [myid:2] - INFO  [main:ServerCnxnFactory@135] - Using org.apache.zookeeper.server.NIOServerCnxnFactory as server connection factory
2020-07-09 14:28:16,398 [myid:2] - INFO  [main:NIOServerCnxnFactory@673] - Configuring NIO connection handler with 10s sessionless connection timeout, 1 selector thread(s), 2 worker threads, and 6
4 kB direct buffers.
2020-07-09 14:28:16,409 [myid:2] - INFO  [main:NIOServerCnxnFactory@686] - binding to port 0.0.0.0/0.0.0.0:2181
2020-07-09 14:28:16,518 [myid:2] - INFO  [main:Log@169] - Logging initialized @1773ms to org.eclipse.jetty.util.log.Slf4jLog
2020-07-09 14:28:17,113 [myid:2] - WARN  [main:ContextHandler@1520] - o.e.j.s.ServletContextHandler@3327bd23{/,null,UNAVAILABLE} contextPath ends with /*
2020-07-09 14:28:17,114 [myid:2] - WARN  [main:ContextHandler@1531] - Empty contextPath
2020-07-09 14:28:17,227 [myid:2] - INFO  [main:X509Util@79] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
# 初始信息的打印
2020-07-09 14:28:17,229 [myid:2] - INFO  [main:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:17,230 [myid:2] - INFO  [main:QuorumPeer@1470] - Local sessions disabled
2020-07-09 14:28:17,230 [myid:2] - INFO  [main:QuorumPeer@1481] - Local session upgrading disabled
2020-07-09 14:28:17,239 [myid:2] - INFO  [main:QuorumPeer@1448] - tickTime set to 2000
2020-07-09 14:28:17,240 [myid:2] - INFO  [main:QuorumPeer@1492] - minSessionTimeout set to 4000
2020-07-09 14:28:17,240 [myid:2] - INFO  [main:QuorumPeer@1503] - maxSessionTimeout set to 40000
2020-07-09 14:28:17,240 [myid:2] - INFO  [main:QuorumPeer@1518] - initLimit set to 10
2020-07-09 14:28:17,287 [myid:2] - INFO  [main:ZKDatabase@117] - zookeeper.snapshotSizeFactor = 0.33
2020-07-09 14:28:17,291 [myid:2] - INFO  [main:QuorumPeer@1763] - Using insecure (non-TLS) quorum communication
2020-07-09 14:28:17,293 [myid:2] - INFO  [main:QuorumPeer@1769] - Port unification disabled
2020-07-09 14:28:17,293 [myid:2] - INFO  [main:QuorumPeer@2137] - QuorumPeer communication is not secured! (SASL auth disabled)
2020-07-09 14:28:17,294 [myid:2] - INFO  [main:QuorumPeer@2166] - quorum.cnxn.threads.size set to 20
2020-07-09 14:28:17,308 [myid:2] - INFO  [main:FileSnap@83] - Reading snapshot /mnt/zookeeper-3.5.8-bin/data/version-2/snapshot.0
2020-07-09 14:28:17,347 [myid:2] - INFO  [main:Server@359] - jetty-9.4.24.v20191120; built: 2019-11-20T21:37:49.771Z; git: 363d5f2df3a8a28de40604320230664b9c793c16; jvm 1.8.0_232-b09
2020-07-09 14:28:17,519 [myid:2] - INFO  [main:DefaultSessionIdManager@333] - DefaultSessionIdManager workerName=node0
2020-07-09 14:28:17,520 [myid:2] - INFO  [main:DefaultSessionIdManager@338] - No SessionScavenger set, using defaults
2020-07-09 14:28:17,525 [myid:2] - INFO  [main:HouseKeeper@140] - node0 Scavenging every 660000ms
2020-07-09 14:28:17,561 [myid:2] - INFO  [main:ContextHandler@825] - Started o.e.j.s.ServletContextHandler@3327bd23{/,null,AVAILABLE}
2020-07-09 14:28:17,584 [myid:2] - INFO  [main:AbstractConnector@330] - Started ServerConnector@724af044{HTTP/1.1,[http/1.1]}{0.0.0.0:8080}
2020-07-09 14:28:17,585 [myid:2] - INFO  [main:Server@399] - Started @2841ms
2020-07-09 14:28:17,586 [myid:2] - INFO  [main:JettyAdminServer@112] - Started AdminServer on address 0.0.0.0, port 8080 and command URL /commands
2020-07-09 14:28:17,619 [myid:2] - INFO  [main:QuorumCnxManager$Listener@878] - Election port bind maximum retries is 3
2020-07-09 14:28:17,633 [myid:2] - INFO  [QuorumPeerListener:QuorumCnxManager$Listener@929] - 2 is accepting connections now, my election bind port: name3/192.168.72.36:3888
# 自己的当前状态
2020-07-09 14:28:17,657 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1175] - LOOKING
2020-07-09 14:28:17,660 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@903] - New election. My id =  2, proposed zxid=0x0
# 连接sever.1 失败,因此sevrer.1先启动,并连接到了sever.2;后面又连接成功,因为server.1做了关闭连接的动作
2020-07-09 14:28:17,689 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-1:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
 # 自己的第一个选票, 先选举自己
2020-07-09 14:28:17,693 [myid:2] - INFO  [WorkerReceiver[myid=2]:FastLeaderElection@697] - Notification: 2 (message format version), 2 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 2
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 关闭连接的操作
2020-07-09 14:28:17,711 [myid:2] - INFO  [QuorumConnectionThread-[myid=2]-2:QuorumCnxManager@481] - Have smaller server identifier, so dropping the connection: (myId:2 --> sid:3)
2020-07-09 14:28:17,715 [myid:2] - INFO  [name3/192.168.72.36:3888:QuorumCnxManager$Listener@936] - Received connection request from /192.168.72.37:58590
# 下面是接收的选票
# 接收到sid 3发送过来的选举 sid 3为leader的选票
2020-07-09 14:28:17,730 [myid:2] - INFO  [WorkerReceiver[myid=2]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 同样的原因,连接server.1 失败
2020-07-09 14:28:17,751 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-3:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
# server.2更新自己的选票,并发送新 选举sid 3的选票
2020-07-09 14:28:17,775 [myid:2] - INFO  [WorkerReceiver[myid=2]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 2
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 接收sid 3选举sid 3的选票
2020-07-09 14:28:17,776 [myid:2] - INFO  [WorkerReceiver[myid=2]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 票数过半, 选举 sid 3为leader, 自己状态更新为 FOLLOWING
 2020-07-09 14:28:17,978 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1251] - FOLLOWING
2020-07-09 14:28:17,993 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Learner@91] - TCP NoDelay set to: true
2020-07-09 14:28:18,015 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:zookeeper.version=3.5.8-f439ca583e70862c3068a1f2a7d4d068eec33315, built on 05/04/2020 15:07 GMT
2020-07-09 14:28:18,016 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:host.name=name3
```



server.3日志:

```shell
2020-07-09 14:28:14,275 [myid:] - INFO  [main:QuorumPeerConfig@135] - Reading configuration from: /mnt/zookeeper-3.5.8-bin/bin/../conf/zoo.cfg
2020-07-09 14:28:14,315 [myid:] - INFO  [main:QuorumPeerConfig@387] - clientPortAddress is 0.0.0.0:2181
2020-07-09 14:28:14,317 [myid:] - INFO  [main:QuorumPeerConfig@391] - secureClientPort is not set
2020-07-09 14:28:14,348 [myid:3] - INFO  [main:DatadirCleanupManager@78] - autopurge.snapRetainCount set to 3
2020-07-09 14:28:14,349 [myid:3] - INFO  [main:DatadirCleanupManager@79] - autopurge.purgeInterval set to 1
2020-07-09 14:28:14,358 [myid:3] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@138] - Purge task started.
2020-07-09 14:28:14,365 [myid:3] - INFO  [main:ManagedUtil@45] - Log4j 1.2 jmx support found and enabled.
2020-07-09 14:28:14,369 [myid:3] - INFO  [PurgeTask:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:14,418 [myid:3] - INFO  [PurgeTask:DatadirCleanupManager$PurgeTask@144] - Purge task completed.
2020-07-09 14:28:14,437 [myid:3] - INFO  [main:QuorumPeerMain@141] - Starting quorum peer
2020-07-09 14:28:14,459 [myid:3] - INFO  [main:ServerCnxnFactory@135] - Using org.apache.zookeeper.server.NIOServerCnxnFactory as server connection factory
2020-07-09 14:28:14,466 [myid:3] - INFO  [main:NIOServerCnxnFactory@673] - Configuring NIO connection handler with 10s sessionless connection timeout, 1 selector thread(s), 2 worker threads, and 6
4 kB direct buffers.
2020-07-09 14:28:14,480 [myid:3] - INFO  [main:NIOServerCnxnFactory@686] - binding to port 0.0.0.0/0.0.0.0:2181
2020-07-09 14:28:14,590 [myid:3] - INFO  [main:Log@169] - Logging initialized @1785ms to org.eclipse.jetty.util.log.Slf4jLog
2020-07-09 14:28:15,210 [myid:3] - WARN  [main:ContextHandler@1520] - o.e.j.s.ServletContextHandler@3327bd23{/,null,UNAVAILABLE} contextPath ends with /*
2020-07-09 14:28:15,215 [myid:3] - WARN  [main:ContextHandler@1531] - Empty contextPath
2020-07-09 14:28:15,296 [myid:3] - INFO  [main:X509Util@79] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
2020-07-09 14:28:15,302 [myid:3] - INFO  [main:FileTxnSnapLog@115] - zookeeper.snapshot.trust.empty : false
2020-07-09 14:28:15,303 [myid:3] - INFO  [main:QuorumPeer@1470] - Local sessions disabled
2020-07-09 14:28:15,303 [myid:3] - INFO  [main:QuorumPeer@1481] - Local session upgrading disabled
2020-07-09 14:28:15,304 [myid:3] - INFO  [main:QuorumPeer@1448] - tickTime set to 2000
2020-07-09 14:28:15,306 [myid:3] - INFO  [main:QuorumPeer@1492] - minSessionTimeout set to 4000
2020-07-09 14:28:15,306 [myid:3] - INFO  [main:QuorumPeer@1503] - maxSessionTimeout set to 40000
2020-07-09 14:28:15,306 [myid:3] - INFO  [main:QuorumPeer@1518] - initLimit set to 10
2020-07-09 14:28:15,346 [myid:3] - INFO  [main:ZKDatabase@117] - zookeeper.snapshotSizeFactor = 0.33
2020-07-09 14:28:15,365 [myid:3] - INFO  [main:QuorumPeer@1763] - Using insecure (non-TLS) quorum communication
2020-07-09 14:28:15,365 [myid:3] - INFO  [main:QuorumPeer@1769] - Port unification disabled
2020-07-09 14:28:15,365 [myid:3] - INFO  [main:QuorumPeer@2137] - QuorumPeer communication is not secured! (SASL auth disabled)
2020-07-09 14:28:15,366 [myid:3] - INFO  [main:QuorumPeer@2166] - quorum.cnxn.threads.size set to 20
2020-07-09 14:28:15,369 [myid:3] - INFO  [main:FileSnap@83] - Reading snapshot /mnt/zookeeper-3.5.8-bin/data/version-2/snapshot.0
2020-07-09 14:28:15,425 [myid:3] - INFO  [main:Server@359] - jetty-9.4.24.v20191120; built: 2019-11-20T21:37:49.771Z; git: 363d5f2df3a8a28de40604320230664b9c793c16; jvm 1.8.0_232-b09
2020-07-09 14:28:15,552 [myid:3] - INFO  [main:DefaultSessionIdManager@333] - DefaultSessionIdManager workerName=node0
2020-07-09 14:28:15,553 [myid:3] - INFO  [main:DefaultSessionIdManager@338] - No SessionScavenger set, using defaults
2020-07-09 14:28:15,560 [myid:3] - INFO  [main:HouseKeeper@140] - node0 Scavenging every 660000ms
2020-07-09 14:28:15,601 [myid:3] - INFO  [main:ContextHandler@825] - Started o.e.j.s.ServletContextHandler@3327bd23{/,null,AVAILABLE}
2020-07-09 14:28:15,631 [myid:3] - INFO  [main:AbstractConnector@330] - Started ServerConnector@724af044{HTTP/1.1,[http/1.1]}{0.0.0.0:8080}
2020-07-09 14:28:15,633 [myid:3] - INFO  [main:Server@399] - Started @2828ms
2020-07-09 14:28:15,636 [myid:3] - INFO  [main:JettyAdminServer@112] - Started AdminServer on address 0.0.0.0, port 8080 and command URL /commands
2020-07-09 14:28:15,673 [myid:3] - INFO  [main:QuorumCnxManager$Listener@878] - Election port bind maximum retries is 3
# 自己选举的地址
2020-07-09 14:28:15,683 [myid:3] - INFO  [QuorumPeerListener:QuorumCnxManager$Listener@929] - 3 is accepting connections now, my election bind port: name4/192.168.72.37:3888
# 自己的状态
2020-07-09 14:28:15,743 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1175] - LOOKING
2020-07-09 14:28:15,752 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@903] - New election. My id =  3, proposed zxid=0x0
# 先选举自己为leader
2020-07-09 14:28:15,771 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
2020-07-09 14:28:15,784 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-2:QuorumCnxManager@381] - Cannot open channel to 2 at election address name3/192.168.72.36:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:15,785 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-1:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:15,981 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-2:QuorumCnxManager@381] - Cannot open channel to 2 at election address name3/192.168.72.36:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:15,981 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@937] - Notification time out: 400
2020-07-09 14:28:15,990 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-3:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:16,392 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-3:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:16,416 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-3:QuorumCnxManager@381] - Cannot open channel to 2 at election address name3/192.168.72.36:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
2020-07-09 14:28:16,422 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@937] - Notification time out: 800
2020-07-09 14:28:17,181 [myid:3] - INFO  [name4/192.168.72.37:3888:QuorumCnxManager$Listener@936] - Received connection request from /192.168.72.36:59046
2020-07-09 14:28:17,224 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@937] - Notification time out: 1600
# 接收到自己投给自己的选票
2020-07-09 14:28:17,227 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
2020-07-09 14:28:17,228 [myid:3] - WARN  [QuorumConnectionThread-[myid=3]-3:QuorumCnxManager@381] - Cannot open channel to 1 at election address name2/192.168.72.35:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
# 接收到 server.2 选举 sid 2为leader的选票
2020-07-09 14:28:17,232 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 2 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 2
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 接收到 server.2 选举sid 3为leader的选票
2020-07-09 14:28:17,234 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 2
 (n.sid), 0x0 (n.peerEPoch), LOOKING (my state)0 (n.config version)
 # 选举自己为leader
2020-07-09 14:28:17,438 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):QuorumPeer@1263] - LEADING
2020-07-09 14:28:17,452 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Leader@66] - TCP NoDelay set to: true
2020-07-09 14:28:17,452 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Leader@86] - zookeeper.leader.maxConcurrentSnapshots = 10
2020-07-09 14:28:17,452 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Leader@88] - zookeeper.leader.maxConcurrentSnapshotTimeout = 5
2020-07-09 14:28:17,752 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:zookeeper.version=3.5.8-f439ca583e70862c3068a1f2a7
d4d068eec33315, built on 05/04/2020 15:07 GMT
2020-07-09 14:28:17,752 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:host.name=name4
2020-07-09 14:28:17,754 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:java.io.tmpdir=/tmp
2020-07-09 14:28:17,754 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:java.compiler=<NA>
2020-07-09 14:28:17,754 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.name=Linux
2020-07-09 14:28:17,754 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.arch=amd64
2020-07-09 14:28:17,759 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.version=3.10.0-957.el7.x86_64
2020-07-09 14:28:17,759 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:user.name=root
2020-07-09 14:28:17,760 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:user.home=/root
2020-07-09 14:28:17,760 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:user.dir=/root
2020-07-09 14:28:17,761 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.memory.free=7MB
2020-07-09 14:28:17,761 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.memory.max=966MB
2020-07-09 14:28:17,761 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Environment@109] - Server environment:os.memory.total=15MB
2020-07-09 14:28:17,766 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):ZooKeeperServer@938] - minSessionTimeout set to 4000
2020-07-09 14:28:17,766 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):ZooKeeperServer@947] - maxSessionTimeout set to 40000
2020-07-09 14:28:17,768 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):ZooKeeperServer@166] - Created server with tickTime 2000 minSessionTimeout 4000 maxSessionTimeout 40000 datadir /mnt/zookeeper-3.5.8-bin/data/version-2 snapdir /mnt/zookeeper-3.5.8-bin/data/version-2
# 选举花费的时间
2020-07-09 14:28:17,771 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Leader@464] - LEADING - LEADER ELECTION TOOK - 333 MS
# 创建 快照
2020-07-09 14:28:17,782 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FileTxnSnapLog@404] - Snapshotting: 0x0 to /mnt/zookeeper-3.5.8-bin/data/version-2/snapshot.0
2020-07-09 14:28:18,507 [myid:3] - INFO  [name4/192.168.72.37:3888:QuorumCnxManager$Listener@936] - Received connection request from /192.168.72.35:53332
# 接收到 sid 1 选举sid 1为leader的选票
2020-07-09 14:28:18,524 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 1 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 1 (n.sid), 0x0 (n.peerEPoch), LEADING (my state)0 (n.config version)
# 接收到 sid 1选举sid 3为leader的选票
2020-07-09 14:28:18,531 [myid:3] - INFO  [WorkerReceiver[myid=3]:FastLeaderElection@697] - Notification: 2 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 1 (n.sid), 0x0 (n.peerEPoch), LEADING (my state)0 (n.config version)
# sid 2 对sid 3做 learner的操作
2020-07-09 14:28:18,763 [myid:3] - INFO  [LearnerHandler-/192.168.72.36:47516:LearnerHandler@406] - Follower sid: 2 : info : name3:2888:3888:participant
2020-07-09 14:28:18,793 [myid:3] - INFO  [LearnerHandler-/192.168.72.36:47516:ZKDatabase@295] - On disk txn sync enabled with snapshotSizeFactor 0.33
# sid 2和leader做的同步的操作
2020-07-09 14:28:18,795 [myid:3] - INFO  [LearnerHandler-/192.168.72.36:47516:LearnerHandler@708] - Synchronizing with Follower sid: 2 maxCommittedLog=0x0 minCommittedLog=0x0 lastProcessedZxid=0x0 peerLastZxid=0x0
2020-07-09 14:28:18,795 [myid:3] - INFO  [LearnerHandler-/192.168.72.36:47516:LearnerHandler@752] - Sending DIFF zxid=0x0 for peer sid: 2
# sid 1和leader的同步操作
2020-07-09 14:28:18,811 [myid:3] - INFO  [LearnerHandler-/192.168.72.35:45608:LearnerHandler@406] - Follower sid: 1 : info : name2:2888:3888:participant
2020-07-09 14:28:18,836 [myid:3] - INFO  [LearnerHandler-/192.168.72.35:45608:ZKDatabase@295] - On disk txn sync enabled with snapshotSizeFactor 0.33
2020-07-09 14:28:18,836 [myid:3] - INFO  [LearnerHandler-/192.168.72.35:45608:LearnerHandler@708] - Synchronizing with Follower sid: 1 maxCommittedLog=0x0 minCommittedLog=0x0 lastProcessedZxid=0x0 peerLastZxid=0x0
2020-07-09 14:28:18,837 [myid:3] - INFO  [LearnerHandler-/192.168.72.35:45608:LearnerHandler@752] - Sending DIFF zxid=0x0 for peer sid: 1
2020-07-09 14:28:18,839 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):Leader@1296] - Have quorum of supporters, sids: [ [2, 3],[2, 3] ]; starting up and setting last processed zxid: 0x100000000
2020-07-09 14:28:18,886 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):CommitProcessor@256] - Configuring CommitProcessor with 1 worker threads.
2020-07-09 14:28:18,911 [myid:3] - INFO  [QuorumPeer[myid=3](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):ContainerManager@64] - Using checkIntervalMs=60000 maxPerMinute=10000
2020-07-09 14:28:47,781 [myid:3] - INFO  [NIOWorkerThread-1:FourLetterCommands@234] - The list of known four letter word commands is : [{1936881266=srvr, 1937006964=stat, 2003003491=wchc, 1685417328=dump, 1668445044=crst, 1936880500=srst, 1701738089=envi, 1668247142=conf, -720899=telnet close, 2003003507=wchs, 2003003504=wchp, 1684632179=dirs, 1668247155=cons, 1835955314=mntr, 1769173615=isro, 1920298859=ruok, 1735683435=gtmk, 1937010027=stmk}]
2020-07-09 14:28:47,781 [myid:3] - INFO  [NIOWorkerThread-1:FourLetterCommands@235] - The list of enabled four letter word commands is : [[srvr]]
2020-07-09 14:28:47,782 [myid:3] - INFO  [NIOWorkerThread-1:NIOServerCnxn@518] - Processing srvr command from /127.0.0.1:40758

```

