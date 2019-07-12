# CharBuffer

## Field

```java
    final char[] hb;                  // Non-null only for heap buffers
    final int offset;
    boolean isReadOnly;    
```



## 构造函数

```java
// Creates a new buffer with the given mark, position, limit, capacity,
// backing array, and array offset
CharBuffer(int mark, int pos, int lim, int cap,   // package-private
           char[] hb, int offset)
{
    super(mark, pos, lim, cap);
    this.hb = hb;
    this.offset = offset;
}

// Creates a new buffer with the given mark, position, limit, and capacity
CharBuffer(int mark, int pos, int lim, int cap) { // package-private
    this(mark, pos, lim, cap, null, 0);
}
```



## 功能函数

### allocate

```java
public static CharBuffer allocate(int capacity) {
    if (capacity < 0)
        throw new IllegalArgumentException();
    return new HeapCharBuffer(capacity, capacity);
}
```



### wrap

```java
// 把一个数组包装为buffer
public static CharBuffer wrap(char[] array,
                              int offset, int length)
{
    try {
        return new HeapCharBuffer(array, offset, length);
    } catch (IllegalArgumentException x) {
        throw new IndexOutOfBoundsException();
    }
}

public static CharBuffer wrap(char[] array) {
    return wrap(array, 0, array.length);
}

public static CharBuffer wrap(CharSequence csq, int start, int end) {
    try {
        return new StringCharBuffer(csq, start, end);
    } catch (IllegalArgumentException x) {
        throw new IndexOutOfBoundsException();
    }
}

public static CharBuffer wrap(CharSequence csq) {
    return wrap(csq, 0, csq.length());
}
```

其他的具体put/get等操作，需要子类是实现。接着看一下子类。