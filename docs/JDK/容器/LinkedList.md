# LinkedList

## Field

```java
    // 节点总数
	transient int size = 0;
	// 第一个几个节点
    transient Node<E> first;
	// 最后一个节点
    transient Node<E> last;
```



## 存储结构

```java
    private static class Node<E> {
        E item;  // 存储值
        Node<E> next; // 前一个节点
        Node<E> prev;	// 后一个节点

        Node(Node<E> prev, E element, Node<E> next) {
            this.item = element;
            this.next = next;
            this.prev = prev;
        }
    }
```

## 构造函数

```java
    public LinkedList() {
    }

    public LinkedList(Collection<? extends E> c) {
        this();
        addAll(c);
    }
```



## 添加元素

```java
    // 可见普通添加都是添加到最后
	public boolean add(E e) {
        linkLast(e);
        return true;
    }
	// 在最后添加元素
    void linkLast(E e) {
        final Node<E> l = last;
        // 创建新节点，封装要添加的元素
        final Node<E> newNode = new Node<>(l, e, null);
        last = newNode;
        if (l == null)
            first = newNode;
        else
            l.next = newNode;
        size++;
        modCount++;
    }
```

### 指定位置添元素

```java
    public void add(int index, E element) {
        checkPositionIndex(index);

        if (index == size) // 如果index等于链表大小，则直接在最后添加元素
            linkLast(element);
        else // 否则找到index位置的节点，在其前面插入一个新节点
            linkBefore(element, node(index));
    }
	// 查找固定位置的节点
    Node<E> node(int index) {
        // 二分查找法
        // 从头开始查找
        if (index < (size >> 1)) {
            Node<E> x = first;
            // 遍历查找
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else { // 从尾开始查找
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
    }
	// 在succ前面插入节点
    void linkBefore(E e, Node<E> succ) {
        // 获取前节点
        final Node<E> pred = succ.prev;
        // 创建新节点
        final Node<E> newNode = new Node<>(pred, e, succ);
        succ.prev = newNode;
        if (pred == null)
            first = newNode;
        else
            pred.next = newNode;
        size++;
        modCount++;
    }
```



## 获取元素

```java
    public E get(int index) {
        checkElementIndex(index);
        // 找到index对应的节点，把其封装的值返回
        return node(index).item;
    }
```

### 获取第一个节点值

```java
    // 获取第一个值，但不删除节点
	public E peek() {
        // 获取第一个节点，返回其值
        final Node<E> f = first;
        return (f == null) ? null : f.item;
    }
	// 获取第一个值，但不删除节点
    public E element() {
        return getFirst();
    }

    public E getFirst() {
        final Node<E> f = first;
        if (f == null)
            throw new NoSuchElementException();
        return f.item;
    }
	// 获取第一个值，并删除节点
    public E poll() {
        // 获取第一个节点，返回其值，并删除节点
        final Node<E> f = first;
        return (f == null) ? null : unlinkFirst(f);
    }

    private E unlinkFirst(Node<E> f) {
        final E element = f.item; // 获取节点的值
        final Node<E> next = f.next; // 得到下一个节点
        f.item = null;
        f.next = null; // help GC
        first = next;
        if (next == null)
            last = null;
        else
            next.prev = null;// 前一个节点为null，说明此节点就是头节点了
        size--;
        modCount++;
        return element;
    }
```





## 删除元素

### 删除第一个元素

```java
    public E remove() {
        return removeFirst();
    }

    public E removeFirst() {
        // 得到第一个节点，并把其删除
        final Node<E> f = first;
        if (f == null)
            throw new NoSuchElementException();
        return unlinkFirst(f);
    }
```



### 删除指定位置的元素

```java
    public E remove(int index) {
        checkElementIndex(index);
        // 先得到对应index的节点
        // 并把该节点删除
        return unlink(node(index));
    }

    E unlink(Node<E> x) {
        // 得到节点的值
        final E element = x.item;
        // 获取前一个元素
        final Node<E> next = x.next;
        // 获取后一个元素
        final Node<E> prev = x.prev;
		// 删除元素的具体操作
        if (prev == null) {
            first = next;
        } else {
            prev.next = next;
            x.prev = null;
        }

        if (next == null) {
            last = prev;
        } else {
            next.prev = prev;
            x.next = null;
        }

        x.item = null;
        size--;
        modCount++;
        return element;
    }
```



## 遍历元素

```java
    public ListIterator<E> listIterator(int index) {
        checkPositionIndex(index);
        // 内部类实现遍历
        return new ListItr(index);
    }

    private class ListItr implements ListIterator<E> {
        private Node<E> lastReturned; // 上一次返回的几点
        private Node<E> next; // 下一个节点
        private int nextIndex; // 下一个index
        private int expectedModCount = modCount;

        ListItr(int index) {
            // 如果是最后则下一个节点是null，否则得到对应index的节点
            next = (index == size) ? null : node(index);
            nextIndex = index;
        }
		// 是否有下一个节点
        public boolean hasNext() {
            return nextIndex < size;
        }
		// 下一个元素
        public E next() {
            checkForComodification();
            if (!hasNext())
                throw new NoSuchElementException();

            lastReturned = next;
            next = next.next;
            nextIndex++;
            return lastReturned.item;
        }
		// 是否有前节点
        public boolean hasPrevious() {
            return nextIndex > 0;
        }
		// 前一个节点的值
        public E previous() {
            checkForComodification();
            if (!hasPrevious())
                throw new NoSuchElementException();

            lastReturned = next = (next == null) ? last : next.prev;
            nextIndex--;
            return lastReturned.item;
        }
		// 下一个元素的索引
        public int nextIndex() {
            return nextIndex;
        }
		// 前一个索引
        public int previousIndex() {
            return nextIndex - 1;
        }
		// 删除元素
        public void remove() {
            checkForComodification();
            if (lastReturned == null)
                throw new IllegalStateException();

            Node<E> lastNext = lastReturned.next;
            // 具体的删除操作
            unlink(lastReturned);
            if (next == lastReturned)
                next = lastNext;
            else
                nextIndex--;
            lastReturned = null;
            expectedModCount++;
        }
		// 修改值
        public void set(E e) {
            if (lastReturned == null)
                throw new IllegalStateException();
            checkForComodification();
            lastReturned.item = e;
        }
		// 添加值
        public void add(E e) {
            checkForComodification();
            lastReturned = null;
            if (next == null)
                linkLast(e);
            else
                linkBefore(e, next);
            nextIndex++;
            expectedModCount++;
        }

        public void forEachRemaining(Consumer<? super E> action) {
            Objects.requireNonNull(action);
            while (modCount == expectedModCount && nextIndex < size) {
                action.accept(next.item);
                lastReturned = next;
                next = next.next;
                nextIndex++;
            }
            checkForComodification();
        }

        final void checkForComodification() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
        }
    }
```

