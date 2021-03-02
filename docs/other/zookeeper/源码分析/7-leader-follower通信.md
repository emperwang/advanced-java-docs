# leader和follower数据通信

上篇分析了leader的选举, 并再最后贴出了leader选举出来后follower和leader要继续做什么, 本篇就继续向下解析leader选举后, leader后面的工作.

## leader

> org.apache.zookeeper.server.quorum.QuorumPeer#run

```java
 @Override
    public void run() {
        setName("QuorumPeer" + "[myid=" + getId() + "]" +
                cnxnFactory.getLocalAddress());

        LOG.debug("Starting quorum peer");
        try {
            /*
             * Main loop
             */
            while (running) {
                // 初始状态为 LOOKING
                // 根据当前的 zk实例状态来进行处理
                switch (getPeerState()) {
                case LOOKING:
                  .....
                    break;
                        // OBSERVING 状态下的处理
                case OBSERVING:
                  ....
                    break;
                        // follower 状态下的处理
                case FOLLOWING:
                   .....
                    break;
                        // leader的处理
                case LEADING:
                    LOG.info("LEADING");
                    try {
                        // 创建leader 并 记录
                        setLeader(makeLeader(logFactory));
                        // leader开始工作,创建 zk实例数据交流的server端
                        // 用于follower和leader同步数据使用
                        // 以及其他的数据 信息交流
                        leader.lead();
                        // 如果退出了,说明出现问题了,则再次设置leader为null,重新进行选举
                        setLeader(null);
                    } catch (Exception e) {
                        LOG.warn("Unexpected exception",e);
                    } finally {
                        if (leader != null) {
                            leader.shutdown("Forcing shutdown");
                            setLeader(null);
                        }
                        setPeerState(ServerState.LOOKING);
                    }
                    break;
                }
            }
        } finally {
    }
```

> org.apache.zookeeper.server.quorum.QuorumPeer#makeLeader

```java
// 创建leader
protected Leader makeLeader(FileTxnSnapLog logFactory) throws IOException {
    return new Leader(this, new LeaderZooKeeperServer(logFactory,this,new ZooKeeperServer.BasicDataTreeBuilder(), this.zkDb));
}

/// 构造器 
Leader(QuorumPeer self,LeaderZooKeeperServer zk) throws IOException {
    this.self = self;
    this.proposalStats = new ProposalStats();
    try {
        // 创建 socket server端
        if (self.getQuorumListenOnAllIPs()) {
            ss = new ServerSocket(self.getQuorumAddress().getPort());
        } else {
            ss = new ServerSocket();
        }
        ss.setReuseAddress(true);
        // server端地址绑定
        if (!self.getQuorumListenOnAllIPs()) {
            ss.bind(self.getQuorumAddress());
        }
    } catch (BindException e) {
        .......
    }
    this.zk=zk;
}

```

![](../../../image/zookeeper/ZookeeperServer.png)

可以看到, 根据最终角色的不同, 创建了zookeeperServer的不同子类, 来实现不同角色下的不同功能.

根据上面代码可以, leader会调用lead()方法, 即 领导集群运行.

> org.apache.zookeeper.server.quorum.Leader#lead

```java
 void lead() throws IOException, InterruptedException {
        self.end_fle = Time.currentElapsedTime();
        // 计算选举花费的时间
        long electionTimeTaken = self.end_fle - self.start_fle;
        self.setElectionTimeTaken(electionTimeTaken);
        LOG.info("LEADING - LEADER ELECTION TOOK - {}", electionTimeTaken);
        self.start_fle = 0;
        self.end_fle = 0;
        try {
            self.tick.set(0);
            zk.loadData();
            leaderStateSummary = new StateSummary(self.getCurrentEpoch(), zk.getLastProcessedZxid());
            // 创建接收 follower 请求的服务端
            // 这里 主要看这里
            cnxAcceptor = new LearnerCnxAcceptor();
            cnxAcceptor.start();
            ...............
            // 启动server
            // 处理器链创建 vote更新  等待对请求进行处理
            startZkServer();
            String initialZxid = System.getProperty("zookeeper.testingonly.initialZxid");
           ......
            boolean tickSkip = true;
            while (true) {
                // 这里会睡眠一段时间
                // 之后睡醒后, 会发送PING包到其他 zk实例节点
                Thread.sleep(self.tickTime / 2);
                if (!tickSkip) {
                    self.tick.incrementAndGet();
                }
                HashSet<Long> syncedSet = new HashSet<Long>();

                // lock on the followers when we use it.
                syncedSet.add(self.getId());

                for (LearnerHandler f : getLearners()) {
                    if (f.synced() && f.getLearnerType() == LearnerType.PARTICIPANT) {
                        syncedSet.add(f.getSid());
                    }
                    f.ping();
                }
				// 如果不超过半数响应, 则关闭
              if (!tickSkip && !self.getQuorumVerifier().containsQuorum(syncedSet)) {
                    shutdown("Not sufficient followers synced, only synced with sids: [ "
                            + getSidSetString(syncedSet) + " ]");
                    return;
              } 
              tickSkip = !tickSkip;
            }
        } finally {
           ...... 
        }
    }
```

这里呢大概做了几件事:

1. 创建了LearnerCnxAcceptor线程, 用于接收其他follower的连接,此连接是leader和follower之间的数据通信
2. 持续运行,并间隔一段时间发送PING 包到其他zk实例
3. 持续监控, 如果集群中 实例 数量 不大于半数,则进行关闭操作

看一下此LearnerCnxAcceptor处理:

> org.apache.zookeeper.server.quorum.Leader.LearnerCnxAcceptor#run

```java
@Override
public void run() {
    try {
        while (!stop) {
            try{
                // 接收其他socket即 follower和 observer的连接
                Socket s = ss.accept();
                // start with the initLimit, once the ack is processed
                // in LearnerHandler switch to the syncLimit
                s.setSoTimeout(self.tickTime * self.initLimit);
                s.setTcpNoDelay(nodelay);

                BufferedInputStream is = new BufferedInputStream(
                    s.getInputStream());
                // 每一个 follower在 leader这里就对应一个 LearnerHandler 处理器
                // 之后使用 LearnerHandler与对应的zk实例进行通信
                LearnerHandler fh = new LearnerHandler(s, is, Leader.this);
                fh.start();
            } catch (SocketException e) {
               .....
            } catch (SaslException e){
                LOG.error("Exception while connecting to quorum learner", e);
            }
        }
    } catch (Exception e) {
        LOG.warn("Exception while accepting follower", e);
    }
}
```

在这里可以看到, 每当要给follower或observer来连接成功后, 就会创建一个LearnerHandler来进行处理; 简单理解的话:`其实每一个follower或observer在leader这里的数据通信表现就是一个LearnerHandler实例.`LearnerHandler中会先和follower进行同步, 之后会一直等待接收数据, 并根据packet类型的不同, 进行不同的处理. 即: LearnerHandler全权处理了和对应zk实例的数据交互.

对于LearnerHandler的解析呢, 会放在后面进行详解.

启动server的操作:

> org.apache.zookeeper.server.quorum.Leader#startZkServer

```java
   // 启动leader
    private synchronized void startZkServer() {
        // Update lastCommitted and Db's zxid to a value representing the new epoch
        lastCommitted = zk.getZxid();
       	// 设置处理器链
        zk.startup();
        self.updateElectionVote(getEpoch());
        // 设置 db的 zxid
        zk.getZKDatabase().setlastProcessedZxid(zk.getZxid());
    }
```

> org.apache.zookeeper.server.ZooKeeperServer#startup

```java
public synchronized void startup() {
    if (sessionTracker == null) {
        createSessionTracker();
    }
    // 检测session 是否过期
    startSessionTracker();
    // 创建处理器链
    // 根据 角色的不同 leader  follower之间的不同 创建不同的处理器链
    setupRequestProcessors();

    registerJMX();
    // 设置当前的实例状态
    setState(State.RUNNING);
    notifyAll();
}
```

> org.apache.zookeeper.server.quorum.LeaderZooKeeperServer#setupRequestProcessors

```java
// 创建好处理器链
// 用于链式处理请求
@Override
protected void setupRequestProcessors() {
    RequestProcessor finalProcessor = new FinalRequestProcessor(this);
    RequestProcessor toBeAppliedProcessor = new Leader.ToBeAppliedRequestProcessor(
        finalProcessor, getLeader().toBeApplied);
    commitProcessor = new CommitProcessor(toBeAppliedProcessor,
                                          Long.toString(getServerId()), false,
                                          getZooKeeperServerListener());
    commitProcessor.start();
    ProposalRequestProcessor proposalProcessor = new ProposalRequestProcessor(this,
                                                                              commitProcessor);
    proposalProcessor.initialize();
    firstProcessor = new PrepRequestProcessor(this, proposalProcessor);
    ((PrepRequestProcessor)firstProcessor).start();
}
```

其实这里主要想给大家看的就是这个处理器链路的创建,  此处理器链创建好之后, follower的请求  以及 2181用户的请求都会通过这里处理器链来进行处理. 

## Follower

> org.apache.zookeeper.server.quorum.Follower#Follower

```java
    Follower(QuorumPeer self,FollowerZooKeeperServer zk) {
        this.self = self;
        this.zk=zk;
        this.fzk = zk;
    }
```

> org.apache.zookeeper.server.quorum.Follower#followLeader

```java
// 和leader进行同步
void followLeader() throws InterruptedException {
    // 选举结束时间
    self.end_fle = Time.currentElapsedTime();
    // 选举时间
    long electionTimeTaken = self.end_fle - self.start_fle;
    // 记录选举花费时间
    self.setElectionTimeTaken(electionTimeTaken);
    LOG.info("FOLLOWING - LEADER ELECTION TOOK - {}", electionTimeTaken);
    self.start_fle = 0;
    self.end_fle = 0;
    fzk.registerJMX(new FollowerBean(this, zk), self.jmxLocalPeerBean);
    try {
        // 获取leader信息
        QuorumServer leaderServer = findLeader();            
        try {
            // 连接到 leader
            connectToLeader(leaderServer.addr, leaderServer.hostname);
            // 向 leader注册自己的信息
            // 并得到 leader的 zxid
            long newEpochZxid = registerWithLeader(Leader.FOLLOWERINFO);
            long newEpoch = ZxidUtils.getEpochFromZxid(newEpochZxid);
            if (newEpoch < self.getAcceptedEpoch()) {
                LOG.error("Proposed leader epoch " + ZxidUtils.zxidToString(newEpochZxid)
                          + " is less than our accepted epoch " + ZxidUtils.zxidToString(self.getAcceptedEpoch()));
                throw new IOException("Error: Epoch of leader is lower");
            }
            // 和leader同步
            // **********************************
            syncWithLeader(newEpochZxid);                
            QuorumPacket qp = new QuorumPacket();
            //  到这里就不出去了  持续读取数据  进行处理
            while (this.isRunning()) {
                // 读取数据
                readPacket(qp);
                // 处理数据
                processPacket(qp);
            }
        } catch (Exception e) {
           ........
        }
    } finally {
        zk.unregisterJMX((Learner)this);
    }
}
```

这里看到follower的处理流程也是比较清晰的:

1. 找到leader的信息
2. 同leader进行连接
3. 发送自身信息到leader, 即注册到leader中
4. 和leader同步
5. 之后就持续等待接收数据, 处理数据.

> org.apache.zookeeper.server.quorum.Follower#processPacket

```java
    protected void processPacket(QuorumPacket qp) throws IOException{
        switch (qp.getType()) {
            // ping 数据处理
        case Leader.PING:            
            ping(qp);            
            break;
            // 事务一阶段  提议
        case Leader.PROPOSAL:            
            TxnHeader hdr = new TxnHeader();
            Record txn = SerializeUtils.deserializeTxn(qp.getData(), hdr);
            if (hdr.getZxid() != lastQueued + 1) {
                LOG.warn("Got zxid 0x"
                        + Long.toHexString(hdr.getZxid())
                        + " expected 0x"
                        + Long.toHexString(lastQueued + 1));
            }
            lastQueued = hdr.getZxid();
            // 处理此事务
            fzk.logRequest(hdr, txn);
            break;
            // 事务提交
        case Leader.COMMIT:
            // 事务提交
            fzk.commit(qp.getZxid());
            break;
        case Leader.UPTODATE:
            LOG.error("Received an UPTODATE message after Follower started");
            break;
            // 重新认证
        case Leader.REVALIDATE:
            revalidate(qp);
            break;
        case Leader.SYNC:
            // 同步
            fzk.sync();
            break;
        default:
            LOG.error("Invalid packet type: {} received by Observer", qp.getType());
        }
    }
```

事件处理同样是根据不同的消息进行特定的处理.