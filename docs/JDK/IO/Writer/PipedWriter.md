# PipedWriter

## Field

```java
    // 连接pipedReader
	private PipedReader sink;
	// 关闭标志位
    private boolean closed = false;
```

## 构造函数

```java
    public PipedWriter() {
    }

    public PipedWriter(PipedReader snk)  throws IOException {
        connect(snk);
    }
```

## 功能函数

### connect

```java
    public synchronized void connect(PipedReader snk) throws IOException {
        if (snk == null) {
            throw new NullPointerException();
        } else if (sink != null || snk.connected) {
            throw new IOException("Already connected");
        } else if (snk.closedByReader || closed) {
            throw new IOException("Pipe closed");
        }
		// 记录下此PipedReader
        sink = snk;
        snk.in = -1;
        snk.out = 0;
        // 设置连接标志
        snk.connected = true;
    }
```

### write

```java
    public void write(int c)  throws IOException {
        if (sink == null) {
            throw new IOException("Pipe not connected");
        }
        // 把数据写入到PipedReader中
        sink.receive(c);
    }
```

```java
    public void write(char cbuf[], int off, int len) throws IOException {
        if (sink == null) {
            throw new IOException("Pipe not connected");
        } else if ((off | len | (off + len) | (cbuf.length - (off + len))) < 0) {
            throw new IndexOutOfBoundsException();
        }
        // 写入到PipedReader
        sink.receive(cbuf, off, len);
    }

```



### flush

```java
    public synchronized void flush() throws IOException {
        if (sink != null) {
            if (sink.closedByReader || closed) {
                throw new IOException("Pipe closed");
            }
            synchronized (sink) {
                sink.notifyAll(); // 通知其他的读取的线程
            }
        }
    }
```