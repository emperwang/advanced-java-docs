# CommitProcessor

此处理器主要是针对那些提交了的request进行进一步的处理.

```java
public CommitProcessor(RequestProcessor nextProcessor, String id,
                       boolean matchSyncs, ZooKeeperServerListener listener) {
    super("CommitProcessor:" + id, listener);
    this.nextProcessor = nextProcessor;
    this.matchSyncs = matchSyncs;
}
```

> org.apache.zookeeper.server.quorum.CommitProcessor#processRequest

```java
// 处理请求
synchronized public void processRequest(Request request) {
    if (!finished) {
        // 同样是把请求缓存起来
        queuedRequests.add(request);
        notifyAll();
    }
}
```

这里对reqeust的处理, 同样是缓存起来. 

> org.apache.zookeeper.server.quorum.CommitProcessor#run

```java
// 真正的处理 函数
@Override
public void run() {
    try {
        Request nextPending = null;            
        while (!finished) {
            // 如果有等待处理的请求
            // 则把等待处理的请求 给到下一个处理器进行处理
            // toProcess中的request是 处理过的请求
            // 简单说: 如果request是事务类型的, 那么当request添加到 toProcess后, 此事务已经是提交状态的
            int len = toProcess.size();
            for (int i = 0; i < len; i++) {
                nextProcessor.processRequest(toProcess.get(i));
            }
            toProcess.clear();
            synchronized (this) {
                if ((queuedRequests.size() == 0 || nextPending != null)
                    && committedRequests.size() == 0) {
                    // 如果没有 请求的话, 则等待
                    wait();
                    continue;
                }
                if ((queuedRequests.size() == 0 || nextPending != null)
                    && committedRequests.size() > 0) {
                    Request r = committedRequests.remove();
                    if (nextPending != null
                        && nextPending.sessionId == r.sessionId
                        && nextPending.cxid == r.cxid) {
                        // we want to send our version of the request.
                        // the pointer to the connection in the request
                        nextPending.hdr = r.hdr;
                        nextPending.txn = r.txn;
                        nextPending.zxid = r.zxid;
                        // 这里把 等待处理的 request 缓存到  toProcess中
                        toProcess.add(nextPending);
                        nextPending = null;
                    } else {
                 // 把committedRequests 提交的事务, 添加到 toProcess中, 准备交由下一个处理器处理
                        toProcess.add(r);
                    }
                }
            }
            // 这里相当于 nextPending 表示下一个等待处理的请求
            // 此请求会和 committedRequests中的请求 配对, 配对成功后才会进行下一步处理
            if (nextPending != null) {
                continue;
            }
            synchronized (this) {
                // 获取队列中的请求, 进行处理
                while (nextPending == null && queuedRequests.size() > 0) {
                    Request request = queuedRequests.remove();
                    // 这里可以看到 对于事务型的请求, 会缓存,等待其commit后才会处理
                    switch (request.type) {
                        case OpCode.create:
                        case OpCode.delete:
                        case OpCode.setData:
                        case OpCode.multi:
                        case OpCode.setACL:
                        case OpCode.createSession:
                        case OpCode.closeSession:
                            nextPending = request;
                            break;
                        case OpCode.sync:
                            if (matchSyncs) {
                                nextPending = request;
                            } else {
                                // 同步的请求 直接处理
                                toProcess.add(request);
                            }
                            break;
                        default:
                            toProcess.add(request);
                    }
                }
            }
        }
    } 
}
```

```java
// 请求 commit
synchronized public void commit(Request request) {
    if (!finished) {
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

可以看到committedRequests中的请求是提交后的请求, 而run方法中, 只有当请求提交后, 才会添加到toProcess中;  toProcess队列中的请求是交由下一个处理器处理的请求.

换句话说, 只有当一个请求被提交后, 才会交由下一个处理器处理, 否则只是缓存在 CommitProcessor的队列中.





































