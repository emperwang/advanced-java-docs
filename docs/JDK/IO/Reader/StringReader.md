# StringReader

## Field
```java
    private String str;  // 记录字符串
    private int length;	// 字符串长度
    private int next = 0;	// 下一个位置
    private int mark = 0;	// 标记的位置
```

## 构造函数

```java
    public StringReader(String s) {
        this.str = s;
        this.length = s.length();
    }
```



## 功能函数

### read
```java
    public int read() throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (next >= length)
                return -1;
            // 返回对应位置的字符
            return str.charAt(next++);
        }
    }
```

```java
    public int read(char cbuf[], int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if ((off < 0) || (off > cbuf.length) || (len < 0) ||
                ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return 0;
            }
            if (next >= length)
                return -1;
            int n = Math.min(length - next, len);
            // 获取子串
            str.getChars(next, next + n, cbuf, off);
            next += n;
            return n;
        }
    }
```



```java
    // 有效判断，字符串不为null就可以
	private void ensureOpen() throws IOException {
        if (str == null)
            throw new IOException("Stream closed");
    }
```

### skip

```java
    public long skip(long ns) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if (next >= length)
                return 0;
            // Bound skip by beginning and end of the source
            long n = Math.min(length - next, ns);
            n = Math.max(-next, n);
            next += n;  // 更新位置
            return n;
        }
    }
```


### ready
```java
    public boolean ready() throws IOException {
        synchronized (lock) {
        ensureOpen();
        return true;
        }
    }
```


### mark

```java
    public void mark(int readAheadLimit) throws IOException {
        if (readAheadLimit < 0){
            throw new IllegalArgumentException("Read-ahead limit < 0");
        }
        synchronized (lock) {
            ensureOpen();
            mark = next;   //标记和之前一样啦。记录下当前要读取的位置
        }
    }

    public void reset() throws IOException {
        synchronized (lock) {
            ensureOpen();
            next = mark;	// 还原标记的位置
        }
    }

```