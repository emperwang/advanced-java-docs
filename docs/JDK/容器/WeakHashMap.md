# WeakHashMap

## Field

```java
	// 默认初始化大小
    private static final int DEFAULT_INITIAL_CAPACITY = 16;
	// 最大容量
    private static final int MAXIMUM_CAPACITY = 1 << 30;
	// 默认加载因子
    private static final float DEFAULT_LOAD_FACTOR = 0.75f;
	// 存储数据
    Entry<K,V>[] table;
	// 数据的个数
    private int size;
	// 扩容阈值
    private int threshold;
	// 加载因子
    private final float loadFactor;
    /**
     * Reference queue for cleared WeakEntries
     */
    private final ReferenceQueue<Object> queue = new ReferenceQueue<>();
	// 修改的次数
    int modCount;
	// null_key的存储会使用此代替
    private static final Object NULL_KEY = new Object();
    private transient Set<Map.Entry<K,V>> entrySet;
```



## 构造器

```java
    // 指定初始化容量和加载因子
	public WeakHashMap(int initialCapacity, float loadFactor) {
        // 健康性检查
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Initial Capacity: "+
                                               initialCapacity);
        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;

        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal Load factor: "+
                                               loadFactor);
        int capacity = 1;
        while (capacity < initialCapacity)
            capacity <<= 1;
        // 初始化数组
        table = newTable(capacity);
        this.loadFactor = loadFactor;
        threshold = (int)(capacity * loadFactor);
    }
	// 创建数组
    private Entry<K,V>[] newTable(int n) {
        return (Entry<K,V>[]) new Entry<?,?>[n];
    }
	//指定容量，使用默认加载因子
    public WeakHashMap(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR);
    }
	// 使用默认容量，默认加载因子构建容器
    public WeakHashMap() {
        this(DEFAULT_INITIAL_CAPACITY, DEFAULT_LOAD_FACTOR);
    }
```

存储结构:

```java
    private static class Entry<K,V> extends WeakReference<Object> implements Map.Entry<K,V> {
        V value;		// value值
        final int hash;  // hash值
        Entry<K,V> next;	// 链表结构，下一个节点
        /**
         * Creates new entry.
         */
        Entry(Object key, V value,
              ReferenceQueue<Object> queue,
              int hash, Entry<K,V> next) {
            s uper(key, queue);
            this.value = value;
            this.hash  = hash;
            this.next  = next;
        }

        @SuppressWarnings("unchecked")
        // 获取key
        public K getKey() {
            return (K) WeakHashMap.unmaskNull(get());
        }
		// 获取value
        public V getValue() {
            return value;
        }
		// 设置value
        public V setValue(V newValue) {
            V oldValue = value;
            value = newValue;
            return oldValue;
        }
		// 重写value方法
        public boolean equals(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> e = (Map.Entry<?,?>)o;
            K k1 = getKey();
            Object k2 = e.getKey();
            if (k1 == k2 || (k1 != null && k1.equals(k2))) {
                V v1 = getValue();
                Object v2 = e.getValue();
                if (v1 == v2 || (v1 != null && v1.equals(v2)))
                    return true;
            }
            return false;
        }

        public int hashCode() {
            K k = getKey();
            V v = getValue();
            return Objects.hashCode(k) ^ Objects.hashCode(v);
        }

        public String toString() {
            return getKey() + "=" + getValue();
        }
    }
```



## 添加元素

```java
   public V put(K key, V value) {
        Object k = maskNull(key);  // 判断key是不是null，是null则使用NULL_KEY
        int h = hash(k);   // 得到key的hash
        Entry<K,V>[] tab = getTable(); // 获取取出无用entry的table
        int i = indexFor(h, tab.length);
		// 如果有相等的entry，则覆盖value
        for (Entry<K,V> e = tab[i]; e != null; e = e.next) {
            if (h == e.hash && eq(k, e.get())) {
                V oldValue = e.value;
                if (value != oldValue)
                    e.value = value;
                return oldValue;
            }
        }
        modCount++;
        Entry<K,V> e = tab[i];
       // 没有相等，则创建一个新的entry，放在链表后面
        tab[i] = new Entry<>(k, value, queue, h, e);
        if (++size >= threshold) // 如果超出阈值，则扩容
            resize(tab.length * 2);
        return null;
    }
	
	// 返回取出无用的entry后的table
    private Entry<K,V>[] getTable() {
        expungeStaleEntries();
        return table;
    }
	// 把无用的entry删除
	// 因为此key会放在WeakReference中，故当queue中有数据时，此数据就是被回收的entry
	// (此处不是很明白就看一下Reference以及ReferenceQueue)
    private void expungeStaleEntries() {
        // 循环从queue中获取无用的key
        for (Object x; (x = queue.poll()) != null; ) {
            synchronized (queue) {
                @SuppressWarnings("unchecked")
                    Entry<K,V> e = (Entry<K,V>) x;
                int i = indexFor(e.hash, table.length);
			  // 得到无用的entry
                Entry<K,V> prev = table[i];
                Entry<K,V> p = prev;
                while (p != null) {
                    Entry<K,V> next = p.next;
                    if (p == e) {
                        if (prev == e)
                            // 使用下一个entyr覆盖原来的entry
                            table[i] = next;
                        else
                            prev.next = next;
					 // 并把value置为null
                        e.value = null; // Help GC
                        size--; // 数量减1
                        break;
                    }
                    prev = p;
                    p = next;
                }
            }
        }
    }
	// 得到一个key对应的索引位置
    private static int indexFor(int h, int length) {
        return h & (length-1);
    }
```

## 获取元素

```java
    public V get(Object key) {
        Object k = maskNull(key);  // 获取key
        int h = hash(k);
        Entry<K,V>[] tab = getTable(); // 获取table
        int index = indexFor(h, tab.length); // 获取index
        Entry<K,V> e = tab[index]; // 获取对应index的entry
        while (e != null) {
            // 遍历循环key对应的value
            if (e.hash == h && eq(k, e.get()))
                return e.value;
            e = e.next;
        }
        return null;
    }
	// 对比相等
    private static boolean eq(Object x, Object y) {
        return x == y || x.equals(y);
    }
```



## 删除元素

```java
    public V remove(Object key) {
        Object k = maskNull(key);
        int h = hash(k);
        Entry<K,V>[] tab = getTable();
        int i = indexFor(h, tab.length);
        Entry<K,V> prev = tab[i]; // 获取index对应位置的第一个entry
        Entry<K,V> e = prev;

        while (e != null) {
            // 循环找到key对应的entry，并把此entry删除
            Entry<K,V> next = e.next;
            if (h == e.hash && eq(k, e.get())) {
                modCount++;
                size--;
                if (prev == e)
                    tab[i] = next;
                else
                    prev.next = next;
                return e.value;
            }
            prev = e;
            e = next;
        }

        return null;
    }
```



## 遍历容器

遍历抽象类

```java
    private abstract class HashIterator<T> implements Iterator<T> {
        private int index;
        private Entry<K,V> entry;	// 
        private Entry<K,V> lastReturned;  // 上次返回的entry
        // 修改次数；也就是在遍历时，进行了删除或者添加操作，再遍历时就会出现ConcurrentModificationException
        private int expectedModCount = modCount; 
        // 相当于给key增加了一个强引用，避免在遍历期间被回收掉
        private Object nextKey;
        // 同样的作用，给key增加一个强引用，避免key被回收
        private Object currentKey;
		// 得到table长度
        HashIterator() {
            index = isEmpty() ? 0 : table.length;
        }
		// 遍历所有entry，以及entry对应的链表
        public boolean hasNext() {
            Entry<K,V>[] t = table;
            while (nextKey == null) {
                Entry<K,V> e = entry;
                int i = index;
                // 遍历所有entry
                while (e == null && i > 0)
                    e = t[--i];
                entry = e;
                index = i;
                if (e == null) {
                    currentKey = null;
                    return false;
                }
                // 增加强引用
                nextKey = e.get(); // hold on to key in strong ref
                // 遍历list
                if (nextKey == null)
                    entry = entry.next;
            }
            return true;
        }

        /** The common parts of next() across different types of iterators */
        protected Entry<K,V> nextEntry() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            if (nextKey == null && !hasNext())
                throw new NoSuchElementException();
            lastReturned = entry;
            entry = entry.next;
            currentKey = nextKey;
            nextKey = null;
            return lastReturned;
        }
		// 删除操作
        public void remove() {
            if (lastReturned == null)
                throw new IllegalStateException();
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            WeakHashMap.this.remove(currentKey);
            expectedModCount = modCount;
            lastReturned = null;
            currentKey = null;
        }
    }
```



### keySet

```java
    public Set<K> keySet() {
        Set<K> ks = keySet;
        if (ks == null) {
            ks = new KeySet();
            keySet = ks;
        }
        return ks;
    }

    private class KeySet extends AbstractSet<K> {
        public Iterator<K> iterator() {
            return new KeyIterator();
        }

        public int size() {
            return WeakHashMap.this.size();
        }

        public boolean contains(Object o) {
            return containsKey(o);
        }

        public boolean remove(Object o) {
            if (containsKey(o)) {
                WeakHashMap.this.remove(o);
                return true;
            }
            else
                return false;
        }

        public void clear() {
            WeakHashMap.this.clear();
        }

        public Spliterator<K> spliterator() {
            return new KeySpliterator<>(WeakHashMap.this, 0, -1, 0, 0);
        }
    }
```

遍历器

```java
    private class KeyIterator extends HashIterator<K> {
        public K next() {
            return nextEntry().getKey();  // 获取key
        }
    }
```



### values

```java
    public Collection<V> values() {
        Collection<V> vs = values;
        if (vs == null) {
            vs = new Values();
            values = vs;
        }
        return vs;
    }

    private class Values extends AbstractCollection<V> {
        public Iterator<V> iterator() {
            return new ValueIterator();
        }

        public int size() {
            return WeakHashMap.this.size();
        }

        public boolean contains(Object o) {
            return containsValue(o);
        }

        public void clear() {
            WeakHashMap.this.clear();
        }

        public Spliterator<V> spliterator() {
            return new ValueSpliterator<>(WeakHashMap.this, 0, -1, 0, 0);
        }
    }
```

遍历器

```java
    private class ValueIterator extends HashIterator<V> {
        public V next() {
            return nextEntry().value;
        }
    }
```



### entrySet

```java
    public Set<Map.Entry<K,V>> entrySet() {
        Set<Map.Entry<K,V>> es = entrySet;
        return es != null ? es : (entrySet = new EntrySet());
    }

    private class EntrySet extends AbstractSet<Map.Entry<K,V>> {
        // 获取遍历器
        public Iterator<Map.Entry<K,V>> iterator() {
            return new EntryIterator();
        }

        public boolean contains(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> e = (Map.Entry<?,?>)o;
            Entry<K,V> candidate = getEntry(e.getKey());
            return candidate != null && candidate.equals(e);
        }

        public boolean remove(Object o) {
            return removeMapping(o);
        }

        public int size() {
            return WeakHashMap.this.size();
        }

        public void clear() {
            WeakHashMap.this.clear();
        }

        private List<Map.Entry<K,V>> deepCopy() {
            List<Map.Entry<K,V>> list = new ArrayList<>(size());
            for (Map.Entry<K,V> e : this)
                list.add(new AbstractMap.SimpleEntry<>(e));
            return list;
        }

        public Object[] toArray() {
            return deepCopy().toArray();
        }

        public <T> T[] toArray(T[] a) {
            return deepCopy().toArray(a);
        }

        public Spliterator<Map.Entry<K,V>> spliterator() {
            return new EntrySpliterator<>(WeakHashMap.this, 0, -1, 0, 0);
        }
    }
	//  删除操作
    boolean removeMapping(Object o) {
        if (!(o instanceof Map.Entry))
            return false;
        Entry<K,V>[] tab = getTable();
        Map.Entry<?,?> entry = (Map.Entry<?,?>)o;
        Object k = maskNull(entry.getKey());
        int h = hash(k);
        int i = indexFor(h, tab.length);
        Entry<K,V> prev = tab[i];
        Entry<K,V> e = prev;

        while (e != null) {
            Entry<K,V> next = e.next;
            if (h == e.hash && e.equals(entry)) {
                modCount++;
                size--;
                if (prev == e)
                    tab[i] = next;
                else
                    prev.next = next;
                return true;
            }
            prev = e;
            e = next;
        }

        return false;
    }
```

遍历器

```java
    private class EntryIterator extends HashIterator<Map.Entry<K,V>> {
        public Map.Entry<K,V> next() {
            return nextEntry();
        }
    }
```

