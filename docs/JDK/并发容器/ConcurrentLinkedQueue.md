# ConcurrentLinkedQueue

## Field

```java
    // 头节点
	private transient volatile Node<E> head;
	// 尾节点
    private transient volatile Node<E> tail;
    // CAS操作
	private static final sun.misc.Unsafe UNSAFE;
    // 头节点的内存偏移值
	private static final long headOffset;
	// 尾节点的内存偏移值    
	private static final long tailOffset;
```

静态初始化：

```java
    static {
        try {
            // 实例化CAS操作
            UNSAFE = sun.misc.Unsafe.getUnsafe();
            Class<?> k = ConcurrentLinkedQueue.class;
            // 获取对应的内存偏移值
            headOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("head"));
            tailOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("tail"));
        } catch (Exception e) {
            throw new Error(e);
        }
    }
```



## 构造函数

```java
    // 创建容器,并添加元素到容器中
	public ConcurrentLinkedQueue(Collection<? extends E> c) {
        Node<E> h = null, t = null;
        for (E e : c) {
            checkNotNull(e);
            Node<E> newNode = new Node<E>(e);
            if (h == null)
                h = t = newNode;
            else {
                // CAS操作,把newNode赋值给next
                t.lazySetNext(newNode);
                t = newNode;
            }
        }
        if (h == null)
            h = t = new Node<E>(null);
        head = h;
        tail = t;
    }
	// 无参构造
    public ConcurrentLinkedQueue() {
        head = tail = new Node<E>(null);
    }
```



## 存储结构

```java
    private static class Node<E> {
        volatile E item; // 存储的值
        volatile Node<E> next; // 下一个节点
		// 构造函数
        Node(E item) {
            // CAS操作,把元素赋值给this.item
            UNSAFE.putObject(this, itemOffset, item);
        }
		// 给this.item替换一个值
        boolean casItem(E cmp, E val) {
            return UNSAFE.compareAndSwapObject(this, itemOffset, cmp, val);
        }
		// 把val赋值给this.next
        void lazySetNext(Node<E> val) {
            UNSAFE.putOrderedObject(this, nextOffset, val);
        }
		// 给next设置新值
        boolean casNext(Node<E> cmp, Node<E> val) {
            return UNSAFE.compareAndSwapObject(this, nextOffset, cmp, val);
        }
        // CAS 操作类
        private static final sun.misc.Unsafe UNSAFE;
        // field对应的内存偏移量
        private static final long itemOffset;
        private static final long nextOffset;

        static {
            try {
                UNSAFE = sun.misc.Unsafe.getUnsafe();
                Class<?> k = Node.class;
                itemOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("item"));
                nextOffset = UNSAFE.objectFieldOffset
                    (k.getDeclaredField("next"));
            } catch (Exception e) {
                throw new Error(e);
            }
        }
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
        checkNotNull(e);
        // 使用node结构把e封装起来
        final Node<E> newNode = new Node<E>(e);
		// 遍历列表,把元素放到列表最后
        for (Node<E> t = tail, p = t;;) {
            Node<E> q = p.next;
            if (q == null) {
                // q==null,说明p就是最后一个节点
                if (p.casNext(null, newNode)) {
                    // 如果把p.next设置为newNode成功,则newNode就成功加入到链表中了
                    if (p != t) // hop two nodes at a time
                        // 把tail设置为newNode
                        casTail(t, newNode);  // Failure is OK.
                    return true;
                }
                // Lost CAS race to another thread; re-read next
            }
            else if (p == q)
				// 如果p.next==p,说明p是被删除的元素
                // 如果tail==t,那么就从head开始遍历链表
                p = (t != (t = tail)) ? t : head;
            else
                // Check for tail updates after two hops.
                p = (p != t && t != (t = tail)) ? t : q;
        }
    }
```



## 获取元素

### peek

```java
    public E peek() {
        restartFromHead:
        for (;;) {
            for (Node<E> h = head, p = h, q;;) {
                E item = p.item;
                if (item != null || (q = p.next) == null) {
                    // 把head设置为p
                    updateHead(h, p);
                    return item;
                }
                else if (p == q)
                    continue restartFromHead;
                else
                    p = q;
            }
        }
    }
	
    final void updateHead(Node<E> h, Node<E> p) {
        // h!=p,则把head设置为p
        if (h != p && casHead(h, p))
            h.lazySetNext(h); // 把h从链表中删除
    }
```

由此可见peek从head开始遍历,找到item不为null的节点,并把节点内容返回。并把head设置为此不为null的节点。

### poll

```java
    public E poll() {
        restartFromHead:
        for (;;) {
            // 从链表头开始遍历
            for (Node<E> h = head, p = h, q;;) {
                E item = p.item;
                // 如果找到了item不为null的节点，则把此node的item设置为null
                if (item != null && p.casItem(item, null)) {
                    // 并把head设置为找到节点的下一个节点
                    // item置为null，并把节点从链表中删除
                    if (p != h) // hop two nodes at a time
                        updateHead(h, ((q = p.next) != null) ? q : p);
                    return item;
                }
                // 如果队列就是为空，则返回null
                else if ((q = p.next) == null) {
                    updateHead(h, p);
                    return null;
                }
                else if (p == q)
                    continue restartFromHead;
                else
                    p = q;
            }
        }
    }
```

## 删除元素

```java
    public boolean remove(Object o) {
        if (o != null) {
            Node<E> next, pred = null;
            // 从第一个有效元素开始遍历
            for (Node<E> p = first(); p != null; pred = p, p = next) {
                boolean removed = false;
                E item = p.item;
                if (item != null) {
                    if (!o.equals(item)) {
                       // 获取p的下一个元素
                        next = succ(p);
                        continue;
                    }
                    // 
                    removed = p.casItem(item, null);
                }
				// 获取p的下一个元素
                next = succ(p);
                // 删除节点p
                if (pred != null && next != null) // unlink
                    pred.casNext(p, next);
                if (removed)
                    return true;
            }
        }
        return false;
    }
	
	// 如果p的next不指向自己，则返回p.next
    final Node<E> succ(Node<E> p) {
        Node<E> next = p.next;
        return (p == next) ? head : next;
    }
```



## 遍历元素

```java
    public Iterator<E> iterator() {
        return new Itr();
    }
```

```java
    private class Itr implements Iterator<E> {
		// 下次要遍历的节点
        private Node<E> nextNode;
		// 下次要遍历的item
        private E nextItem;
		// 上次返回的节点
        private Node<E> lastRet;

        Itr() {
            advance();
        }
		// 初始化函数
        private E advance() {
            lastRet = nextNode;
            E x = nextItem;
            Node<E> pred, p;
            // 初始化
            if (nextNode == null) {
                // 获取第一个有效节点
                p = first();
                pred = null;
            } else {
                // 否则获取下一个节点
                pred = nextNode;
                p = succ(nextNode);
            }

            for (;;) {
                // 链表为空
                if (p == null) {
                    nextNode = null;
                    nextItem = null;
                    return x;
                }
                E item = p.item;
                // 获取下一个元素
                if (item != null) {
                    nextNode = p;
                    nextItem = item;
                    return x;
                } else {
                    // 获取p的下一个节点
                    Node<E> next = succ(p);
                    // 删除节点p
                    if (pred != null && next != null)
                        pred.casNext(p, next);
                    p = next;
                }
            }
        }

        public boolean hasNext() {
            return nextNode != null;
        }

        public E next() {
            if (nextNode == null) throw new NoSuchElementException();
            return advance();
        }

        public void remove() {
            Node<E> l = lastRet;
            if (l == null) throw new IllegalStateException();
            // rely on a future traversal to relink.
            l.item = null;
            lastRet = null;
        }
    }
```

