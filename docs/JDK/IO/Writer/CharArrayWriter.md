# CharArrayWriter

## Field

```java
    // 数据存储的地方
	protected char buf[];

    /**
     * The number of chars in the buffer.
     */
    protected int count;
```



## 构造函数

```java
    public CharArrayWriter() {
        // 由此可见默认大小是32
        this(32);
    }
	
    public CharArrayWriter(int initialSize) {
        if (initialSize < 0) {
            throw new IllegalArgumentException("Negative initial size: "
                                               + initialSize);
        }
        // 初始化数组
        buf = new char[initialSize];
    }
```



## 功能函数

### write

#### write

```java
    public void write(int c) {
        synchronized (lock) {
            int newcount = count + 1;
            if (newcount > buf.length) {
                // 拷贝到一个新数组中
                // 并把buf指向新数组
                buf = Arrays.copyOf(buf, Math.max(buf.length << 1, newcount));
            }
            // 把值存入数组中
            buf[count] = (char)c;
            count = newcount;
        }
    }
```



#### write Char Array

```java
    public void write(char c[], int off, int len) {
        if ((off < 0) || (off > c.length) || (len < 0) ||
            ((off + len) > c.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return;
        }
        synchronized (lock) {
            int newcount = count + len;
            if (newcount > buf.length) {
                // 同样是拷贝新数组
                buf = Arrays.copyOf(buf, Math.max(buf.length << 1, newcount));
            }
            // 把c中的值写入到数组中
            System.arraycopy(c, off, buf, count, len);
            count = newcount;
        }
    }
```



#### write String

```java
    public void write(String str, int off, int len) {
        synchronized (lock) {
            int newcount = count + len;
            if (newcount > buf.length) {
                // 创建新数组
                buf = Arrays.copyOf(buf, Math.max(buf.length << 1, newcount));
            }
            // 把string的值，从off开始，拷贝len个长度到数组中
            str.getChars(off, off + len, buf, count);
            count = newcount;
        }
    }
	
	// 这是String中的方法
    public void getChars(int srcBegin, int srcEnd, char dst[], int dstBegin) {
        if (srcBegin < 0) {
            throw new StringIndexOutOfBoundsException(srcBegin);
        }
        if (srcEnd > value.length) {
            throw new StringIndexOutOfBoundsException(srcEnd);
        }
        if (srcBegin > srcEnd) {
            throw new StringIndexOutOfBoundsException(srcEnd - srcBegin);
        }
        // 从这里可以看到，同样是把String中值拷贝到dst中
        System.arraycopy(value, srcBegin, dst, dstBegin, srcEnd - srcBegin);
    }
```



#### write to

```java
    public void writeTo(Writer out) throws IOException {
        synchronized (lock) {
            out.write(buf, 0, count);
        }
    }
```



### append

#### append charSequence

```java
    // 还击的charSequence把，就是封装了多个输入源而已
	public CharArrayWriter append(CharSequence csq) {
        String s = (csq == null ? "null" : csq.toString());
        // 也就是把多个输入源中中的数据写入到数组中
        write(s, 0, s.length());
        return this;
    }
```



#### append charSequence

```java
    // 同样也是，得到多个输入源的一段数据，然后写入
	public CharArrayWriter append(CharSequence csq, int start, int end) {
        // 获取数据
        String s = (csq == null ? "null" : csq).subSequence(start, end).toString();
        // 写入操作
        write(s, 0, s.length());
        return this;
    }
```



#### append char

```java
    public CharArrayWriter append(char c) {
        // 写入一个字符
        write(c);
        return this;
    }
```



### flush

```java
    public void flush() { }
```

