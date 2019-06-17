# TreeSet

## Field

```java
    private transient NavigableMap<E,Object> m;

    // value值
    private static final Object PRESENT = new Object();
```



## 构造器

```java
    public TreeSet() {
        this(new TreeMap<E,Object>());
    }
    TreeSet(NavigableMap<E,Object> m) {
        this.m = m;
    }
    public TreeSet(Comparator<? super E> comparator) {
        this(new TreeMap<>(comparator));
    }
    public TreeSet(Collection<? extends E> c) {
        this();
        addAll(c);
    }
    public TreeSet(SortedSet<E> s) {
        this(s.comparator());
        addAll(s);
    }
```

可见此处的TreeSet时依赖于TreeMap实现的，只不过value值都存储的是固定值PRESENT。

是不是很眼熟？HashMap和HashSet，想起来了把。

## 加入元素

```java
    public boolean add(E e) {
        return m.put(e, PRESENT)==null;
    }
```



## 删除元素

```java
    public boolean remove(Object o) {
        return m.remove(o)==PRESENT;
    }
```



## 遍历元素

```java
    public Iterator<E> iterator() {
        return m.navigableKeySet().iterator();
    }
// 使用的是TreeMap的keySet遍历
```

剩下就不用多说了.