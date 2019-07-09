# BufferedOutputStream

## Field
```java
    // 存储数据的buf
	protected byte buf[];
	// 有效元素个数
    protected int count;
```

## 构造函数
```java
    public BufferedOutputStream(OutputStream out) {
        this(out, 8192); // 可以看到默认buf大小是8192
    }

    public BufferedOutputStream(OutputStream out, int size) {
        super(out);  // 记录输出流
        if (size <= 0) {
            throw new IllegalArgumentException("Buffer size <= 0");
        }
        // 创建数组
        buf = new byte[size];
    }
```


## 功能函数

### write
```java
    public synchronized void write(int b) throws IOException {
        if (count >= buf.length) {
            flushBuffer();
        }
        // 写入到数据对应位置
        buf[count++] = (byte)b;
    }

    public synchronized void write(byte b[], int off, int len) throws IOException {
        if (len >= buf.length) {
			// 把buf中数据写入输出流
            flushBuffer();
            // 直接把b中数据写入到输出流中
            out.write(b, off, len);
            return;
        }
        if (len > buf.length - count) {
            flushBuffer();
        }
        // 把b中数据拷贝到buf中
        System.arraycopy(b, off, buf, count, len);
        count += len;
    }
```


### flushBuffer
```java
    private void flushBuffer() throws IOException {
        if (count > 0) {
            // 把buf中的数据写入到输出流中
            out.write(buf, 0, count);
            count = 0;
        }
    }
```


### flush

```java
    public synchronized void flush() throws IOException {
        // 把buf中的数据写入到输出流中
        flushBuffer();
        // 流flush
        out.flush();
    }
```



