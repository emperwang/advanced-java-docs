# HashSet

## Field

```java
    private transient HashMap<E,Object> map;
	// 存储的对应的value值,都为这个
    private static final Object PRESENT = new Object();
```



## 构造器

```java
    public HashSet() {
        map = new HashMap<>();
    }

    public HashSet(Collection<? extends E> c) {
        map = new HashMap<>(Math.max((int) (c.size()/.75f) + 1, 16));
        addAll(c);
    }

    public HashSet(int initialCapacity, float loadFactor) {
        map = new HashMap<>(initialCapacity, loadFactor);
    }

    public HashSet(int initialCapacity) {
        map = new HashMap<>(initialCapacity);
    }

    HashSet(int initialCapacity, float loadFactor, boolean dummy) {
        map = new LinkedHashMap<>(initialCapacity, loadFactor);
    }
```

从这里看起来其底层是HashMap和LinkedHashMap实现的.



## 添加一个元素

```java
    public boolean add(E e) {
        return map.put(e, PRESENT)==null;
    }
```



## 删除一个元素

```java
    public boolean remove(Object o) {
        return map.remove(o)==PRESENT;
    }
```



## 扩容

那底层是HashMap,扩容当然就是HashMap的扩容了.

## 遍历操作

```java
    public Iterator<E> iterator() {
        return map.keySet().iterator();
    }
```

不用多说了,底层就是HashMap的结构.