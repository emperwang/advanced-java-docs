# Reader

## Field
```java
    // skipBuffer最大长度
	private static final int maxSkipBufferSize = 8192;

    /** Skip buffer, null until allocated */
    private char skipBuffer[] = null;
    protected Object lock;
```


## 构造函数
```java
    protected Reader() {
        this.lock = this;
    }

    protected Reader(Object lock) {
        if (lock == null) {
            throw new NullPointerException();
        }
        this.lock = lock;
    }
```


## 功能函数

### read
```java
    public int read(java.nio.CharBuffer target) throws IOException {
        int len = target.remaining();
        char[] cbuf = new char[len];
        int n = read(cbuf, 0, len);
        if (n > 0)
            target.put(cbuf, 0, n);
        return n;
    }

   public int read(char cbuf[]) throws IOException {
        return read(cbuf, 0, cbuf.length);
    }

    abstract public int read(char cbuf[], int off, int len) throws IOException;
```


### skip
```java
    public long skip(long n) throws IOException {
        if (n < 0L)
            throw new IllegalArgumentException("skip value is negative");
        // 不要超过最大长度
        int nn = (int) Math.min(n, maxSkipBufferSize);
        synchronized (lock) {
            if ((skipBuffer == null) || (skipBuffer.length < nn))
                skipBuffer = new char[nn];
            long r = n;
            while (r > 0) {
                int nc = read(skipBuffer, 0, (int)Math.min(r, nn));
                if (nc == -1)
                    break;
                r -= nc;
            }
            return n - r;
        }
    }
```


### mark

```java
    public void mark(int readAheadLimit) throws IOException {
        throw new IOException("mark() not supported");
    }

    public void reset() throws IOException {
        throw new IOException("reset() not supported");
    }
```

看一下就了解了，此抽象函数，大多功能需要子类去进行实现。
