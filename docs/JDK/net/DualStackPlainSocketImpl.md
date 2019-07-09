# DualStackPlainSocketImpl

先看下javaDoc的介绍:

```java
This class defines the plain SocketImpl that is used on Windows platforms greater or equal to Windows Vista. These platforms have a dual layer TCP/IP stack and can handle both IPv4 and IPV6 through a  single file descriptor.
```

## Field

```java
static JavaIOFileDescriptorAccess fdAccess = SharedSecrets.getJavaIOFileDescriptorAccess();

// true if this socket is exclusively bound
// true表示此套接字是唯一绑定的
private final boolean exclusiveBind;

// emulates SO_REUSEADDR when exclusiveBind is true
private boolean isReuseAddress;
static final int WOULDBLOCK = -2;  
```

静态初始化函数:

```java
    static {
        initIDs();
    }

    static native void initIDs();
```



## 构造函数

```java
   public DualStackPlainSocketImpl(boolean exclBind) {
        exclusiveBind = exclBind;
    }

    public DualStackPlainSocketImpl(FileDescriptor fd, boolean exclBind) {
        this.fd = fd;
        exclusiveBind = exclBind;
    }
```



## 功能方法

### socketCreate

```java
    void socketCreate(boolean stream) throws IOException {
        if (fd == null)
            throw new SocketException("Socket closed");
		// 创建套接字 文件描述符
        // 创建操作，依赖于C++实现
        int newfd = socket0(stream, false /*v6 Only*/);
		// 操作此文件描述符
        fdAccess.set(fd, newfd);
    }
```

### socketConnect

```java
    void socketConnect(InetAddress address, int port, int timeout)
        throws IOException {
        // 检查文件描述符，并返回
        int nativefd = checkAndReturnNativeFD();
        if (address == null)
            throw new NullPointerException("inet address argument is null.");

        int connectResult;
        if (timeout <= 0) {
            // 依赖底层函数，去进行连接操作
            connectResult = connect0(nativefd, address, port);
        } else {
            // 配置阻塞与否
            configureBlocking(nativefd, false);
            try {
                // 连接操作
                connectResult = connect0(nativefd, address, port);
                if (connectResult == WOULDBLOCK) {
                    // 等待连接
                    waitForConnect(nativefd, timeout);
                }
            } finally {
                configureBlocking(nativefd, true);
            }
        }
		// 获取本地port端口
        if (localport == 0)
            localport = localPort0(nativefd);
    }

	// 检查并返回文件描述符
    private int checkAndReturnNativeFD() throws SocketException {
        if (fd == null || !fd.valid())
            throw new SocketException("Socket closed");

        return fdAccess.get(fd);
    }
```



### socketBind

```java
    void socketBind(InetAddress address, int port) throws IOException {
        int nativefd = checkAndReturnNativeFD();
        if (address == null)
            throw new NullPointerException("inet address argument is null.");
		// 底层方法进行绑定
        bind0(nativefd, address, port, exclusiveBind);
        if (port == 0) {
            // 获取本地端口号
            localport = localPort0(nativefd);
        } else {
            localport = port;
        }
        this.address = address;
    }
```



### socketListen
```java
    void socketListen(int backlog) throws IOException {
        int nativefd = checkAndReturnNativeFD();
		// 底层方法，监听
        listen0(nativefd, backlog);
    }
```


### socketAccept
```java
    void socketAccept(SocketImpl s) throws IOException {
        int nativefd = checkAndReturnNativeFD();
        if (s == null)
            throw new NullPointerException("socket is null");
		
        int newfd = -1;
        InetSocketAddress[] isaa = new InetSocketAddress[1];
        if (timeout <= 0) {
            newfd = accept0(nativefd, isaa);
        } else {
            configureBlocking(nativefd, false);
            try {
                // 等待连接
                waitForNewConnection(nativefd, timeout);
                // 连接
                newfd = accept0(nativefd, isaa);
                if (newfd != -1) {
                    configureBlocking(newfd, true);
                }
            } finally {
                configureBlocking(nativefd, true);
            }
        }
        /* Update (SocketImpl)s' fd */
        fdAccess.set(s.fd, newfd);
        /* Update socketImpls remote port, address and localport */
        InetSocketAddress isa = isaa[0];
        s.port = isa.getPort();
        s.address = isa.getAddress();
        s.localport = localport;
    }

```


### socketAvailable
```java
    int socketAvailable() throws IOException {
        int nativefd = checkAndReturnNativeFD();
        return available0(nativefd);
    }
```


### socketClose0
```java
    void socketClose0(boolean useDeferredClose/*unused*/) throws IOException {
        if (fd == null)
            throw new SocketException("Socket closed");

        if (!fd.valid())
            return;

        final int nativefd = fdAccess.get(fd);
        fdAccess.set(fd, -1);
        // 关闭；同样依赖底层实现
        close0(nativefd);
    }
```
### socketShutdown
```java
    void socketShutdown(int howto) throws IOException {
        int nativefd = checkAndReturnNativeFD();
        // 关闭操作
        shutdown0(nativefd, howto);
    }
```


### socketSendUrgentData
```java
    void socketSendUrgentData(int data) throws IOException {
        int nativefd = checkAndReturnNativeFD();
        sendOOB(nativefd, data);
    }
```

### native method

由下面函数可知，具体的网络操作还是要依赖于JVM原有函数的实现。现阶段咱们先分析Java层面的的实现，JVM的代码，可以慢慢去了解，前提还要会一点C++。

```java
    static native int socket0(boolean stream, boolean v6Only) throws IOException;

    static native void bind0(int fd, InetAddress localAddress, int localport,
                             boolean exclBind) throws IOException;

    static native int connect0(int fd, InetAddress remote, int remotePort)
        throws IOException;

    static native void waitForConnect(int fd, int timeout) throws IOException;

    static native int localPort0(int fd) throws IOException;

    static native void localAddress(int fd, InetAddressContainer in) throws SocketException;

    static native void listen0(int fd, int backlog) throws IOException;

    static native int accept0(int fd, InetSocketAddress[] isaa) throws IOException;

    static native void waitForNewConnection(int fd, int timeout) throws IOException;

    static native int available0(int fd) throws IOException;

    static native void close0(int fd) throws IOException;

    static native void shutdown0(int fd, int howto) throws IOException;

    static native void setIntOption(int fd, int cmd, int optionValue) throws SocketException;

    static native int getIntOption(int fd, int cmd) throws SocketException;

    static native void sendOOB(int fd, int data) throws IOException;

    static native void configureBlocking(int fd, boolean blocking) throws IOException;
```

这应该就是Java层面的底层实现了，再继续查看代码，就要看JVM层面了。