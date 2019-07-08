# SequenceInputStream

## Field

```java
    // 存储多个输入源
	Enumeration<? extends InputStream> e;
	// 要读取的输入源
    InputStream in;
```



## 构造函数

```java
    public SequenceInputStream(Enumeration<? extends InputStream> e) {
        // 记录输入源集合
        this.e = e;
        try {
            // 获取一个输入源
            nextStream();
        } catch (IOException ex) {
            // This should never happen
            throw new Error("panic");
        }
    }
	
	// 指定两个输入源
    public SequenceInputStream(InputStream s1, InputStream s2) {
        Vector<InputStream> v = new Vector<>(2);
        v.addElement(s1);
        v.addElement(s2);
        e = v.elements();
        try {
            nextStream();
        } catch (IOException ex) {
            // This should never happen
            throw new Error("panic");
        }
    }
```



## 功能函数

### available

```java
    public int available() throws IOException {
        if (in == null) {
            return 0; // no way to signal EOF from available()
        }
        return in.available();
    }
```



### read

```java
    public int read() throws IOException {
        // 从in输入源中读取
        while (in != null) {
            int c = in.read();
            if (c != -1) {
                return c;
            }
            // 获取下一个输入源
            nextStream();
        }
        return -1;
    }

    public int read(byte b[], int off, int len) throws IOException {
        if (in == null) {
            return -1;
        } else if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }
        do {
            int n = in.read(b, off, len);
            if (n > 0) {
                return n;
            }
            nextStream();
        } while (in != null);
        return -1;
    }
```



### nextStream

```java
    final void nextStream() throws IOException {
        if (in != null) {
            in.close();
        }
		// 获取下一个输入源
        if (e.hasMoreElements()) {
            in = (InputStream) e.nextElement();
            if (in == null)
                throw new NullPointerException();
        }
        else in = null;

    }
```

很明了，就是保存多个输入源，读取时可以连续从多个输入源一块读取数据。