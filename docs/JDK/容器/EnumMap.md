# EnumMap

## 示例代码

```java
public class EnumTest {
    
    public enum Color {
        red, blue, black, yellow, green
    }
    
    public static void main(String[] args) {
        EnumMap<Color,String> map = new EnumMap<>(Color.class);
        map.put(Color.yellow, "黄色");
        map.put(Color.blue, "蓝色");
        map.put(Color.red, "红色");
        map.put(Color.black, "黑色");
        map.put(Color.green, "绿色");

        for(Map.Entry<Color,String> entry : map.entrySet()){
            System.out.println(entry.getKey()+":"+entry.getValue());
        }
        System.out.println(map);
    }
}
```



## Field

```java
	// 存储key的class类型
    private final Class<K> keyType;
	// 存储key
    private transient K[] keyUniverse;
	// 存储数据
    private transient Object[] vals;
	// 元素的个数
    private transient int size = 0;
	// value存储为null时，使用这个代替
    private static final Object NULL = new Object() {
        public int hashCode() {
            return 0;
        }

        public String toString() {
            return "java.util.EnumMap.NULL";
        }
    };
    
	private static final Enum<?>[] ZERO_LENGTH_ENUM_ARRAY = new Enum<?>[0];

    private transient Set<Map.Entry<K,V>> entrySet;
```

## 构造函数

```java
	public EnumMap(Class<K> keyType) {
        this.keyType = keyType; // 就是枚举类的类型
        keyUniverse = getKeyUniverse(keyType); // 获取枚举类的实例
        vals = new Object[keyUniverse.length];
    }
	// 参数为一个EnumMap类型，则会把EnumMap参数中的值拷贝到新容器中
    public EnumMap(EnumMap<K, ? extends V> m) {
        keyType = m.keyType;
        keyUniverse = m.keyUniverse;
        vals = m.vals.clone();
        size = m.size;
    }
    public EnumMap(Map<K, ? extends V> m) {
        if (m instanceof EnumMap) {
            EnumMap<K, ? extends V> em = (EnumMap<K, ? extends V>) m;
            keyType = em.keyType;
            keyUniverse = em.keyUniverse;
            vals = em.vals.clone();
            size = em.size;
        } else {
            if (m.isEmpty())
                throw new IllegalArgumentException("Specified map is empty");
            keyType = m.keySet().iterator().next().getDeclaringClass();
            keyUniverse = getKeyUniverse(keyType);
            vals = new Object[keyUniverse.length];
            putAll(m);
        }
    }
```

因为key使用枚举类型，所以在构建函数中，存储key的数组以及存储valuede数组的长度就已经定义好了。

## 添加元素

```java
    public V put(K key, V value) {
        // 检查key的类型是不是定义的keyType类型
        typeCheck(key);
        // key在Enum中的位置
        int index = key.ordinal();
        Object oldValue = vals[index];
        vals[index] = maskNull(value);
        if (oldValue == null)
            size++;
        return unmaskNull(oldValue);
    }
	// 检查要存储的value是不是null，是则存储定义好的NULL
    private Object maskNull(Object value) {
        return (value == null ? NULL : value);
    }

    @SuppressWarnings("unchecked")
    private V unmaskNull(Object value) {
        return (V)(value == NULL ? null : value);
    }
	// 类型检查
    private void typeCheck(K key) {
        Class<?> keyClass = key.getClass();
        if (keyClass != keyType && keyClass.getSuperclass() != keyType)
            throw new ClassCastException(keyClass + " != " + keyType);
    }
```

## 获取元素

```java
    public V get(Object key) {
        return (isValidKey(key) ?
                unmaskNull(vals[((Enum<?>)key).ordinal()]) : null);
    }
	// 检验key的类或者其父类是不是keyType类型
    private boolean isValidKey(Object key) {
        if (key == null)
            return false;
        Class<?> keyClass = key.getClass();
        return keyClass == keyType || keyClass.getSuperclass() == keyType;
    }
```

这里涉及到EnumMap的数据的一个存储，其key值存储在keyUniverse中，value中存储在vals中。那么是如何联系起来的呢？

key存储在keyUniverse中时，key会有ordinal值，那么value也会存储在vals中的相应的位置。

## 删除元素

```java
    public V remove(Object key) {
        if (!isValidKey(key))
            return null;
        int index = ((Enum<?>)key).ordinal();
        Object oldValue = vals[index];
        vals[index] = null;    // 把相应位置的value值存储为null
        if (oldValue != null)
            size--;
        return unmaskNull(oldValue);
    }
```



## 遍历集合

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
            return size;
        }
        public boolean contains(Object o) {
            return containsKey(o);
        }
        public boolean remove(Object o) {
            int oldSize = size;
            EnumMap.this.remove(o);
            return size != oldSize;
        }
        public void clear() {
            EnumMap.this.clear();
        }
    }
```

看一下这个遍历器

```java
    private class KeyIterator extends EnumMapIterator<K> {
        public K next() {
            if (!hasNext())
                throw new NoSuchElementException();
            lastReturnedIndex = index++;
            return keyUniverse[lastReturnedIndex]; // 返回index索引下的key值
        }
    }
```

看一下遍历器的父类

```java
    private abstract class EnumMapIterator<T> implements Iterator<T> {
        // Lower bound on index of next element to return
        int index = 0;

        // Index of last returned element, or -1 if none
        int lastReturnedIndex = -1;
		// 是否有下一个元素
        public boolean hasNext() {
            // 此while循环，是找到值不为null的下标位置
            while (index < vals.length && vals[index] == null)
                index++;
            return index != vals.length;
        }
		// 把上次遍历到的值，删除掉
        public void remove() {
            checkLastReturnedIndex();
            if (vals[lastReturnedIndex] != null) {
                vals[lastReturnedIndex] = null;
                size--;
            }
            lastReturnedIndex = -1;
        }

        private void checkLastReturnedIndex() {
            if (lastReturnedIndex < 0)
                throw new IllegalStateException();
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
            return size;
        }
        public boolean contains(Object o) {
            return containsValue(o);
        }
        public boolean remove(Object o) {
            o = maskNull(o);
            for (int i = 0; i < vals.length; i++) {
                if (o.equals(vals[i])) {
                    vals[i] = null;
                    size--;
                    return true;
                }
            }
            return false;
        }
        public void clear() {
            EnumMap.this.clear();
        }
    }
```

遍历器:

```java
    private class ValueIterator extends EnumMapIterator<V> {
        public V next() {
            if (!hasNext())
                throw new NoSuchElementException();
            lastReturnedIndex = index++;
            return unmaskNull(vals[lastReturnedIndex]);  // 返回value的值；从vals数组中查找
        }
    }
```



### EntrySet

```java
    public Set<Map.Entry<K,V>> entrySet() {
        Set<Map.Entry<K,V>> es = entrySet;
        if (es != null)
            return es;
        else
            return entrySet = new EntrySet();
    }

    private class EntrySet extends AbstractSet<Map.Entry<K,V>> {
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
            EnumMap.this.clear();
        }
        public Object[] toArray() {
            return fillEntryArray(new Object[size]);
        }
        @SuppressWarnings("unchecked")
        public <T> T[] toArray(T[] a) {
            int size = size();
            if (a.length < size)
                a = (T[])java.lang.reflect.Array
                    .newInstance(a.getClass().getComponentType(), size);
            if (a.length > size)
                a[size] = null;
            return (T[]) fillEntryArray(a);
        }
        private Object[] fillEntryArray(Object[] a) {
            int j = 0;
            for (int i = 0; i < vals.length; i++)
                if (vals[i] != null)
                    a[j++] = new AbstractMap.SimpleEntry<>(
                        keyUniverse[i], unmaskNull(vals[i]));
            return a;
        }
    }
```

遍历器:

```java
    private class EntryIterator extends EnumMapIterator<Map.Entry<K,V>> {
        private Entry lastReturnedEntry;
		// 获取下一个
        public Map.Entry<K,V> next() {
            if (!hasNext())
                throw new NoSuchElementException();
            lastReturnedEntry = new Entry(index++);
            return lastReturnedEntry;
        }
		// 删除操作
        public void remove() {
            lastReturnedIndex =
                ((null == lastReturnedEntry) ? -1 : lastReturnedEntry.index);
            super.remove();
            lastReturnedEntry.index = lastReturnedIndex;
            lastReturnedEntry = null;
        }
		// 实现entry结构
        private class Entry implements Map.Entry<K,V> {
            private int index;
			// 记录key和value的索引位置
            private Entry(int index) {
                this.index = index;
            }
			// 获取key是从keyUniverse获取
            public K getKey() {
                checkIndexForEntryUse();
                return keyUniverse[index];
            }
			// 获取value时，从vals中获取
            public V getValue() {
                checkIndexForEntryUse();
                return unmaskNull(vals[index]);
            }
			// 使用新value覆盖旧value
            public V setValue(V value) {
                checkIndexForEntryUse();
                V oldValue = unmaskNull(vals[index]);
                vals[index] = maskNull(value);
                return oldValue;
            }
			// key和value相等才是相等
            public boolean equals(Object o) {
                if (index < 0)
                    return o == this;
                if (!(o instanceof Map.Entry))
                    return false;
                Map.Entry<?,?> e = (Map.Entry<?,?>)o;
                V ourValue = unmaskNull(vals[index]);
                Object hisValue = e.getValue();
                return (e.getKey() == keyUniverse[index] &&
                        (ourValue == hisValue ||
                         (ourValue != null && ourValue.equals(hisValue))));
            }

            public int hashCode() {
                if (index < 0)
                    return super.hashCode();

                return entryHashCode(index);
            }

            public String toString() {
                if (index < 0)
                    return super.toString();

                return keyUniverse[index] + "="
                    + unmaskNull(vals[index]);
            }

            private void checkIndexForEntryUse() {
                if (index < 0)
                    throw new IllegalStateException("Entry was removed");
            }
        }
    }
```

## 如何获取到Enum中实例的数量的呢？

从函数调用关系分析，是其对应的Class对象获取的。这里先知道，后面会细致分析Class对象的使用.

```java
    public EnumMap(Class<K> keyType) {
        this.keyType = keyType;
        keyUniverse = getKeyUniverse(keyType);
        vals = new Object[keyUniverse.length];
    }
    private static <K extends Enum<K>> K[] getKeyUniverse(Class<K> keyType) {
        return SharedSecrets.getJavaLangAccess()
                                        .getEnumConstantsShared(keyType);
    }
	// java.lang.Class
    T[] getEnumConstantsShared() {
        if (enumConstants == null) {
            if (!isEnum()) return null;
            try {
                final Method values = getMethod("values");
                java.security.AccessController.doPrivileged(
                    new java.security.PrivilegedAction<Void>() {
                        public Void run() {
                                values.setAccessible(true);
                                return null;
                            }
                        });
                @SuppressWarnings("unchecked")
                T[] temporaryConstants = (T[])values.invoke(null);
                enumConstants = temporaryConstants;
            }
            // These can happen when users concoct enum-like classes
            // that don't comply with the enum spec.
            catch (InvocationTargetException | NoSuchMethodException |
                   IllegalAccessException ex) { return null; }
        }
        return enumConstants;
    }
```

