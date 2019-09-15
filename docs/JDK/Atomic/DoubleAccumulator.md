# DoubleAccumulator

## Field

```java
    private final DoubleBinaryOperator function; // 函数式接口
    private final long identity; // use long representation
```

## 构造函数

```java
    public DoubleAccumulator(DoubleBinaryOperator accumulatorFunction,
                             double identity) {
        this.function = accumulatorFunction;
        base = this.identity = Double.doubleToRawLongBits(identity);
    }
```

## 内部类

```java
    // 序列化时使用
	private static class SerializationProxy implements Serializable {
		// 返回值
        private final double value;
        // 用户更新值的函数
        private final DoubleBinaryOperator function;
        // 
        private final long identity;

        SerializationProxy(DoubleAccumulator a) {
            function = a.function;
            identity = a.identity;
            value = a.get();
        }

        /**
         * Returns a {@code DoubleAccumulator} object with initial state
         * held by this proxy.
         *
         * @return a {@code DoubleAccumulator} object with initial state
         * held by this proxy.
         */
        private Object readResolve() {
            double d = Double.longBitsToDouble(identity);
            DoubleAccumulator a = new DoubleAccumulator(function, d);
            a.base = Double.doubleToRawLongBits(value);
            return a;
        }
    }
```



## 功能函数

### 更新值

```java
    // 更新值
	public void accumulate(double x) {
        Cell[] as; long b, v, r; int m; Cell a;
        if ((as = cells) != null ||
            (r = Double.doubleToRawLongBits
             (function.applyAsDouble
              (Double.longBitsToDouble(b = base), x))) != b  && !casBase(b, r)) {
            boolean uncontended = true;
            if (as == null || (m = as.length - 1) < 0 ||
                (a = as[getProbe() & m]) == null ||
                !(uncontended =
                  (r = Double.doubleToRawLongBits
                   (function.applyAsDouble
                    (Double.longBitsToDouble(v = a.value), x))) == v ||
                  a.cas(v, r)))
                doubleAccumulate(x, function, uncontended);
        }
    }
```

### 获取值

```java
    public double get() {
        Cell[] as = cells; Cell a;
        double result = Double.longBitsToDouble(base);
        if (as != null) {
            for (int i = 0; i < as.length; ++i) {
                if ((a = as[i]) != null)
                    result = function.applyAsDouble
                        (result, Double.longBitsToDouble(a.value));
            }
        }
        return result;
    }
```



### reset

```java
    public void reset() {
        Cell[] as = cells; Cell a;
        base = identity;
        if (as != null) {
            for (int i = 0; i < as.length; ++i) {
                if ((a = as[i]) != null)
                    a.value = identity;
            }
        }
    }
```

### getThenReset

```java
    public double getThenReset() {
        Cell[] as = cells; Cell a;
        double result = Double.longBitsToDouble(base);
        base = identity;
        if (as != null) {
            for (int i = 0; i < as.length; ++i) {
                if ((a = as[i]) != null) {
                    double v = Double.longBitsToDouble(a.value);
                    a.value = identity;
                    result = function.applyAsDouble(result, v);
                }
            }
        }
        return result;
    }
```

### 获取值

```java
    public double doubleValue() {
        return get();
    }


    public long longValue() {
        return (long)get();
    }
```

