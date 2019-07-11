# URLClassPath

## Field

```java
// 版本信息
static final String USER_AGENT_JAVA_VERSION = "UA-Java-Version";
// java版本信息
static final String JAVA_VERSION = (String)AccessController.doPrivileged(new GetPropertyAction("java.version"));
// 获取系统属性,是否是debug模式
private static final boolean DEBUG = AccessController.doPrivileged(new GetPropertyAction("sun.misc.URLClassPath.debug")) != null;
// debugCache模式
private static final boolean DEBUG_LOOKUP_CACHE = AccessController.doPrivileged(new GetPropertyAction("sun.misc.URLClassPath.debugLookupCache")) != null;
// 标志
private static final boolean DISABLE_JAR_CHECKING;
private static final boolean DISABLE_ACC_CHECKING;
private ArrayList<URL> path;
Stack<URL> urls;
ArrayList<URLClassPath.Loader> loaders;
HashMap<String, URLClassPath.Loader> lmap;
private URLStreamHandler jarHandler;
// 是否关闭
private boolean closed;
// 访问权限上下文
private final AccessControlContext acc;
// 查找cache 是否开启
private static volatile boolean lookupCacheEnabled;
private URL[] lookupCacheURLs;
private ClassLoader lookupCacheLoader;
```

静态初始化代码：

```java
static {
    // 根据属性类设置DISABLE_JAR_CHECKING和DISABLE_ACC_CHECKING以及
    // lookupCacheEnabled的值
    String var0 = (String)AccessController.doPrivileged(new GetPropertyAction("sun.misc.URLClassPath.disableJarChecking"));
    DISABLE_JAR_CHECKING = var0 != null ? var0.equals("true") || var0.equals("") : false;
    var0 = (String)AccessController.doPrivileged(new GetPropertyAction("jdk.net.URLClassPath.disableRestrictedPermissions"));
    DISABLE_ACC_CHECKING = var0 != null ? var0.equals("true") || var0.equals("") : false;
    lookupCacheEnabled = "true".equals(VM.getSavedProperty("sun.cds.enableSharedLookupCache"));
}
```

## 构造函数
```java
public URLClassPath(URL[] var1) {
    this(var1, (URLStreamHandlerFactory)null, (AccessControlContext)null);
}

public URLClassPath(URL[] var1, AccessControlContext var2) {
    this(var1, (URLStreamHandlerFactory)null, var2);
}


public URLClassPath(URL[] var1, URLStreamHandlerFactory var2, AccessControlContext var3) {
    // 初始化field
    this.path = new ArrayList();
    this.urls = new Stack();
    this.loaders = new ArrayList();
    this.lmap = new HashMap();
    this.closed = false;
	// 添加url路径
    for(int var4 = 0; var4 < var1.length; ++var4) {
        this.path.add(var1[var4]);
    }

    this.push(var1);
    if (var2 != null) {
        // 对jar包的操作函数
        // 依赖于本地系统
        this.jarHandler = var2.createURLStreamHandler("jar");
    }

    if (DISABLE_ACC_CHECKING) {
        this.acc = null;
    } else {
        this.acc = var3;
    }
}
```


## 功能函数

### get/addURL

```java
  // 就是容器函数的一个添加操作
	public synchronized void addURL(URL var1) {
        if (!this.closed) {
            Stack var2 = this.urls;
            synchronized(this.urls) {
                if (var1 != null && !this.path.contains(var1)) {
                    this.urls.add(0, var1);
                    this.path.add(var1);
                    if (this.lookupCacheURLs != null) {
                        disableAllLookupCaches();
                    }

                }
            }
        }
    }

	// 容器转换为数组返回
    public URL[] getURLs() {
        Stack var1 = this.urls;
        synchronized(this.urls) {
            return (URL[])this.path.toArray(new URL[this.path.size()]);
        }
    }
```

### disableAllLookupCaches

```java
    static void disableAllLookupCaches() {
        lookupCacheEnabled = false;
    }
```



### find/getResource

```java
    public URL findResource(String var1, boolean var2) {
        int[] var4 = this.getLookupCache(var1);
        URLClassPath.Loader var3;
        // 使用不同的classLoader去查找这个资源
        for(int var5 = 0; (var3 = this.getNextLoader(var4, var5)) != null; ++var5) {
            URL var6 = var3.findResource(var1, var2);
            if (var6 != null) {
                return var6;
            }
        }
        return null;
    }

    public Resource getResource(String var1, boolean var2) {
        if (DEBUG) {
            System.err.println("URLClassPath.getResource(\"" + var1 + "\")");
        }
		// 先从缓存查找
        int[] var4 = this.getLookupCache(var1);
        URLClassPath.Loader var3;
        // 使用不同的classLoader去进行加载
        for(int var5 = 0; (var3 = this.getNextLoader(var4, var5)) != null; ++var5) {
            Resource var6 = var3.getResource(var1, var2);
            if (var6 != null) {
                return var6;
            }
        }
        return null;
    }
```

### getLookupCache

```java
// 从缓存的中获取
private synchronized int[] getLookupCache(String var1) {
    if (this.lookupCacheURLs != null && lookupCacheEnabled) {
        // 本地方法
        int[] var2 = getLookupCacheForClassLoader(this.lookupCacheLoader, var1);
        if (var2 != null && var2.length > 0) {
            int var3 = var2[var2.length - 1];
            if (!this.ensureLoaderOpened(var3)) {
                if (DEBUG_LOOKUP_CACHE) {
                    System.out.println("Expanded loaders FAILED " + this.loaders.size() + " for maxindex=" + var3);
                }
                return null;
            }
        }
        return var2;
    } else {
        return null;
    }
}

// 本地查找类加载器
private static native int[] getLookupCacheForClassLoader(ClassLoader var0, String var1);
// 检查对应位置上的classLoader存在
private boolean ensureLoaderOpened(int var1) {
    if (this.loaders.size() <= var1) {
        if (this.getLoader(var1) == null) {
            return false;
        }
        if (!lookupCacheEnabled) {
            return false;
        }
        if (DEBUG_LOOKUP_CACHE) {
            System.out.println("Expanded loaders " + this.loaders.size() + " to index=" + var1);
        }
    }
    return true;
}
```

### initLookupCache

```java
    synchronized void initLookupCache(ClassLoader var1) {
        if ((this.lookupCacheURLs = getLookupCacheURLs(var1)) != null) {
            this.lookupCacheLoader = var1;
        } else {
            disableAllLookupCaches();
        }
    }

    private static native URL[] getLookupCacheURLs(ClassLoader var0);
```

### validateLookupCache

```java
    // 检查是否有效
	private synchronized void validateLookupCache(int var1, String var2) {
        if (this.lookupCacheURLs != null && lookupCacheEnabled) {
            if (var1 < this.lookupCacheURLs.length && var2.equals(URLUtil.urlNoFragString(this.lookupCacheURLs[var1]))) {
                return;
            }
            if (DEBUG || DEBUG_LOOKUP_CACHE) {
                System.out.println("WARNING: resource lookup cache invalidated for lookupCacheLoader at " + var1);
            }
            disableAllLookupCaches();
        }
    }
```

### getNextLoader

```java
// var1 对应的classLoader的索引数组
// var2 要获取的classLoader位置
private synchronized URLClassPath.Loader getNextLoader(int[] var1, int var2) {
    if (this.closed) {
        return null;
    } else if (var1 != null) {
        if (var2 < var1.length) {
            // 直接获取
            URLClassPath.Loader var3 = (URLClassPath.Loader)this.loaders.get(var1[var2]);
            if (DEBUG_LOOKUP_CACHE) {
                System.out.println("HASCACHE: Loading from : " + var1[var2] + " = " + var3.getBaseURL());
            }
            return var3;
        } else {
            return null;
        }
    } else {
        return this.getLoader(var2);
    }
}
```

### getLoader

```java
// 加载classLoader
private synchronized URLClassPath.Loader getLoader(int var1) {
    if (this.closed) {
        return null;
    } else {
        while(this.loaders.size() < var1 + 1) {// 总长度都不够,需要添加新的加载器
            Stack var3 = this.urls;
            URL var2;
            synchronized(this.urls) {
                if (this.urls.empty()) {
                    return null;
                }
                // url路径
                var2 = (URL)this.urls.pop();
            }
            String var9 = URLUtil.urlNoFragString(var2);
            if (!this.lmap.containsKey(var9)) {
                URLClassPath.Loader var4;
                try {
                    // 依据var2创建新的加载器
                    var4 = this.getLoader(var2);
                    URL[] var5 = var4.getClassPath();
                    if (var5 != null) {
                        this.push(var5);
                    }
                } catch (IOException var6) {
                    continue;
                } catch (SecurityException var7) {
                    if (DEBUG) {
                        System.err.println("Failed to access " + var2 + ", " + var7);
                    }
                    continue;
                }
                this.validateLookupCache(this.loaders.size(), var9);
                // 添加新创建的loader
                this.loaders.add(var4);
                // url 和 loader的映射
                this.lmap.put(var9, var4);
            }
        }

        if (DEBUG_LOOKUP_CACHE) {
            System.out.println("NOCACHE: Loading from : " + var1);
        }
		// 直接返回对应位置的loader
        return (URLClassPath.Loader)this.loaders.get(var1);
    }
}
```

```java
private URLClassPath.Loader getLoader(final URL var1) throws IOException {
    try {
        return (URLClassPath.Loader)AccessController.doPrivileged(new PrivilegedExceptionAction<URLClassPath.Loader>() {
            public URLClassPath.Loader run() throws IOException {
                // 是否是文件
                String var1x = var1.getFile();
                if (var1x != null && var1x.endsWith("/")) {
                    // 创建新的URLClassPath.Loader
                    return (URLClassPath.Loader)("file".equals(var1.getProtocol()) ? new URLClassPath.FileLoader(var1) : new URLClassPath.Loader(var1));
                } else {
                    // 是jar包，则获取jar包loader
                    return new URLClassPath.JarLoader(var1, URLClassPath.this.jarHandler, URLClassPath.this.lmap, URLClassPath.this.acc);
                }
            }
        }, this.acc);
    } catch (PrivilegedActionException var3) {
        throw (IOException)var3.getException();
    }
}
```

### push

```java
private void push(URL[] var1) {
    Stack var2 = this.urls;
    synchronized(this.urls) {
        for(int var3 = var1.length - 1; var3 >= 0; --var3) {
            this.urls.push(var1[var3]);
        }

    }
}
```

### pathToURLs

```java
public static URL[] pathToURLs(String var0) {
    StringTokenizer var1 = new StringTokenizer(var0, File.pathSeparator);
    URL[] var2 = new URL[var1.countTokens()];
    int var3 = 0;
    while(var1.hasMoreTokens()) {
        File var4 = new File(var1.nextToken());
        try {
            var4 = new File(var4.getCanonicalPath());
        } catch (IOException var7) {
            ;
        }
        try {
            var2[var3++] = ParseUtil.fileToEncodedURL(var4);
        } catch (IOException var6) {
            ;
        }
    }
    if (var2.length != var3) {
        URL[] var8 = new URL[var3];
        System.arraycopy(var2, 0, var8, 0, var3);
        var2 = var8;
    }

    return var2;
}
```

### checkURL

```java
public URL checkURL(URL var1) {
    try {
        check(var1);
        return var1;
    } catch (Exception var3) {
        return null;
    }
}

static void check(URL var0) throws IOException {
    SecurityManager var1 = System.getSecurityManager();
    if (var1 != null) {
        // 打开连接,并获取权限
        URLConnection var2 = var0.openConnection();
        Permission var3 = var2.getPermission();
        if (var3 != null) {
            try {
                // 检查权限
                var1.checkPermission(var3);
            } catch (SecurityException var6) {
                // file 权限
                if (var3 instanceof FilePermission && var3.getActions().indexOf("read") != -1) {
                    var1.checkRead(var3.getName());
                } else {
                    // socket权限
                    if (!(var3 instanceof SocketPermission) || var3.getActions().indexOf("connect") == -1) {
                        throw var6;
                    }
                    URL var5 = var0;
                    if (var2 instanceof JarURLConnection) {
                        var5 = ((JarURLConnection)var2).getJarFileURL();
                    }
					// URL远程
                    var1.checkConnect(var5.getHost(), var5.getPort());
                }
            }
        }
    }

}
```



## 内部类

### FileLoader
Field

```java
private File dir;
```



构造函数

```java
FileLoader(URL var1) throws IOException {
    super(var1);
    if (!"file".equals(var1.getProtocol())) {
        throw new IllegalArgumentException("url");
    } else {
        // 文件路径
        String var2 = var1.getFile().replace('/', File.separatorChar);
        var2 = ParseUtil.decode(var2);
        // 转换为规范路径,并记录
        this.dir = (new File(var2)).getCanonicalFile();
    }
}
```


功能函数

```java
URL findResource(String var1, boolean var2) {
    // 查找路径
    Resource var3 = this.getResource(var1, var2);
    return var3 != null ? var3.getURL() : null;
}
// 查找
Resource getResource(final String var1, boolean var2) {
    try {
        URL var4 = new URL(this.getBaseURL(), ".");
        final URL var3 = new URL(this.getBaseURL(), ParseUtil.encodePath(var1, false));
        if (!var3.getFile().startsWith(var4.getFile())) {
            return null;
        } else {
            if (var2) {
                URLClassPath.check(var3);
            }
            final File var5;
            if (var1.indexOf("..") != -1) {
                var5 = (new File(this.dir, var1.replace('/', File.separatorChar))).getCanonicalFile();
                if (!var5.getPath().startsWith(this.dir.getPath())) {
                    return null;
                }
            } else {
                var5 = new File(this.dir, var1.replace('/', File.separatorChar));
            }

            return var5.exists() ? new Resource() {
                public String getName() {
                    return var1;
                }

                public URL getURL() {
                    return var3;
                }

                public URL getCodeSourceURL() {
                    return FileLoader.this.getBaseURL();
                }

                public InputStream getInputStream() throws IOException {
                    return new FileInputStream(var5);
                }

                public int getContentLength() throws IOException {
                    return (int)var5.length();
                }
            } : null;
        }
    } catch (Exception var6) {
        return null;
    }
}
```


### JarLoader
Field

```java
private JarFile jar;
private final URL csu;
private JarIndex index;
private MetaIndex metaIndex;
private URLStreamHandler handler;
private final HashMap<String, URLClassPath.Loader> lmap;
private final AccessControlContext acc;
private boolean closed = false;
private static final JavaUtilZipFileAccess zipAccess = SharedSecrets.getJavaUtilZipFileAccess();
```



构造函数

```java
JarLoader(URL var1, URLStreamHandler var2, HashMap<String, URLClassPath.Loader> var3, AccessControlContext var4) throws IOException {
    super(new URL("jar", "", -1, var1 + "!/", var2));
    this.csu = var1;
    this.handler = var2;
    this.lmap = var3;
    this.acc = var4;
    if (!this.isOptimizable(var1)) {
        this.ensureOpen();
    } else {
        String var5 = var1.getFile();
        if (var5 != null) {
            var5 = ParseUtil.decode(var5);
            File var6 = new File(var5);
            this.metaIndex = MetaIndex.forJar(var6);
            if (this.metaIndex != null && !var6.exists()) {
                this.metaIndex = null;
            }
        }

        if (this.metaIndex == null) {
            this.ensureOpen();
        }
    }
}

// 判断是不是file协议
private boolean isOptimizable(URL var1) {
    return "file".equals(var1.getProtocol());
}
```

功能函数

ensureOpen:

```java
private void ensureOpen() throws IOException {
    if (this.jar == null) {
        try {
            AccessController.doPrivileged(new PrivilegedExceptionAction<Void>() {
                public Void run() throws IOException {
                    if (URLClassPath.DEBUG) {
                        System.err.println("Opening " + JarLoader.this.csu);
                        Thread.dumpStack();
                    }
       JarLoader.this.jar = JarLoader.this.getJarFile(JarLoader.this.csu);
       JarLoader.this.index = JarIndex.getJarIndex(JarLoader.this.jar, JarLoader.this.metaIndex);
                    if (JarLoader.this.index != null) {
                        String[] var1 = JarLoader.this.index.getJarFiles();
                        // 遍历记录URL下的所有jar包
                        for(int var2 = 0; var2 < var1.length; ++var2) {
                            try {
                                URL var3 = new URL(JarLoader.this.csu, var1[var2]);
                                String var4 = URLUtil.urlNoFragString(var3);
                                if (!JarLoader.this.lmap.containsKey(var4)) {
                                    JarLoader.this.lmap.put(var4, (Object)null);
                                }
                            } catch (MalformedURLException var5) {
                                ;
                            }
                        }
                    }
                    return null;
                }
            }, this.acc);
        } catch (PrivilegedActionException var2) {
            throw (IOException)var2.getException();
        }
    }

}
```

getJarFile

```java
private JarFile getJarFile(URL var1) throws IOException {
    if (this.isOptimizable(var1)) {
        FileURLMapper var4 = new FileURLMapper(var1);
        if (!var4.exists()) {
            throw new FileNotFoundException(var4.getPath());
        } else {
            return checkJar(new JarFile(var4.getPath()));
        }
    } else {
        URLConnection var2 = this.getBaseURL().openConnection();
        var2.setRequestProperty("UA-Java-Version", URLClassPath.JAVA_VERSION);
        JarFile var3 = ((JarURLConnection)var2).getJarFile();
        return checkJar(var3);
    }
}
```

getResource:

```java
// 查找资源
URL findResource(String var1, boolean var2) {
    Resource var3 = this.getResource(var1, var2);
    return var3 != null ? var3.getURL() : null;
}

// 查找资源
Resource getResource(String var1, boolean var2) {
    if (this.metaIndex != null && !this.metaIndex.mayContain(var1)) {
        return null;
    } else {
        try {
            this.ensureOpen();
        } catch (IOException var5) {
            throw new InternalError(var5);
        }
        JarEntry var3 = this.jar.getJarEntry(var1);
        if (var3 != null) {
            return this.checkResource(var1, var2, var3);
        } else if (this.index == null) {
            return null;
        } else {
            HashSet var4 = new HashSet();
            return this.getResource(var1, var2, var4);
        }
    }
}
```

```java
Resource getResource(String var1, boolean var2, Set<String> var3) {
    int var6 = 0;
    LinkedList var7 = null;
    if ((var7 = this.index.get(var1)) == null) {
        return null;
    } else {
        do {
            int var8 = var7.size();
            String[] var5 = (String[])var7.toArray(new String[var8]);
            while(var6 < var8) {
                String var9 = var5[var6++];
                URLClassPath.JarLoader var10;
                final URL var11;
                try {
                    var11 = new URL(this.csu, var9);
                    String var12 = URLUtil.urlNoFragString(var11);
           if ((var10 = (URLClassPath.JarLoader)this.lmap.get(var12)) == null) {
           var10 = (URLClassPath.JarLoader)AccessController.doPrivileged(new PrivilegedExceptionAction<URLClassPath.JarLoader>() {
                            public URLClassPath.JarLoader run() throws IOException {
                                return new URLClassPath.JarLoader(var11, JarLoader.this.handler, JarLoader.this.lmap, JarLoader.this.acc);
                            }
                        }, this.acc);
                        JarIndex var13 = var10.getIndex();
                        if (var13 != null) {
                            int var14 = var9.lastIndexOf("/");
                            var13.merge(this.index, var14 == -1 ? null : var9.substring(0, var14 + 1));
                        }
					// url和classLoader的映射
                        this.lmap.put(var12, var10);
                    }
                } catch (PrivilegedActionException var16) {
                    continue;
                } catch (MalformedURLException var17) {
                    continue;
                }

                boolean var18 = !var3.add(URLUtil.urlNoFragString(var11));
                if (!var18) {
                    try {
                        var10.ensureOpen();
                    } catch (IOException var15) {
                        throw new InternalError(var15);
                    }

                    JarEntry var19 = var10.jar.getJarEntry(var1);
                    if (var19 != null) {
                        return var10.checkResource(var1, var2, var19);
                    }

                    if (!var10.validIndex(var1)) {
                        throw new InvalidJarIndexException("Invalid index");
                    }
                }

                Resource var4;
                if (!var18 && var10 != this && var10.getIndex() != null && (var4 = var10.getResource(var1, var2, var3)) != null) {
                    return var4;
                }
            }

            var7 = this.index.get(var1);
        } while(var6 < var7.size());

        return null;
    }
}
```



getClassPath:

```java
URL[] getClassPath() throws IOException {
    if (this.index != null) {
        return null;
    } else if (this.metaIndex != null) {
        return null;
    } else {
        this.ensureOpen();
        this.parseExtensionsDependencies();
        if (SharedSecrets.javaUtilJarAccess().jarFileHasClassPathAttribute(this.jar)) {
            Manifest var1 = this.jar.getManifest();
            if (var1 != null) {
                Attributes var2 = var1.getMainAttributes();
                if (var2 != null) {
                    String var3 = var2.getValue(Name.CLASS_PATH);
                    if (var3 != null) {
                        return this.parseClassPath(this.csu, var3);
                    }
                }
            }
        }

        return null;
    }
}
```





parseExtensions:

```java
private void parseExtensionsDependencies() throws IOException {
    ExtensionDependency.checkExtensionsDependencies(this.jar);
}
```



parseClassPath:

```java
private URL[] parseClassPath(URL var1, String var2) throws MalformedURLException {
    StringTokenizer var3 = new StringTokenizer(var2);
    URL[] var4 = new URL[var3.countTokens()];

    for(int var5 = 0; var3.hasMoreTokens(); ++var5) {
        String var6 = var3.nextToken();
        var4[var5] = new URL(var1, var6);
    }
    return var4;
}
```



### Loader

Field

```java
private final URL base;
private JarFile jarfile;
```



构造函数

```java
Loader(URL var1) {
    this.base = var1;
}
```

功能函数

getBaseURL

```java
URL getBaseURL() {
    return this.base;
}
```

findResource

```java
URL findResource(String var1, boolean var2) {
    URL var3;
    try {
        // 解析资源的路径，并封装为URL
        var3 = new URL(this.base, ParseUtil.encodePath(var1, false));
    } catch (MalformedURLException var7) {
        throw new IllegalArgumentException("name");
    }
    try {
        if (var2) {
            URLClassPath.check(var3);
        }
		// 打开连接
        URLConnection var4 = var3.openConnection();
        if (var4 instanceof HttpURLConnection) { // httpURLConnection
            HttpURLConnection var5 = (HttpURLConnection)var4;
            var5.setRequestMethod("HEAD");
            if (var5.getResponseCode() >= 400) {
                return null;
            }
        } else {
            var4.setUseCaches(false);
            // 获取输入源
            InputStream var8 = var4.getInputStream();
            var8.close();
        }
        return var3;
    } catch (Exception var6) {
        return null;
    }
}
```

getResources

```java
Resource getResource(final String var1, boolean var2) {
    final URL var3;
    try {
        // 封装URL
        var3 = new URL(this.base, ParseUtil.encodePath(var1, false));
    } catch (MalformedURLException var7) {
        throw new IllegalArgumentException("name");
    }
    final URLConnection var4;
    try {
        if (var2) {
            URLClassPath.check(var3);
        }
		// 打开连接
        var4 = var3.openConnection();
        InputStream var5 = var4.getInputStream();
        if (var4 instanceof JarURLConnection) { // jarURL
            JarURLConnection var6 = (JarURLConnection)var4;
            // 获取到文件
            this.jarfile = URLClassPath.JarLoader.checkJar(var6.getJarFile());
        }
    } catch (Exception var8) {
        return null;
    }

    return new Resource() {
        public String getName() {
            return var1;
        }

        public URL getURL() {
            return var3;
        }

        public URL getCodeSourceURL() {
            return Loader.this.base;
        }

        public InputStream getInputStream() throws IOException {
            return var4.getInputStream();
        }

        public int getContentLength() throws IOException {
            return var4.getContentLength();
        }
    };
}
```

getResources

```java
Resource getResource(String var1) {
    return this.getResource(var1, true);
}
```

close

```java
public void close() throws IOException {
    if (this.jarfile != null) {
        this.jarfile.close();
    }
}

URL[] getClassPath() throws IOException {
    return null;
}
```

