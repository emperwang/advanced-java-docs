# HeapCharBuffer

## 构造函数

```java
HeapCharBuffer(int cap, int lim) {            // package-private
    super(-1, 0, lim, cap, new char[cap], 0);
}

HeapCharBuffer(char[] buf, int off, int len) { // package-private
    super(-1, off, off + len, buf.length, buf, 0);
}

protected HeapCharBuffer(char[] buf,
                         int mark, int pos, int lim, int cap,
                         int off)
{
    super(mark, pos, lim, cap, buf, off);
}
```



## 功能函数

### slice

```java
public CharBuffer slice() {
    return new HeapCharBuffer(hb,
                              -1,
                              0,
                              this.remaining(),
                              this.remaining(),
                              this.position() + offset);
}
```



### duplicate
```java
public CharBuffer duplicate() {
    return new HeapCharBuffer(hb,
                              this.markValue(),
                              this.position(),
                              this.limit(),
                              this.capacity(),
                              offset);
}
```


### asReadOnlyBuffer
```java
public CharBuffer asReadOnlyBuffer() {
    return new HeapCharBufferR(hb,
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

public char get() {
    return hb[ix(nextGetIndex())];
}

public char get(int i) {
    return hb[ix(checkIndex(i))];
}


char getUnchecked(int i) {
    return hb[ix(i)];
}


public CharBuffer get(char[] dst, int offset, int length) {
    checkBounds(offset, length, dst.length);
    if (length > remaining())
        throw new BufferUnderflowException();
    System.arraycopy(hb, ix(position()), dst, offset, length);
    position(position() + length);
    return this;
}
```


### put
```java
public CharBuffer put(int i, char x) {
    hb[ix(checkIndex(i))] = x;
    return this;
}
// 存放数组
public CharBuffer put(char[] src, int offset, int length) {
    checkBounds(offset, length, src.length);
    if (length > remaining())
        throw new BufferOverflowException();
    System.arraycopy(src, offset, hb, ix(position()), length);
    position(position() + length);
    return this;
}

public CharBuffer put(CharBuffer src) {
    if (src instanceof HeapCharBuffer) {
        if (src == this)
            throw new IllegalArgumentException();
        HeapCharBuffer sb = (HeapCharBuffer)src;
        int n = sb.remaining();
        if (n > remaining())
            throw new BufferOverflowException();
        // 拷贝
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
public CharBuffer compact() {
    System.arraycopy(hb, ix(position()), hb, ix(0), remaining());
    position(remaining());
    limit(capacity());
    discardMark();
    return this;
}
```



### order

```java
public ByteOrder order() {
    return ByteOrder.nativeOrder();
}
```

操作起来很简单明了了，至于HeapCharBufferR只读buffer，就是没有put/compact函数啦。 不过多说废话了。