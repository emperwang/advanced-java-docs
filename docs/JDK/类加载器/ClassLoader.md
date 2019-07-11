# ClassLoader

## Field

```java
    // 父类加载器
	private final ClassLoader parent;
    // Maps class name to the corresponding lock object when the current
    // class loader is parallel capable.
	// 并行加载时使用
    private final ConcurrentHashMap<String, Object> parallelLockMap;

    // Hashtable that maps packages to certs
	// 包 和 certs的映射
    private final Map <String, Certificate[]> package2certs;

    // Shared among all packages with unsigned classes
	// 所有包共享
    private static final Certificate[] nocerts = new Certificate[0];

    // The classes loaded by this class loader. The only purpose of this table
    // is to keep the classes from being GC'ed until the loader is GC'ed.
	// 保存此加载器加载的class
    private final Vector<Class<?>> classes = new Vector<>();

    // The "default" domain. Set as the default ProtectionDomain on newly
    // created classes.
	// 新创建class的域
    private final ProtectionDomain defaultDomain =
        new ProtectionDomain(new CodeSource(null, (Certificate[]) null),
                             null, this, null);

    // The initiating protection domains for all classes loaded by this loader
	// 被此加载器加载的class的初始化保护域
    private final Set<ProtectionDomain> domains;

    // The packages defined in this class loader.  Each package name is mapped
    // to its corresponding Package object.
    // @GuardedBy("itself")
	// 被此加载器加载的class的包 和 package 对象的映射
    private final HashMap<String, Package> packages = new HashMap<>();
    // The class loader for the system
    // @GuardedBy("ClassLoader.class")
	// 从系统获取的加载器
    private static ClassLoader scl;

    // Set to true once the system class loader has been set
    // @GuardedBy("ClassLoader.class")
	// 当 System class loader 被设置时，此属性为true
    private static boolean sclSet;
   // All native library names we've loaded.
	// 所有本地加载的本地库名字
    private static Vector<String> loadedLibraryNames = new Vector<>();

    // Native libraries belonging to system classes.
	// 被系统加载器加载的库的名字
    private static Vector<NativeLibrary> systemNativeLibraries
        = new Vector<>();

    // Native libraries associated with the class loader.
    private Vector<NativeLibrary> nativeLibraries = new Vector<>();

    // native libraries being loaded/unloaded.
	// 要被加载或卸载的本地库
    private static Stack<NativeLibrary> nativeLibraryContext = new Stack<>();

    // The paths searched for libraries
	// 搜索库的路径
    private static String usr_paths[];
    private static String sys_paths[];
    final Object assertionLock;

    // The default toggle for assertion checking.
    // @GuardedBy("assertionLock")
    private boolean defaultAssertionStatus = false;
   // Maps String packageName to Boolean package default assertion status Note
    // that the default package is placed under a null map key.  If this field
    // is null then we are delegating assertion status queries to the VM, i.e.,
    // none of this ClassLoader's assertion status modification methods have
    // been invoked.
    // @GuardedBy("assertionLock")
    private Map<String, Boolean> packageAssertionStatus = null;

    // Maps String fullyQualifiedClassName to Boolean assertionStatus If this
    // field is null then we are delegating assertion status queries to the VM,
    // i.e., none of this ClassLoader's assertion status modification methods
    // have been invoked.
    // @GuardedBy("assertionLock")
    Map<String, Boolean> classAssertionStatus = null;
```

静态初始化代码:

```java
    private static native void registerNatives();
    static {
        registerNatives();  // 注册本地函数
    }
```



## 构造函数

```java
    protected ClassLoader(ClassLoader parent) {
        this(checkCreateClassLoader(), parent);
    }

    protected ClassLoader() {
        this(checkCreateClassLoader(), getSystemClassLoader());
    }

    private ClassLoader(Void unused, ClassLoader parent) {
        this.parent = parent;
        // 是否并行加载类
        // 如果是,则需要对相关的field进行初始化
        if (ParallelLoaders.isRegistered(this.getClass())) {
            parallelLockMap = new ConcurrentHashMap<>();
            package2certs = new ConcurrentHashMap<>();
            domains =
                Collections.synchronizedSet(new HashSet<ProtectionDomain>());
            assertionLock = new Object();
        } else {
            // no finer-grained lock; lock on the classloader instance
            parallelLockMap = null;
            package2certs = new Hashtable<>();
            domains = new HashSet<>();
            assertionLock = this;
        }
    }
```



## 功能函数

### addClass

```java
    // Invoked by the VM to record every loaded class with this loader.
	// 此类被VM调用,用来记录此加载器加载的class
	void addClass(Class<?> c) {
        classes.addElement(c);
    }
```



### checkCreateClassLoader

```java
    private static Void checkCreateClassLoader() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            // 检查创建的类加载器
            security.checkCreateClassLoader();
        }
        return null;
    }
```

### loadClass

```java
    // 此类被JVM调用来解析class的引用.
	public Class<?> loadClass(String name) throws ClassNotFoundException {
        return loadClass(name, false);
    }
```

```java
    // 参数: name--表示类型, resolve 表示是否解析类
	protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        synchronized (getClassLoadingLock(name)) {
            // First, check if the class has already been loaded
            // 查看类是否已经被加载
            Class<?> c = findLoadedClass(name);
            if (c == null) { // 没有被加载
                long t0 = System.nanoTime();
                try {
                    if (parent != null) {
                    	// 委托父加载器进行加载
                        c = parent.loadClass(name, false);
                    } else {
                    	// 没有父类则调用 BootStrap加载器
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }

                if (c == null) { // 如果还没有找到
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    long t1 = System.nanoTime();
                    // 本地方法开始进行查找
                    c = findClass(name);
                    // this is the defining class loader; record the stats
                    sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                    sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                    sun.misc.PerfCounter.getFindClasses().increment();
                }
            }
            if (resolve) {
            // 解析类
                resolveClass(c);
            }
            return c;
        }
    }
    
	// 加载类是获取的锁
	// 如果是并行加载,那么锁就是多把
	// 如果不是呢,锁就是一把
    protected Object getClassLoadingLock(String className) {
        Object lock = this;
        if (parallelLockMap != null) {
            Object newLock = new Object();
            // 保存锁
            lock = parallelLockMap.putIfAbsent(className, newLock);
            if (lock == null) {
                lock = newLock;
            }
        }
        return lock;
    }
```

### findLoadedClass

```java
    /* Returns the class with the given binary name if this
     * loader has been recorded by the Java virtual machine as an initiating
     * loader of a class with that binary name.  Otherwise
     * null is returned.*/
	// 如果加载了则返回类型,没有则返回null
	protected final Class<?> findLoadedClass(String name) {
        if (!checkName(name))
            return null;
        return findLoadedClass0(name);
    }

    private native final Class<?> findLoadedClass0(String name);
```

### findBootstrapClassOrNull

```java
    /**
     * Returns a class loaded by the bootstrap class loader;
     * or return null if not found.
     */
	// 如果被bootstrap class loader加载了,则返回类名;没有加载则返回null
	private Class<?> findBootstrapClassOrNull(String name)
    {
        if (!checkName(name)) return null;

        return findBootstrapClass(name);
    }

    // return null if not found
    private native Class<?> findBootstrapClass(String name);
```

### findClass

```java
   // 需要由具体的子类去实现
	protected Class<?> findClass(String name) throws ClassNotFoundException {
        throw new ClassNotFoundException(name);
    }
```

### resolveClass

```java
    /**
     * Links the specified class.  This (misleadingly named) method may be
     * used by a class loader to link a class.  If the class c has
     * already been linked, then this method simply returns. Otherwise, the
     * class is linked as described in the "Execution" chapter of
     * <cite>The Java&trade; Language Specification</cite>.
     */
	// 解析类
    protected final void resolveClass(Class<?> c) {
        resolveClass0(c);
    }

    private native void resolveClass0(Class<?> c);
```

### getSystemClassLoader

```java
    public static ClassLoader getSystemClassLoader() {
        // 初始化系统类加载器
        initSystemClassLoader();
        if (scl == null) {
            return null;
        }
        SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            // 检查权限
            checkClassLoaderPermission(scl, Reflection.getCallerClass());
        }
        return scl;
    }
	
	// 初始化系统类加载器
    private static synchronized void initSystemClassLoader() {
        if (!sclSet) {
            if (scl != null)
                throw new IllegalStateException("recursive invocation");
            // 获取加载器
            sun.misc.Launcher l = sun.misc.Launcher.getLauncher();
            if (l != null) {
                Throwable oops = null;
                // 获取加载器
                scl = l.getClassLoader();
                try {
                    // 创建SystemClassLoaderAction
                    scl = AccessController.doPrivileged(
                        new SystemClassLoaderAction(scl));
                } catch (PrivilegedActionException pae) {
                    oops = pae.getCause();
                    if (oops instanceof InvocationTargetException) {
                        oops = oops.getCause();
                    }
                }
                if (oops != null) {
                    if (oops instanceof Error) {
                        throw (Error) oops;
                    } else {
                        // wrap the exception
                        throw new Error(oops);
                    }
                }
            }
            sclSet = true;
        }
    }
```

### loadClassInternal

```java
    // This method is invoked by the virtual machine to load a class.
	// 此类被JVM调用,来加载class
    private Class<?> loadClassInternal(String name)
        throws ClassNotFoundException
    {
        // For backward compatibility, explicitly lock on 'this' when
        // the current class loader is not parallel capable.
        if (parallelLockMap == null) {
            synchronized (this) { // 如果不是并行加载类,则需要加锁,再去加载
                 return loadClass(name);
            }
        } else {
            return loadClass(name);
        }
    }

```

### checkPackageAccess

```java
  // Invoked by the VM after loading class with this loader.
    private void checkPackageAccess(Class<?> cls, ProtectionDomain pd) {
        final SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            if (ReflectUtil.isNonPublicProxyClass(cls)) {
                for (Class<?> intf: cls.getInterfaces()) {
                    checkPackageAccess(intf, pd);
                }
                return;
            }
            final String name = cls.getName();
            final int i = name.lastIndexOf('.');
            if (i != -1) {
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() {
                        sm.checkPackageAccess(name.substring(0, i));
                        return null;
                    }
                }, new AccessControlContext(new ProtectionDomain[] {pd}));
            }
        }
        domains.add(pd);
    }
```

### defineClass

```java
     /* Converts an array of bytes into an instance of class <tt>Class</tt>.
     * Before the <tt>Class</tt> can be used it must be resolved. */
	protected final Class<?> defineClass(String name, byte[] b, int off, int len)
        throws ClassFormatError
    {
        return defineClass(name, b, off, len, null);
    }
    
	// 解析字节到一个class
    protected final Class<?> defineClass(String name, byte[] b, int off, int len,
                                         ProtectionDomain protectionDomain)
        throws ClassFormatError
    {	
    	// 先决定此class的保护域,定义前所作的操作
        protectionDomain = preDefineClass(name, protectionDomain);
        // 定义源
        String source = defineClassSourceLocation(protectionDomain);
        // 具体的解析
        Class<?> c = defineClass1(name, b, off, len, protectionDomain, source);
        // 定义之后的操作
        postDefineClass(c, protectionDomain);
        return c;
    }
    
	// 本地方法解析类
    private native Class<?> defineClass1(String name, byte[] b, int off, int len,
                                         ProtectionDomain pd, String source);
```

```java
    // 把buffer中的内容解析出来
	protected final Class<?> defineClass(String name, java.nio.ByteBuffer b,
                                         ProtectionDomain protectionDomain)
        throws ClassFormatError
    {
        int len = b.remaining(); // 获取可用的数据长度
        // Use byte[] if not a direct ByteBufer:
        if (!b.isDirect()) {
            if (b.hasArray()) {
           	 // 把内容转换为数组,并调用上一个定义方法定义
                return defineClass(name, b.array(),
                                   b.position() + b.arrayOffset(), len,
                                   protectionDomain);
            } else {
                // no array, or read-only array
                byte[] tb = new byte[len];
                b.get(tb);  // get bytes out of byte buffer.
                return defineClass(name, tb, 0, len, protectionDomain);
            }
        }
		// 获取保护域,定义前
        protectionDomain = preDefineClass(name, protectionDomain);
        String source = defineClassSourceLocation(protectionDomain);
        // 定义
        Class<?> c = defineClass2(name, b, b.position(), len, protectionDomain, source);
        // 设置签名
        postDefineClass(c, protectionDomain);
        return c;
    }
    // 定义class方法
    private native Class<?> defineClass2(String name, java.nio.ByteBuffer b,
                                         int off, int len, ProtectionDomain pd,
                                         String source);
```



### preDefineClass

```java
    /* Determine protection domain, and check that:
        - not define java.* class,
        - signer of this class matches signers for the rest of the classes in
          package.
    */
private ProtectionDomain preDefineClass(String name, ProtectionDomain pd) {
    if (!checkName(name))
        throw new NoClassDefFoundError("IllegalName: " + name);

    // Note:  Checking logic in java.lang.invoke.MemberName.checkForTypeAlias
    // relies on the fact that spoofing is impossible if a class has a name
    // of the form "java.*"
    // 不能使用java开头的包
    if ((name != null) && name.startsWith("java.")) {
        throw new SecurityException
            ("Prohibited package name: " +
             name.substring(0, name.lastIndexOf('.')));
    }
    if (pd == null) {
        pd = defaultDomain;
    }
    if (name != null) checkCerts(name, pd.getCodeSource());
    return pd;
}


    // true if the name is null or has the potential to be a valid binary name
	// 检查名字
    private boolean checkName(String name) {
        if ((name == null) || (name.length() == 0))
            return true;
        if ((name.indexOf('/') != -1)
            || (!VM.allowArraySyntax() && (name.charAt(0) == '[')))
            return false;
        return true;
    }


    private void checkCerts(String name, CodeSource cs) {
        int i = name.lastIndexOf('.');
        String pname = (i == -1) ? "" : name.substring(0, i);

        Certificate[] certs = null;
        if (cs != null) {
            certs = cs.getCertificates();
        }
        Certificate[] pcerts = null;
        if (parallelLockMap == null) {  // 不是并行加载,则加锁
            synchronized (this) {
                pcerts = package2certs.get(pname);
                if (pcerts == null) {
                    package2certs.put(pname, (certs == null? nocerts:certs));
                }
            }
        } else {
            pcerts = ((ConcurrentHashMap<String, Certificate[]>)package2certs).
                putIfAbsent(pname, (certs == null? nocerts:certs));
        }
        if (pcerts != null && !compareCerts(pcerts, certs)) {
            throw new SecurityException("class \""+ name +
                 "\"'s signer information does not match signer information of other classes in the same package");
        }
    }
```

### defineClassSourceLocation

```java
    private String defineClassSourceLocation(ProtectionDomain pd)
    {
        CodeSource cs = pd.getCodeSource();
        String source = null;
        if (cs != null && cs.getLocation() != null) {
            source = cs.getLocation().toString();
        }
        return source;
    }

```

### postDefineClass

```java
    private void postDefineClass(Class<?> c, ProtectionDomain pd)
    {	
        // 设置签名
        if (pd.getCodeSource() != null) {
            Certificate certs[] = pd.getCodeSource().getCertificates();
            if (certs != null)
                setSigners(c, certs);
        }
    }
```

### findSystemClass

```java
    /* Finds a class with the specified binary name,
     * loading it if necessary.
     * This method loads the class through the system class loader (see
     * getSystemClassLoader().  The Class object returned
     * might have more than one ClassLoader associated with it.
     * Subclasses of ClassLoader need not usually invoke this method,
     * because most class loaders need to override just 
     * findClass(String) */
	// 使用 system Class Loader 加载找到的类
	protected final Class<?> findSystemClass(String name)
        throws ClassNotFoundException
    {
        ClassLoader system = getSystemClassLoader();
        if (system == null) {
            if (!checkName(name))
                throw new ClassNotFoundException(name);
                // bootstrap class loader 加载class
            Class<?> cls = findBootstrapClass(name);
            if (cls == null) {
                throw new ClassNotFoundException(name);
            }
            return cls;
        }
        // 系统类加载
        return system.loadClass(name);
    }
    
    // return null if not found
    private native Class<?> findBootstrapClass(String name);
```

### getResource

```java
    /* Finds the resource with the given name.  A resource is some data
     * (images, audio, text, etc) that can be accessed by class code in a way
     * that is independent of the location of the code.
     *
     * The name of a resource is a '/'-separated path name that
     * identifies the resource.
     *
     * This method will first search the parent class loader for the
     * resource; if the parent is null the path of the class loader
     * built-in to the virtual machine is searched.  That failing, this method
     * will invoke findResource(String) to find the resource. */
	// 加载资源前先看parent是否加载此资源
	// parent每找到就从JVM 内部的加载器查找
	// 再找不到就自己查找了
	public URL getResource(String name) {
        URL url;
        if (parent != null) {
            // 父类先查找
            url = parent.getResource(name);
        } else {
            // jvm 内查找
            url = getBootstrapResource(name);
        }
        if (url == null) {
            // 还每找到,就自己查找
            url = findResource(name);
        }
        return url;
    }

    /**
     * Find resources from the VM's built-in classloader.
     */
    private static URL getBootstrapResource(String name) {
        URLClassPath ucp = getBootstrapClassPath();
        Resource res = ucp.getResource(name);
        return res != null ? res.getURL() : null;
    }

    // Returns the URLClassPath that is used for finding system resources.
    static URLClassPath getBootstrapClassPath() {
        return sun.misc.Launcher.getBootstrapClassPath();
    }
// 此类就需要子类去实现了
    protected URL findResource(String name) {
        return null;
    }
```

```java
    // 根据名字找到所有资源,可能不止一个
	public Enumeration<URL> getResources(String name) throws IOException {
        @SuppressWarnings("unchecked")
        Enumeration<URL>[] tmp = (Enumeration<URL>[]) new Enumeration<?>[2];
        if (parent != null) {
            tmp[0] = parent.getResources(name);
        } else {
            tmp[0] = getBootstrapResources(name);
        }
        tmp[1] = findResources(name);

        return new CompoundEnumeration<>(tmp);
    }
```

### registerAsParallelCapable

```java
    /* Registers the caller as parallel capable.
     * The registration succeeds if and only if all of the following
     * conditions are met:
     * <ol>
     * <li> no instance of the caller has been created</li>
     * <li> all of the super classes (except class Object) of the caller are
     * registered as parallel capable</li>
     * </ol>
     * Note that once a class loader is registered as parallel capable, there
     * is no way to change it back.*/
	protected static boolean registerAsParallelCapable() {
        Class<? extends ClassLoader> callerClass =
            Reflection.getCallerClass().asSubclass(ClassLoader.class);
        return ParallelLoaders.register(callerClass);
    }
```

### definePackage

```java
     /* Defines a package by name in this <tt>ClassLoader</tt>.  This allows
     * class loaders to define the packages for their classes. Packages must
     * be created before the class is defined, and package names must be
     * unique within a class loader and cannot be redefined or changed once
     * created.*/
	// 在class被解析前,先定义package
 	protected Package definePackage(String name, String specTitle,
                                    String specVersion, String specVendor,
                                    String implTitle, String implVersion,
                                    String implVendor, URL sealBase)
        throws IllegalArgumentException
    {
        synchronized (packages) {
            Package pkg = getPackage(name);
            if (pkg != null) {
                throw new IllegalArgumentException(name);
            }
            // 创建package object
            pkg = new Package(name, specTitle, specVersion, specVendor,
                              implTitle, implVersion, implVendor,
                              sealBase, this);
			// 放入容器中存储
            packages.put(name, pkg);
            return pkg;
        }
    }
```

```java
    /* Returns a Package that has been defined by this class loader
     * or any of its ancestors.*/
	// 查看package 是否已经被此classLoader定义了
	protected Package getPackage(String name) {
        Package pkg;
        synchronized (packages) {
            pkg = packages.get(name);
        }
        if (pkg == null) {
            if (parent != null) {
                // 从父加载器查看依一下
                pkg = parent.getPackage(name);
            } else {
                // 查看是否被系统加载器加载
                // 加载了,则返回对象
                pkg = Package.getSystemPackage(name);
            }
            if (pkg != null) {
                synchronized (packages) {
                    Package pkg2 = packages.get(name);
                    if (pkg2 == null) {
                        packages.put(name, pkg);
                    } else {
                        pkg = pkg2;
                    }
                }
            }
        }
        return pkg;
    }
```

### initializePath

```java
   // 初始化路径
	private static String[] initializePath(String propname) {
        String ldpath = System.getProperty(propname, "");
        String ps = File.pathSeparator;
        int ldlen = ldpath.length();
        int i, j, n;
        // Count the separators in the path
        i = ldpath.indexOf(ps);
        n = 0;
        while (i >= 0) {
            n++;
            i = ldpath.indexOf(ps, i + 1);
        }

        // allocate the array of paths - n :'s = n + 1 path elements
        String[] paths = new String[n + 1];

        // Fill the array with paths from the ldpath
        n = i = 0;
        j = ldpath.indexOf(ps);
        while (j >= 0) {
            if (j - i > 0) {
                paths[n++] = ldpath.substring(i, j);
            } else if (j - i == 0) {
                paths[n++] = ".";
            }
            i = j + 1;
            j = ldpath.indexOf(ps, i);
        }
        paths[n] = ldpath.substring(i, ldlen);
        return paths;
    }
```

### loadLibrary

```java
    // Invoked in the java.lang.Runtime class to implement load and loadLibrary.
    static void loadLibrary(Class<?> fromClass, String name,
                            boolean isAbsolute) {
        // 获取加载器
        ClassLoader loader =
            (fromClass == null) ? null : fromClass.getClassLoader();
        // 初始化路径
        if (sys_paths == null) {
            usr_paths = initializePath("java.library.path");
            sys_paths = initializePath("sun.boot.library.path");
        }
        if (isAbsolute) {
            // 加载
            if (loadLibrary0(fromClass, new File(name))) {
                return;
            }
            throw new UnsatisfiedLinkError("Can't load library: " + name);
        }
        if (loader != null) {
            // 加载操作
            String libfilename = loader.findLibrary(name);
            if (libfilename != null) {
                File libfile = new File(libfilename);
                if (!libfile.isAbsolute()) {
                    throw new UnsatisfiedLinkError(
    "ClassLoader.findLibrary failed to return an absolute path: " + libfilename);
                }
                if (loadLibrary0(fromClass, libfile)) {
                    return;
                }
                throw new UnsatisfiedLinkError("Can't load " + libfilename);
            }
        }
        // 遍历系统路径进行查找并加载
        for (int i = 0 ; i < sys_paths.length ; i++) {
            File libfile = new File(sys_paths[i], System.mapLibraryName(name));
            if (loadLibrary0(fromClass, libfile)) {
                return;
            }
            libfile = ClassLoaderHelper.mapAlternativeName(libfile);
            if (libfile != null && loadLibrary0(fromClass, libfile)) {
                return;
            }
        }
        // 遍历用户路径进行查找加载
        if (loader != null) {
            for (int i = 0 ; i < usr_paths.length ; i++) {
                File libfile = new File(usr_paths[i],
                                        System.mapLibraryName(name));
                if (loadLibrary0(fromClass, libfile)) {
                    return;
                }
                libfile = ClassLoaderHelper.mapAlternativeName(libfile);
                if (libfile != null && loadLibrary0(fromClass, libfile)) {
                    return;
                }
            }
        }
        // Oops, it failed
        throw new UnsatisfiedLinkError("no " + name + " in java.library.path");
    }
```

```java
    // 从文件中加载class
	private static boolean loadLibrary0(Class<?> fromClass, final File file) {
        // Check to see if we're attempting to access a static library
        String name = findBuiltinLib(file.getName());
        boolean isBuiltin = (name != null);
        if (!isBuiltin) {
            boolean exists = AccessController.doPrivileged(
                new PrivilegedAction<Object>() {
                    public Object run() {
                        return file.exists() ? Boolean.TRUE : null;
                    }})
                != null;
            if (!exists) {
                return false;
            }
            try {
                // 路径
                name = file.getCanonicalPath();
            } catch (IOException e) {
                return false;
            }
        }
        ClassLoader loader =
            (fromClass == null) ? null : fromClass.getClassLoader();
        Vector<NativeLibrary> libs =
            loader != null ? loader.nativeLibraries : systemNativeLibraries;
        // 查看是否已经被加载
        synchronized (libs) {
            int size = libs.size();
            for (int i = 0; i < size; i++) {
                NativeLibrary lib = libs.elementAt(i);
                if (name.equals(lib.name)) {
                    return true;
                }
            }

            synchronized (loadedLibraryNames) {
                if (loadedLibraryNames.contains(name)) {
                    throw new UnsatisfiedLinkError
                        ("Native Library " +
                         name +
                         " already loaded in another classloader");
                }
                /* If the library is being loaded (must be by the same thread,
                 * because Runtime.load and Runtime.loadLibrary are
                 * synchronous). The reason is can occur is that the JNI_OnLoad
                 * function can cause another loadLibrary invocation.
                 * Thus we can use a static stack to hold the list of libraries
                 * we are loading.
                 * If there is a pending load operation for the library, we
                 * immediately return success; otherwise, we raise
                 * UnsatisfiedLinkError.
                 */
                int n = nativeLibraryContext.size();
                for (int i = 0; i < n; i++) {
                    NativeLibrary lib = nativeLibraryContext.elementAt(i);
                    if (name.equals(lib.name)) {
                        if (loader == lib.fromClass.getClassLoader()) {
                            return true;
                        } else {
                            throw new UnsatisfiedLinkError
                                ("Native Library " +
                                 name +
                                 " is being loaded in another classloader");
                        }
                    }
                }
                // 把本类创建为NativeLibrary
                NativeLibrary lib = new NativeLibrary(fromClass, name, isBuiltin);
                // 存储起来
                nativeLibraryContext.push(lib);
                try {
                    // 加载
                    lib.load(name, isBuiltin);
                } finally {
                    nativeLibraryContext.pop();
                }
                if (lib.loaded) {
                    loadedLibraryNames.addElement(name);
                    libs.addElement(lib);
                    return true;
                }
                return false;
            }
        }
    }

    private static native String findBuiltinLib(String name);
```

### findNative

```java
    // Invoked in the VM class linking code.
    static long findNative(ClassLoader loader, String name) {
        Vector<NativeLibrary> libs =
            loader != null ? loader.nativeLibraries : systemNativeLibraries;
        synchronized (libs) {
            int size = libs.size();
            for (int i = 0; i < size; i++) {
                NativeLibrary lib = libs.elementAt(i);
                long entry = lib.find(name);
                if (entry != 0)
                    return entry;
            }
        }
        return 0;
    }
```



### 内部类

#### ParallelLoads

##### Field

```java
// the set of parallel capable loader types
private static final Set<Class<? extends ClassLoader>> loaderTypes =
    Collections.newSetFromMap(
    new WeakHashMap<Class<? extends ClassLoader>, Boolean>());
```

静态初始化代码:

```java
static {
    synchronized (loaderTypes) { loaderTypes.add(ClassLoader.class); }
}
```

##### 构造函数

```java
        private ParallelLoaders() {}
```

##### 功能方法

注册:

```java
        /* Registers the given class loader type as parallel capabale.
         * Returns  true is successfully registered; {@code false} if
         * loader's super class is not registered.
         */
        static boolean register(Class<? extends ClassLoader> c) {
            synchronized (loaderTypes) {
                if (loaderTypes.contains(c.getSuperclass())) {
                    // register the class loader as parallel capable
                    // if and only if all of its super classes are.
                    // Note: given current classloading sequence, if
                    // the immediate super class is parallel capable,
                    // all the super classes higher up must be too.
                    loaderTypes.add(c);
                    return true;
                } else {
                    return false;
                }
            }
        }

        /**
         * Returns {@code true} if the given class loader type is
         * registered as parallel capable.
         */
        static boolean isRegistered(Class<? extends ClassLoader> c) {
            synchronized (loaderTypes) {
                return loaderTypes.contains(c);
            }
        }
```



#### NativeLibrary
##### Field

```java
        // opaque handle to native library, used in native code.
		// 在native方法中使用
        long handle;
        // the version of JNI environment the native library requires.
        private int jniVersion;
        // the class from which the library is loaded, also indicates
        // the loader this native library belongs.
		// 要加载的类
        private final Class<?> fromClass;
        // the canonicalized name of the native library.
        // or static library name
	// library名字
        String name;
        // Indicates if the native library is linked into the VM
		// 标识是不是 VM连接的本地库
        boolean isBuiltin;
        // Indicates if the native library is loaded
		// 是否已经加载
        boolean loaded;
```

##### 构造函数

```java
        public NativeLibrary(Class<?> fromClass, String name, boolean isBuiltin) {
            this.name = name;
            this.fromClass = fromClass;
            this.isBuiltin = isBuiltin;
        }
```

##### 功能方法

加载-查找-卸载的本地方法:

```java
        native void load(String name, boolean isBuiltin);

        native long find(String name);
        native void unload(String name, boolean isBuiltin);
```

getFromClass:

```java
        // Invoked in the VM to determine the context class in
        // JNI_Load/JNI_Unload
        static Class<?> getFromClass() {
            return ClassLoader.nativeLibraryContext.peek().fromClass;
        }
```

finalize

```java
    // 卸载类    
	protected void finalize() {
            synchronized (loadedLibraryNames) {
                if (fromClass.getClassLoader() != null && loaded) {
                    /* remove the native library name */
                    int size = loadedLibraryNames.size();
                    for (int i = 0; i < size; i++) {
                        if (name.equals(loadedLibraryNames.elementAt(i))) {
                            loadedLibraryNames.removeElementAt(i);
                            break;
                        }
                    }
                    /* unload the library. */
                    ClassLoader.nativeLibraryContext.push(this);
                    try {
                        unload(name, isBuiltin);
                    } finally {
                        ClassLoader.nativeLibraryContext.pop();
                    }
                }
            }
        }
```




## SystemClassLoaderAction

### Field

```java
    private ClassLoader parent;
```



### 构造函数

```java
    SystemClassLoaderAction(ClassLoader parent) {
        this.parent = parent;
    }
```



### 功能函数

```java
    public ClassLoader run() throws Exception {
        String cls = System.getProperty("java.system.class.loader");
        if (cls == null) {
            return parent;
        }
		// 获取类构造函数
        Constructor<?> ctor = Class.forName(cls, true, parent)
            .getDeclaredConstructor(new Class<?>[] { ClassLoader.class });
        // 创建类加载器实例
        ClassLoader sys = (ClassLoader) ctor.newInstance(
            new Object[] { parent });
        // 设置当前线程的类加载为sys
        Thread.currentThread().setContextClassLoader(sys);
        return sys;
    }
```

