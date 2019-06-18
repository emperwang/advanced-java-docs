# ArrayList

## Field

```java
	// 默认初始化容量
    private static final int DEFAULT_CAPACITY = 10;
	// 空数组
    private static final Object[] EMPTY_ELEMENTDATA = {};
	// 默认空数组
    private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
	// 真正存储数据
    transient Object[] elementData; 
	// 元素个数
    private int size;
	// 最大容量
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```



## 构造函数

```java
   public ArrayList(int initialCapacity) {
        if (initialCapacity > 0) {
            // 根据指定的容量，创建数组
            this.elementData = new Object[initialCapacity];
        } else if (initialCapacity == 0) {
            // 使用空数组
            this.elementData = EMPTY_ELEMENTDATA;
        } else {
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        }
    }
    public ArrayList() {
        // 使用默认的空数组
        this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
    }
	// 创建容器，并把参数中的数据拷贝到容器中
    public ArrayList(Collection<? extends E> c) {
        elementData = c.toArray();
        if ((size = elementData.length) != 0) {
            // c.toArray might (incorrectly) not return Object[] (see 6260652)
            if (elementData.getClass() != Object[].class)
                elementData = Arrays.copyOf(elementData, size, Object[].class);
        } else {
            // replace with empty array.
            this.elementData = EMPTY_ELEMENTDATA;
        }
    }

```

## 添加元素

```java
    // 添加元素
	public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }
	// 在指定位置添加元素
    public void add(int index, E element) {
        rangeCheckForAdd(index);
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);
        elementData[index] = element;
        size++;
    }
	// 判断指定的index是合法的
    private void rangeCheckForAdd(int index) {
        if (index > size || index < 0)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }
```

确定没有超出容量:

```java
    // 确保容量足够
	private void ensureCapacityInternal(int minCapacity) {
        ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
    }
	// 计算所需的最小容量
    private static int calculateCapacity(Object[] elementData, int minCapacity) {
        if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
            return Math.max(DEFAULT_CAPACITY, minCapacity);
        }
        return minCapacity;
    }
    private void ensureExplicitCapacity(int minCapacity) {
        modCount++;
		// 如果所需的最小容量小于现在的容量大小，则进行扩容
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
	// 扩容
    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
        // 每次扩容位原来的1.5倍
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
	// 判断有没有达到可允许的最大容量值
    private static int hugeCapacity(int minCapacity) {
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
    }
```



## 获取元素

```java
    public E get(int index) {
        rangeCheck(index);
        return elementData(index); // 直接返回数组中对应位置的数据
    }

    private void rangeCheck(int index) {
        if (index >= size)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }
```



## 删除元素’

### 根据索引删除

```java
    public E remove(int index) {
        rangeCheck(index);
        modCount++;  // 操作数加1
        E oldValue = elementData(index);  // 获取对应位置的值
        int numMoved = size - index - 1; // 获取要移动的数据的数量
        if (numMoved > 0) // 把index位置后面的元素往前移动一位，就把index位置的数据覆盖了，也就是删除了
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // 最后位置数据位null
        return oldValue;  // 返回删除的值
    }
```

### 根据元素删除

```java
    public boolean remove(Object o) {
        if (o == null) {
            // 遍历找到第一个值位null的位置
            for (int index = 0; index < size; index++)
                if (elementData[index] == null) {
                    // 后面的元素前移，进行覆盖
                    fastRemove(index);
                    return true;
                }
        } else {
            // 遍历找到值相等的位置
            for (int index = 0; index < size; index++)
                if (o.equals(elementData[index])) {
                    // 后面的元素前移，进行覆盖
                    fastRemove(index);
                    return true;
                }
        }
        return false;
    }

    private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
    }
```



## 遍历元素

### iterator

```java
    public Iterator<E> iterator() {
        return new Itr();
    }
```

内部类实现:

```java
    private class Itr implements Iterator<E> {
        int cursor;       // index of next element to return
        int lastRet = -1; // index of last element returned; -1 if no such
        int expectedModCount = modCount;

        Itr() {}
		// 是否有下一个
        public boolean hasNext() {
            return cursor != size;
        }

        @SuppressWarnings("unchecked")
        // 下一个位置元素
        public E next() {
            checkForComodification();
            int i = cursor;
            if (i >= size)
                throw new NoSuchElementException();
            Object[] elementData = ArrayList.this.elementData; // 得到存储数据的数组
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i + 1;
            return (E) elementData[lastRet = i]; // 返回对应位置的数据
        }
		// 删除一个元素
        public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();
            checkForComodification();

            try {
                // 使用主类函数删除
                ArrayList.this.remove(lastRet);
                cursor = lastRet;
                lastRet = -1;
                expectedModCount = modCount;
            } catch (IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }

        @Override
        @SuppressWarnings("unchecked")
        // 函数式编程
        public void forEachRemaining(Consumer<? super E> consumer) {
            Objects.requireNonNull(consumer);
            final int size = ArrayList.this.size;
            int i = cursor;
            if (i >= size) {
                return;
            }
            final Object[] elementData = ArrayList.this.elementData;
            if (i >= elementData.length) {
                throw new ConcurrentModificationException();
            }
            while (i != size && modCount == expectedModCount) {
                consumer.accept((E) elementData[i++]);
            }
            // update once at end of iteration to reduce heap write traffic
            cursor = i;
            lastRet = i - 1;
            checkForComodification();
        }

        final void checkForComodification() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
        }
    }
```



### listIterator

```java
    public ListIterator<E> listIterator() {
        return new ListItr(0);
    }
    public ListIterator<E> listIterator(int index) {
        if (index < 0 || index > size)
            throw new IndexOutOfBoundsException("Index: "+index);
        return new ListItr(index);
    }
```

这里同样是一个内部类的实现:

```java
    private class ListItr extends Itr implements ListIterator<E> {
        ListItr(int index) {
            super();
            cursor = index;  // 记录索引的位置
        }
		// 是否有前一个元素
        // 可见这里是一个双向遍历
        public boolean hasPrevious() {
            return cursor != 0;
        }
		// 下一个元素的索引位置
        public int nextIndex() {
            return cursor;
        }
		// 前一个元素的索引位置
        public int previousIndex() {
            return cursor - 1;
        }

        @SuppressWarnings("unchecked")
        // 前一个元素
        public E previous() {
            checkForComodification();
            int i = cursor - 1; // 前一个元素的索引
            if (i < 0)
                throw new NoSuchElementException();
            Object[] elementData = ArrayList.this.elementData;
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i;
            return (E) elementData[lastRet = i]; // 前一个元素
        }
		// 修改值
        public void set(E e) {
            if (lastRet < 0)
                throw new IllegalStateException();
            checkForComodification();
            try {// 把上一次返回的数据修改为e
                ArrayList.this.set(lastRet, e);
            } catch (IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }
		// 添加元素
        public void add(E e) {
            checkForComodification();
            try {
                int i = cursor;
                ArrayList.this.add(i, e);
                cursor = i + 1;
                lastRet = -1;
                expectedModCount = modCount;
            } catch (IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }
    }
```



