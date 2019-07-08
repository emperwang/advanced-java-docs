# InputStreamReader

## Field

```java
    private final StreamDecoder sd;
```



## 构造函数

```java
    public InputStreamReader(InputStream in) {
        super(in);
        try {
            sd = StreamDecoder.forInputStreamReader(in, this, (String)null); // ## check lock object
        } catch (UnsupportedEncodingException e) {
            // The default encoding should always be available
            throw new Error(e);
        }
    }

    public InputStreamReader(InputStream in, String charsetName)
        throws UnsupportedEncodingException
    {
        super(in);
        if (charsetName == null)
            throw new NullPointerException("charsetName");
        sd = StreamDecoder.forInputStreamReader(in, this, charsetName);
    }
    
    public InputStreamReader(InputStream in, Charset cs) {
        super(in);
        if (cs == null)
            throw new NullPointerException("charset");
        sd = StreamDecoder.forInputStreamReader(in, this, cs);
    }

    public InputStreamReader(InputStream in, CharsetDecoder dec) {
        super(in);
        if (dec == null)
            throw new NullPointerException("charset decoder");
        sd = StreamDecoder.forInputStreamReader(in, this, dec);
    }
```



## 功能函数

### read

```java
    public int read() throws IOException {
        return sd.read();
    }

    public int read(char cbuf[], int offset, int length) throws IOException {
        return sd.read(cbuf, offset, length);
    }
```



### ready

```java
    public boolean ready() throws IOException {
        return sd.ready();
    }
```



### close

```java

    public void close() throws IOException {
        sd.close();
    }
```

可以看到具体的实现函数都是StreamDecoder来操作的，废话不多说，来看一下这个类的实现。

## StringDecoder

### Field

```java
    // buffer最小大小
	private static final int MIN_BYTE_BUFFER_SIZE = 32;
	// buffer最大大小
    private static final int DEFAULT_BYTE_BUFFER_SIZE = 8192;
	// 文件是否打开
    private volatile boolean isOpen;
    private boolean haveLeftoverChar;
    private char leftoverChar;
    private static volatile boolean channelsAvailable = true;
	// 编码格式
    private Charset cs;
	// 解码
    private CharsetDecoder decoder;
	// 缓冲区
    private ByteBuffer bb;
	// 输入流
    private InputStream in;
    private ReadableByteChannel ch;
```

### 构造函数

```java
    StreamDecoder(InputStream var1, Object var2, CharsetDecoder var3) {
        super(var2);
        this.isOpen = true;
        this.haveLeftoverChar = false;
        this.cs = var3.charset();
        this.decoder = var3;
        if (this.ch == null) {
            this.in = var1;
            this.ch = null;
            this.bb = ByteBuffer.allocate(8192);
        }

        this.bb.flip();
    }

    StreamDecoder(ReadableByteChannel var1, CharsetDecoder var2, int var3) {
        this.isOpen = true;
        this.haveLeftoverChar = false;
        this.in = null;
        this.ch = var1;
        this.decoder = var2;
        this.cs = var2.charset();
        this.bb = ByteBuffer.allocate(var3 < 0 ? 8192 : (var3 < 32 ? 32 : var3));
        this.bb.flip();
    }
```

```java
    private void ensureOpen() throws IOException {
        if (!this.isOpen) {
            throw new IOException("Stream closed");
        }
    }
```

再来看一下静态实例化方法：

```java
    // var0是输入流
	// var1 是lock锁
	// var2 是编码格式
	public static StreamDecoder forInputStreamReader(InputStream var0, Object var1, String var2) throws UnsupportedEncodingException {
        String var3 = var2;
        if (var2 == null) {
            var3 = Charset.defaultCharset().name();
        }

        try {
            if (Charset.isSupported(var3)) {
                return new StreamDecoder(var0, var1, Charset.forName(var3));
            }
        } catch (IllegalCharsetNameException var5) {
            ;
        }

        throw new UnsupportedEncodingException(var3);
    }
```

### 功能函数

#### read

```java
    public int read() throws IOException {
        return this.read0();
    }
	
    private int read0() throws IOException {
        Object var1 = this.lock;
        // 读取操作上锁
        synchronized(this.lock) {
            if (this.haveLeftoverChar) { // 读取一个元素
                this.haveLeftoverChar = false;
                return this.leftoverChar;
            } else {
                char[] var2 = new char[2]; // 创建一个存放数据的数组
                int var3 = this.read(var2, 0, 2); // 读取数据
                switch(var3) {
                case -1: // 读取的个数为0
                    return -1;
                case 0:  // 读取0个元素
                default:
                    assert false : var3;
                    return -1;
                case 2: // 读取两个元素；则把第一个元素放到leftoverChar
                    this.leftoverChar = var2[1];
                    this.haveLeftoverChar = true;
                case 1: // 读取一个元素  ；直接返回
                    return var2[0];
                }
            }
        }
    }
```

```java
    // var1	存储读取的数据
	// var2 offset，偏移位置
	// var3 读取多少个数据
	public int read(char[] var1, int var2, int var3) throws IOException {
        int var4 = var2;
        int var5 = var3;
        Object var6 = this.lock;
        synchronized(this.lock) {
            this.ensureOpen();
            if (var4 >= 0 && var4 <= var1.length && var5 >= 0 && var4 + var5 <= var1.length && var4 + var5 >= 0) {
                if (var5 == 0) {
                    return 0;
                } else {
                    byte var7 = 0;
                    if (this.haveLeftoverChar) {
                        // 读取一个元素，放到数组中，并且偏移加1
                        // 数量减1
                        var1[var4] = this.leftoverChar;
                        ++var4;
                        --var5;
                        this.haveLeftoverChar = false;
                        var7 = 1;
                        if (var5 == 0 || !this.implReady()) {
                            return var7;
                        }
                    }

                    if (var5 == 1) {
                        // 读取一个元素
                        int var8 = this.read0();
                        if (var8 == -1) {
                            return var7 == 0 ? -1 : var7;
                        } else {
                            // 存入到数组中
                            var1[var4] = (char)var8;
                            return var7 + 1;
                        }
                    } else {
                        // 如果var5不为1，则继续读取
                        return var7 + this.implRead(var1, var4, var4 + var5);
                    }
                }
            } else {
                throw new IndexOutOfBoundsException();
            }
        }
    }
```



#### ready

```java
    public boolean ready() throws IOException {
        Object var1 = this.lock;
        synchronized(this.lock) {
            this.ensureOpen();
            return this.haveLeftoverChar || this.implReady();
        }
    }
```

#### implReady

```java
    boolean implReady() {
        // 缓存还有数据，或者输入流可用
        return this.bb.hasRemaining() || this.inReady();
    }
```

#### inReady

```java
    private boolean inReady() {
        try {
            // 输入流不为null  或 输入流还有数据  或 是FileChannel
            // 则输入已经准备好
            return this.in != null && this.in.available() > 0 || this.ch instanceof FileChannel;
        } catch (IOException var2) {
            return false;
        }
    }
```

#### implRead

```java
    // var1 存储数据的数组
	// var2 offset
	// var3  读取的个数
	int implRead(char[] var1, int var2, int var3) throws IOException {
        assert var3 - var2 > 1;
        // var4 对var1数组进行了包装
        CharBuffer var4 = CharBuffer.wrap(var1, var2, var3 - var2);
        if (var4.position() != 0) {
            var4 = var4.slice();
        }
        boolean var5 = false;
        while(true) {
            CoderResult var6 = this.decoder.decode(this.bb, var4, var5);
            if (var6.isUnderflow()) {
                if (var5 || !var4.hasRemaining() || var4.position() > 0 && !this.inReady()) {
                    break;
                }
				// 从输入流或channel中读取数据到bb中
                // var7 是buffer中有效数据的个数
                int var7 = this.readBytes();
                if (var7 < 0) {
                    var5 = true;
                    if (var4.position() == 0 && !this.bb.hasRemaining()) {
                        break;
                    }

                    this.decoder.reset();
                }
            } else {
                if (var6.isOverflow()) {
                    assert var4.position() > 0;
                    break;
                }

                var6.throwException();
            }
        }

        if (var5) {
            this.decoder.reset();
        }

        if (var4.position() == 0) {
            if (var5) {
                return -1;
            }

            assert false;
        }
		
        return var4.position();
    }
```

#### readBytes

```java
    private int readBytes() throws IOException {
        this.bb.compact();
        int var1;
        try {
            int var2;
            if (this.ch != null) {
               	// 从channel中读取数据到bb中
                var1 = this.ch.read(this.bb);
                if (var1 < 0) {
                    var2 = var1;
                    return var2;
                }
            } else {
                var1 = this.bb.limit();
                var2 = this.bb.position();

                assert var2 <= var1;

                int var3 = var2 <= var1 ? var1 - var2 : 0;

                assert var3 > 0;
				// 从输入流读取数据到bb中
                int var4 = this.in.read(this.bb.array(), this.bb.arrayOffset() + var2, var3);
                if (var4 < 0) {
                    int var5 = var4;
                    return var5;
                }

                if (var4 == 0) {
                    throw new IOException("Underlying input stream returned zero bytes");
                }

                assert var4 <= var3 : "n = " + var4 + ", rem = " + var3;

                this.bb.position(var2 + var4);
            }
        } finally {
            this.bb.flip();
        }
		// buffer中数据个数
        var1 = this.bb.remaining();

        assert var1 != 0 : var1;

        return var1;
    }
```









