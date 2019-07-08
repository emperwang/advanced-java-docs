# FilterReader

## Field

```java
    protected Reader in;
```



## 构造函数
```java
    protected FilterReader(Reader in) {
        super(in);
        this.in = in;
    }
```


## 功能函数

### read
```java
    public int read() throws IOException {
        return in.read();
    }

    public int read(char cbuf[], int off, int len) throws IOException {
        return in.read(cbuf, off, len);
    }
```


### skip
```java
    public long skip(long n) throws IOException {
        return in.skip(n);
    }
```


### ready
```java
    public boolean ready() throws IOException {
        return in.ready();
    }
```


### mark
```java
    public void mark(int readAheadLimit) throws IOException {
        in.mark(readAheadLimit);
    }

    public void reset() throws IOException {
        in.reset();
    }
```

全部都是调用传递进来的Reader，也没有其他特殊的操作。