# FinalRequestProcessor

`FinalRequestProcessor`处理器是处理器链的最后一个, 此会对具体的请求进行处理, 如: 创建一个节点等.  并设置响应的响应数据.

```java
public FinalRequestProcessor(ZooKeeperServer zks) {
    this.zks = zks;
}
```

> org.apache.zookeeper.server.FinalRequestProcessor#processRequest

```java
// 最终的请求处理
public void processRequest(Request request) {
    ProcessTxnResult rc = null;
    synchronized (zks.outstandingChanges) {
        while (!zks.outstandingChanges.isEmpty()
               && zks.outstandingChanges.get(0).zxid <= request.zxid) {
            ChangeRecord cr = zks.outstandingChanges.remove(0);
            if (cr.zxid < request.zxid) {
                LOG.warn("Zxid outstanding "
                         + cr.zxid
                         + " is less than current " + request.zxid);
            }
            if (zks.outstandingChangesForPath.get(cr.path) == cr) {
                zks.outstandingChangesForPath.remove(cr.path);
            }
        }
        if (request.hdr != null) {
            // 事务header
            TxnHeader hdr = request.hdr;
            // 此事务具体对应的  request
            Record txn = request.txn;
            // 处理事务
            // *************
            rc = zks.processTxn(hdr, txn);
        }
        // do not add non quorum packets to the queue.
        if (Request.isQuorum(request.type)) {
            // 记录此 request对应的proposal 事务一阶段
            zks.getZKDatabase().addCommittedProposal(request);
        }
    }

    if (request.hdr != null && request.hdr.getType() == OpCode.closeSession) {
        ServerCnxnFactory scxn = zks.getServerCnxnFactory();
        if (scxn != null && request.cnxn == null) {
            // 直接响应结果
            scxn.closeSession(request.sessionId);
            return;
        }
    }
    ServerCnxn cnxn = request.cnxn;
	// 下面会准备响应的数据
    String lastOp = "NA";
    zks.decInProcess();
    Code err = Code.OK;
    Record rsp = null;
    boolean closeSession = false;
    try {
        switch (request.type) {
            case OpCode.ping: {
                zks.serverStats().updateLatency(request.createTime);
                lastOp = "PING";
                cnxn.updateStatsForResponse(request.cxid, request.zxid, lastOp,
                                            request.createTime, Time.currentElapsedTime());
                // 发送响应
                cnxn.sendResponse(new ReplyHeader(-2,
 zks.getZKDatabase().getDataTreeLastProcessedZxid(), 0), null, "response");
                return;
            }
            case OpCode.createSession: {
                zks.serverStats().updateLatency(request.createTime);

                lastOp = "SESS";
                cnxn.updateStatsForResponse(request.cxid, request.zxid, lastOp,
                                            request.createTime, Time.currentElapsedTime());
                // 这里完成后  就会进行数据的响应
                zks.finishSessionInit(request.cnxn, true);
                return;
            }
            case OpCode.multi: {
                lastOp = "MULT";

                break;
            }
            case OpCode.create: {
                lastOp = "CREA";
                rsp = new CreateResponse(rc.path);
                err = Code.get(rc.err);
                break;
            }
            case OpCode.delete: {
                lastOp = "DELE";
                break;
            }
            case OpCode.setData: {
                lastOp = "SETD";
                break;
            }
            case OpCode.setACL: {
                lastOp = "SETA";
                break;
            }
            case OpCode.closeSession: {
                lastOp = "CLOS";
                break;
            }
            case OpCode.sync: {
                lastOp = "SYNC";
                break;
            }
            case OpCode.check: {
                lastOp = "CHEC";
                break;
            }
            case OpCode.exists: {
                lastOp = "EXIS";
                break;
            }
            case OpCode.getData: {
                lastOp = "GETD";
                break;
            }
            case OpCode.setWatches: {
                break;
            }
            case OpCode.getACL: {
                lastOp = "GETA";
                break;
            }
            case OpCode.getChildren: {
                break;
            }
            case OpCode.getChildren2: {
                break;
            }
        }
    } 
    } catch (Exception e) {
        err = Code.MARSHALLINGERROR;
    }

    long lastZxid = zks.getZKDatabase().getDataTreeLastProcessedZxid();
    // 响应 header
    ReplyHeader hdr =
        new ReplyHeader(request.cxid, lastZxid, err.intValue());

    zks.serverStats().updateLatency(request.createTime);
    cnxn.updateStatsForResponse(request.cxid, lastZxid, lastOp,
                                request.createTime, Time.currentElapsedTime());
    try {
        // 发送响应数据
        cnxn.sendResponse(hdr, rsp, "response");
        if (closeSession) {
            cnxn.sendCloseSession();
        }
    }
}
```

这里代码看似比较多, 不过主要做了两个主要的工作:

1. 对事务性的 请求进行处理
2. 准备响应的数据

> org.apache.zookeeper.server.ZooKeeperServer#processTxn

```java
// 对事务性请求的处理
public ProcessTxnResult processTxn(TxnHeader hdr, Record txn) {
    ProcessTxnResult rc;
    // 操作码
    int opCode = hdr.getType();
    // sessionId
    long sessionId = hdr.getClientId();
    // 处理事务
    //*******************
    // 如: create操作, 在内存db中创建对应的 dataNode节点,并保存起来
    rc = getZKDatabase().processTxn(hdr, txn);
    // .......
    return rc;
}
```

> org.apache.zookeeper.server.ZKDatabase#processTxn

```java
// 处理事物
public ProcessTxnResult processTxn(TxnHeader hdr, Record txn) {
    return dataTree.processTxn(hdr, txn);
}
```

> org.apache.zookeeper.server.DataTree#processTxn

```java
// 事务处理
public ProcessTxnResult processTxn(TxnHeader header, Record txn)
{
    // 记录事务处理结果
    ProcessTxnResult rc = new ProcessTxnResult();
    try {
        rc.clientId = header.getClientId();
        rc.cxid = header.getCxid();
        rc.zxid = header.getZxid();
        rc.type = header.getType();
        rc.err = 0;
        rc.multiResult = null;
        // 根据 不同的类型 来进行对应的操作
        // 即应用事务,也就是把reqeust中对应的操作 在内存db中 操作一下,如: 创建节点
        switch (header.getType()) {
            case OpCode.create:
                // 转换为  CreateTxn 创建事务
                CreateTxn createTxn = (CreateTxn) txn;
                // 创建的path
                rc.path = createTxn.getPath();
                // 创建节点
                createNode(
                    createTxn.getPath(),
                    createTxn.getData(),
                    createTxn.getAcl(),
                    createTxn.getEphemeral() ? header.getClientId() : 0,
                    createTxn.getParentCVersion(),
                    header.getZxid(), header.getTime());
                break;
            case OpCode.delete:
                DeleteTxn deleteTxn = (DeleteTxn) txn;
                rc.path = deleteTxn.getPath();
                // 删除节点的操作
                deleteNode(deleteTxn.getPath(), header.getZxid());
                break;
            case OpCode.setData:
                break;
            case OpCode.setACL:
                break;
            case OpCode.closeSession:
                // 关闭session操作
                killSession(header.getClientId(), header.getZxid());
                break;
            case OpCode.error:
                break;
            case OpCode.check:
                break;
            case OpCode.multi:
                break;
        }
    }
    // 先应用 事务, 再 更新 事务ID
    if (rc.zxid > lastProcessedZxid) {
        // 更新事务 zxid
        lastProcessedZxid = rc.zxid;
    }
    if (header.getType() == OpCode.create &&
        rc.err == Code.NODEEXISTS.intValue()) {
        LOG.debug("Adjusting parent cversion for Txn: " + header.getType() +
                  " path:" + rc.path + " err: " + rc.err);
        int lastSlash = rc.path.lastIndexOf('/');
        String parentName = rc.path.substring(0, lastSlash);
        CreateTxn cTxn = (CreateTxn)txn;
        try {
            setCversionPzxid(parentName, cTxn.getParentCVersion(),
                             header.getZxid());
        } catch (KeeperException.NoNodeException e) {
            LOG.error("Failed to set parent cversion for: " +
                      parentName, e);
            rc.err = e.code().intValue();
        }
    } else if (rc.err != Code.OK.intValue()) {
        LOG.debug("Ignoring processTxn failure hdr: " + header.getType() +
                  " : error: " + rc.err);
    }
    return rc;
}
```

这里对事务的处理: 简单说就是应用事务. 

简单看一下对创建节点的操作:

> org.apache.zookeeper.server.DataTree#createNode

```java
// 存储所有的节点信心
// key为 path路径,  value 为: 节点 信息
// 表示节点的 dataNode 是可序列化的
private final ConcurrentHashMap<String, DataNode> nodes =
    new ConcurrentHashMap<String, DataNode>();

// 创建 node节点
public String createNode(String path, byte data[], List<ACL> acl,
                         long ephemeralOwner, int parentCVersion, long zxid, long time)
    throws KeeperException.NoNodeException,
KeeperException.NodeExistsException {
    int lastSlash = path.lastIndexOf('/');
    // 得到要创建路径的 父亲 节点路径
    String parentName = path.substring(0, lastSlash);
    // 得到 具体要创建的 路径
    String childName = path.substring(lastSlash + 1);
    // 记录 此节点的信息, 可以序列化
    StatPersisted stat = new StatPersisted();
    // 创建时间
    stat.setCtime(time);
    // 修改时间
    stat.setMtime(time);
    // zxid
    stat.setCzxid(zxid);
    // 修改时的 zxid
    stat.setMzxid(zxid);
    stat.setPzxid(zxid);
    stat.setVersion(0);
    stat.setAversion(0);
    // 设置拥有者, 对应的sessionId
    stat.setEphemeralOwner(ephemeralOwner);
    // 得到父节点
    DataNode parent = nodes.get(parentName);
    if (parent == null) {
        throw new KeeperException.NoNodeException();
    }
    synchronized (parent) {
        // 得到 父节点的所有子节点
        Set<String> children = parent.getChildren();
        // 如果已经有此节点, 则报错
        if (children.contains(childName)) {
            throw new KeeperException.NodeExistsException();
        }

        if (parentCVersion == -1) {
            parentCVersion = parent.stat.getCversion();
            parentCVersion++;
        }
        // cVersion, 记录修改的次数
        parent.stat.setCversion(parentCVersion);
        parent.stat.setPzxid(zxid);
        Long longval = aclCache.convertAcls(acl);
        // 创建子节点
        DataNode child = new DataNode(parent, data, longval, stat);
        // 把子节点信息 记录到 父节点中
        parent.addChild(childName);
        // 记录此新 创建的 节点
        nodes.put(path, child);
        if (ephemeralOwner != 0) {
            // 获取此 sessionId 创建的 节点
            HashSet<String> list = ephemerals.get(ephemeralOwner);
            if (list == null) {
                list = new HashSet<String>();
                ephemerals.put(ephemeralOwner, list);
            }
            synchronized (list) {
                // 添加到此sessionId 对应的容器
                list.add(path);
            }
        }
    }
   
    // 监听器 触发
    dataWatches.triggerWatch(path, Event.EventType.NodeCreated);
    // 监听器触发
    childWatches.triggerWatch(parentName.equals("") ? "/" : parentName,
                              Event.EventType.NodeChildrenChanged);
    return path;
}
```

这里看到所谓的内存数据库, 即一个map, 存储了所有的节点信息, 创建节点 即: 创建一个node 节点存储到map中, 并更新此节点对应的父节点的信息.



















