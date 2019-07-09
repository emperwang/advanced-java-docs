# PrintWriter

## Field

```java
    // 输出流
	protected Writer out;
	// 自动刷新
    private final boolean autoFlush;
    private boolean trouble = false;
	// 格式化字符串
    private Formatter formatter;
    private PrintStream psOut = null;
	// 行分隔符
    private final String lineSeparator;
```



## 构造函数

```java
    // 都会调用到此构造函数
	public PrintWriter(Writer out,
                       boolean autoFlush) {
        super(out);
        this.out = out;
        this.autoFlush = autoFlush;
        lineSeparator = java.security.AccessController.doPrivileged(
            new sun.security.action.GetPropertyAction("line.separator"));
    }

    public PrintWriter (Writer out) {
        this(out, false);
    }

    public PrintWriter(OutputStream out) {
        this(out, false);
    }

    public PrintWriter(OutputStream out, boolean autoFlush) {
        // 把stream转换为writer
        this(new BufferedWriter(new OutputStreamWriter(out)), autoFlush);

        if (out instanceof java.io.PrintStream) {
            psOut = (PrintStream) out;
        }
    }

    public PrintWriter(String fileName) throws FileNotFoundException {
        // 把outputStream转换为writer
        this(new BufferedWriter(new OutputStreamWriter(new FileOutputStream(fileName))),
             false);
    }


    private PrintWriter(Charset charset, File file)
        throws FileNotFoundException
    {
        this(new BufferedWriter(new OutputStreamWriter(new FileOutputStream(file), charset)),
             false);
    }
```

## 功能函数

### ensureOpen

```java
    private void ensureOpen() throws IOException {
        if (out == null)
            throw new IOException("Stream closed");
    }
```

### write

#### write char

```java
    public void write(int c) {
        try {
            synchronized (lock) {
                ensureOpen();
                out.write(c); // 直接把字符写入到输出流中
            }
        }
        catch (InterruptedIOException x) {
            Thread.currentThread().interrupt();
        }
        catch (IOException x) {
            trouble = true;   // 发生异常，则更新标志位
        }
    }
```



#### write char Array

```java
    public void write(char buf[], int off, int len) {
        try {
            synchronized (lock) {
                ensureOpen();
                out.write(buf, off, len);  // 仍是直接把数据写入到输出流中
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



#### write String

```java
    public void write(String s, int off, int len) {
        try {
            synchronized (lock) {
                ensureOpen();
                out.write(s, off, len);  // 写入到输出流
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
            synchronized (lock) {
                ensureOpen();
                out.write(lineSeparator); // 写入一个行分隔符，标志一行的结束
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



### print 

```java
    public void print(String s) {
        if (s == null) {
            s = "null";
        }
        write(s);  // 这里的打印就很有意思了，就是调用write函数，把数据写入输出流中
    }

    public void print(char s[]) {
        write(s);
    }

    public void println() {
        newLine();   // 换行，输入一个行分隔符
    }
	
	// 打印数据并换行
    public void println(String x) {
        synchronized (lock) {
            print(x);      // 先输出数据
            println();	// 再打印一个行分隔符
        }
    }
```



### flush

```java
    public void flush() {
        try {
            synchronized (lock) {
                ensureOpen();
                out.flush();
            }
        }
        catch (IOException x) {
            trouble = true;
        }
    }
```

