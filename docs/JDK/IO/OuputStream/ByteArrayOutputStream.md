# ByteArrayOutputStream

## Field

```java
    // 存储
	protected byte buf[];
	// buf数组中有效元素的个数
    protected int count;
	// buf最大长度
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```



## 构造函数

```java
    public ByteArrayOutputStream(int size) {
        if (size < 0) {
            throw new IllegalArgumentException("Negative initial size: "
                                               + size);
        }
        // 使用指定大小创建数组
        buf = new byte[size];
    }
	// 默认创建长度为32
    public ByteArrayOutputStream() {
        this(32);
    }
```



## 功能函数

### write

```java
    public synchronized void write(int b) {
        // 保证容器大小
        ensureCapacity(count + 1);
        // 存入数组
        buf[count] = (byte) b;
        // 数量加1
        count += 1;
    }
```

```java
    public synchronized void write(byte b[], int off, int len) {
        if ((off < 0) || (off > b.length) || (len < 0) ||
            ((off + len) - b.length > 0)) {
            throw new IndexOutOfBoundsException();
        }
        // 保证容器大小
        ensureCapacity(count + len);
        // 复制数组b到buf中
        System.arraycopy(b, off, buf, count, len);
        // 增加count大小
        count += len;
    }
```

扩容：

```java
    private void ensureCapacity(int minCapacity) {
        // 如果超出buf的长度
        if (minCapacity - buf.length > 0)
            // 进行扩容
            grow(minCapacity);
    }
	// 具体的扩容函数
    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = buf.length;
        // 可见容量每次是增加一倍
        int newCapacity = oldCapacity << 1;
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // 使用新大小创建数组，并把原来数组中的数据拷贝到新数组中
        buf = Arrays.copyOf(buf, newCapacity);
    }
	// 保证不要超过最大长度
    private static int hugeCapacity(int minCapacity) {
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
    }
```

主要函数就这几个了，底层存储仍是数组，其他操作仍是基于数组进行。