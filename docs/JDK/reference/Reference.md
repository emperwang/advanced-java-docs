# Reference

此类功能主要是负责内存的一个状态,当然它还和java虚拟机,垃圾回收器打交道. Reference把内存分为4中状态:Active, Pending, Enqueued, Inactive.

* Active,一般来说内存一开始被分配的状态都是active
* Pending, 大概是指快要被放进对象的对象, 也即是马上要被回收的对象
* Enqueued 就是对象的内存已经被回收, 已经把这个对象放入到一个队列中, 方便以后我们查询某大对象是否被回收
* Inactive就是最终的状态, 不能再变为其他状态.

ReferenceQueue, 引用队列. 再检测到对象的可达性更改之后, 垃圾回收器将已注册的引用对象添加到队列中,ReferenceQueue实现了入队(Enqueue)和出队(poll),还有remove操作.  内部元素head就是泛型的Reference.

```java
// 创建一个队列
ReferenceQueue queue = new ReferenceQueue();
// 创建弱引用,此时状态为Active, 并且Reference.pending为空, 当前Reference.queue=queue(上面创建的),next=null
WeakReference reference = new WeakReference(new Object(),queue);

// 当GC执行后,由于是弱引用,所以回收该object对象, 并且置于pending上,此时reference状态为PENDING
System.gc();
// ReferenceHandler从pending中取下该元素,并且将该元素放入到queue中,此时Reference状态为ENQUEUED,Reference.queue=Reference.ENQUEUED

// 当从queue中取出该元素,则变为INACTIVE, Reference.queue=Reference.NULL;
Reference ref = queue.remove();
System.out.println(ref);
```

可以用来做什么呢?

可以用来检测内存泄漏.

* 监听bean的生命周期.
* 在onDestory()的时候, 创建相应的Reference和ReferenceQueue, 并启动后天进程去检测
* 一段时间后,从ReferenceQueue中读取, 若读取不到相应的bean的Reference, 有可能发生内存泄漏了， 这个时候，再促发一次GC，一段时间后，再次读取，若再ReferenceQueue中还是读取不到相应bean的Refernece，可以断定是内存泄漏了。
* 发生内存泄漏后，dump，分析hprof文件，找到泄漏路径。

## Refenec源码解析

### Field

```java
    // 存储引用的对象
	private T referent;         /* Treated specially by GC */
	// 引用队列
    volatile ReferenceQueue<? super T> queue;
	
	// 查看注释，再四种状态下的next的值
	// 正常情况下，此field在加入队列后使用，指向下一个元素
    /* When active:   NULL
     *     pending:   this
     *    Enqueued:   next reference in queue (or this if last)
     *    Inactive:   this
     */
    @SuppressWarnings("rawtypes")
    Reference next;
	
	//  不同状态下对应的值，并且此代表下一个元素
    /* When active:   next element in a discovered reference list maintained by GC (or this if last)
     *     pending:   next element in the pending list (or null if last)
     *   otherwise:   NULL
     */
    transient private Reference<T> discovered;  /* used by VM */
	// 锁
    static private class Lock { }
    private static Lock lock = new Lock();

	// 等待被加入队列的对象。 此field由回收器赋值，和垃圾回收器打交道
    /* List of References waiting to be enqueued.  The collector adds
     * References to this list, while the Reference-handler thread removes
     * them.  This list is protected by the above lock object. The
     * list uses the discovered field to link its elements.
     */
    private static Reference<Object> pending = null;
```



### 构造函数

```java
    // 可以看到，此引用可以和对垒绑定，也可以不和队列绑定
	
	Reference(T referent) {
        this(referent, null);
    }

    Reference(T referent, ReferenceQueue<? super T> queue) {
        this.referent = referent;
        this.queue = (queue == null) ? ReferenceQueue.NULL : queue;
    }
```



### 静态初始化代码

```java
    static {
        ThreadGroup tg = Thread.currentThread().getThreadGroup();
        // 获取一个不为null的线程组
        for (ThreadGroup tgn = tg;
             tgn != null;
             tg = tgn, tgn = tg.getParent());
        // 创建线程
        Thread handler = new ReferenceHandler(tg, "Reference Handler");
        // 设置优先级为最大优先级
        handler.setPriority(Thread.MAX_PRIORITY);
        // 守护线程
        handler.setDaemon(true);
        // 开始运行
        handler.start();
        // provide access in SharedSecrets
        SharedSecrets.setJavaLangRefAccess(new JavaLangRefAccess() {
            @Override
            public boolean tryHandlePendingReference() {
                return tryHandlePending(false);
            }
        });
    }
```

看一下这个后台线程处理什么内容呢？

```java
   private static class ReferenceHandler extends Thread {

        private static void ensureClassInitialized(Class<?> clazz) {
            try {
                // 加载类
                Class.forName(clazz.getName(), true, clazz.getClassLoader());
            } catch (ClassNotFoundException e) {
                throw (Error) new NoClassDefFoundError(e.getMessage()).initCause(e);
            }
        }

        static {
			// 加载类
            ensureClassInitialized(InterruptedException.class);
            ensureClassInitialized(Cleaner.class);
        }

        ReferenceHandler(ThreadGroup g, String name) {
            super(g, name);
        }

        public void run() {
            while (true) {
                tryHandlePending(true);
            }
        }
    }
```

可以看出来，此后台线程只是运行函数tryHandlePending，也就是此函数处理的内容，就是此线程的工作内容

```java
    static boolean tryHandlePending(boolean waitForNotify) {
        Reference<Object> r;
        Cleaner c;
        try {
            synchronized (lock) { // 同步操作
                if (pending != null) {
                    r = pending; // 回去要回收的对象
                    // 'instanceof' might throw OutOfMemoryError sometimes
                    // so do this before un-linking 'r' from the 'pending' chain...
                    c = r instanceof Cleaner ? (Cleaner) r : null;
                    // unlink 'r' from 'pending' chain
                    // 让pending指向下一个要回收的元素
                    pending = r.discovered;
                    r.discovered = null;
                } else {
                    // The waiting on the lock may cause an OutOfMemoryError
                    // because it may try to allocate exception objects.
                    if (waitForNotify) {
                        lock.wait();
                    }
                    // retry if waited
                    return waitForNotify;
                }
            }
        } catch (OutOfMemoryError x) {
            // Give other threads CPU time so they hopefully drop some live references
            // and GC reclaims some space.
            // Also prevent CPU intensive spinning in case 'r instanceof Cleaner' above
            // persistently throws OOME for some time...
            Thread.yield();   // 释放cpu
            // retry
            return true;
        } catch (InterruptedException x) {
            // retry
            return true;
        }

        // Fast path for cleaners
        if (c != null) {
            c.clean();  // 运行clean方法
            return true;
        }

        ReferenceQueue<? super Object> q = r.queue;
        if (q != ReferenceQueue.NULL) q.enqueue(r); // 把对象加入到队列中
        return true;
    }
```

看此一下此clean方法和加入队列方法

clean:

```java
    public void clean() {
        // 把自己从队列中删除
        if (remove(this)) {
            try {
                // 执行一次回调函数
                this.thunk.run();
            } catch (final Throwable var2) {
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() {
                        if (System.err != null) {
                            (new Error("Cleaner terminated abnormally", var2)).printStackTrace();
                        }

                        System.exit(1);
                        return null;
                    }
                });
            }

        }
    }

	// 也就是把var0这个节点从队列中删除
    private static synchronized boolean remove(Cleaner var0) {
        if (var0.next == var0) {
            return false;
        } else {
            if (first == var0) { // 如果var0就是first节点
                if (var0.next != null) {
                    // first指向下一个节点
                    first = var0.next;
                } else {
                    first = var0.prev; // 无后节点，则指向其前节点
                }
            }
			// var0后一个节点的前节点指向var0的前节点
            if (var0.next != null) {
                var0.next.prev = var0.prev;
            }
			// 前节点的后节点指向var0的后节点
            // 这两步就把var0从队列中删除了
            if (var0.prev != null) {
                var0.prev.next = var0.next;
            }
			// 不可达，help gc
            var0.next = var0;
            var0.prev = var0;
            return true;
        }
    }
```



加入队列:

```java
    boolean enqueue(Reference<? extends T> r) { /* Called only by Reference class */
        synchronized (lock) {
            // Check that since getting the lock this reference hasn't already been
            // enqueued (and even then removed)
            ReferenceQueue<?> queue = r.queue;
            if ((queue == NULL) || (queue == ENQUEUED)) {
                return false;
            }
            assert queue == this;
            r.queue = ENQUEUED; // 也就是修改一下队列
            r.next = (head == null) ? r : head;
            head = r;
            queueLength++;
            if (r instanceof FinalReference) {
                sun.misc.VM.addFinalRefCount(1);
            }
            lock.notifyAll();
            return true;
        }
    }
```

可见此静态代码块会启动一个后台线程把pending中的节点加入到队列中；如果pending为null，则等待。









