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

public static ByteBuffer wrap(byte[] array,int offset, int length){
    try {
        return new HeapByteBuffer(array, offset, length);
    } catch (IllegalArgumentException x) {
        throw new IndexOutOfBoundsException();
    }
}
```

### 抽象方法

```java
public abstract ByteBuffer duplicate();
public abstract ByteBuffer slice();
public abstract ByteBuffer asReadOnlyBuffer();
public abstract byte get();
public abstract ByteBuffer put(byte b);
public abstract byte get(int index);
public abstract ByteBuffer put(int index, byte b);
public abstract ByteBuffer compact();
public abstract boolean isDirect();
```

### get/put

```java
public ByteBuffer get(byte[] dst, int offset, int length) {
    checkBounds(offset, length, dst.length);
    if (length > remaining())
        throw new BufferUnderflowException();
    int end = offset + length;
    for (int i = offset; i < end; i++)
        dst[i] = get();
    return this;
}

public ByteBuffer put(ByteBuffer src) {
    if (src == this)
        throw new IllegalArgumentException();
    if (isReadOnly())
        throw new ReadOnlyBufferException();
    int n = src.remaining();
    if (n > remaining())
        throw new BufferOverflowException();
    for (int i = 0; i < n; i++)
        put(src.get());
    return this;
}
```

其他也都是抽象方法了，还需要子类去具体实现。那接着看一下子类实现把。