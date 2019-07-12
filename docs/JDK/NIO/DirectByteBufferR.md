# DirectByteBufferR

此时DirectByteBuffer的子类，是只读buffer，看一下有什么特殊的把。

## 构造函数

```java
// Primary constructor
DirectByteBufferR(int cap) {                   // package-private
    super(cap);
}

// For memory-mapped buffers -- invoked by FileChannelImpl via reflection
protected DirectByteBufferR(int cap, long addr,
                            FileDescriptor fd,
                            Runnable unmapper){
    super(cap, addr, fd, unmapper);
}



// For duplicates and slices
DirectByteBufferR(DirectBuffer db,         // package-private
                  int mark, int pos, int lim, int cap,
                  int off){
    super(db, mark, pos, lim, cap, off);
}
```



## 功能函数

### slice

```java
public ByteBuffer slice() {
    int pos = this.position();
    int lim = this.limit();
    assert (pos <= lim);
    int rem = (pos <= lim ? lim - pos : 0);
    int off = (pos << 0);
    assert (off >= 0);
    return new DirectByteBufferR(this, -1, 0, rem, rem, off);
}
```

### duplicate

```java
public ByteBuffer duplicate() {
    return new DirectByteBufferR(this,
                                 this.markValue(),
                                 this.position(),
                                 this.limit(),
                                 this.capacity(),
                                 0);
}
```

### put

这里就是最大的区别了，不能向buffer种放入数据.

```java
    public ByteBuffer put(byte x) {
        throw new ReadOnlyBufferException();
    }

    public ByteBuffer put(int i, byte x) {
        throw new ReadOnlyBufferException();
    }

    public ByteBuffer put(ByteBuffer src) {
        throw new ReadOnlyBufferException();
    }

    public ByteBuffer put(byte[] src, int offset, int length) {
        throw new ReadOnlyBufferException();
    }
```

### compact

也不能合并数据

```java
    public ByteBuffer compact() {
        throw new ReadOnlyBufferException();
    }
```

### get/put

仍然是，只有get函数，没有put函数。

```java
    byte _get(int i) {                          // package-private
        return unsafe.getByte(address + i);
    }

    void _put(int i, byte b) {                  // package-private
        throw new ReadOnlyBufferException();
    }
```

### putChar / asCharBuffer

这里也是了，只能转换，不能put操作。

```java
private ByteBuffer putChar(long a, char x) {
    throw new ReadOnlyBufferException();
}

public ByteBuffer putChar(char x) {
    throw new ReadOnlyBufferException();
}

public ByteBuffer putChar(int i, char x) {
    throw new ReadOnlyBufferException();
}

public CharBuffer asCharBuffer() {
    int off = this.position();
    int lim = this.limit();
    assert (off <= lim);
    int rem = (off <= lim ? lim - off : 0);
    int size = rem >> 1;
    if (!unaligned && ((address + off) % (1 << 1) != 0)) {
        return (bigEndian
                ? (CharBuffer)(new ByteBufferAsCharBufferRB(this,
                                                            -1,
                                                            0,
                                                            size,
                                                            size,
                                                            off))
                : (CharBuffer)(new ByteBufferAsCharBufferRL(this,
                                                            -1,
                                                            0,
                                                            size,
                                                            size,
                                                            off)));
    } else {
        return (nativeByteOrder
                ? (CharBuffer)(new DirectCharBufferRU(this,
                                                      -1,
                                                      0,
                                                      size,
                                                      size,
                                                      off))
                : (CharBuffer)(new DirectCharBufferRS(this,
                                                      -1,
                                                      0,
                                                      size,
                                                      size,
                                                      off)));
    }
}
```

其他的put short/int/long/double/float函数，也是这样，只能转换，不能put操作。这才是只读的精髓把，就只有读函数，简单粗暴。哈哈