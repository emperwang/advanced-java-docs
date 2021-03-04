# ToBeAppliedRequestProcessor

> org.apache.zookeeper.server.quorum.Leader.ToBeAppliedRequestProcessor#ToBeAppliedRequestProcessor

```java
ToBeAppliedRequestProcessor(RequestProcessor next,
                            ConcurrentLinkedQueue<Proposal> toBeApplied) {
    if (!(next instanceof FinalRequestProcessor)) {
        throw new RuntimeException(ToBeAppliedRequestProcessor.class
                                   .getName()
                                   + " must be connected to "
                                   + FinalRequestProcessor.class.getName()
                                   + " not "
                                   + next.getClass().getName());
    }
    this.toBeApplied = toBeApplied;
    this.next = next;
}
```

> org.apache.zookeeper.server.quorum.Leader.ToBeAppliedRequestProcessor#processRequest

```java
// 处理请求
public void processRequest(Request request) throws RequestProcessorException {
    // request.addRQRec(">tobe");
    next.processRequest(request);
    Proposal p = toBeApplied.peek();
    if (p != null && p.request != null
        && p.request.zxid == request.zxid) {
        toBeApplied.remove();
    }
}
```

这里对于请求会传递给下一个处理器, 之后会对 toBeApplied队列进行一些处理.

 















