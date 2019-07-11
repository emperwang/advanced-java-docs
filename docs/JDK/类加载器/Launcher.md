# Launcher

## Field

```java
    private static URLStreamHandlerFactory factory = new Launcher.Factory();
    private static Launcher launcher = new Launcher();
    private static String bootClassPath = System.getProperty("sun.boot.class.path");
    private ClassLoader loader;
    private static URLStreamHandler fileHandler;
```



## 构造函数

```java
    public Launcher() {
        Launcher.ExtClassLoader var1;
        try {
            var1 = Launcher.ExtClassLoader.getExtClassLoader();
        } catch (IOException var10) {
        throw new InternalError("Could not create extension class loader", var10);
        }
        try {
            this.loader = Launcher.AppClassLoader.getAppClassLoader(var1);
        } catch (IOException var9) {
         throw new InternalError("Could not create application class loader", var9);
        }
		// 设置加载类
        Thread.currentThread().setContextClassLoader(this.loader);
        String var2 = System.getProperty("java.security.manager");
        if (var2 != null) {
            SecurityManager var3 = null;
            if (!"".equals(var2) && !"default".equals(var2)) {
                try {
              var3 = (SecurityManager)this.loader.loadClass(var2).newInstance();
                } catch (IllegalAccessException var5) {
                    ;
                } catch (InstantiationException var6) {
                    ;
                } catch (ClassNotFoundException var7) {
                    ;
                } catch (ClassCastException var8) {
                    ;
                }
            } else {
                var3 = new SecurityManager();
            }

            if (var3 == null) {
              throw new InternalError("Could not create SecurityManager: " + var2);
            }
            // 保存创建的SecurityManager
            System.setSecurityManager(var3);
        }
    }
```



## 功能方法

### getLauncher

```java
    public static Launcher getLauncher() {
        return launcher;
    }
```

### getClassLoader

```java
    public ClassLoader getClassLoader() {
        return this.loader;
    }
```

### getBootstrapClasspath
```java
    public static URLClassPath getBootstrapClassPath() {
        return Launcher.BootClassPathHolder.bcp;
    }
```


### pathToUrls
```java
    private static URL[] pathToURLs(File[] var0) {
        URL[] var1 = new URL[var0.length];
        for(int var2 = 0; var2 < var0.length; ++var2) {
            var1[var2] = getFileURL(var0[var2]);
        }
        return var1;
    }
	// 获取文件对应的url
    static URL getFileURL(File var0) {
        try {
            var0 = var0.getCanonicalFile();
        } catch (IOException var3) {
            ;
        }
        try {
            // 具体的解析
            return ParseUtil.fileToEncodedURL(var0);
        } catch (MalformedURLException var2) {
            throw new InternalError(var2);
        }
    }
```


### getClassPath
```java
   // 获取类路径
	private static File[] getClassPath(String var0) {
        File[] var1;
        if (var0 != null) {
            int var2 = 0;
            int var3 = 1;
            boolean var4 = false;
            int var5;
            int var7;
            for(var5 = 0; (var7 = var0.indexOf(File.pathSeparator, var5)) != -1; var5 = var7 + 1) {
                ++var3;// 记录多少个文件分隔符
            }
            var1 = new File[var3];
            var4 = false;
            // 对var0路径进行遍历,每个分隔符都创建一个文件
            for(var5 = 0; (var7 = var0.indexOf(File.pathSeparator, var5)) != -1; var5 = var7 + 1) {
                if (var7 - var5 > 0) {
                    var1[var2++] = new File(var0.substring(var5, var7));
                } else {
                    var1[var2++] = new File(".");
                }
            }

            if (var5 < var0.length()) {
                var1[var2++] = new File(var0.substring(var5));
            } else {
                var1[var2++] = new File(".");
            }

            if (var2 != var3) {
                File[] var6 = new File[var2];
                System.arraycopy(var1, 0, var6, 0, var2);
                var1 = var6;
            }
        } else {
            var1 = new File[0];
        }
        return var1;
    }
```




## 内部类

### AppClassLoader

静态初始化代码：

```java
static {
    // 注册成并发加载器
    ClassLoader.registerAsParallelCapable();
}
```

Field

```java
 final URLClassPath ucp = SharedSecrets.getJavaNetAccess().getURLClassPath(this);
```

构造器:

```java
AppClassLoader(URL[] var1, ClassLoader var2) {
    super(var1, var2, Launcher.factory);
    this.ucp.initLookupCache(this);
}
```
getAppClassLoader:

```java
public static ClassLoader getAppClassLoader(final ClassLoader var0) throws IOException {
    final String var1 = System.getProperty("java.class.path");
    final File[] var2 = var1 == null ? new File[0] : Launcher.getClassPath(var1);
    return (ClassLoader)AccessController.doPrivileged(new PrivilegedAction<Launcher.AppClassLoader>() {
        public Launcher.AppClassLoader run() {
            // 返回规范文件路径
            URL[] var1x = var1 == null ? new URL[0] : Launcher.pathToURLs(var2);
            return new Launcher.AppClassLoader(var1x, var0);
        }
    });
}
```
loadClass:

```java
public Class<?> loadClass(String var1, boolean var2) throws ClassNotFoundException {
    int var3 = var1.lastIndexOf(46);
    if (var3 != -1) {
        SecurityManager var4 = System.getSecurityManager();
        if (var4 != null) {
            var4.checkPackageAccess(var1.substring(0, var3));
        }
    }

    if (this.ucp.knownToNotExist(var1)) {
        // 从已经加载的类中查找
        Class var5 = this.findLoadedClass(var1);
        if (var5 != null) {// 找到了
            if (var2) { // 如果需要解析,则进行解析
                this.resolveClass(var5);
            }
            return var5;
        } else {
            throw new ClassNotFoundException(var1);
        }
    } else {
        return super.loadClass(var1, var2);
    }
}
```
gerPermissions:

```java
protected PermissionCollection getPermissions(CodeSource var1) {
    PermissionCollection var2 = super.getPermissions(var1);
    var2.add(new RuntimePermission("exitVM"));
    return var2;
}
```


appendToClass:

```java
private void appendToClassPathForInstrumentation(String var1) {
    assert Thread.holdsLock(this);

    super.addURL(Launcher.getFileURL(new File(var1)));
}
```


getContext:

```java
private static AccessControlContext getContext(File[] var0) throws MalformedURLException {
    PathPermissions var1 = new PathPermissions(var0);
    ProtectionDomain var2 = new ProtectionDomain(new CodeSource(var1.getCodeBase(), (Certificate[])null), var1);
    AccessControlContext var3 = new AccessControlContext(new ProtectionDomain[]{var2});
    return var3;
}
```


### BootClassPathHolder

Field

```java
static final URLClassPath bcp;
```



静态初始化代码:

```java
static {
    URL[] var0;
    if (Launcher.bootClassPath != null) {
        var0 = (URL[])AccessController.doPrivileged(new PrivilegedAction<URL[]>() {
            public URL[] run() {
                File[] var1 = Launcher.getClassPath(Launcher.bootClassPath);
                int var2 = var1.length;
                HashSet var3 = new HashSet();

                for(int var4 = 0; var4 < var2; ++var4) {
                    File var5 = var1[var4];
                    if (!var5.isDirectory()) {
                        var5 = var5.getParentFile();
                    }

                    if (var5 != null && var3.add(var5)) {
                        MetaIndex.registerDirectory(var5);
                    }
                }

                return Launcher.pathToURLs(var1);
            }
        });
    } else {
        var0 = new URL[0];
    }

    bcp = new URLClassPath(var0, Launcher.factory, (AccessControlContext)null);
    bcp.initLookupCache((ClassLoader)null);
}
```



构造函数

```java
        private BootClassPathHolder() {
        }
```





### ExtClassLoader

```java
static class ExtClassLoader extends URLClassLoader
```

静态初始化代码：

```java
static {
    // 注册并发加载
    ClassLoader.registerAsParallelCapable();
}
```

ExtClassLoader-构造函数:
```java
public ExtClassLoader(File[] var1) throws IOException {
    super(getExtURLs(var1), (ClassLoader)null, Launcher.factory);
    SharedSecrets.getJavaNetAccess().getURLClassPath(this).initLookupCache(this);
}
```
getExtClassLoader:
```java
public static Launcher.ExtClassLoader getExtClassLoader() throws IOException {
    final File[] var0 = getExtDirs(); // 获取要加载的文件
    try {
        return (Launcher.ExtClassLoader)AccessController.doPrivileged(new PrivilegedExceptionAction<Launcher.ExtClassLoader>() {
            public Launcher.ExtClassLoader run() throws IOException {
                int var1 = var0.length;
			// 遍历创建的文件,并进行注册
                for(int var2 = 0; var2 < var1; ++var2) {
                    MetaIndex.registerDirectory(var0[var2]);
                }
			// 创建一个ExtClassLoader返回
                return new Launcher.ExtClassLoader(var0);
            }
        });
    } catch (PrivilegedActionException var2) {
        throw (IOException)var2.getException();
    }
}
```
addExtURL:
```java
void addExtURL(URL var1) {
    super.addURL(var1);
}
```
getExtDirs:
```java
private static File[] getExtDirs() {
    // 获取要加载的路径
    String var0 = System.getProperty("java.ext.dirs");
    File[] var1;
    if (var0 != null) {
        StringTokenizer var2 = new StringTokenizer(var0, File.pathSeparator);
        int var3 = var2.countTokens();
        var1 = new File[var3];
        // 遍历创建出文件夹中的文件对应的File
        for(int var4 = 0; var4 < var3; ++var4) {
            var1[var4] = new File(var2.nextToken());
        }
    } else {
        var1 = new File[0];
    }
    return var1;
}
```
getExtURLs:
```java
private static URL[] getExtURLs(File[] var0) throws IOException {
    Vector var1 = new Vector();
    for(int var2 = 0; var2 < var0.length; ++var2) {
        String[] var3 = var0[var2].list();
        if (var3 != null) {
            // 遍历创建好的File
            for(int var4 = 0; var4 < var3.length; ++var4) {
                if (!var3[var4].equals("meta-index")) {
                    File var5 = new File(var0[var2], var3[var4]);
                    // 添加创建好的文件的URL路径
                    var1.add(Launcher.getFileURL(var5));
                }
            }
        }
    }
    URL[] var6 = new URL[var1.size()];
    // var1中内容拷贝到var6
    var1.copyInto(var6);
    return var6;
}
```
findLibrary:
```java
// 加载库
public String findLibrary(String var1) {
    var1 = System.mapLibraryName(var1);
    URL[] var2 = super.getURLs();
    File var3 = null;
    for(int var4 = 0; var4 < var2.length; ++var4) {
        URI var5;
        try {
            var5 = var2[var4].toURI();
        } catch (URISyntaxException var9) {
            continue;
        }
        // 父路径文件
        File var6 = Paths.get(var5).toFile().getParentFile();
        if (var6 != null && !var6.equals(var3)) {
            String var7 = VM.getSavedProperty("os.arch");
            File var8;
            if (var7 != null) {
                var8 = new File(new File(var6, var7), var1);
                if (var8.exists()) {
                    return var8.getAbsolutePath();
                }
            }

            var8 = new File(var6, var1);
            if (var8.exists()) {
                return var8.getAbsolutePath();
            }
        }
        var3 = var6;
    }
    return null;
}
```
getContext:

```java
private static AccessControlContext getContext(File[] var0) throws IOException {
    PathPermissions var1 = new PathPermissions(var0);
    ProtectionDomain var2 = new ProtectionDomain(new CodeSource(var1.getCodeBase(), (Certificate[])null), var1);
    AccessControlContext var3 = new AccessControlContext(new ProtectionDomain[]{var2});
    return var3;
}
```



### Factory

field:

```java
private static String PREFIX = "sun.net.www.protocol";
```



构造函数

```java
        private Factory() {
        }
```



方法:

```java
public URLStreamHandler createURLStreamHandler(String var1) {
    String var2 = PREFIX + "." + var1 + ".Handler";
    try {
        // 加载类
        Class var3 = Class.forName(var2);
        return (URLStreamHandler)var3.newInstance();
    } catch (ReflectiveOperationException var4) {
        throw new InternalError("could not load " + var1 + "system protocol handler", var4);
    }
}
```

