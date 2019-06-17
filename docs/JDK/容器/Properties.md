# Properties

此类是HashTable的子类；

## Field

```java
    /**
     * A property list that contains default values for any keys not
     * found in this property list.
     */
    protected Properties defaults;

    /** A table of hex digits */
    private static final char[] hexDigit = {
        '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
    };
```

## 构造函数

```java
    public Properties() {
        this(null);
    }
    public Properties(Properties defaults) {
        this.defaults = defaults;
    }
```

## 加载数据

### Reader

```java
    public synchronized void load(Reader reader) throws IOException {
        load0(new LineReader(reader));
    }

    private void load0 (LineReader lr) throws IOException {
        char[] convtBuf = new char[1024];
        int limit;
        int keyLen;
        int valueStart;
        char c;
        boolean hasSep;  // 是否有分隔符，= 或 ：
        boolean precedingBackslash;

        while ((limit = lr.readLine()) >= 0) { // limit为读取的处理后的有效数据个数
            c = 0;
            keyLen = 0;
            valueStart = limit;
            hasSep = false;

            //System.out.println("line=<" + new String(lineBuf, 0, limit) + ">");
            precedingBackslash = false;
            while (keyLen < limit) {
                c = lr.lineBuf[keyLen];
                //need check if escaped.
                if ((c == '=' ||  c == ':') && !precedingBackslash) {
                    valueStart = keyLen + 1;
                    hasSep = true;
                    break;
                 // 字符是空格或 \t 或 \f 表示处理完了
                } else if ((c == ' ' || c == '\t' ||  c == '\f') && !precedingBackslash) {
                    valueStart = keyLen + 1;
                    break;
                }
                // 这种字符，则表示处理转义字符
                if (c == '\\') {
                    precedingBackslash = !precedingBackslash;
                } else {
                    precedingBackslash = false;
                }
                keyLen++;
            }
            while (valueStart < limit) { // 查看valueStart中是否换有分隔符
                c = lr.lineBuf[valueStart];
                if (c != ' ' && c != '\t' &&  c != '\f') {
                    if (!hasSep && (c == '=' ||  c == ':')) {
                        hasSep = true;
                    } else {
                        break;
                    }
                }
                valueStart++;
            }
            // 得到key值
            String key = loadConvert(lr.lineBuf, 0, keyLen, convtBuf);
            // 得到value值
            String value = loadConvert(lr.lineBuf, valueStart, limit - valueStart, convtBuf);
            // 此操作是把key-value放入到table(HashTable存储数据的数组)中
            put(key, value);
        }
    }
	// 把char转换为字符串
	// in: 存储的数据
	// off: 有效数据的偏移位置
	// len: 有效数据的长度
	// convtBuf:输出的缓存
    private String loadConvert (char[] in, int off, int len, char[] convtBuf) {
        // 缓存小,则扩容
        if (convtBuf.length < len) {
            int newLen = len * 2;
            if (newLen < 0) {
                newLen = Integer.MAX_VALUE;
            }
            convtBuf = new char[newLen];
        }
        char aChar;
        char[] out = convtBuf; // 输入的缓存
        int outLen = 0;
        int end = off + len;  // 结束位置

        while (off < end) {
            aChar = in[off++];
            // 处理此种数据  \\uxxxx
            if (aChar == '\\') {
                aChar = in[off++];
                if(aChar == 'u') {
                    // Read the xxxx
                    int value=0;
                    for (int i=0; i<4; i++) {
                        aChar = in[off++];
                        switch (aChar) {
                          case '0': case '1': case '2': case '3': case '4':
                          case '5': case '6': case '7': case '8': case '9':
                             value = (value << 4) + aChar - '0';
                             break;
                          case 'a': case 'b': case 'c':
                          case 'd': case 'e': case 'f':
                             value = (value << 4) + 10 + aChar - 'a';
                             break;
                          case 'A': case 'B': case 'C':
                          case 'D': case 'E': case 'F':
                             value = (value << 4) + 10 + aChar - 'A';
                             break;
                          default:
                              throw new IllegalArgumentException(
                                           "Malformed \\uxxxx encoding.");
                        }
                     }
                    out[outLen++] = (char)value;
                } else {
                    if (aChar == 't') aChar = '\t';
                    else if (aChar == 'r') aChar = '\r';
                    else if (aChar == 'n') aChar = '\n';
                    else if (aChar == 'f') aChar = '\f';
                    out[outLen++] = aChar;
                }
            } else {
                out[outLen++] = aChar;
            }
        }
        // 转换为字符串
        return new String (out, 0, outLen);
    }
```

看一下此内部类有何功能:

```java
    class LineReader {
        public LineReader(InputStream inStream) {
            this.inStream = inStream; // 初始化数据源
            inByteBuf = new byte[8192]; // 初始化缓存数组
        }

        public LineReader(Reader reader) {
            this.reader = reader;  // 初始化数据源
            inCharBuf = new char[8192];  // 初始化缓存数组
        }
		// 缓存数组
        byte[] inByteBuf;
        char[] inCharBuf;
        char[] lineBuf = new char[1024];
        int inLimit = 0; // 读取了多少数据
        int inOff = 0;	// 处理的数组在缓存中的位置
        // 数据源
        InputStream inStream;
        Reader reader;

        int readLine() throws IOException {
            int len = 0; // 记录leneBuf中的有效数据个数
            char c = 0; // 从缓存中读取的要处理的数据
            boolean skipWhiteSpace = true; // 跳过空格
            boolean isCommentLine = false; // 是否是注释行
            boolean isNewLine = true;  // 是否是新行
            boolean appendedLineBegin = false; // 
            boolean precedingBackslash = false; // 处理反斜线
            boolean skipLF = false; // 跳过LF

            while (true) {
                if (inOff >= inLimit) {
                    inLimit = (inStream==null)?reader.read(inCharBuf)
                                              :inStream.read(inByteBuf);
                    inOff = 0;
                    if (inLimit <= 0) {
                        if (len == 0 || isCommentLine) {
                            return -1;
                        }
                        if (precedingBackslash) {
                            len--;
                        }
                        return len;
                    }
                }
                // 从缓存中读取数据
                if (inStream != null) {
                    c = (char) (0xff & inByteBuf[inOff++]);
                } else {
                    c = inCharBuf[inOff++];
                }
                // 是否跳过换行
                if (skipLF) {
                    skipLF = false;
                    if (c == '\n') {
                        continue;
                    }
                }
                // 是否跳过空白字符
                if (skipWhiteSpace) {
                    if (c == ' ' || c == '\t' || c == '\f') {
                        continue;
                    }
                    if (!appendedLineBegin && (c == '\r' || c == '\n')) {
                        continue;
                    }
                    skipWhiteSpace = false;
                    appendedLineBegin = false;
                }
                if (isNewLine) {
                    isNewLine = false;
                    // 如果是#开头或！开头，表示注释行
                    if (c == '#' || c == '!') {
                        isCommentLine = true;
                        continue;
                    }
                }
				// 是正常数据
                if (c != '\n' && c != '\r') {
                    // 放到LineBuf
                    lineBuf[len++] = c;
                    // 如果达到最大值，则扩容
                    if (len == lineBuf.length) {
                        int newLength = lineBuf.length * 2;
                        if (newLength < 0) {
                            newLength = Integer.MAX_VALUE;
                        }
                        // 并把原来的数据拷贝到新的数组中
                        char[] buf = new char[newLength];
                        System.arraycopy(lineBuf, 0, buf, 0, lineBuf.length);
                        lineBuf = buf;
                    }
                    //flip the preceding backslash flag
                    if (c == '\\') {
                        precedingBackslash = !precedingBackslash;
                    } else {
                        precedingBackslash = false;
                    }
                }
                else {
                    // 得到尾部或者是注释行，则跳过
                    if (isCommentLine || len == 0) {
                        isCommentLine = false;
                        isNewLine = true;
                        skipWhiteSpace = true;
                        len = 0;
                        continue;
                    }
                    // 处理完了，则再次读取
                    if (inOff >= inLimit) {
                        inLimit = (inStream==null)
                                  ?reader.read(inCharBuf)
                                  :inStream.read(inByteBuf);
                        inOff = 0;
                        if (inLimit <= 0) {
                            if (precedingBackslash) {
                                len--;
                            }
                            return len;
                        }
                    }
                    if (precedingBackslash) {
                        len -= 1;
                        //skip the leading whitespace characters in following line
                        skipWhiteSpace = true;
                        appendedLineBegin = true;
                        precedingBackslash = false;
                        if (c == '\r') {
                            skipLF = true;
                        }
                    } else {
                        return len;
                    }
                }
            }
        }
    }
```

### InputStream

```java
    // 可以看到此种处理,和上面是差不多的,就是数据源为 InputStream操作
	public synchronized void load(InputStream inStream) throws IOException {
        load0(new LineReader(inStream));
    }

    private void load0 (LineReader lr) throws IOException {
        char[] convtBuf = new char[1024];
        int limit;
        int keyLen;
        int valueStart;
        char c;
        boolean hasSep;
        boolean precedingBackslash;

        while ((limit = lr.readLine()) >= 0) {
            c = 0;
            keyLen = 0;
            valueStart = limit;
            hasSep = false;

            //System.out.println("line=<" + new String(lineBuf, 0, limit) + ">");
            precedingBackslash = false;
            while (keyLen < limit) {
                c = lr.lineBuf[keyLen];
                //need check if escaped.
                if ((c == '=' ||  c == ':') && !precedingBackslash) {
                    valueStart = keyLen + 1;
                    hasSep = true;
                    break;
                } else if ((c == ' ' || c == '\t' ||  c == '\f') && !precedingBackslash) {
                    valueStart = keyLen + 1;
                    break;
                }
                if (c == '\\') {
                    precedingBackslash = !precedingBackslash;
                } else {
                    precedingBackslash = false;
                }
                keyLen++;
            }
            while (valueStart < limit) {
                c = lr.lineBuf[valueStart];
                if (c != ' ' && c != '\t' &&  c != '\f') {
                    if (!hasSep && (c == '=' ||  c == ':')) {
                        hasSep = true;
                    } else {
                        break;
                    }
                }
                valueStart++;
            }
            String key = loadConvert(lr.lineBuf, 0, keyLen, convtBuf);
            String value = loadConvert(lr.lineBuf, valueStart, limit - valueStart, convtBuf);
            put(key, value);
        }
    }
```

可以看到此种处理,和上面是差不多的,就是数据源为 InputStream操作。不多说，接着往下看.

## 获取数据

使用的是HashTable中获取方法。

```java
    public String getProperty(String key) {
        // 看这里，使用父类的get方法，即使用的是HashTable方法
        Object oval = super.get(key);
        String sval = (oval instanceof String) ? (String)oval : null;
        return ((sval == null) && (defaults != null)) ? defaults.getProperty(key) : sval;
    }
    public String getProperty(String key, String defaultValue) {
        String val = getProperty(key);
        return (val == null) ? defaultValue : val;
    }

```



## 从xml中加载数据

```java
    public synchronized void loadFromXML(InputStream in)
        throws IOException, InvalidPropertiesFormatException
    {
        XmlSupport.load(this, Objects.requireNonNull(in));
        in.close();
    }
```

看一下这个xml的内部类实现把:

```java
    private static class XmlSupport {
        private static final XmlPropertiesProvider PROVIDER = loadProvider();
        
        private static XmlPropertiesProvider loadProviderFromProperty(ClassLoader cl) {
            String cn = System.getProperty("sun.util.spi.XmlPropertiesProvider");
            if (cn == null)
                return null;
            try {
                Class<?> c = Class.forName(cn, true, cl);
                return (XmlPropertiesProvider)c.newInstance();
            } catch (ClassNotFoundException |
                     IllegalAccessException |
                     InstantiationException x) {
                throw new ServiceConfigurationError(null, x);
            }
        }

        private static XmlPropertiesProvider loadProviderAsService(ClassLoader cl) {
            // 使用SPI机制来加载实现类
            // 具体的实现，可以查看XmlPropertiesProvider的两个实现类，查看其load具体的工作
            Iterator<XmlPropertiesProvider> iterator =
                 ServiceLoader.load(XmlPropertiesProvider.class, cl).iterator();
            return iterator.hasNext() ? iterator.next() : null;
        }

        private static XmlPropertiesProvider loadProvider() {
            return AccessController.doPrivileged(
                new PrivilegedAction<XmlPropertiesProvider>() {
                    public XmlPropertiesProvider run() {
                        ClassLoader cl = ClassLoader.getSystemClassLoader();
                        XmlPropertiesProvider provider = loadProviderFromProperty(cl);
                        if (provider != null)
                            return provider;
                        provider = loadProviderAsService(cl);
                        if (provider != null)
                            return provider;
                        return new jdk.internal.util.xml.BasicXmlPropertiesProvider();
                }});
        }

        static void load(Properties props, InputStream in)
            throws IOException, InvalidPropertiesFormatException
        {
            PROVIDER.load(props, in);
        }

        static void save(Properties props, OutputStream os, String comment,
                         String encoding)
            throws IOException
        {
            PROVIDER.store(props, os, comment, encoding);
        }
    }
```

