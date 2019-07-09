# BufferedWriter

## Field

```java
    // 输出类
	private Writer out;
	// 缓冲区
    private char cb[];
	// nChars表示元素个数
	// nextChar 下一个元素位置
    private int nChars, nextChar;
	// 缓冲区默认大小
    private static int defaultCharBufferSize = 8192;
	// 分隔符
    private String lineSeparator;
```

## 构造函数

```java
    public BufferedWriter(Writer out) {
        this(out, defaultCharBufferSize);
    }

    public BufferedWriter(Writer out, int sz) {
        super(out);
        if (sz <= 0)
            throw new IllegalArgumentException("Buffer size <= 0");
        // 保存out
        this.out = out;
        // 创建缓存区
        cb = new char[sz];
        // 更新nChars 和 nextChar
        nChars = sz;
        nextChar = 0;
		// 获取属性值
        lineSeparator = java.security.AccessController.doPrivileged(
            new sun.security.action.GetPropertyAction("line.separator"));
    }
```

## 功能函数

### write

```java
    public void write(int c) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (nextChar >= nChars) // 如果没有多余空间，则把缓冲区中数据先写入到out流中
                flushBuffer();
            // 数据写入到缓存区中
            cb[nextChar++] = (char) c;
        }
    }

```

writer char Array：

```java
    public void write(char cbuf[], int off, int len) throws IOException {
        synchronized (lock) {
            // 安全性检查
            ensureOpen();
            if ((off < 0) || (off > cbuf.length) || (len < 0) ||
                ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return;
            }

            if (len >= nChars) { // 如果要写入的数据大于缓存区长度
                /* If the request length exceeds the size of the output buffer,
                   flush the buffer and then write the data directly.  In this
                   way buffered streams will cascade harmlessly. */
                // 把缓存区情况
                flushBuffer();
                // 直接写入到out流中
                out.write(cbuf, off, len);
                return;
            }

            int b = off, t = off + len;
            while (b < t) {
                int d = min(nChars - nextChar, t - b);
                // 把cbuf中的数据拷贝到  cb中
                System.arraycopy(cbuf, b, cb, nextChar, d);
                b += d;
                nextChar += d;
                if (nextChar >= nChars)
                    // 清空缓存区
                    flushBuffer();
            }
        }
    }
```



write String：

```java
    public void write(String s, int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen();
            int b = off, t = off + len;
            while (b < t) {
                int d = min(nChars - nextChar, t - b);
                // 先写入数组
                s.getChars(b, b + d, cb, nextChar);
                b += d;
                nextChar += d;
                if (nextChar >= nChars)
                    // 如果大于缓存区长度，则清空缓存
                    flushBuffer();
            }
        }
    }
```



安全检查

```java
    private void ensureOpen() throws IOException {
        if (out == null)
            throw new IOException("Stream closed");
    }
```



### newLine

```java
    public void newLine() throws IOException {
        // 写入行分隔符，表明这是一行数据结束
        write(lineSeparator);
    }
```



### flushBuffer

```java
    void flushBuffer() throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (nextChar == 0)
                return;
            // 把缓存区中的数据全部写入out流中
            out.write(cb, 0, nextChar);
            nextChar = 0;
        }
    }
```





