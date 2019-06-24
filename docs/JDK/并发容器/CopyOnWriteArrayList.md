#  CopyOnWriteArrayList

## Field

```java
    // 非公平锁
    final transient ReentrantLock lock = new ReentrantLock();
    /** The array, accessed only via getArray/setArray. */
	// 存储元素
    private transient volatile Object[] array;
    private static final sun.misc.Unsafe UNSAFE;
    private static final long lockOffset;
```

## 初始化代码

```java
    static {
        try {
            UNSAFE = sun.misc.Unsafe.getUnsafe();
            Class<?> k = CopyOnWriteArrayList.class;
            lockOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("lock"));
        } catch (Exception e) {
            throw new Error(e);
        }
    }
```



## 构造函数

```java
    // 设置一个空数组
	public CopyOnWriteArrayList() {
        setArray(new Object[0]);
    }
	// 把指定集合元素添加到容器中的数组中
    public CopyOnWriteArrayList(Collection<? extends E> c) {
        Object[] elements;
        if (c.getClass() == CopyOnWriteArrayList.class)
            elements = ((CopyOnWriteArrayList<?>)c).getArray();
        else {
            elements = c.toArray();
            // c.toArray might (incorrectly) not return Object[] (see 6260652)
            if (elements.getClass() != Object[].class)
                elements = Arrays.copyOf(elements, elements.length, Object[].class);
        }
        setArray(elements);
    }
	// 把数组中的元素复制到集合数组中
    public CopyOnWriteArrayList(E[] toCopyIn) {
        setArray(Arrays.copyOf(toCopyIn, toCopyIn.length, Object[].class));
    }
	// 数组操作函数
	final Object[] getArray() {
        return array;
    }

    final void setArray(Object[] a) {
        array = a;
    }
```



## 添加元素

### add

```java
    public boolean add(E e) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 获取原数组 及其长度
            Object[] elements = getArray();
            int len = elements.length;
            // 把原来数组的元素复制到新数组中
            // 新数组比原来数组长度长1 
            Object[] newElements = Arrays.copyOf(elements, len + 1);
            // 把新元素放置到新数组最后位置
            newElements[len] = e;
            // 把新数组设置为容器的数组
            setArray(newElements);
            return true;
        } finally {
            lock.unlock();
        }
    }
```



### addIfAbsent

```java
    public boolean addIfAbsent(E e) {
        Object[] snapshot = getArray(); // 获取元素
        // 如果元素在数组中存在,则不添加;只有在不存在时再进行添加操作
        return indexOf(e, snapshot, 0, snapshot.length) >= 0 ? false :
            addIfAbsent(e, snapshot);
    }

   private boolean addIfAbsent(E e, Object[] snapshot) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            Object[] current = getArray();
            int len = current.length;
            // 再次比较快照数组和容器数组是否相等,如果不相等,则说明容器进行了添加或删除操作
            if (snapshot != current) {
                // Optimize for lost race to another addXXX operation
                int common = Math.min(snapshot.length, len);
                // 如果新加了元素,并且要添加元素和新添加元素相等,则不添加
                // 就是又做了一次校验
                for (int i = 0; i < common; i++)
                    if (current[i] != snapshot[i] && eq(e, current[i]))
                        return false;
                // 如果在容器新数组中存在要添加的元素,则不添加
                if (indexOf(e, current, common, len) >= 0)
                        return false;
            }
            // 检查过后,确定容器中不存在要添加元素
            // 则进行添加操作
            Object[] newElements = Arrays.copyOf(current, len + 1);
            newElements[len] = e;
            setArray(newElements);
            return true;
        } finally {
            lock.unlock();
        }
    }
	// 找到元素在数组中的位置
    private static int indexOf(Object o, Object[] elements,
                               int index, int fence) {
        if (o == null) { //如果要查找元素为null,则遍历数组找到第一个为null的位置
            for (int i = index; i < fence; i++)
                if (elements[i] == null)
                    return i;
        } else { // 否则遍历数组找到相等元素的下标
            for (int i = index; i < fence; i++)
                if (o.equals(elements[i]))
                    return i;
        }
        return -1;
    }
```



## 获取元素

```java
    // 直接返回数组中对应位置的元素
	public E get(int index) {
        return get(getArray(), index);
    }

    private E get(Object[] a, int index) {
        return (E) a[index];
    }
```



## 删除元素

```java
    public E remove(int index) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            Object[] elements = getArray(); // 获取容器数组
            int len = elements.length; // 得到数组长度
            E oldValue = get(elements, index); // 得到要删除元素的值
            int numMoved = len - index - 1; // 需要移动的元素数
            if (numMoved == 0)
                // 如果删除是最后一个,则创建一个新数组,长度比原来少1,然后把元素0-(len-1)的元素复制到新数组，并返回
                setArray(Arrays.copyOf(elements, len - 1));
            else {
                // 创建长度少1的数组
                Object[] newElements = new Object[len - 1];
                // 把0-index拷贝到新数组
                System.arraycopy(elements, 0, newElements, 0, index);
                // 把index+1-len拷贝到新数组,没有拷贝index
                // 所以新数组中没有原来index位置的元素,也就是删除了
                System.arraycopy(elements, index + 1, newElements, index,
                                 numMoved);
                setArray(newElements);
            }
            return oldValue;
        } finally {
            lock.unlock();
        }
    }
```



## 遍历元素

```java
    public Iterator<E> iterator() {
        return new COWIterator<E>(getArray(), 0);
    }
```



内部类实现遍历操作

```java
    static final class COWIterator<E> implements ListIterator<E> {
        /** Snapshot of the array */
        private final Object[] snapshot; // 容器数组的快照
        /** Index of element to be returned by subsequent call to next.  */
        private int cursor; // 要操作元素的index

        private COWIterator(Object[] elements, int initialCursor) {
            cursor = initialCursor;
            snapshot = elements;
        }
		// 判断是否有下一个
        public boolean hasNext() {
            return cursor < snapshot.length;
        }
		// 是否有前一个
        public boolean hasPrevious() {
            return cursor > 0;
        }
		// 下一个元素
        @SuppressWarnings("unchecked")
        public E next() {
            if (! hasNext())
                throw new NoSuchElementException();
            return (E) snapshot[cursor++];
        }
		// 前一个元素
        @SuppressWarnings("unchecked")
        public E previous() {
            if (! hasPrevious())
                throw new NoSuchElementException();
            return (E) snapshot[--cursor];
        }
		// 下一个操作元素的索引
        public int nextIndex() {
            return cursor;
        }
		// 操作元素的前一个索引
        public int previousIndex() {
            return cursor-1;
        }
		// 函数式编程
        @Override
        public void forEachRemaining(Consumer<? super E> action) {
            Objects.requireNonNull(action);
            Object[] elements = snapshot;
            final int size = elements.length;
            for (int i = cursor; i < size; i++) {
                @SuppressWarnings("unchecked") E e = (E) elements[i];
                action.accept(e);
            }
            cursor = size;
        }
    }
```

