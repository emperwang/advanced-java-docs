# MappedByteBuffer

javaDoc解释:

```java
 A direct byte buffer whose content is a memory-mapped region of a file.
 Mapped byte buffers are created via the java.nio.channels.FileChannel FileChannel.mapmethod.  This class  extends the ByteBuffer class with operations that are specific to  memory-mapped file regions
```

## FIeld

```java
// For mapped buffers, a FileDescriptor that may be used for mapping
// operations if valid; null if the buffer is not mapped.
private final FileDescriptor fd;
// not used, but a potential target for a store, see load() for details.
private static byte unused;
```



## 构造函数

```java
// This should only be invoked by the DirectByteBuffer constructors
MappedByteBuffer(int mark, int pos, int lim, int cap, // package-private
                 FileDescriptor fd)
{
    super(mark, pos, lim, cap);
    this.fd = fd;
}

MappedByteBuffer(int mark, int pos, int lim, int cap) { // package-private
    super(mark, pos, lim, cap);
    this.fd = null;
}
```



## 功能函数

### load

```java
	/** Loads this buffer's content into physical memory.
	 * This method makes a best effort to ensure that, when it returns,
     * this buffer's content is resident in physical memory.  Invoking this
     * method may cause some number of page faults and I/O operations to
     * occur. */
public final MappedByteBuffer load() {
    checkMapped();
    if ((address == 0) || (capacity() == 0))
        return this;
    long offset = mappingOffset();
    long length = mappingLength(offset);
    // load操作
    load0(mappingAddress(offset), length);

    // Read a byte from each page to bring it into memory. A checksum
    // is computed as we go along to prevent the compiler from otherwise
    // considering the loop as dead code.
    Unsafe unsafe = Unsafe.getUnsafe();
    int ps = Bits.pageSize();
    int count = Bits.pageCount(length);
    long a = mappingAddress(offset);
    byte x = 0;
    for (int i=0; i<count; i++) {
        x ^= unsafe.getByte(a);
        a += ps;
    }
    if (unused != 0)
        unused = x;
    return this;
}

private native void load0(long address, long length);
```

### isLoaded

```java
/* Tells whether or not this buffer's content is resident in physical
 * memory.*/
public final boolean isLoaded() {
    checkMapped();
    if ((address == 0) || (capacity() == 0))
        return true;
    long offset = mappingOffset();
    long length = mappingLength(offset);
    return isLoaded0(mappingAddress(offset), length, Bits.pageCount(length));
}

private native boolean isLoaded0(long address, long length, int pageCount);
```



### force

```java
/** Forces any changes made to this buffer's content to be written to the
     * storage device containing the mapped file.
     * <p> If the file mapped into this buffer resides on a local storage
     * device then when this method returns it is guaranteed that all changes
     * made to the buffer since it was created, or since this method was last
     * invoked, will have been written to that device. */
// 刷新buffer中的内容到硬件中
public final MappedByteBuffer force() {
    checkMapped();
    if ((address != 0) && (capacity() != 0)) {
        long offset = mappingOffset();
        // 底层方法刷新
        force0(fd, mappingAddress(offset), mappingLength(offset));
    }
    return this;
}


private void checkMapped() {
    if (fd == null)
        throw new UnsupportedOperationException();
}

// Returns the distance (in bytes) of the buffer from the page aligned address
// of the mapping. Computed each time to avoid storing in every direct buffer.
private long mappingOffset() {
    int ps = Bits.pageSize();
    long offset = address % ps;
    return (offset >= 0) ? offset : (ps + offset);
}

private long mappingAddress(long mappingOffset) {
    return address - mappingOffset;
}

private long mappingLength(long mappingOffset) {
    return (long)capacity() + mappingOffset;
}
private native void force0(FileDescriptor fd, long address, long length);
```

