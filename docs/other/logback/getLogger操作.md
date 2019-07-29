# 获取log操作

```java
public static Logger getLogger(String name) {
    ILoggerFactory iLoggerFactory = getILoggerFactory();
    return iLoggerFactory.getLogger(name);
}
```

```java
public final Logger getLogger(final String name) {
    if (name == null) {
        throw new IllegalArgumentException("name argument cannot be null");
    }

    // if we are asking for the root logger, then let us return it without
    // wasting time
    // 获取根日志
    if (Logger.ROOT_LOGGER_NAME.equalsIgnoreCase(name)) {
        return root;
    }

    int i = 0;
    Logger logger = root;

    // check if the desired logger exists, if it does, return it
    // without further ado.
    Logger childLogger = (Logger) loggerCache.get(name);
    // if we have the child, then let us return it without wasting time
    // 已经存在了,则直接返回
    if (childLogger != null) {
        return childLogger;
    }

    // if the desired logger does not exist, them create all the loggers
    // in between as well (if they don't already exist)
    String childName;
    while (true) {
        int h = LoggerNameUtil.getSeparatorIndexOf(name, i);
        if (h == -1) {
            childName = name;
        } else {
            childName = name.substring(0, h);
        }
        // move i left of the last point
        i = h + 1;
        synchronized (logger) {
            // 不存在则创建此log
            childLogger = logger.getChildByName(childName);
            if (childLogger == null) {
                childLogger = logger.createChildByName(childName);
                // 把创建好的logger放到当前log的子log容器中
                loggerCache.put(childName, childLogger);
                // 增加数量
                incSize();
            }
        }
        logger = childLogger;
        if (h == -1) {
            return childLogger;
        }
    }
}

// 存储子log的容器
transient private List<Logger> childrenList;
// 从子log中查看是否存在
Logger getChildByName(final String childName) {
    if (childrenList == null) {
        return null;
    } else {
        // 遍历子log容器进行查找
        // 找到则返回，否则返回null
        int len = this.childrenList.size();
        for (int i = 0; i < len; i++) {
            final Logger childLogger_i = (Logger) childrenList.get(i);
            final String childName_i = childLogger_i.getName();
            if (childName.equals(childName_i)) {
                return childLogger_i;
            }
        }
        // no child found
        return null;
    }
}
```

创建一个log对象

```java
Logger createChildByName(final String childName) {
    int i_index = LoggerNameUtil.getSeparatorIndexOf(childName, this.name.length() + 1);
    if (i_index != -1) {
        throw new IllegalArgumentException("For logger [" + this.name + "] child name [" + childName
                                           + " passed as parameter, may not include '.' after index" + (this.name.length() + 1));
    }

    if (childrenList == null) { // 设置存放子log的容器，读多存少，这里设置为CopyOnWrite
        childrenList = new CopyOnWriteArrayList<Logger>();
    }
    Logger childLogger;
    // 创建一个新额logger
    childLogger = new Logger(childName, this, this.loggerContext);
    childrenList.add(childLogger);
    // 这是log有效级别，debug info  还是其他
    childLogger.effectiveLevelInt = this.effectiveLevelInt;
    return childLogger;
}
```

