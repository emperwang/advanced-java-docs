# FilterOutputStream

## Field

```java
    protected OutputStream out;
```



## 构造函数

```java
    public FilterOutputStream(OutputStream out) {
        this.out = out;
    }
```



## 功能函数

### write

```java
    public void write(int b) throws IOException {
        out.write(b);
    }

    public void write(byte b[]) throws IOException {
        write(b, 0, b.length);
    }

    public void write(byte b[], int off, int len) throws IOException {
        if ((off | len | (b.length - (len + off)) | (off + len)) < 0)
            throw new IndexOutOfBoundsException();

        for (int i = 0 ; i < len ; i++) {
            write(b[off + i]);
        }
    }
```



### flush

```java
    public void flush() throws IOException {
        out.flush();
    }
```

全部就是基于传递进来的输出流的实现，也没有什么特殊的地方，不清除此类是做什么用的。