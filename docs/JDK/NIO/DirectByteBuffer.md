# DirectByteBuffer

## Field

```java
// Cached unsafe-access object
protected static final Unsafe unsafe = Bits.unsafe();

// Cached array base offset
private static final long arrayBaseOffset = (long)unsafe.arrayBaseOffset(byte[].class);

// Cached unaligned-access capability
protected static final boolean unaligned = Bits.unaligned();

// An object attached to this buffer. If this buffer is a view of another
// buffer then we use this field to keep a reference to that buffer to
// ensure that its memory isn't freed before we are done with it.
private final Object att;
private final Cleaner cleaner;
```



## 内部类

### Field

```java
private static Unsafe unsafe = Unsafe.getUnsafe();
private long address;
private long size;
private int capacity;
```



### 构造函数

```java
private Deallocator(long address, long size, int capacity) {
    assert (address != 0);
    this.address = address;
    this.size = size;
    this.capacity = capacity;
}
```



### 功能函数

```java
public void run() {
    if (address == 0) {
        return;
    }
    unsafe.freeMemory(address);
    address = 0;
    Bits.unreserveMemory(size, capacity);
}

public native void freeMemory(long var1);
```



## 构造方法

```java
// Primary constructor
DirectByteBuffer(int cap) {                   // package-private
    super(-1, 0, cap, cap);
    boolean pa = VM.isDirectMemoryPageAligned();
    int ps = Bits.pageSize();
    long size = Math.max(1L, (long)cap + (pa ? ps : 0));
    Bits.reserveMemory(size, cap);
    long base = 0;
    try {
        // 分配内存
        base = unsafe.allocateMemory(size);
    } catch (OutOfMemoryError x) {
        Bits.unreserveMemory(size, cap);
        throw x;
    }
    // 设置为0
    unsafe.setMemory(base, size, (byte) 0);
    // 记录内存开始地址
    if (pa && (base % ps != 0)) {
        // Round up to page boundary
        address = base + ps - (base & (ps - 1));
    } else {
        address = base;
    }
    cleaner = Cleaner.create(this, new Deallocator(base, size, cap));
    att = null;
}

public native long allocateMemory(long var1);

public void setMemory(long var1, long var3, byte var5) {
    this.setMemory((Object)null, var1, var3, var5);
}

public native void setMemory(Object var1, long var2, long var4, byte var6);
```

```java
// Invoked to construct a direct ByteBuffer referring to the block of
// memory. A given arbitrary object may also be attached to the buffer.
DirectByteBuffer(long addr, int cap, Object ob) {
    super(-1, 0, cap, cap);
    address = addr;
    cleaner = null;
    att = ob;
}

// Invoked only by JNI: NewDirectByteBuffer(void*, long)
private DirectByteBuffer(long addr, int cap) {
    super(-1, 0, cap, cap);
    address = addr;
    cleaner = null;
    att = null;
}

// For memory-mapped buffers -- invoked by FileChannelImpl via reflection
protected DirectByteBuffer(int cap, long addr,FileDescriptor fd,Runnable unmapper){
    super(-1, 0, cap, cap, fd);
    address = addr;
    cleaner = Cleaner.create(this, unmapper);
    att = null;
}

// For duplicates and slices
DirectByteBuffer(DirectBuffer db,int mark, int pos, int lim, int cap,int off){
    super(mark, pos, lim, cap);
    address = db.address() + off;
    cleaner = null;
    att = db;
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
    // 创建一个只包含数据的buffer
    return new DirectByteBuffer(this, -1, 0, rem, rem, off);
}
```

### duplicate

```java
public ByteBuffer duplicate() {
    return new DirectByteBuffer(this,this.markValue(),                    	  this.position(), this.limit(), this.capacity(),0);
}
```

### asReadyOnlyBuffer

```java
public ByteBuffer asReadOnlyBuffer() {
    return new DirectByteBufferR(this,this.markValue(), this.position(),
                                 this.limit(), this.capacity(), 0);
}
```

### get

```java
private long ix(int i) {
    return address + ((long)i << 0);
}
// 获取指定内存位置的值
public byte get() {
    return ((unsafe.getByte(ix(nextGetIndex()))));
}

public byte get(int i) {
    return ((unsafe.getByte(ix(checkIndex(i)))));
}
```

### put

```java
public ByteBuffer put(byte x) {
    unsafe.putByte(ix(nextPutIndex()), ((x)));
    return this;
}

public ByteBuffer put(int i, byte x) {
    unsafe.putByte(ix(checkIndex(i)), ((x)));
    return this;
}
```

```java
public ByteBuffer put(ByteBuffer src) {
    if (src instanceof DirectByteBuffer) {
        if (src == this)
            throw new IllegalArgumentException();
        DirectByteBuffer sb = (DirectByteBuffer)src;
        // 获取记录的位置信息
        int spos = sb.position();
        int slim = sb.limit();
        assert (spos <= slim);
        // 获取有效数据个数
        int srem = (spos <= slim ? slim - spos : 0);
        // 当前buffer可用的长度
        int pos = position();
        int lim = limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0);
        if (srem > rem)
            throw new BufferOverflowException();
        // 数据拷贝
        unsafe.copyMemory(sb.ix(spos), ix(pos), (long)srem << 0);
        sb.position(spos + srem);
        position(pos + srem);
    } else if (src.hb != null) {
        // 获取数据index位置,并进行拷贝操作
        // 最后更新position位置
        int spos = src.position();
        int slim = src.limit();
        assert (spos <= slim);
        int srem = (spos <= slim ? slim - spos : 0);
        put(src.hb, src.offset + spos, srem);
        src.position(spos + srem);
    } else {
        super.put(src);
    }
    return this;
}
```

```java
public ByteBuffer put(byte[] src, int offset, int length) {
    if (((long)length << 0) > Bits.JNI_COPY_FROM_ARRAY_THRESHOLD) {
        checkBounds(offset, length, src.length);
        int pos = position();
        int lim = limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0);
        if (length > rem)
            throw new BufferOverflowException();
        // 数据拷贝;  看这里就行了
        Bits.copyFromArray(src, arrayBaseOffset,
                           (long)offset << 0,
                           ix(pos),
                           (long)length << 0);
        position(pos + length);
    } else {
        super.put(src, offset, length);
    }
    return this;
}
```

### compact

```java
public ByteBuffer compact() {
    // 把pos至limit之间的有效数据拷贝到buffer的0开始位置
    int pos = position();
    int lim = limit();
    assert (pos <= lim);
    int rem = (pos <= lim ? lim - pos : 0);
    unsafe.copyMemory(ix(pos), ix(0), (long)rem << 0);
    position(rem);
    limit(capacity());
    // 丢弃标记
    discardMark();
    return this;
}
```

### get/put

```java
byte _get(int i) {                          // package-private
    return unsafe.getByte(address + i);
}

void _put(int i, byte b) {                  // package-private
    unsafe.putByte(address + i, b);
}
```

### getChar

```java
private char getChar(long a) {
    if (unaligned) {
        char x = unsafe.getChar(a);
        return (nativeByteOrder ? x : Bits.swap(x));
    }
    return Bits.getChar(a, bigEndian);
}

public char getChar() {
    return getChar(ix(nextGetIndex((1 << 1))));
}

public char getChar(int i) {
    return getChar(ix(checkIndex(i, (1 << 1))));
}
```

### putChar

```java
private ByteBuffer putChar(long a, char x) {
    if (unaligned) {
        char y = (x);
        unsafe.putChar(a, (nativeByteOrder ? y : Bits.swap(y)));
    } else {
        Bits.putChar(a, x, bigEndian);
    }
    return this;
}

public ByteBuffer putChar(char x) {
    putChar(ix(nextPutIndex((1 << 1))), x);
    return this;
}

public ByteBuffer putChar(int i, char x) {
    putChar(ix(checkIndex(i, (1 << 1))), x);
    return this;
}
```

### asCharBuffer

```java
public CharBuffer asCharBuffer() {
    int off = this.position();
    int lim = this.limit();
    assert (off <= lim);
    int rem = (off <= lim ? lim - off : 0);
    int size = rem >> 1;
    if (!unaligned && ((address + off) % (1 << 1) != 0)) {
 return (bigEndian? (CharBuffer)(new ByteBufferAsCharBufferB(this,  -1,
                   0, size,size, off))
                : (CharBuffer)(new ByteBufferAsCharBufferL(this,
                       -1,  0, size, size,  off)));
    } else {
        return (nativeByteOrder
                ? (CharBuffer)(new DirectCharBufferU(this,
                                                     -1,
                                                     0,
                                                     size,
                                                     size,
                                                     off))
                : (CharBuffer)(new DirectCharBufferS(this,
                                                     -1,
                                                     0,
                                                     size,
                                                     size,
                                                     off)));
    }
}
```

其余函数就是put/get  short /long/double 等不同类型的数据，在风格大概一致，这篇就不继续分析下去了，有兴趣的读者，可以自己翻一下哈。