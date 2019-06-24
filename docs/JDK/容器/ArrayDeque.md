# ArrayDeque

## Field

```java
   // 存储元素
	transient Object[] elements; // non-private to simplify nested class access
	// 要获取的元素或删除元素的index
    transient int head;
	// 尾index
    transient int tail;
	// 最小容量
    private static final int MIN_INITIAL_CAPACITY = 8;
```



## 构造方法

```java
    // 默认容器大小为16
	public ArrayDeque() {
        elements = new Object[16];
    }
	// 指定容量创建容器
    public ArrayDeque(int numElements) {
        allocateElements(numElements);
    }

    public ArrayDeque(Collection<? extends E> c) {
        allocateElements(c.size());
        addAll(c);
    }
```

当指定容量时,保证容量为2的倍数:

```java
    private void allocateElements(int numElements) {
        elements = new Object[calculateSize(numElements)];
    }

    private static int calculateSize(int numElements) {
        int initialCapacity = MIN_INITIAL_CAPACITY;
        // Find the best power of two to hold elements.
        // Tests "<=" because arrays aren't kept full.
        if (numElements >= initialCapacity) {
            initialCapacity = numElements;
            initialCapacity |= (initialCapacity >>>  1);
            initialCapacity |= (initialCapacity >>>  2);
            initialCapacity |= (initialCapacity >>>  4);
            initialCapacity |= (initialCapacity >>>  8);
            initialCapacity |= (initialCapacity >>> 16);
            initialCapacity++;

            if (initialCapacity < 0)   // Too many elements, must back off
                initialCapacity >>>= 1;// Good luck allocating 2 ^ 30 elements
        }
        return initialCapacity;
    }
```



## 添加元素

### 头部添加

```java

	public void addFirst(E e) {
        if (e == null)
            throw new NullPointerException();
        elements[head = (head - 1) & (elements.length - 1)] = e;
        if (head == tail)
            doubleCapacity();
    }

    public boolean offerFirst(E e) {
        addFirst(e);
        return true;
    }
```



### 尾部添加

```java
   public boolean offer(E e) {
        return offerLast(e);
    }
    public boolean offerLast(E e) {
        addLast(e);
        return true;
    }
	// 默认从尾部添加
	public boolean add(E e) {
        addLast(e);  // 
        return true;
    }
	public void addLast(E e) {
        if (e == null)
            throw new NullPointerException();
        elements[tail] = e;
        if ( (tail = (tail + 1) & (elements.length - 1)) == head)
            doubleCapacity();
    }
```



### 扩容

```java
    private void doubleCapacity() {
        assert head == tail;
        int p = head;
        int n = elements.length;
        int r = n - p; // number of elements to the right of p
        int newCapacity = n << 1; // 容量扩大2倍
        if (newCapacity < 0)
            throw new IllegalStateException("Sorry, deque too big");
        Object[] a = new Object[newCapacity];// 创建新数组
        System.arraycopy(elements, p, a, 0, r); // 把p之后的元素拷贝进入
        System.arraycopy(elements, 0, a, r, p); // 把elements中的0-p元素拷贝进新数组
        elements = a;
        head = 0;
        tail = n;
    }
```



##　获取元素


### 获取头元素
#### poll 获取元素

```java
    // 不会报错,但是当获取数据后,会把数据删除
	public E pollFirst() {
        int h = head;
        @SuppressWarnings("unchecked")
        E result = (E) elements[h];
        // Element is null if deque empty
        if (result == null)
            return null;
        elements[h] = null;     // 删除数组
        head = (h + 1) & (elements.length - 1);
        return result;
    }
```



#### peek获取元素

```java
  // 直接获取元素,不存在则返回null
	public E peekFirst() {
        // elements[head] is null if deque empty
        return (E) elements[head];
    }
```



#### get 获取元素

```java
    // 获取元素,如果元素不存在,则报错
	public E getFirst() {
        @SuppressWarnings("unchecked")
        E result = (E) elements[head];
        if (result == null)
            throw new NoSuchElementException();
        return result;
    }
```



### 获取尾元素
#### poll 获取元素

```java
    public E pollLast() {
        int t = (tail - 1) & (elements.length - 1);
        @SuppressWarnings("unchecked")
        E result = (E) elements[t];
        if (result == null)
            return null;
        elements[t] = null;
        tail = t;
        return result;
    }
```



#### peek获取元素

```java
    @SuppressWarnings("unchecked")
    public E peekLast() {
        return (E) elements[(tail - 1) & (elements.length - 1)];
    }
```



#### get 获取元素

```java
    public E getLast() {
        @SuppressWarnings("unchecked")
        E result = (E) elements[(tail - 1) & (elements.length - 1)];
        if (result == null)
            throw new NoSuchElementException();
        return result;
    }
```



## 删除元素

### 从头部删除

#### remove

```java
    public E remove() {
        return removeFirst();
    }

    public E removeFirst() {
        E x = pollFirst();  // 使用poll获取第一个元素
        if (x == null)
            throw new NoSuchElementException();
        return x;
    }
```

### 删除指定的元素

```java
    public boolean remove(Object o) {
        return removeFirstOccurrence(o);
    }
	
    public boolean removeFirstOccurrence(Object o) {
        if (o == null)
            return false;
        int mask = elements.length - 1;
        int i = head;
        Object x;
        // 遍历循环找到要删除的元素的位置
        while ( (x = elements[i]) != null) {
            if (o.equals(x)) {
                // 删除指定位置的元素
                delete(i);
                return true;
            }
            i = (i + 1) & mask;
        }
        return false;
    }
	// 删除指定位置的元素
	private boolean delete(int i) {
        checkInvariants();
        final Object[] elements = this.elements;
        final int mask = elements.length - 1;
        final int h = head;
        final int t = tail;
        final int front = (i - h) & mask;  // i前面的元素数
        final int back  = (t - i) & mask; // i后面的元素数

        // Invariant: head <= i < tail mod circularity
        if (front >= ((t - h) & mask))
            throw new ConcurrentModificationException();

        // Optimize for least element motion
        if (front < back) {
            if (h <= i) { 
                // 就是head-i之间的元素,整体向后移动一个,也就把i覆盖了
                System.arraycopy(elements, h, elements, h + 1, front);
            } else { // Wrap around
                // 0-i间的元素向后移动一个,把i位置的元素覆盖
                System.arraycopy(elements, 0, elements, 1, i);
                // 0位置保存最后一个元素
                elements[0] = elements[mask];
                // 再把h-(mask-h)间数据向后移动一个位置
                System.arraycopy(elements, h, elements, h + 1, mask - h);
            }
            elements[h] = null;
            head = (h + 1) & mask;
            return false;
        } else {
            if (i < t) { // Copy the null tail as well
                // i+1后面的back个元整体向前移动一位
                System.arraycopy(elements, i + 1, elements, i, back);
                tail = t - 1;
            } else { // Wrap around
                // i+1后面(mask-i)个元素向前移动一位
                System.arraycopy(elements, i + 1, elements, i, mask - i);
                elements[mask] = elements[0];
                // 1后面t个元素向前移动一位
                System.arraycopy(elements, 1, elements, 0, t);
                tail = (t - 1) & mask;
            }
            return true;
        }
    }

    private void checkInvariants() {
        assert elements[tail] == null;
        assert head == tail ? elements[head] == null :
            (elements[head] != null &&
             elements[(tail - 1) & (elements.length - 1)] != null);
        assert elements[(head - 1) & (elements.length - 1)] == null;
    }
```



## 遍历容器

```java
    public Iterator<E> iterator() {
        return new DeqIterator();
    }

    private class DeqIterator implements Iterator<E> {
		// 头位置
        private int cursor = head;
		// 最后一个位置
        private int fence = tail;
		// 上次返回元素的位置
        private int lastRet = -1;
		// 是否有下一个
        public boolean hasNext() {
            return cursor != fence;
        }
		// 获取下一个元素
        public E next() {
            if (cursor == fence)
                throw new NoSuchElementException();
            @SuppressWarnings("unchecked")
            E result = (E) elements[cursor];
            // This check doesn't catch all possible comodifications,
            // but does catch the ones that corrupt traversal
            if (tail != fence || result == null)
                throw new ConcurrentModificationException();
            lastRet = cursor;
            cursor = (cursor + 1) & (elements.length - 1);
            return result;
        }
		// 删除元素
        public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();
            if (delete(lastRet)) { // if left-shifted, undo increment in next()
                cursor = (cursor - 1) & (elements.length - 1);
                fence = tail;
            }
            lastRet = -1;
        }

        public void forEachRemaining(Consumer<? super E> action) {
            Objects.requireNonNull(action);
            Object[] a = elements;
            int m = a.length - 1, f = fence, i = cursor;
            cursor = f;
            while (i != f) {
                @SuppressWarnings("unchecked") E e = (E)a[i];
                i = (i + 1) & m;
                if (e == null)
                    throw new ConcurrentModificationException();
                action.accept(e);
            }
        }
    }
```

