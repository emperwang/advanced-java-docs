# PrintStream

## Field
```java
    // writer 字符流
	private BufferedWriter textOut;
	// 字节流转字符流
    private OutputStreamWriter charOut;
	// 自动刷新
    private final boolean autoFlush;
	// 是否出错
    private boolean trouble = false;
	// 格式化函数
    private Formatter formatter;
	// 关闭标志
    private boolean closing = false; 
```


## 构造函数
```java
    // 没有指定编码时的构造器
	private PrintStream(boolean autoFlush, OutputStream out) {
        super(out);
        this.autoFlush = autoFlush;
        // 把一个输出流转换为字节流
        this.charOut = new OutputStreamWriter(this);
        this.textOut = new BufferedWriter(charOut);
    }
	// 指定编码时的构造器
    private PrintStream(boolean autoFlush, OutputStream out, Charset charset) {
        super(out);
        this.autoFlush = autoFlush;
        // 把一个字节流转换为字符流
        this.charOut = new OutputStreamWriter(this, charset);
        this.textOut = new BufferedWriter(charOut);
    }


    private PrintStream(boolean autoFlush, Charset charset, OutputStream out)
        throws UnsupportedEncodingException
    {
        this(autoFlush, out, charset);
    }
    
    public PrintStream(OutputStream out) {
        this(out, false);
    }

    public PrintStream(OutputStream out, boolean autoFlush) {
        this(autoFlush, requireNonNull(out, "Null output stream"));
    }


    public PrintStream(OutputStream out, boolean autoFlush, String encoding)
        throws UnsupportedEncodingException
    {
        this(autoFlush,
             requireNonNull(out, "Null output stream"),
             toCharset(encoding));
    }
    
	// 输出到文件中
    public PrintStream(String fileName) throws FileNotFoundException {
        this(false, new FileOutputStream(fileName));
    }

	// 输出到文件中
    public PrintStream(String fileName, String csn)
        throws FileNotFoundException, UnsupportedEncodingException
    {
        // ensure charset is checked before the file is opened
        this(false, toCharset(csn), new FileOutputStream(fileName));
    }
    // 输出到文件中
    public PrintStream(File file) throws FileNotFoundException {
        this(false, new FileOutputStream(file));
    }


    public PrintStream(File file, String csn)
        throws FileNotFoundException, UnsupportedEncodingException
    {
        // ensure charset is checked before the file is opened
        this(false, toCharset(csn), new FileOutputStream(file));
    }
```


## 功能函数

### requireNonNull
```java
    // 如果obj为null,则报错message错误
	private static <T> T requireNonNull(T obj, String message) {
        if (obj == null)
            throw new NullPointerException(message);
        return obj;
    }
```
### ensureOpen
```java
    private void ensureOpen() throws IOException {
        if (out == null)
            throw new IOException("Stream closed");
    }
```


### flush
```java
    public void flush() {
        synchronized (this) {
            try {
                ensureOpen();
                // 输出流刷新
                out.flush();
            }
            catch (IOException x) {
                trouble = true;  // 出错就设置标志
            }
        }
    }
```


### checkError
```java
    public boolean checkError() {
        if (out != null)
            flush();
        if (out instanceof java.io.PrintStream) {
            PrintStream ps = (PrintStream) out;
            return ps.checkError();
        }
        return trouble;  // 返回是否出错标志
    }
```


### clearError
```java
    protected void clearError() {
        trouble = false;  // 清楚错误,就是把标志清楚;;简单
    }

```


### write
#### write int
```java
    public void write(int b) {
        try {
            synchronized (this) {
                ensureOpen();
                // 输出流写函数
                out.write(b);
                // 如果是一行,且自动刷新,则进行刷新操作
                if ((b == '\n') && autoFlush)
                    out.flush();
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;
        }
    }
```
#### write byte array
```java
   public void write(byte buf[], int off, int len) {
        try {
            synchronized (this) {
                ensureOpen();
                // 输出流的写函数实现
                out.write(buf, off, len);
                if (autoFlush)
                    out.flush();
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;
        }
    }
```
#### write char array
```java
    private void write(char buf[]) {
        try {
            synchronized (this) {
                ensureOpen();
                // 这里的textOut是输出流转换为字符流
                // 也就是这里会把字节转换为字符写入
                textOut.write(buf);
                textOut.flushBuffer();
                charOut.flushBuffer();
                if (autoFlush) {
                    for (int i = 0; i < buf.length; i++)
                        if (buf[i] == '\n')
                            out.flush();
                }
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;
        }
    }

```
#### write string
```java
   private void write(String s) {
        try {
            synchronized (this) {
                ensureOpen();
                // 字符流操作
                textOut.write(s);
                textOut.flushBuffer();
                charOut.flushBuffer();
                if (autoFlush && (s.indexOf('\n') >= 0))
                    out.flush();
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;
        }
    }
```


### newLine
```java
    private void newLine() {
        try {
            synchronized (this) {
                ensureOpen();
                // nweLine就是写入一个换行符啦
                textOut.newLine();
                textOut.flushBuffer();
                charOut.flushBuffer();
                if (autoFlush)
                    out.flush();
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;
        }
    }
```
### print  boolean
```java
    public void print(boolean b) {
        write(b ? "true" : "false");
    }
```


### print char
```java
    public void print(char c) {
        write(String.valueOf(c));
    }
```


### print int
```java
    public void print(int i) {
        write(String.valueOf(i));
    }
```
### print long
```java
    public void print(long l) {
        write(String.valueOf(l));
    }
```


### print double
```java
    public void print(double d) {
        write(String.valueOf(d));
    }
```
嗯,这里可以稍微总结一下，print函数就是相等于给write函数起了一个别名。

### println 

```java
    // 就是写入一个换行符
	public void println() {
        newLine();
    }
```


### println boolean
```java
    public void println(boolean x) {
        synchronized (this) {
            print(x);
            newLine();
        }
    }
```


### println char
```java
    public void println(char x) {
        synchronized (this) {
            print(x);
            newLine();
        }
    }
```


### println long
```java
   public void println(long x) {
        synchronized (this) {
            print(x);
            newLine();
        }
    }
```


### println string
```java
    public void println(String x) {
        synchronized (this) {
            print(x);
            newLine();
        }
    }
```

这里也很清晰了，调用一个print写数据，也就是调用对应的write，再写入一个换行符。。

### format

```java
    public PrintStream format(String format, Object ... args) {
        try {
            synchronized (this) {
                ensureOpen();
                if ((formatter == null)
                    || (formatter.locale() != Locale.getDefault()))
                    formatter = new Formatter((Appendable) this);
                // 就格式了一下,然后返回当前实例.
                formatter.format(Locale.getDefault(), format, args);
            }
        } catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        } catch (IOException x) {
            trouble = true;
        }
        return this;
    }



    public PrintStream format(Locale l, String format, Object ... args) {
        try {
            synchronized (this) {
                ensureOpen();
                if ((formatter == null)
                    || (formatter.locale() != l))
                    formatter = new Formatter(this, l);
                formatter.format(l, format, args);
            }
        } catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        } catch (IOException x) {
            trouble = true;
        }
        return this;
    }
```

