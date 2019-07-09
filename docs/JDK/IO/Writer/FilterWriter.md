# FilterWriter

## Field

```java
    protected Writer out;
```



## 构造函数

```java
    protected FilterWriter(Writer out) {
        super(out);
        this.out = out;
    }
```



## 功能函数

### write

#### write

```java
    public void write(int c) throws IOException {
        out.write(c);
    }
```



#### write char Array

```java
    public void write(char cbuf[], int off, int len) throws IOException {
        out.write(cbuf, off, len);
    }

```



#### write String

```java
    public void write(String str, int off, int len) throws IOException {
        out.write(str, off, len);
    }
```



### flush

```java
    public void flush() throws IOException {
        out.flush();
    }
```

全部都是传递进来的out流的函数，一点修饰都没有。。不知此种类的用处是什么？