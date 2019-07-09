# PushBackInputStream

## Field
```java
    //当前元素在数据中的位置
	protected int pos;
    protected byte[] buf;
```


## 构造函数
```java
    public PushbackInputStream(InputStream in, int size) {
        super(in);
        if (size <= 0) {
            throw new IllegalArgumentException("size <= 0");
        }
        // 使用指定大小初始化数组
        this.buf = new byte[size];
        // 指向栈顶
        this.pos = size;
    }

    public PushbackInputStream(InputStream in) {
        this(in, 1); // 默认使用一个数组长度
    }
```


## 功能函数

### ensureOpen
```java
    private void ensureOpen() throws IOException {
        if (in == null)  // 保证有输入流
            throw new IOException("Stream closed");
    }
```


### read
```java
    public int read() throws IOException {
        ensureOpen();
        if (pos < buf.length) {
            // 从buf中读取数据
            return buf[pos++] & 0xff;
        }
        // 否则直接从输入流中读取
        return super.read();
    }
```


### read byte Array
```java
   public int read(byte[] b, int off, int len) throws IOException {
        ensureOpen();
        if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }
		// buf中可用元素个数
        int avail = buf.length - pos;
        if (avail > 0) {
            if (len < avail) {
                avail = len;
            }
            // 从buf中拷贝数据到b中
            System.arraycopy(buf, pos, b, off, avail);
            pos += avail;
            off += avail;
            len -= avail;
        }
        if (len > 0) {
            // 如果buf中数据不足,则直接从输入流中读取数据放到b中
            len = super.read(b, off, len);
            if (len == -1) {
                return avail == 0 ? -1 : avail;
            }
            return avail + len;
        }
        return avail;
    }
```
### unread
```java
    // 存数据的功能
	public void unread(int b) throws IOException {
        ensureOpen();
        if (pos == 0) {
            throw new IOException("Push back buffer is full");
        }
        // 存到buf中,类似于栈的存放;FIFO
        buf[--pos] = (byte)b;
    }
```

### unread byte Array
```java
    public void unread(byte[] b, int off, int len) throws IOException {
        ensureOpen();
        if (len > pos) {
            throw new IOException("Push back buffer is full");
        }
        pos -= len;
        // 把b中数据拷贝到buf中
        System.arraycopy(b, off, buf, pos, len);
    }
```


### available
```java
    public int available() throws IOException {
        ensureOpen();
        // buf中可用数据数
        int n = buf.length - pos;
        // 输入流中可用数据数
        int avail = super.available();
        // 得到总的可用数据数
        return n > (Integer.MAX_VALUE - avail)
                    ? Integer.MAX_VALUE
                    : n + avail;
    }
```


### skip
```java
    public long skip(long n) throws IOException {
        ensureOpen();
        if (n <= 0) {
            return 0;
        }
		// 得到buf中可跳过数据总数
        long pskip = buf.length - pos;
        // 操作buf中的pos跳过元素
        if (pskip > 0) {
            if (n < pskip) {
                pskip = n;
            }
            pos += pskip;
            n -= pskip;
        }
        // 如果buf中元素不足,则从输入流中继续跳过元素
        if (n > 0) {
            pskip += super.skip(n);
        }
        return pskip;
    }
```


### mark

```java
    public synchronized void mark(int readlimit) {
    }
```

