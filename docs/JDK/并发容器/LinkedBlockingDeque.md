# LinkedBlockingDeque

## Field

```java
    // 第一个节点
	transient Node<E> first;
	// 最后一个节点
    transient Node<E> last;
	// 队列中存储元素个数
    private transient int count;
	// 最大容量
    private final int capacity;
	// 非公平锁
    final ReentrantLock lock = new ReentrantLock();
	// 条件等待队列
    private final Condition notEmpty = lock.newCondition();
    private final Condition notFull = lock.newCondition();
```

存储结构:

```java
    static final class Node<E> {
        E item;  // 存储的元素
        Node<E> prev; // 前节点
        Node<E> next; // 后节点
        Node(E x) {
            item = x;
        }
    }
```



## 构造函数

```java
    // 使用最大容量构建容器
	public LinkedBlockingDeque() {
        this(Integer.MAX_VALUE);
    }
	// 指定容器容量
    public LinkedBlockingDeque(int capacity) {
        if (capacity <= 0) throw new IllegalArgumentException();
        this.capacity = capacity;
    }
	// 把制定元素加入到构建的容器中
    public LinkedBlockingDeque(Collection<? extends E> c) {
        this(Integer.MAX_VALUE);
        final ReentrantLock lock = this.lock;
        lock.lock(); // Never contended, but necessary for visibility
        try {
            for (E e : c) {
                if (e == null)
                    throw new NullPointerException();
                if (!linkLast(new Node<E>(e)))
                    throw new IllegalStateException("Deque full");
            }
        } finally {
            lock.unlock();
        }
    }
```



##　添加元素

### add

```java
    // 调用offer进行添加,添加失败会报错
	public void addFirst(E e) {
        if (!offerFirst(e))
            throw new IllegalStateException("Deque full");
    }
```

```java
    public void addLast(E e) {
        if (!offerLast(e))
            throw new IllegalStateException("Deque full");
    }
```

### offer

```java
   // 从开头添加元素 ; 加锁添加
	public boolean offerFirst(E e) {
        if (e == null) throw new NullPointerException();
        Node<E> node = new Node<E>(e);
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return linkFirst(node);
        } finally {
            lock.unlock();
        }
    }
```

```java
    // 从尾节点添加元素 ; 并加锁
	public boolean offerLast(E e) {
        if (e == null) throw new NullPointerException();
        Node<E> node = new Node<E>(e);
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return linkLast(node);
        } finally {
            lock.unlock();
        }
    }
```



### put

```java
    // 从头添加元素; 如果添加不成功,则等待继续添加
	public void putFirst(E e) throws InterruptedException {
        if (e == null) throw new NullPointerException();
        Node<E> node = new Node<E>(e);
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            while (!linkFirst(node))
                notFull.await();
        } finally {
            lock.unlock();
        }
    }
```

```java
   public void putLast(E e) throws InterruptedException {
        if (e == null) throw new NullPointerException();
        Node<E> node = new Node<E>(e);
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            while (!linkLast(node))
                notFull.await();
        } finally {
            lock.unlock();
        }
    }
```

区别:

* add调用offer进行添加,但是添加失败或报错
* offer 直接添加,会返回添加是否成功
* put 容器满了,则等待容器不满时继续添加

```java
    // 具体添加操作实现
	private boolean linkFirst(Node<E> node) {
        // 容器满了,则返回false ,添加失败
        if (count >= capacity)
            return false;
        // 获取第一个节点
        Node<E> f = first;
        // 把node添加到链表的第一个
        node.next = f;
        first = node;
        if (last == null)
            last = node;
        else
            f.prev = node;
        // 容器元素数量增加
        ++count;
        notEmpty.signal();
        return true;
    }
```

```java
    private boolean linkLast(Node<E> node) {
        // 容量满了,则添加失败
        if (count >= capacity)
            return false;
        // 获取最后一个节点
        Node<E> l = last;
        // 把node添加到最后一个节点
        node.prev = l;
        last = node;
        if (first == null)
            first = node;
        else
            l.next = node;
        // 数量增加
        ++count;
        notEmpty.signal();
        return true;
    }
```



## 获取元素

### poll

获取元素时加锁,之后把获取的元素删除;   不会进行等待

```java
    public E pollFirst() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return unlinkFirst();
        } finally {
            lock.unlock();
        }
    }
	// 删除第一个节点,并返回节点的item值
    private E unlinkFirst() {
        // 获取第一个节点,节点为null则返回null
        Node<E> f = first;
        if (f == null)
            return null;
        Node<E> n = f.next;
        // 获取第一个节点的item值,并把此节点从链表中删除
        E item = f.item;
        f.item = null;
        f.next = f; // help GC
        // 更新第一个节点的值
        first = n;
        if (n == null)
            last = null;
        else
            n.prev = null;
        --count;
        notFull.signal();
        return item;
    }
```

```java
    public E pollLast() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return unlinkLast();
        } finally {
            lock.unlock();
        }
    }

    private E unlinkLast() {
        // 获取最后一个节点的值
        Node<E> l = last;
        if (l == null)
            return null;
        Node<E> p = l.prev;
        // 获取最后一个节点的值,并把此节点从链表中删除
        E item = l.item;
        l.item = null;
        l.prev = l; // help GC
        // 更新最后一个节点
        last = p;
        if (p == null)
            first = null;
        else
            p.next = null;
        --count;
        notFull.signal();
        return item;
    }
```

### take

获取元素时加锁

如果链表为空,则等待链表不为空时, 继续获取;

```java
    public E takeFirst() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            E x;
            // 如果获取失败,则线程等待链表不为空,继续获取
            while ( (x = unlinkFirst()) == null)
                notEmpty.await();
            return x;
        } finally {
            lock.unlock();
        }
    }

```

```java
    public E takeLast() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            E x;
            while ( (x = unlinkLast()) == null)
                notEmpty.await();
            return x;
        } finally {
            lock.unlock();
        }
    }
```

### peek

直接读取第一个或最后一个节点的值, 链表为空,则直接返回null,  不会等待.

不会把节点从链表中删除

```java
    public E peekFirst() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 直接返回第一个节点的值;不进行删除操作
            return (first == null) ? null : first.item;
        } finally {
            lock.unlock();
        }
    }

```

```java
    public E peekLast() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return (last == null) ? null : last.item;
        } finally {
            lock.unlock();
        }
    }
```


## 删除元素

```java
    public E removeFirst() {
        // 把第一个元素删除
        E x = pollFirst();
        if (x == null) throw new NoSuchElementException();
        return x;
    }
```

```java
    public E removeLast() {
        E x = pollLast();
        if (x == null) throw new NoSuchElementException();
        return x;
    }
```

```java
    public boolean remove(Object o) {
        return removeFirstOccurrence(o);
    }

    public boolean removeFirstOccurrence(Object o) {
        if (o == null) return false;
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 遍历链表找到对应的节点
            for (Node<E> p = first; p != null; p = p.next) {
                if (o.equals(p.item)) {
                    // 把该节点删除
                    unlink(p);
                    return true;
                }
            }
            return false;
        } finally {
            lock.unlock();
        }
    }

    void unlink(Node<E> x) {
        // 获取要删除节点的前后节点
        Node<E> p = x.prev;
        Node<E> n = x.next;
        if (p == null) {
            unlinkFirst();
        } else if (n == null) {
            unlinkLast();
        } else {
            // 把节点删除
            p.next = n;
            n.prev = p;
            x.item = null;
            --count;
            notFull.signal();
        }
    }
```



## 遍历元素

```java
    public Iterator<E> iterator() {
        return new Itr();
    }
```

```java
    private class Itr extends AbstractItr {
        Node<E> firstNode() { return first; }
        Node<E> nextNode(Node<E> n) { return n.next; }
    }
```

```java
    private abstract class AbstractItr implements Iterator<E> {
		// 下次遍历要操作的节点
        Node<E> next;
		// 下一个节点的值
        E nextItem;
		// 上次返回的节点
        private Node<E> lastRet;
		// 获取第一个节点
        abstract Node<E> firstNode();
        // 获取下一个节点
        abstract Node<E> nextNode(Node<E> n);

        AbstractItr() {
            final ReentrantLock lock = LinkedBlockingDeque.this.lock;
            lock.lock();
            try {
                // 初始化为第一个节点及其值
                next = firstNode();
                nextItem = (next == null) ? null : next.item;
            } finally {
                lock.unlock();
            }
        }

        // 获取n的下一个有效节点
        private Node<E> succ(Node<E> n) {
            for (;;) {
                Node<E> s = nextNode(n);
                if (s == null)
                    return null;
                else if (s.item != null)
                    return s;
                else if (s == n)
                    return firstNode();
                else
                    n = s;
            }
        }
		// 获取下一个节点
        void advance() {
            final ReentrantLock lock = LinkedBlockingDeque.this.lock;
            lock.lock();
            try {
                next = succ(next);
                nextItem = (next == null) ? null : next.item;
            } finally {
                lock.unlock();
            }
        }
		// 是否有下一个节点
        public boolean hasNext() {
            return next != null;
        }
		// 下一个节点
        public E next() {
            if (next == null)
                throw new NoSuchElementException();
            lastRet = next;
            E x = nextItem;
            advance();
            return x;
        }
		// 删除操作
        public void remove() {
            Node<E> n = lastRet;
            if (n == null)
                throw new IllegalStateException();
            lastRet = null;
            final ReentrantLock lock = LinkedBlockingDeque.this.lock;
            lock.lock();
            try {
                if (n.item != null)
                    unlink(n);
            } finally {
                lock.unlock();
            }
        }
    }
```

