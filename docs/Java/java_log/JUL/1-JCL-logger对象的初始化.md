#  JCL-logger对象的初始化

前面通过多SLF4J的学习，可以了解到SLF4J是如何跟JCL进行整合使用的， 那么本节呢主要就是分下一下JCL 的logger对象的生成。

首先回顾一下SLF4J，对于SLF4J整合JCL， 其主要是通过`JDK14LoggerFactory`来生成对应的logger对象的，那么我们就从这个类入手来看一下生成logger对象的流程。



## 1. Logger创建

```java
// org.slf4j.jul.JDK14LoggerFactory#getLogger
// 保存生成的logger对象
ConcurrentMap<String, Logger> loggerMap = new ConcurrentHashMap();
public Logger getLogger(String name) {
    if (name.equalsIgnoreCase("ROOT")) {
        name = JUL_ROOT_LOGGER_NAME;
    }

    Logger slf4jLogger = (Logger)this.loggerMap.get(name);
    if (slf4jLogger != null) {
        return slf4jLogger;
    } else {
        // 如果map中没有的话, 就生成一个logger对象,并把新的对象保存到map中.
        // 此开始就是生成jcl logger对象了
        java.util.logging.Logger julLogger = java.util.logging.Logger.getLogger(name);
        Logger newInstance = new JDK14LoggerAdapter(julLogger);
        Logger oldInstance = (Logger)this.loggerMap.putIfAbsent(name, newInstance);
        return (Logger)(oldInstance == null ? newInstance : oldInstance);
    }
}
```

```java
// java.util.logging.Logger#getLogger(java.lang.String)
@CallerSensitive
public static Logger getLogger(String name) {
    return demandLogger(name, null, Reflection.getCallerClass());
}

// java.util.logging.Logger#demandLogger
private static Logger demandLogger(String name, String resourceBundleName, Class<?> caller) {
    // 获取logManager, 通过LogManager来保存并生成logger对象
    // LogManager是一个全局单例对象
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

这里我们先跳过LogManager的初始化，先继续看logger的创建。

```java
// java.util.logging.LogManager#demandLogger  注意这个方法,其实是在LogManager中
    Logger demandLogger(String name, String resourceBundleName, Class<?> caller) {
        // 先从缓存中去查看name对应的logger是否已经存在
        // 如果存在则直接返回 使用
        // 如果不存在,则创建一个
        Logger result = getLogger(name);
        if (result == null) {
            // 创建一个新logger对象
            Logger newLogger = new Logger(name, resourceBundleName, caller, this, false);
            do {
                // 添加logger到缓存中
                if (addLogger(newLogger)) {
                    return newLogger;
                }
                // 这里又从缓存中获取logger对象
                // 因为上面添加logger的操作可能会失败,由可能另一个thread创建了logger并成功添加到缓存中
                // 这里我们就再次从缓存中获取对象
                result = getLogger(name);
            } while (result == null);
        }
        return result;
    }
```

从缓存中查找logger

```java
// java.util.logging.LogManager#getLogger
public Logger getLogger(String name) {
    return getUserContext().findLogger(name);
}

// 用于缓存创建的对象
// 但是logger对象是使用 weakReference包裹的, 很有可能随时被 GC 清除
// 所以每次打印日志时使用的 logger对象 很有可能不是同一个
//java.util.logging.LogManager.LoggerContext#namedLoggers
private final Hashtable<String,LoggerWeakRef> namedLoggers = new Hashtable<>();
// java.util.logging.LogManager.LoggerContext#findLogger
synchronized Logger findLogger(String name) {
    // 保证初始化了
    ensureInitialized();
    // 从缓存中查找
    LoggerWeakRef ref = namedLoggers.get(name);
    if (ref == null) {
        return null;
    }
    // 从reference中获取对象
    Logger logger = ref.get();
    if (logger == null) {
        // 如果logger被GC,则进行一个 清除操作
        // 1. 把自己从 缓存中namedLoggers删除
        // 2. 把自己从父 Node中删除
        ref.dispose();
    }
    return logger;
}
```

如果从缓存中没有找到， 那么就要创建一个logger：

```java
// java.util.logging.Logger#Logger(java.lang.String, java.lang.String, java.lang.Class<?>, java.util.logging.LogManager, boolean)
Logger(String name, String resourceBundleName, Class<?> caller, LogManager manager, boolean isSystemLogger) {
    this.manager = manager;
    this.isSystemLogger = isSystemLogger;
    setupResourceInfo(resourceBundleName, caller);
    this.name = name;
    levelValue = Level.INFO.intValue();
}
```



创建完logger对象，要保存起来以备后用：

```java
// java.util.logging.LogManager#addLogger   // 这里的保存logger，同样是在LogManager中
public boolean addLogger(Logger logger) {
    final String name = logger.getName();
    if (name == null) {
        throw new NullPointerException();
    }
    // 此时清除被GC掉的那些logger对象
    drainLoggerRefQueueBounded();
    // 获取logger context
    LoggerContext cx = getUserContext();
    // 添加到 loggerContext中
    if (cx.addLocalLogger(logger)) {
        /// 加载logger对应的 handler
        loadLoggerHandlers(logger, name, name + ".handlers");
        return true;
    } else {
        return false;
    }
}

// java.util.logging.LogManager.LoggerContext#addLocalLogger(java.util.logging.Logger)
boolean addLocalLogger(Logger logger) {
    return addLocalLogger(logger, requiresDefaultLoggers());
}

//java.util.logging.LogManager.LoggerContext#addLocalLogger(java.util.logging.Logger, boolean)
synchronized boolean addLocalLogger(Logger logger, boolean addDefaultLoggersIfNeeded) {
    if (addDefaultLoggersIfNeeded) {
        ensureAllDefaultLoggers(logger);
    }

    final String name = logger.getName();
    if (name == null) {
        throw new NullPointerException();
    }
    // 从缓存中获取 logger的reference
    LoggerWeakRef ref = namedLoggers.get(name);
    if (ref != null) {
        if (ref.get() == null) {
            // 有reference,但是没有了logger对象, 那么就做一下清除操作
            ref.dispose();
        } else {
            return false;
        }
    }
    // 获取LogManager对象
    final LogManager owner = getOwner();
    // 记录LogManager 到logger对象中
    logger.setLogManager(owner);
    // 使用 weakReference 包裹 logger对象
    ref = owner.new LoggerWeakRef(logger);
    // 把创建的logger保存起来
    namedLoggers.put(name, ref);

    // 获取 logger对象对应的 日志 level
    Level level = owner.getLevelProperty(name + ".level", null);
    if (level != null && !logger.isLevelInitialized()) {
        // 设置logger的level
        doSetLevel(logger, level);
    }

	 // 处理logger对象对应的handler
    processParentHandlers(logger, name);
	
    // 获取 name对应的Node对象
    // 简单说 日志的保存是一个父子结构的
    // 如: com.heima.aiguigu.test1, 并且此类有logger对象
    // com.heima.testparent. 此类也有logger对象
    // 那么 testparent 就可以是  test1的父类.
    // 这里注意, 父子node必须都有 logger对象
    LogNode node = getNode(name);
    node.loggerRef = ref;
    Logger parent = null;
    LogNode nodep = node.parent;
    // 向上寻找第一个有 logger对象的 Node
    while (nodep != null) {
        LoggerWeakRef nodeRef = nodep.loggerRef;
        if (nodeRef != null) {
            parent = nodeRef.get();
            if (parent != null) {
                break;
            }
        }
        nodep = nodep.parent;
    }
	// 找了一个有logger对象的Node, 则设置此node为Parent
    if (parent != null) {
        doSetParent(logger, parent);
    }
    // Walk over the children and tell them we are their new parent.
    node.walkAndSetParent(logger);
    // new LogNode is ready so tell the LoggerWeakRef about it
    ref.setNode(node);
    return true;
}

// java.util.logging.LogManager.LogNode#walkAndSetParent
void walkAndSetParent(Logger parent) {
    if (children == null) {
        return;
    }
    Iterator<LogNode> values = children.values().iterator();
 	// 找到所有的child, 并且把拥有logger对象的child的logger's parent更为为parent(参数)
    while (values.hasNext()) {
        LogNode node = values.next();
        LoggerWeakRef ref = node.loggerRef;
        Logger logger = (ref == null) ? null : ref.get();
        if (logger == null) {
            node.walkAndSetParent(parent);
        } else {
            doSetParent(logger, parent);
        }
    }
}
```

到这里logger对象的创建就完成了. 







