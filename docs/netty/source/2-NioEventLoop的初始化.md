[TOC]

# NioEventLoop的初始化

由上篇了解到NioEventLoopGroup初始化了多个NioEventLoop，本篇就接着上篇继续分析下NioEventLoop的初始化。

看一下NioEventLoop的类图:

![](../../image/netty/NioEventLoop.png)

回顾一下上篇的初始化：

> io.netty.channel.nio.NioEventLoopGroup#newChild

```java
/**
     * 创建NioEventLoop
     */
@Override
protected EventLoop newChild(Executor executor, Object... args) throws Exception {
    // queueFactory为null
    EventLoopTaskQueueFactory queueFactory = args.length == 4 ? (EventLoopTaskQueueFactory) args[3] : null;
    // args[0]为selector
    // args[1]为selectStrategy
    // args[2]为拒绝策略
    // parent =this,也就是 NioEventLoop的parent为NioEventLoopGroup
    return new NioEventLoop(this, executor, (SelectorProvider) args[0],
                            ((SelectStrategyFactory) args[1]).newSelectStrategy(), (RejectedExecutionHandler) args[2], queueFactory);
}
```

> io.netty.channel.nio.NioEventLoop#NioEventLoop

```java
NioEventLoop(NioEventLoopGroup parent, Executor executor, SelectorProvider selectorProvider, SelectStrategy strategy, RejectedExecutionHandler rejectedExecutionHandler, EventLoopTaskQueueFactory queueFactory) {
    // newTaskQueue用来创建任务队列, 当第一次创建NioEventLoop时, queueFactory为null
    super(parent, executor, false, newTaskQueue(queueFactory), newTaskQueue(queueFactory),
          rejectedExecutionHandler);
    this.provider = ObjectUtil.checkNotNull(selectorProvider, "selectorProvider");
    // 策略
    this.selectStrategy = ObjectUtil.checkNotNull(strategy, "selectStrategy");
    // 每一个NioEventLoop对应一个selector
    final SelectorTuple selectorTuple = openSelector();
    this.selector = selectorTuple.selector;
    this.unwrappedSelector = selectorTuple.unwrappedSelector;
}
```

```java
// 此函数功能简单说就是创建 selector
private SelectorTuple openSelector() {
    final Selector unwrappedSelector;
    try {
        // 目前分析是在windows环境,故此处创建的是 WindowsSelectorImpl
        // 简单说也就是创建一个 selector
        unwrappedSelector = provider.openSelector();
    } catch (IOException e) {
        throw new ChannelException("failed to open a new selector", e);
    }

    if (DISABLE_KEY_SET_OPTIMIZATION) {
        return new SelectorTuple(unwrappedSelector);
    }
    // 加载 sun.nio.ch.SelectorImpl
    Object maybeSelectorImplClass = AccessController.doPrivileged(new PrivilegedAction<Object>() {
        @Override
        public Object run() {
            try {
                return Class.forName(
                    "sun.nio.ch.SelectorImpl",
                    false,
                    PlatformDependent.getSystemClassLoader());
            } catch (Throwable cause) {
                return cause;
            }
        }
    });

    if (!(maybeSelectorImplClass instanceof Class) ||
        // ensure the current selector implementation is what we can instrument.
        !((Class<?>) maybeSelectorImplClass).isAssignableFrom(unwrappedSelector.getClass())) {
        if (maybeSelectorImplClass instanceof Throwable) {
            Throwable t = (Throwable) maybeSelectorImplClass;
            logger.trace("failed to instrument a special java.util.Set into: {}", unwrappedSelector, t);
        }
        return new SelectorTuple(unwrappedSelector);
    }

    final Class<?> selectorImplClass = (Class<?>) maybeSelectorImplClass;
    final SelectedSelectionKeySet selectedKeySet = new SelectedSelectionKeySet();
    //
    Object maybeException = AccessController.doPrivileged(new PrivilegedAction<Object>() {
        @Override
        public Object run() {
            try {
                Field selectedKeysField = selectorImplClass.getDeclaredField("selectedKeys");
                Field publicSelectedKeysField = selectorImplClass.getDeclaredField("publicSelectedKeys");

                if (PlatformDependent.javaVersion() >= 9 && PlatformDependent.hasUnsafe()) {
// Let us try to use sun.misc.Unsafe to replace the SelectionKeySet.
// This allows us to also do this in Java9+ without any extra flags.
                    long selectedKeysFieldOffset = PlatformDependent.objectFieldOffset(selectedKeysField);
                    long publicSelectedKeysFieldOffset =
                        PlatformDependent.objectFieldOffset(publicSelectedKeysField);
                    // 设置创建的 selector的selectedKeys field
                    // 设置创建的 selector的publicSelectedKeys field
                    if (selectedKeysFieldOffset != -1 && publicSelectedKeysFieldOffset != -1) {
                        PlatformDependent.putObject(
                            unwrappedSelector, selectedKeysFieldOffset, selectedKeySet);
                        PlatformDependent.putObject(
                            unwrappedSelector, publicSelectedKeysFieldOffset, selectedKeySet);
                        return null;
                    }
                    // We could not retrieve the offset, lets try reflection as last-resort.
                }

                Throwable cause = ReflectionUtil.trySetAccessible(selectedKeysField, true);
                if (cause != null) {
                    return cause;
                }
                cause = ReflectionUtil.trySetAccessible(publicSelectedKeysField, true);
                if (cause != null) {
                    return cause;
                }

                selectedKeysField.set(unwrappedSelector, selectedKeySet);
                publicSelectedKeysField.set(unwrappedSelector, selectedKeySet);
                return null;
            } catch (NoSuchFieldException e) {
                return e;
            } catch (IllegalAccessException e) {
                return e;
            }
        }
    });

    if (maybeException instanceof Exception) {
        selectedKeys = null;
        Exception e = (Exception) maybeException;
        logger.trace("failed to instrument a special java.util.Set into: {}", unwrappedSelector, e);
        return new SelectorTuple(unwrappedSelector);
    }
    selectedKeys = selectedKeySet;
    logger.trace("instrumented a special java.util.Set into: {}", unwrappedSelector);
    return new SelectorTuple(unwrappedSelector,
                             new SelectedSelectionKeySetSelector(unwrappedSelector, selectedKeySet));
}
```

> io.netty.channel.SingleThreadEventLoop#SingleThreadEventLoop

```java
protected SingleThreadEventLoop(EventLoopGroup parent, Executor executor,
    boolean addTaskWakesUp, Queue<Runnable> taskQueue, Queue<Runnable> tailTaskQueue,RejectedExecutionHandler rejectedExecutionHandler) {
    super(parent, executor, addTaskWakesUp, taskQueue, rejectedExecutionHandler);
    tailTasks = ObjectUtil.checkNotNull(tailTaskQueue, "tailTaskQueue");
}
```

> io.netty.util.concurrent.SingleThreadEventExecutor#SingleThreadEventExecutor

```java
protected SingleThreadEventExecutor(EventExecutorGroup parent, Executor executor,
  boolean addTaskWakesUp, Queue<Runnable> taskQueue,RejectedExecutionHandler   rejectedHandler) {
    super(parent);
    this.addTaskWakesUp = addTaskWakesUp;
    this.maxPendingTasks = DEFAULT_MAX_PENDING_EXECUTOR_TASKS;
    // 线程池
    this.executor = ThreadExecutorMap.apply(executor, this);
    // 任务队列
    this.taskQueue = ObjectUtil.checkNotNull(taskQueue, "taskQueue");
    // 拒绝策略的设置
    this.rejectedExecutionHandler = ObjectUtil.checkNotNull(rejectedHandler, "rejectedHandler");
}
```

> io.netty.util.concurrent.AbstractScheduledEventExecutor#AbstractScheduledEventExecutor(io.netty.util.concurrent.EventExecutorGroup)

```java
protected AbstractScheduledEventExecutor(EventExecutorGroup parent) {
    super(parent);
}
```

> io.netty.util.concurrent.AbstractEventExecutor#AbstractEventExecutor(io.netty.util.concurrent.EventExecutorGroup)

```java
protected AbstractEventExecutor(EventExecutorGroup parent) {
    this.parent = parent;
}
```

这就是 NioEventLoop的初始化了，总体还是比较简单的，一些列的父类的初始化，还有一个重点需要关注下：

1. NioEventLoop其创建了selector，所以简单说，此才是具体的处理类
2. NioEventLoopGroup就是字面意思，其其实是包含了多个NioEventLoop的group（组）

到这里NioEventLoop就创建完处理，也就是线程组创建好了，server端就可以进一步进行配置了。下篇咱们看一下ServerBootstrap的初始化以及使用。