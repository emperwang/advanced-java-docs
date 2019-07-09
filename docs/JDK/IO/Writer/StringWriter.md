# StringWriter

## Field

```java
    private StringBuffer buf;
```



## 构造函数

```java
    public StringWriter() {
        // 创建StringBuffer，并更新为锁
        buf = new StringBuffer();
        lock = buf;
    }

    public StringWriter(int initialSize) {
        if (initialSize < 0) {
            throw new IllegalArgumentException("Negative buffer size");
        }
        // 使用指定长度创建StringBuffer 并更新锁
        buf = new StringBuffer(initialSize);
        lock = buf;
    }
```



## 功能函数

### write

#### writer char

```java
    public void write(int c) {
        // 写入就是更新到buf中
        buf.append((char) c);
    }
```



#### write charArray

```java
    public void write(char cbuf[], int off, int len) {
        if ((off < 0) || (off > cbuf.length) || (len < 0) ||
            ((off + len) > cbuf.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return;
        }
        // 同样是更新到buf中
        buf.append(cbuf, off, len);
    }
```



#### write String

```java
   // 这里也是了。写入就是更新到buf中
	public void write(String str) {
        buf.append(str);
    }

    public void write(String str, int off, int len)  {
        buf.append(str.substring(off, off + len));
    }
```



### append

#### append CharSequence

```java
    // 在回忆一下CharSequence，嗯，或者看一下代码就好
	// 就一个封装了多个输入源的类实现
	public StringWriter append(CharSequence csq) {
        if (csq == null)
            write("null");
        else
            write(csq.toString()); // 把多个输入源的数据写入到buf中
        return this;
    }
```

#### append charSequence

```java
    public StringWriter append(CharSequence csq, int start, int end) {
        CharSequence cs = (csq == null ? "null" : csq);
        write(cs.subSequence(start, end).toString());
        return this;
    }
```

#### append char

```java
    public StringWriter append(char c) {
        write(c);
        return this;
    }
```



### flush

```java
    public void flush() {
    }
```

可以看到了，写入追加都是把数据写入到StringBuffer中。