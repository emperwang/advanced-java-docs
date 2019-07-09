# OutputStreamWriter

## Field

```java
    // 看到这个类熟悉吗？ InputStreamReader 也是由这样一个类进行转换的，把inputStream准换为Reader
	private final StreamEncoder se; 
```



## 构造函数

```java
    // 指定编码格式
	public OutputStreamWriter(OutputStream out, String charsetName)
        throws UnsupportedEncodingException
    {
        super(out);
        if (charsetName == null)
            throw new NullPointerException("charsetName");
        se = StreamEncoder.forOutputStreamWriter(out, this, charsetName);
    }
    // 指定输出流
    public OutputStreamWriter(OutputStream out) {
        super(out);
        try {
            se = StreamEncoder.forOutputStreamWriter(out, this, (String)null);
        } catch (UnsupportedEncodingException e) {
            throw new Error(e);
        }
    }

    public OutputStreamWriter(OutputStream out, Charset cs) {
        super(out);
        if (cs == null)
            throw new NullPointerException("charset");
        se = StreamEncoder.forOutputStreamWriter(out, this, cs);
    }

    public OutputStreamWriter(OutputStream out, CharsetEncoder enc) {
        super(out);
        if (enc == null)
            throw new NullPointerException("charset encoder");
        se = StreamEncoder.forOutputStreamWriter(out, this, enc);
    }
```



## 功能函数

### write

```java
    public void write(int c) throws IOException {
        se.write(c);
    }

    public void write(char cbuf[], int off, int len) throws IOException {
        se.write(cbuf, off, len);
    }

    public void write(String str, int off, int len) throws IOException {
        se.write(str, off, len);
    }
```



### flush

```java
    void flushBuffer() throws IOException {
        se.flushBuffer();
    }
```

具体实现函数，就都是依赖StreamEncoder来实现的。咱就不多说，直接看它长个什么样子。

## StreamEncoder

### Fied

```java
    // 缓冲区最大大小
	private static final int DEFAULT_BYTE_BUFFER_SIZE = 8192;
	// 是否打开
    private volatile boolean isOpen;
	// 编码格式
    private Charset cs;
    private CharsetEncoder encoder;
	// 缓存区
    private ByteBuffer bb;
	// 输出流
    private final OutputStream out;
	// channel
    private WritableByteChannel ch;
    private boolean haveLeftoverChar;
    private char leftoverChar;
	// 同样是缓存区
    private CharBuffer lcb;
```

### 构造函数

```java
    // 可以看到就是为各个field设置初始值
	private StreamEncoder(OutputStream var1, Object var2, CharsetEncoder var3) {
        super(var2);
        this.isOpen = true;
        this.haveLeftoverChar = false;
        this.lcb = null;
        this.out = var1;
        this.ch = null;
        this.cs = var3.charset();
        this.encoder = var3;
        if (this.ch == null) {
            this.bb = ByteBuffer.allocate(8192);
        }

    }

    private StreamEncoder(WritableByteChannel var1, CharsetEncoder var2, int var3) {
        this.isOpen = true;
        this.haveLeftoverChar = false;
        this.lcb = null;
        this.out = null;
        this.ch = var1;
        this.cs = var2.charset();
        this.encoder = var2;
        this.bb = ByteBuffer.allocate(var3 < 0 ? 8192 : var3);
    }
```



### 功能函数

#### flushBuffer

```java
    public void flushBuffer() throws IOException {
        Object var1 = this.lock;
        synchronized(this.lock) {
            if (this.isOpen()) {
                this.implFlushBuffer();  // flush-buffer
            } else {
                throw new IOException("Stream closed");
            }
        }
    }
```

#### write

##### writeBytes

```java
    private void writeBytes() throws IOException {
        // bb是一块缓存
        this.bb.flip();
        // 大小
        int var1 = this.bb.limit();
        // 写入的位置
        int var2 = this.bb.position();

        assert var2 <= var1;
		// 可用长度
        int var3 = var2 <= var1 ? var1 - var2 : 0;
        if (var3 > 0) {
            if (this.ch != null) {
                // 把bb内容写入到channel中
                assert this.ch.write(this.bb) == var3 : var3;
            } else {
                // 把bb中的数据，写入到输出流中
                this.out.write(this.bb.array(), this.bb.arrayOffset() + var2, var3);
            }
        }
		// 清空bb
        this.bb.clear();
    }
```

##### write char

```java
    public void write(int var1) throws IOException {
        // 转换为数组，然后再写入
        char[] var2 = new char[]{(char)var1};
        this.write((char[])var2, 0, 1);
    }
```

##### write char array

```java
    public void write(char[] var1, int var2, int var3) throws IOException {
        Object var4 = this.lock;
        synchronized(this.lock) {
            this.ensureOpen();
            if (var2 >= 0 && var2 <= var1.length && var3 >= 0 && var2 + var3 <= var1.length && var2 + var3 >= 0) {
                if (var3 != 0) {
                    // 具体的写函数
                    this.implWrite(var1, var2, var3);
                }
            } else {
                throw new IndexOutOfBoundsException();
            }
        }
    }
```



##### write string

```java
    public void write(String var1, int var2, int var3) throws IOException {
        if (var3 < 0) {
            throw new IndexOutOfBoundsException();
        } else {
            char[] var4 = new char[var3];
            var1.getChars(var2, var2 + var3, var4, 0);
            this.write((char[])var4, 0, var3);
        }
    }
```



##### implWrite

```java
    void implWrite(char[] var1, int var2, int var3) throws IOException {
        // 创建一个charBuffer包装一下次char数组 var1
        CharBuffer var4 = CharBuffer.wrap(var1, var2, var3);
        if (this.haveLeftoverChar) {
            this.flushLeftoverChar(var4, false);
        }
		// var4 数据
        while(var4.hasRemaining()) {
            CoderResult var5 = this.encoder.encode(var4, this.bb, false);
            if (var5.isUnderflow()) {
                assert var4.remaining() <= 1 : var4.remaining();

                if (var4.remaining() == 1) {
                    this.haveLeftoverChar = true;
                    this.leftoverChar = var4.get(); // 把最后一个元素写到leftoverChar
                }
                break;
            }

            if (var5.isOverflow()) {
                assert this.bb.position() > 0;
                this.writeBytes(); // 把bb的数据写入到out流或channel中
            } else {
                var5.throwException();
            }
        }

    }
```

##### fushLeftoverChar

```java
    private void flushLeftoverChar(CharBuffer var1, boolean var2) throws IOException {
        if (this.haveLeftoverChar || var2) {
            // 使用lcb缓存区
            if (this.lcb == null) {
                // 如果没有初始化，就先初始化一下
                this.lcb = CharBuffer.allocate(2);
            } else {
                this.lcb.clear();
            }
			// 把leftoverChar添加到lcb，如果存在的话
            if (this.haveLeftoverChar) {
                this.lcb.put(this.leftoverChar);
            }
			// 从var1中拿数据添加到lcb中
            if (var1 != null && var1.hasRemaining()) {
                this.lcb.put(var1.get());
            }

            this.lcb.flip();
            while(this.lcb.hasRemaining() || var2) {
                // 把lcb数据写入bb
                CoderResult var3 = this.encoder.encode(this.lcb, this.bb, var2);
                if (var3.isUnderflow()) {
                    if (this.lcb.hasRemaining()) {
                        this.leftoverChar = this.lcb.get();
                        // 这里再次调用自己
                       // 也就是使用递归把var1中的数据都写入到bb中
                        if (var1 != null && var1.hasRemaining()) {
                            this.flushLeftoverChar(var1, var2);
                        }

                        return;
                    }
                    break;
                }

                if (var3.isOverflow()) {
                    assert this.bb.position() > 0;
                    this.writeBytes(); // 把bb的数据写入到out流或channel中
                } else {
                    var3.throwException();
                }
            }

            this.haveLeftoverChar = false;
        }
    }
```



##### implFlushBuffer

```java
    void implFlushBuffer() throws IOException {
        if (this.bb.position() > 0) {
            this.writeBytes();  // 清空buffer，就是把bb中的数据写入到out流或channel中
        }

    }
```



##### implFlush

```java
    void implFlush() throws IOException {
        this.implFlushBuffer();
        if (this.out != null) {
            this.out.flush();  // 流清空
        }
    }
```



##### implClose

```java
    void implClose() throws IOException {
        this.flushLeftoverChar((CharBuffer)null, true);
        try {
            while(true) {
                // 把bb中的数据清空
                CoderResult var1 = this.encoder.flush(this.bb);
                if (var1.isUnderflow()) {
                    if (this.bb.position() > 0) {
                        // 把bb中的数据写入到流或channel中
                        this.writeBytes();
                    }

                    if (this.ch != null) {
                        this.ch.close();
                    } else {
                        this.out.close();
                    }

                    return;
                }
                if (var1.isOverflow()) {
                    assert this.bb.position() > 0;
                    this.writeBytes();  // 再写入
                } else {
                    var1.throwException();
                }
            }
        } catch (IOException var2) {
            this.encoder.reset();
            throw var2;
        }
    }
```

这就大概有个思路了，这里使用了Buffer和channel对liu进行了包装。此类就先分析到这，下次咱们再分析这些包装类的作用，看它是如何实现转变的。