# ByteBuffer

## Field

```java
final byte[] hb;                  // Non-null only for heap buffers
final int offset;
boolean isReadOnly;                 // Valid only for heap buffers
 // package-private
boolean bigEndian = true;
 // package-private
boolean nativeByteOrder = (Bits.byteOrder() == ByteOrder.BIG_ENDIAN);
```

## 构造器

```java
ByteBuffer(int mark, int pos, int lim, int cap,   // package-private
           byte[] hb, int offset)
{
    super(mark, pos, lim, cap);
    this.hb = hb;
    this.offset = offset;
}

// Creates a new buffer with the given mark, position, limit, and capacity
ByteBuffer(int mark, int pos, int lim, int cap) { // package-private
    this(mark, pos, lim, cap, null, 0);
}
```

## 功能函数

### allocateDirect

```java
public static ByteBuffer allocateDirect(int capacity) {
    return new DirectByteBuffer(capacity);
}
```

### allocate

```java
public static ByteBuffer allocate(int capacity) {
    if (capacity < 0)
        throw new IllegalArgumentException();
    return new HeapByteBuffer(capacity, capacity);
}
```

### wrap

```java
public static ByteBuffer wrap(byte[] array) {
    return wrap(array, 0, array.length);
}

public static ByteBuffer wrap(byte[] array,
                              int offset, int length)
{
    try {
        return new HeapByteBuffer(array, offset, length);
    } catch (IllegalArgumentException x) {
        throw new IndexOutOfBoundsException();
    }
}
```

