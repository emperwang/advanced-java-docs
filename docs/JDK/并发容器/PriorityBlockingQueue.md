# PriorityBlockingQueue

## Field

```java
    // 默认容量
	private static final int DEFAULT_INITIAL_CAPACITY = 11;
    // 最大容量
	private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
    // 二叉堆数据结构
	private transient Object[] queue;
	// 元素个数
    private transient int size;
	// 比较器
    private transient Comparator<? super E> comparator;
	// 锁
    private final ReentrantLock lock;
	// 非空条件
    private final Condition notEmpty;
	// 自旋次数
    private transient volatile int allocationSpinLock;
    private PriorityQueue<E> q;
	// CAS操作
    private static final sun.misc.Unsafe UNSAFE;
    private static final long allocationSpinLockOffset;
```

静态初始化代码:

```java
    static {
        try {
            UNSAFE = sun.misc.Unsafe.getUnsafe();
            Class<?> k = PriorityBlockingQueue.class;
            allocationSpinLockOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("allocationSpinLock"));
        } catch (Exception e) {
            throw new Error(e);
        }
    }
```

## 构造器

```java
    public PriorityBlockingQueue(int initialCapacity,
                                 Comparator<? super E> comparator) {
        if (initialCapacity < 1)
            throw new IllegalArgumentException();
        // 创建锁
        this.lock = new ReentrantLock();
        this.notEmpty = lock.newCondition();
        // 比较器
        this.comparator = comparator;
        // 初始化数组
        this.queue = new Object[initialCapacity];
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

```java
    public boolean offer(E e) {
        if (e == null)
            throw new NullPointerException();
        final ReentrantLock lock = this.lock;
        lock.lock();
        int n, cap;
        Object[] array;
        // 如果元素>=容器长度了,就进行扩容
        while ((n = size) >= (cap = (array = queue).length))
            tryGrow(array, cap);
        try {
            Comparator<? super E> cmp = comparator;
            // 二叉堆添加元素
            if (cmp == null)
                siftUpComparable(n, e, array);
            else
                siftUpUsingComparator(n, e, array, cmp);
            size = n + 1;
            notEmpty.signal();
        } finally {
            lock.unlock();
        }
        return true;
    }

	// 使用默认比较器,自然比较法
    private static <T> void siftUpComparable(int k, T x, Object[] array) {
        Comparable<? super T> key = (Comparable<? super T>) x;
        while (k > 0) {
            int parent = (k - 1) >>> 1; // (k-1)/2是父节点，2*k+1,2*(k+1) 是子节点
            Object e = array[parent];
            if (key.compareTo((T) e) >= 0) // 跟二叉堆算法有关
                break;
            array[k] = e; // 在对应位置放入元素
            k = parent;
        }
        array[k] = key;
    }
	// 使用比较器
    private static <T> void siftUpUsingComparator(int k, T x, Object[] array,
                                       Comparator<? super T> cmp) {
        while (k > 0) {
            int parent = (k - 1) >>> 1;
            Object e = array[parent];
            if (cmp.compare(x, (T) e) >= 0) // 还是二叉法,不过使用指定的比较器进行比较
                break;
            array[k] = e;
            k = parent;
        }
        array[k] = x;
    }
```

### put

```java
    public void put(E e) {
        offer(e); // never need to block
    }
```

可见offer才是关键实现。

扩容操作:

```java
    private void tryGrow(Object[] array, int oldCap) {
        lock.unlock(); // must release and then re-acquire main lock
        Object[] newArray = null;
        // CAS 锁
        if (allocationSpinLock == 0 &&
            UNSAFE.compareAndSwapInt(this, allocationSpinLockOffset,
                                     0, 1)) {
            try {
                // 可见小于64时,每次是 oldCap*2+2
                // 大于64后,每次扩容一半
                int newCap = oldCap + ((oldCap < 64) ?
                                       (oldCap + 2) : // grow faster if small
                                       (oldCap >> 1));
                if (newCap - MAX_ARRAY_SIZE > 0) {    // possible overflow
                    int minCap = oldCap + 1;
                    if (minCap < 0 || minCap > MAX_ARRAY_SIZE)
                        throw new OutOfMemoryError();
                    newCap = MAX_ARRAY_SIZE;
                }
                // 扩容
                if (newCap > oldCap && queue == array)
                    newArray = new Object[newCap];
            } finally {
                allocationSpinLock = 0;
            }
        }
        if (newArray == null) // back off if another thread is allocating
            Thread.yield();
        lock.lock();
        if (newArray != null && queue == array) {
            queue = newArray;
            System.arraycopy(array, 0, newArray, 0, oldCap);
        }
    }
```



## 获取元素

### poll

```java
    public E poll() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 获取第一个元素,并删除
            return dequeue();
        } finally {
            lock.unlock();
        }
    }

    private E dequeue() {
        int n = size - 1;
        if (n < 0)
            return null;
        else {
            // 获取数组
            Object[] array = queue;
            // 获取第一个元素
            E result = (E) array[0];
            // 获取最后一个元素
            E x = (E) array[n];
            // 并把最后一个元素删除
            array[n] = null;
            Comparator<? super E> cmp = comparator;
            // 二叉堆的删除
            if (cmp == null)
                siftDownComparable(0, x, array, n);
            else
                siftDownUsingComparator(0, x, array, n, cmp);
            size = n;
            return result;
        }
    }
	// 二叉堆的删除实现
    private static <T> void siftDownComparable(int k, T x, Object[] array,
                                               int n) {
        if (n > 0) {
            Comparable<? super T> key = (Comparable<? super T>)x;
            int half = n >>> 1;           // loop while a non-leaf
            // 因此删除了第一个节点,所以要从k的子节点中找出最小的节点,放到k的位置上,不然二叉树就没有根了
            // 一步一步把小的值类似冒泡一样传递上来
            while (k < half) {
                int child = (k << 1) + 1; // 左子节点
                Object c = array[child];
                int right = child + 1; // 右子节点
                if (right < n &&
                    ((Comparable<? super T>) c).compareTo((T) array[right]) > 0)
                    c = array[child = right];
                if (key.compareTo((T) c) <= 0)
                    break;
                array[k] = c;
                k = child;
            }
            array[k] = key;
        }
    }
	// 这里也是一样的功能了, 区别就是使用的是指定的比较器
    private static <T> void siftDownUsingComparator(int k, T x, Object[] array,
                                                    int n,
                                                    Comparator<? super T> cmp) {
        if (n > 0) {
            int half = n >>> 1;
            while (k < half) {
                int child = (k << 1) + 1;
                Object c = array[child];
                int right = child + 1;
                if (right < n && cmp.compare((T) c, (T) array[right]) > 0)
                    c = array[child = right];
                if (cmp.compare(x, (T) c) <= 0)
                    break;
                array[k] = c;
                k = child;
            }
            array[k] = x;
        }
    }
```

### take

```java
   public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        E result;
        try {
            // 获取不到元素就等待
            while ( (result = dequeue()) == null)
                notEmpty.await();
        } finally {
            lock.unlock();
        }
        return result;
    }
```



### peek

```java
    public E peek() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 直接获取数组的第一个值，不进行删除等操作
            return (size == 0) ? null : (E) queue[0];
        } finally {
            lock.unlock();
        }
    }
```



## 删除元素

```java
    public boolean remove(Object o) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            int i = indexOf(o);
            if (i == -1)
                return false;
            removeAt(i);
            return true;
        } finally {
            lock.unlock();
        }
    }
	// 找到元素的位置
    private int indexOf(Object o) {
        if (o != null) {
            Object[] array = queue;
            int n = size;
            for (int i = 0; i < n; i++)
                if (o.equals(array[i]))
                    return i;
        }
        return -1;
    }
	// 删除指定位置的元素
    private void removeAt(int i) {
        Object[] array = queue;
        int n = size - 1;
        if (n == i) // removed last element
            array[i] = null;
        else {
            E moved = (E) array[n];
            array[n] = null;
            Comparator<? super E> cmp = comparator;
            // 二叉堆删除
            if (cmp == null)
                siftDownComparable(i, moved, array, n);
            else
                siftDownUsingComparator(i, moved, array, n, cmp);
            if (array[i] == moved) {
                if (cmp == null)
                    siftUpComparable(i, moved, array);
                else
                    siftUpUsingComparator(i, moved, array, cmp);
            }
        }
        size = n;
    }
```

到此，可以看出来所有的添加，删除，获取操作都使用了锁。保证多线程操作下的安全.

## 遍历元素

```java
    public Iterator<E> iterator() {
        return new Itr(toArray());
    }
```

```java
    final class Itr implements Iterator<E> {
        final Object[] array; // Array of all elements
        int cursor;           // index of next element to return
        int lastRet;          // index of last element, or -1 if no such

        Itr(Object[] array) {
            lastRet = -1;
            this.array = array;
        }

        public boolean hasNext() {
            return cursor < array.length;
        }

        public E next() {
            if (cursor >= array.length)
                throw new NoSuchElementException();
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

