# CountDownLatch 分析

CountDownLatch也是基于AQS实现的一种共享锁机制。今天来学习一下其工作原理

其实现是由内部类Sync继承AQS实现的.

## CountDownLatch的创建

```java
    // 创建一个CountDownLatch时的初始值就是为state变量设置一个初始值
	public CountDownLatch(int count) {
        if (count < 0) throw new IllegalArgumentException("count < 0");
        this.sync = new Sync(count);
    }

    Sync(int count) {
        setState(count);
    }

    protected final void setState(int newState) {
        state = newState;
    }
```



## countDown函数做了什么？

```java
    public void countDown() {
        sync.releaseShared(1);
    }

    public final boolean releaseShared(int arg) {
        if (tryReleaseShared(arg)) {
            doReleaseShared();
            return true;
        }
        return false;
    }

    protected boolean tryReleaseShared(int releases) {
        // countDown就是把state值减1
        for (;;) {
            int c = getState();
            if (c == 0)
                return false;
            int nextc = c-1;
            if (compareAndSetState(c, nextc))
                return nextc == 0;
        }
    }
	// 如果state值大于0 ,则执行此函数
    private void doReleaseShared() {
        for (;;) {
            Node h = head;
            if (h != null && h != tail) {
                int ws = h.waitStatus;
                if (ws == Node.SIGNAL) {
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                        continue;            // loop to recheck cases
                    unparkSuccessor(h);
                }
                else if (ws == 0 &&
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                    continue;                // loop on failed CAS
            }
            if (h == head)                   // loop if head changed
                break;
        }
    }
```



## await函数做了什么?

```java
    // 获取锁
	public void await() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
    }

    public final void acquireSharedInterruptibly(int arg)
            throws InterruptedException {
        if (Thread.interrupted())
            throw new InterruptedException();
        // 如果state不为0,则获取不到锁
        // 如果state为0, 则执行doAcquireSharedInterruptibly,田添加shared节点到同步队列
        // 死循环获取锁,或阻塞线程
        if (tryAcquireShared(arg) < 0)
            doAcquireSharedInterruptibly(arg);
    }
	// 如果state==0返回1,否则返回-1
    protected int tryAcquireShared(int acquires) {
        return (getState() == 0) ? 1 : -1;
    }
	// 如果state=0, 则添加该shared节点到同步队列,并死循环获取锁
	// 如果过去到了锁,则唤醒同步队列中的一个节点
    private void doAcquireSharedInterruptibly(int arg)
        throws InterruptedException {
        // 添加节点到同步队列
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            for (;;) { // 死循环获取锁
                final Node p = node.predecessor();
                if (p == head) {
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        // 获取到了锁,则唤醒同步队列中的一个节点
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        failed = false;
                        return;
                    }
                }
                // 如果当前线程可以阻塞,则阻塞线程并检查是否发生了中断
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    // 如果发生了中断,则抛出中断异常
                    throw new InterruptedException();
            }
        } finally {
            if (failed) // 如果获取锁失败,则把当前节点从同步队列中删除,并设置状态为取消状态
                cancelAcquire(node);
        }
    }
```

由此可见，当使用countDownLatch进行多线程同步运行时，运行情况如下：

1. 如果主线程调用了await函数，因为获取不到锁，主线程把自己添加到同步队列中，并死循环获取锁
2. 各个线程调用countDown函数，把state值减1
3. 如果state值为0，主线程获取到锁，唤醒主线程，继续执行。