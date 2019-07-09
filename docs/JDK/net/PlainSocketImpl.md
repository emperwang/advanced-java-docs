# PlainSocketImpl

## Field

```java
    // 记录具体的实现类
	private AbstractPlainSocketImpl impl;
    /* the windows version. */
    private static float version;
    /* java.net.preferIPv4Stack */
    private static boolean preferIPv4Stack = false;
    /* If the version supports a dual stack TCP implementation */
    private static boolean useDualStackImpl = false;
    /* sun.net.useExclusiveBind */
    private static String exclBindProp;
    /* True if exclusive binding is on for Windows */
    private static boolean exclusiveBind = true;
```

静态初始化代码:

```java
static {
    java.security.AccessController.doPrivileged( new PrivilegedAction<Object>() {
        public Object run() {
            version = 0;
            try {
                // 获取系统版本
                version = Float.parseFloat(System.getProperties().getProperty("os.version"));
                // 判断是否使用IPV4-stack
                preferIPv4Stack = Boolean.parseBoolean(
 System.getProperties().getProperty("java.net.preferIPv4Stack"));
                exclBindProp = System.getProperty("sun.net.useExclusiveBind");
            } catch (NumberFormatException e ) {
                assert false : e;
            }
            return null; // nothing to return
        } });

    // (version >= 6.0) implies Vista or greater.
    // 这是系统底层的区别,系统版本一样, 网络栈不一样
    if (version >= 6.0 && !preferIPv4Stack) {
        useDualStackImpl = true;
    }
    if (exclBindProp != null) {
        // sun.net.useExclusiveBind is true
        exclusiveBind = exclBindProp.length() == 0 ? true
            : Boolean.parseBoolean(exclBindProp);
    } else if (version < 6.0) {
        exclusiveBind = false;
    }
}
```



## 构造函数

```java
    PlainSocketImpl() {
        // 这里就看出来了,具体的两个实现类
        // 这是根据windows系统实现的.可能系统版本迭代,导致了网络栈的实现有区别
        if (useDualStackImpl) {
            impl = new DualStackPlainSocketImpl(exclusiveBind);
        } else {
            impl = new TwoStacksPlainSocketImpl(exclusiveBind);
        }
    }

    PlainSocketImpl(FileDescriptor fd) {
        if (useDualStackImpl) {
            impl = new DualStackPlainSocketImpl(fd, exclusiveBind);
        } else {
            impl = new TwoStacksPlainSocketImpl(fd, exclusiveBind);
        }
    }
```



## 功能函数

### getFileDescriptor
```java
    protected FileDescriptor getFileDescriptor() {
        return impl.getFileDescriptor();
    }
```
### getInetAddress
```java
    protected InetAddress getInetAddress() {
        return impl.getInetAddress();
    }
```
### getPort
```java
    protected int getPort() {
        return impl.getPort();
    }
```


### getLocalPort
```java
    protected int getLocalPort() {
        return impl.getLocalPort();
    }
```


### get/setSocket
```java
    void setSocket(Socket soc) {
        impl.setSocket(soc);
    }

    Socket getSocket() {
        return impl.getSocket();
    }
```


### set/getServerSocket
```java
    void setServerSocket(ServerSocket soc) {
        impl.setServerSocket(soc);
    }

    ServerSocket getServerSocket() {
        return impl.getServerSocket();
    }
```


### create
```java
    protected synchronized void create(boolean stream) throws IOException {
        impl.create(stream);

        // set fd to delegate's fd to be compatible with older releases
        this.fd = impl.fd;
    }
```


### connect
```java
    protected synchronized void create(boolean stream) throws IOException {
        impl.create(stream);
        this.fd = impl.fd;
    }

    protected void connect(String host, int port)
        throws UnknownHostException, IOException
    {
        impl.connect(host, port);
    }

    protected void connect(InetAddress address, int port) throws IOException {
        impl.connect(address, port);
    }

    protected void connect(SocketAddress address, int timeout) throws IOException {
        impl.connect(address, timeout);
    }
```


### doConnect
```java
    synchronized void doConnect(InetAddress address, int port, int timeout) throws IOException {
        impl.doConnect(address, port, timeout);
    }
```
### bind
```java
    protected synchronized void bind(InetAddress address, int lport)
        throws IOException
    {
        impl.bind(address, lport);
    }
```


### accept
```java
   protected synchronized void accept(SocketImpl s) throws IOException {
        if (s instanceof PlainSocketImpl) {
            // pass in the real impl not the wrapper.
            SocketImpl delegate = ((PlainSocketImpl)s).impl;
            delegate.address = new InetAddress();
            delegate.fd = new FileDescriptor();
            impl.accept(delegate);
            // set fd to delegate's fd to be compatible with older releases
            s.fd = delegate.fd;
        } else {
            impl.accept(s);
        }
    }
```


### set
```java
   void setFileDescriptor(FileDescriptor fd) {
        impl.setFileDescriptor(fd);
    }

    void setAddress(InetAddress address) {
        impl.setAddress(address);
    }

    void setPort(int port) {
        impl.setPort(port);
    }

    void setLocalPort(int localPort) {
        impl.setLocalPort(localPort);
    }
```


### set/getInputStream
```java
    protected synchronized InputStream getInputStream() throws IOException {
        return impl.getInputStream();
    }

    void setInputStream(SocketInputStream in) {
        impl.setInputStream(in);
    }
```
### getOutputStream
```java
    protected synchronized OutputStream getOutputStream() throws IOException {
        return impl.getOutputStream();
    }
```
### socketCreate
```java
    void socketCreate(boolean isServer) throws IOException {
        impl.socketCreate(isServer);
    }
```


### socketConnect

```java

    void socketConnect(InetAddress address, int port, int timeout)
        throws IOException {
        impl.socketConnect(address, port, timeout);
    }
```

### socketBind

```java
    void socketBind(InetAddress address, int port)
        throws IOException {
        impl.socketBind(address, port);
    }
```



### socketListen

```java
    void socketListen(int count) throws IOException {
        impl.socketListen(count);
    }
```

很清晰了，就是调用了具体的实现方法而已。趁热打铁，接着往下走。