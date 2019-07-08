# PipedReader

## Field

```java
    // 状态标志位
	boolean closedByWriter = false;
    boolean closedByReader = false;
    boolean connected = false;
	// 记录读写线程
    Thread readSide;
    Thread writeSide;
	// 默认数组的长度
    private static final int DEFAULT_PIPE_SIZE = 1024;
	// 存储数据
    char buffer[];
	// 写入位置
    int in = -1;
	// 读取的位置
    int out = 0;
```

## 构造函数
```java
    public PipedReader(PipedWriter src) throws IOException {
        this(src, DEFAULT_PIPE_SIZE);
    }

    public PipedReader(PipedWriter src, int pipeSize) throws IOException {
        initPipe(pipeSize);
        connect(src);
    }

    public PipedReader(int pipeSize) {
        initPipe(pipeSize);
    }
```


## 功能函数

### initPipe
```java
    private void initPipe(int pipeSize) {
        if (pipeSize <= 0) {
            throw new IllegalArgumentException("Pipe size <= 0");
        }
        // 初始化存储数据的数组
        buffer = new char[pipeSize];
    }
```
### connect
```java
    public void connect(PipedWriter src) throws IOException {
        // 调用PipedWriter的connect进行连接
        src.connect(this);
    }
```
### revceive
```java
    synchronized void receive(int c) throws IOException {
        if (!connected) {
            throw new IOException("Pipe not connected");
        } else if (closedByWriter || closedByReader) {
            throw new IOException("Pipe closed");
        } else if (readSide != null && !readSide.isAlive()) {
            throw new IOException("Read end dead");
        }
		// 记录写入数据的线程
        writeSide = Thread.currentThread();
        while (in == out) { // 数据满了
            if ((readSide != null) && !readSide.isAlive()) {
                throw new IOException("Pipe broken");
            }
            /* full: kick any waiting readers */
            // 唤醒所有线程
            notifyAll();
            try {
                // 当前线程等待
                wait(1000);
            } catch (InterruptedException ex) {
                throw new java.io.InterruptedIOException();
            }
        }
        if (in < 0) {
            in = 0;
            out = 0;
        }
        // 写入数据
        buffer[in++] = (char) c;
        // 写满了，则再从头开始写
        if (in >= buffer.length) {
            in = 0;
        }
    }
```

```java
    synchronized void receive(char c[], int off, int len)  throws IOException {
        while (--len >= 0) {
            receive(c[off++]);
        }
    }
	// 接收最后，也就是更新写入关闭；并通知其他所有线程
    synchronized void receivedLast() {
        closedByWriter = true;
        notifyAll();
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
		// 记录读取线程
        readSide = Thread.currentThread();
        int trials = 2;
        while (in < 0) {  // 没有数据
            // 写线程关闭了，则直接返回-1
            if (closedByWriter) {
                /* closed by writer, return EOF */
                return -1;
            }
            if ((writeSide != null) && (!writeSide.isAlive()) && (--trials < 0)) {
                throw new IOException("Pipe broken");
            }
            /* might be a writer waiting */
            // 唤醒所有线程
            notifyAll();
            try {
                // 当前读线程等待
                wait(1000);
            } catch (InterruptedException ex) {
                throw new java.io.InterruptedIOException();
            }
        }
        // 读取out位置的数据
        int ret = buffer[out++];
        // 读到尾，则再从头开始读取
        if (out >= buffer.length) {
            out = 0;
        }
        if (in == out) {
            /* now empty */
            in = -1;
        }
        // 返回读取的数据
        return ret;
    }
```
```java
    public synchronized int read(char cbuf[], int off, int len)  throws IOException {
        if (!connected) {
            throw new IOException("Pipe not connected");
        } else if (closedByReader) {
            throw new IOException("Pipe closed");
        } else if (writeSide != null && !writeSide.isAlive()
                   && !closedByWriter && (in < 0)) {
            throw new IOException("Write end dead");
        }

        if ((off < 0) || (off > cbuf.length) || (len < 0) ||
            ((off + len) > cbuf.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }
        // 读取数据
        int c = read();
        if (c < 0) {
            return -1;
        }
        // 放入到数组中
        cbuf[off] =  (char)c;
        int rlen = 1;
        while ((in >= 0) && (--len > 0)) {
            // 循环读取数据，并存储到cbuf中
            cbuf[off + rlen] = buffer[out++];
            rlen++;
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

### ready

```java
    public synchronized boolean ready() throws IOException {
        if (!connected) {
            throw new IOException("Pipe not connected");
        } else if (closedByReader) {
            throw new IOException("Pipe closed");
        } else if (writeSide != null && !writeSide.isAlive()
                   && !closedByWriter && (in < 0)) {
            throw new IOException("Write end dead");
        }
        if (in < 0) {
            return false;
        } else { // in>0，就是准备好了；也就是有数据
            return true;
        }
    }
```

### close

```java
    public void close()  throws IOException {
        in = -1;	// 设置in=-1，表示没有数据
        closedByReader = true; // 设置标志位，表示关闭
    }
```

