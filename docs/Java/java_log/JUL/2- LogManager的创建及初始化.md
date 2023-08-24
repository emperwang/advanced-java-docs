#  LogManager的创建及初始化

上面了解了JCL logger对象的创建， 本篇看一下LogManager的创建及初始化。

## 1. LogManager创建

回顾一下上篇获取logger对象时，是需要先获取LogManager对象才可以继续的：

```java
// java.util.logging.Logger#demandLogger
private static Logger demandLogger(String name, String resourceBundleName, Class<?> caller) {
    // 创建logger之前， 先获取LogManager对象
    LogManager manager = LogManager.getLogManager();
    SecurityManager sm = System.getSecurityManager();
    if (sm != null && !SystemLoggerHelper.disableCallerCheck) {
        if (caller.getClassLoader() == null) {
            return manager.demandSystemLogger(name, resourceBundleName);
        }
    }
    return manager.demandLogger(name, resourceBundleName, caller);
}
```

```java
// java.util.logging.LogManager#getLogManager
public static LogManager getLogManager() {
    if (manager != null) {
        // manager通过静态代码块进行了创建, 这里开始进行初始化
        manager.ensureLogManagerInitialized();
    }
    return manager;
}

// LogManager 静态代码块
static {
    manager = AccessController.doPrivileged(new PrivilegedAction<LogManager>() {
        @Override
        public LogManager run() {
            LogManager mgr = null;
            String cname = null;
            try {
                // 通过这里可以看到，可以通过java.util.logging.manager属性，设置自己的
                // LogManager类
                cname = System.getProperty("java.util.logging.manager");
                if (cname != null) {
                    try {
                        Class<?> clz = ClassLoader.getSystemClassLoader()
                            .loadClass(cname);
                        mgr = (LogManager) clz.newInstance();
                    } catch (ClassNotFoundException ex) {
                        Class<?> clz = Thread.currentThread()
                            .getContextClassLoader().loadClass(cname);
                        mgr = (LogManager) clz.newInstance();
                    }
                }
            } catch (Exception ex) {
                System.err.println("Could not load Logmanager \"" + cname + "\"");
                ex.printStackTrace();
            }
            // 如果没有设置呢, 就直接创建一个 LogManager
            if (mgr == null) {
                mgr = new LogManager();
            }
            return mgr;

        }
    });
}
```



## 2. LogManager 初始化



```java
// java.util.logging.LogManager#ensureLogManagerInitialized
final void ensureLogManagerInitialized() {
    final LogManager owner = this;
	/// 避免重复初始化
    if (initializationDone || owner != manager) {
        return;
    }

    synchronized(this) {
        final boolean isRecursiveInitialization = (initializedCalled == true);

        assert initializedCalled || !initializationDone
            : "Initialization can't be done if initialized has not been called!";

        if (isRecursiveInitialization || initializationDone) {
            return;
        }
        initializedCalled = true;
        try {
            AccessController.doPrivileged(new PrivilegedAction<Object>() {
                @Override
                public Object run() {
                    assert rootLogger == null;
                    assert initializedCalled && !initializationDone;
					// 读取配置文件
                    owner.readPrimordialConfiguration();
					// 创建 root logger
                    owner.rootLogger = owner.new RootLogger();
                    // 保存创建的 rootLogger
                    owner.addLogger(owner.rootLogger);
                    if (!owner.rootLogger.isLevelInitialized()) {
                        // 设置rootLogger的 level
                        owner.rootLogger.setLevel(defaultLevel);
                    }

                    @SuppressWarnings("deprecation")
                    final Logger global = Logger.global;
					// 添加 global logger
                    owner.addLogger(global);
                    return null;
                }
            });
        } finally {
            // 标记初始化完成
            initializationDone = true;
        }
    }
}
```

读取配置文件

```java
// java.util.logging.LogManager#readPrimordialConfiguration
private void readPrimordialConfiguration() {
    if (!readPrimordialConfiguration) {
        synchronized (this) {
            if (!readPrimordialConfiguration) {
                // If System.in/out/err are null, it's a good
                // indication that we're still in the
                // bootstrapping phase
                if (System.out == null) {
                    return;
                }
                readPrimordialConfiguration = true;
                try {
                    AccessController.doPrivileged(new PrivilegedExceptionAction<Void>() {
                        @Override
                        public Void run() throws Exception {
                            // 读取配置文件
                            readConfiguration();

                            sun.util.logging.PlatformLogger.redirectPlatformLoggers();
                            return null;
                        }
                    });
                } catch (Exception ex) {
            }
        }
    }
}
    

```

```java
//java.util.logging.LogManager#readConfiguration()
public void readConfiguration() throws IOException, SecurityException {
    checkPermission();
	// 通过系统属性读取配置类
    String cname = System.getProperty("java.util.logging.config.class");
    if (cname != null) {
        try {
            try {
                // 加载并实例化 配置类
                Class<?> clz = ClassLoader.getSystemClassLoader().loadClass(cname);
                clz.newInstance();
                return;
            } catch (ClassNotFoundException ex) {
                Class<?> clz = Thread.currentThread().getContextClassLoader().loadClass(cname);
                clz.newInstance();
                return;
            }
        } catch (Exception ex) {
            System.err.println("Logging configuration class \"" + cname + "\" failed");
            System.err.println("" + ex);
        }
    }
	// 读取设置的配置文件
    String fname = System.getProperty("java.util.logging.config.file");
    if (fname == null) {
 		// 如果没有设置配置文件, 则使用 java.home/lib/logging.properties 文件
        fname = System.getProperty("java.home");
        if (fname == null) {
            throw new Error("Can't find java.home ??");
        }
        File f = new File(fname, "lib");
        f = new File(f, "logging.properties");
        fname = f.getCanonicalPath();
    }
    try (final InputStream in = new FileInputStream(fname)) {
        final BufferedInputStream bin = new BufferedInputStream(in);
        // 加载配置
        readConfiguration(bin);
    }
}
```

```java
// java.util.logging.LogManager#readConfiguration(java.io.InputStream)
public void readConfiguration(InputStream ins) throws IOException, SecurityException {
    checkPermission();
    // 这里会把所有的logger中的handler删除并进行close操作.
    // 因为配置文件会重新进行配置
    reset();
	// 加载
    props.load(ins);
    // 配置对象
    String names[] = parseClassNames("config");

    for (int i = 0; i < names.length; i++) {
        String word = names[i];
        try {
            Class<?> clz = ClassLoader.getSystemClassLoader().loadClass(word);
            clz.newInstance();
        } catch (Exception ex) {
            System.err.println("Can't load config class \"" + word + "\"");
            System.err.println("" + ex);
            // ex.printStackTrace();
        }
    }
	// 根据配置文件重新设置logger对象的 level
    setLevelsOnExistingLoggers();

    // listener, ???? 目前还没有仔细看起作用
    // 先行略过
    Map<Object,Integer> listeners = null;
    synchronized (listenerMap) {
        if (!listenerMap.isEmpty())
            listeners = new HashMap<>(listenerMap);
    }
    
    if (listeners != null) {
        assert Beans.isBeansPresent();
        Object ev = Beans.newPropertyChangeEvent(LogManager.class, null, null, null);
        for (Map.Entry<Object,Integer> entry : listeners.entrySet()) {
            Object listener = entry.getKey();
            int count = entry.getValue().intValue();
            for (int i = 0; i < count; i++) {
                Beans.invokePropertyChange(listener, ev);
            }
        }
    }

    synchronized (this) {
        initializedGlobalHandlers = false;
    }
}
```

到此, LogManager初始化完成.









