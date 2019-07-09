# FileInputStream

## Field

```java
    /* File Descriptor - handle to the open file */
    private final FileDescriptor fd;

    /**
     * The path of the referenced file
     * (null if the stream is created with a file descriptor)
     */
    private final String path;

    private FileChannel channel = null;

    private final Object closeLock = new Object();
    private volatile boolean closed = false;
```

静态初始化方法:

```java
    private static native void initIDs();
    private native void close0() throws IOException;

    static {
        initIDs();
    }
```

## 构造方法

```java
    public FileInputStream(File file) throws FileNotFoundException {
        String name = (file != null ? file.getPath() : null);
        SecurityManager security = System.getSecurityManager();
        // 安全性检查
        if (security != null) {
            security.checkRead(name);
        }
        if (name == null) {
            throw new NullPointerException();
        }
        if (file.isInvalid()) {
            throw new FileNotFoundException("Invalid file path");
        }
        // 创建文件描述符
        fd = new FileDescriptor();
        fd.attach(this);
        path = name;
        // native方法打开文件
        open(name);
    }

    public FileInputStream(FileDescriptor fdObj) {
        SecurityManager security = System.getSecurityManager();
        if (fdObj == null) {
            throw new NullPointerException();
        }
        if (security != null) {
            security.checkRead(fdObj);
        }
        fd = fdObj;
        path = null;
		// 绑定
        fd.attach(this);
    }
```

## 功能方法

### 读取:

```java
    public int read() throws IOException {
        return read0();
    }

    private native int read0() throws IOException;

    private native int readBytes(byte b[], int off, int len) throws IOException;

    public int read(byte b[]) throws IOException {
        return readBytes(b, 0, b.length);
    }
```

都是由本地方法实现.

### skip

```java
    public long skip(long n) throws IOException {
        return skip0(n);
    }

    private native long skip0(long n) throws IOException;
```



### 可用

```java
    public int available() throws IOException {
        return available0();
    }

    private native int available0() throws IOException;
```

大都功能都是C++实现的，目前就先分析到这。