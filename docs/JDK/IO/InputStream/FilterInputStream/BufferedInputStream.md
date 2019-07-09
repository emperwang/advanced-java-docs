# BufferedInputStream

## Field

```java
    // 具体存储数据的缓存区
	protected volatile byte buf[];
	// 默认长度
    private static int DEFAULT_BUFFER_SIZE = 8192;
	// 最大长度
    private static int MAX_BUFFER_SIZE = Integer.MAX_VALUE - 8;
	// 原子更新
    private static final
        AtomicReferenceFieldUpdater<BufferedInputStream, byte[]> bufUpdater =
        AtomicReferenceFieldUpdater.newUpdater
        (BufferedInputStream.class,  byte[].class, "buf");
	// 元素隔宿
    protected int count;
	// 当亲位置
    protected int pos;
	// mark的位置
    protected int markpos = -1;
    protected int marklimit;
```



## 构造函数

```java
    public BufferedInputStream(InputStream in) {
        this(in, DEFAULT_BUFFER_SIZE);
    }

    public BufferedInputStream(InputStream in, int size) {
        super(in);
        if (size <= 0) {
            throw new IllegalArgumentException("Buffer size <= 0");
        }
        // 初始化数组
        buf = new byte[size];
    }
```





## 功能函数

### getInIfOpen

```java
    private InputStream getInIfOpen() throws IOException {
        // 得到输入流
        InputStream input = in;
        if (input == null)
            throw new IOException("Stream closed");
        return input;
    }
```



### getBufIfOpen
```java
    private byte[] getBufIfOpen() throws IOException {
        // 得到buf缓存区
        byte[] buffer = buf;
        if (buffer == null)
            throw new IOException("Stream closed");
        return buffer;
    }
```


### fill
```java
    private void fill() throws IOException {
        // 得到缓存区
        byte[] buffer = getBufIfOpen();
        if (markpos < 0) // 没有标记
            pos = 0;            /* no mark: throw away the buffer */
        else if (pos >= buffer.length)  /* no room left in buffer */
            if (markpos > 0) {  /* can throw away early part of the buffer */
                int sz = pos - markpos;
                // 把mark后sz个数组拷贝到0位置
                // 也就是0-sz的数据丢弃了
                System.arraycopy(buffer, markpos, buffer, 0, sz);
                pos = sz;
                markpos = 0;
            } else if (buffer.length >= marklimit) {
                markpos = -1;   /* buffer got too big, invalidate mark */
                pos = 0;        /* drop buffer contents */
            } else if (buffer.length >= MAX_BUFFER_SIZE) {
                throw new OutOfMemoryError("Required array size too large");
            } else {            /* grow buffer */
                int nsz = (pos <= MAX_BUFFER_SIZE - pos) ?
                        pos * 2 : MAX_BUFFER_SIZE;
                if (nsz > marklimit)
                    nsz = marklimit;
                // 使用新长度创建一个数组
                byte nbuf[] = new byte[nsz];
                // 把原数组的值拷贝到新数组中
                System.arraycopy(buffer, 0, nbuf, 0, pos);
                // 更新buf的引用,CAS原子更新
                if (!bufUpdater.compareAndSet(this, buffer, nbuf)) {
                    throw new IOException("Stream closed");
                }
                buffer = nbuf;
            }
        count = pos;
        // 把输入流的数据读取到buffer中
        int n = getInIfOpen().read(buffer, pos, buffer.length - pos);
        if (n > 0)
            count = n + pos;
    }
```


###  read
```java
    public synchronized int read() throws IOException {
        if (pos >= count) {
            fill();
            if (pos >= count)
                return -1;
        }
        // 获取pos对应位置的数据
        return getBufIfOpen()[pos++] & 0xff;
    }
```

### read array

```java
   private int read1(byte[] b, int off, int len) throws IOException {
        int avail = count - pos; // 获取buffer当前可用长度
        if (avail <= 0) {
			// 如果buffer不可用,则直接把输入流的数据读取到b中
            if (len >= getBufIfOpen().length && markpos < 0) {
                return getInIfOpen().read(b, off, len);
            }
            // 读取输入流的数据到buffer中
            fill();
            avail = count - pos;
            if (avail <= 0) return -1;
        }
        int cnt = (avail < len) ? avail : len;
       // 把buffer中的数据拷贝到b中
        System.arraycopy(getBufIfOpen(), pos, b, off, cnt);
        pos += cnt;
        return cnt;
    }
```

```java
    public synchronized int read(byte b[], int off, int len)
        throws IOException
    {
        getBufIfOpen(); // Check for closed stream
        if ((off | len | (off + len) | (b.length - (off + len))) < 0) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }

        int n = 0;
        for (;;) {
        	// 读取数据到数组b中
            int nread = read1(b, off + n, len - n);
            if (nread <= 0)
                return (n == 0) ? nread : n;
            n += nread;
            // 读取的数据长度够了,则直接返回
            if (n >= len)
                return n;
            // if not closed but no bytes available, return
            // 如果输入流没有数据了,则也直接返回
            InputStream input = in;
            if (input != null && input.available() <= 0)
                return n;
        }
    }
```



### skip

```java
    public synchronized long skip(long n) throws IOException {
        getBufIfOpen(); // Check for closed stream
        if (n <= 0) {
            return 0;
        }
        long avail = count - pos;
        if (avail <= 0) {
            // If no mark position set then don't keep in buffer
            // 如果没有标记,则直接让输入流跳过n
            if (markpos <0)
                return getInIfOpen().skip(n);
            // Fill in buffer to save bytes for reset
            fill();
            avail = count - pos;
            if (avail <= 0)
                return 0;
        }
		// 跳过的元素个数不能大于总过有效个数
        long skipped = (avail < n) ? avail : n;
        // 跳过skipped元素
        pos += skipped;
        return skipped;
    }

```


### available
```java
    public synchronized int available() throws IOException {
        int n = count - pos;
        int avail = getInIfOpen().available();
        // 获取可用参数的个数
        return n > (Integer.MAX_VALUE - avail)
                    ? Integer.MAX_VALUE
                    : n + avail;
    }
```


### mark
```java
    public synchronized void mark(int readlimit) {
        marklimit = readlimit;  // 读取的limit
        markpos = pos;		// mark的位置
    }

    public synchronized void reset() throws IOException {
        getBufIfOpen(); // Cause exception if closed
        if (markpos < 0)
            throw new IOException("Resetting to invalid mark");
        pos = markpos;  // 还原mark时的位置
    }
```
