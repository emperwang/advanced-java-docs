# System

## Field

```java
// 标准输入输出错误输出
public final static InputStream in = null;
public final static PrintStream out = null;
public final static PrintStream err = null;
// 安全管理类
private static volatile SecurityManager security = null;
private static volatile Console cons = null;
// System properties
private static Properties props;
// 分隔符
 private static String lineSeparator;
```

静态初始化函数:

```java
private static native void registerNatives();
static {
    registerNatives();
}
```



## 构造函数

```java
 /** Don't let anyone instantiate this class */
private System() {
}
```



## 功能函数

### 设置输入输出

```java
private static native void setIn0(InputStream in);
private static native void setOut0(PrintStream out);
private static native void setErr0(PrintStream err);

public static void setIn(InputStream in) {
    checkIO();
    setIn0(in);
}

public static void setOut(PrintStream out) {
    checkIO();
    setOut0(out);
}

public static void setErr(PrintStream err) {
    checkIO();
    setErr0(err);
}

private static void checkIO() {
    SecurityManager sm = getSecurityManager();
    if (sm != null) { // 安全检查
        sm.checkPermission(new RuntimePermission("setIO"));
    }
}
```

### currentTimeMillis

```java
public static native long currentTimeMillis();
```

### nanoTime

```java
public static native long nanoTime();
```

### arraycopy

```java
public static native void arraycopy(Object src,  int  srcPos,
                                    Object dest, int destPos,
                                    int length);
```

### getenv
```java
public static String getenv(String name) {
    SecurityManager sm = getSecurityManager();
    if (sm != null) {
        sm.checkPermission(new RuntimePermission("getenv."+name));
    }
	// 具体获取遍历的操作
    return ProcessEnvironment.getenv(name);
}

public static java.util.Map<String,String> getenv() {
    SecurityManager sm = getSecurityManager();
    if (sm != null) {
        sm.checkPermission(new RuntimePermission("getenv.*"));
    }

    return ProcessEnvironment.getenv();
}
```


### exit
```java
    public static void exit(int status) { // 停止JVM
        Runtime.getRuntime().exit(status);
    }
```


### gc
```java
    public static void gc() { // 执行gc垃圾收集
        Runtime.getRuntime().gc();
    }
```


### runFinalization
```java
// Runs the finalization methods of any objects pending finalization.    
public static void runFinalization() {
        Runtime.getRuntime().runFinalization();
    }
```


### load
```java
/* Loads the native library specified by the filename argument.  The filename
* argument must be an absolute path name.*/
public static void load(String filename) {
    Runtime.getRuntime().load0(Reflection.getCallerClass(), filename);
}
```


### loadLibrary
```java
/*Loads the native library specified by the <code>libname</code>
 * argument.*/    
public static void loadLibrary(String libname) {
        Runtime.getRuntime().loadLibrary0(Reflection.getCallerClass(), libname);
    }
```


### mapLibraryName
```java
/* Maps a library name into a platform-specific string representing
* a native library.*/
public static native String mapLibraryName(String libname);
```


### newPrintStream
```java
private static PrintStream newPrintStream(FileOutputStream fos, String enc) {
    if (enc != null) {
        try {
            return new PrintStream(new BufferedOutputStream(fos, 128), true, enc);
        } catch (UnsupportedEncodingException uee) {}
    }
    return new PrintStream(new BufferedOutputStream(fos, 128), true);
}
```


### initializaSystemClass
```java
/**
     * Initialize the system class.  Called after thread initialization.
     */
private static void initializeSystemClass() {

    // VM might invoke JNU_NewStringPlatform() to set those encoding
    // sensitive properties (user.home, user.name, boot.class.path, etc.)
    // during "props" initialization, in which it may need access, via
    // System.getProperty(), to the related system encoding property that
    // have been initialized (put into "props") at early stage of the
    // initialization. So make sure the "props" is available at the
    // very beginning of the initialization and all system properties to
    // be put into it directly.
    props = new Properties();
    initProperties(props);  // initialized by the VM

    // There are certain system configurations that may be controlled by
    // VM options such as the maximum amount of direct memory and
    // Integer cache size used to support the object identity semantics
    // of autoboxing.  Typically, the library will obtain these values
    // from the properties set by the VM.  If the properties are for
    // internal implementation use only, these properties should be
    // removed from the system properties.
    //
    // See java.lang.Integer.IntegerCache and the
    // sun.misc.VM.saveAndRemoveProperties method for example.
    //
    // Save a private copy of the system properties object that
    // can only be accessed by the internal implementation.  Remove
    // certain system properties that are not intended for public access.
    sun.misc.VM.saveAndRemoveProperties(props);


    lineSeparator = props.getProperty("line.separator");
    sun.misc.Version.init();

    FileInputStream fdIn = new FileInputStream(FileDescriptor.in);
    FileOutputStream fdOut = new FileOutputStream(FileDescriptor.out);
    FileOutputStream fdErr = new FileOutputStream(FileDescriptor.err);
    setIn0(new BufferedInputStream(fdIn));
    setOut0(newPrintStream(fdOut, props.getProperty("sun.stdout.encoding")));
    setErr0(newPrintStream(fdErr, props.getProperty("sun.stderr.encoding")));

    // Load the zip library now in order to keep java.util.zip.ZipFile
    // from trying to use itself to load this library later.
    loadLibrary("zip");

    // Setup Java signal handlers for HUP, TERM, and INT (where available).
    Terminator.setup();

    // Initialize any miscellenous operating system settings that need to be
    // set for the class libraries. Currently this is no-op everywhere except
    // for Windows where the process-wide error mode is set before the java.io
    // classes are used.
    sun.misc.VM.initializeOSEnvironment();

    // The main thread is not added to its thread group in the same
    // way as other threads; we must do it ourselves here.
    Thread current = Thread.currentThread();
    current.getThreadGroup().add(current);

    // register shared secrets
    setJavaLangAccess();

    // Subsystems that are invoked during initialization can invoke
    // sun.misc.VM.isBooted() in order to avoid doing things that should
    // wait until the application class loader has been set up.
    // IMPORTANT: Ensure that this remains the last initialization action!
    sun.misc.VM.booted();
}
```


### setJavaLangAccess

```java
private static void setJavaLangAccess() {
    // Allow privileged classes outside of java.lang
    sun.misc.SharedSecrets.setJavaLangAccess(new sun.misc.JavaLangAccess(){
        public sun.reflect.ConstantPool getConstantPool(Class<?> klass) {
            return klass.getConstantPool();
        }
        public boolean casAnnotationType(Class<?> klass, AnnotationType oldType, AnnotationType newType) {
            return klass.casAnnotationType(oldType, newType);
        }
        public AnnotationType getAnnotationType(Class<?> klass) {
            return klass.getAnnotationType();
        }
        public Map<Class<? extends Annotation>, Annotation> getDeclaredAnnotationMap(Class<?> klass) {
            return klass.getDeclaredAnnotationMap();
        }
        public byte[] getRawClassAnnotations(Class<?> klass) {
            return klass.getRawAnnotations();
        }
        public byte[] getRawClassTypeAnnotations(Class<?> klass) {
            return klass.getRawTypeAnnotations();
        }
        public byte[] getRawExecutableTypeAnnotations(Executable executable) {
            return Class.getExecutableTypeAnnotationBytes(executable);
        }
        public <E extends Enum<E>>
            E[] getEnumConstantsShared(Class<E> klass) {
            return klass.getEnumConstantsShared();
        }
        public void blockedOn(Thread t, Interruptible b) {
            t.blockedOn(b);
        }
        public void registerShutdownHook(int slot, boolean registerShutdownInProgress, Runnable hook) {
            Shutdown.add(slot, registerShutdownInProgress, hook);
        }
        public int getStackTraceDepth(Throwable t) {
            return t.getStackTraceDepth();
        }
        public StackTraceElement getStackTraceElement(Throwable t, int i) {
            return t.getStackTraceElement(i);
        }
        public String newStringUnsafe(char[] chars) {
            return new String(chars, true);
        }
        public Thread newThreadWithAcc(Runnable target, AccessControlContext acc) {
            return new Thread(target, acc);
        }
        public void invokeFinalize(Object o) throws Throwable {
            o.finalize();
        }
    });
}
```

