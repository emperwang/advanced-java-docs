# FilterInputStream

## Field

```java
	// 要进行过滤的流    
	protected volatile InputStream in;
```



## 构造函数

```java
    protected FilterInputStream(InputStream in) {
        this.in = in;
    }
```



## 功能函数

### read

```java
    public int read() throws IOException {
        return in.read();
    }

    public int read(byte b[]) throws IOException {
        return read(b, 0, b.length);
    }

    public int read(byte b[], int off, int len) throws IOException {
        return in.read(b, off, len);
    }
```



### available

```java
    public int available() throws IOException {
        return in.available();
    }
```



### skip

```java
    public long skip(long n) throws IOException {
        return in.skip(n);
    }
```



### mark

```java
   public synchronized void mark(int readlimit) {
        in.mark(readlimit);
    }

    public synchronized void reset() throws IOException {
        in.reset();
    }
```

全部都是依赖于要过滤的流实现的. 那就不多说了.