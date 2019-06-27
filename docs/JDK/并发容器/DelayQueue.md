# DelayQueue

## Field

```java
    private final transient ReentrantLock lock = new ReentrantLock();
    // 底层存储使用PriorityQueue实现
	private final PriorityQueue<E> q = new PriorityQueue<E>();
	// 等待的线程
    private Thread leader = null;
	// 元素可用条件等待队列
    private final Condition available = lock.newCondition();
```

## 构造器
```java
    public DelayQueue() {}

    public DelayQueue(Collection<? extends E> c) {
        this.addAll(c);
    }
```

## 添加元素

### add

```java
    public boolean add(E e) {
        return offer(e);
    }
```

### offer

元素添加，也解锁.

```java
    public boolean offer(E e) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 调用priorityQueue的offer
            q.offer(e);
            // 如果第一个元素就是添加的元素,则通知其他等待的线程
            if (q.peek() == e) {
                leader = null;
                available.signal();
            }
            return true;
        } finally {
            lock.unlock();
        }
    }
```

### put

```java
    public void put(E e) {
        offer(e);
    }
```



## 获取元素

### poll

```java
    public E poll() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            E first = q.peek();
            // 如果第一个元素为null 或 等待时间不到
            // 则返回null
            if (first == null || first.getDelay(NANOSECONDS) > 0)
                return null;
            else
                return q.poll();
        } finally {
            lock.unlock();
        }
    }
```

### take

```java
    public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            for (;;) {
                // 先获取第一个元素,如果第一个元素就为空,则线程等待
                E first = q.peek();
                if (first == null)
                    available.await();
                else {
                    // 第一次获取,需要等待指定时间,才能获取
                    long delay = first.getDelay(NANOSECONDS);
                    if (delay <= 0)
                        return q.poll();
                    first = null; // don't retain ref while waiting
                    // 如果等待时间没有到,则线程等待
                    // 并且把leader设置为的当前线程
                    if (leader != null)
                        available.await();
                    else {
                        Thread thisThread = Thread.currentThread();
                        leader = thisThread;
                        try {
                            available.awaitNanos(delay);
                        } finally {
                            if (leader == thisThread)
                                leader = null;
                        }
                    }
                }
            }
        } finally {
            if (leader == null && q.peek() != null)
                available.signal();
            lock.unlock();
        }
    }
```

### peek

peek直接获取,不会等待也不会导致线程阻塞.

```java
    public E peek() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return q.peek();
        } finally {
            lock.unlock();
        }
    }
```

由上可知，获取时也都需要加锁。

## 删除元素

```java
    public boolean remove(Object o) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return q.remove(o);
        } finally {
            lock.unlock();
        }
    }
```

底层仍然是调用priorityQueue的实现，也需要加锁。

## 遍历元素

```java
    public Iterator<E> iterator() {
        return new Itr(toArray());
    }

```

```java
    private class Itr implements Iterator<E> {
        final Object[] array; // Array of all elements
        int cursor;           // index of next element to return
        int lastRet;          // index of last element, or -1 if no such

        Itr(Object[] array) {  // 参数就是队列中元素,只是转换为了数组形式
            lastRet = -1;
            this.array = array;
        }
		// 判断是否有下一个
        public boolean hasNext() {
            return cursor < array.length;
        }
		// 下一个元素
        @SuppressWarnings("unchecked")
        public E next() {
            if (cursor >= array.length)
                throw new NoSuchElementException();
            // 直接从数组中获取
            lastRet = cursor;
            return (E)array[cursor++];
        }

        public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();
            removeEQ(array[lastRet]);
            lastRet = -1;
        }
    }
```

特点:

1. 所有的添加获取加锁实现
2. 底层使用PriorityQueue实现, 会使用自然排序
3. 第一次获取需要等待.