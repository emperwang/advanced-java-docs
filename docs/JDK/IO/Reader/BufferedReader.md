# BufferedReader

## Field

```java
 	// 输入源
	private Reader in;
	// 存储数组
    private char cb[];
	// nChars表示cb元素数量
	// nextChar表示下次要读取的元素位置
    private int nChars, nextChar;
	// 两个标志flag
    private static final int INVALIDATED = -2;
    private static final int UNMARKED = -1;
	// 标记char
    private int markedChar = UNMARKED;
    private int readAheadLimit = 0; /* Valid only when markedChar > 0 */

    /** If the next character is a line feed, skip it */
    private boolean skipLF = false;

    // 当mark时 记录skipLF的值
    private boolean markedSkipLF = false;
	// 默认charbuf长度
    private static int defaultCharBufferSize = 8192;
	// 每行长度
    private static int defaultExpectedLineLength = 80;
```



## 构造函数

```java
    public BufferedReader(Reader in, int sz) {
        super(in);
        if (sz <= 0)
            throw new IllegalArgumentException("Buffer size <= 0");
        this.in = in;
        // 初始化数组
        cb = new char[sz];
        nextChar = nChars = 0;
    }
	// 设置输入源
    public BufferedReader(Reader in) {
        this(in, defaultCharBufferSize);
    }
```

## 功能函数

### read

```java
    public int read() throws IOException {
        synchronized (lock) {
            ensureOpen(); // 保证输入源不为null
            for (;;) {
                if (nextChar >= nChars) {
                    fill(); // 从输入源中读取数据到cb数组
                    if (nextChar >= nChars) // 说明没有数据
                        return -1;
                }
                // 如果跳过line feed
                if (skipLF) {
                    skipLF = false;
                    // 跳过此元素，读取下一个
                    if (cb[nextChar] == '\n') {
                        nextChar++;
                        continue;
                    }
                }
                // 返回nextChar位置上的数据
                return cb[nextChar++];
            }
        }
    }
```

### fill

```java
    // 填写cb(Field)缓存
	private void fill() throws IOException {
        int dst;
        if (markedChar <= UNMARKED) { // 没有标记
            /* No mark */
            dst = 0;
        } else { // 标记的情况
            /* Marked */
            int delta = nextChar - markedChar;
            // 如果要读取的数据位置和标记时的位置距离大于readAheadLimit，则把标记取出
            if (delta >= readAheadLimit) {
                /* Gone past read-ahead limit: Invalidate mark */
                markedChar = INVALIDATED;
                readAheadLimit = 0;
                dst = 0;
            } else { 
  // 说明要读取位置和标记位置据小于如果要读取的数据位置和标记时的位置距离大于readAheadLimit
                // 小于总长度
                if (readAheadLimit <= cb.length) {
                    /* Shuffle in the current buffer */
                    // 则把标记位置后的数据拷贝到0-delta
                    System.arraycopy(cb, markedChar, cb, 0, delta);
                    markedChar = 0;  // 标记从0开始
                    dst = delta;
                } else { // 大于总长度
                    /* Reallocate buffer to accommodate read-ahead limit */
                    // 则使用此长度创建新数组
                    char ncb[] = new char[readAheadLimit];
                    // 把原来数组中markedChar后delta个数据，拷贝到ncb的0位置后
                    System.arraycopy(cb, markedChar, ncb, 0, delta);
                    // 把数组的索引更新
                    cb = ncb;
                    markedChar = 0;
                    dst = delta;
                }
                // 更新位置
                nextChar = nChars = delta;
            }
        }

        int n;
        do {
            // 从输入流中读取数据到cb数组
            n = in.read(cb, dst, cb.length - dst);
        } while (n == 0);
        // 更新标记
        if (n > 0) {
            // cChars表示元素数量
            nChars = dst + n;
            // 表示下一个元素的位置
            nextChar = dst;
        }
    }
```



```java
    private int read1(char[] cbuf, int off, int len) throws IOException {
        if (nextChar >= nChars) { // 本地数组没有数据
            // 需要的长度大于cb的长度，并且没有标记，且不关系line feed
            if (len >= cb.length && markedChar <= UNMARKED && !skipLF) {
                // 直接从输入源中获取数据
                return in.read(cbuf, off, len);
            }
            // 填充数据到本地
            fill();
        }
        // 本地还是没有数据
        if (nextChar >= nChars) return -1;
        if (skipLF) { // 跳过line feed
            skipLF = false;
            // 则读取下一个元素
            if (cb[nextChar] == '\n') {
                nextChar++;
                // 再次填充本地数组
                if (nextChar >= nChars)
                    fill();
                if (nextChar >= nChars)
                    return -1;
            }
        }
        int n = Math.min(len, nChars - nextChar);
        // 从本地数组拷贝n个数据到cbuf的off位置后
        System.arraycopy(cb, nextChar, cbuf, off, n);
        nextChar += n;
        return n;
    }
```

```java
    public int read(char cbuf[], int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen(); // 保证有输入源
            // 安全性检查
            if ((off < 0) || (off > cbuf.length) || (len < 0) ||
                ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return 0;
            }
			// 读取数据
            int n = read1(cbuf, off, len);
            if (n <= 0) return n;
            while ((n < len) && in.ready()) {
                // 没有读取够长度，就继续读取
                int n1 = read1(cbuf, off + n, len - n);
                if (n1 <= 0) break;
                n += n1;
            }
            return n;
        }
    }
```

```java
    private void ensureOpen() throws IOException {
        if (in == null)  // 保证输入源不为null
            throw new IOException("Stream closed");
    }
```



### readLine

```java
    String readLine(boolean ignoreLF) throws IOException {
        StringBuffer s = null;
        int startChar;
        synchronized (lock) {
            ensureOpen();
            boolean omitLF = ignoreLF || skipLF;
        bufferLoop:
            for (;;) {
                // 没有数据则进行填充
                if (nextChar >= nChars)
                    fill();
                if (nextChar >= nChars) { /* EOF */
                    if (s != null && s.length() > 0)
                        return s.toString();
                    else
                        return null;
                }
                boolean eol = false;
                char c = 0;
                int i;
                /* Skip a leftover '\n', if necessary */
                // 跳过 \n
                if (omitLF && (cb[nextChar] == '\n'))
                    nextChar++;
                skipLF = false;
                omitLF = false;

            charLoop: // 读取一行数据
                for (i = nextChar; i < nChars; i++) {
                    c = cb[i];
                    if ((c == '\n') || (c == '\r')) {
                        eol = true;
                        break charLoop;
                    }
                }
				// startChar此行的开始
                startChar = nextChar;
                // i是下一行的开始
                nextChar = i;

                if (eol) {
                    String str;
                    if (s == null) {
                        // 一行数据转换为string
                        str = new String(cb, startChar, i - startChar);
                    } else {
                        // 追加到s后面
                        s.append(cb, startChar, i - startChar);
                        str = s.toString();
                    }
                    nextChar++;
                    if (c == '\r') {
                        skipLF = true;
                    }
                    return str; // 返回读取的一行数据
                }

                if (s == null)
                    // 使用默认一行长度创建 StringBuffer
                    s = new StringBuffer(defaultExpectedLineLength);
                s.append(cb, startChar, i - startChar);
            }
        }
    }
```
```java
    public String readLine() throws IOException {
        return readLine(false);
    }
```

### skip

```java
    public long skip(long n) throws IOException {
        if (n < 0L) {
            throw new IllegalArgumentException("skip value is negative");
        }
        synchronized (lock) {
            ensureOpen();  // 确保有数据源
            long r = n;
            while (r > 0) {
                // 为空，填充数据
                if (nextChar >= nChars)
                    fill();
                if (nextChar >= nChars) /* EOF */
                    break;
                // 跳过line feed
                if (skipLF) {
                    skipLF = false;
                    if (cb[nextChar] == '\n') {
                        nextChar++;
                    }
                }
                // d为有效元素个数
                long d = nChars - nextChar;
                // 如果有效个数大于等于要跳过的数据
                // 则直接跳过r个数据，并把r置为0
                if (r <= d) {
                    nextChar += r;
                    r = 0;
                    break;
                }
                // 如果有效个数不够要跳过的数据
                // 则直接全部跳过
                else {
                    r -= d;
                    nextChar = nChars;
                }
            }
            // 返回没有跳过的数据的个数
            return n - r;
        }
    }
```
### ready

```java
    public boolean ready() throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (skipLF) {
                // 如果数据为空，则填充数组
                if (nextChar >= nChars && in.ready()) {
                    fill();
                }
                // 跳过line feed
                if (nextChar < nChars) {
                    if (cb[nextChar] == '\n')
                        nextChar++;
                    skipLF = false;
                }
            }
            return (nextChar < nChars) || in.ready();
        }
    }
```

### mark

```java
    public void mark(int readAheadLimit) throws IOException {
        if (readAheadLimit < 0) {
            throw new IllegalArgumentException("Read-ahead limit < 0");
        }
        synchronized (lock) {
            ensureOpen();
            // 标记一个位置
            this.readAheadLimit = readAheadLimit;
            // 标记此时的位置
            markedChar = nextChar;
            // 记录是否跳过line feed
            markedSkipLF = skipLF;
        }
    }

    public void reset() throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (markedChar < 0)
                throw new IOException((markedChar == INVALIDATED)
                                      ? "Mark invalid"
                                      : "Stream not marked");
            // 还原到标记的位置上
            nextChar = markedChar;
            skipLF = markedSkipLF;
        }
    }
```

主要功能函数都在上面了。注释还是比较清楚的。