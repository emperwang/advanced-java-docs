# Vecotr

## Field

```java
    // 存储数据的数组
	protected Object[] elementData;
	// 元素数量
    protected int elementCount;
	// 当capacityIncrement大于0时，容量每次扩大capacityIncrement
	// 否则每次扩容一倍
    protected int capacityIncrement;
	// 最大容量
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```



## 构造函数

```java
    // 指定容量，以及每次扩容大小
	public Vector(int initialCapacity, int capacityIncrement) {
        super();
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        this.elementData = new Object[initialCapacity];
        this.capacityIncrement = capacityIncrement;
    }
    public Vector(int initialCapacity) {
        this(initialCapacity, 0);
    }

    public Vector() {
        this(10);
    }
	// 创建数组并把参数中的元素拷贝进来
    public Vector(Collection<? extends E> c) {
        elementData = c.toArray();
        elementCount = elementData.length;
        // c.toArray might (incorrectly) not return Object[] (see 6260652)
        if (elementData.getClass() != Object[].class)
            elementData = Arrays.copyOf(elementData, elementCount, Object[].class);
    }
```



## 添加元素

```java
    public synchronized boolean add(E e) {
        modCount++;
        ensureCapacityHelper(elementCount + 1);
        elementData[elementCount++] = e;
        return true;
    }
```

确保容量，不够大则扩容:

```java
    private void ensureCapacityHelper(int minCapacity) {
        // 如果大小不够，则扩容
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
        // 每次增大capacityIncrement
        // 或每次扩大一倍
        int newCapacity = oldCapacity + ((capacityIncrement > 0) ?
                                         capacityIncrement : oldCapacity);
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // 新扩容再拷贝
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
	// 判断是否达到允许容量的最大值
    private static int hugeCapacity(int minCapacity) {
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
    }
	// 数组拷贝操作
    public static <T> T[] copyOf(T[] original, int newLength) {
        return (T[]) copyOf(original, newLength, original.getClass());
    }
	
    public static <T,U> T[] copyOf(U[] original, int newLength, Class<? extends T[]> newType) {
        @SuppressWarnings("unchecked")
        // 先进行扩容操作
        T[] copy = ((Object)newType == (Object)Object[].class)
            ? (T[]) new Object[newLength]
            : (T[]) Array.newInstance(newType.getComponentType(), newLength);
        // 在把原来数组中的值拷贝到新的数组中
        System.arraycopy(original, 0, copy, 0,
                         Math.min(original.length, newLength));
        return copy;
    }
```

第二个添加元素方法

```java
    public synchronized void addElement(E obj) {
        modCount++;
        ensureCapacityHelper(elementCount + 1);
        elementData[elementCount++] = obj;
    }
    private void ensureCapacityHelper(int minCapacity) {
        // overflow-conscious code
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
```



## 获取元素

```java
    public synchronized E get(int index) {
        if (index >= elementCount)
            throw new ArrayIndexOutOfBoundsException(index);
		// 返回数组中对应位置的值
        return elementData(index);
    }
```



## 删除元素

### 按元素删除

```java
    public boolean remove(Object o) {
        return removeElement(o);
    }
    public synchronized boolean removeElement(Object obj) {
        modCount++;
        int i = indexOf(obj);
        if (i >= 0) {
            removeElementAt(i);
            return true;
        }
        return false;
    }

```

查看某个元素的第一个位置

```java
    public int indexOf(Object o) {
        return indexOf(o, 0);// 从第一个元素开始查找
    }
    public synchronized int indexOf(Object o, int index) {
        if (o == null) {// 如果元素为null，则查找第一个值为null的索引
            for (int i = index ; i < elementCount ; i++)
                if (elementData[i]==null)
                    return i;
        } else {
            // 否则遍历查找相等值的索引
            for (int i = index ; i < elementCount ; i++)
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
    }
```

删除某个位置的元素

```java
    public synchronized void removeElementAt(int index) {
        modCount++;
        if (index >= elementCount) {
            throw new ArrayIndexOutOfBoundsException(index + " >= " +
                                                     elementCount);
        }
        else if (index < 0) {
            throw new ArrayIndexOutOfBoundsException(index);
        }
        int j = elementCount - index - 1;
        if (j > 0) {// 后面元素向前拷贝
            System.arraycopy(elementData, index + 1, elementData, index, j);
        }
        elementCount--;// 数量减1
        // 最后元素置为null
        elementData[elementCount] = null; /* to let gc do its work */
    }
```



### 按索引删除

```java
    public synchronized E remove(int index) {
        modCount++;
        if (index >= elementCount)
            throw new ArrayIndexOutOfBoundsException(index);
        E oldValue = elementData(index);// 获取要删除位置的值

        int numMoved = elementCount - index - 1;
        if (numMoved > 0)// 后面元素向前移动
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--elementCount] = null; // Let gc do its work
        return oldValue;
    }
```



## 遍历元素

### Iterator

```java
    public synchronized Iterator<E> iterator() {
        return new Itr();
    }

	// 内部类遍历操作实现
    private class Itr implements Iterator<E> {
        int cursor;       // index of next element to return
        int lastRet = -1; // index of last element returned; -1 if no such
        int expectedModCount = modCount;
	
        // 是否有下一个元素
        public boolean hasNext() {
            // Racy but within spec, since modifications are checked
            // within or after synchronization in next/previous
            return cursor != elementCount;
        }
		// 下一个元素
        public E next() {
            synchronized (Vector.this) {
                checkForComodification();
                int i = cursor;
                if (i >= elementCount)
                    throw new NoSuchElementException();
                cursor = i + 1;
                return elementData(lastRet = i);
            }
        }
		// 删除一个元素
        public void remove() {
            if (lastRet == -1)
                throw new IllegalStateException();
            synchronized (Vector.this) {
                checkForComodification();
                Vector.this.remove(lastRet);
                expectedModCount = modCount;
            }
            cursor = lastRet;
            lastRet = -1;
        }

        @Override
        // 函数式编程
        public void forEachRemaining(Consumer<? super E> action) {
            Objects.requireNonNull(action);
            synchronized (Vector.this) {
                final int size = elementCount;
                int i = cursor;
                if (i >= size) {
                    return;
                }
        @SuppressWarnings("unchecked")
                final E[] elementData = (E[]) Vector.this.elementData;
                if (i >= elementData.length) {
                    throw new ConcurrentModificationException();
                }
                while (i != size && modCount == expectedModCount) {
                    action.accept(elementData[i++]);
                }
                // update once at end of iteration to reduce heap write traffic
                cursor = i;
                lastRet = i - 1;
                checkForComodification();
            }
        }

        final void checkForComodification() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
        }
    }
```





### listIterator

```java
    public synchronized ListIterator<E> listIterator() {
        return new ListItr(0);
    }


   final class ListItr extends Itr implements ListIterator<E> {
        ListItr(int index) {
            super();
            cursor = index; // 记录开始查找的索引位置
        }
		// 是否有前一个元素
        public boolean hasPrevious() {
            return cursor != 0;
        }
		// 下一个索引
        public int nextIndex() {
            return cursor;
        }
		// 前一个元素的索引
        public int previousIndex() {
            return cursor - 1;
        }
		// 前一个元素
        public E previous() {
            synchronized (Vector.this) {
                checkForComodification();
                int i = cursor - 1;
                if (i < 0)
                    throw new NoSuchElementException();
                cursor = i;
                return elementData(lastRet = i); // 返回前一个元素的值
            }
        }
		// 设置新值
        public void set(E e) {
            if (lastRet == -1)
                throw new IllegalStateException();
            synchronized (Vector.this) {
                checkForComodification();
                Vector.this.set(lastRet, e);
            }
        }
		// 添加新值
        public void add(E e) {
            int i = cursor;
            synchronized (Vector.this) {
                checkForComodification();
                Vector.this.add(i, e);
                expectedModCount = modCount;
            }
            cursor = i + 1;
            lastRet = -1;
        }
    }
```

可以看到此容器的操作，大都带有synchronized关键字，保证了再多线程模式下是安全的。