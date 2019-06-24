# CopyOnWriteArraySet

## Field

```java
    private final CopyOnWriteArrayList<E> al;
```



## 构造函数

```java
    public CopyOnWriteArraySet() {
        al = new CopyOnWriteArrayList<E>();
    }

    public CopyOnWriteArraySet(Collection<? extends E> c) {
        if (c.getClass() == CopyOnWriteArraySet.class) {
            @SuppressWarnings("unchecked") CopyOnWriteArraySet<E> cc =
                (CopyOnWriteArraySet<E>)c;
            al = new CopyOnWriteArrayList<E>(cc.al);
        }
        else {
            al = new CopyOnWriteArrayList<E>();
            al.addAllAbsent(c);
        }
    }
```

由此可见，底层就是CopyOnWriteArrayList实现的。 看来也不用分析太多了。

看一眼其添加，遍历，删除函数把

添加：

```java
    public boolean add(E e) {
        return al.addIfAbsent(e);
    }
```

遍历：

```java
    public Iterator<E> iterator() {
        return al.iterator();
    }
```



删除:

```java
    public boolean remove(Object o) {
        return al.remove(o);
    }
```

可以看见了，都是调用CopyOnWriteArrayList的函数了。