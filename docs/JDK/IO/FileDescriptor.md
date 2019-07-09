# FileDescriptor

## Field

```java
    private int fd = -1;
    private long handle = -1L;
    private Closeable parent;
    private List<Closeable> otherParents;
    private boolean closed;
	// 标准输入输出错误输出描述符记录
    public static final FileDescriptor in;
    public static final FileDescriptor out;
    public static final FileDescriptor err;
```

静态初始化代码:

```java
static {
        initIDs();
        SharedSecrets.setJavaIOFileDescriptorAccess(new JavaIOFileDescriptorAccess() 		{
            public void set(FileDescriptor var1, int var2) {
                var1.fd = var2;
            }

            public int get(FileDescriptor var1) {
                return var1.fd;
            }

            public void setHandle(FileDescriptor var1, long var2) {
                var1.handle = var2;
            }

            public long getHandle(FileDescriptor var1) {
                return var1.handle;
            }
        });
        in = standardStream(0);
        out = standardStream(1);
        err = standardStream(2);
    }
```



## 构造函数
```java
    public FileDescriptor() {
    }
```


## 功能函数

### vaild
```java
    public boolean valid() {
        return this.handle != -1L || this.fd != -1;
    }
```
### standard
```java
   private static FileDescriptor standardStream(int var0) {
       // 创建文件描述符
        FileDescriptor var1 = new FileDescriptor();
       // 设置此文件描述符对应哪个文件
        var1.handle = set(var0);
        return var1;
    }
```
### attach
```java
    synchronized void attach(Closeable var1) {
        if (this.parent == null) {
            this.parent = var1;
        } else if (this.otherParents == null) {
            this.otherParents = new ArrayList();
            this.otherParents.add(this.parent);
            this.otherParents.add(var1);
        } else {
            this.otherParents.add(var1);
        }

    }
```


### closeAll
```java
   synchronized void closeAll(Closeable var1) throws IOException {
        if (!this.closed) {
            this.closed = true;
            IOException var2 = null;
            try {
                Closeable var3 = var1;
                Throwable var4 = null;

                try {
                    if (this.otherParents != null) {
                        Iterator var5 = this.otherParents.iterator();
						// 循环把其他的parents也关闭
                        while(var5.hasNext()) {
                            Closeable var6 = (Closeable)var5.next();

                            try {
                                var6.close();
                            } catch (IOException var26) {
                                if (var2 == null) {
                                    var2 = var26;
                                } else {
                                    var2.addSuppressed(var26);
                                }
                            }
                        }
                    }
                } catch (Throwable var27) {
                    var4 = var27;
                    throw var27;
                } finally {
                    if (var1 != null) {
                        if (var4 != null) {
                            try {
                                var3.close();
                            } catch (Throwable var25) {
                                var4.addSuppressed(var25);
                            }
                        } else {
                            var1.close();
                        }
                    }

                }
            } catch (IOException var29) {
                if (var2 != null) {
                    var29.addSuppressed(var2);
                }

                var2 = var29;
            } finally {
                if (var2 != null) {
                    throw var2;
                }

            }
        }

    }
```

### NativeMethod

```java
    public native void sync() throws SyncFailedException;

    private static native void initIDs();

    private static native long set(int var0);
```

