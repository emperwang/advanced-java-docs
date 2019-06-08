# AQS 概述

## 设计模式

AQS使用了模板方法，把锁的队列管理，获取锁，释放锁等操作已经定义好，只需要实现其中的

```java
// 当前现象是否独占锁
protected boolean isHeldExclusively() {
        throw new UnsupportedOperationException();
    }
// 独占锁获取
protected boolean tryAcquire(int arg) {
        throw new UnsupportedOperationException();
    }
// 独占锁释放
 protected boolean tryRelease(int arg) {
        throw new UnsupportedOperationException();
    }    
 // 共享锁获取
 protected int tryAcquireShared(int arg) {
        throw new UnsupportedOperationException();
    }
// 共享锁释放
    protected boolean tryReleaseShared(int arg) {
        throw new UnsupportedOperationException();
    }
```

这五个方法，根据需要进行重写就可以实现一个自定义的锁机制。

当然了，如果需要是独占锁，那么就重写tryRcqire(), tryRelease；共享锁就实现tryAcquireShared，tryReleaseShared；

isHeldExclusively函数根据需要进行重写。

Concurrent包中的其他锁，ReentrantLock，semaphore，CountDownLatch等都是重写上述方法中的几种，实现了一种特定功能的锁。当然了如果自己需要实现一个锁，也只需要这五个方法中的几个就可以了。

## Node节点

看一下Node（是一个双向列表节点）节点组成:

```java
static final class Node {
		/*
			Node节点的种类，表示哪种锁的实现
			SHARED:共享锁
			EXALUSIVE:独占锁
		*/
        static final Node SHARED = new Node();
    
        static final Node EXCLUSIVE = null;
		// Node节点的状态   取消
        static final int CANCELLED =  1;
 		// 需要唤醒后续节点
        static final int SIGNAL    = -1;
		// 等待某些条件的节点
        static final int CONDITION = -2;
		// 唤醒后续节点
        static final int PROPAGATE = -3;
		// 等待状态，就是上面的四种
        volatile int waitStatus;
		// 前一个节点
        volatile Node prev;
		// 后一个节点
        volatile Node next;
		// 此节点存储的线程
        volatile Thread thread;
		
        Node nextWaiter;
    	// 是否是共享锁
        final boolean isShared() {
            return nextWaiter == SHARED;
        }
    	// 获取前节点
        final Node predecessor() throws NullPointerException {
            Node p = prev;
            if (p == null)
                throw new NullPointerException();
            else
                return p;
        }

        Node() {    // Used to establish initial head or SHARED marker
        }

        Node(Thread thread, Node mode) {     // Used by addWaiter
            this.nextWaiter = mode;
            this.thread = thread;
        }

        Node(Thread thread, int waitStatus) { // Used by Condition
            this.waitStatus = waitStatus;
            this.thread = thread;
        }
    }
```

AQS使用Node实现了一个双向链表，来管理获取锁的线程队列。

## AQS重要的field

```java
	// 双向列表的头节点    
	private transient volatile Node head;
    // 尾节点
	private transient volatile Node tail;
    // 状态量，就是通过维护此状态量来实现锁
	private volatile int state;
	// 自旋时间
    static final long spinForTimeoutThreshold = 1000L;
	// CAS的操作函数
	private static final Unsafe unsafe = Unsafe.getUnsafe();
	// state的内存偏移
    private static final long stateOffset;
	// 头节点的内存偏移
    private static final long headOffset;
	// 尾节点的内存偏移
    private static final long tailOffset;
	// waitStatus内存偏移
    private static final long waitStatusOffset;
    private static final long nextOffset;
   static {
        try {
            // 静态代码块，获取上面的偏移值
            stateOffset = unsafe.objectFieldOffset
                (AbstractQueuedSynchronizer.class.getDeclaredField("state"));
            headOffset = unsafe.objectFieldOffset
                (AbstractQueuedSynchronizer.class.getDeclaredField("head"));
            tailOffset = unsafe.objectFieldOffset
                (AbstractQueuedSynchronizer.class.getDeclaredField("tail"));
            waitStatusOffset = unsafe.objectFieldOffset
                (Node.class.getDeclaredField("waitStatus"));
            nextOffset = unsafe.objectFieldOffset
                (Node.class.getDeclaredField("next"));

        } catch (Exception ex) { throw new Error(ex); }
    }
```



### AQS 操作state方法

```java
	// 底层都是CAS区操作变量
    private final boolean compareAndSetHead(Node update) {
        return unsafe.compareAndSwapObject(this, headOffset, null, update);
    }

    private final boolean compareAndSetTail(Node expect, Node update) {
        return unsafe.compareAndSwapObject(this, tailOffset, expect, update);
    }

    private static final boolean compareAndSetWaitStatus(Node node,
                                                         int expect,
                                                         int update) {
        return unsafe.compareAndSwapInt(node, waitStatusOffset,
                                        expect, update);
    }

    private static final boolean compareAndSetNext(Node node,
                                                   Node expect,
                                                   Node update) {
        return unsafe.compareAndSwapObject(node, nextOffset, expect, update);
    }
```

CAS是compareAndSwap的使用，从jvm底层可以看到是使用的对应的cpu的汇编CompareAndSwap指令去实现的。