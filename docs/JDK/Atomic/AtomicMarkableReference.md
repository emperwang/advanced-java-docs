# AtomicMarkableReference

## Field

```java
   private volatile Pair<V> pair;
	//CAS
    private static final sun.misc.Unsafe UNSAFE = sun.misc.Unsafe.getUnsafe();
	// 内存偏移
    private static final long pairOffset =
        objectFieldOffset(UNSAFE, "pair", AtomicMarkableReference.class);
```

```java
    // 获取偏移值
	static long objectFieldOffset(sun.misc.Unsafe UNSAFE,
                                  String field, Class<?> klazz) {
        try {
            return UNSAFE.objectFieldOffset(klazz.getDeclaredField(field));
        } catch (NoSuchFieldException e) {
            // Convert Exception to corresponding Error
            NoSuchFieldError error = new NoSuchFieldError(field);
            error.initCause(e);
            throw error;
        }
    }
```



内部类:

```java
    private static class Pair<T> {
        final T reference;
        final boolean mark;
        // 私有构造器
        private Pair(T reference, boolean mark) {
            this.reference = reference;
            this.mark = mark;
        }
        // 构建函数,工厂方法
        static <T> Pair<T> of(T reference, boolean mark) {
            return new Pair<T>(reference, mark);
        }
    }
```

## 构造函数

```java
    public AtomicMarkableReference(V initialRef, boolean initialMark) {
        pair = Pair.of(initialRef, initialMark);
    }
```



## 功能函数

### 获取引用

```java
    public V getReference() {
        return pair.reference;
    }
```



### 是否标记
```java
    public boolean isMarked() {
        return pair.mark;
    }
```


### 获取
```java
    public V get(boolean[] markHolder) {
        Pair<V> pair = this.pair;
        markHolder[0] = pair.mark;
        return pair.reference;
    }
```


### 自旋操作
```java
    public boolean weakCompareAndSet(V       expectedReference,
                                     V       newReference,
                                     boolean expectedMark,
                                     boolean newMark) {
        return compareAndSet(expectedReference, newReference,
                             expectedMark, newMark);
    }

	// 自旋设置
    public boolean compareAndSet(V       expectedReference,
                                 V       newReference,
                                 boolean expectedMark,
                                 boolean newMark) {
        Pair<V> current = pair;
        return
            expectedReference == current.reference &&
            expectedMark == current.mark &&
            ((newReference == current.reference &&
              newMark == current.mark) ||
             casPair(current, Pair.of(newReference, newMark)));
    }
	// 自旋设置值
  private boolean casPair(Pair<V> cmp, Pair<V> val) {
        return UNSAFE.compareAndSwapObject(this, pairOffset, cmp, val);
    }
```


### 设置值
```java
   public void set(V newReference, boolean newMark) {
        Pair<V> current = pair;
        if (newReference != current.reference || newMark != current.mark)
            // 设置新值
            this.pair = Pair.of(newReference, newMark);
    }
```


### 尝试标记
```java
    public boolean attemptMark(V expectedReference, boolean newMark) {
        Pair<V> current = pair;
        return
            // CAS 设置值
            expectedReference == current.reference &&
            (newMark == current.mark ||
             casPair(current, Pair.of(expectedReference, newMark)));
    }
```
