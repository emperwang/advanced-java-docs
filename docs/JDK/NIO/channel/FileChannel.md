# FileChannel

## Field

```java
private static final FileAttribute<?>[] NO_ATTRIBUTES = new FileAttribute[0];
```



## 构造函数

```java
protected FileChannel() { }
```



## 功能函数

### open

打开文件

```java
public static FileChannel open(Path path,
                               Set<? extends OpenOption> options,
                               FileAttribute<?>... attrs)
    throws IOException
    {
        FileSystemProvider provider = path.getFileSystem().provider();
        return provider.newFileChannel(path, options, attrs);
    }

    public static FileChannel open(Path path, OpenOption... options)
        throws IOException
    {
        Set<OpenOption> set = new HashSet<OpenOption>(options.length);
        Collections.addAll(set, options);
        return open(path, set, NO_ATTRIBUTES);
    }
```

其他函数都是抽象方法，依赖于底层函数的实现.

## 内部类

### MapMode

#### Field

```java
/** Mode for a read-only mapping. */
public static final MapMode READ_ONLY
            = new MapMode("READ_ONLY");

/** Mode for a read/write mapping. */
public static final MapMode READ_WRITE
            = new MapMode("READ_WRITE");

/** Mode for a private (copy-on-write) mapping. */
public static final MapMode PRIVATE
            = new MapMode("PRIVATE");

private final String name;
```



#### 构造函数

```java
private MapMode(String name) {
    this.name = name;
}
```