# URLClassLoader

## FIeld
```java
    /* The search path for classes and resources */
	// 查找的路径
    private final URLClassPath ucp;

    /* The context to be used when loading classes and resources */
    private final AccessControlContext acc;

    /* A map (used as a set) to keep track of closeable local resources
     * (either JarFiles or FileInputStreams). We don't care about
     * Http resources since they don't need to be closed.
     *
     * If the resource is coming from a jar file
     * we keep a (weak) reference to the JarFile object which can
     * be closed if URLClassLoader.close() called. Due to jar file
     * caching there will typically be only one JarFile object
     * per underlying jar file.
     *
     * For file resources, which is probably a less common situation
     * we have to keep a weak reference to each stream.
     */
	// 记录可关闭的资源
    private WeakHashMap<Closeable,Void> closeables = new WeakHashMap<>();
```

静态初始化代码:

```java
    static {
        sun.misc.SharedSecrets.setJavaNetAccess (
            new sun.misc.JavaNetAccess() {
                public URLClassPath getURLClassPath (URLClassLoader u) {
                    return u.ucp;
                }

                public String getOriginalHostName(InetAddress ia) {
                    return ia.holder.getOriginalHostName();
                }
            }
        ); // 注册并行加载
        ClassLoader.registerAsParallelCapable();
    }
```



## 构造器

```java
    /* Constructs a new URLClassLoader for the given URLs. The URLs will be
     * searched in the order specified for classes and resources after first
     * searching in the specified parent class loader. Any URL that ends with
     * a '/' is assumed to refer to a directory. Otherwise, the URL is assumed
     * to refer to a JAR file which will be downloaded and opened as needed.*/
	public URLClassLoader(URL[] urls, ClassLoader parent) {
        super(parent);
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        this.acc = AccessController.getContext();
        ucp = new URLClassPath(urls, acc);
    }

    URLClassLoader(URL[] urls, ClassLoader parent,
                   AccessControlContext acc) {
        super(parent);
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        this.acc = acc;
        ucp = new URLClassPath(urls, acc);
    }

    public URLClassLoader(URL[] urls) {
        super();
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        this.acc = AccessController.getContext();
        ucp = new URLClassPath(urls, acc);
    }

    URLClassLoader(URL[] urls, AccessControlContext acc) {
        super();
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        this.acc = acc;
        ucp = new URLClassPath(urls, acc);
    }

    public URLClassLoader(URL[] urls, ClassLoader parent,
                          URLStreamHandlerFactory factory) {
        super(parent);
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        acc = AccessController.getContext();
        ucp = new URLClassPath(urls, factory, acc);
    }
```

## 功能函数

### getResourceAsStream

```java
    /* Returns an input stream for reading the specified resource.
     * If this loader is closed, then any resources opened by this method
     * will be closed.*/
	// 获取文件的输入流
	public InputStream getResourceAsStream(String name) {
        // 会先从父类查找
       	// 在从bootstrap Class loader查找
        // 最后就是自己查找
        URL url = getResource(name);
        try {
            if (url == null) { // 没有找到 
                return null;
            }
            // 找到资源继续进行操作
            // 打开连接
            URLConnection urlc = url.openConnection();
            // 获取输入流
            InputStream is = urlc.getInputStream();
            if (urlc instanceof JarURLConnection) {// jarfile
                JarURLConnection juc = (JarURLConnection)urlc;
                // 获取jarFile 对象
                JarFile jar = juc.getJarFile();
                synchronized (closeables) {
                    // 记录资源
                    if (!closeables.containsKey(jar)) {
                        closeables.put(jar, null);
                    }
                }
            }
            // 其他情况
            else if (urlc instanceof sun.net.www.protocol.file.FileURLConnection) 				{
                synchronized (closeables) { // 记录资源
                    closeables.put(is, null);
                }
            }
            return is;
        } catch (IOException e) {
            return null;
        }
    }
```

自己查找资源:

```java
     /* Finds the resource with the specified name on the URL search path.*/
	public URL findResource(final String name) {
        /* The same restriction to finding classes applies to resources*/
        URL url = AccessController.doPrivileged(
            new PrivilegedAction<URL>() {
                public URL run() {
                    // 获取文件url
                    return ucp.findResource(name, true);
                }
            }, acc);

        return url != null ? ucp.checkURL(url) : null;
    }
```

### close

```java
   /* Closes this URLClassLoader, so that it can no longer be used to load
    * new classes or resources that are defined by this loader.
    * Classes and resources defined by any of this loader's parents in the
    * delegation hierarchy are still accessible. Also, any classes or resources
    * that are already loaded, are still accessible.
    * <p>
    * In the case of jar: and file: URLs, it also closes any files
    * that were opened by it. If another thread is loading a
    * class when the {@code close} method is invoked, then the result of
    * that load is undefined.
    * <p>
    * The method makes a best effort attempt to close all opened files,
    * by catching {@link IOException}s internally. Unchecked exceptions
    * and errors are not caught. Calling close on an already closed
    * loader has no effect. */
	// 关闭此classLoader 并关闭打开的资源文件
	public void close() throws IOException {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkPermission(new RuntimePermission("closeClassLoader"));
        }
        List<IOException> errors = ucp.closeLoaders();

        // now close any remaining streams.
        synchronized (closeables) {
            Set<Closeable> keys = closeables.keySet();
            for (Closeable c : keys) { // 关闭资源文件
                try {
                    c.close();  // 关闭
                } catch (IOException ioex) {
                    errors.add(ioex); // 把错误记录
                }
            }
            closeables.clear(); // 清楚记录的文件
        }
        if (errors.isEmpty()) {
            return;
        }
        IOException firstex = errors.remove(0);

        // Suppress any remaining exceptions
        for (IOException error: errors) {
            firstex.addSuppressed(error);
        }
        throw firstex; // 把所有错误抛出
    }
```

### addURL

```java
    protected void addURL(URL url) {
        ucp.addURL(url);
    }

    public URL[] getURLs() {
        return ucp.getURLs();
    }
```

### getURLs

```java
   public URL[] getURLs() {
        return ucp.getURLs();
    }

```

### findClass

```java
    /* Finds and loads the class with the specified name from the URL search
     * path. Any URLs referring to JAR files are loaded and opened as needed
     * until the class is found. */
	// 找到特定的class并进行解析
    protected Class<?> findClass(final String name)
        throws ClassNotFoundException
    {
        final Class<?> result;
        try {
            result = AccessController.doPrivileged(
                new PrivilegedExceptionAction<Class<?>>() {
                    public Class<?> run() throws ClassNotFoundException {
                    	// 把路径转换为class全限定名
                        String path = name.replace('.', '/').concat(".class");
                        Resource res = ucp.getResource(path, false);
                        if (res != null) { // 资源找到
                            try {
                            	// 解析class
                                return defineClass(name, res);
                            } catch (IOException e) {
                                throw new ClassNotFoundException(name, e);
                            }
                        } else {
                            return null;
                        }
                    }
                }, acc);
        } catch (java.security.PrivilegedActionException pae) {
            throw (ClassNotFoundException) pae.getException();
        }
        if (result == null) {
            throw new ClassNotFoundException(name);
        }
        // 返回解析的类
        return result;
    }
```

```java
    /* Defines a Class using the class bytes obtained from the specified
     * Resource. The resulting Class must be resolved before it can be
     * used. */
	// 从资源中解析类
    private Class<?> defineClass(String name, Resource res) throws IOException {
        long t0 = System.nanoTime();
        // 最后一个.前是名字
        int i = name.lastIndexOf('.');
        URL url = res.getCodeSourceURL();
        if (i != -1) {
            // 包名
            String pkgname = name.substring(0, i);
            // Check if package already loaded.
            // 检查包是否已经加载
            Manifest man = res.getManifest();
            definePackageInternal(pkgname, man, url);
        }
        // Now read the class bytes and define the class
        // 获取class bytes到缓存中
        java.nio.ByteBuffer bb = res.getByteBuffer();
        if (bb != null) {
            // Use (direct) ByteBuffer:
            CodeSigner[] signers = res.getCodeSigners();
            CodeSource cs = new CodeSource(url, signers);
            sun.misc.PerfCounter.getReadClassBytesTime().addElapsedTimeFrom(t0);
            // 解析类
            // 追看一下,这里还是调用classLoader类中的native方法
            return defineClass(name, bb, cs);
        } else {
            byte[] b = res.getBytes();
            // must read certificates AFTER reading bytes.
            CodeSigner[] signers = res.getCodeSigners();
            CodeSource cs = new CodeSource(url, signers);
            sun.misc.PerfCounter.getReadClassBytesTime().addElapsedTimeFrom(t0);
            // 解析类
            // 追看一下,这里还是调用classLoader类中的native方法
            return defineClass(name, b, 0, b.length, cs);
        }
    }
```

### definePackageInternal

```java
    // Also called by VM to define Package for classes loaded from the CDS
    // archive
    private void definePackageInternal(String pkgname, Manifest man, URL url)
    {
        if (getAndVerifyPackage(pkgname, man, url) == null) {
            try {
                if (man != null) {
                    definePackage(pkgname, man, url);
                } else {
                  definePackage(pkgname, null, null, null, null, null, null, null);
                }
            } catch (IllegalArgumentException iae) {
                // parallel-capable class loaders: re-verify in case of a
                // race condition
                // 并发加载
                if (getAndVerifyPackage(pkgname, man, url) == null) {
                    // Should never happen
                 throw new AssertionError("Cannot find package " + pkgname);
                }
            }
        }
    }
```


getAndVerifyPackage

```java
    /* Retrieve the package using the specified package name.
     * If non-null, verify the package using the specified code
     * source and manifest.*/
	// 获取并验证包
    private Package getAndVerifyPackage(String pkgname,
                                        Manifest man, URL url) {
        // ClassLoader中的getPackage
        // 如果有父class loader,先从父loader中查看
        // 从system loader中查看
        Package pkg = getPackage(pkgname);
        if (pkg != null) { // 找到了
            // Package found, so check package sealing.
            // 校验
            if (pkg.isSealed()) {
                // Verify that code source URL is the same.
                if (!pkg.isSealed(url)) {
                    throw new SecurityException(
                        "sealing violation: package " + pkgname + " is sealed");
                }
            } else {
                // Make sure we are not attempting to seal the package
                // at this code source URL.
                if ((man != null) && isSealed(pkgname, man)) {
                    throw new SecurityException(
                        "sealing violation: can't seal package " + pkgname +
                        ": already loaded");
                }
            }
        }
        return pkg;
    }

    /* Returns true if the specified package name is sealed according to the
     * given manifest. */
    private boolean isSealed(String name, Manifest man) {
        String path = name.replace('.', '/').concat("/");
        Attributes attr = man.getAttributes(path);
        String sealed = null;
        if (attr != null) {
            sealed = attr.getValue(Name.SEALED);
        }
        if (sealed == null) {
            if ((attr = man.getMainAttributes()) != null) {
                sealed = attr.getValue(Name.SEALED);
            }
        }
        return "true".equalsIgnoreCase(sealed);
    }
```

definePackage

```java
    /* Defines a new package by name in this ClassLoader. The attributes
     * contained in the specified Manifest will be used to obtain package
     * version and sealing information. For sealed packages, the additional
     * URL specifies the code source URL from which the package was loaded.  */
	// 定义package
    protected Package definePackage(String name, Manifest man, URL url)
        throws IllegalArgumentException
    {
    	// 包路径
        String path = name.replace('.', '/').concat("/");
        String specTitle = null, specVersion = null, specVendor = null;
        String implTitle = null, implVersion = null, implVendor = null;
        String sealed = null;
        URL sealBase = null;
		// 获取记录的信息
		// 可以打开一个jar包看一下和这个Manifest文件
        Attributes attr = man.getAttributes(path);
        if (attr != null) {
            specTitle   = attr.getValue(Name.SPECIFICATION_TITLE);
            specVersion = attr.getValue(Name.SPECIFICATION_VERSION);
            specVendor  = attr.getValue(Name.SPECIFICATION_VENDOR);
            implTitle   = attr.getValue(Name.IMPLEMENTATION_TITLE);
            implVersion = attr.getValue(Name.IMPLEMENTATION_VERSION);
            implVendor  = attr.getValue(Name.IMPLEMENTATION_VENDOR);
            sealed      = attr.getValue(Name.SEALED);
        }
        attr = man.getMainAttributes();
        if (attr != null) {
        	// 分别获取需要的属性
            if (specTitle == null) {
                specTitle = attr.getValue(Name.SPECIFICATION_TITLE);
            }
            if (specVersion == null) {
                specVersion = attr.getValue(Name.SPECIFICATION_VERSION);
            }
            if (specVendor == null) {
                specVendor = attr.getValue(Name.SPECIFICATION_VENDOR);
            }
            if (implTitle == null) {
                implTitle = attr.getValue(Name.IMPLEMENTATION_TITLE);
            }
            if (implVersion == null) {
                implVersion = attr.getValue(Name.IMPLEMENTATION_VERSION);
            }
            if (implVendor == null) {
                implVendor = attr.getValue(Name.IMPLEMENTATION_VENDOR);
            }
            if (sealed == null) {
                sealed = attr.getValue(Name.SEALED);
            }
        }
        if ("true".equalsIgnoreCase(sealed)) {
            sealBase = url;
        }
        // 定义包
        // ClassLoader中的定义包方法
        // 直接调用 new 创建了一个对象
        return definePackage(name, specTitle, specVersion, specVendor,
                             implTitle, implVersion, implVendor, sealBase);
    }
```

### findResources

```java
    /* Returns an Enumeration of URLs representing all of the resources
     * on the URL search path having the specified name. */
    public Enumeration<URL> findResources(final String name)
        throws IOException
    {
        final Enumeration<URL> e = ucp.findResources(name, true);
        return new Enumeration<URL>() {
            private URL url = null;
			// 是否有下一个元素
            private boolean next() {
                if (url != null) {
                    return true;
                }
                do {
                    URL u = AccessController.doPrivileged(
                        new PrivilegedAction<URL>() {
                            public URL run() {
                                if (!e.hasMoreElements())
                                    return null;
                                return e.nextElement();
                            }
                        }, acc);
                    if (u == null)
                        break;
                    url = ucp.checkURL(u);
                } while (url == null);
                return url != null;
            }
			// 下一个url
            public URL nextElement() {
                if (!next()) {
                    throw new NoSuchElementException();
                }
                URL u = url;
                url = null;
                return u;
            }
			// 是否有下一个
            public boolean hasMoreElements() {
                return next();
            }
        };
    }
```

### getPermissions

```java
    /* Returns the permissions for the given codesource object.
     * The implementation of this method first calls super.getPermissions
     * and then adds permissions based on the URL of the codesource.
     * If the protocol of this URL is "jar", then the permission granted
     * is based on the permission that is required by the URL of the Jar file.
     * If the protocol is "file" and there is an authority component, then
     * permission to connect to and accept connections from that authority
     * may be granted. If the protocol is "file"
     * and the path specifies a file, then permission to read that
     * file is granted. If protocol is "file" and the path is
     * a directory, permission is granted to read all files
     * and (recursively) all files and subdirectories contained in
     * that directory.
     * If the protocol is not "file", then permission
     * to connect to and accept connections from the URL's host is granted.
     */
    protected PermissionCollection getPermissions(CodeSource codesource)
    {
        PermissionCollection perms = super.getPermissions(codesource);
        URL url = codesource.getLocation();
        Permission p;
        URLConnection urlConnection;
        try {
            // 打开连接
            urlConnection = url.openConnection();
            // 获取权限
            p = urlConnection.getPermission();
        } catch (java.io.IOException ioe) {
            p = null;
            urlConnection = null;
        }

        if (p instanceof FilePermission) { // 文件权限
            // if the permission has a separator char on the end,
            // it means the codebase is a directory, and we need
            // to add an additional permission to read recursively
            String path = p.getName();
            if (path.endsWith(File.separator)) {
                path += "-";
                p = new FilePermission(path, SecurityConstants.FILE_READ_ACTION);
            }
            // 文件权限
        } else if ((p == null) && (url.getProtocol().equals("file"))) {
            String path = url.getFile().replace('/', File.separatorChar);
            path = ParseUtil.decode(path);
            if (path.endsWith(File.separator))
                path += "-";
            p =  new FilePermission(path, SecurityConstants.FILE_READ_ACTION);
        } else {
            /* Not loading from a 'file:' URL so we want to give the class
             * permission to connect to and accept from the remote host
             * after we've made sure the host is the correct one and is valid.*/
            URL locUrl = url;
            // jar包
            if (urlConnection instanceof JarURLConnection) {
                locUrl = ((JarURLConnection)urlConnection).getJarFileURL();
            }
            String host = locUrl.getHost();
            if (host != null && (host.length() > 0))
                p = new SocketPermission(host,
                          SecurityConstants.SOCKET_CONNECT_ACCEPT_ACTION);
        }
        // make sure the person that created this class loader
        // would have this permission
        if (p != null) { // 权限检查
            final SecurityManager sm = System.getSecurityManager();
            if (sm != null) {
                final Permission fp = p;
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() throws SecurityException {
                        sm.checkPermission(fp);
                        return null;
                    }
                }, acc);
            }
            perms.add(p);
        }
        return perms;
    }
```

### newInstance

```java
    /** Creates a new instance of URLClassLoader for the specified
     * URLs and parent class loader. If a security manager is
     * installed, the {@code loadClass} method of the URLClassLoader
     * returned by this method will invoke the
     * {@code SecurityManager.checkPackageAccess} method before
     * loading the class. */
	// 实例化方法
    public static URLClassLoader newInstance(final URL[] urls,
                                             final ClassLoader parent) {
        // Save the caller's context
        final AccessControlContext acc = AccessController.getContext();
        // Need a privileged block to create the class loader
        URLClassLoader ucl = AccessController.doPrivileged(
            new PrivilegedAction<URLClassLoader>() {
                public URLClassLoader run() {
                    // 工厂方法
                    return new FactoryURLClassLoader(urls, parent, acc);
                }
            });
        return ucl;
    }
```

```java
   /* Creates a new instance of URLClassLoader for the specified
     * URLs and default parent class loader. If a security manager is
     * installed, the {@code loadClass} method of the URLClassLoader
     * returned by this method will invoke the
     * {@code SecurityManager.checkPackageAccess} before
     * loading the class.*/
    public static URLClassLoader newInstance(final URL[] urls) {
        // Save the caller's context
        final AccessControlContext acc = AccessController.getContext();
        // Need a privileged block to create the class loader
        URLClassLoader ucl = AccessController.doPrivileged(
            new PrivilegedAction<URLClassLoader>() {
                public URLClassLoader run() {
                    // 工厂方法
                    return new FactoryURLClassLoader(urls, acc);
                }
            });
        return ucl;
    }
```



## 工厂类函数

静态初始化函数:

```java
    static {
        ClassLoader.registerAsParallelCapable();
    }
```

### 构造函数
```java
    FactoryURLClassLoader(URL[] urls, ClassLoader parent,
                          AccessControlContext acc) {
        super(urls, parent, acc); // 所以，这里就是调用的URLClassLoader的构造方法
    }

    FactoryURLClassLoader(URL[] urls, AccessControlContext acc) {
        super(urls, acc);
    }
```

class父类:

```java
final class FactoryURLClassLoader extends URLClassLoader
```

### 功能方法

```java
    public final Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        // First check if we have permission to access the package. This
        // should go away once we've added support for exported packages.
        SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            int i = name.lastIndexOf('.');
            if (i != -1) {
                sm.checkPackageAccess(name.substring(0, i));
            }
        }
        // 调用URLClassLoader的loadClass方法加载类
        return super.loadClass(name, resolve);
    }
```
