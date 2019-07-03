# File

## Field

```java
    // 依赖于操作系统的文件操作函数
	private static final FileSystem fs = DefaultFileSystem.getFileSystem();
	// 文件路径
    private final String path;
	// 路径是否可用
    private transient PathStatus status = null;
    // 文件路径前缀长度,windows前缀 为3, E:\
    private final transient int prefixLength;
	// 文件系统的分隔符,windows系统分隔符: \\
    public static final char separatorChar = fs.getSeparator();
	// 分割符,
    public static final String separator = "" + separatorChar;
	// 路径分隔符
    public static final char pathSeparatorChar = fs.getPathSeparator();
	// 文件内存偏移值
    public static final String pathSeparator = "" + pathSeparatorChar;
    private static final long PATH_OFFSET;
    private static final long PREFIX_LENGTH_OFFSET;
	// CAS 操作
    private static final sun.misc.Unsafe UNSAFE;
```

静态初始化:

```java
static {
        try {
            sun.misc.Unsafe unsafe = sun.misc.Unsafe.getUnsafe();
            PATH_OFFSET = unsafe.objectFieldOffset(
                    File.class.getDeclaredField("path"));
            PREFIX_LENGTH_OFFSET = unsafe.objectFieldOffset(
                    File.class.getDeclaredField("prefixLength"));
            UNSAFE = unsafe;
        } catch (ReflectiveOperationException e) {
            throw new Error(e);
        }
    }
```

## 构造函数

```java
    // 指定文件路径和前缀长度
	private File(String pathname, int prefixLength) {
        this.path = pathname;
        this.prefixLength = prefixLength;
    }

	// 
    private File(String child, File parent) {
        assert parent.path != null;
        assert (!parent.path.equals(""));
        // 解析得到 parent+child的一个文件路径
        this.path = fs.resolve(parent.path, child);
        this.prefixLength = parent.prefixLength;
    }

	// 指定文件路径
    public File(String pathname) {
        if (pathname == null) {
            throw new NullPointerException();
        }
        // 设置一下slash
        this.path = fs.normalize(pathname);
        this.prefixLength = fs.prefixLength(this.path);
    }
	
    public File(String parent, String child) {
        if (child == null) {
            throw new NullPointerException();
        }
        if (parent != null) {
            if (parent.equals("")) {
                this.path = fs.resolve(fs.getDefaultParent(),
                                       fs.normalize(child));
            } else {
                this.path = fs.resolve(fs.normalize(parent),
                                       fs.normalize(child));
            }
        } else {
            this.path = fs.normalize(child);
        }
        this.prefixLength = fs.prefixLength(this.path);
    }

    public File(File parent, String child) {
        if (child == null) {
            throw new NullPointerException();
        }
        if (parent != null) {
            if (parent.path.equals("")) {
                this.path = fs.resolve(fs.getDefaultParent(),
                                       fs.normalize(child));
            } else {
                this.path = fs.resolve(parent.path,
                                       fs.normalize(child));
            }
        } else {
            this.path = fs.normalize(child);
        }
        this.prefixLength = fs.prefixLength(this.path);
    }

    public File(URI uri) {
        // Check our many preconditions
        if (!uri.isAbsolute())
            throw new IllegalArgumentException("URI is not absolute");
        if (uri.isOpaque())
            throw new IllegalArgumentException("URI is not hierarchical");
        String scheme = uri.getScheme();
        if ((scheme == null) || !scheme.equalsIgnoreCase("file"))
            throw new IllegalArgumentException("URI scheme is not \"file\"");
        if (uri.getAuthority() != null)
            throw new IllegalArgumentException("URI has an authority component");
        if (uri.getFragment() != null)
            throw new IllegalArgumentException("URI has a fragment component");
        if (uri.getQuery() != null)
            throw new IllegalArgumentException("URI has a query component");
        String p = uri.getPath();
        if (p.equals(""))
            throw new IllegalArgumentException("URI path component is empty");

        // Okay, now initialize
        p = fs.fromURIPath(p);
        if (File.separatorChar != '/')
            p = p.replace('/', File.separatorChar);
        this.path = fs.normalize(p);
        this.prefixLength = fs.prefixLength(this.path);
    }
```



```java
    public String getDefaultParent() {
        return ("" + slash);
    }
```

## 功能函数

### 1.获取文件名字

```java
   public String getName() {
       // 得到最后一个路径分隔符位置,separatorChar=\\
        int index = path.lastIndexOf(separatorChar);
        if (index < prefixLength) return path.substring(prefixLength);
       // 截取文件名字
        return path.substring(index + 1);
    }
```


### 2. 获取父文件
```java
    public String getParent() {
        // 得到最后一个分隔符位置
        int index = path.lastIndexOf(separatorChar);
        if (index < prefixLength) {
            if ((prefixLength > 0) && (path.length() > prefixLength))
                return path.substring(0, prefixLength);
            return null;
        }
        // 最后一个路径的前边就是父目录, C:\\douck\\text.txt的父目录就是C:\\douck
        // 此处就是得到目录
        return path.substring(0, index);
    }

	// 得到父目录
   public File getParentFile() {
       // 获取上级目录
        String p = this.getParent();
        if (p == null) return null;
       // 父文件
        return new File(p, this.prefixLength);
    }
```


### 3. 获取绝对路径
```java
    public String getAbsolutePath() {
        // 依赖操作系统接口函数实现,这里先了解,回头文件依赖函数
        return fs.resolve(this);
    }

    public File getAbsoluteFile() {
        String absPath = getAbsolutePath();
        // 得到绝对路径文件
        return new File(absPath, fs.prefixLength(absPath));
    }
```


### 4. 转换为URI
```java
    public URI toURI() {
        try {
            File f = getAbsoluteFile();
            String sp = slashify(f.getPath(), f.isDirectory());
            if (sp.startsWith("//"))
                sp = "//" + sp;
            return new URI("file", null, sp, null);
        } catch (URISyntaxException x) {
            throw new Error(x);         // Can't happen
        }
    }
	// 把文件分隔符,替换为 /
    private static String slashify(String path, boolean isDirectory) {
        String p = path;
        if (File.separatorChar != '/')
            p = p.replace(File.separatorChar, '/');
        if (!p.startsWith("/"))
            p = "/" + p;
        if (!p.endsWith("/") && isDirectory)
            p = p + "/";
        return p;
    }
```
### 5. 判断能否读写
```java
    public boolean canRead() {
        // 安全管理
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            // 通过权限去验证
            security.checkRead(path);
        }
        if (isInvalid()) {
            return false;
        }
        // 通过底层系统函数验证
        return fs.checkAccess(this, FileSystem.ACCESS_READ);
    }

    public boolean canWrite() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkWrite(path);
        }
        if (isInvalid()) {
            return false;
        }
        return fs.checkAccess(this, FileSystem.ACCESS_WRITE);
    }
```
### 6. 文件是否存在
```java
    public boolean exists() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(path);
        }
        if (isInvalid()) {
            return false;
        }
        // 底层系统函数验证
        return ((fs.getBooleanAttributes(this) & FileSystem.BA_EXISTS) != 0);
    }
```


### 7.  是否是目录
```java
    public boolean isDirectory() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            // 安全机制验证
            security.checkRead(path);
        }
        if (isInvalid()) {
            return false;
        }
        // 底层操作系统函数 验证
        return ((fs.getBooleanAttributes(this) & FileSystem.BA_DIRECTORY)
                != 0);
    }
```


### 8. 是否是文件
```java
   public boolean isFile() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            // 安全机制验证
            security.checkRead(path);
        }
        if (isInvalid()) {
            return false;
        }
       // 操作系统函数验证
        return ((fs.getBooleanAttributes(this) & FileSystem.BA_REGULAR) != 0);
    }
```


### 9. 是否是隐藏文件
```java
    public boolean isHidden() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(path);
        }
        if (isInvalid()) {
            return false;
        }
        return ((fs.getBooleanAttributes(this) & FileSystem.BA_HIDDEN) != 0);
    }
```


### 10. 删除文件
```java
    public boolean delete() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkDelete(path);
        }
        if (isInvalid()) {
            return false;
        }
        return fs.delete(this);
    }
```


### 11.  上次修改时间
```java
    public long lastModified() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(path);
        }
        if (isInvalid()) {
            return 0L;
        }
        return fs.getLastModifiedTime(this);
    }
```


### 12. 文件长度
```java
    public long length() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(path);
        }
        if (isInvalid()) {
            return 0L;
        }
        return fs.getLength(this);
    }
```


### 13. 创建新文件
```java
    public boolean createNewFile() throws IOException {
        SecurityManager security = System.getSecurityManager();
        if (security != null) security.checkWrite(path);
        if (isInvalid()) {
            throw new IOException("Invalid file path");
        }
        // 底层系统函数
        return fs.createFileExclusively(path);
    }
```


### 14. 列出文件
```java
    public String[] list() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(path);
        }
        if (isInvalid()) {
            return null;
        }
        return fs.list(this);
    }
```

### 15. 设置读写执行权限
```java
    public boolean setReadOnly() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkWrite(path);
        }
        if (isInvalid()) {
            return false;
        }
        return fs.setReadOnly(this);
    }

    public boolean setWritable(boolean writable, boolean ownerOnly) {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkWrite(path);
        }
        if (isInvalid()) {
            return false;
        }
        return fs.setPermission(this, FileSystem.ACCESS_WRITE, writable, ownerOnly);
    }

    public boolean setExecutable(boolean executable, boolean ownerOnly) {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkWrite(path);
        }
        if (isInvalid()) {
            return false;
        }
        return fs.setPermission(this, FileSystem.ACCESS_EXECUTE, executable, ownerOnly);
    }
```


### 16. 获取文件占据总磁盘大小
```java
    public long getTotalSpace() {
        SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            sm.checkPermission(new RuntimePermission("getFileSystemAttributes"));
            sm.checkRead(path);
        }
        if (isInvalid()) {
            return 0L;
        }
        return fs.getSpace(this, FileSystem.SPACE_TOTAL);
    }
```


### 17. 获取文件使用的磁盘大小
```java
    public long getUsableSpace() {
        SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            sm.checkPermission(new RuntimePermission("getFileSystemAttributes"));
            sm.checkRead(path);
        }
        if (isInvalid()) {
            return 0L;
        }
        return fs.getSpace(this, FileSystem.SPACE_USABLE);
    }
```

### 18. 文件是否有效

```java
    final boolean isInvalid() {
        if (status == null) {
            // 如果文件路径中不存在 \u0000 ,则文件无效
            status = (this.path.indexOf('\u0000') < 0) ? PathStatus.CHECKED
                                                       : PathStatus.INVALID;
        }
        return status == PathStatus.INVALID;
    }
```



