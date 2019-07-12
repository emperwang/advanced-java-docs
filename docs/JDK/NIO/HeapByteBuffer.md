# HeapByteBuffer

## 构造方法

```java
HeapByteBuffer(int cap, int lim) {            // package-private
    super(-1, 0, lim, cap, new byte[cap], 0);
}

HeapByteBuffer(byte[] buf, int off, int len) { // package-private
    super(-1, off, off + len, buf.length, buf, 0);
}

protected HeapByteBuffer(byte[] buf,
                         int mark, int pos, int lim, int cap, int off){
    super(mark, pos, lim, cap, buf, off);
}
```



## 功能函数

### slice

```java
public ByteBuffer slice() {
    return new HeapByteBuffer(hb,
        -1,0, this.remaining(), this.remaining(), this.position() + offset);
}
```



### duplicate

```java
public ByteBuffer duplicate() {
    return new HeapByteBuffer(hb,
                              this.markValue(),
                              this.position(),
                              this.limit(),
                              this.capacity(),
                              offset);
}
```



### asReadyOnlyBuffer

```java
public ByteBuffer asReadOnlyBuffer() {
    return new HeapByteBufferR(hb,
                               this.markValue(),
                               this.position(),
                               this.limit(),
                               this.capacity(),
                               offset);
}
```



### get

```java
protected int ix(int i) {
    return i + offset;
}

public byte get() {
    return hb[ix(nextGetIndex())];
}

public byte get(int i) {
    return hb[ix(checkIndex(i))];
}

public ByteBuffer get(byte[] dst, int offset, int length) {
    checkBounds(offset, length, dst.length);
    if (length > remaining())
        throw new BufferUnderflowException();
    // 复制数据到dst种
    System.arraycopy(hb, ix(position()), dst, offset, length);
    position(position() + length);
    return this;
}
```

### put

```java
public boolean isReadOnly() {
    return false;
}

// 直接放到数组种
public ByteBuffer put(byte x) {
    hb[ix(nextPutIndex())] = x;
    return this;
}
// 直接放数组种
public ByteBuffer put(int i, byte x) {
    hb[ix(checkIndex(i))] = x;
    return this;
}

public ByteBuffer put(byte[] src, int offset, int length) {
    checkBounds(offset, length, src.length);
    if (length > remaining())
        throw new BufferOverflowException();
    // 把src数据拷贝到数组种
    System.arraycopy(src, offset, hb, ix(position()), length);
    position(position() + length);
    return this;
}

public ByteBuffer put(ByteBuffer src) {
    if (src instanceof HeapByteBuffer) {
        if (src == this)
            throw new IllegalArgumentException();
        HeapByteBuffer sb = (HeapByteBuffer)src;
        int n = sb.remaining();
        if (n > remaining())
            throw new BufferOverflowException();
        // 拷贝操作
        System.arraycopy(sb.hb, sb.ix(sb.position()),
                         hb, ix(position()), n);
        sb.position(sb.position() + n);
        position(position() + n);
    } else if (src.isDirect()) {
        int n = src.remaining();
        if (n > remaining())
            throw new BufferOverflowException();
        // put操作
        src.get(hb, ix(position()), n);
        position(position() + n);
    } else {
        super.put(src);
    }
    return this;
}
```

### compact

```java
    public ByteBuffer compact() {
        System.arraycopy(hb, ix(position()), hb, ix(0), remaining());
        position(remaining());
        limit(capacity());
        discardMark();
        return this;
    }
```

### put/get

```java
byte _get(int i) {                          // package-private
    return hb[i];
}

void _put(int i, byte b) {                  // package-private
    hb[i] = b;
}
```

接下来就是put/get char/short/int/long/doble/float等操作了。可以看出来，heap就是对数组的操作，DirectBuffer是对内存块的操作。而HeapByteBufferR只读buffer，也就没有put函数。就是这么的简单粗暴