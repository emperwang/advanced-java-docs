# FileChannelmpl

## Field

```java
private static final long allocationGranularity;
private final FileDispatcher nd;
// 文件描述符
private final FileDescriptor fd;
// 读写标志
private final boolean writable;
private final boolean readable;
// 追加
private final boolean append;
// 父目录
private final Object parent;
// 路径
private final String path;
private final NativeThreadSet threads = new NativeThreadSet(2);
private final Object positionLock = new Object();
// 传输标志
private static volatile boolean transferSupported = true;
private static volatile boolean pipeSupported = true;
private static volatile boolean fileSupported = true;
private static final long MAPPED_TRANSFER_SIZE = 8388608L;
private static final int TRANSFER_SIZE = 8192;
private static final int MAP_RO = 0;
private static final int MAP_RW = 1;
private static final int MAP_PV = 2;
private volatile FileLockTable fileLockTable;
private static boolean isSharedFileLockTable;
private static volatile boolean propertyChecked;
```

静态初始化代码:

```java
    private static native long initIDs();

    static {
        IOUtil.load();
        allocationGranularity = initIDs();
    }
```



## 构造函数

```java
private FileChannelImpl(FileDescriptor var1, String var2, boolean var3, boolean var4, boolean var5, Object var6) {
    this.fd = var1;
    this.readable = var3;
    this.writable = var4;
    this.append = var5;
    this.parent = var6;
    this.path = var2;
    this.nd = new FileDispatcherImpl(var5);
}
```

## 功能函数

### open

```java
public static FileChannel open(FileDescriptor var0, String var1, boolean var2, boolean var3, Object var4) {
    return new FileChannelImpl(var0, var1, var2, var3, false, var4);
}

public static FileChannel open(FileDescriptor var0, String var1, boolean var2, boolean var3, boolean var4, Object var5) {
    return new FileChannelImpl(var0, var1, var2, var3, var4, var5);
}
```

### read

```java
public int read(ByteBuffer var1) throws IOException {
    this.ensureOpen();
    if (!this.readable) {
        throw new NonReadableChannelException();
    } else {
        Object var2 = this.positionLock;
        synchronized(this.positionLock) { // 读取获取锁
            int var3 = 0;
            int var4 = -1;
            try {
                // 读取前的一些操作
                this.begin();
                var4 = this.threads.add();
                if (!this.isOpen()) {
                    byte var12 = 0;
                    return var12;
                } else {
                    do {
                        // 读取数据到var1中
                        var3 = IOUtil.read(this.fd, var1, -1L, this.nd);
                    } while(var3 == -3 && this.isOpen());

                    int var5 = IOStatus.normalize(var3);
                    return var5;
                }
            } finally {
                this.threads.remove(var4);
                this.end(var3 > 0);

                assert IOStatus.check(var3);

            }
        }
    }
}

public long read(ByteBuffer[] var1, int var2, int var3) throws IOException {
    if (var2 >= 0 && var3 >= 0 && var2 <= var1.length - var3) {
        this.ensureOpen();
        if (!this.readable) {
            throw new NonReadableChannelException();
        } else {
            Object var4 = this.positionLock;
            synchronized(this.positionLock) {
                long var5 = 0L;
                int var7 = -1;
                long var8;
                try {
                    this.begin();
                    var7 = this.threads.add();
                    if (this.isOpen()) {
                        do {// 读取数据到var1中
                            var5 = IOUtil.read(this.fd, var1, var2, var3, this.nd);
                        } while(var5 == -3L && this.isOpen());

                        var8 = IOStatus.normalize(var5);
                        return var8;
                    }
                    var8 = 0L;
                } finally {
                    this.threads.remove(var7);
                    this.end(var5 > 0L);
                    assert IOStatus.check(var5);
                }
                return var8;
            }
        }
    } else {
        throw new IndexOutOfBoundsException();
    }
}
```

### write

```java
public int write(ByteBuffer var1) throws IOException {
    this.ensureOpen();
    if (!this.writable) {
        throw new NonWritableChannelException();
    } else {
        Object var2 = this.positionLock;
        synchronized(this.positionLock) {
            int var3 = 0;
            int var4 = -1;
            byte var5;
            try {
                this.begin();
                var4 = this.threads.add();
                if (this.isOpen()) {
                    do {
                        // 写入数据
                        var3 = IOUtil.write(this.fd, var1, -1L, this.nd);
                    } while(var3 == -3 && this.isOpen());
                    int var12 = IOStatus.normalize(var3);
                    return var12;
                }
                var5 = 0;
            } finally {
                this.threads.remove(var4);
                this.end(var3 > 0);
                assert IOStatus.check(var3);
            }
            return var5;
        }
    }
}

public long write(ByteBuffer[] var1, int var2, int var3) throws IOException {
    if (var2 >= 0 && var3 >= 0 && var2 <= var1.length - var3) {
        this.ensureOpen();
        if (!this.writable) {
            throw new NonWritableChannelException();
        } else {
            Object var4 = this.positionLock;
            synchronized(this.positionLock) {
                long var5 = 0L;
                int var7 = -1;
                long var8;
                try {
                    this.begin();
                    var7 = this.threads.add();
                    if (this.isOpen()) {
                        do {
                            // 写入
                            var5 = IOUtil.write(this.fd, var1, var2, var3, this.nd);
                        } while(var5 == -3L && this.isOpen());
                        var8 = IOStatus.normalize(var5);
                        return var8;
                    }
                    var8 = 0L;
                } finally {
                    this.threads.remove(var7);
                    this.end(var5 > 0L);
                    assert IOStatus.check(var5);
                }
                return var8;
            }
        }
    } else {
        throw new IndexOutOfBoundsException();
    }
}
```

### get/setPosition

```java
public long position() throws IOException {
    this.ensureOpen();
    Object var1 = this.positionLock;
    synchronized(this.positionLock) {
        long var2 = -1L;
        int var4 = -1;
        try {
            this.begin();
            var4 = this.threads.add();
            long var5;
            if (!this.isOpen()) {
                var5 = 0L;
                return var5;
            } else {
                do {
                    // 本地方法获取position位置
                    var2 = this.append ? this.nd.size(this.fd) : this.position0(this.fd, -1L);
                } while(var2 == -3L && this.isOpen());
                var5 = IOStatus.normalize(var2);
                return var5;
            }
        } finally {
            this.threads.remove(var4);
            this.end(var2 > -1L);
            assert IOStatus.check(var2);
        }
    }
}

public FileChannel position(long var1) throws IOException {
    this.ensureOpen();
    if (var1 < 0L) {
        throw new IllegalArgumentException();
    } else {
        Object var3 = this.positionLock;
        synchronized(this.positionLock) {
            long var4 = -1L;
            int var6 = -1;
            FileChannelImpl var7;
            try {
                this.begin();
                var6 = this.threads.add();
                if (this.isOpen()) {
                    do {
                        // 本地方法
                        var4 = this.position0(this.fd, var1);
                    } while(var4 == -3L && this.isOpen());
                    var7 = this;
                    return var7;
                }
                var7 = null;
            } finally {
                this.threads.remove(var6);
                this.end(var4 > -1L);
                assert IOStatus.check(var4);
            }
            return var7;
        }
    }
}

private native long position0(FileDescriptor var1, long var2);
```

### size

```java
public long size() throws IOException {
    this.ensureOpen();
    Object var1 = this.positionLock;
    synchronized(this.positionLock) {
        long var2 = -1L;
        int var4 = -1;
        try {
            this.begin();
            var4 = this.threads.add();
            long var5;
            if (!this.isOpen()) {
                var5 = -1L;
                return var5;
            } else {
                do {
				// 获取大小,通过本地方法
                    var2 = this.nd.size(this.fd);
                } while(var2 == -3L && this.isOpen());
                var5 = IOStatus.normalize(var2);
                return var5;
            }
        } finally {
            this.threads.remove(var4);
            this.end(var2 > -1L);
            assert IOStatus.check(var2);
        }
    }
}

long size(FileDescriptor var1) throws IOException {
    return size0(var1);
}

static native long size0(FileDescriptor var0) throws IOException;
```

### transfer

把当前文件描述符中的内容拷贝到另一个文件中:

```java
private long transferToDirectly(long var1, int var3, WritableByteChannel var4) throws IOException {
    if (!transferSupported) {
        return -4L;
    } else {
        FileDescriptor var5 = null;
        if (var4 instanceof FileChannelImpl) {
            if (!fileSupported) {
                return -6L;
            }// 获取要目标描述符
            var5 = ((FileChannelImpl)var4).fd;
        } else if (var4 instanceof SelChImpl) {
            if (var4 instanceof SinkChannelImpl && !pipeSupported) {
                return -6L;
            }
            SelectableChannel var6 = (SelectableChannel)var4;
            if (!this.nd.canTransferToDirectly(var6)) {
                return -6L;
            }
            var5 = ((SelChImpl)var4).getFD();
        }

        if (var5 == null) {
            return -4L;
        } else {
            int var19 = IOUtil.fdVal(this.fd);
            int var7 = IOUtil.fdVal(var5);
            if (var19 == var7) {
                return -4L;
            } else if (this.nd.transferToDirectlyNeedsPositionLock()) {
                Object var8 = this.positionLock;
                synchronized(this.positionLock) {
                    long var9 = this.position();

                    long var11;
                    try {
                        / 进行转移操作
                        var11 = this.transferToDirectlyInternal(var1, var3, var4, var5);
                    } finally {
                        this.position(var9);
                    }
                    return var11;
                }
            } else {
                return this.transferToDirectlyInternal(var1, var3, var4, var5);
            }
        }
    }
}

// 具体的转移操作
private long transferToDirectlyInternal(long var1, int var3, WritableByteChannel var4, FileDescriptor var5) throws IOException {
    assert !this.nd.transferToDirectlyNeedsPositionLock() || Thread.holdsLock(this.positionLock);
    long var6 = -1L;
    int var8 = -1;
    long var9;
    try {
        this.begin();
        var8 = this.threads.add();
        if (!this.isOpen()) {
            var9 = -1L;
            return var9;
        }
        do {
            // 底层函数进行转义
            var6 = this.transferTo0(this.fd, var1, (long)var3, var5);
        } while(var6 == -3L && this.isOpen());
        if (var6 == -6L) {
            if (var4 instanceof SinkChannelImpl) {
                pipeSupported = false;
            }

            if (var4 instanceof FileChannelImpl) {
                fileSupported = false;
            }
            var9 = -6L;
            return var9;
        }
        if (var6 != -4L) {
            var9 = IOStatus.normalize(var6);
            return var9;
        }
        transferSupported = false;
        var9 = -4L;
    } finally {
        this.threads.remove(var8);
        this.end(var6 > -1L);
    }
    return var9;
}

private native long transferTo0(FileDescriptor var1, long var2, long var4, FileDescriptor var6);
```

### read

```java
public int read(ByteBuffer var1, long var2) throws IOException {
    if (var1 == null) {
        throw new NullPointerException();
    } else if (var2 < 0L) {
        throw new IllegalArgumentException("Negative position");
    } else if (!this.readable) {
        throw new NonReadableChannelException();
    } else {
        this.ensureOpen();
        if (this.nd.needsPositionLock()) {
            Object var4 = this.positionLock;
            synchronized(this.positionLock) {
                // 读取操作
                return this.readInternal(var1, var2);
            }
        } else {
            return this.readInternal(var1, var2);
        }
    }
}

private int readInternal(ByteBuffer var1, long var2) throws IOException {
    assert !this.nd.needsPositionLock() || Thread.holdsLock(this.positionLock);
    int var4 = 0;
    int var5 = -1;
    try {
        this.begin();
        var5 = this.threads.add();
        if (!this.isOpen()) {
            byte var10 = -1;
            return var10;
        } else {
            do {
                // 这里调用底层方法  进行读取操作
                var4 = IOUtil.read(this.fd, var1, var2, this.nd);
            } while(var4 == -3 && this.isOpen());

            int var6 = IOStatus.normalize(var4);
            return var6;
        }
    } finally {
        this.threads.remove(var5);
        this.end(var4 > 0);
        assert IOStatus.check(var4);
    }
}
```



### write

```java
public int write(ByteBuffer var1, long var2) throws IOException {
    if (var1 == null) {
        throw new NullPointerException();
    } else if (var2 < 0L) {
        throw new IllegalArgumentException("Negative position");
    } else if (!this.writable) {
        throw new NonWritableChannelException();
    } else {
        this.ensureOpen();
        if (this.nd.needsPositionLock()) {
            Object var4 = this.positionLock;
            synchronized(this.positionLock) {
                // 读取操作
                return this.writeInternal(var1, var2);
            }
        } else {
            return this.writeInternal(var1, var2);
        }
    }
}

private int writeInternal(ByteBuffer var1, long var2) throws IOException {
    assert !this.nd.needsPositionLock() || Thread.holdsLock(this.positionLock);

    int var4 = 0;
    int var5 = -1;

    try {
        this.begin();
        var5 = this.threads.add();
        if (!this.isOpen()) {
            byte var10 = -1;
            return var10;
        } else {
            do {
                // 底层方法读取
                var4 = IOUtil.write(this.fd, var1, var2, this.nd);
            } while(var4 == -3 && this.isOpen());
            int var6 = IOStatus.normalize(var4);
            return var6;
        }
    } finally {
        this.threads.remove(var5);
        this.end(var4 > 0);

        assert IOStatus.check(var4);

    }
}
```

### map

```java
public MappedByteBuffer map(MapMode var1, long var2, long var4) throws IOException {
    this.ensureOpen();
    if (var1 == null) {
        throw new NullPointerException("Mode is null");
    } else if (var2 < 0L) {
        throw new IllegalArgumentException("Negative position");
    } else if (var4 < 0L) {
        throw new IllegalArgumentException("Negative size");
    } else if (var2 + var4 < 0L) {
        throw new IllegalArgumentException("Position + size overflow");
    } else if (var4 > 2147483647L) {
        throw new IllegalArgumentException("Size exceeds Integer.MAX_VALUE");
    } else {
        byte var6 = -1;
        if (var1 == MapMode.READ_ONLY) {
            var6 = 0;
        } else if (var1 == MapMode.READ_WRITE) {
            var6 = 1;
        } else if (var1 == MapMode.PRIVATE) {
            var6 = 2;
        }
        assert var6 >= 0;
        if (var1 != MapMode.READ_ONLY && !this.writable) {
            throw new NonWritableChannelException();
        } else if (!this.readable) {
            throw new NonReadableChannelException();
        } else {
            long var7 = -1L;
            int var9 = -1;
            try {
                this.begin();
                var9 = this.threads.add();
                if (!this.isOpen()) {
                    Object var32 = null;
                    return (MappedByteBuffer)var32;
                } else {
                    long var10;
                    do {
                        var10 = this.nd.size(this.fd);
                    } while(var10 == -3L && this.isOpen());
                    FileDescriptor var33;
                    if (!this.isOpen()) {
                        var33 = null;
                        return var33;
                    } else {
                        MappedByteBuffer var34;
                        int var12;
                        if (var10 < var2 + var4) {
                            if (!this.writable) {
	throw new IOException("Channel not open for writing - cannot extend file to required size");
                            }
                            do {
                                var12 = this.nd.truncate(this.fd, var2 + var4);
                            } while(var12 == -3 && this.isOpen());
                            if (!this.isOpen()) {
                                var34 = null;
                                return var34;
                            }
                        }
                        if (var4 == 0L) {
                            var7 = 0L;
                            var33 = new FileDescriptor();
                            if (this.writable && var6 != 0) {
                                var34 = Util.newMappedByteBuffer(0, 0L, var33, (Runnable)null);
                                return var34;
                            } else {
                                var34 = Util.newMappedByteBufferR(0, 0L, var33, (Runnable)null);
                                return var34;
                            }
                        } else {
                            var12 = (int)(var2 % allocationGranularity);
                            long var13 = var2 - (long)var12;
                            long var15 = var4 + (long)var12;
                            try {
                                // 底层函数进行映射
                                var7 = this.map0(var6, var13, var15);
                            } catch (OutOfMemoryError var30) {
                                System.gc();
                                try {
                                    Thread.sleep(100L);
                                } catch (InterruptedException var29) {
                                    Thread.currentThread().interrupt();
                                }

                                try {
                                    var7 = this.map0(var6, var13, var15);
                                } catch (OutOfMemoryError var28) {
                                    throw new IOException("Map failed", var28);
                                }
                            }
                            FileDescriptor var17;
                            try {
                                var17 = this.nd.duplicateForMapping(this.fd);
                            } catch (IOException var27) {
                                unmap0(var7, var15); // 取消映射
                                throw var27;
                            }
                            assert IOStatus.checkAll(var7);
                            assert var7 % allocationGranularity == 0L;
                            int var18 = (int)var4;
                            FileChannelImpl.Unmapper var19 = new FileChannelImpl.Unmapper(var7, var15, var18, var17, null);
                            MappedByteBuffer var20;
                            if (this.writable && var6 != 0) {
                          ar20 = Util.newMappedByteBuffer(var18, var7 + (long)var12, var17, var19);
                                return var20;
                            } else {
                         var20 = Util.newMappedByteBufferR(var18, var7 + (long)var12, var17, var19);
                                return var20;
                            }
                        }
                    }
                }
            } finally {
                this.threads.remove(var9);
                this.end(IOStatus.checkAll(var7));
            }
        }
    }
}
```



## 内部类

### SimpleFileLockTable

Field

```java
private final List<FileLock> lockList = new ArrayList(2);
```

构造函数

```java
public SimpleFileLockTable() {
        }
```

功能函数: 

```java
// 一个检查操作
// 检查有没有重叠
private void checkList(long var1, long var3) throws OverlappingFileLockException {
    assert Thread.holdsLock(this.lockList);
    Iterator var5 = this.lockList.iterator();
    FileLock var6;
    do {
        if (!var5.hasNext()) {
            return;
        }
        var6 = (FileLock)var5.next();
    } while(!var6.overlaps(var1, var3));
    throw new OverlappingFileLockException();
}

// 这几个方法就没有什么特殊了,就是容器的增删改
public void add(FileLock var1) throws OverlappingFileLockException {
    List var2 = this.lockList;
    synchronized(this.lockList) {
        this.checkList(var1.position(), var1.size());
        this.lockList.add(var1);
    }
}

public void remove(FileLock var1) {
    List var2 = this.lockList;
    synchronized(this.lockList) {
        this.lockList.remove(var1);
    }
}

public List<FileLock> removeAll() {
    List var1 = this.lockList;
    synchronized(this.lockList) {
        ArrayList var2 = new ArrayList(this.lockList);
        this.lockList.clear();
        return var2;
    }
}

public void replace(FileLock var1, FileLock var2) {
    List var3 = this.lockList;
    synchronized(this.lockList) {
        this.lockList.remove(var1);
        this.lockList.add(var2);
    }
}
```

### Unmapper

Field

```java
private static final NativeDispatcher nd = new FileDispatcherImpl();
static volatile int count;
static volatile long totalSize;
static volatile long totalCapacity;
private volatile long address;
private final long size;
private final int cap;
private final FileDescriptor fd;
```

构造函数

```java
private Unmapper(long var1, long var3, int var5, FileDescriptor var6) {
    assert var1 != 0L;
    this.address = var1;
    this.size = var3;
    this.cap = var5;
    this.fd = var6;
    Class var7 = FileChannelImpl.Unmapper.class;
    synchronized(FileChannelImpl.Unmapper.class) {
        ++count;
        totalSize += var3;
        totalCapacity += (long)var5;
    }
}
```

```java
public void run() {
    if (this.address != 0L) {
        FileChannelImpl.unmap0(this.address, this.size);
        this.address = 0L;
        if (this.fd.valid()) {
            try {
                nd.close(this.fd);
            } catch (IOException var4) {
                ;
            }
        }
        Class var1 = FileChannelImpl.Unmapper.class;
        synchronized(FileChannelImpl.Unmapper.class) {
            --count;
            totalSize -= this.size;
            totalCapacity -= (long)this.cap;
        }
    }
}
```



