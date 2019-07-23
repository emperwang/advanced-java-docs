# Thread

## Field

````java
// 线程名字
private volatile String name;
// 线程优先级
private int priority;
private Thread threadQ;
private long eetop;
private boolean single_step;
// 是否是守护线程
private boolean daemon = false;
private boolean stillborn = false;
// 目标函数
private Runnable target;
// 所属的线程组
private ThreadGroup group;
// 加载器
private ClassLoader contextClassLoader;
private AccessControlContext inheritedAccessControlContext;
private static int threadInitNumber;
ThreadLocalMap threadLocals = null;
ThreadLocalMap inheritableThreadLocals = null;
private long stackSize;
private long nativeParkEventPointer;
private long tid;
private static long threadSeqNumber;
private volatile int threadStatus = 0;
volatile Object parkBlocker;
private volatile Interruptible blocker;
private final Object blockerLock = new Object();
// 设置了三个优先级状态
public static final int MIN_PRIORITY = 1;
public static final int NORM_PRIORITY = 5;
public static final int MAX_PRIORITY = 10;
private static final StackTraceElement[] EMPTY_STACK_TRACE;
private static final RuntimePermission SUBCLASS_IMPLEMENTATION_PERMISSION;
private volatile Thread.UncaughtExceptionHandler uncaughtExceptionHandler;
private static volatile Thread.UncaughtExceptionHandler defaultUncaughtExceptionHandler;
@Contended("tlr")
long threadLocalRandomSeed;
@Contended("tlr")
int threadLocalRandomProbe;
@Contended("tlr")
int threadLocalRandomSecondarySeed;
````

静态初始化函数:

```java
static {
    registerNatives();
    EMPTY_STACK_TRACE = new StackTraceElement[0];
    SUBCLASS_IMPLEMENTATION_PERMISSION = new 	RuntimePermission("enableContextClassLoaderOverride");
}
```

## 构造函数

```java
// 可以看到初始化函数,是调用了init函数来进行初始化的操作

public Thread() {
    this.init((ThreadGroup)null, (Runnable)null, "Thread-" + nextThreadNum(), 0L);
}

public Thread(Runnable var1) {
    this.init((ThreadGroup)null, var1, "Thread-" + nextThreadNum(), 0L);
}
public Thread(ThreadGroup var1, Runnable var2) {
    this.init(var1, var2, "Thread-" + nextThreadNum(), 0L);
}

public Thread(String var1) {
    this.init((ThreadGroup)null, (Runnable)null, var1, 0L);
}

public Thread(ThreadGroup var1, String var2) {
    this.init(var1, (Runnable)null, var2, 0L);
}

public Thread(Runnable var1, String var2) {
    this.init((ThreadGroup)null, var1, var2, 0L);
}

public Thread(ThreadGroup var1, Runnable var2, String var3) {
    this.init(var1, var2, var3, 0L);
}

public Thread(ThreadGroup var1, Runnable var2, String var3, long var4) {
    this.init(var1, var2, var3, var4);
}
```

```java
private void init(ThreadGroup var1, Runnable var2, String var3, long var4) {
    this.init(var1, var2, var3, var4, (AccessControlContext)null, true);
}

private void init(ThreadGroup var1, Runnable var2, String var3, long var4, AccessControlContext var6, boolean var7) {
    if (var3 == null) {
        throw new NullPointerException("name cannot be null");
    } else {
        // 设置名字
        this.name = var3;
        Thread var8 = currentThread();
        SecurityManager var9 = System.getSecurityManager();
        if (var1 == null) {
            if (var9 != null) {
                // 设置threadGroup
                var1 = var9.getThreadGroup();
            }

            if (var1 == null) {
                var1 = var8.getThreadGroup();
            }
        }

        var1.checkAccess();
        if (var9 != null && isCCLOverridden(this.getClass())) {
            var9.checkPermission(SUBCLASS_IMPLEMENTATION_PERMISSION);
        }
		
        var1.addUnstarted();
        // 初始化threadGroup
        this.group = var1;
        // 是否是守护线程
        this.daemon = var8.isDaemon();
        // 优先级
        this.priority = var8.getPriority();
        // 类加载器
        if (var9 != null && !isCCLOverridden(var8.getClass())) {
            this.contextClassLoader = var8.contextClassLoader;
        } else {
            this.contextClassLoader = var8.getContextClassLoader();
        }
		// 
        this.inheritedAccessControlContext = var6 != null ? var6 : AccessController.getContext();
        // 目标函数
        this.target = var2;
        this.setPriority(this.priority);
        if (var7 && var8.inheritableThreadLocals != null) {
            this.inheritableThreadLocals = ThreadLocal.createInheritedMap(var8.inheritableThreadLocals);
        }
		// 栈大小
        this.stackSize = var4;
        // threadID
        this.tid = nextThreadID();
    }
}

private static synchronized int nextThreadNum() {
    return threadInitNumber++;
}

private static synchronized long nextThreadID() {
    return ++threadSeqNumber;
}
```



## 功能函数

### start

```java
public synchronized void start() {
    if (this.threadStatus != 0) {
        throw new IllegalThreadStateException();
    } else {
        // 把此线程加入到线程组中
        this.group.add(this);
        boolean var1 = false;
        try {
            // 调用本地函数进行启动
            this.start0();
            var1 = true;
        } finally {
            try {
                if (!var1) {
                    this.group.threadStartFailed(this);
                }
            } catch (Throwable var8) {
                ;
            }
        }
    }
}

private native void start0();
```



### sleep

```java
public static native void sleep(long var0) throws InterruptedException;
```



### run

```java
// 从这里可以看到,调用的是传递进来的目标类的run方法
public void run() {
    if (this.target != null) {
        this.target.run();
    }
}
```



### yield

```java
public static native void yield();
```



### exit

```java
// 退出. 内容清空
private void exit() {
    if (this.group != null) {
        this.group.threadTerminated(this);
        this.group = null;
    }
    this.target = null;
    this.threadLocals = null;
    this.inheritableThreadLocals = null;
    this.inheritedAccessControlContext = null;
    this.blocker = null;
    this.uncaughtExceptionHandler = null;
}
```



### interrupt

```java
public void interrupt() {
    if (this != currentThread()) {
        this.checkAccess();
    }
	// 阻塞锁
    Object var1 = this.blockerLock;
    // 获取锁
    synchronized(this.blockerLock) {
        Interruptible var2 = this.blocker;
        if (var2 != null) {
            // 调用本地函数进行中断
            this.interrupt0();
            var2.interrupt(this);
            return;
        }
    }
    this.interrupt0();
}
```

### join

```java
public final synchronized void join(long var1) throws InterruptedException {
    long var3 = System.currentTimeMillis();
    long var5 = 0L;
    if (var1 < 0L) {
        throw new IllegalArgumentException("timeout value is negative");
    } else {
        if (var1 == 0L) {
            // 进行休眠操作
            while(this.isAlive()) {
                this.wait(0L);
            }
        } else {
            while(this.isAlive()) {
                long var7 = var1 - var5;
                if (var7 <= 0L) {
                    break;
                }
                // 有超时时间的休眠
                this.wait(var7);
                var5 = System.currentTimeMillis() - var3;
            }
        }
    }
}
```



### dumpStack

```java
    public static void dumpStack() {
        (new Exception("Stack trace")).printStackTrace();
    }
```



### suspend0

```java
private native void setPriority0(int var1);

private native void stop0(Object var1);

private native void suspend0();

private native void resume0();

private native void interrupt0();
```

## 内部类

### state

```java
public static enum State {
    NEW,
    RUNNABLE,
    BLOCKED,
    WAITING,
    TIMED_WAITING,
    TERMINATED;

    private State() {
    }
}
```

### caches

```java
private static class Caches {
    static final ConcurrentMap<Thread.WeakClassKey, Boolean> subclassAudits = new ConcurrentHashMap();
    static final ReferenceQueue<Class<?>> subclassAuditsQueue = new ReferenceQueue();

    private Caches() {
    }
}
```

### WeakClassKey

```java
private static class Caches {
    static final ConcurrentMap<Thread.WeakClassKey, Boolean> subclassAudits = new ConcurrentHashMap();
    static final ReferenceQueue<Class<?>> subclassAuditsQueue = new ReferenceQueue();

    private Caches() {
    }
}
```

