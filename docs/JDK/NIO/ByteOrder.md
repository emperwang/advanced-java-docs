# ByteOrder

看一下javaDoc解释：

```java
A typesafe enumeration for byte orders.
```

## Field

```java
private String name;

public static final ByteOrder BIG_ENDIAN
        = new ByteOrder("BIG_ENDIAN");

public static final ByteOrder LITTLE_ENDIAN
        = new ByteOrder("LITTLE_ENDIAN");
```



## 构造器

```java
private ByteOrder(String name) {
        this.name = name;
    }
```



## 功能函数

```java
// etrieves the native byte order of the underlying platform.
public static ByteOrder nativeOrder() {
    return Bits.byteOrder();
}

// 看一下这个Bits.byteOrder函数:

private static final ByteOrder byteOrder;

static ByteOrder byteOrder() {
    if (byteOrder == null)
        throw new Error("Unknown byte order");
    return byteOrder;
}


// 静态代码块,确定本机内存存储方式是大头还是小头
static {
    long a = unsafe.allocateMemory(8);
    try {
        unsafe.putLong(a, 0x0102030405060708L);
        byte b = unsafe.getByte(a);
        switch (b) {
            case 0x01: byteOrder = ByteOrder.BIG_ENDIAN;     break;
            case 0x08: byteOrder = ByteOrder.LITTLE_ENDIAN;  break;
            default:
                assert false;
                byteOrder = null;
        }
    } finally {
        unsafe.freeMemory(a);
    }
}
```

