# AbstractPlainSocketImpl

## Field
```java
    int timeout;   // timeout in millisec
    // traffic class
    private int trafficClass;

    private boolean shut_rd = false;
    private boolean shut_wr = false;

    private SocketInputStream socketInputStream = null;
    private SocketOutputStream socketOutputStream = null;

    /* number of threads using the FileDescriptor */
    protected int fdUseCount = 0;

    /* lock when increment/decrementing fdUseCount */
    protected final Object fdLock = new Object();

    /* indicates a close is pending on the file descriptor */
    protected boolean closePending = false;

    /* indicates connection reset state */
    private int CONNECTION_NOT_RESET = 0;
    private int CONNECTION_RESET_PENDING = 1;
    private int CONNECTION_RESET = 2;
    private int resetState;
    private final Object resetLock = new Object();

   /* whether this Socket is a stream (TCP) socket or not (UDP)
    */
    protected boolean stream;
    public final static int SHUT_RD = 0;
    public final static int SHUT_WR = 1;
```

静态初始化代码:

```java
    static {
        java.security.AccessController.doPrivileged(
            new java.security.PrivilegedAction<Void>() {
                public Void run() {
                    System.loadLibrary("net");
                    return null;
                }
            });
    }
```



## 功能方法

### create

```java
   // 参数为true，表示TCP
	// 参数为false 表示UDP
	protected synchronized void create(boolean stream) throws IOException {
        this.stream = stream;
        if (!stream) { // 创建UDP
            // 创建UDP前的准备
           	// socket数不要超过限制
            ResourceManager.beforeUdpCreate();
           // only create the fd after we know we will be able to create the socket
            fd = new FileDescriptor();
            try {
                // 具体创建socket的函数
                socketCreate(false);
            } catch (IOException ioe) {
                ResourceManager.afterUdpClose();
                fd = null;
                throw ioe;
            }
        } else { // 创建TCP
            fd = new FileDescriptor();
            socketCreate(true);
        }
        if (socket != null)
            socket.setCreated();
        if (serverSocket != null)
            serverSocket.setCreated();
    }
```


### connect
```java
    // 创建连接
	protected void connect(String host, int port)
        throws UnknownHostException, IOException
    {
        boolean connected = false;
        try {
        // 把字符串解析为具体的IP地址
            InetAddress address = InetAddress.getByName(host);
            // 记录端口和地址
            this.port = port;
            this.address = address;
			// 连接到这个地址
            connectToAddress(address, port, timeout);
            // 更新标志位
            connected = true;
        } finally {
            if (!connected) {
                try {
                    close();
                } catch (IOException ioe) {
                    /* Do nothing. If connect threw an exception then
                       it will be passed up the call stack */
                }
            }
        }
    }
```

```java
    protected void connect(InetAddress address, int port) throws IOException {
        // 记录端口和地址
        this.port = port;
        this.address = address;
        try {
            // 连接
            connectToAddress(address, port, timeout);
            return;
        } catch (IOException e) {
            // everything failed
            close();
            throw e;
        }
    }
```

```java
    protected void connect(SocketAddress address, int timeout)
            throws IOException {
        boolean connected = false;
        try {
            if (address == null || !(address instanceof InetSocketAddress))
                throw new IllegalArgumentException("unsupported address type");
            // 转换
            InetSocketAddress addr = (InetSocketAddress) address;
            if (addr.isUnresolved())
                throw new UnknownHostException(addr.getHostName());
            // 记录端口和地址
            this.port = addr.getPort();
            this.address = addr.getAddress();
			// 连接
            connectToAddress(this.address, port, timeout);
            connected = true;
        } finally {
            if (!connected) {
                try {
                    close();
                } catch (IOException ioe) {
                    /* Do nothing. If connect threw an exception then
                       it will be passed up the call stack */
                }
            }
        }
    }

```

```java
    private void connectToAddress(InetAddress address, int port, int timeout) throws IOException {
        if (address.isAnyLocalAddress()) {
            // 具体的连接函数
            doConnect(InetAddress.getLocalHost(), port, timeout);
        } else {
            doConnect(address, port, timeout);
        }
    }

	// 具体连接
    synchronized void doConnect(InetAddress address, int port, int timeout) throws IOException {
        synchronized (fdLock) {
            if (!closePending && (socket == null || !socket.isBound())) {
                NetHooks.beforeTcpConnect(fd, address, port);
            }
        }
        try {
            // 文件描述符引用增加
            acquireFD();
            try {
                // 连接
                socketConnect(address, port, timeout);
                /* socket may have been closed during poll/select */
                synchronized (fdLock) {
                    if (closePending) {
                        throw new SocketException ("Socket closed");
                    }
                }
				// 设置bound  和 connect标志位true
                if (socket != null) {
                    socket.setBound();
                    socket.setConnected();
                }
            } finally {
                // 释放文件描述符
                releaseFD();
            }
        } catch (IOException e) {
            close();
            throw e;
        }
    }
```


### bind
```java
    protected synchronized void bind(InetAddress address, int lport)
        throws IOException
    {
       synchronized (fdLock) {
            if (!closePending && (socket == null || !socket.isBound())) {
            // 钩子函数，此处函数为空
                NetHooks.beforeTcpBind(fd, address, lport);
            }
        }
        // 地址绑定
        socketBind(address, lport);
        if (socket != null)
            socket.setBound();
        if (serverSocket != null)
            serverSocket.setBound();
    }
```


### listen
```java
    protected synchronized void listen(int count) throws IOException {
        socketListen(count); // 监听
    }
```
### accept
```java
    protected void accept(SocketImpl s) throws IOException {
        acquireFD(); // 先把文件描述符增加
        try { // 等待连接
            socketAccept(s);
        } finally {
            releaseFD(); // 用完后再释放
        }
    }
```


### set/getInputStream
```java
    protected synchronized InputStream getInputStream() throws IOException {
        synchronized (fdLock) {
            if (isClosedOrPending())
                throw new IOException("Socket Closed");
            if (shut_rd)
                throw new IOException("Socket input is shutdown");
            // scoketInputStream操作此socket
            if (socketInputStream == null)
                socketInputStream = new SocketInputStream(this);
        }
        return socketInputStream;
    }

    void setInputStream(SocketInputStream in) {
        socketInputStream = in;
    }
```


### getOutputStream
```java
    protected synchronized OutputStream getOutputStream() throws IOException {
        synchronized (fdLock) {
            if (isClosedOrPending())
                throw new IOException("Socket Closed");
            if (shut_wr)
                throw new IOException("Socket output is shutdown");
            // socketOuptuStream
            if (socketOutputStream == null)
                socketOutputStream = new SocketOutputStream(this);
        }
        return socketOutputStream;
    }
```


### setFileDescriptor
```java
    void setFileDescriptor(FileDescriptor fd) {
        this.fd = fd;
    }
```
### setAddress
```java
    void setAddress(InetAddress address) {
        this.address = address;
    }
```


### setPort
```java
    void setPort(int port) {
        this.port = port;
    }

```


### setLocalPort
```java
    void setLocalPort(int localport) {
        this.localport = localport;
    }
```


### available
```java
    protected synchronized int available() throws IOException {
        if (isClosedOrPending()) {
            throw new IOException("Stream closed.");
        }
        /*
         * If connection has been reset or shut down for input, then return 0
         * to indicate there are no buffered bytes.
         */
        // 复位 或者  关闭了， 则就没有可用的了
        if (isConnectionReset() || shut_rd) {
            return 0;
        }

        /*
         * If no bytes available and we were previously notified
         * of a connection reset then we move to the reset state.
         *
         * If are notified of a connection reset then check
         * again if there are bytes buffered on the socket.
         */
        int n = 0;
        try {
            n = socketAvailable();
            // 如果没有可用的数 并且 状态为等待 reset， 则进行复位操作
            if (n == 0 && isConnectionResetPending()) {
                setConnectionReset();
            }
        } catch (ConnectionResetException exc1) {
            setConnectionResetPending();
            try {
                n = socketAvailable();
                if (n == 0) {
                    setConnectionReset();
                }
            } catch (ConnectionResetException exc2) {
            }
        }
        return n;
    }
```

### close

```java
    protected void close() throws IOException {
        synchronized(fdLock) {
            if (fd != null) {
                if (!stream) {
                    // UDP关闭前的操作
                    ResourceManager.afterUdpClose();
                }
                if (fdUseCount == 0) {
                    if (closePending) {
                        return;
                    }
                    closePending = true;
                    /*
                     * We close the FileDescriptor in two-steps - first the
                     * "pre-close" which closes the socket but doesn't
                     * release the underlying file descriptor. This operation
                     * may be lengthy due to untransmitted data and a long
                     * linger interval. Once the pre-close is done we do the
                     * actual socket to release the fd.
                     */
                    try {
                        // 为防止仍有数据交互，故socket关闭分两步
                        // 还没有释放文件描述符
                        socketPreClose();
                    } finally {
                        // 真的关闭
                        socketClose();
                    }
                    fd = null;
                    return;
                } else {
                    /*
                     * If a thread has acquired the fd and a close
                     * isn't pending then use a deferred close.
                     * Also decrement fdUseCount to signal the last
                     * thread that releases the fd to close it.
                     */
                    // 文件描述符还有其他线程再用
                    // 则只是减少引用次数
                    if (!closePending) {
                        closePending = true;
                        fdUseCount--;
                        socketPreClose();
                    }
                }
            }
        }
    }
```



### sendUrgentData

```java
    protected void sendUrgentData (int data) throws IOException {
        if (fd == null) {
            throw new IOException("Socket Closed");
        }
        socketSendUrgentData (data);
    }
```
### acquireFD
```java
    FileDescriptor acquireFD() {
        synchronized (fdLock) {
            fdUseCount++;  // 文件描述符引用数增减
            return fd;
        }
    }
```


### releaseFD
```java
    void releaseFD() {
        synchronized (fdLock) {
            fdUseCount--;   // 文件描述符引用数量减少
            if (fdUseCount == -1) {
                if (fd != null) {
                    try {
                        socketClose();
                    } catch (IOException e) {
                    } finally {
                        fd = null;
                    }
                }
            }
        }
    }
```


### socketCreate
```java
    abstract void socketCreate(boolean isServer) throws IOException;
```
### socketBind
```java
abstract void socketBind(InetAddress address, int port)
        throws IOException;
```


### socketConnect
```java
abstract void socketConnect(InetAddress address, int port, int timeout)
        throws IOException;
```
### socketListen
```java
    abstract void socketListen(int count)
        throws IOException;
```


### socketAccept
```java
    abstract void socketAccept(SocketImpl s)
        throws IOException;
```


### socketAvailable
```java
    abstract int socketAvailable()
        throws IOException;
```


### socketClose0

```java
    abstract void socketClose0(boolean useDeferredClose)
        throws IOException;
```

再看其子类的实现...[PlainSocketImpl](PlainSocketImpl.md)