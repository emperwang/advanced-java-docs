# ByteArrayInputStream

## Field

```java
    protected byte buf[];
	// 记录读取的位置
    protected int pos;
	// mark的位置
    protected int mark = 0;
	// 可读取的buf的元素数
    protected int count;
```

## 构造函数

```java
    public ByteArrayInputStream(byte buf[]) {
        this.buf = buf;
        this.pos = 0;
        this.count = buf.length;
    }

    public ByteArrayInputStream(byte buf[], int offset, int length) {
        this.buf = buf;
        this.pos = offset;
        this.count = Math.min(offset + length, buf.length);
        this.mark = offset;
    }
```

## 功能函数

### 读取

```java
    public synchronized int read() {
        // 直接读取pos位置的元素
        // 如果已经超过了可读元素总数,直接返回-1
        return (pos < count) ? (buf[pos++] & 0xff) : -1;
    }

    public synchronized int read(byte b[], int off, int len) {
        if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        }

        if (pos >= count) {
            return -1;
        }
		// 确定可读取的数量
        int avail = count - pos;
        if (len > avail) {
            len = avail;
        }
        // 没有可读取的,则直接返回0
        if (len <= 0) {
            return 0;
        }
        // 把buf中的数据拷贝到数组b中
        System.arraycopy(buf, pos, b, off, len);
        pos += len;
        return len;
    }
```

读取数需要加锁的。

### skip

```java
    public synchronized long skip(long n) {
        long k = count - pos;
        if (n < k) {
            k = n < 0 ? 0 : n;
        }
		// 跳过,则直接跳转pos的位置
        pos += k;
        return k;
    }
```



### mark

```java
    public void mark(int readAheadLimit) {
        mark = pos;  // 记录当前的位置
    }

    public synchronized void reset() {
        pos = mark;   // 还原记录的位置
    }
```

### available

```java
    public synchronized int available() {
        return count - pos;   // 返回可用的元素的数量
  }
```

