# ProposalRequestProcessor

`ProposalRequestProcessor`是处理器链中的第二个, 用于处理用户的请求.  从名字来看, 此处理器跟事务一致性处理相关, 这里分析会分析到 此处理器在事务一致性中 起到的作用.

```java
// 第二个处理器 是ProposalRequestProcessor, 用于事务处理相关的
ProposalRequestProcessor proposalProcessor = new ProposalRequestProcessor(this,
                                                                          commitProcessor);
proposalProcessor.initialize();
```



> org.apache.zookeeper.server.quorum.ProposalRequestProcessor#ProposalRequestProcessor

```java
public ProposalRequestProcessor(LeaderZooKeeperServer zks,
                                RequestProcessor nextProcessor) {
    this.zks = zks;
    // 下一个处理
    this.nextProcessor = nextProcessor;
    // 创建一个 ACK 处理器
    // 此会等待outstandingProposals中发布的那些proposal,等待超过半数的follower进行响应
    // 如果响应数超过半数后 会把此 propsal进行 commit
    AckRequestProcessor ackProcessor = new AckRequestProcessor(zks.getLeader());
    // 创建同步请求处理器
    syncProcessor = new SyncRequestProcessor(zks, ackProcessor);
}

// 同步请求处理器启动
public void initialize() {
    syncProcessor.start();
}
```

这里看到Porposal处理器在内部创建了SyncRequestProcessor和AckRequestProcessor处理器. 而Proposal处理器下一个处理器是CommitProcessor.

ProposalRequestProcessor处理器对请求的处理:

> org.apache.zookeeper.server.quorum.ProposalRequestProcessor#processRequest

```java
// 处理请求
public void processRequest(Request request) throws RequestProcessorException {
    // 如果请求是 同步请求, 则使用leader处理同步请求
    if(request instanceof LearnerSyncRequest){
        // leader 开始处理同步请求
        zks.getLeader().processSync((LearnerSyncRequest)request);
    } else {
        // 交给下一个处理器处理
        nextProcessor.processRequest(request);
        if (request.hdr != null) {
            try {
                // leader 事务的一阶段 即 事务提议
// 把此proposal 提议发送到其他  follower后, 会记录此 proposal到outstandingProposals, 用于后面的事务提交
                zks.getLeader().propose(request);
            } catch (XidRolloverException e) {
                throw new RequestProcessorException(e.getMessage(), e);
            }
            syncProcessor.processRequest(request);
        }
    }
}
```

这里看到请求分为三部分:

1. 是LearnerSyncRequest, 那么直接传递给leader进行同步请求的处理
2. 无论什么请求交由下一个处理器继续处理. 
3. 如果是 事务性的请求, 需要leader把此请求扩散到其他的follower中, 当超过半数的follower进行了回应, 那么就会提交此request 事务
4. 如果是事务性reqeust, 则交由 sync 处理器, 进行一些同步处理

### 1. LearnerSyncRequest  同步请求

> org.apache.zookeeper.server.quorum.Leader#processSync

```java
// 处理同步请求
synchronized public void processSync(LearnerSyncRequest r){
    if(outstandingProposals.isEmpty()){
        // 发送同步请求到 对应的 follower
        sendSync(r);
    } else {
        // 缓存请求  等待后面处理
        List<LearnerSyncRequest> l = pendingSyncs.get(lastProposed);
        if (l == null) {
            l = new ArrayList<LearnerSyncRequest>();
        }
        l.add(r);
        pendingSyncs.put(lastProposed, l);
    }
}
```

这里呢 分为两种情况:

1. 有存在的一阶段 proposal, 那么缓存此同步请求, 等待后面对proposal提交后进一步处理
2. 没有发出的一阶段, 那么直接发送 sync 同步到 follower



### 2. proposal 一阶段提交事务

> org.apache.zookeeper.server.quorum.Leader#propose

```java
// leader把事务请求 发送到 其他follower中
// 如果半数响应OK, 则提交事务
public Proposal propose(Request request) throws XidRolloverException {
    // 序列化 请求
    byte[] data = SerializeUtils.serializeRequest(request);
    proposalStats.setLastProposalSize(data.length);
    // 创建事务提议包, 并把请求放入到 包中
    QuorumPacket pp = new QuorumPacket(Leader.PROPOSAL, request.zxid, data, null);

    Proposal p = new Proposal();
    p.packet = pp;
    p.request = request;
    synchronized (this) {
        lastProposed = p.packet.getZxid();
        outstandingProposals.put(lastProposed, p);
        // 发送 包到 follower
        sendPacket(pp);
    }
    return p;
}
```

> org.apache.zookeeper.server.quorum.Leader#sendPacket

```java
// 发送 一阶段 提交到 集群中的 各个 follower
void sendPacket(QuorumPacket qp) {
    synchronized (forwardingFollowers) {
        for (LearnerHandler f : forwardingFollowers) {                
            f.queuePacket(qp);
        }
    }
}
```



### 3. sync 同步处理器同步事务请求

> org.apache.zookeeper.server.SyncRequestProcessor#processRequest

```java
// 同步处理器, 同样也是 把请求缓存下来
public void processRequest(Request request) {
    // request.addRQRec(">sync");
    queuedRequests.add(request);
}
```

> org.apache.zookeeper.server.SyncRequestProcessor#run

```java
  // 同步处理器 对请求的处理
    @Override
    public void run() {
        try {
            int logCount = 0;
            setRandRoll(r.nextInt(snapCount/2));
            while (true) {
                Request si = null;
                // 获取缓存的请求进行处理
                if (toFlush.isEmpty()) {
                    si = queuedRequests.take();
                } else {
                    si = queuedRequests.poll();
                    // 如果没有请求,则尝试 进行 log的 flush操作
                    if (si == null) {
                        // *****************************
                        // 再次flush操作中,
                        // 1. 会把log日志的输出流进行flush
                        // 2. 会处理这些proposal 的ack, 当ack超过半数时, 才会进行提交操作; 提交了的request才能进入下一步
                        flush(toFlush);
                        continue;
                    }
                }
                // 停止操作
                if (si == requestOfDeath) {
                    break;
                }
                if (si != null) {
                    // track the number of records written to the log
                    // 这里把 request 记录写入到 log日志文件中
                    // *******************
                    if (zks.getZKDatabase().append(si)) {
                        logCount++;
                        // 当日志操作次数 大于后面这个数字后, 就会滚动
                        if (logCount > (snapCount / 2 + randRoll)) {
                            setRandRoll(r.nextInt(snapCount/2));
                            // roll the log
                            // 日志滚动
                            zks.getZKDatabase().rollLog();
                            // take a snapshot
                            if (snapInProcess != null && snapInProcess.isAlive()) {
                                LOG.warn("Too busy to snap, skipping");
                            } else {
                                // 后台启动一个线程来做 一个 snapshot 快照
                                snapInProcess = new ZooKeeperThread("Snapshot Thread") {
                                        public void run() {
                                            try {
                                                zks.takeSnapshot();
                                            } catch(Exception e) {
                                                LOG.warn("Unexpected exception", e);
                                            }
                                        }
                                    };
                                snapInProcess.start();
                            }
                            logCount = 0;
                        }
                    } else if (toFlush.isEmpty()) {
                        // 这里会把 处理完的请求 交给下一个处理器 进行处理
                        if (nextProcessor != null) {
                            nextProcessor.processRequest(si);
                            if (nextProcessor instanceof Flushable) {
                                ((Flushable)nextProcessor).flush();
                            }
                        }
                        continue;
                    }
                    // 这里上面把请求处理完成后, 会添加到  toFlush,
                    toFlush.add(si);
                    // 个数太大时, 也会进行一次 flush
                    if (toFlush.size() > 1000) {
                        flush(toFlush);
                    }
                }
            }
        } catch (Throwable t) {
            handleException(this.getName(), t);
            running = false;
        }
    }
```

这里可以看到:

1. 把请求序列化后追加到log日志文件输出流中
2. 判断log日志文件是否滚动
3. 是否进行snapshot
4. 把处理完的request添加到toFlush中
5. 对toFlush中的request进行flush操作

> org.apache.zookeeper.server.SyncRequestProcessor#flush

```java
// log的 flush操作
private void flush(LinkedList<Request> toFlush)
    throws IOException, RequestProcessorException
{
    // flush为空 不操作
    if (toFlush.isEmpty())
        return;
    //  log日志文件的 flush,即把内存中的数据 flush到 磁盘中
    // 此处flush时, 不光会flush当前的log输出流, 也会对之前那些没有进行过flush的输出流 进行flush
    zks.getZKDatabase().commit();
    while (!toFlush.isEmpty()) {
        Request i = toFlush.remove();
        // 把flush中的 请求 交由下一个处理器  ACKRequestProcessor 进行处理
        if (nextProcessor != null) {
            nextProcessor.processRequest(i);
        }
    }
    if (nextProcessor != null && nextProcessor instanceof Flushable) {
        ((Flushable)nextProcessor).flush();
    }
}
```

这里可以看到主要有两点:

1. 对log的输出流进行flush
2. 把request交由下一个reqeust进行处理; 在这里的nextProcessor时AckRequestProcessor

#### 3.1 flush操作

> org.apache.zookeeper.server.ZKDatabase#commit

```java
    // log日志的 flush
    public void commit() throws IOException {
        this.snapLog.commit();
    }
```

> org.apache.zookeeper.server.persistence.FileTxnSnapLog#commit

```java
// log 事务的提交
public void commit() throws IOException {
    txnLog.commit();
}
```

> org.apache.zookeeper.server.persistence.FileTxnLog#commit

```java
// 事务提交
public synchronized void commit() throws IOException {
    if (logStream != null) {
        logStream.flush();
    }
    // 把那些等待 flush的输出流 都进行 flush操作
    for (FileOutputStream log : streamsToFlush) {
        log.flush();
        // 如果强制 flush
        if (forceSync) {
            long startSyncNS = System.nanoTime();
            // 刷新
            log.getChannel().force(false);
            // 刷新的结束时间
            long syncElapsedMS =
                TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startSyncNS);
            // 大于 flush的世间 阈值, 则警告
            if (syncElapsedMS > fsyncWarningThresholdMS) {
                if(serverStats != null) {
                    serverStats.incrementFsyncThresholdExceedCount();
                }
                LOG.warn("fsync-ing the write ahead log in "
                         + Thread.currentThread().getName()
                         + " took " + syncElapsedMS
                         + "ms which will adversely effect operation latency. "
                         + "See the ZooKeeper troubleshooting guide");
            }
        }
    }
    while (streamsToFlush.size() > 1) {
        streamsToFlush.removeFirst().close();
    }
}
```

这里可以看到具体对输出流进行flush的操作, 平时看到的 fsync超时的日志, 也是这里打印的. 



#### 3.2 AckRequestProcessor

> org.apache.zookeeper.server.quorum.AckRequestProcessor#processRequest

```java
public void processRequest(Request request) {
    QuorumPeer self = leader.self;
    // 对 request进行响应
    // 即对于事务的请求 进行提交
    if(self != null)
        leader.processAck(self.getId(), request.zxid, null);
    else
        LOG.error("Null QuorumPeer");
}

```

> org.apache.zookeeper.server.quorum.Leader#processAck

```java
    // leader处理事务的ack
    synchronized public void processAck(long sid, long zxid, SocketAddress followerAddr) {
        // zxid最大  回滚的情况
        if ((zxid & 0xffffffffL) == 0) {
            return;
        }
        // 如果没有输出的 一阶段事务, 则不需要处理ack
        if (outstandingProposals.size() == 0) {
            return;
        }
        // 已有事务大于 当前的事务, 则不处理
        if (lastCommitted >= zxid) {
            // The proposal has already been committed
            return;
        }
        // 获取到 要等待 ack的 一阶段事务
        Proposal p = outstandingProposals.get(zxid);
        if (p == null) {
            return;
        }
        // 记录自己的sid
        p.ackSet.add(sid);
        // 如果此 Porposal响应的sid数超过半数
        if (self.getQuorumVerifier().containsQuorum(p.ackSet)){  
            // 如果响应大于 半数, 则说明此 proposal 生效
            // 则移除此 porposal
            outstandingProposals.remove(zxid);
            if (p.request != null) {
                // 如果此 proposal 有request,则添加到 toBeApplied队列中
                toBeApplied.add(p);
            }
            // 超过半数响应则 提交此 zxid
            // 发送 COMMIT 包到各个 follower, 告知此 事务 可以提交了
            commit(zxid);
            // 通知集群中 observer节点
            inform(p);
            // 调用 commitProcessor 进行此 reqeust的提交
            zk.commitProcessor.commit(p.request);
            // 对于那些 缓存的 同步请求 ,进行处理
            if(pendingSyncs.containsKey(zxid)){
                for(LearnerSyncRequest r: pendingSyncs.remove(zxid)) {
                    // 把此请求发送到对应的follower中
                    // 即同步此请求到 follower中
                    sendSync(r);
                }
            }
        }
    }
```

这里主要是针对发出的proposal即 事务一阶段提交的处理, 当此proposal的响应的ack数量大于半数时, 会提交此 proposal, 并通知observer此提交.

> org.apache.zookeeper.server.quorum.Leader#commit

```java
// 事务提交
public void commit(long zxid) {
    synchronized(this){
        lastCommitted = zxid;
    }
    QuorumPacket qp = new QuorumPacket(Leader.COMMIT, zxid, null, null);
    sendPacket(qp);
}
```

> org.apache.zookeeper.server.quorum.Leader#inform

```java
// 通知 observer 事务提交
public void inform(Proposal proposal) {   
    QuorumPacket qp = new QuorumPacket(Leader.INFORM, proposal.request.zxid, 
                                       proposal.packet.getData(), null);
    sendObserverPacket(qp);
}
```



> org.apache.zookeeper.server.quorum.CommitProcessor#commit

```java
// 请求 commit
synchronized public void commit(Request request) {
    if (!finished) {
        if (request == null) {
            LOG.warn("Committed a null!",
                     new Exception("committing a null! "));
            return;
        }
        if (LOG.isDebugEnabled()) {
            LOG.debug("Committing request:: " + request);
        }
        // 记录committed request
        // 即 保存其那些 提交的request
        committedRequests.add(request);
        notifyAll();
    }
}
```

发送commit提交packet到 follower, 发送inform通知packet到 observer. 之后把此request提交到 CommitProcessor处理器中.  这里对CommitProcessor先不展开, 后面会有分析.

可见ProposalRequestProcessor处理器主要就是把事务性的request分两阶段提交:

1. Proposal分发到 follower
2. 当此proposal响应 ack数量大于半数时, 进行提交操作





