# AQS之独占锁

java中synchronized关键字和1.5并发包之后的lock锁，都是并发下常用到同步机制。synchronized关键字属于jvm层的锁，需要查看jvm源码。不过今天来分析一下java层实现的锁机制。

并发包中ReentrantLock是基于AQS的独占锁，semaphore和CountDownLatch等是基于AQS的共享锁实现，当然了还有条件锁Condition，组合锁ReadWriteLock，今天就以ReentrantLock的非公平锁为切入点分析一下AQS的独占锁。ReentrantLock有公平锁和非公平锁两种实现，默认是使用非公平锁。

先看一下获取锁有几种方式

## 创建锁

```java
	// 传入参数为true是，创建公平锁，false为非公平锁
	public ReentrantLock(boolean fair) {
        sync = fair ? new FairSync() : new NonfairSync();
    }
    // 默认创建非公平锁
	public ReentrantLock() {
        sync = new NonfairSync();
    }
```

ReenTrantLock内部有一个静态抽象类Sync，继承了AQS，实现了非公平抢占所，释放锁等函数；以及Sync的实现类NonfairSync和FairSync，分别实现了非公平锁和公平锁的获取和释放。ReentrantLock也是通过这三个内部类类实现的锁机制.

## lock获取锁的方式

### 非公平锁实现

   ```java
   // 调用此函数进行锁的获取
   public void lock() {
       sync.lock();
   }
   	
   // lock函数的实现如下:
   final void lock() {
       // 把state变量设置为1,表示为占用状态, 如果设置成功则把当前线程设置为占用线程
       if (compareAndSetState(0, 1))
           setExclusiveOwnerThread(Thread.currentThread());
       else
       // 如果没有设置成功,则添加到同步队列
           acquire(1);
   }
   
   // AQS的方法 
   public final void acquire(int arg) {
       if (!tryAcquire(arg) &&
           acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
           // 如果获取锁失败, 并且检查
           selfInterrupt();
   }
   // ReentrantLock 的重写
   protected final boolean tryAcquire(int acquires) {
               return nonfairTryAcquire(acquires);
           }
   
   // 非公平获取锁
   final boolean nonfairTryAcquire(int acquires) {
           // 得到当前线程    
       	final Thread current = Thread.currentThread();
       	// 获取state的值
               int c = getState();
       	// 如果c为0,说明锁已经被其他线程释放了
               if (c == 0) {
                   // 再次尝试获取锁,也就是尝试设置state值为1
                   if (compareAndSetState(0, acquires)) {
                       // 设置当前线程为占用线程
                       setExclusiveOwnerThread(current);
                       return true;
                   }
               } // 如果占用的线程为当前线程
               else if (current == getExclusiveOwnerThread()) {
                   // 则把state值加上acquires, 表示这是可重入锁. (这也是可重入锁的实现)
                   int nextc = c + acquires;
                   if (nextc < 0) // overflow
                       throw new Error("Maximum lock count exceeded");
                   // 设置state的值为修改后的值
                   setState(nextc);
                   return true;
               }
               return false;
           }
   
   // 添加一个Node节点到同步队列中
   private Node addWaiter(Node mode) {
       	// 创建一个Node节点
           Node node = new Node(Thread.currentThread(), mode);
       	// 获取尾节点
           Node pred = tail;
       	// 如果尾节点不为空,那么队列已经被初始化
           if (pred != null) {
               // 当前节点的前节点设置为现在的尾节点
               node.prev = pred;
               // 把尾节点设置为当前节点(原子操作)
               if (compareAndSetTail(pred, node)) {
                   // 把原来的尾节点的下一个节点指向新建的node节点
                   pred.next = node;
                   return node;
               }
           }
       	// 否则使用enq插入node节点
           enq(node);
           return node;
       }
   
   
   private Node enq(final Node node) {
       	// 死循环插入节点
           for (;;) {
               // 获取尾节点
               Node t = tail;
               // 如果尾节点为null,那么进行初始化
               if (t == null) {
                   // 创建一个新节点设置为head节点
                   if (compareAndSetHead(new Node()))
                       // 尾节点也指向head(新创建的节点)节点
                       tail = head;
               } else { // 如果尾节点不为null
                   // 把要插入的node节点的前节点设置为tail
                   node.prev = t;
                   // 把tail设置为当前要插入的node节点
                   if (compareAndSetTail(t, node)) {
                       // 原tail节点的next指向node节点
                       t.next = node;
                       // 返回原tail节点
                       return t;
                   }
               }
           }
       }
   
   
   final boolean acquireQueued(final Node node, int arg) {
           boolean failed = true;
           try {
               boolean interrupted = false;
               for (;;) { // 死循环,一直尝试进行
                   // 获取前一个节点
                   final Node p = node.predecessor();
                   // 如果前一个节点为head,并再次尝试获取锁
                   if (p == head && tryAcquire(arg)) { // 如果是head节点并获取锁成功
                       // 设置node为当前节点
                       setHead(node);
                       p.next = null; // help GC
                       failed = false;
                       return interrupted; // 返回false
                   }
                   if (shouldParkAfterFailedAcquire(p, node) &&
                       parkAndCheckInterrupt())
                       // 如果p节点状态为singal  并且线程中断过, 则设置中断标志为true
                       interrupted = true;
               }
           } finally {
               if (failed)  // 如果获取锁失败, 则设置node节点为取消状态
                   cancelAcquire(node);
           }
       }
   
   
   private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
         // 获取前节点的状态
           int ws = pred.waitStatus;
           if (ws == Node.SIGNAL) // singal表示唤醒后续节点, 故当前节点可以进行休眠了
               return true;
           if (ws > 0) { // 如果前一个节点为取消状态, 那么把当前节点放到一个节点状态不大于0的节点后
               do {
                   node.prev = pred = pred.prev;
               } while (pred.waitStatus > 0);
               pred.next = node;
           } else {
               // 到这里说明前节点的等待状态为0,或者-3, 把前一个节点的等待状态设置为-1
               compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
           }
       	// 只有前一个节点的状态为-1才返回true,否则返回false
           return false;
       }
   
       private final boolean parkAndCheckInterrupt() {
           // 阻塞当前线程
           LockSupport.park(this);
           // 当前线程是否被中断过
           return Thread.interrupted();
       }
   
    private void cancelAcquire(Node node) {
           // Ignore if node doesn't exist
           if (node == null)
               return;
   
           node.thread = null;
   
           // 跳过已经被取消的node
           Node pred = node.prev;
           while (pred.waitStatus > 0)
               node.prev = pred = pred.prev;
   
        	// 此时这里的predNext就是node节点
           Node predNext = pred.next;
   		// 把node节点状态设置为1取消状态
           node.waitStatus = Node.CANCELLED;
   
           // 如果当前节点为尾节点,并且把尾节点设置为pred节点成功
           if (node == tail && compareAndSetTail(node, pred)) {
               // 则把pred的next节点设置为null
               compareAndSetNext(pred, predNext, null);
           } else {
               int ws;
               // (如果pred不是head节点&&(前节点状态为singal || (前节点状态小于0 && 设置前节点状态为singal成功)) && pred的thread不为null)   -- 这里条件有点多,好好捋一下
               // 也就是:
               // pred不是head节点 && pred的状态为singal && pred的thread不为null
               if (pred != head &&
                   ((ws = pred.waitStatus) == Node.SIGNAL ||
                    (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
                   pred.thread != null) {
                   // 获取要取消的node的后一个节点
                   Node next = node.next;
                   if (next != null && next.waitStatus <= 0)
                       // 如果next不是null&&等待状态小于0, 则把pred的下一个node设置为next
                       // 也就是把node删除
                       compareAndSetNext(pred, predNext, next);
               } else {
                   // 如果满足条件 ( pred是head节点 || pred的状态不为singal || pred的thread为null)
                   // 则把node节点线程放行
                   unparkSuccessor(node);
               }
               // node不可达, 就会被回收
               node.next = node; // help GC
           }
       }
   ```

   

### 公平锁实现

   luck公平锁的获取和上面非公平锁实现除了tryAcquire不一样外,其他都是一样的.

   ```java
   final void lock() {
               acquire(1);
           }
   
   public final void acquire(int arg) {
       	  // 如果获取锁失败, 则添加节点到同步队列并阻塞当前线程
           if (!tryAcquire(arg) &&
               acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
               // 如果获取锁失败,并且线程中断过, 则中断自己
               selfInterrupt();
       }
   
   protected final boolean tryAcquire(int acquires) {
               final Thread current = Thread.currentThread();
               int c = getState();
               if (c == 0) { // state为0,说明锁无人占用
                   // 如果队列中没有阻塞线程 并且 抢占锁成功, 则设置当前线程为占用线程
                   if (!hasQueuedPredecessors() &&
                       compareAndSetState(0, acquires)) {
                       setExclusiveOwnerThread(current);
                       return true;
                   }
               }  //  否则查看占用线程是否为当前线程
               else if (current == getExclusiveOwnerThread()) {
                   // 如果占用线程为当前线程, 那么把state数量增大acquires, 并返回true,否则返回false
                   int nextc = c + acquires;
                   if (nextc < 0)
                       throw new Error("Maximum lock count exceeded");
                   setState(nextc);
                   return true;
               }
               return false;
           }
       }
   
   // 查看同步队列中是否有阻塞的线程
   public final boolean hasQueuedPredecessors() {
           Node t = tail; // Read fields in reverse initialization order
           Node h = head;
           Node s;
           return h != t &&
               ((s = h.next) == null || s.thread != Thread.currentThread());
       }
   ```

   区别:

非同步锁上来就开始抢占; 而同步锁, 则要查看下同步队列中是否有其他阻塞节点在等待, 如果有且不是当前线程占用,则不进行占用.

```java
// 同步
final void lock() {
               acquire(1);
           }
// 非同步
final void lock() {
            if (compareAndSetState(0, 1))
                setExclusiveOwnerThread(Thread.currentThread());
            else
                acquire(1);
        }
```



## lockInterruptibly 锁抢占

### 非同步实现

```java
// 允许中断的获取锁
public void lockInterruptibly() throws InterruptedException {
    sync.acquireInterruptibly(1);
}

public final void acquireInterruptibly(int arg)
    throws InterruptedException {
    // 如果当前线程发生了中断, 那么就抛出一个中断异常
    if (Thread.interrupted())
        throw new InterruptedException();
    if (!tryAcquire(arg))
        // 如果没有获取到锁, 
        doAcquireInterruptibly(arg);
}
// 使用非公平方式抢占锁
protected final boolean tryAcquire(int acquires) {
    return nonfairTryAcquire(acquires);
}

final boolean nonfairTryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0) // overflow
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }

private void doAcquireInterruptibly(int arg)
        throws InterruptedException {
        // 添加一个节点到同步队列尾
    	final Node node = addWaiter(Node.EXCLUSIVE);
        boolean failed = true;
        try {
            for (;;) {// 死循环获取锁
                // 获取前节点
                final Node p = node.predecessor();
                // 如果前节点是head节点, 再次获取锁
                if (p == head && tryAcquire(arg)) {
                    // 如果既是头节点,并获取锁成功,  那么就把当前节点设置为头节点, 并退出
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return;
                }
                // 如果当前线程需要阻塞,并且发生过中断
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    // 抛出中断异常
                    throw new InterruptedException();
            }
        } finally {
            if (failed)
                cancelAcquire(node); // 设置当前线程节点为取消状态
        }
    }
```



### 同步实现

只有获取锁的tryAcquire函数和非同步实现不同，其他函数都一样。

```java
public void lockInterruptibly() throws InterruptedException {
    sync.acquireInterruptibly(1);
}

public final void acquireInterruptibly(int arg)
            throws InterruptedException {
        if (Thread.interrupted())
            throw new InterruptedException();
        if (!tryAcquire(arg))
            doAcquireInterruptibly(arg);
    }

protected final boolean tryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            // 获取锁状态
    	    int c = getState();
            if (c == 0) { // 锁无人占用
                // 如果同步队列没有其他节点并且占用锁成功
                if (!hasQueuedPredecessors() &&
                    compareAndSetState(0, acquires)) {
                    // 设置当前线程为占用线程
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
    		// 如果当前线程为占用线程，则把state数组增大。 可重入锁实现
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }

private void doAcquireInterruptibly(int arg)
        throws InterruptedException {
    }
```

lock和lockInterruptibly 函数的不同点：
第一点：

```java
// lockInterruptibly 具体获取锁函数

public final void acquireInterruptibly(int arg)
            throws InterruptedException {
       // 当前线程中断过， 则抛出中断异常
        if (Thread.interrupted())
            throw new InterruptedException();
        if (!tryAcquire(arg)) // 获取锁失败
            // 则添加节点到同步队列，并循环获取锁或者阻塞当前线程
            doAcquireInterruptibly(arg);
    }


// lock获取锁函数

public final void acquire(int arg) {
       	  // 如果获取锁失败, 则添加节点到同步队列并阻塞当前线程
           if (!tryAcquire(arg) &&
               acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
               // 如果获取锁失败,并且线程中断过, 则中断自己
               selfInterrupt();
       }

不同： 
	1. lockInterruptibly在线程中断时，会抛出中断异常，而lock函数不会
	2. lockInterruptibly在线程中断时抛出中断异常
	   lock函数只是设置了interrupted标志位，表示是否中断过
```



## tryLock 锁抢占

### 非同步实现

```java
public boolean tryLock() {
        // 通过非公平方式抢占锁
    	return sync.nonfairTryAcquire(1);
    }

final boolean nonfairTryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0) // overflow
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
```

此函数没有同步实现。 可以看到此函数直接去抢占锁，抢占成功返回true，否则返回false，不会去阻塞线程。

## tryLock(long timeout, TimeUnit unit) 抢占

### 非同步实现

```java
    public boolean tryLock(long timeout, TimeUnit unit)
        throws InterruptedException {
        return sync.tryAcquireNanos(1, unit.toNanos(timeout));
    }

    public final boolean tryAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
        // 当前线程中断过， 则抛出中断异常
        if (Thread.interrupted())
            throw new InterruptedException();
        // 先通过非公平方式抢占所，失败再doAcquireNanos
        return tryAcquire(arg) ||
            doAcquireNanos(arg, nanosTimeout);
    }

    protected final boolean tryAcquire(int acquires) {
        return nonfairTryAcquire(acquires);
    }

    final boolean nonfairTryAcquire(int acquires) {
        final Thread current = Thread.currentThread();
        int c = getState();
        if (c == 0) {
            if (compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(current);
                return true;
            }
        }
        else if (current == getExclusiveOwnerThread()) {
            int nextc = c + acquires;
            if (nextc < 0) // overflow
                throw new Error("Maximum lock count exceeded");
            setState(nextc);
            return true;
        }
        return false;
    }
	
	// 在规定时间没有获取到锁， 就返回，不获取了
    private boolean doAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
        // 健壮性检查
        if (nanosTimeout <= 0L)
            return false;
        final long deadline = System.nanoTime() + nanosTimeout;
        // 添加一个节点到同步队列尾
        final Node node = addWaiter(Node.EXCLUSIVE);
        boolean failed = true;
        try {
            for (;;) {// 死循环获取锁
                final Node p = node.predecessor();
                if (p == head && tryAcquire(arg)) {
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return true;
                }
                nanosTimeout = deadline - System.nanoTime();
                // 如果超值未获取到，就直接返回false
                if (nanosTimeout <= 0L)
                    return false;
                // 如果当前线程可以直接阻塞 并且自旋时间大于阈值， 则阻塞该线程
                if (shouldParkAfterFailedAcquire(p, node) &&
                    nanosTimeout > spinForTimeoutThreshold)
                    LockSupport.parkNanos(this, nanosTimeout);
                if (Thread.interrupted())
                    // 如果当前线程中断过， 则抛出异常
                    throw new InterruptedException();
            }
        } finally {
            if (failed)
                cancelAcquire(node); // 把当前节点设置为取消状态
        }
    }
```



### 同步实现

```java
 public boolean tryLock(long timeout, TimeUnit unit)
        throws InterruptedException {
        return sync.tryAcquireNanos(1, unit.toNanos(timeout));
    }

    public final boolean tryAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
        // 当前线程中断过， 则抛出中断异常
        if (Thread.interrupted())
            throw new InterruptedException();
        // 先通过非公平方式抢占所，失败再doAcquireNanos
        return tryAcquire(arg) ||
            doAcquireNanos(arg, nanosTimeout);
    }

    protected final boolean tryAcquire(int acquires) {
        return nonfairTryAcquire(acquires);
    }
   // 同步获取锁实现
     protected final boolean tryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (!hasQueuedPredecessors() &&
                    compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }
	
	// 在规定时间没有获取到锁， 就返回，不获取了
    private boolean doAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
        // 健壮性检查
        if (nanosTimeout <= 0L)
            return false;
        final long deadline = System.nanoTime() + nanosTimeout;
        // 添加一个节点到同步队列尾
        final Node node = addWaiter(Node.EXCLUSIVE);
        boolean failed = true;
        try {
            for (;;) {// 死循环获取锁
                final Node p = node.predecessor();
                if (p == head && tryAcquire(arg)) {
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return true;
                }
                nanosTimeout = deadline - System.nanoTime();
                // 如果超值未获取到，就直接返回false
                if (nanosTimeout <= 0L)
                    return false;
                // 如果当前线程可以直接阻塞 并且自旋时间大于阈值， 则阻塞该线程
                if (shouldParkAfterFailedAcquire(p, node) &&
                    nanosTimeout > spinForTimeoutThreshold)
                    LockSupport.parkNanos(this, nanosTimeout);
                if (Thread.interrupted())
                    // 如果当前线程中断过， 则抛出异常
                    throw new InterruptedException();
            }
        } finally {
            if (failed)
                cancelAcquire(node); // 把当前节点设置为取消状态
        }
    }
```

## 释放锁的方式

```java
public void unlock() {
    sync.release(1);
}

public final boolean release(int arg) {
    	// 如果释放锁后，state值为0，则进行下面操作
        if (tryRelease(arg)) {
            Node h = head;
            if (h != null && h.waitStatus != 0)
                unparkSuccessor(h);
            return true;
        }
    	// 如果释放后，state不为0，则返回false
        return false;
    }

private void unparkSuccessor(Node node) {
    	// 获取头节点
        int ws = node.waitStatus;
        if (ws < 0)
            // 头节点状态小于0， 则设置头节点状态为0
            compareAndSetWaitStatus(node, ws, 0);
		// 获取头节点的下一个节点，也就是需要唤醒的线程
        Node s = node.next;
    	// 如果下一个节点为null，或者等待状态大于0，也就是取消状态，那么从尾节点开始寻找一个等待状态小于0的节点进行唤醒
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            // 唤醒线程
            LockSupport.unpark(s.thread);
    }

protected final boolean tryRelease(int releases) {
    		// 获取state - release的值
            int c = getState() - releases;
            if (Thread.currentThread() != getExclusiveOwnerThread())
                // 如果当前线程不是占用线程，则抛出异常
                throw new IllegalMonitorStateException();
            boolean free = false;
    		// 因为有可重入锁的实现，故只有当state为0，才能算是释放锁
            if (c == 0) {
                free = true;
                // 占用线程为null
                setExclusiveOwnerThread(null);
            }
    		// 更新state的值
            setState(c);
            return free;
        }
```

