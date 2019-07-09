# LineNumberInputStream

在JDK1.8中此类已经被舍弃，不过不耽误分析一下其实现。

## Field
```java
    int pushBack = -1;   // 是否换行
    int lineNumber;   // 行号
    int markLineNumber; // 标记时的lineNumber的值
    int markPushBack = -1; // 标记时的pushBack的值
```


## 构造函数
```java
    public LineNumberInputStream(InputStream in) {
        super(in);  // 记录输入流
    }
```


## 功能函数

### read
```java
    public int read() throws IOException {
        int c = pushBack;
        if (c != -1) {
            pushBack = -1;
        } else {
            c = in.read(); // 从流中读取数据
        }
        switch (c) {
          case '\r':
            pushBack = in.read();
            if (pushBack == '\n') {
                pushBack = -1;
            }
          case '\n':  // 是换行,则行号增加
            lineNumber++;
            return '\n';
        }
        return c;
    }
```
read array:

```java
    public int read(byte b[], int off, int len) throws IOException {
        if (b == null) {
            throw new NullPointerException();
        } else if ((off < 0) || (off > b.length) || (len < 0) ||
                   ((off + len) > b.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }

        int c = read();
        if (c == -1) {
            return -1;
        }
        // 数据存放到b中
        b[off] = (byte)c;
        int i = 1;
        try {// 连续读数据,放入到数组b中
            for (; i < len ; i++) {
                c = read();
                if (c == -1) {
                    break;
                }
                if (b != null) {
                    b[off + i] = (byte)c;
                }
            }
        } catch (IOException ee) {
        }
        return i;
    }
```



### skip

```java
    public long skip(long n) throws IOException {
        int chunk = 2048;
        long remaining = n;
        byte data[];
        int nr;
        if (n <= 0) {
            return 0;
        }
        // 存放要跳过的数据
        data = new byte[chunk];
        while (remaining > 0) {
            // 从流中读取数据到data中
            nr = read(data, 0, (int) Math.min(chunk, remaining));
            if (nr < 0) {
                break;
            }
            remaining -= nr;
        }

        return n - remaining;
    }
```


### skipLineNumber
```java
    public void setLineNumber(int lineNumber) {
        this.lineNumber = lineNumber;
    }
```


### getLineNumber
```java
    public int getLineNumber() {
        return lineNumber;
    }
```
### available
```java
    public int available() throws IOException {
        return (pushBack == -1) ? super.available()/2 : super.available()/2 + 1;
    }
```


### mark

```java
    public void mark(int readlimit) {
        // 记录此时的标记
        markLineNumber = lineNumber;
        markPushBack   = pushBack;
        in.mark(readlimit);
    }


    public void reset() throws IOException {
        // 还原记录时的标记
        lineNumber = markLineNumber;
        pushBack   = markPushBack;
        in.reset();
    }
```