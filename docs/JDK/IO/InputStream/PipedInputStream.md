# PipedInputStream

## Field

```java

    boolean closedByWriter = false;
    volatile boolean closedByReader = false;
    boolean connected = false;

    Thread readSide;
    Thread writeSide;
	// 默认大小
    private static final int DEFAULT_PIPE_SIZE = 1024;

    protected static final int PIPE_SIZE = DEFAULT_PIPE_SIZE;
	// 读取数据存放的地方
    protected byte buffer[];
	// 存放数据的位置
    protected int in = -1;
	// 读取数据的位置
	protected int out = 0;
```

## 构造函数

```java
    public PipedInputStream(int pipeSize) {
        initPipe(pipeSize);
    }

    public PipedInputStream() {
        initPipe(DEFAULT_PIPE_SIZE);
    }

    public PipedInputStream(PipedOutputStream src, int pipeSize)
            throws IOException {
        // 初始化buffer
         initPipe(pipeSize);
         connect(src);
    }
```

```java
    private void initPipe(int pipeSize) {
         if (pipeSize <= 0) {
            throw new IllegalArgumentException("Pipe Size <= 0");
         }
        // 创建buffer数组
         buffer = new byte[pipeSize];
    }

    public void connect(PipedOutputStream src) throws IOException {
        // 调用PipedOutputStream的conenct函数，进行连接
        src.connect(this);
    }
```



## 功能函数

### receive

```java
    // 从PipedoutputStream接收数据
	protected synchronized void receive(int b) throws IOException {
        checkStateForReceive();
        // 记录当前写入的线程
        writeSide = Thread.currentThread();
        // in==out,则等待空间写入
        if (in == out)
            awaitSpace();
        if (in < 0) {
            in = 0;
            out = 0;
        }
        // 往buffer中进行写入
        buffer[in++] = (byte)(b & 0xFF);
        // 如果写到头,则再从头写入
        if (in >= buffer.length) {
            in = 0;
        }
    }
	// 状态检查
    private void checkStateForReceive() throws IOException {
        if (!connected) {
            throw new IOException("Pipe not connected");
        } else if (closedByWriter || closedByReader) {
            throw new IOException("Pipe closed");
        } else if (readSide != null && !readSide.isAlive()) {
            throw new IOException("Read end dead");
        }
    }

    private void awaitSpace() throws IOException {
        while (in == out) {
            checkStateForReceive();
            /* full: kick any waiting readers */
            // 唤醒读取线程
            notifyAll();
            try {
                // 当前线程进行等待
                wait(1000);
            } catch (InterruptedException ex) {
                throw new java.io.InterruptedIOException();
            }
        }
    }
```

```java
    synchronized void receive(byte b[], int off, int len)  throws IOException {
        checkStateForReceive();
        // 状态检查
        writeSide = Thread.currentThread();
        int bytesToTransfer = len;
        while (bytesToTransfer > 0) {
            // 缓存满了,则等待
            if (in == out)
                awaitSpace();
            int nextTransferAmount = 0;
            // buffer是一个循环存储的数组
            if (out < in) { // 此情况说明,in的位置到 buffer.length是可写的空间
                nextTransferAmount = buffer.length - in;
            } else if (in < out) { // 说明in写到从,又从头开始写的情况
                if (in == -1) { // 说明是开始--first-time
                    in = out = 0;
                    nextTransferAmount = buffer.length - in;
                } else { // 说此情况就是:in到out之间已经消费过的数据,out到最后是没没有消费的数据,所以in到out之间消费过的数据就可以被覆盖掉
                    nextTransferAmount = out - in;
                }
            }
            // 防止空间不够
            if (nextTransferAmount > bytesToTransfer)
                nextTransferAmount = bytesToTransfer;
            assert(nextTransferAmount > 0);
            // 把数据写入到buffer中
            System.arraycopy(b, off, buffer, in, nextTransferAmount);
            bytesToTransfer -= nextTransferAmount;
            // 更新索引位置
            off += nextTransferAmount;
            in += nextTransferAmount;
            if (in >= buffer.length) {
                in = 0;
            }
        }
    }
```



### read

```java
    public synchronized int read()  throws IOException {
        if (!connected) {
            throw new IOException("Pipe not connected");
        } else if (closedByReader) {
            throw new IOException("Pipe closed");
        } else if (writeSide != null && !writeSide.isAlive()
                   && !closedByWriter && (in < 0)) {
            throw new IOException("Write end dead");
        }
		// 记录当前读取的线程
        readSide = Thread.currentThread();
        int trials = 2;
        while (in < 0) { // 说明此时buffer为空,没有可用数据
            if (closedByWriter) {
                /* closed by writer, return EOF */
                return -1;
            }
            if ((writeSide != null) && (!writeSide.isAlive()) && (--trials < 0)) {
                throw new IOException("Pipe broken");
            }
            /* might be a writer waiting */
            // 唤醒写入线程
            notifyAll();
            try {
                wait(1000);
            } catch (InterruptedException ex) {
                throw new java.io.InterruptedIOException();
            }
        }
        // 直接读取buffer中数据
        int ret = buffer[out++] & 0xFF;
        if (out >= buffer.length) {
            out = 0;
        }
        // 为空
        if (in == out) {
            /* now empty */
            in = -1;
        }
        // 返回读取的数据
        return ret;
    }
```

```java
    public synchronized int read(byte b[], int off, int len)  throws IOException {
        if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }
        /* possibly wait on the first character */
        int c = read();
        if (c < 0) {
            return -1;
        }
        // 数据放入到数组b中
        b[off] = (byte) c;
        int rlen = 1;
        while ((in >= 0) && (len > 1)) {
            int available;
            // 获取buffer中可用数据多少
            if (in > out) {
                available = Math.min((buffer.length - out), (in - out));
            } else {
                available = buffer.length - out;
            }

            // A byte is read beforehand outside the loop
            if (available > (len - 1)) {
                available = len - 1;
            }
            // 把数据从buffer中拷贝到b中
            System.arraycopy(buffer, out, b, off + rlen, available);
            // 更新索引
            out += available;
            rlen += available;
            len -= available;
			// 回滚从头开始
            if (out >= buffer.length) {
                out = 0;
            }
            if (in == out) {
                /* now empty */
                in = -1;
            }
        }
        return rlen;
    }
```



### available

```java
    public synchronized int available() throws IOException {
        if(in < 0) // 空buffer
            return 0;
        else if(in == out)
            return buffer.length;
        else if (in > out)
            return in - out;
        else
            return in + buffer.length - out;
    }
```



可以看到PipedInputStream和PipedOutputStream是一起使用的，所以在这里一起进行分析.

## PipedOutputStream

## Field

```java
    private PipedInputStream sink; // 用于和PipedInputStream进行连接字段
```



## 构造函数

```java
    public PipedOutputStream(PipedInputStream snk)  throws IOException {
        connect(snk);
    }

    public PipedOutputStream() {
    }
```



## 功能函数

### connect

```java
    public synchronized void connect(PipedInputStream snk) throws IOException {
        if (snk == null) {
            throw new NullPointerException();
        } else if (sink != null || snk.connected) {
            throw new IOException("Already connected");
        }
        // outputStream和inputStream进行连接，并设置标志位
        sink = snk;
        snk.in = -1;
        snk.out = 0;
        snk.connected = true;
    }
```

### write

```java
    public void write(int b)  throws IOException {
        if (sink == null) {
            throw new IOException("Pipe not connected");
        }
        // 可以看到写函数就是inputStream的接收,也就是往inputStream写
        sink.receive(b);
    }

    public void write(byte b[], int off, int len) throws IOException {
        if (sink == null) {
            throw new IOException("Pipe not connected");
        } else if (b == null) {
            throw new NullPointerException();
        } else if ((off < 0) || (off > b.length) || (len < 0) ||
                   ((off + len) > b.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return;
        }
        // 同样是往inputStream进行写入操作
        sink.receive(b, off, len);
    }
```



### flush

```java
    public synchronized void flush() throws IOException {
        if (sink != null) {
            synchronized (sink) {
                // 唤醒其他线程
                sink.notifyAll();
            }
        }
    }
```

### Close

```java
    public void close()  throws IOException {
        if (sink != null) {
            // 把剩余的数据接收
            sink.receivedLast();
        }
    }
```

