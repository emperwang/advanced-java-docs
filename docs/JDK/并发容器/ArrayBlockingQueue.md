# ArrayBlockingQueue

## Field

```java
    //  存储数据
    final Object[] items;

    // 要获取的数据的index
    int takeIndex;

    // 要放入数据的index
    int putIndex;

    // 元素的数量
    int count;

    /*
     * Concurrency control uses the classic two-condition algorithm
     * found in any textbook.
     */

    // 并发锁
    final ReentrantLock lock;

    // 不是空队列的条件队列
    private final Condition notEmpty;

    // 不是满队列的条件
    private final Condition notFull;

    /**
     * Shared state for currently active iterators, or null if there
     * are known not to be any.  Allows queue operations to update
     * iterator state.
     */
    transient Itrs itrs = null;
```





## 构造函数

```java
    public ArrayBlockingQueue(int capacity, boolean fair,
                              Collection<? extends E> c) {
        this(capacity, fair);
        final ReentrantLock lock = this.lock;
        lock.lock(); // 添加元素需要锁
        try {
            int i = 0;
            try {
                for (E e : c) {
                    checkNotNull(e);
                    items[i++] = e;
                }
            } catch (ArrayIndexOutOfBoundsException ex) {
                throw new IllegalArgumentException();
            }
            count = i;
            putIndex = (i == capacity) ? 0 : i;
        } finally {
            lock.unlock();
        }
    }
	// 都会调用此创建队列
    public ArrayBlockingQueue(int capacity, boolean fair) {
        if (capacity <= 0)
            throw new IllegalArgumentException();
        // 创建数组
        this.items = new Object[capacity];
        // 创建锁，根据参数创建是否是否是公平锁
        lock = new ReentrantLock(fair);
        // 创建两个条件等待队列
        notEmpty = lock.newCondition();
        notFull =  lock.newCondition();
    }
	// 指定容器大小
    public ArrayBlockingQueue(int capacity) {
        this(capacity, false);
    }
```



## 添加数据

### add 函数

```java
   // add添加失败  会报错
	public boolean add(E e) {
        return super.add(e);
    }
	// 父函数添加
    public boolean add(E e) {
        if (offer(e))
            return true;
        else
            throw new IllegalStateException("Queue full");
    }
	// 最终调用此函数进行添加操作
    public boolean offer(E e) {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        // 添加操作需要上锁
        lock.lock();
        try {
            	// 队列满了，则添加失败
            if (count == items.length)
                return false;
            else {
                enqueue(e);
                return true;
            }
        } finally {
            lock.unlock();
        }
    }

    private void enqueue(E x) {
        // 获取数组
        final Object[] items = this.items;
        // 根据putIndex的添加
        items[putIndex] = x;
        // putIndex会回滚
        if (++putIndex == items.length)
            putIndex = 0;
        // 元素数量加1
        count++;
        // 唤醒需要获取数据的队列
        notEmpty.signal();
    }
```



### offer 函数

```java
	// 最终调用此函数进行添加操作
    public boolean offer(E e) {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        // 添加操作需要上锁
        lock.lock();
        try {
            	// 队列满了，则添加失败
            if (count == items.length)
                return false;
            else {
                enqueue(e);
                return true;
            }
        } finally {
            lock.unlock();
        }
    }
```



### put函数

由此可见，当队列满了，put会等待队列不满时再次插入。

```java
    public void put(E e) throws InterruptedException {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            // 等待队列不满，再次插入
            while (count == items.length)
                notFull.await();
            enqueue(e);
        } finally {
            lock.unlock();
        }
    }
```





## 获取数据

### poll

```java
    // 如果队列没有元素，poll不会等待，直接返回null
	// 有元素，返回得到的元素，并把元素删除
	public E poll() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return (count == 0) ? null : dequeue();
        } finally {
            lock.unlock();
        }
    }

    private E dequeue() {
        final Object[] items = this.items;
        @SuppressWarnings("unchecked")
        // 获取takeIndex位置上的元素
        E x = (E) items[takeIndex];
        // 并删除元素
        items[takeIndex] = null;
        if (++takeIndex == items.length)
            takeIndex = 0;
        count--;
        if (itrs != null)
            itrs.elementDequeued();
        notFull.signal();
        return x;
    }
```



### take

```java
    // 当队列为空，take会等待队列有元素
	// 当队列有元素，返回获取的元素，并把元素删除
	public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            // 如果队列为空，则等待队列有元素，再去获取
            while (count == 0)
                notEmpty.await();
            return dequeue();
        } finally {
            lock.unlock();
        }
    }
```

### peek

```java
    // 不会检查，直接返回对应位置的元素。
	public E peek() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return itemAt(takeIndex); // null when queue is empty
        } finally {
            lock.unlock();
        }
    }
    final E itemAt(int i) {
        return (E) items[i];
    }
```



## 删除数据

```java
    // 从队列中删除指定元素
	public boolean remove(Object o) {
        if (o == null) return false;
        final Object[] items = this.items;
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            if (count > 0) {
                // 获取putIndex(可以代表有效元素的最后一个) 和 takeIndex(可以代表有效元素的第一个)
                final int putIndex = this.putIndex;
                int i = takeIndex;
                do {// 编列列表找到相等的元素
                    if (o.equals(items[i])) {
                        // 删除对应索引的元素
                        removeAt(i);
                        return true;
                    }
                    if (++i == items.length)
                        i = 0;
                } while (i != putIndex);
            }
            return false;
        } finally {
            lock.unlock();
        }
    }

	// 删除对应索引的元素
    void removeAt(final int removeIndex) {
        // assert lock.getHoldCount() == 1;
        // assert items[removeIndex] != null;
        // assert removeIndex >= 0 && removeIndex < items.length;
        // 获取存储元素的数组
        final Object[] items = this.items;
        if (removeIndex == takeIndex) {
            // 直接删除对应位置上的数据
            items[takeIndex] = null;
            if (++takeIndex == items.length)
                takeIndex = 0;
            count--;
            if (itrs != null)
                itrs.elementDequeued();
        } else {
            // slide over all others up through putIndex.
            final int putIndex = this.putIndex;
            for (int i = removeIndex;;) {
                int next = i + 1;
                if (next == items.length)
                    next = 0;
                // 这个操作相当把removeIndex后面所有元素向前移动一位
                if (next != putIndex) {
                    items[i] = items[next];
                    i = next;
                } else {
                    items[i] = null;
                    this.putIndex = i;
                    break;
                }
            }
            count--;
            if (itrs != null)
                itrs.removedAt(removeIndex);
        }
        notFull.signal();
    }
```



## 遍历容器

```java
    public Iterator<E> iterator() {
        return new Itr();
    }
```

### 内部遍历器实现类

#### field

```java
        /** Index to look for new nextItem; NONE at end */
		// 下一个元素的index
        private int cursor;

        /** Element to be returned by next call to next(); null if none */
		// 下一个元素
        private E nextItem;

        /** Index of nextItem; NONE if none, REMOVED if removed elsewhere */
		// 下一个元素的index
        private int nextIndex;

        /** Last element returned; null if none or not detached. */
		// 上次返回的元素
        private E lastItem;

        /** Index of lastItem, NONE if none, REMOVED if removed elsewhere */
		// 上次返回元素的index
        private int lastRet;

        /** Previous value of takeIndex, or DETACHED when detached */
		// takeIndex的前一个index
        private int prevTakeIndex;

        /** Previous value of iters.cycles */
        private int prevCycles;
		// 标识元素不可用  或 未定义
        private static final int NONE = -1;
		// 标识原始 被删除
        private static final int REMOVED = -2;

        /** Special value for prevTakeIndex indicating "detached mode" */
        private static final int DETACHED = -3;
```

#### 构造器

```java
		 	Itr() {
            // assert lock.getHoldCount() == 0;
            lastRet = NONE;
            final ReentrantLock lock = ArrayBlockingQueue.this.lock;
            lock.lock();
            try {
                if (count == 0) {
                    // 没有原始 各个fiel的值
                    cursor = NONE;
                    nextIndex = NONE;
                    prevTakeIndex = DETACHED;
                } else {
                    final int takeIndex = ArrayBlockingQueue.this.takeIndex;
                    // 可以看到  prevTakeIndex就是takeIndex
                    prevTakeIndex = takeIndex;
                    // 获取takeIndex的值
                    nextItem = itemAt(nextIndex = takeIndex);
                    // takeIndex+1
                    cursor = incCursor(takeIndex);
                    if (itrs == null) {
                        itrs = new Itrs(this);
                    } else {
                        itrs.register(this); // in this order
                        itrs.doSomeSweeping(false);
                    }
                    prevCycles = itrs.cycles;
                    // assert takeIndex >= 0;
                    // assert prevTakeIndex == takeIndex;
                    // assert nextIndex >= 0;
                    // assert nextItem != null;
                }
            } finally {
                lock.unlock();
            }
        }
```



#### hasNext

```java
    // 是否有下一个元素    
	public boolean hasNext() {
            if (nextItem != null)
                return true;
            noNext();
            return false;
        }

        private void noNext() {
            final ReentrantLock lock = ArrayBlockingQueue.this.lock;
            lock.lock();
            try {
                // assert cursor == NONE;
                // assert nextIndex == NONE;
                if (!isDetached()) {
                    // assert lastRet >= 0;
                    incorporateDequeues(); // might update lastRet
                    if (lastRet >= 0) {
                        lastItem = itemAt(lastRet);
                        // assert lastItem != null;
                        detach();
                    }
                }
                // assert isDetached();
                // assert lastRet < 0 ^ lastItem != null;
            } finally {
                lock.unlock();
            }
        }
		// 是否时Detached模式
        boolean isDetached() {
            return prevTakeIndex < 0;
        }

        private void incorporateDequeues() {
            final int cycles = itrs.cycles;
            final int takeIndex = ArrayBlockingQueue.this.takeIndex;
            final int prevCycles = this.prevCycles;
            final int prevTakeIndex = this.prevTakeIndex;

            if (cycles != prevCycles || takeIndex != prevTakeIndex) {
                final int len = items.length;
                // how far takeIndex has advanced since the previous
                // operation of this iterator
                long dequeues = (cycles - prevCycles) * len
                    + (takeIndex - prevTakeIndex);

                // Check indices for invalidation
                if (invalidated(lastRet, prevTakeIndex, dequeues, len))
                    lastRet = REMOVED;
                if (invalidated(nextIndex, prevTakeIndex, dequeues, len))
                    nextIndex = REMOVED;
                if (invalidated(cursor, prevTakeIndex, dequeues, len))
                    cursor = takeIndex;
				// 都小于0  则处于Detach状态
                if (cursor < 0 && nextIndex < 0 && lastRet < 0)
                    detach();
                else {
                    this.prevCycles = cycles;
                    this.prevTakeIndex = takeIndex;
                }
            }
        }
		// index 要检验的值
		// prevTakeIndex 如名字
		// dequeues	已经出列的元素数量
		// length 队列的长度
        private boolean invalidated(int index, int prevTakeIndex,
                                    long dequeues, int length) {
            if (index < 0)
                return false;
            // index和prevTakeIndex之间差多少个元素
            int distance = index - prevTakeIndex;
            if (distance < 0)
                distance += length;
            return dequeues > distance;
        }
```



#### next

```java
        public E next() {
            final E x = nextItem;
            if (x == null)
                throw new NoSuchElementException();
            final ReentrantLock lock = ArrayBlockingQueue.this.lock;
            lock.lock();
            try {
                if (!isDetached())
                    incorporateDequeues();
                // 获取上次返回的元素的index
                lastRet = nextIndex;
                final int cursor = this.cursor;
                if (cursor >= 0) {
                    // 获取下次的item
                    nextItem = itemAt(nextIndex = cursor);
                    // cursor+1
                    this.cursor = incCursor(cursor);
                } else {
                    // 不然就是没有元素了
                    nextIndex = NONE;
                    nextItem = null;
                }
            } finally {
                lock.unlock();
            }
            return x;
        }
```

再来看一下这个ltrs内部类是个啥?

### ltrs

#### Field

```java
		/** Incremented whenever takeIndex wraps around to 0 */
        int cycles = 0;

        /** Linked list of weak iterator references */
        private Node head;

        /** Used to expunge stale iterators */
        private Node sweeper = null;

        private static final int SHORT_SWEEP_PROBES = 4;
        private static final int LONG_SWEEP_PROBES = 16;
```



#### 构造器

```java
       Itrs(Itr initial) {
            register(initial);
        }
```

看下此函数:

```java
        void register(Itr itr) {
            // assert lock.getHoldCount() == 1;
            head = new Node(itr, head);
        }
```

哟？又是一个内部类，在深入看:

```java
        private class Node extends WeakReference<Itr> {
            Node next;

            Node(Itr iterator, Node next) {
                super(iterator);
                this.next = next;
            }
        }
```

这里是个弱引用对象，弱引用引用的对象就是遍历器。也就是虽然ltrs可以有多个遍历器，但是因为每个遍历器都是弱引用，会被回收。



