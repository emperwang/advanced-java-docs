# InputStream

## Field

```java
    private static final int MAX_SKIP_BUFFER_SIZE = 2048;
```

## 功能方法

### 读取

```java
   // 供子函数实现的读取方法 
   public abstract int read() throws IOException;
	// 读取到数组中
    public int read(byte b[]) throws IOException {
        return read(b, 0, b.length);
    }

    public int read(byte b[], int off, int len) throws IOException {
        if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }
		// 读取内容
        int c = read();
        if (c == -1) {
            return -1;
        }
        // 把内容转换为byte类型
        b[off] = (byte)c;

        int i = 1;
        try {
            // 循环读取,并写到数组中
            for (; i < len ; i++) {
                c = read();
                if (c == -1) {
                    break;
                }
                b[off + i] = (byte)c;
            }
        } catch (IOException ee) {
        }
        return i;
    }
```

## skip

```java
    public long skip(long n) throws IOException {
        long remaining = n;
        int nr;
        if (n <= 0) {
            return 0;
        }
        int size = (int)Math.min(MAX_SKIP_BUFFER_SIZE, remaining);
        // 保存跳过的byte
        byte[] skipBuffer = new byte[size];
        while (remaining > 0) {
            nr = read(skipBuffer, 0, (int)Math.min(size, remaining));
            if (nr < 0) {
                break;
            }
            remaining -= nr;
        }
        // 返回真实跳过了多少byte
        return n - remaining;
    }
```

```java
    // 有效字符数
	public int available() throws IOException {
        return 0;
    }
```

```java
    // 关闭
	public void close() throws IOException {}
```

```java
    // 记录
	public synchronized void mark(int readlimit) {}

    // 复位
	public synchronized void reset() throws IOException {
        throw new IOException("mark/reset not supported");
    }
	// 是否支持mark
    public boolean markSupported() {
        return false;
    }
```



