# SocketOutputStream

## Field

```java
    // 具体的实现类
	private AbstractPlainSocketImpl impl = null;
    private byte temp[] = new byte[1];
	// 对应的socket
    private Socket socket = null;
	// 是否正在关闭
    private boolean closing = false;
```

静态初始化函数:

```java
    static {
        init();
    }
    private native static void init();
```



## 构造函数

```java
    SocketOutputStream(AbstractPlainSocketImpl impl) throws IOException {
        super(impl.getFileDescriptor()); // 记录文件描述符
        this.impl = impl;		// 实现类
        socket = impl.getSocket();	// 对应的socket
    }
```



## 功能方法

### getChannel
```java
    public final FileChannel getChannel() {
        return null;
    }
```


### socketWrite
```java
   // 下数据到socket中
	private void socketWrite(byte b[], int off, int len) throws IOException {
        if (len <= 0 || off < 0 || len > b.length - off) {
            if (len == 0) {
                return;
            }
            throw new ArrayIndexOutOfBoundsException("len == " + len
                    + " off == " + off + " buffer length == " + b.length);
        }
		// 获取文件描述符
        FileDescriptor fd = impl.acquireFD();
        try {
            // 具体的写入操作
            // 底层方法实现
            socketWrite0(fd, b, off, len);
        } catch (SocketException se) {
            if (se instanceof sun.net.ConnectionResetException) {
                impl.setConnectionResetPending();
                se = new SocketException("Connection reset");
            }
            if (impl.isClosedOrPending()) {
                throw new SocketException("Socket closed");
            } else {
                throw se;
            }
        } finally {
            impl.releaseFD();
        }
    }

 private native void socketWrite0(FileDescriptor fd, byte[] b, int off,
                                     int len) throws IOException;
```


### write
```java
    public void write(int b) throws IOException {
        temp[0] = (byte)b;
        socketWrite(temp, 0, 1);
    }

    public void write(byte b[]) throws IOException {
        socketWrite(b, 0, b.length);
    }

    public void write(byte b[], int off, int len) throws IOException {
        socketWrite(b, off, len);
    }
```


### close

```java
    public void close() throws IOException {
        // Prevent recursion. See BugId 4484411
        if (closing)
            return;
        closing = true;
        if (socket != null) {
            if (!socket.isClosed())
                socket.close();
        } else
            impl.close();
        closing = false;
    }
```

