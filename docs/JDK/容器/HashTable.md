# HashTable

平时面试肯定少不了问一下HashMap和HashTable有什么区别呢?嗯....一脸得意. 哈哈我可看HashTable是如何实现的呢.这可难不倒我.

当然了心里得以归得以,答案自在code中. 那咱们今天就揭开平时不怎么使用的HashTable的神秘面纱吧.

## Field

```java
	// 存储数据的数据
    private transient Entry<?,?>[] table;
	// entry的数量
    private transient int count;
	// 扩展数据的一个阈值
    private int threshold;
	// 容量*loadFactor = threshold
    private float loadFactor;
	// 操作次数
    private transient int modCount = 0;
	// 最大容量
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```



## 构造方法

```java
    // 设置了初始容量和加载因子的构造器
	public Hashtable(int initialCapacity, float loadFactor) {
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal Load: "+loadFactor);

        if (initialCapacity==0)
            initialCapacity = 1;
        this.loadFactor = loadFactor;
        table = new Entry<?,?>[initialCapacity];
        threshold = (int)Math.min(initialCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
    }
	// 使用默认加载因子0.75
    public Hashtable(int initialCapacity) {
        this(initialCapacity, 0.75f);
    }

	// 使用默认容量11, 加载因子0.75
    public Hashtable() {
        this(11, 0.75f);
    }
	// 设置初始值的构造方法
    public Hashtable(Map<? extends K, ? extends V> t) {
        this(Math.max(2*t.size(), 11), 0.75f);
        putAll(t);
    }
```

数组存储的数值的方式是封装在Entry中, 这是一个内部类, 看一下其实现:

```java
    private static class Entry<K,V> implements Map.Entry<K,V> {
        final int hash;  // hash值
        final K key;	// key
        V value;	// value
        Entry<K,V> next;	// 下一个entry

        protected Entry(int hash, K key, V value, Entry<K,V> next) {
            this.hash = hash;
            this.key =  key;
            this.value = value;
            this.next = next;
        }

        @SuppressWarnings("unchecked")
        protected Object clone() {
            return new Entry<>(hash, key, value,
                                  (next==null ? null : (Entry<K,V>) next.clone()));
        }

        // Map.Entry Ops
        public K getKey() {
            return key;     // 得到key
        }

        public V getValue() {
            return value;	// 返回value
        }

        public V setValue(V value) {
            if (value == null)
                throw new NullPointerException();
            V oldValue = this.value;  // 得到旧值
            this.value = value;		// 设置新值
            return oldValue;		// 返回原来的值
        }

        public boolean equals(Object o) { // 相等的情况,key相等,value相等
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> e = (Map.Entry<?,?>)o;
            return (key==null ? e.getKey()==null : key.equals(e.getKey())) &&
               (value==null ? e.getValue()==null : value.equals(e.getValue()));
        }

        public int hashCode() {
            return hash ^ Objects.hashCode(value);
        }

        public String toString() {
            return key.toString()+"="+value.toString();
        }
    }
```



## 添加一个元素

```java
   // 添加元素到容器中
	public synchronized V put(K key, V value) {
        if (value == null) {
            throw new NullPointerException();
        }
        // Makes sure the key is not already in the hashtable.
        Entry<?,?> tab[] = table;
        int hash = key.hashCode();
        int index = (hash & 0x7FFFFFFF) % tab.length; // 获取要存储位置的方法
        @SuppressWarnings("unchecked")
        Entry<K,V> entry = (Entry<K,V>)tab[index]; // 判断数组位置是否有值
        for(; entry != null ; entry = entry.next) {// 有值则把原来的值覆盖掉
            if ((entry.hash == hash) && entry.key.equals(key)) {
                V old = entry.value;
                entry.value = value;
                return old;
            }
        }
        // 如果对应的位置没有值,则新添加一个entry
        addEntry(hash, key, value, index);
        return null;
    }

    private void addEntry(int hash, K key, V value, int index) {
        modCount++;
        Entry<?,?> tab[] = table;
        if (count >= threshold) {// 使用的容量超过阈值,则扩容
            // Rehash the table if the threshold is exceeded
            rehash();
            tab = table;
            hash = key.hashCode();
            index = (hash & 0x7FFFFFFF) % tab.length;
        }

        // 创建一个新的entry,添加到数据中
        @SuppressWarnings("unchecked")
        Entry<K,V> e = (Entry<K,V>) tab[index];
        tab[index] = new Entry<>(hash, key, value, e);
        count++;
    }
	// 看一下扩容的方式
    protected void rehash() {
        int oldCapacity = table.length;
        Entry<?,?>[] oldMap = table;
        // 每次扩容都是 原来容量*2+1
        int newCapacity = (oldCapacity << 1) + 1;
        // 判断是否大于最大容量,大于则使用最大容量
        if (newCapacity - MAX_ARRAY_SIZE > 0) {
            if (oldCapacity == MAX_ARRAY_SIZE)
                return;
            newCapacity = MAX_ARRAY_SIZE;
        }
        // 使用新容量创建一个数组
        Entry<?,?>[] newMap = new Entry<?,?>[newCapacity];
        modCount++;
        // 重新设置阈值
        threshold = (int)Math.min(newCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
        table = newMap;
        // 把原来数组中的值,设置到新的数组中
        for (int i = oldCapacity ; i-- > 0 ;) {
            for (Entry<K,V> old = (Entry<K,V>)oldMap[i] ; old != null ; ) {
                Entry<K,V> e = old;
                old = old.next;
                int index = (e.hash & 0x7FFFFFFF) % newCapacity;
                e.next = (Entry<K,V>)newMap[index];
                newMap[index] = e;
            }
        }
    }
```



## 删除一个元素

```java
    // 删除一个元素
	public synchronized V remove(Object key) {
        Entry<?,?> tab[] = table;
        int hash = key.hashCode(); // 得到hash值
        int index = (hash & 0x7FFFFFFF) % tab.length; // 得到索引值
        @SuppressWarnings("unchecked")
        Entry<K,V> e = (Entry<K,V>)tab[index];
        // 就是entry的索引,把要删除的元素的前一个元素指向要删除元素的下一个
        for(Entry<K,V> prev = null ; e != null ; prev = e, e = e.next) {
            if ((e.hash == hash) && e.key.equals(key)) {
                modCount++;
                if (prev != null) {
                    prev.next = e.next;
                } else {
                    tab[index] = e.next;
                }
                count--;
                V oldValue = e.value;
                e.value = null;
                return oldValue;
            }
        }
        return null;
    }
```



## 获取一个元素

```java
    public synchronized V get(Object key) {
        Entry<?,?> tab[] = table;
        int hash = key.hashCode();
        int index = (hash & 0x7FFFFFFF) % tab.length; // 获取到索引位置
        // 获取数组对应位置的数组
        for (Entry<?,?> e = tab[index] ; e != null ; e = e.next) {
            if ((e.hash == hash) && e.key.equals(key)) {
                return (V)e.value;
            }
        }
        return null;
    }
```



## 遍历整个容器

### KeySet

```java
    public Set<K> keySet() {
        if (keySet == null) // 此synchronizedSet操作,就是给所有操作加上Synchronized关键字
            keySet = Collections.synchronizedSet(new KeySet(), this);
        return keySet;
    }

    private class KeySet extends AbstractSet<K> {
        public Iterator<K> iterator() {
            return getIterator(KEYS);
        }
        public int size() {
            return count;
        }
        public boolean contains(Object o) {
            return containsKey(o);
        }
        public boolean remove(Object o) {
            return Hashtable.this.remove(o) != null;
        }
        public void clear() {
            Hashtable.this.clear();
        }
    }

    private <T> Iterator<T> getIterator(int type) {
        if (count == 0) {
            return Collections.emptyIterator();
        } else {
            return new Enumerator<>(type, true);
        }
    }
```

看一下这个内部类Enumerator,其作用就是遍历操作的实现

```java
    private class Enumerator<T> implements Enumeration<T>, Iterator<T> {
        Entry<?,?>[] table = Hashtable.this.table; // 获得存储元素的数组
        int index = table.length;	// 长度
        Entry<?,?> entry;
        Entry<?,?> lastReturned; // 上一次获取到的元素
        int type;
        /**
         * Indicates whether this Enumerator is serving as an Iterator
         * or an Enumeration.  (true -> Iterator).
         */
        boolean iterator;

        protected int expectedModCount = modCount;

        Enumerator(int type, boolean iterator) {
            this.type = type;
            this.iterator = iterator;
        }
		// 查看是否有更多的元素存在
        public boolean hasMoreElements() {
            Entry<?,?> e = entry;
            int i = index;
            Entry<?,?>[] t = table;
            // 从后往前获取元素
            while (e == null && i > 0) {
                e = t[--i];
            }
            entry = e;
            index = i;
            return e != null;
        }

        @SuppressWarnings("unchecked")
        // 获取下一个元素
        public T nextElement() {
            Entry<?,?> et = entry;
            int i = index;
            Entry<?,?>[] t = table;
            /* Use locals for faster loop iteration */
            while (et == null && i > 0) {
                et = t[--i];
            }
            entry = et;
            index = i;  // 这里更新了索引,所以才能循环遍历时,获取到不同的值
            if (et != null) {
                Entry<?,?> e = lastReturned = entry;
                entry = e.next;
                // 根据传递的type不同,返回key或者value或者直接返回entry
                return type == KEYS ? (T)e.key : (type == VALUES ? (T)e.value : (T)e);
            }
            throw new NoSuchElementException("Hashtable Enumerator");
        }

        // 判断是否有更多元素
        public boolean hasNext() {
            return hasMoreElements();
        }

        public T next() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            return nextElement();
        }

        public void remove() {
            if (!iterator)
                throw new UnsupportedOperationException();
            if (lastReturned == null)
                throw new IllegalStateException("Hashtable Enumerator");
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
			// 类锁
            synchronized(Hashtable.this) {
                Entry<?,?>[] tab = Hashtable.this.table;
                int index = (lastReturned.hash & 0x7FFFFFFF) % tab.length;
                @SuppressWarnings("unchecked")
                Entry<K,V> e = (Entry<K,V>)tab[index];
                // 要删除元素前一个元素指向要删除元素的下一个元素
                for(Entry<K,V> prev = null; e != null; prev = e, e = e.next) {
                    if (e == lastReturned) {
                        modCount++;
                        expectedModCount++;
                        if (prev == null)
                            tab[index] = e.next;
                        else
                            prev.next = e.next;
                        count--;
                        lastReturned = null;
                        return;
                    }
                }
                throw new ConcurrentModificationException();
            }
        }
    }
```



### Values

```java
   // 这里就是跟上面的keySet很相似,就传递的type类型不一样,为values,也就是查找时返回value值
	
	public Collection<V> values() {
        if (values==null)
            values = Collections.synchronizedCollection(new ValueCollection(),
                                                        this);
        return values;
    }

    private class ValueCollection extends AbstractCollection<V> {
        public Iterator<V> iterator() {
            return getIterator(VALUES);
        }
        public int size() {
            return count;
        }
        public boolean contains(Object o) {
            return containsValue(o);
        }
        public void clear() {
            Hashtable.this.clear();
        }
    }
```



### entrySet

```java
    public Set<Map.Entry<K,V>> entrySet() {
        if (entrySet==null)
            entrySet = Collections.synchronizedSet(new EntrySet(), this);
        return entrySet;
    }

    private class EntrySet extends AbstractSet<Map.Entry<K,V>> {
        // 这里的遍历也是一样了,不同的是每次返回的是entry值
        public Iterator<Map.Entry<K,V>> iterator() {
            return getIterator(ENTRIES);
        }

        public boolean add(Map.Entry<K,V> o) {
            return super.add(o);
        }
		
        public boolean contains(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> entry = (Map.Entry<?,?>)o;
            Object key = entry.getKey();
            Entry<?,?>[] tab = table;
            int hash = key.hashCode();
            int index = (hash & 0x7FFFFFFF) % tab.length;
			// 遍历数组对应位置的entry链表,有相等的则返回true
            for (Entry<?,?> e = tab[index]; e != null; e = e.next)
                if (e.hash==hash && e.equals(entry))
                    return true;
            return false;
        }
		// 删除
        public boolean remove(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> entry = (Map.Entry<?,?>) o;
            Object key = entry.getKey();
            Entry<?,?>[] tab = table;
            int hash = key.hashCode();
            int index = (hash & 0x7FFFFFFF) % tab.length;

            @SuppressWarnings("unchecked")
            Entry<K,V> e = (Entry<K,V>)tab[index];
            // 删除原理一样,把要出元素的前一个元素指向要删除元素的后一个元素
            for(Entry<K,V> prev = null; e != null; prev = e, e = e.next) {
                if (e.hash==hash && e.equals(entry)) {
                    modCount++;
                    if (prev != null)
                        prev.next = e.next;
                    else
                        tab[index] = e.next;
                    count--;
                    e.value = null;
                    return true;
                }
            }
            return false;
        }

        public int size() {
            return count;
        }

        public void clear() {
            Hashtable.this.clear();
        }
    }
```

注意到一个特点吗? HashTable所有的操作方法都有synchrongized关键字进行修饰. 说明什么呢? 

1. 在多线程操作时, 是线程安全的
2. 执行效率慢