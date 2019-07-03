# AtomicReference

## Field

```java
    private volatile V value; // 要操作的值
    private static final Unsafe unsafe = Unsafe.getUnsafe();  // CAS
    private static final long valueOffset;  // 内存偏移值
```

静态初始化代码块:

```java
    static {
        try {
            valueOffset = unsafe.objectFieldOffset
                (AtomicReference.class.getDeclaredField("value"));
        } catch (Exception ex) { throw new Error(ex); }
    }
```



## 构造函数

```java
    public AtomicReference(V initialValue) {
        value = initialValue;
    }

    public AtomicReference() {
    }
```



## 功能函数

### 获取
```java
    public final V get() {
        return value;
    }
```


### 设置
```java
    public final void set(V newValue) {
        value = newValue;
    }
```


### 自旋设置
```java
    public final boolean compareAndSet(V expect, V update) {
        return unsafe.compareAndSwapObject(this, valueOffset, expect, update);
    }

    public final boolean weakCompareAndSet(V expect, V update) {
        return unsafe.compareAndSwapObject(this, valueOffset, expect, update);
    }
```


### 获取并设置

```java
    public final V getAndSet(V newValue) {
        return (V)unsafe.getAndSetObject(this, valueOffset, newValue);
    }
```

