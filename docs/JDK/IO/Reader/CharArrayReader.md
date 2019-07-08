# CharArrayReader

## Field

```java
    // 存储数据
    protected char buf[];
    // 当前读取的位置
    protected int pos;   
	// 标记的位置
    protected int markedPos = 0;
	// 有效元素个数
    protected int count;
```



## 构造函数
```java
    // 使用指定char数组进行初始化
	public CharArrayReader(char buf[]) {
        this.buf = buf;
        this.pos = 0;
        this.count = buf.length;
    }

    public CharArrayReader(char buf[], int offset, int length) {
        if ((offset < 0) || (offset > buf.length) || (length < 0) ||
            ((offset + length) < 0)) {
            throw new IllegalArgumentException();
        }
        // 更新对应的标志
        this.buf = buf;
        this.pos = offset;
        this.count = Math.min(offset + length, buf.length);
        this.markedPos = offset;
    }
```


## 功能函数

### read
```java
    public int read() throws IOException {
        synchronized (lock) {
            ensureOpen(); // 保证数组不为bull
            if (pos >= count)
                return -1;
            else
                // 返回pos位置的数据
                return buf[pos++];
        }
    }
```

```java
    public int read(char b[], int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if ((off < 0) || (off > b.length) || (len < 0) ||
                ((off + len) > b.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return 0;
            }
            // 没有数据
            if (pos >= count) {
                return -1;
            }
			// 可用数据
            int avail = count - pos;
            if (len > avail) {
                len = avail;
            }
            if (len <= 0) {
                return 0;
            }
            // 拷贝数据
            System.arraycopy(buf, pos, b, off, len);
            pos += len;
            // 返回拷贝的数据个数
            return len;
        }
    }
```

### skip

```java
    public long skip(long n) throws IOException {
        synchronized (lock) {
            ensureOpen();
            long avail = count - pos;
            if (n > avail) {
                n = avail;
            }
            if (n < 0) {
                return 0;
            }
            // 更新pos位置
            pos += n;
            return n;
        }
    }
```

### ready

```java
    public boolean ready() throws IOException {
        synchronized (lock) {
            ensureOpen();
            return (count - pos) > 0;  // 有效数据大于0
        }
    }
```



### mark

```java
    public void mark(int readAheadLimit) throws IOException {
        synchronized (lock) {
            ensureOpen();
            markedPos = pos;  // 记录当前的置为
        }
    }

    public void reset() throws IOException {
        synchronized (lock) {
            ensureOpen();
            pos = markedPos; // 还原记录的位置
        }
    }
```

此函数就是对数据的一个操作，很简单啦。。。