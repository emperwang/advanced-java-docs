# SynchronousQueue

## Field

```java
    // CPU核数
	static final int NCPUS = Runtime.getRuntime().availableProcessors();
	// 最大自旋
    static final int maxTimedSpins = (NCPUS < 2) ? 0 : 32;
	// 不限时时候的自旋次数
    static final int maxUntimedSpins = maxTimedSpins * 16;
    static final long spinForTimeoutThreshold = 1000L;
    private transient volatile Transferer<E> transferer;
    // 锁 以及生产者和消费者队列
	private ReentrantLock qlock;
    private WaitQueue waitingProducers;
    private WaitQueue waitingConsumers;
```

## 构造器

```java
    public SynchronousQueue(boolean fair) {
        transferer = fair ? new TransferQueue<E>() : new TransferStack<E>();
    }

    public SynchronousQueue() {
        this(false);
    }
```



## 添加元素

### put

```java
    public void put(E e) throws InterruptedException {
        if (e == null) throw new NullPointerException();
        if (transferer.transfer(e, false, 0) == null) {
            Thread.interrupted();
            throw new InterruptedException();
        }
    }
```

### offer

```java
    public boolean offer(E e) {
        if (e == null) throw new NullPointerException();
        return transferer.transfer(e, true, 0) != null;
    }
```



## 获取元素

### poll

```java
    public E poll() {
        return transferer.transfer(null, true, 0);
    }
```



### take

```java
    public E take() throws InterruptedException {
        E e = transferer.transfer(null, false, 0);
        if (e != null)
            return e;
        Thread.interrupted();
        throw new InterruptedException();
    }
```

### peek

```java
    public E peek() {
        return null;
    }
```



## 删除元素

```java
    public boolean remove(Object o) {
        return false;
    }
```

## Transfer

从添加元素和获取元素以及删除元素操作，可以看出来删除函数没有做任何事，添加和获取也只是调用这个transfer的函数，所以关键点就在此内部类的实现。那还等什么，看一下把:

### TransferStack

#### Field
```java
       // 表示节点的三种状态
		/** Node represents an unfulfilled consumer */
        static final int REQUEST    = 0;
        /** Node represents an unfulfilled producer */
        static final int DATA       = 1;
        /** Node is fulfilling another unfulfilled DATA or REQUEST */
        static final int FULFILLING = 2;

        private static final sun.misc.Unsafe UNSAFE;
        private static final long headOffset;
```
静态初始化:
```java
static {
            try {
                UNSAFE = sun.misc.Unsafe.getUnsafe();
                Class<?> k = TransferStack.class;
                headOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("head"));
            } catch (Exception e) {
                throw new Error(e);
            }
        }
```
存储结构：

```java
        static final class SNode {
            volatile SNode next;        // next node in stack
            volatile SNode match;       // the node matched to this
            volatile Thread waiter;     // to control park/unpark  // 等待的线程
            Object item;                // data; or null for REQUESTs // 存储的元素
            int mode;				// 节点的状态
			// 构造函数
            SNode(Object item) {
                this.item = item;
            }
			// 设置next值
            boolean casNext(SNode cmp, SNode val) {
                return cmp == next &&
                    UNSAFE.compareAndSwapObject(this, nextOffset, cmp, val);
            }
			// 匹配节点操作
            boolean tryMatch(SNode s) {
                if (match == null &&
                    UNSAFE.compareAndSwapObject(this, matchOffset, null, s)) {
                    // 匹配到节点了,则把节点对应的线程唤醒
                    Thread w = waiter;
                    if (w != null) {    // waiters need at most one unpark
                        waiter = null;
                        LockSupport.unpark(w);
                    }
                    return true;
                }
                return match == s;
            }

            // match指向自己,就把把节点取消
            void tryCancel() {
                UNSAFE.compareAndSwapObject(this, matchOffset, null, this);
            }
			// 是否取消
            boolean isCancelled() {
                return match == this;
            }

            // CAS操作
            private static final sun.misc.Unsafe UNSAFE;
            private static final long matchOffset;
            private static final long nextOffset;

            static {
                try {
                    UNSAFE = sun.misc.Unsafe.getUnsafe();
                    Class<?> k = SNode.class;
                    matchOffset = UNSAFE.objectFieldOffset
                        (k.getDeclaredField("match"));
                    nextOffset = UNSAFE.objectFieldOffset
                        (k.getDeclaredField("next"));
                } catch (Exception e) {
                    throw new Error(e);
                }
            }
        }
```

看一下次transfer具体实现把：
```java
        E transfer(E e, boolean timed, long nanos) {
            // transfer函数运行包含下面三种情况
            /*
             * Basic algorithm is to loop trying one of three actions:
             *
             * 1. If apparently empty or already containing nodes of same
             *    mode, try to push node on stack and wait for a match,
             *    returning it, or null if cancelled.
             *
             * 2. If apparently containing node of complementary mode(补充模式),
             *    try to push a fulfilling node on to stack, match
             *    with corresponding waiting node, pop both from
             *    stack, and return matched item. The matching or
             *    unlinking might not actually be necessary because of
             *    other threads performing action 3:
             *
             * 3. If top of stack already holds another fulfilling node,
             *    help it out by doing its match and/or pop
             *    operations, and then continue. The code for helping
             *    is essentially the same as for fulfilling, except
             *    that it doesn't return the item.
             */

            SNode s = null; // constructed/reused as needed
            // 判断是获取数据,还是添加数据
            int mode = (e == null) ? REQUEST : DATA;

            for (;;) { // 持续运行,直到执行成功
                SNode h = head;
                // 第一种情况--空队列获取元素,添加节点到stack中
                if (h == null || h.mode == mode) {  // empty or same-mode
                    // 设置了超时时间
                    if (timed && nanos <= 0) {      // can't wait
                        // 如果h为null,并且被取消了,则删除h节点
                        if (h != null && h.isCancelled())
                            casHead(h, h.next);     // pop cancelled node
                        else
                            return null;
                        // 新建一个节点,并把节点添加到stack的第一个位置上
                        // 也就是 后进先出-stack
                        // 获取元素时,e为null,mode为REQUEST
                        // 添加元素时,e不为null,mode为DATA
                    } else if (casHead(h, s = snode(s, e, h, mode))) {
                        // 添加节点成功呢,就阻塞线程
                        SNode m = awaitFulfill(s, timed, nanos);
                        // 节点取消,则删除节点
                        if (m == s) {               // wait was cancelled
                            clean(s);
                            return null;
                        }
                        if ((h = head) != null && h.next == s)
                            casHead(h, s.next);     // help s's fulfiller
                        return (E) ((mode == REQUEST) ? m.item : s.item);
                    }
                    // 添加元素,尝试进行匹配操作 -- 第二种情况
                } else if (!isFulfilling(h.mode)) { // try to fulfill
                    // 节点被取消,直接删除
                    if (h.isCancelled())            // already cancelled
                        casHead(h, h.next);         // pop and retry
                    // 新建一个正在匹配模式的节点,并添加到头部
                    else if (casHead(h, s=snode(s, e, h, FULFILLING|mode))) {
                        for (;;) { // loop until matched or waiters disappear
                            // m 就是要匹配的节点
                            SNode m = s.next;       // m is s's match
                            // 如果没有等待节点,则重新添加节点到队列中,并把节点对应线程阻塞
                            if (m == null) {        // all waiters are gone
                                casHead(s, null);   // pop fulfill node
                                s = null;           // use new node next time
                                break;              // restart main loop
                            }
                            SNode mn = m.next;
                            // 尝试进行匹配
                            if (m.tryMatch(s)) {
                                // 并把匹配到的两个节点删除
                                casHead(s, mn);     // pop both s and m
                                // 根据请求不同,返回值
                                return (E) ((mode == REQUEST) ? m.item : s.item);
                            } else                  // lost match
                                s.casNext(m, mn);   // help unlink
                        }
                    }
                    // 发现第一个节点是正在匹配,则帮助其进行匹配--第三种情况
                } else {                            // help a fulfiller
                    // m 就是要匹配的节点
                    SNode m = h.next;               // m is h's match
                    if (m == null)                  // waiter is gone
                        casHead(h, null);           // pop fulfilling node
                    else {
                        SNode mn = m.next;
                        // 尝试进行匹配,匹配上了,则把这两个节点删除
                        if (m.tryMatch(h))          // help match
                            casHead(h, mn);         // pop both h and m
                        else                        // lost match
                            h.casNext(m, mn);       // help unlink
                    }
                }
            }
        }
		// 创建节点操作
        static SNode snode(SNode s, Object e, SNode next, int mode) {
            if (s == null) s = new SNode(e);
            s.mode = mode;
            s.next = next;
            return s;
        }
	// 尝试匹配
    boolean tryMatch(SNode s) {
        if (match == null &&
            UNSAFE.compareAndSwapObject(this, matchOffset, null, s)) {
            Thread w = waiter;
            if (w != null) {    // waiters need at most one unpark
                waiter = null;
                LockSupport.unpark(w);
            }
            return true;
        }
        return match == s;
    }
```

阻塞节点对应的线程:

```java
        SNode awaitFulfill(SNode s, boolean timed, long nanos) {
            /*
             * When a node/thread is about to block, it sets its waiter
             * field and then rechecks state at least one more time
             * before actually parking, thus covering race vs
             * fulfiller noticing that waiter is non-null so should be
             * woken.
             *
             * When invoked by nodes that appear at the point of call
             * to be at the head of the stack, calls to park are
             * preceded by spins to avoid blocking when producers and
             * consumers are arriving very close in time.  This can
             * happen enough to bother only on multiprocessors.
             *
             * The order of checks for returning out of main loop
             * reflects fact that interrupts have precedence over
             * normal returns, which have precedence over
             * timeouts. (So, on timeout, one last check for match is
             * done before giving up.) Except that calls from untimed
             * SynchronousQueue.{poll/offer} don't check interrupts
             * and don't wait at all, so are trapped in transfer
             * method rather than calling awaitFulfill.
             */
            // 获取一个超时时间
            final long deadline = timed ? System.nanoTime() + nanos : 0L;
            Thread w = Thread.currentThread();
            // 设置自旋次数
            int spins = (shouldSpin(s) ?
                         (timed ? maxTimedSpins : maxUntimedSpins) : 0);
            for (;;) {
                // 如果中断了,则尝试取消节点
                if (w.isInterrupted())
                    s.tryCancel();
                SNode m = s.match;
                if (m != null)
                    return m;
                // 超时了,则也进行取消
                if (timed) {
                    nanos = deadline - System.nanoTime();
                    if (nanos <= 0L) {
                        s.tryCancel();
                        continue;
                    }
                }
                // 自旋
                if (spins > 0)
                    spins = shouldSpin(s) ? (spins-1) : 0;
                else if (s.waiter == null)
                    s.waiter = w; // establish waiter so can park next iter
                else if (!timed)
                    // 阻塞线程
                    LockSupport.park(this);
                else if (nanos > spinForTimeoutThreshold)
                    // 有超时的阻塞线程
                    LockSupport.parkNanos(this, nanos);
            }
        }
```

删除节点:

```java
        // 情况队列
		void clean(SNode s) {
            s.item = null;   // forget item
            s.waiter = null; // forget thread
            /*
             * At worst we may need to traverse entire stack to unlink
             * s. If there are multiple concurrent calls to clean, we
             * might not see s if another thread has already removed
             * it. But we can stop when we see any node known to
             * follow s. We use s.next unless it too is cancelled, in
             * which case we try the node one past. We don't check any
             * further because we don't want to doubly traverse just to
             * find sentinel.
             */

            SNode past = s.next;
            if (past != null && past.isCancelled())
                past = past.next;

            // 跳过哪些已经被删除的节点
            SNode p;
            while ((p = head) != null && p != past && p.isCancelled())
                casHead(p, p.next);

            // 删除节点s
            // 也就是把s的前节点的next指向s.next
            while (p != null && p != past) {
                SNode n = p.next;
                if (n != null && n.isCancelled())
                    p.casNext(n, n.next);
                else
                    p = n;
            }
        }
```



### TransferQueue
#### Field
```java
        // 队列头
		transient volatile QNode head;
        // 队列尾
        transient volatile QNode tail;
        transient volatile QNode cleanMe;
		// CAS 操作及其内存偏移值
        private static final sun.misc.Unsafe UNSAFE;
        private static final long headOffset;
        private static final long tailOffset;
        private static final long cleanMeOffset;
```
静态初始化:
```java
        static {
            try {
                UNSAFE = sun.misc.Unsafe.getUnsafe();
                Class<?> k = TransferQueue.class;
                headOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("head"));
                tailOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("tail"));
                cleanMeOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("cleanMe"));
            } catch (Exception e) {
                throw new Error(e);
            }
        }
```
存储结构：

```java
        static final class QNode {
            volatile QNode next;          // next node in queue
            volatile Object item;         // CAS'ed to or from null
            volatile Thread waiter;       // to control park/unpark
            final boolean isData;  // 是否是数据
			// 构造函数
            QNode(Object item, boolean isData) {
                this.item = item;
                this.isData = isData;
            }
			// 设置next值
            boolean casNext(QNode cmp, QNode val) {
                return next == cmp &&
                    UNSAFE.compareAndSwapObject(this, nextOffset, cmp, val);
            }
			// 设置item值		
            boolean casItem(Object cmp, Object val) {
                return item == cmp &&
                    UNSAFE.compareAndSwapObject(this, itemOffset, cmp, val);
            }

            // 设置item为自己,就是取消该节点
            void tryCancel(Object cmp) {
                UNSAFE.compareAndSwapObject(this, itemOffset, cmp, this);
            }
			// 判断节点是否取消
            boolean isCancelled() {
                return item == this;
            }

			// next指向自己就是删除节点
            boolean isOffList() {
                return next == this;
            }

            // Unsafe mechanics
            private static final sun.misc.Unsafe UNSAFE;
            private static final long itemOffset;
            private static final long nextOffset;

            static {
                try {
                    UNSAFE = sun.misc.Unsafe.getUnsafe();
                    Class<?> k = QNode.class;
                    itemOffset = UNSAFE.objectFieldOffset
                        (k.getDeclaredField("item"));
                    nextOffset = UNSAFE.objectFieldOffset
                        (k.getDeclaredField("next"));
                } catch (Exception e) {
                    throw new Error(e);
                }
            }
        }
```

#### 构造函数

```java
        TransferQueue() {
            QNode h = new QNode(null, false); // initialize to dummy node.
            head = h;
            tail = h;
        }
```



看一下次transfer具体实现把：

```java
		 	/* Basic algorithm is to loop trying to take either of
             * two actions:
             *
             * 1. If queue apparently empty or holding same-mode nodes,
             *    try to add node to queue of waiters, wait to be
             *    fulfilled (or cancelled) and return matching item.
             *
             * 2. If queue apparently contains waiting items, and this
             *    call is of complementary mode, try to fulfill by CAS'ing
             *    item field of waiting node and dequeuing it, and then
             *    returning matching item.
             *
             * In each case, along the way, check for and try to help
             * advance head and tail on behalf of other stalled/slow
             * threads.
             * The loop starts off with a null check guarding against
             * seeing uninitialized head or tail values. This never
             * happens in current SynchronousQueue, but could if
             * callers held non-volatile/final ref to the
             * transferer. The check is here anyway because it places
             * null checks at top of loop, which is usually faster
             * than having them implicitly interspersed.
             */ 		
		// e:放入的元素
		// timed：是否超时
		// nanos:超时时间
		E transfer(E e, boolean timed, long nanos) {
            QNode s = null; // constructed/reused as needed
            boolean isData = (e != null);
			// 下面for循环有两种情况
            // 队列同时有且只能有一种类型的节点
            // 1)添加数据
            	// 1. 已经有数据节点   --- 添加节点在后面,并阻塞线程
            	// 2. 没有数据节点	--- 添加节点到tail节点,并阻塞线程
            	// 3. 有等待获取数据的节点 -- 尝试匹配
            // 2)获取节点
            	// 1.有数据节点
            	// 2.没有数据节点且没有获取数据的节点	-- 添加节点到tail,并阻塞线程
            	// 3.同样要获取数据的节点   -- 添加节点后tail,并阻塞线程
            for (;;) {
                QNode t = tail;
                QNode h = head;
                // 头尾节点都为null，没有初始化
                if (t == null || h == null)         // saw uninitialized value
                    continue;                       // spin
                // 节点添加的情况
                if (h == t || t.isData == isData) { // empty or same-mode
                    QNode tn = t.next;
                    if (t != tail)                  // inconsistent read
                        continue;
                    // 更新tail指向,真正指向最后一个节点
                    if (tn != null) {               // lagging tail
                        advanceTail(t, tn);
                        continue;
                    }
                    // 超时直接返回null
                    if (timed && nanos <= 0)        // can't wait
                        return null;
                    // 新建节点，并添加到队列尾部
                    if (s == null)
                        s = new QNode(e, isData);
                    if (!t.casNext(null, s))        // failed to link in
                        continue;
					// 再次更新tail的值,使tail指向最后节点
                    advanceTail(t, s);              // swing tail and wait
                    // 使节点对应的线程等待
                    // 不论是添加数据节点,还是获取数据节点,到这里说明没有匹配上
                    // 节点对应的线程都会阻塞
                    Object x = awaitFulfill(s, e, timed, nanos);
                    // 节点被取消 或 节点的item值被修改  线程被唤醒继续执行
                    // x为返回的item，如果item==自己，说明节点被取消
                    if (x == s) {                   // wait was cancelled
                        clean(t, s);
                        return null;
                    }
					// 如果s节点没有被删除
                    if (!s.isOffList()) {           // not already unlinked
                        // 删除头节点，并设置s为头节点
                        advanceHead(t, s);          // unlink if head
                        if (x != null)              // and forget fields
                            s.item = s;
                        s.waiter = null;
                    }
                    return (x != null) ? (E)x : e;
				// 匹配节点模式
                  // 只有在队列中节点模式不同时才会运行这里,进行匹配操作
                } else {                            // complementary-mode
                    QNode m = h.next;               // node to fulfill
                    if (t != tail || m == null || h != head)
                        continue;                   // inconsistent read
                    Object x = m.item;
                    // 进行匹配:
                    // 1. m节点的item是否是null
                    // 2. x和m是否相等,也就是m是否已经被取消
                    // 3. 设置m的item为要添加的元素e, 也就是进行匹配;设置成功也就是匹配成功了
                    if (isData == (x != null) ||    // m already fulfilled
                        x == m ||                   // m cancelled
                        !m.casItem(x, e)) {         // lost CAS
                        advanceHead(h, m);          // dequeue and retry
                        continue;
                    }
					// 更新head节点
                    advanceHead(h, m);              // successfully fulfilled
                    LockSupport.unpark(m.waiter);
                    // 返回匹配到的数据值
                    return (x != null) ? (E)x : e;
                }
            }
        }
		// 设置tail的值为nt
        void advanceTail(QNode t, QNode nt) {
            if (tail == t)
                UNSAFE.compareAndSwapObject(this, tailOffset, t, nt);
        }
		// 设置head值为nh，并把h删除
        void advanceHead(QNode h, QNode nh) {
            if (h == head &&
                UNSAFE.compareAndSwapObject(this, headOffset, h, nh))
                h.next = h; // forget old next
        }
```

```java
        // 等待被匹配
		Object awaitFulfill(QNode s, E e, boolean timed, long nanos) {
            // 获取超时时间
            final long deadline = timed ? System.nanoTime() + nanos : 0L;
            Thread w = Thread.currentThread();
            // 获取自旋次数
            int spins = ((head.next == s) ?
                         (timed ? maxTimedSpins : maxUntimedSpins) : 0);
            for (;;) {
                if (w.isInterrupted())
                    s.tryCancel(e);
                Object x = s.item;
                if (x != e)
                    return x;
                // 如果超时则删除节点
                if (timed) {
                    nanos = deadline - System.nanoTime();
                    if (nanos <= 0L) {
                        s.tryCancel(e);
                        continue;
                    }
                }
                if (spins > 0)  // 先自旋
                    --spins;
                else if (s.waiter == null) // 设置此节点上的线程为当前线程
                    s.waiter = w;
                else if (!timed)  // 如果没有设置超时，则阻塞线程
                    LockSupport.park(this);
                else if (nanos > spinForTimeoutThreshold) // 设置了超时，则在时间内阻塞线程
                    LockSupport.parkNanos(this, nanos);
            }
        }
```

节点删除操作:

```java
        // 删除s节点
		void clean(QNode pred, QNode s) {
            s.waiter = null; // forget thread
            /*
             * At any given time, exactly one node on list cannot be
             * deleted -- the last inserted node. To accommodate this,
             * if we cannot delete s, we save its predecessor as
             * "cleanMe", deleting the previously saved version
             * first. At least one of node s or the node previously
             * saved can always be deleted, so this always terminates.
             */
            while (pred.next == s) { // Return early if already unlinked
                QNode h = head;
                QNode hn = h.next;   // Absorb cancelled first node as head
                // 跳过删除的节点
                if (hn != null && hn.isCancelled()) {
                    advanceHead(h, hn);
                    continue;
                }
                QNode t = tail;      // Ensure consistent read for tail
                if (t == h)
                    return;
                QNode tn = t.next;
                if (t != tail)
                    continue;
                // 更新tail,指向真正的最后节点
                if (tn != null) {
                    advanceTail(t, tn);
                    continue;
                }
                // 如果s不是最后的节点,则直接删除
                if (s != t) {        // If not tail, try to unsplice
                    QNode sn = s.next;
                    if (sn == s || pred.casNext(s, sn))
                        return;
                }
                // 当s为tail节点时,使用变量cleanMe记录s的前节点
                // 当合适的时候,s不再是tail节点时,再进行删除
                QNode dp = cleanMe;
                if (dp != null) {    // Try unlinking previous cancelled node
                    QNode d = dp.next;
                    QNode dn;
                    // 真正删除s节点
                    if (d == null ||               // d is gone or
                        d == dp ||                 // d is off list or
                        !d.isCancelled() ||        // d not cancelled or
                        (d != t &&                 // d not tail and
                         (dn = d.next) != null &&  //   has successor
                         dn != d &&                //   that is on list
                         dp.casNext(d, dn)))       // d unspliced
                        casCleanMe(dp, null);
                    if (dp == pred)
                        return;      // s is already saved node
                } else if (casCleanMe(null, pred))
                    return;          // Postpone cleaning s
            }
        }
```

