# LinkedHashMap

```java
public class LinkedHashMap<K,V>
    extends HashMap<K,V> implements implements Map<K,V>
```

LinkedHashMap是HashMap的子类.

在看一下其内部类entry，继承自HashMap的Node

```java
static class Entry<K,V> extends HashMap.Node<K,V> {
    Entry<K,V> before, after;
    Entry(int hash, K key, V value, Node<K,V> next) {
        super(hash, key, value, next);
    }
}
```

## Field

```java
    // 队列头
	transient LinkedHashMap.Entry<K,V> head;
	// 队列尾
    transient LinkedHashMap.Entry<K,V> tail;
    final boolean accessOrder;
```



## 构造方法

```java
    public LinkedHashMap(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
        accessOrder = false;
    }
    public LinkedHashMap(int initialCapacity) {
        super(initialCapacity);
        accessOrder = false;
    }
    public LinkedHashMap() {
        super();
        accessOrder = false;
    }
    public LinkedHashMap() {
        super();
        accessOrder = false;
    }
    public LinkedHashMap(Map<? extends K, ? extends V> m) {
        super();
        accessOrder = false;
        putMapEntries(m, false);
    }
    public LinkedHashMap(int initialCapacity,
                         float loadFactor,
                         boolean accessOrder) {
        super(initialCapacity, loadFactor);
        this.accessOrder = accessOrder;
    }
```

可见其使用的是HashMap的初始容量以及加载因子，扩容机制也是相同的；以及链表转换为红黑树的方法。



## 放入一个元素

```java
    // 这个放入操作，就是HashMap的操作了
	public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        // 如果table为null，或者长度为0，则创建存储数据的数组
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        // 如果对应的位置没有数据，则直接放入一个新的node节点
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        else {
            Node<K,V> e; K k;
            // 如果对应的节点有数据且key相等，就让e指向节点
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                for (int binCount = 0; ; ++binCount) {
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            // 如果e不为null，说明插入时，对应的节点是有数据的
            // 如果允许覆盖呢，就使用新的value覆盖旧值
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                // 把e节点方法链表的最后一个
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
	// 把修改后的节点放到链表的最后一个
    void afterNodeAccess(Node<K,V> e) { // move node to last
        LinkedHashMap.Entry<K,V> last;
        if (accessOrder && (last = tail) != e) {
            LinkedHashMap.Entry<K,V> p =
                (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
            p.after = null;
            if (b == null)
                head = a;
            else
                b.after = a;
            if (a != null)
                a.before = b;
            else
                last = b;
            if (last == null)
                head = p;
            else {
                p.before = last;
                last.after = p;
            }
            tail = p;  // 即尾节点是p
            ++modCount;
        }
    }

    void afterNodeInsertion(boolean evict) { // possibly remove eldest
        LinkedHashMap.Entry<K,V> first;
        // 如果条件为true，则删除第一个节点
        if (evict && (first = head) != null && removeEldestEntry(first)) {
            K key = first.key;
            removeNode(hash(key), key, null, false, true);
        }
    }
	// 是否删除第一个节点
    protected boolean removeEldestEntry(Map.Entry<K,V> eldest) {
        return false;
    }
```



## 得到一个元素

```java
    // 获取key对应的value
	public V get(Object key) {
        Node<K,V> e;
        if ((e = getNode(hash(key), key)) == null)
            return null;
        if (accessOrder)
            afterNodeAccess(e);
        return e.value;
    }
	// 如果没有找到对应的节点，则返回默认的值
    public V getOrDefault(Object key, V defaultValue) {
       Node<K,V> e;
       if ((e = getNode(hash(key), key)) == null)
           return defaultValue;
       if (accessOrder)
           afterNodeAccess(e);
       return e.value;
   }
	// HashMap中实现--得到一个key对应的value
    final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
            if (first.hash == hash && // 检查第一个元素，如果key相等，则直接返回第一个元素
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
            if ((e = first.next) != null) { // 如果对应位置上的元素不止一个
                if (first instanceof TreeNode)// 查看是否是TreeNode，是则红黑树查找
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                do {// 不是则遍历对应位置上所有的元素，查找key对应的node
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
    }
```



## 删除一个元素

删除元素，使用的是HashMap中的删除元素方法.

## 遍历元素

### keySet

```java
    public Set<K> keySet() {
        Set<K> ks = keySet;
        if (ks == null) {
            ks = new LinkedKeySet();
            keySet = ks;
        }
        return ks;
    }

    final class LinkedKeySet extends AbstractSet<K> {
        public final int size()                 { return size; }
        public final void clear()               { LinkedHashMap.this.clear(); }
        public final Iterator<K> iterator() {
            return new LinkedKeyIterator();
        }
        public final boolean contains(Object o) { return containsKey(o); }
        public final boolean remove(Object key) {
            return removeNode(hash(key), key, null, false, true) != null;
        }
        public final Spliterator<K> spliterator()  {
            return Spliterators.spliterator(this, Spliterator.SIZED |
                                            Spliterator.ORDERED |
                                            Spliterator.DISTINCT);
        }
        public final void forEach(Consumer<? super K> action) {
            if (action == null)
                throw new NullPointerException();
            int mc = modCount;
            for (LinkedHashMap.Entry<K,V> e = head; e != null; e = e.after)
                action.accept(e.key);
            if (modCount != mc)
                throw new ConcurrentModificationException();
        }
    }
```

看一下这个具体的遍历器全貌:

```java
    final class LinkedKeyIterator extends LinkedHashIterator
        implements Iterator<K> {
        public final K next() { return nextNode().getKey(); } // 把获取到的node的key返回
    }
    
	// 抽象的遍历器父类
    abstract class LinkedHashIterator {
        LinkedHashMap.Entry<K,V> next; // 下一个节点
        LinkedHashMap.Entry<K,V> current; // 当前节点
        int expectedModCount;
        LinkedHashIterator() {
            next = head; // 从链表开头遍历
            expectedModCount = modCount;
            current = null;
        }
		// 判断是否有下一个节点
        public final boolean hasNext() {
            return next != null;
        }
		// 下一个节点
        final LinkedHashMap.Entry<K,V> nextNode() {
            LinkedHashMap.Entry<K,V> e = next;
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            if (e == null)
                throw new NoSuchElementException();
            current = e;
            next = e.after;  // next的下一个节点
            return e;
        }
		// 删除一个元素
        public final void remove() {
            Node<K,V> p = current;
            if (p == null)
                throw new IllegalStateException();
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            current = null;
            K key = p.key;
            // 删除一个节点，为HashMap中的实现
            removeNode(hash(key), key, null, false, false);
            expectedModCount = modCount;
        }
    }
```

### Values

这里就不过多注释了，相信大家对内容都是一目了然。

```java
    public Collection<V> values() {
        Collection<V> vs = values;
        if (vs == null) {
            vs = new LinkedValues();
            values = vs;
        }
        return vs;
    }

    final class LinkedValues extends AbstractCollection<V> {
        public final int size()                 { return size; }
        public final void clear()               { LinkedHashMap.this.clear(); }
        public final Iterator<V> iterator() {
            return new LinkedValueIterator();
        }
        public final boolean contains(Object o) { return containsValue(o); }
        public final Spliterator<V> spliterator() {
            return Spliterators.spliterator(this, Spliterator.SIZED |
                                            Spliterator.ORDERED);
        }
        public final void forEach(Consumer<? super V> action) {
            if (action == null)
                throw new NullPointerException();
            int mc = modCount;
            for (LinkedHashMap.Entry<K,V> e = head; e != null; e = e.after)
                action.accept(e.value);
            if (modCount != mc)
                throw new ConcurrentModificationException();
        }
    }
	// 此遍历器就是把获取到的node的value值返回就可以了
    final class LinkedValueIterator extends LinkedHashIterator
        implements Iterator<V> {
        public final V next() { return nextNode().value; }
    }
```



### entrySet

```java
    public Set<Map.Entry<K,V>> entrySet() {
        Set<Map.Entry<K,V>> es;
        return (es = entrySet) == null ? (entrySet = new LinkedEntrySet()) : es;
    }

    final class LinkedEntrySet extends AbstractSet<Map.Entry<K,V>> {
        public final int size()                 { return size; }
        public final void clear()               { LinkedHashMap.this.clear(); }
        public final Iterator<Map.Entry<K,V>> iterator() {
            return new LinkedEntryIterator();
        }
        public final boolean contains(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> e = (Map.Entry<?,?>) o;
            Object key = e.getKey();
            Node<K,V> candidate = getNode(hash(key), key);
            return candidate != null && candidate.equals(e);
        }
        public final boolean remove(Object o) {
            if (o instanceof Map.Entry) {
                Map.Entry<?,?> e = (Map.Entry<?,?>) o;
                Object key = e.getKey();
                Object value = e.getValue();
                return removeNode(hash(key), key, value, true, true) != null;
            }
            return false;
        }
        public final Spliterator<Map.Entry<K,V>> spliterator() {
            return Spliterators.spliterator(this, Spliterator.SIZED |
                                            Spliterator.ORDERED |
                                            Spliterator.DISTINCT);
        }
        public final void forEach(Consumer<? super Map.Entry<K,V>> action) {
            if (action == null)
                throw new NullPointerException();
            int mc = modCount;
            for (LinkedHashMap.Entry<K,V> e = head; e != null; e = e.after)
                action.accept(e);
            if (modCount != mc)
                throw new ConcurrentModificationException();
        }
    }
	// 把查找到的node返回
    final class LinkedEntryIterator extends LinkedHashIterator
        implements Iterator<Map.Entry<K,V>> {
        public final Map.Entry<K,V> next() { return nextNode(); }
    }
```



## 扩容

HashMap的扩容机制。



也就是LinkedHashMap插入，删除，获取等操作都是依据与HashMap去进行实现的，此处的操作和HashMap没太大区别；查找就有点不一样了，LinkedHashMap维护了一个链表结构，存储了所有的元素节点，查找是从此链表中遍历进行操作的。