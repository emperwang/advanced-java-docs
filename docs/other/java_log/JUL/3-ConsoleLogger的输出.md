#  ConsoleLogger的输出

本篇我们以console logger为例，了解一下logger的输出。

## 1. logger的handler添加

```java
// java.util.logging.LogManager#addLogger
public boolean addLogger(Logger logger) {
    final String name = logger.getName();
    if (name == null) {
        throw new NullPointerException();
    }
    drainLoggerRefQueueBounded();
    LoggerContext cx = getUserContext();
    if (cx.addLocalLogger(logger)) {
        // 解析logger对应的handler, 并记录到logger中
        loadLoggerHandlers(logger, name, name + ".handlers");
        return true;
    } else {
        return false;
    }
}
```

可以看到handler是在创建logger后，准备添加到context中时进行了handler的初始化。

```java
// java.util.logging.Logger#handlers // logger用于保存handler的 容器
private final CopyOnWriteArrayList<Handler> handlers =
    new CopyOnWriteArrayList<>();
// java.util.logging.LogManager#loadLoggerHandlers
private void loadLoggerHandlers(final Logger logger, final String name,
                                final String handlersPropertyName)
{
    AccessController.doPrivileged(new PrivilegedAction<Object>() {
        @Override
        public Object run() {
            // 从配置文件中获取对应的 handler类
            // 之后进行handler class的加载 以及 实例化
            String names[] = parseClassNames(handlersPropertyName);
            for (int i = 0; i < names.length; i++) {
                String word = names[i];
                try {
                    Class<?> clz = ClassLoader.getSystemClassLoader().loadClass(word);
                    Handler hdl = (Handler) clz.newInstance();
                    String levs = getProperty(word + ".level");
                    if (levs != null) {
                        Level l = Level.findLevel(levs);
                        if (l != null) {
                            hdl.setLevel(l);
                        } else {
                            System.err.println("Can't set level for " + word);
                        }
                    }
                    // 把实例化后的 handler对象保存到 logger中
                    logger.addHandler(hdl);
                } catch (Exception ex) {
                    System.err.println("Can't load log handler \"" + word + "\"");
                    System.err.println("" + ex);
                    ex.printStackTrace();
                }
            }
            return null;
        }
    });
}
```





## 2.logger的输出

下面我们看一下logger的输出是如何进行的.

```java
// java.util.logging.Logger#info(java.lang.String)
public void info(String msg) {
    log(Level.INFO, msg);
}

// java.util.logging.Logger#log(java.util.logging.Level, java.lang.String)
public void log(Level level, String msg) {
    if (!isLoggable(level)) {
        return;
    }
    // 把要输出的消息保存为一个  LogRecord
    LogRecord lr = new LogRecord(level, msg);
    // 输出
    doLog(lr);
}

// java.util.logging.Logger#doLog(java.util.logging.LogRecord)
private void doLog(LogRecord lr) {
    // 记录logger的name到 LogRecord中
    lr.setLoggerName(name);
    final LoggerBundle lb = getEffectiveLoggerBundle();
    final ResourceBundle  bundle = lb.userBundle;
    final String ebname = lb.resourceBundleName;
    if (ebname != null && bundle != null) {
        lr.setResourceBundleName(ebname);
        lr.setResourceBundle(bundle);
    }
    // 记录输出 logRecord
    log(lr);
}
```

```java
// java.util.logging.Logger#log(java.util.logging.LogRecord)
public void log(LogRecord record) {
    // 根据level判断此 logRecord是否可以输出
    if (!isLoggable(record.getLevel())) {
        return;
    }
    // 获取此logger的 filter对象
    Filter theFilter = filter;
    // 进行过滤判断
    if (theFilter != null && !theFilter.isLoggable(record)) {
        return;
    }

	//获取当前logger
    Logger logger = this;
    while (logger != null) {
        // 获取当前logger对象记录的所有 handler对象
        final Handler[] loggerHandlers = isSystemLogger
            ? logger.accessCheckedHandlers()
            : logger.getHandlers();
		
        // 把logRecord发送到所有handler中 进行输出操作
        for (Handler handler : loggerHandlers) {
            handler.publish(record);
        }
		// name + ".useParentHandlers" 来配置是否使用父类的 handler对象
        // 默认是使用父类的handler对象
        final boolean useParentHdls = isSystemLogger
            ? logger.useParentHandlers
            : logger.getUseParentHandlers();
		
        // 如果不使用父类对象,则跳出循环
        if (!useParentHdls) {
            break;
        }

        logger = isSystemLogger ? logger.parent : logger.getParent();
    }
}
```

在看console handler是如何输出的之前，我们先看一下console handler的创建及初始化

```java
// java.util.logging.ConsoleHandler#ConsoleHandler
public ConsoleHandler() {
    sealed = false;
    // 进行配置
    configure();
    // 设置输出流为 system.err
    setOutputStream(System.err);
    sealed = true;
}
```



```java
// java.util.logging.ConsoleHandler#configure
private void configure() {
    // 得到 LogManager对象
    LogManager manager = LogManager.getLogManager();
    // 获取类名
    String cname = getClass().getName();
	// 根据配置 来设置 level
    setLevel(manager.getLevelProperty(cname +".level", Level.INFO));
    // 根据配置设置 logger的filter
    setFilter(manager.getFilterProperty(cname +".filter", null));
    // 设置日志的 formatter
    setFormatter(manager.getFormatterProperty(cname +".formatter", new SimpleFormatter()));
    try {
        // 设置 encoding
        setEncoding(manager.getStringProperty(cname +".encoding", null));
    } catch (Exception ex) {
        try {
            setEncoding(null);
        } catch (Exception ex2) {
            // doing a setEncoding with null should always work.
            // assert false;
        }
    }
}
```

```java
// java.util.logging.StreamHandler#setOutputStream
protected synchronized void setOutputStream(OutputStream out) throws SecurityException {
    if (out == null) {
        throw new NullPointerException();
    }
    flushAndClose();
    output = out;
    doneHeader = false;
    String encoding = getEncoding();
    if (encoding == null) {
        writer = new OutputStreamWriter(output);
    } else {
        try {
            // 设置输出流，输出对象为 system.err
            writer = new OutputStreamWriter(output, encoding);
        } catch (UnsupportedEncodingException ex) {
            // This shouldn't happen.  The setEncoding method
            // should have validated that the encoding is OK.
            throw new Error("Unexpected exception " + ex);
        }
    }
}
```





了解其前世今生，接下来我们看一下其对应的输出操作

```java
// java.util.logging.ConsoleHandler#publish
public void publish(LogRecord record) {
    super.publish(record);
    flush();
}

// java.util.logging.StreamHandler#publish
public synchronized void publish(LogRecord record) {
    // 再次判断是否可输出
    if (!isLoggable(record)) {
        return;
    }
    String msg;
    try {
        // 使用 formatter 来格式化消息
        msg = getFormatter().format(record);
    } catch (Exception ex) {
        // We don't want to throw an exception here, but we
        // report the exception to any registered ErrorManager.
        reportError(null, ex, ErrorManager.FORMAT_FAILURE);
        return;
    }

    try {
        // 看起来只有第一次 会打印 head
        if (!doneHeader) {
            writer.write(getFormatter().getHead(this));
            doneHeader = true;
        }
        // 把消息写入到 system.err中
        writer.write(msg);
    } catch (Exception ex) {
        // We don't want to throw an exception here, but we
        // report the exception to any registered ErrorManager.
        reportError(null, ex, ErrorManager.WRITE_FAILURE);
    }
}
```

























