# AtomicInteger

## Field

```java
	// CAS 操作    
    private static final Unsafe unsafe = Unsafe.getUnsafe();
	// value的内存偏移值
    private static final long valueOffset;
	// 存储值
    private volatile int value;
```

静态初始化代码:

```java
    static {
        try {
            valueOffset = unsafe.objectFieldOffset
                (AtomicInteger.class.getDeclaredField("value"));
        } catch (Exception ex) { throw new Error(ex); }
    }
```

## 构造函数

```java
    public AtomicInteger() {
    }

    public AtomicInteger(int initialValue) {
        value = initialValue;
    }
```



## 功能函数

### 获取值

```java
    public final int get() {
        return value;
    }
```

### 设置值

```java
    public final void set(int newValue) {
        value = newValue;
    }
```


### 懒设置值

```java
    public final void lazySet(int newValue) {
        unsafe.putOrderedInt(this, valueOffset, newValue);
    }
```


### 获取并设置值

```java
    public final int getAndSet(int newValue) {
        // 先获取值,再设置新值
        return unsafe.getAndSetInt(this, valueOffset, newValue);
    }

    public final int getAndSetInt(Object var1, long var2, int var4) {
        int var5;
        do {
            // 获取值
            var5 = this.getIntVolatile(var1, var2);
            // 设置为新值
        } while(!this.compareAndSwapInt(var1, var2, var5, var4));

        return var5;
    }
```


### 比较并设置值

```java
    public final boolean compareAndSet(int expect, int update) {
        // 自旋设置值
        return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
    }
```


### 获取并自增

```java
    public final int getAndIncrement() {
        return unsafe.getAndAddInt(this, valueOffset, 1);
    }

   public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            // 获取值
            var5 = this.getIntVolatile(var1, var2);
            // 更新为新的值,也就是var5+1
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```


### 获取并自减

```java
    public final int getAndDecrement() {
        return unsafe.getAndAddInt(this, valueOffset, -1);
    }

    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            // 获取值
            var5 = this.getIntVolatile(var1, var2);
            // 更新值,也就是原来的值-1
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```


### 先增加在获取
```java
    public final int incrementAndGet() {
        // 相当于增加2
        return unsafe.getAndAddInt(this, valueOffset, 1) + 1;
    }

    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            var5 = this.getIntVolatile(var1, var2);
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```

### 先减少再获取

```java
    public final int decrementAndGet() {
        // 减少2
        return unsafe.getAndAddInt(this, valueOffset, -1) - 1;
    }

    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            var5 = this.getIntVolatile(var1, var2);
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```


### 获取并更新

```java
    public final int getAndUpdate(IntUnaryOperator updateFunction) {
        int prev, next;
        do {
            // 获取值
            prev = get();
            // 使用函数式编程,对值操作
            next = updateFunction.applyAsInt(prev);
            // 设置值
        } while (!compareAndSet(prev, next));
        return prev;
    }
```


### 转换为int值

```java
    public int intValue() {
        return get();
    }
```


### 转换为string值
```java
    public String toString() {
        return Integer.toString(get());
    }

```