# LinkedBlockingQueue

## Field

```java
	 // 容量
    private final int capacity;

    /** Current number of elements */
	// 当前容器中元素数量
    private final AtomicInteger count = new AtomicInteger();

	// 头结点
    transient Node<E> head;
	// 尾节点
    private transient Node<E> last;

    // 获取元素锁
    private final ReentrantLock takeLock = new ReentrantLock();

    // 获取元素,队列空的等待条件队列
    private final Condition notEmpty = takeLock.newCondition();

    // 放置元素锁
    private final ReentrantLock putLock = new ReentrantLock();

    // 放置元素--队列满的等待条件队列
    private final Condition notFull = putLock.newCondition();
```

## 封装存储结构

```java
    static class Node<E> {
        E item;  // 存储具体的元素
        /**
         * One of:
         * - the real successor Node
         * - this Node, meaning the successor is head.next
         * - null, meaning there is no successor (this is the last node)
         */
        Node<E> next;  // 指向下一个元素  可见此链表是单链表

        Node(E x) { item = x; }
    }

```



## 构造函数

```java
    public LinkedBlockingQueue() {
        this(Integer.MAX_VALUE);   // 默认容量大小为最大值
    }
	// 指定容量
    public LinkedBlockingQueue(int capacity) {
        if (capacity <= 0) throw new IllegalArgumentException();
        this.capacity = capacity;
        last = head = new Node<E>(null);
    }
	// 创建容器,并放置一些元素进入
    public LinkedBlockingQueue(Collection<? extends E> c) {
        // 先使用最大容量创建容器
        this(Integer.MAX_VALUE);
        final ReentrantLock putLock = this.putLock;
        //添加前锁定
        putLock.lock(); // Never contended, but necessary for visibility
        try {
            int n = 0;
            for (E e : c) { // 遍历添加元素
                if (e == null)
                    throw new NullPointerException();
                if (n == capacity)
                    throw new IllegalStateException("Queue full");
                enqueue(new Node<E>(e));
                ++n;
            }
            count.set(n);
        } finally {
            putLock.unlock();
        }
    }
```



## 添加元素

### put添加

```java
    public void put(E e) throws InterruptedException {
        if (e == null) throw new NullPointerException();
        int c = -1;
        Node<E> node = new Node<E>(e); // 创建节点，封装元素
        final ReentrantLock putLock = this.putLock;
        final AtomicInteger count = this.count;
        putLock.lockInterruptibly();  // 当前所可被中断
        try {
            // 如果队列满 则等待 
            while (count.get() == capacity) {
                notFull.await();
            }
            // 添加元素
            enqueue(node);
            // 数量增加
            c = count.getAndIncrement();
            if (c + 1 < capacity)
                notFull.signal();
        } finally {
            putLock.unlock();
        }
        if (c == 0)
            signalNotEmpty();
    }
	// 把节点放到最后一个
    private void enqueue(Node<E> node) {
        last = last.next = node;
    }
```



###　offer添加

```java
    public boolean offer(E e) {
        if (e == null) throw new NullPointerException();
        final AtomicInteger count = this.count;
        // 注意,不会等待
        if (count.get() == capacity) // 如果容量达到最大,则添加失败;
            return false;
        int c = -1;
        Node<E> node = new Node<E>(e);
        final ReentrantLock putLock = this.putLock;
        // 不可中断锁
        putLock.lock();
        try {
            if (count.get() < capacity) {
                enqueue(node);
                c = count.getAndIncrement();
                if (c + 1 < capacity)
                    notFull.signal();
            }
        } finally {
            putLock.unlock();
        }
        if (c == 0)
            signalNotEmpty();
        return c >= 0;
    }
```

可以看到put和offer有些区别:

1. put在队列满时会等待,offer直接返回添加失败,不会等待
2. put使用的是可中断锁, offer不是

## 获取元素

### take

```java
    public E take() throws InterruptedException {
        E x;
        int c = -1;
        final AtomicInteger count = this.count;
        final ReentrantLock takeLock = this.takeLock;
        takeLock.lockInterruptibly(); // 中断锁
        try {
            // 如果队列为空,则等等待队列不为空
            while (count.get() == 0) {
                notEmpty.await();
            }
            // 获取元素
            x = dequeue();
            // 容量减少1
            c = count.getAndDecrement();
            // 唤醒其他等待获取元素的线程
            if (c > 1)
                notEmpty.signal();
        } finally {
            takeLock.unlock();
        }
        if (c == capacity)
            signalNotFull();
        return x;
    }
	// 获取元素值
    private E dequeue() {
		// 获取head节点
        Node<E> h = head;
        // 得到下一个节点
        Node<E> first = h.next;
        h.next = h; // help GC
        head = first;
        // 获取元素值
        E x = first.item;
        // 元素值置空
        first.item = null;
        return x;
    }
```



### poll

```java
    public E poll() {
        final AtomicInteger count = this.count;
        if (count.get() == 0) // 如果队列为空,直接返回null
            return null;
        E x = null;
        int c = -1;
        final ReentrantLock takeLock = this.takeLock;
        takeLock.lock();
        try {
            // 获取元素,并把容量减少1, 并通知其他等待获取元素的线程
            if (count.get() > 0) {
                x = dequeue();
                c = count.getAndDecrement();
                if (c > 1)
                    notEmpty.signal();
            }
        } finally {
            takeLock.unlock();
        }
        if (c == capacity)
            signalNotFull();
        return x;
    }

```



### peek

```java
    public E peek() {
        if (count.get() == 0) // 队列空,直接返回
            return null;
        final ReentrantLock takeLock = this.takeLock;
        takeLock.lock();
        try {
            // 获取头结点的下一个元素
            Node<E> first = head.next;
            if (first == null) // 如果值为空,则返回null;  否则返回节点的值
                return null;
            else
                return first.item;
        } finally {
            takeLock.unlock();
        }
    }
```

其三中获取元素还是区别挺大的:

1. take在队列为空时,要等待去获取元素;  poll 和peek不会等待
2. take使用的是可中断锁, poll和peek不可中断
3. take和poll获取到元素后会通知其他等待线程, peek不会



## 删除元素

```java
    public boolean remove(Object o) {
        if (o == null) return false;
        // 可见删除元素期间,不能在读取或者放入元素
        fullyLock();
        try {
            // 遍历链表找到相等的元素,然后把其删除
            for (Node<E> trail = head, p = trail.next;
                 p != null;
                 trail = p, p = p.next) {
                if (o.equals(p.item)) {
                    unlink(p, trail);
                    return true;
                }
            }
            return false;
        } finally {
            fullyUnlock();
        }
    }
	// p为要删除的元素
	// trail为其前一个元素
    void unlink(Node<E> p, Node<E> trail) {
        p.item = null; // 置空p的内容
        trail.next = p.next; // 把p的前一个元素指向p的下一个元素,从队列中删除了p节点
        if (last == p)
            last = trail;
        if (count.getAndDecrement() == capacity)
            notFull.signal();
    }
```



## 遍历元素

```java
    // 返回一个遍历器
	public Iterator<E> iterator() {
        return new Itr();
    }
	// 实现遍历内容的内部类
    private class Itr implements Iterator<E> {
        private Node<E> current; // 记录当前遍历要操作的节点
        private Node<E> lastRet; // 存储上次返回的节点
        private E currentElement; // 当前要操作节点的节点内容

        Itr() {
            fullyLock(); // 创建遍历期间,放入和读取全部锁住
            try {
                current = head.next;
                if (current != null)
                    currentElement = current.item;
            } finally {
                fullyUnlock();
            }
        }
		// 是否有下一个元素
        public boolean hasNext() {
            return current != null;
        }


        // 下一个节点
        private Node<E> nextNode(Node<E> p) {
            for (;;) {// 遍历找到下一个live的节点
                Node<E> s = p.next;
                // p.next=p
                // 说明p为删除的节点
                if (s == p)
                    return head.next;
                if (s == null || s.item != null)
                    return s;
                p = s;
            }
        }
		// 获取下一个节点
        public E next() {
            fullyLock();
            try {
                if (current == null)
                    throw new NoSuchElementException();
                // 获取当前操作节点的内容
                E x = currentElement;
                // 更新上次返回节点
                lastRet = current;
                // 获取下一个节点
                current = nextNode(current);
                currentElement = (current == null) ? null : current.item;
                return x;
            } finally {
                fullyUnlock();
            }
        }
		// 删除节点
        public void remove() {
            if (lastRet == null)
                throw new IllegalStateException();
            fullyLock();
            try {
                Node<E> node = lastRet;
                lastRet = null;
                // 遍历找到相等的节点
                for (Node<E> trail = head, p = trail.next;
                     p != null;
                     trail = p, p = p.next) {
                    if (p == node) {
                        // 把节点从队列中删除
                        unlink(p, trail);
                        break;
                    }
                }
            } finally {
                fullyUnlock();
            }
        }
    }
```

