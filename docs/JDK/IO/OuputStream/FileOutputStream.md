# FileOutpurStream

## Field

```java
    // 对应的文件描述符
	private final FileDescriptor fd;
	// 是否是追加内容到文件尾
    private final boolean append;

    /**
     * The associated channel, initialized lazily.
     */
    private FileChannel channel;
	// 文件路径
    private final String path;
	// 关闭文件时的锁
    private final Object closeLock = new Object();
	// 文件是否关闭
    private volatile boolean closed = false;
```

静态初始化代码：

```java
    private static native void initIDs();

    static {
        initIDs();
    }
```



## 构造函数

```java
    // 基于文件名创建文件
	public FileOutputStream(String name) throws FileNotFoundException {
        this(name != null ? new File(name) : null, false);
    }
	// 基于文件名创建文件,并设置是否是追加
    public FileOutputStream(String name, boolean append)
        throws FileNotFoundException
    {
            this(name != null ? new File(name) : null, append);
    }
    // 基于File创建文件
	public FileOutputStream(File file, boolean append)
        throws FileNotFoundException
    {
    	// 得到文件名
        String name = (file != null ? file.getPath() : null);
        // 安全检查
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkWrite(name);
        }
        if (name == null) {
            throw new NullPointerException();
        }
        if (file.isInvalid()) {
            throw new FileNotFoundException("Invalid file path");
        }
        // 创建文件描述符
        this.fd = new FileDescriptor();
        // 文件描述符和当前的FileOutputStream绑定
        fd.attach(this);
        // 记录是否是追加模式 以及  路径名
        this.append = append;
        this.path = name;

        open(name, append);
    }
    // 基于文件描述符创建文件输出流
    public FileOutputStream(FileDescriptor fdObj) {
    	// 安全检查
        SecurityManager security = System.getSecurityManager();
        if (fdObj == null) {
            throw new NullPointerException();
        }
        if (security != null) {
            security.checkWrite(fdObj);
        }
        // 记录
        this.fd = fdObj;
        this.append = false;
        this.path = null;
		// 绑定
        fd.attach(this);
    }
```



## 功能方法

### open

```java
    private void open(String name, boolean append)
        throws FileNotFoundException {
        open0(name, append);
    }

    private native void open0(String name, boolean append)
        throws FileNotFoundException;
```



### write

```java
    public void write(byte b[]) throws IOException {
        writeBytes(b, 0, b.length, append);
    }

    private native void writeBytes(byte b[], int off, int len, boolean append)
        throws IOException;
```

```java
    public void write(int b) throws IOException {
        write(b, append);
    }

    private native void write(int b, boolean append) throws IOException;

```

可以看到文件的读写，都是底层函数实现。可以在JVM源码中查看。 这里就先不分析底层源码了。