# SocketInputStream

## Field
```java
    private boolean eof;
	// 具体的socket实现
    private AbstractPlainSocketImpl impl = null;
    private byte temp[];
	// 对应的socket
    private Socket socket = null;
	// 是否正在关闭
    private boolean closing = false;
```

静态初始化代码:

```java
    static {
        init();
    }
    private native static void init();
```



## 构造函数

```java
    SocketInputStream(AbstractPlainSocketImpl impl) throws IOException {
        // 记录文件描述符
        super(impl.getFileDescriptor());
        // 具体的实现
        this.impl = impl;
        // 对应的socket
        socket = impl.getSocket();
    }
```


## 功能函数

### getChannel
```java
   public final FileChannel getChannel() {
        return null;
    }
```
### socketRead
```java
    private int socketRead(FileDescriptor fd,
                           byte b[], int off, int len,
                           int timeout)
        throws IOException {
        return socketRead0(fd, b, off, len, timeout);
    }
	/*Reads into an array of bytes at the specified offset using
      the received socket primitive. */
	// 从接收缓存区读取数据到  数组b中
    private native int socketRead0(FileDescriptor fd,
                                   byte b[], int off, int len,
                                   int timeout)
        throws IOException;
```


### read
```java
   // 读取数据到数组中
	public int read(byte b[]) throws IOException {
        return read(b, 0, b.length);
    }

    public int read(byte b[], int off, int length) throws IOException {
        return read(b, off, length, impl.getTimeout());
    }

```

```java
    int read(byte b[], int off, int length, int timeout) throws IOException {
        int n;
        // EOF already encountered
        // 已经结束
        if (eof) {
            return -1;
        }
        // connection reset
        if (impl.isConnectionReset()) {
            throw new SocketException("Connection reset");
        }
        // bounds check
        if (length <= 0 || off < 0 || length > b.length - off) {
            if (length == 0) {
                return 0;
            }
            throw new ArrayIndexOutOfBoundsException("length == " + length
                    + " off == " + off + " buffer length == " + b.length);
        }

        boolean gotReset = false;

        // acquire file descriptor and do the read
        // 增加文件描述符的引用册数
        FileDescriptor fd = impl.acquireFD();
        try {
            // 读取数据
            // 底层方法实现
            n = socketRead(fd, b, off, length, timeout);
            if (n > 0) {
                return n;
            }
        } catch (ConnectionResetException rstExc) {
            gotReset = true;
        } finally {
            // 使用文件引用
            impl.releaseFD();
        }
        /*
         * We receive a "connection reset" but there may be bytes still
         * buffered on the socket
         */
        // reset操作
        if (gotReset) {
            impl.setConnectionResetPending();
            impl.acquireFD();
            try {
                // 从头读取
                n = socketRead(fd, b, off, length, timeout);
                if (n > 0) {
                    return n;
                }
            } catch (ConnectionResetException rstExc) {
            } finally {
                impl.releaseFD();
            }
        }

        /*
         * If we get here we are at EOF, the socket has been closed,
         * or the connection has been reset.
         */
        if (impl.isClosedOrPending()) {
            throw new SocketException("Socket closed");
        }
        if (impl.isConnectionResetPending()) {
            impl.setConnectionReset();
        }
        if (impl.isConnectionReset()) {
            throw new SocketException("Connection reset");
        }
        // 读取到结束了
        eof = true;
        return -1;
    }
```

读取一个字节from socket:

```java
    public int read() throws IOException {
        if (eof) {
            return -1;
        }
        temp = new byte[1];
        // 读取字节
        int n = read(temp, 0, 1);
        if (n <= 0) {
            return -1;
        }
        // 返回读取的数据
        return temp[0] & 0xff;
    }
```



### skip

```java
    // 跳过一些字节
	public long skip(long numbytes) throws IOException {
        if (numbytes <= 0) {
            return 0;
        }
        long n = numbytes;
        // 最大为1024
        int buflen = (int) Math.min(1024, n);
        // 存储跳过的数据
        byte data[] = new byte[buflen];
        // 读取数据到data中，进行跳过操作
        while (n > 0) {
            int r = read(data, 0, (int) Math.min((long) buflen, n));
            if (r < 0) {
                break;
            }
            n -= r;
        }
        return numbytes - n;
    }
```


### available

```java
    public int available() throws IOException {
        return impl.available();
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
			// socket关闭操作
                socket.close();
        } else
            impl.close();
        closing = false;
    }
```

