# AQS-共享锁(semaphore)

今天以semaphore为入口，学习关于AQS共享锁的原理。

废话不多说，直接看代码。

## acquire获取锁

### 非同步实现

```java
// 获取共享锁 
public void acquire() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
    }

public final void acquireSharedInterruptibly(int arg)
    throws InterruptedException {
    // 如果当前线程发生了中断，就抛出中断异常
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0) // 如果state剩下的值小于0
        doAcquireSharedInterruptibly(arg);
}

protected int tryAcquireShared(int acquires) {
            return nonfairTryAcquireShared(acquires);
        }
// 非公平获取共享锁
 final int nonfairTryAcquireShared(int acquires) {
            for (;;) {
                // 获取state值
                int available = getState();
                // 获得剩下的state值
                int remaining = available - acquires;
                if (remaining < 0 ||
                    compareAndSetState(available, remaining))
                    // 如果剩下的值小于0 或者 CAS设置state状态成功， 就返回state剩下的值
                    return remaining;
            }
        }

private void doAcquireSharedInterruptibly(int arg)
        throws InterruptedException {
    	// 添加一个节点到同步队列中
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            for (;;) { // 死循环获取锁
                // 获取前节点
                final Node p = node.predecessor();
                if (p == head) {
                    // 如果前节点为head节点，就再次获取共享锁
                    int r = tryAcquireShared(arg);
                    // 此时如果共享锁值大于0
                    if (r >= 0) {
                        // 如果head节点为singal，唤醒同步队列中的一个node节点
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        failed = false;
                        return;
                    }
                }
                // 如果当前线程可以阻塞 并且中断过
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    // 则抛出中断异常
                    throw new InterruptedException();
            }
        } finally {
            if (failed) // 如果获取锁失败，则把当前node设置为取消状态
                cancelAcquire(node);
        }
    }

private void setHeadAndPropagate(Node node, int propagate) {
    	// 记录原来head节点值
    	Node h = head;
    	// 设置当前节点为head节点
        setHead(node);
		// 如果 state大于0 || 原head节点为null || 原head节点状态小于0 || （新head节点为null || 新head节点状态小于0）
        if (propagate > 0 || h == null || h.waitStatus < 0 ||
            (h = head) == null || h.waitStatus < 0) {
            // 获取head的下一个节点
            Node s = node.next;
            if (s == null || s.isShared())
                // 如果下一个节点为null 或者是共享节点  释放共享锁的哪个线程
                doReleaseShared();
        }
    }

 private void doReleaseShared() {
        for (;;) {// 死循环释放阻塞的线程
            Node h = head;
            if (h != null && h != tail) { // 如果头节点不为null，并且不是tail节点
                int ws = h.waitStatus;
                if (ws == Node.SIGNAL) {// 如果head等待状态为singal
                    // 循环设置head的状态为0
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                        continue;            // loop to recheck cases
                    // 释放等待队列中的一个线程
                    unparkSuccessor(h);
                }
                // 如果等待状态不是singal
                else if (ws == 0 &&  // 如果head状态为0 则 设置状态为 propagate
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                    continue;                // loop on failed CAS
            }
            if (h == head)                   // loop if head changed
                break;
        }
    }

 private void unparkSuccessor(Node node) {
        int ws = node.waitStatus;
        if (ws < 0)
            // 如果head节点状态小于0，则设置其等待状态为0
            compareAndSetWaitStatus(node, ws, 0);
	    // 获取下一个要唤醒的节点
        Node s = node.next;
     	// 如果下一个节点为null  或 是取消状态， 则tail节点往回搜索，查找一个不为null且等待状态<=0的节点，唤醒其线程
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);
    }
```



### 同步实现

```java
    public void acquire() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
    }

    public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
        if (Thread.interrupted())
            throw new InterruptedException();
        if (tryAcquireShared(arg) < 0)
            doAcquireSharedInterruptibly(arg);
    }
	// 同步获取共享锁实现
    protected int tryAcquireShared(int acquires) {
        for (;;) {// 死循环获取锁
            // 如果同步队列有其他的节点， 则直接返回-1
            if (hasQueuedPredecessors())
                return -1;
            int available = getState();
            int remaining = available - acquires;
            // state剩下值小于0  或 设置state状态成功
            // 则返回remaining值
            if (remaining < 0 ||
                compareAndSetState(available, remaining))
                return remaining;
        }
    }

    // 判断同步队列中是否有其他的等待节点
    public final boolean hasQueuedPredecessors() {
        Node t = tail; // Read fields in reverse initialization order
        Node h = head;
        Node s;
        return h != t &&
            ((s = h.next) == null || s.thread != Thread.currentThread());
    }
	// 同非同步实现一样
    private void doAcquireSharedInterruptibly(int arg)
        throws InterruptedException {
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            for (;;) {
                final Node p = node.predecessor();
                if (p == head) {
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        failed = false;
                        return;
                    }
                }
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    throw new InterruptedException();
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
```



## acquireUninterruptibly获取锁

### 非同步实现

```java
    public void acquireUninterruptibly() {
        sync.acquireShared(1);
    }

    public final void acquireShared(int arg) {
        if (tryAcquireShared(arg) < 0)
            // 如果state-acquires后的值小于0
            // 则死循环获取锁
            doAcquireShared(arg);
    }

    protected int tryAcquireShared(int acquires) {
        return nonfairTryAcquireShared(acquires);
    }
	// 非同步获取锁
    final int nonfairTryAcquireShared(int acquires) {
        for (;;) {
            int available = getState();
            int remaining = available - acquires;
            if (remaining < 0 ||
                compareAndSetState(available, remaining))
                return remaining;
        }
    }

    private void doAcquireShared(int arg) {
        // 添加一个节点到同步队列中
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                // 获取前一个节点
                final Node p = node.predecessor();
                if (p == head) {
                    // 如果前节点为head节点，则再次获取锁
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        // 如果state-acquires值大于0
                        // 则唤醒同步队列中的一个node节点
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        // 如果中断过，则中断执行中断一次
                        if (interrupted)
                            selfInterrupt();
                        failed = false;
                        return;
                    }
                }
                // 如果当前线程可以阻塞，并发生过中断，则设置interrupted值为true
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                // 如果获取锁失败，则设置node节点为取消状态，并从同步队列中删除node节点
                cancelAcquire(node);
        }
    }
```





### 同步实现

```java
    public void acquireUninterruptibly() {
        sync.acquireShared(1);
    }

    public final void acquireShared(int arg) {
        if (tryAcquireShared(arg) < 0)
            // 如果state-acquires值小于0
            // 添加节点到同步队列并死循环获取锁，如果可以阻塞，也会把当前线程阻塞
            doAcquireShared(arg);
    }
	// 同步获取锁
    protected int tryAcquireShared(int acquires) {
        for (;;) {
            if (hasQueuedPredecessors())
                return -1;
            int available = getState();
            int remaining = available - acquires;
            if (remaining < 0 ||
                compareAndSetState(available, remaining))
                return remaining;
        }
    }

    private void doAcquireShared(int arg) {
        // 添加一个节点到同步队列中
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                // 获取前一个节点
                final Node p = node.predecessor();
                if (p == head) {
                    // 如果前节点为head节点，则再次获取锁
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        // 如果state-acquires值大于0
                        // 则唤醒同步队列中的一个node节点
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        // 如果中断过，则中断执行中断一次
                        if (interrupted)
                            selfInterrupt();
                        failed = false;
                        return;
                    }
                }
                // 如果当前线程可以阻塞，并发生过中断，则设置interrupted值为true
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                // 如果获取锁失败，则设置node节点为取消状态，并从同步队列中删除node节点
                cancelAcquire(node);
        }
    }
```



## tryAcquire获取锁

### 非同步实现

```java
    // 不阻塞，成功返回true，失败返回false
	public boolean tryAcquire() {
        return sync.nonfairTryAcquireShared(1) >= 0;
    }
    
	// 非公平获取锁
	final int nonfairTryAcquireShared(int acquires) {
        for (;;) {
            int available = getState();
            int remaining = available - acquires;
            if (remaining < 0 ||
                compareAndSetState(available, remaining))
                return remaining;
        }
    }

```

## tryAcquire(long timeout, TimeUnit unit)获取锁

### 非同步实现

```java
    // 规定时间内获取锁，规定时间内没有获取到就返回false
	public boolean tryAcquire(long timeout, TimeUnit unit)
        throws InterruptedException {
        return sync.tryAcquireSharedNanos(1, unit.toNanos(timeout));
    }

    public final boolean tryAcquireSharedNanos(int arg, long nanosTimeout)
            throws InterruptedException {
        // 线程中断过就抛出中断异常
        if (Thread.interrupted())
            throw new InterruptedException();
        // 获取锁成功则返回true 或者 规定时间获取到锁也返回true
        return tryAcquireShared(arg) >= 0 ||
            doAcquireSharedNanos(arg, nanosTimeout);
    }

    protected int tryAcquireShared(int acquires) {
        return nonfairTryAcquireShared(acquires);
    }
	// 非公平共享锁获取
    final int nonfairTryAcquireShared(int acquires) {
        for (;;) {
            int available = getState();
            int remaining = available - acquires;
            if (remaining < 0 ||
                compareAndSetState(available, remaining))
                return remaining;
        }
    }

    private boolean doAcquireSharedNanos(int arg, long nanosTimeout)
            throws InterruptedException {
        // 健康性检查
        if (nanosTimeout <= 0L)
            return false;
        final long deadline = System.nanoTime() + nanosTimeout;
        // 添加节点到同步队列中
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            for (;;) { // 死循环获取锁
                // 获取前节点
                final Node p = node.predecessor();
                if (p == head) {
                    // 如果前节点为head 则再次获取锁
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {// state-acquires大于0
                        // 则唤醒同步队列中的一个
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC
                        failed = false;
                        return true;
                    }
                }
                nanosTimeout = deadline - System.nanoTime();
                // 如果时间到了，还没有获取到锁，则返回false
                if (nanosTimeout <= 0L)
                    return false;
                // 如果允许阻塞，并且自旋时间大于阈值
                if (shouldParkAfterFailedAcquire(p, node) &&
                    nanosTimeout > spinForTimeoutThreshold)
                    // 则阻塞线程
                    LockSupport.parkNanos(this, nanosTimeout);
                // 如果线程中断过，则抛出中断异常
                if (Thread.interrupted())
                    throw new InterruptedException();
            }
        } finally {
            if (failed)// 如果没有获取到锁 ，则把node节点设置为取消，并从同步队列中去除
                cancelAcquire(node);
        }
    }
```



### 同步实现

```java
    // 规定时间内获取锁，规定时间内没有获取到就返回false
	public boolean tryAcquire(long timeout, TimeUnit unit)
        throws InterruptedException {
        return sync.tryAcquireSharedNanos(1, unit.toNanos(timeout));
    }

    public final boolean tryAcquireSharedNanos(int arg, long nanosTimeout)
            throws InterruptedException {
        // 线程中断过就抛出中断异常
        if (Thread.interrupted())
            throw new InterruptedException();
        // 获取锁成功则返回true 或者 规定时间获取到锁也返回true
        return tryAcquireShared(arg) >= 0 ||
            doAcquireSharedNanos(arg, nanosTimeout);
    }
	// 公平获取锁   ， 只有此函数不一样，其他函数和非公平获取实现一样的
	protected int tryAcquireShared(int acquires) {
            for (;;) {
                if (hasQueuedPredecessors())
                    return -1;
                int available = getState();
                int remaining = available - acquires;
                if (remaining < 0 ||
                    compareAndSetState(available, remaining))
                    return remaining;
            }
        }
```



## 锁的释放

在semaphore中释放锁的非公平和公平实现是一样的。

 ```java
    public void release() {
        sync.releaseShared(1);
    }
	
    public final boolean releaseShared(int arg) {
        if (tryReleaseShared(arg)) {// 设置state值成功
            // 
            doReleaseShared();
            return true;
        }
        return false;
    }
	// 释放锁
    protected final boolean tryReleaseShared(int releases) {
        for (;;) {// 死循环释放锁
            int current = getState();
            int next = current + releases;
            if (next < current) // overflow
                throw new Error("Maximum permit count exceeded");
            // 自旋设置state的值
            if (compareAndSetState(current, next))
                return true;
        }
    }

    private void doReleaseShared() {
        /*
             * Ensure that a release propagates, even if there are other
             * in-progress acquires/releases.  This proceeds in the usual
             * way of trying to unparkSuccessor of head if it needs
             * signal. But if it does not, status is set to PROPAGATE to
             * ensure that upon release, propagation continues.
             * Additionally, we must loop in case a new node is added
             * while we are doing this. Also, unlike other uses of
             * unparkSuccessor, we need to know if CAS to reset status
             * fails, if so rechecking.
             */
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

