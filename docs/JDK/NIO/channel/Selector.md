# Selector

## 构造器

```java
protected Selector() {
    }
```



## 功能函数

```java
public static Selector open() throws IOException {
    return SelectorProvider.provider().openSelector();
}

public abstract boolean isOpen();

public abstract SelectorProvider provider();

public abstract Set<SelectionKey> keys();

public abstract Set<SelectionKey> selectedKeys();

public abstract int selectNow() throws IOException;

public abstract int select(long var1) throws IOException;

public abstract int select() throws IOException;

public abstract Selector wakeup();

public abstract void close() throws IOException;
```

