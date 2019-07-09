# SocketImpl

从Socket实现我们看到，其实socket的实现依赖于SocketImpl这个类，那为了了解其原理，咱们就来看一下把。

## Field

```java
    /**
     * The actual Socket object.
     */
    Socket socket = null;
    ServerSocket serverSocket = null;

    /**
     * The file descriptor object for this socket.
     */
	// 文件描述符
    protected FileDescriptor fd;

    /**
     * The IP address of the remote end of this socket.
     */
	// ip 地址
    protected InetAddress address;

    /**
     * The port number on the remote host to which this socket is connected.
     */
	// 端口号
    protected int port;

    /**
     * The local port number to which this socket is connected.
     */
	// 本地端口号
    protected int localport;

```



## 功能方法

### create
```java
    protected abstract void create(boolean stream) throws IOException;
```
### connect
```java
protected abstract void connect(String host, int port) throws IOException;
protected abstract void connect(InetAddress address, int port) throws IOException;
protected abstract void connect(SocketAddress address, int timeout) throws IOException;
```


### bind
```java
    protected abstract void bind(InetAddress host, int port) throws IOException;
```
### listen
```java
    protected abstract void listen(int backlog) throws IOException;
```


### accept
```java
    protected abstract void accept(SocketImpl s) throws IOException;
```


### getInputStream
```java
    protected abstract InputStream getInputStream() throws IOException;
```


### getOutputStream
```java
protected abstract OutputStream getOutputStream() throws IOException;
```


### available
```java
protected abstract int available() throws IOException;
```


### getFileDescriptor
```java
protected FileDescriptor getFileDescriptor() {
    return fd;
}
```


### getInetAddress
```java
    protected InetAddress getInetAddress() {
        return address;
    }
```


### getPort
```java
protected int getPort() {
        return port;
    }
```


### sendUrgentData
```java
protected abstract void sendUrgentData (int data) throws IOException;
```


### getLocalPort
```java
protected int getLocalPort() {
        return localport;
    }
```


### set/getSocket

```java
    void setSocket(Socket soc) {
        this.socket = soc;
    }

    Socket getSocket() {
        return socket;
    }
```

### set/getServerSocket

```java
    void setServerSocket(ServerSocket soc) {
        this.serverSocket = soc;
    }

    ServerSocket getServerSocket() {
        return serverSocket;
    }
```



可以看到，大多是的实现是需要具体的子类实现的，此类就是把公共的方法抽象出来。

再看其子类。。。。[AbstractPlainSocketImpl](AbstractPlainSocketImpl.md)