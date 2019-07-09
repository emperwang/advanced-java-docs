# TwoStacksPlainSocketImpl

## Field

```java
    // 文件描述符
	private FileDescriptor fd1;

    /*
     * Needed for ipv6 on windows because we need to know
     * if the socket is bound to ::0 or 0.0.0.0, when a caller
     * asks for it. Otherwise we don't know which socket to ask.
     */
    private InetAddress anyLocalBoundAddr = null;

    /* to prevent starvation when listening on two sockets, this is
     * is used to hold the id of the last socket we accepted on.
     */
	// 上次的文件描述符
	private int lastfd = -1;

    // true if this socket is exclusively bound
    private final boolean exclusiveBind;

    // emulates SO_REUSEADDR when exclusiveBind is true
    private boolean isReuseAddress;
```
静态初始化函数

```java
    static {
        initProto();
    }
    static native void initProto();
```



## 构造函数

```java
    public TwoStacksPlainSocketImpl(boolean exclBind) {
        exclusiveBind = exclBind;
    }

    public TwoStacksPlainSocketImpl(FileDescriptor fd, boolean exclBind) {
        this.fd = fd;
        exclusiveBind = exclBind;
    }
```


## 功能函数

### create

```java
    protected synchronized void create(boolean stream) throws IOException {
        fd1 = new FileDescriptor();
        try {
            // 依然是调用底层函数  进行创建操作
            super.create(stream);
        } catch (IOException e) {
            fd1 = null;
            throw e;
        }
    }
```


### bind

```java
    protected synchronized void bind(InetAddress address, int lport)
        throws IOException
    {
    	// 底层函数进行绑定
        super.bind(address, lport);
        if (address.isAnyLocalAddress()) {
            anyLocalBoundAddr = address;
        }
    }
```


### socketBind

```java
    void socketBind(InetAddress address, int port) throws IOException {
        socketBind(address, port, exclusiveBind);
    }
```


### close

```java
    protected void close() throws IOException {
        synchronized(fdLock) {
            if (fd != null || fd1 != null) {
                if (!stream) { // UDP关闭
                    ResourceManager.afterUdpClose();
                }
                if (fdUseCount == 0) { // 文件描述符没有其他线程再用了
                    if (closePending) {
                        return;
                    }
                    closePending = true;
                    socketClose();
                    fd = null;
                    fd1 = null;
                    return;
                } else { // 仍有线程再使用线程描述符
      				// 减少描述符引用次数
                    if (!closePending) {
                        closePending = true;
                        fdUseCount--;
                        socketClose();
                    }
                }
            }
        }
    }
```


### nativeMethod

```java
 static native void initProto();

    native void socketCreate(boolean isServer) throws IOException;

    native void socketConnect(InetAddress address, int port, int timeout)
        throws IOException;

    native void socketBind(InetAddress address, int port, boolean exclBind)
        throws IOException;

    native void socketListen(int count) throws IOException;

    native void socketAccept(SocketImpl s) throws IOException;

    native int socketAvailable() throws IOException;

    native void socketClose0(boolean useDeferredClose) throws IOException;

    native void socketShutdown(int howto) throws IOException;

    native void socketNativeSetOption(int cmd, boolean on, Object value)
        throws SocketException;

    native int socketGetOption(int opt, Object iaContainerObj) throws SocketException;

    native void socketSendUrgentData(int data) throws IOException;
```

