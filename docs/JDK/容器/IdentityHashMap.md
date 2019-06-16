# IdentityHashMap

那今天看一下这个容器可以做什么呢？其实现的原理又是什么呢？

Talk is cheap, show me you code.  咱们就来探寻一下答案把.

## Field

```java
	// 初始化容量
    private static final int DEFAULT_CAPACITY = 32;

    // 最小容量
    private static final int MINIMUM_CAPACITY = 4;

  	// 最大容量
    private static final int MAXIMUM_CAPACITY = 1 << 29;

   // 存储数据的地方
    transient Object[] table; // non-private to simplify nested class access

   // 容器的大小
    int size;

    // 记录修改的次数
    transient int modCount;

  // 当key为null时，使用此key进行代替
    static final Object NULL_KEY = new Object();
```

## 构造函数

```java
    public IdentityHashMap() {
        init(DEFAULT_CAPACITY);
    }

    public IdentityHashMap(int expectedMaxSize) {
        if (expectedMaxSize < 0)
            throw new IllegalArgumentException("expectedMaxSize is negative: "
                                               + expectedMaxSize);
        init(capacity(expectedMaxSize));
    }

    private static int capacity(int expectedMaxSize) {
        // assert expectedMaxSize >= 0;
        return
            (expectedMaxSize > MAXIMUM_CAPACITY / 3) ? MAXIMUM_CAPACITY :
            (expectedMaxSize <= 2 * MINIMUM_CAPACITY / 3) ? MINIMUM_CAPACITY :
            Integer.highestOneBit(expectedMaxSize + (expectedMaxSize << 1));
    }
	// 最终就是实例化table数组
    private void init(int initCapacity) {
        table = new Object[2 * initCapacity];
    }
```



## 添加操作

```java
    public V put(K key, V value) {
        // 从这个可以看出此容器可以存储key为null的值
        final Object k = maskNull(key);
        retryAfterResize: for (;;) {
            final Object[] tab = table;
            final int len = tab.length;
            int i = hash(k, len); // 得到对应的存储位置
			// 如果对应的位置上有数据，则再换一个位置
            for (Object item; (item = tab[i]) != null;
                 i = nextKeyIndex(i, len)) {
                if (item == k) {
                    @SuppressWarnings("unchecked")
                    V oldValue = (V) tab[i + 1]; // 保存原来的值
                    tab[i + 1] = value; // 存入新的值
                    return oldValue; // 返回原来的值
                }
            }

            final int s = size + 1;
			// 现在使用超过三分之一，则进行扩容；扩容每次都是扩容2倍
            if (s + (s << 1) > len && resize(len))
                continue retryAfterResize;

            modCount++;
            tab[i] = k;// 可见此存储值特点，key为value按序存储到数组中；前面是key，后面是value
            tab[i + 1] = value;
            size = s;  // 更新大小
            return null;
        }
    }

    private static Object maskNull(Object key) {
        return (key == null ? NULL_KEY : key);
    }

    private static int hash(Object x, int length) {
        int h = System.identityHashCode(x);
        // Multiply by -127, and left-shift to use least bit as part of hash
        return ((h << 1) - (h << 8)) & (length - 1);
    }
	// 换到后面第二个位置(如果原来为1，则下一次为3)
    private static int nextKeyIndex(int i, int len) {
        return (i + 2 < len ? i + 2 : 0);
    }
	// 给容器设置一个新容量
    private boolean resize(int newCapacity) {
        // assert (newCapacity & -newCapacity) == newCapacity; // power of 2
        int newLength = newCapacity * 2;

        Object[] oldTable = table;
        int oldLength = oldTable.length;
        if (oldLength == 2 * MAXIMUM_CAPACITY) { // can't expand any further
            if (size == MAXIMUM_CAPACITY - 1)
                throw new IllegalStateException("Capacity exhausted.");
            return false;
        }
        if (oldLength >= newLength)
            return false;

        Object[] newTable = new Object[newLength];
		// 那原来table的值存储到新的容器中
        for (int j = 0; j < oldLength; j += 2) {
            Object key = oldTable[j];
            if (key != null) {
                Object value = oldTable[j+1];
                oldTable[j] = null;
                oldTable[j+1] = null;
                int i = hash(key, newLength);
                while (newTable[i] != null)
                    i = nextKeyIndex(i, newLength);
                newTable[i] = key;
                newTable[i + 1] = value;
            }
        }
        table = newTable;
        return true;
    }
```



## 删除操作

```java
    public V remove(Object key) {
        Object k = maskNull(key); // 获取key
        Object[] tab = table; // 容器存储数组
        int len = tab.length; // 容器长度
        int i = hash(k, len); // 存储位置

        while (true) {
            Object item = tab[i]; // 获取key值
            if (item == k) { // key值相等，则说明找到了
                modCount++;
                size--;
                @SuppressWarnings("unchecked")
                V oldValue = (V) tab[i + 1]; // 获取key对应的value
                tab[i + 1] = null;  // 删除value
                tab[i] = null;	// 阐述key
                closeDeletion(i);
                return oldValue; // 返回删除的value
            }
            if (item == null)
                return null;
            i = nextKeyIndex(i, len);
        }
    }
	// 因为有可能hash-碰撞，所以每次删除操作后，要rehash
	// 什么意思呢？ 就是每次插入时，hash冲突的话，会往后放，现在删除了，就看一下有没有和删除的key的hash冲突的值，如果有，则把哪个现在删除的位置上来.
    private void closeDeletion(int d) {
        Object[] tab = table;
        int len = tab.length;

        Object item;
        for (int i = nextKeyIndex(d, len); (item = tab[i]) != null;
             i = nextKeyIndex(i, len) ) {
            int r = hash(item, len);
            if ((i < r && (r <= d || d <= i)) || (r <= d && d <= i)) {
                tab[d] = item;
                tab[d + 1] = tab[i + 1];
                tab[i] = null;
                tab[i + 1] = null;
                d = i;
            }
        }
    }
```

## 获取一个值

```java
    public V get(Object key) {
        Object k = maskNull(key); // 得到key
        Object[] tab = table;
        int len = tab.length;
        int i = hash(k, len); // 得到存储位置
        while (true) {
            Object item = tab[i];
            if (item == k) // 如果key相等,则返回对应的value
                return (V) tab[i + 1];
            if (item == null) // 为空,说明没有对应的value
                return null;
            i = nextKeyIndex(i, len); // 否则呢,就查找下一个
        }
    }
```



## 遍历操作

### keySet遍历

```java
    public Set<K> keySet() {
        Set<K> ks = keySet;
        if (ks == null) {
            ks = new KeySet();
            keySet = ks;
        }
        return ks;
    }
// 一般都是遍历key,看一下这个遍历器的使用把
    private class KeyIterator extends IdentityHashMapIterator<K> {
        @SuppressWarnings("unchecked")
        // 返回下一个key
        public K next() {
            return (K) unmaskNull(traversalTable[nextIndex()]);
        }
    }
	// 下一个索引的值
    protected int nextIndex() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        if (!indexValid && !hasNext())
            throw new NoSuchElementException();

        indexValid = false;
        lastReturnedIndex = index;
        index += 2;  // key值查找都是间隔2,因为key的下一个存储的是value
        return lastReturnedIndex;
    }
	// 判断是否有下一个元素
    public boolean hasNext() {
        Object[] tab = traversalTable;
        for (int i = index; i < tab.length; i+=2) {
            Object key = tab[i];
            if (key != null) {
                index = i;
                return indexValid = true;
            }
        }
        index = tab.length;
        return false;
    }

```

这个keySet是个内部类实现, 看一下这个类的实现把.已经用到了

```java
private class KeySet extends AbstractSet<K> {
    	// 创建一个遍历器,进行key的遍历
        public Iterator<K> iterator() {
            return new KeyIterator();
        }
    	// 得到大小
        public int size() {
            return size;
        }
    	// 是否包含某个key
        public boolean contains(Object o) {
            return containsKey(o);
        }
    	// 删除某个key
        public boolean remove(Object o) {
            int oldSize = size;
            IdentityHashMap.this.remove(o);
            return size != oldSize;
        }
		// 删除一个集合
        public boolean removeAll(Collection<?> c) {
            Objects.requireNonNull(c);
            boolean modified = false;
            // 可见喽,也是遍历一个一个删除的
            for (Iterator<K> i = iterator(); i.hasNext(); ) {
                if (c.contains(i.next())) {
                    i.remove();
                    modified = true;
                }
            }
            return modified;
        }
    	// 清空操作
        public void clear() {
            IdentityHashMap.this.clear();
        }
        public int hashCode() {
            int result = 0;
            for (K key : this)
                result += System.identityHashCode(key);
            return result;
        }
        public Object[] toArray() {
            return toArray(new Object[0]);
        }
        @SuppressWarnings("unchecked")
        public <T> T[] toArray(T[] a) {
            int expectedModCount = modCount;
            int size = size();
            if (a.length < size)
                a = (T[]) Array.newInstance(a.getClass().getComponentType(), size);
            Object[] tab = table;
            int ti = 0;
            for (int si = 0; si < tab.length; si += 2) {
                Object key;
                if ((key = tab[si]) != null) { // key present ?
                    // more elements than expected -> concurrent modification from other thread
                    if (ti >= size) {
                        throw new ConcurrentModificationException();
                    }
                    a[ti++] = (T) unmaskNull(key); // unmask key
                }
            }
            // fewer elements than expected or concurrent modification from other thread detected
            if (ti < size || expectedModCount != modCount) {
                throw new ConcurrentModificationException();
            }
            // final null marker as per spec
            if (ti < a.length) {
                a[ti] = null;
            }
            return a;
        }

        public Spliterator<K> spliterator() {
            return new KeySpliterator<>(IdentityHashMap.this, 0, -1, 0, 0);
        }
    }
```

在看一下这个内部抽象类的作用(遍历时会使用到):

```java
    private abstract class IdentityHashMapIterator<T> implements Iterator<T> {
        int index = (size != 0 ? 0 : table.length); // current slot.
        int expectedModCount = modCount; // to support fast-fail
        int lastReturnedIndex = -1;      // to allow remove()
        boolean indexValid; // To avoid unnecessary next computation
        Object[] traversalTable = table; // reference to main table or copy

        public boolean hasNext() {  // 判断是否有下一个
            Object[] tab = traversalTable;
            for (int i = index; i < tab.length; i+=2) {
                Object key = tab[i];
                if (key != null) {
                    index = i;
                    return indexValid = true;
                }
            }
            index = tab.length;
            return false;
        }

        protected int nextIndex() { // 下一个索引的值
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            if (!indexValid && !hasNext())
                throw new NoSuchElementException();
            indexValid = false;
            lastReturnedIndex = index;
            index += 2;
            return lastReturnedIndex;
        }
		// 删除操作
        public void remove() {
            if (lastReturnedIndex == -1)
                throw new IllegalStateException();
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();

            expectedModCount = ++modCount;
            int deletedSlot = lastReturnedIndex;
            lastReturnedIndex = -1;
            // back up index to revisit new contents after deletion
            index = deletedSlot;
            indexValid = false;

            Object[] tab = traversalTable;
            int len = tab.length;

            int d = deletedSlot;
            Object key = tab[d];
            tab[d] = null;        // 具体的删除操作
            tab[d + 1] = null;

            // If traversing a copy, remove in real table.
            // We can skip gap-closure on copy.
            if (tab != IdentityHashMap.this.table) {
                IdentityHashMap.this.remove(key);
                expectedModCount = modCount;
                return;
            }
            size--;
            Object item;
            for (int i = nextKeyIndex(d, len); (item = tab[i]) != null;
                 i = nextKeyIndex(i, len)) {
                int r = hash(item, len);
                // See closeDeletion for explanation of this conditional
                if ((i < r && (r <= d || d <= i)) ||
                    (r <= d && d <= i)) {
					// 把原来的内容拷贝到一个新的数组中,这样再次获取数据时,就不会得到删除的值
                    if (i < deletedSlot && d >= deletedSlot &&
                        traversalTable == IdentityHashMap.this.table) {
                        int remaining = len - deletedSlot;
                        Object[] newTable = new Object[remaining];
                        System.arraycopy(tab, deletedSlot,
                                         newTable, 0, remaining);
                        traversalTable = newTable;
                        index = 0;
                    }

                    tab[d] = item;
                    tab[d + 1] = tab[i + 1];
                    tab[i] = null;
                    tab[i + 1] = null;
                    d = i;
                }
            }
        }
    }
```





### value遍历

```java
public Collection<V> values() {
        Collection<V> vs = values;
        if (vs == null) {
            vs = new Values();
            values = vs;
        }
        return vs;
    }


```

其也有一个遍历器类:

```java
    // 这里遍历器内部类
	private class ValueIterator extends IdentityHashMapIterator<V> {
        @SuppressWarnings("unchecked")
        public V next() {
            return (V) traversalTable[nextIndex() + 1]; // 这里注意一下,修改了要获取值的索引值,这里直接返回的是value
        }
    }
```



value遍历也有一个内部类实现,可以key遍历的差不多,看一下把:

```java
    private class Values extends AbstractCollection<V> {
        public Iterator<V> iterator() {
            return new ValueIterator();
        }
        public int size() {
            return size;
        }
        public boolean contains(Object o) {
            return containsValue(o);
        }
        public boolean remove(Object o) {
            for (Iterator<V> i = iterator(); i.hasNext(); ) {
                if (i.next() == o) {
                    i.remove();
                    return true;
                }
            }
            return false;
        }
        public void clear() {
            IdentityHashMap.this.clear();
        }
        public Object[] toArray() {
            return toArray(new Object[0]);
        }
        @SuppressWarnings("unchecked")
        public <T> T[] toArray(T[] a) {
            int expectedModCount = modCount;
            int size = size();
            if (a.length < size)
                a = (T[]) Array.newInstance(a.getClass().getComponentType(), size);
            Object[] tab = table;
            int ti = 0;
            for (int si = 0; si < tab.length; si += 2) {
                if (tab[si] != null) { // key present ?
                    // more elements than expected -> concurrent modification from other thread
                    if (ti >= size) {
                        throw new ConcurrentModificationException();
                    }
                    a[ti++] = (T) tab[si+1]; // copy value
                }
            }
            // fewer elements than expected or concurrent modification from other thread detected
            if (ti < size || expectedModCount != modCount) {
                throw new ConcurrentModificationException();
            }
            // final null marker as per spec
            if (ti < a.length) {
                a[ti] = null;
            }
            return a;
        }

        public Spliterator<V> spliterator() {
            return new ValueSpliterator<>(IdentityHashMap.this, 0, -1, 0, 0);
        }
    }
```



### entrySet遍历

```java
    public Set<Map.Entry<K,V>> entrySet() {
        Set<Map.Entry<K,V>> es = entrySet;
        if (es != null)
            return es;
        else
            return entrySet = new EntrySet();
    }
```

这里当然差不多了,也有两个内部类,一个遍历器,另一个entrySet内部类:

这个遍历器有点意思,是不是. 来看一下:

这样一看, 是不是就一目了然了.....

```java
   private class EntryIterator
        extends IdentityHashMapIterator<Map.Entry<K,V>>
    {
        private Entry lastReturnedEntry;

        public Map.Entry<K,V> next() {
            lastReturnedEntry = new Entry(nextIndex());
            return lastReturnedEntry;
        }

        public void remove() {
            lastReturnedIndex =
                ((null == lastReturnedEntry) ? -1 : lastReturnedEntry.index);
            super.remove();
            lastReturnedEntry.index = lastReturnedIndex;
            lastReturnedEntry = null;
        }
		// 内部类,实现了entry
        private class Entry implements Map.Entry<K,V> {
            private int index;
			// 创建方法
            private Entry(int index) {
                this.index = index;  // 记录要查询的数据索引位置
            }

            @SuppressWarnings("unchecked")
            public K getKey() {
                checkIndexForEntryUse();
                return (K) unmaskNull(traversalTable[index]); // 获取key
            }

            @SuppressWarnings("unchecked")
            public V getValue() {
                checkIndexForEntryUse();
                return (V) traversalTable[index+1]; // 获取value
            }

            @SuppressWarnings("unchecked")
            public V setValue(V value) {
                checkIndexForEntryUse();
                V oldValue = (V) traversalTable[index+1];
                traversalTable[index+1] = value;
                if (traversalTable != IdentityHashMap.this.table)
                    put((K) traversalTable[index], value);
                return oldValue;
            }

            public boolean equals(Object o) {
                if (index < 0)
                    return super.equals(o);

                if (!(o instanceof Map.Entry))
                    return false;
                Map.Entry<?,?> e = (Map.Entry<?,?>)o;
                return (e.getKey() == unmaskNull(traversalTable[index]) &&
                       e.getValue() == traversalTable[index+1]);
            }

            public int hashCode() {
                if (lastReturnedIndex < 0)
                    return super.hashCode();

                return (System.identityHashCode(unmaskNull(traversalTable[index])) ^
                       System.identityHashCode(traversalTable[index+1]));
            }

            public String toString() {
                if (index < 0)
                    return super.toString();

                return (unmaskNull(traversalTable[index]) + "="
                        + traversalTable[index+1]);
            }

            private void checkIndexForEntryUse() {
                if (index < 0)
                    throw new IllegalStateException("Entry was removed");
            }
        }
    }
```



```java
private class EntrySet extends AbstractSet<Map.Entry<K,V>> {
    	// EntrySet遍历器
        public Iterator<Map.Entry<K,V>> iterator() {
            return new EntryIterator();
        }
        public boolean contains(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> entry = (Map.Entry<?,?>)o;
            return containsMapping(entry.getKey(), entry.getValue());
        }
        public boolean remove(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> entry = (Map.Entry<?,?>)o;
            return removeMapping(entry.getKey(), entry.getValue());
        }
        public int size() {
            return size;
        }
        public void clear() {
            IdentityHashMap.this.clear();
        }
        public boolean removeAll(Collection<?> c) {
            Objects.requireNonNull(c);
            boolean modified = false;
            // 循环遍历,进行删除
            for (Iterator<Map.Entry<K,V>> i = iterator(); i.hasNext(); ) {
                if (c.contains(i.next())) {
                    i.remove();
                    modified = true;
                }
            }
            return modified;
        }

        public Object[] toArray() {
            return toArray(new Object[0]);
        }

        @SuppressWarnings("unchecked")
        public <T> T[] toArray(T[] a) {
            int expectedModCount = modCount;
            int size = size();
            if (a.length < size)
                a = (T[]) Array.newInstance(a.getClass().getComponentType(), size);
            Object[] tab = table;
            int ti = 0;
            for (int si = 0; si < tab.length; si += 2) {
                Object key;
                if ((key = tab[si]) != null) { // key present ?
                    // more elements than expected -> concurrent modification from other thread
                    if (ti >= size) {
                        throw new ConcurrentModificationException();
                    }
                    a[ti++] = (T) new AbstractMap.SimpleEntry<>(unmaskNull(key), tab[si + 1]);
                }
            }
            // fewer elements than expected or concurrent modification from other thread detected
            if (ti < size || expectedModCount != modCount) {
                throw new ConcurrentModificationException();
            }
            // final null marker as per spec
            if (ti < a.length) {
                a[ti] = null;
            }
            return a;
        }

        public Spliterator<Map.Entry<K,V>> spliterator() {
            return new EntrySpliterator<>(IdentityHashMap.this, 0, -1, 0, 0);
        }
    }
```



