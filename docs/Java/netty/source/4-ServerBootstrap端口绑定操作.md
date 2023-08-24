[TOC]

# ServerBootstrap的端口绑定操作

上篇分析了ServerBootstrap的初始化以及参数配置的一些操作，本篇看一下端口绑定的操作，了解一下其具体做了哪些工作：

```java
ServerBootstrap bootstrap = new ServerBootstrap()
    .group(parent, child)
    .channel(NioServerSocketChannel.class)
    .option(ChannelOption.SO_BACKLOG, 128)
    //.option(ChannelOption.SO_KEEPALIVE, true)
    .handler(new LoggingHandler())  // parent handler
    .childHandler(new ChannelInitializer<SocketChannel>() {
        @Override
        protected void initChannel(SocketChannel ch) throws Exception {
            ChannelPipeline pipeline = ch.pipeline();
            pipeline.addLast(new ServerHandler());
        }
    });    // child handler

System.out.println("server is ready .... ");
// 绑定地址
ChannelFuture channelFuture = bootstrap.bind(8000).sync();
```

> io.netty.bootstrap.AbstractBootstrap#bind(int)

```java
    // 进行地址的绑定
    public ChannelFuture bind(int inetPort) {
        return bind(new InetSocketAddress(inetPort));
    }
```

> io.netty.bootstrap.AbstractBootstrap#bind(java.net.SocketAddress)

```java
    // 先做下校验, 在执行端口绑定的操作
    public ChannelFuture bind(SocketAddress localAddress) {
        // 主要对 group  channelFactory两个参数进行了判空操作
        validate();
        return doBind(ObjectUtil.checkNotNull(localAddress, "localAddress"));
    }
```

> io.netty.bootstrap.AbstractBootstrap#doBind

```java
// 端口绑定
private ChannelFuture doBind(final SocketAddress localAddress) {
    // 创建并初始化channel  并 注册handler
    // 重点
    final ChannelFuture regFuture = initAndRegister();
    final Channel channel = regFuture.channel();
    // 如果出现什么异常,则直接返回
    if (regFuture.cause() != null) {
        return regFuture;
    }
    // regFuture此已经操作完成, 则直接调用doBind0 进行绑定
    if (regFuture.isDone()) {
        // At this point we know that the registration was complete and successful.
        ChannelPromise promise = channel.newPromise();
        // 注册相应的成功监听器 以及 如果失败设置失败的标志
        // 重点
        doBind0(regFuture, channel, localAddress, promise);
        return promise;
        // 如果没有操作完成,则注册一个listener,在完成后调用 doBind0 进行绑定
    } else {
 // Registration future is almost always fulfilled already, but just in case it's not.
        final PendingRegistrationPromise promise = new PendingRegistrationPromise(channel);
        regFuture.addListener(new ChannelFutureListener() {
            @Override
            public void operationComplete(ChannelFuture future) throws Exception {
                Throwable cause = future.cause();
                if (cause != null) {
// Registration on the EventLoop failed so fail the ChannelPromise directly to not cause an
// IllegalStateException once we try to access the EventLoop of the Channel.
                    promise.setFailure(cause);
                } else {
                // Registration was successful, so set the correct executor to use.
                    // See https://github.com/netty/netty/issues/2586
                    promise.registered();
                    doBind0(regFuture, channel, localAddress, promise);
                }
            }
        });
        return promise;
    }
}
```

> io.netty.bootstrap.AbstractBootstrap#initAndRegister

```java
 final ChannelFuture initAndRegister() {
        Channel channel = null;
        try {
            // 此处其实就是通过反射, 创建一个通过 channel 执行的class的 实例
            // 此时看的是server端的绑定,故此应该看一下 NioServerSocketChannel的构造器
            // 此处创建了 NioServerSocketChannel
            // 重点
            channel = channelFactory.newChannel();
            // 对创建的channel 进行初始化
            //对NioServerSocketChannel 的初始化
            // 重点
            init(channel);
        } catch (Throwable t) {
            if (channel != null) {
                // channel can be null if newChannel crashed (eg SocketException("too many open files"))
                channel.unsafe().closeForcibly();
                // as the Channel is not registered yet we need to force the usage of the GlobalEventExecutor
                return new DefaultChannelPromise(channel, GlobalEventExecutor.INSTANCE).setFailure(t);
            }
            // as the Channel is not registered yet we need to force the usage of the GlobalEventExecutor
            return new DefaultChannelPromise(new FailedChannel(), GlobalEventExecutor.INSTANCE).setFailure(t);
        }
        // 此时看的是Server端,故此时是吧 NioServerSocketChannel注册到 group
        // 看一下这个注册动作
        // config().group() 获取到的 boss group
        // config().group().register 此操作就是把此channel注册到  boss group的NioEventLoop上
        ChannelFuture regFuture = config().group().register(channel);
        // 如果注册的过程中有什么异常, 那么就执行关闭操作
        if (regFuture.cause() != null) {
            if (channel.isRegistered()) {
                channel.close();
            } else {
                channel.unsafe().closeForcibly();
            }
        }
        return regFuture;
    }
```

> io.netty.channel.ReflectiveChannelFactory#newChannel

```java
// 通过构造器直接 直接实例化一个对象
@Override
public T newChannel() {
    try {
        // 使用 目标类的构造器 来创建一个实例
        return constructor.newInstance();
    } catch (Throwable t) {
        throw new ChannelException("Unable to create Channel from class " + constructor.getDeclaringClass(), t);
    }
}
```

> io.netty.bootstrap.ServerBootstrap#init

```java
// 对创建好的channel进行初始化
@Override
void init(Channel channel) {
    // 设置channelOption值
    setChannelOptions(channel, newOptionsArray(), logger);
    // 设置attribute值
    setAttributes(channel, attrs0().entrySet().toArray(EMPTY_ATTRIBUTE_ARRAY));
    // 得到此channel对应的pipeline
    // 此channel是 NioServerSocketChannel
    ChannelPipeline p = channel.pipeline();
    //  具体的worker, 也就是child
    final EventLoopGroup currentChildGroup = childGroup;
    final ChannelHandler currentChildHandler = childHandler;
    final Entry<ChannelOption<?>, Object>[] currentChildOptions;
    // 这里就是保存对 childGroup的一些设置
    synchronized (childOptions) {
        currentChildOptions = childOptions.entrySet().toArray(EMPTY_OPTION_ARRAY);
    }
    final Entry<AttributeKey<?>, Object>[] currentChildAttrs = childAttrs.entrySet().toArray(EMPTY_ATTRIBUTE_ARRAY);

    p.addLast(new ChannelInitializer<Channel>() {
        @Override
        public void initChannel(final Channel ch) {
            final ChannelPipeline pipeline = ch.pipeline();
            // 处理的handler 是 ServerBootStrap中注册的 server的handler
            ChannelHandler handler = config.handler();
            if (handler != null) {
                pipeline.addLast(handler);
            }
            // 在pipeline中创建 ServerBootstrapAcceptor 处理器,用来处理channel接入事件
            // .......重点 ......
            ch.eventLoop().execute(new Runnable() {
                @Override
                public void run() {
                    pipeline.addLast(new ServerBootstrapAcceptor(
                        ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
                }
            });
        }
    });
}
```

属性的设置：

> io.netty.bootstrap.AbstractBootstrap#setChannelOptions

```java
static void setChannelOptions(
    Channel channel, Map.Entry<ChannelOption<?>, Object>[] options, InternalLogger logger) {
    for (Map.Entry<ChannelOption<?>, Object> e: options) {
        setChannelOption(channel, e.getKey(), e.getValue(), logger);
    }
}
```

> io.netty.bootstrap.AbstractBootstrap#setChannelOption

```java
private static void setChannelOption(
    Channel channel, ChannelOption<?> option, Object value, InternalLogger logger) {
    try {
        // 属性配置
        if (!channel.config().setOption((ChannelOption<Object>) option, value)) {
            logger.warn("Unknown channel option '{}' for channel '{}'", option, channel);
        }
    } catch (Throwable t) {
        logger.warn(
            "Failed to set channel option '{}' with value '{}' for channel '{}'", option, value, channel, t);
    }
}
```

> io.netty.channel.socket.nio.NioServerSocketChannel.NioServerSocketChannelConfig#setOption

```java
// channel属性配置
@Override
public <T> boolean setOption(ChannelOption<T> option, T value) {
    if (PlatformDependent.javaVersion() >= 7 && option instanceof NioChannelOption) {
        return NioChannelOption.setOption(jdkChannel(), (NioChannelOption<T>) option, value);
    }
    return super.setOption(option, value);
}
```

> io.netty.channel.socket.nio.NioChannelOption#setOption

```java
// 配置 channel的属性
@SuppressJava6Requirement(reason = "Usage guarded by java version check")
static <T> boolean setOption(Channel jdkChannel, NioChannelOption<T> option, T value) {
    java.nio.channels.NetworkChannel channel = (java.nio.channels.NetworkChannel) jdkChannel;
    if (!channel.supportedOptions().contains(option.option)) {
        return false;
    }
    if (channel instanceof ServerSocketChannel && option.option == java.net.StandardSocketOptions.IP_TOS) {
        // Skip IP_TOS as a workaround for a JDK bug:
        // See http://mail.openjdk.java.net/pipermail/nio-dev/2018-August/005365.html
        return false;
    }
    try {
        // 属性的设置
        channel.setOption(option.option, value);
        return true;
    } catch (IOException e) {
        throw new ChannelException(e);
    }
}
```

> sun.nio.ch.ServerSocketChannelImpl#setOption

```java
public <T> ServerSocketChannel setOption(SocketOption<T> var1, T var2) throws IOException {
    if (var1 == null) {
        throw new NullPointerException();
    } else if (!this.supportedOptions().contains(var1)) {
        throw new UnsupportedOperationException("'" + var1 + "' not supported");
    } else {
        synchronized(this.stateLock) {
            if (!this.isOpen()) {
                throw new ClosedChannelException();
            } else if (var1 == StandardSocketOptions.IP_TOS) {
                StandardProtocolFamily var4 = Net.isIPv6Available() ? StandardProtocolFamily.INET6 : StandardProtocolFamily.INET;
                Net.setSocketOption(this.fd, var4, var1, var2);
                return this;
            } else {
                if (var1 == StandardSocketOptions.SO_REUSEADDR && Net.useExclusiveBind()) {
                    this.isReuseAddress = (Boolean)var2;
                } else {
                    Net.setSocketOption(this.fd, Net.UNSPEC, var1, var2);
                }

                return this;
            }
        }
    }
}

```

option设置就完成了，下面看一下 添加handler的操作：

```java
p.addLast(new ChannelInitializer<Channel>() {
    @Override
    public void initChannel(final Channel ch) {
        final ChannelPipeline pipeline = ch.pipeline();
        // 处理的handler 是 ServerBootStrap中注册的 server的handler
        ChannelHandler handler = config.handler();
        if (handler != null) {
            pipeline.addLast(handler);
        }
        // 在pipeline中创建 ServerBootstrapAcceptor 处理器,用来处理channel接入事件
        // .......重点 ......
        ch.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                pipeline.addLast(new ServerBootstrapAcceptor(
                    ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
            }
        });
    }
});
```



> io.netty.channel.DefaultChannelPipeline#addLast(io.netty.channel.ChannelHandler...)

```java
    // 向pipeline中添加 handler
    @Override
    public final ChannelPipeline addLast(ChannelHandler... handlers) {
        return addLast(null, handlers);
    }
```

```java
@Override
public final ChannelPipeline addLast(EventExecutorGroup executor, ChannelHandler... handlers) {
    ObjectUtil.checkNotNull(handlers, "handlers");
    // 遍历参数中的 handler,把其添加到 pipeline
    for (ChannelHandler h: handlers) {
        // 如果handler为null，跳过
        if (h == null) {
            break;
        }
        addLast(executor, null, h);
    }
    return this;
}
```

> io.netty.channel.DefaultChannelPipeline#addLast(io.netty.util.concurrent.EventExecutorGroup, java.lang.String, io.netty.channel.ChannelHandler)

```java
    // 添加handler到 pipeline
    @Override
    public final ChannelPipeline addLast(EventExecutorGroup group, String name, ChannelHandler handler) {
        final AbstractChannelHandlerContext newCtx;
        synchronized (this) {
            checkMultiplicity(handler);
            // filterName 为此handler 创建一个名字
            // newContext 创建DefaultChannelHandlerContext 来对 包装handler的上下文内容
            newCtx = newContext(group, filterName(name, handler), handler);
            // 具体的添加动作
            addLast0(newCtx);

// If the registered is false it means that the channel was not registered on an eventLoop yet.
// In this case we add the context to the pipeline and add a task that will call
            // ChannelHandler.handlerAdded(...) once the channel is registered.
            /// 注册回调函数; 也就是在 handler添加成功后,在回调函数中调用callHandlerAdded0
            if (!registered) {
                newCtx.setAddPending();
                callHandlerCallbackLater(newCtx, true);
                return this;
            }
            EventExecutor executor = newCtx.executor();
            if (!executor.inEventLoop()) {
                callHandlerAddedInEventLoop(newCtx, executor);
                return this;
            }
        }
        callHandlerAdded0(newCtx);
        return this;
    }
```

> io.netty.channel.DefaultChannelPipeline#addLast0

```java
// 链表添加
private void addLast0(AbstractChannelHandlerContext newCtx) {
    AbstractChannelHandlerContext prev = tail.prev;
    newCtx.prev = prev;
    newCtx.next = tail;
    prev.next = newCtx;
    tail.prev = newCtx;
}
```

> io.netty.channel.DefaultChannelHandlerContext#DefaultChannelHandlerContext

```java
DefaultChannelHandlerContext(
    DefaultChannelPipeline pipeline, EventExecutor executor, String name, ChannelHandler handler) {
    // 可以看到记录的信息, 此handler所在的pipeline, executor, name,class
    super(pipeline, executor, name, handler.getClass());
    // 记录处理器
    this.handler = handler;
}
```

DefaultChannelHandlerContext的类图:

![](DefaultChannelHandlerContext.png)

> io.netty.channel.AbstractChannelHandlerContext#AbstractChannelHandlerContext

```java
// handler的上下文, 记跟此handler相关的信息
AbstractChannelHandlerContext(DefaultChannelPipeline pipeline, EventExecutor executor, String name, Class<? extends ChannelHandler> handlerClass) {
    // 此 handler的name
    this.name = ObjectUtil.checkNotNull(name, "name");
    // 此handler所在的pipeline
    this.pipeline = pipeline;
    // 默认此 线程池 为null
    this.executor = executor;
    // 此handler执行的mask计算
    this.executionMask = mask(handlerClass);
    // Its ordered if its driven by the EventLoop or the given Executor is an instanceof OrderedEventExecutor.
    ordered = executor == null || executor instanceof OrderedEventExecutor;
}
```

添加到pipeline后，会调用pipeline中所有handler的handlerAdd事件的处理函数：

> io.netty.channel.DefaultChannelPipeline#callHandlerAdded0

```java
// 调用pipeline中handlerAdd 事件的处理函数
private void callHandlerAdded0(final AbstractChannelHandlerContext ctx) {
    try {
        // 最终会调用到 ChannelInitializer中的 handlerAdd--> initChannel方法
        ctx.callHandlerAdded();
    } catch (Throwable t) {
        boolean removed = false;
        try {
            atomicRemoveFromHandlerList(ctx);
            ctx.callHandlerRemoved();
            removed = true;
        } catch (Throwable t2) {
            if (logger.isWarnEnabled()) {
                logger.warn("Failed to remove a handler: " + ctx.name(), t2);
            }
        }
        if (removed) {
            fireExceptionCaught(new ChannelPipelineException(
                ctx.handler().getClass().getName() +
                ".handlerAdded() has thrown an exception; removed.", t));
        } else {
            fireExceptionCaught(new ChannelPipelineException(
                ctx.handler().getClass().getName() +
         ".handlerAdded() has thrown an exception; also failed to remove.", t));
        }
    }
}
```

> io.netty.channel.AbstractChannelHandlerContext#callHandlerAdded

```java
    // 调用handlerAdd 事件的处理函数
    final void callHandlerAdded() throws Exception {
        // 最终会调用到 ChannelInitializer中的 handlerAdd--> initChannel方法
        if (setAddComplete()) {
            handler().handlerAdded(this);
        }
    }
```

> io.netty.channel.DefaultChannelHandlerContext#handler

```java
@Override
public ChannelHandler handler() {
    return handler;
}
```

到这里就从刚才创建的handler上下文中返回handler，还记得此添加handler的操作吗？真正的handler是在参数中指定的哦，回顾一下：

```java
// 此可以看到, 此处添加的handler其实就是ChannelInitializer
p.addLast(new ChannelInitializer<Channel>() {
    @Override
    public void initChannel(final Channel ch) {
        final ChannelPipeline pipeline = ch.pipeline();
        // 处理的handler 是 ServerBootStrap中注册的 server的handler
        ChannelHandler handler = config.handler();
        if (handler != null) {
            pipeline.addLast(handler);
        }
        // 在pipeline中创建 ServerBootstrapAcceptor 处理器,用来处理channel接入事件
        // .......重点 ......
        ch.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                pipeline.addLast(new ServerBootstrapAcceptor(
                    ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
            }
        });
    }
});
```

也就是说此处返回的hanler为ChannelInitializer，然后再调用handler的 handlerAdded函数：

> io.netty.channel.ChannelInitializer#handlerAdded

```java
// handlerAdd 事件的处理函数
@Override
public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
    // 此channel注册完成后再进行 后面的初始化操作
    if (ctx.channel().isRegistered()) {
        if (initChannel(ctx)) {
            // We are done with init the Channel, removing the initializer now.
            removeState(ctx);
        }
    }
}
```



```java
// 对channel进行初始化操作
@SuppressWarnings("unchecked")
private boolean initChannel(ChannelHandlerContext ctx) throws Exception {
    if (initMap.add(ctx)) { // Guard against re-entrance.
        try {
            /**
                 * 在此处调用子类复写的  initChannel方法
                 * 此initChannel 就是用户复写的 方法了
                 */
            initChannel((C) ctx.channel());
        } catch (Throwable cause) {
            // Explicitly call exceptionCaught(...) as we removed the handler before calling initChannel(...).
            // We do so to prevent multiple calls to initChannel(...).
            exceptionCaught(ctx, cause);
        } finally {
            ChannelPipeline pipeline = ctx.pipeline();
            // 当最后执行完 上面的handler后, 会进行移除
            // 也就是说 initChannel方法只会执行一次
            // ********重点 **********
            if (pipeline.context(this) != null) {
                pipeline.remove(this);
            }
        }
        return true;
    }
    return false;
}
```

也就是此initChannel((C) ctx.channel()) 就是用户定义的方法了：

```java
// 也就是会调用这里的 initChannel 方法
p.addLast(new ChannelInitializer<Channel>() {
    @Override
    public void initChannel(final Channel ch) {
        final ChannelPipeline pipeline = ch.pipeline();
        ChannelHandler handler = config.handler();
        if (handler != null) {
            pipeline.addLast(handler);
        }
        ch.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                pipeline.addLast(new ServerBootstrapAcceptor(
                    ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
            }
        });
    }
});
```

执行完initChannel后移除此方法对应的handler，

> io.netty.channel.DefaultChannelPipeline#context(io.netty.channel.ChannelHandler)

```java
// 此是 在pipeline中查找 是否存在参数中的handler
@Override
public final ChannelHandlerContext context(ChannelHandler handler) {
    ObjectUtil.checkNotNull(handler, "handler");

    AbstractChannelHandlerContext ctx = head.next;
    for (;;) {

        if (ctx == null) {
            return null;
        }
        // 如果存在,则返回此handler所在的 AbstractChannelHandlerContext
        if (ctx.handler() == handler) {
            return ctx;
        }
        ctx = ctx.next;
    }
}
```

> io.netty.channel.DefaultChannelPipeline#remove(io.netty.channel.ChannelHandler)

```java
// 从pipeline中移除一个handler的操作
@Override
public final ChannelPipeline remove(ChannelHandler handler) {
    remove(getContextOrDie(handler));
    return this;
}
```

> io.netty.channel.DefaultChannelPipeline#remove(io.netty.channel.AbstractChannelHandlerContext)

```java
// 移除一个handler
private AbstractChannelHandlerContext remove(final AbstractChannelHandlerContext ctx) {
    assert ctx != head && ctx != tail;

    synchronized (this) {
        // 真正的移除操作
        atomicRemoveFromHandlerList(ctx);

        if (!registered) {
            callHandlerCallbackLater(ctx, false);
            return ctx;
        }
        EventExecutor executor = ctx.executor();
        if (!executor.inEventLoop()) {
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    callHandlerRemoved0(ctx);
                }
            });
            return ctx;
        }
    }
    // 调用handlerRemove 的事件处理函数
    callHandlerRemoved0(ctx);
    return ctx;
}
```

> io.netty.channel.DefaultChannelPipeline#atomicRemoveFromHandlerList

```java
// 从链表中删除元素的操作
private synchronized void atomicRemoveFromHandlerList(AbstractChannelHandlerContext ctx) {
    AbstractChannelHandlerContext prev = ctx.prev;
    AbstractChannelHandlerContext next = ctx.next;
    prev.next = next;
    next.prev = prev;
}
```

> io.netty.channel.DefaultChannelPipeline#callHandlerRemoved0

```java
    // 调用handlerRemove的事件处理函数
    private void callHandlerRemoved0(final AbstractChannelHandlerContext ctx) {
        // Notify the complete removal.
        try {
            ctx.callHandlerRemoved();
        } catch (Throwable t) {
            fireExceptionCaught(new ChannelPipelineException(
                    ctx.handler().getClass().getName() + ".handlerRemoved() has thrown an exception.", t));
        }
    }
```

> io.netty.channel.AbstractChannelHandlerContext#callHandlerRemoved

```java
// 调用handlerRemoved事件的处理函数
final void callHandlerRemoved() throws Exception {
    try {
        // Only call handlerRemoved(...) if we called handlerAdded(...) before.
        if (handlerState == ADD_COMPLETE) {
            handler().handlerRemoved(this);
        }
    } finally {
        // Mark the handler as removed in any case.
        setRemoved();
    }
}
```

调用到这里，就想pipeline中添加一个ChannelInitializer，在此handler的initChannel中，做了两件事：

1. 添加此channel配置时添加的 handler到 pipeline
2. 添加ServerBootstrapAcceptor 到pipeline中。(**此handler很重要**)

第一步的处理器的配置，回顾一下：

```java
ServerBootstrap bootstrap = new ServerBootstrap()
    .group(parent, child)
    .channel(NioServerSocketChannel.class)
    .option(ChannelOption.SO_BACKLOG, 128)
    //.option(ChannelOption.SO_KEEPALIVE, true)
    // 就是此handler了, 是否想起来了?
    .handler(new LoggingHandler())  // parent handler
    .childHandler(new ChannelInitializer<SocketChannel>() {
        @Override
        protected void initChannel(SocketChannel ch) throws Exception {
            ChannelPipeline pipeline = ch.pipeline();
            pipeline.addLast(new ServerHandler());
        }
    });    // child handler
```

好了，到这里注册handler操作，以及initChannel的操作就告一段落了。

在回顾一下，咱们说了这么多的开头是啥：

```java
    final ChannelFuture initAndRegister() {
        Channel channel = null;
        try {
            // 此处其实就是通过反射, 创建一个通过 channel 执行的class的 实例
            // 此时看的是server端的绑定,故此应该看一下 NioServerSocketChannel的构造器
            // 此处创建了 NioServerSocketChannel
            // 重点
            channel = channelFactory.newChannel();
            // 对创建的channel 进行初始化
            // 重点
            // 别掉链子哦，刚在的一大段操作，全在init此函数
            init(channel);
        } catch (Throwable t) {
            if (channel != null) {
                channel.unsafe().closeForcibly();
                return new DefaultChannelPromise(channel, GlobalEventExecutor.INSTANCE).setFailure(t);
            }
            return new DefaultChannelPromise(new FailedChannel(), GlobalEventExecutor.INSTANCE).setFailure(t);
        }
        // 此时看的是Server端,故此时是吧 NioServerSocketChannel注册到 group
        // 看一下这个注册动作
        // config().group() 获取到的 boss group
        // config().group().register 此操作就是把此channel注册到  boss group的NioEventLoop上
        ChannelFuture regFuture = config().group().register(channel);
        // 如果注册的过程中有什么异常, 那么就执行关闭操作
        if (regFuture.cause() != null) {
            if (channel.isRegistered()) {
                channel.close();
            } else {
                channel.unsafe().closeForcibly();
            }
        }
        return regFuture;
    }
```

上面的init函数说完了，咱们就看下一步的注册操作，看起来是吧此初始化好的channel注册到一个group中；此group在上面的注释说的也比较清楚了，看一下代码：

> io.netty.channel.MultithreadEventLoopGroup#register(io.netty.channel.Channel)

```java
    // MultithreadEventLoopGroup下后多个NioEventLoop,此处的next()实现选择一个 NioEventLoop来进行注册
    // 故后面的 register是NioEventLoop的父类 SingleThreadEventLoop的操作
    @Override
    public ChannelFuture register(Channel channel) {
        return next().register(channel);
    }
```

```java
    public EventLoop next() {
        return (EventLoop) super.next();
    }
	// 此chooser是否还有印象,就是在刚开始创建NioEventLoopGroup时创建一个选择器
// 对就在这里使用上了
    public EventExecutor next() {
        return chooser.next();
    }
```

此chooser的实现一:

```java
private static final class GenericEventExecutorChooser implements EventExecutorChooser {
    private final AtomicInteger idx = new AtomicInteger();
    // 存储具体的 NioeventLoop
    private final EventExecutor[] executors;

    GenericEventExecutorChooser(EventExecutor[] executors) {
        this.executors = executors;
    }
    @Override
    // 这里了,看这里哦
    // 递增 取 余数
    public EventExecutor next() {
        return executors[Math.abs(idx.getAndIncrement() % executors.length)];
    }
}
```

此chooser的实现二:

```java
private static final class PowerOfTwoEventExecutorChooser implements EventExecutorChooser {
    private final AtomicInteger idx = new AtomicInteger();
    private final EventExecutor[] executors;

    PowerOfTwoEventExecutorChooser(EventExecutor[] executors) {
        this.executors = executors;
    }

    @Override
    // 这里哦, 这里是 与 操作
    public EventExecutor next() {
        return executors[idx.getAndIncrement() & executors.length - 1];
    }
}
```

这里就通过算法选择出一个NioEventLoop来进行注册:

> io.netty.channel.SingleThreadEventLoop#register(io.netty.channel.Channel)

```java
    // 注册一个channel到selector
    @Override
    public ChannelFuture register(Channel channel) {
        return register(new DefaultChannelPromise(channel, this));
    }
```

创建一个Promise，看一下此类图，本质是一个Future

![](DefaultChannelPromise.png)

> io.netty.channel.SingleThreadEventLoop#register(io.netty.channel.ChannelPromise)

```java
    // 注册
    @Override
    public ChannelFuture register(final ChannelPromise promise) {
        ObjectUtil.checkNotNull(promise, "promise");
        // 具体的注册动作
        promise.channel().unsafe().register(this, promise);
        return promise;
    }
```

> io.netty.channel.AbstractChannel.AbstractUnsafe#register

```java
// 注册一个channel到 EventLoop
@Override
public final void register(EventLoop eventLoop, final ChannelPromise promise) {
    ObjectUtil.checkNotNull(eventLoop, "eventLoop");
    // 判断是否已经注册
    if (isRegistered()) {
        promise.setFailure(new IllegalStateException("registered to an event loop already"));
        return;
    }
    //
    if (!isCompatible(eventLoop)) {
        promise.setFailure(
            new IllegalStateException("incompatible event loop type: " + eventLoop.getClass().getName()));
        return;
    }

    AbstractChannel.this.eventLoop = eventLoop;

    // 判断eventLoop是否是当前线程
    // 如果是,则直接调用register0,来进行注册
    if (eventLoop.inEventLoop()) {
        // 具体的注册动作
        register0(promise);
    } else {
        try {
            // 如果不是,则提交一个任务, 进行注册动作
            eventLoop.execute(new Runnable() {
                @Override
                public void run() {
                    register0(promise);
                }
            });
        } catch (Throwable t) {
            logger.warn(
                "Force-closing a channel whose registration task was not accepted by an event loop: {}",
                AbstractChannel.this, t);
            closeForcibly();
            closeFuture.setClosed();
            safeSetFailure(promise, t);
        }
    }
}
```

> io.netty.channel.AbstractChannel.AbstractUnsafe#register0

```java
// 具体的注册 channel到 selector的操作
private void register0(ChannelPromise promise) {
    try {
        // check if the channel is still open as it could be closed in the mean time when the register
        // call was outside of the eventLoop
        if (!promise.setUncancellable() || !ensureOpen(promise)) {
            return;
        }
        boolean firstRegistration = neverRegistered;
        // 注册
        doRegister();
        neverRegistered = false;
        registered = true;

        // Ensure we call handlerAdded(...) before we actually notify the promise. This is needed as the
        // user may already fire events through the pipeline in the ChannelFutureListener.
        // 注册完成后, 查看是否需要回调函数  HandlerAdd
        /**
        * 1. 就是在此调用.childHandler(new CustomServerInitializer()); 的方法,向pipeline中注册handler
        * // 最终会调用到 ChannelInitializer中的 handlerAdd--> initChannel方法
          */
        pipeline.invokeHandlerAddedIfNeeded();

        safeSetSuccess(promise);
        // 回调 channelRegistered 函数
        pipeline.fireChannelRegistered();
        // Only fire a channelActive if the channel has never been registered. This prevents firing
        // multiple channel actives if the channel is deregistered and re-registered.
        // 当次channelactive时,会调用 channelActive方法
        if (isActive()) {
            if (firstRegistration) {
                // 回调 channelActive函数
                // 真实的绑定操作
                pipeline.fireChannelActive();
            } else if (config().isAutoRead()) {
                // 如果设置了自动读, 则开始进行数据的读取
                beginRead();
            }
        }
    } catch (Throwable t) {
        // Close the channel directly to avoid FD leak.
        closeForcibly();
        closeFuture.setClosed();
        safeSetFailure(promise, t);
    }
}
```

> io.netty.channel.nio.AbstractNioChannel#doRegister

```java
// 注册操作;注册channel到selector上
@Override
protected void doRegister() throws Exception {
    boolean selected = false;
    for (;;) {
        try {
            // 注册动作
            selectionKey = javaChannel().register(eventLoop().unwrappedSelector(), 0, this);
            return;
        } catch (CancelledKeyException e) {
            if (!selected) {
                // Force the Selector to select now as the "canceled" SelectionKey may still be
                // cached and not removed because no Select.select(..) operation was called yet.
                eventLoop().selectNow();
                selected = true;
            } else {
                // We forced a select operation on the selector before but the SelectionKey is still cached
                // for whatever reason. JDK bug ?
                throw e;
            }
        }
    }
}
```

> java.nio.channels.spi.AbstractSelectableChannel#register

此就是jdk的操作了，就不进行深入查看了。

然后，咱们在进行回溯，代码看的比较深了，贴出原来了进行下回顾：

```java
// 端口绑定
private ChannelFuture doBind(final SocketAddress localAddress) {
    // 创建并初始化channel  并 注册handler
    // 前面一大部分，都是此函数 initAndRegister的深入查看。
    // 通过前面一大段的分析,此函数算告一段落了
    final ChannelFuture regFuture = initAndRegister();
    final Channel channel = regFuture.channel();
    // 如果出现什么异常,则直接返回
    if (regFuture.cause() != null) {
        return regFuture;
    }
    // regFuture此已经操作完成, 则直接调用doBind0 进行绑定
    if (regFuture.isDone()) {
        // At this point we know that the registration was complete and successful.
        ChannelPromise promise = channel.newPromise();
        // 注册相应的成功监听器 以及 如果失败设置失败的标志
        // 端口绑定操作
        doBind0(regFuture, channel, localAddress, promise);
        return promise;
        // 如果没有操作完成,则注册一个listener,在完成后调用 doBind0 进行绑定
    } else {
        final PendingRegistrationPromise promise = new PendingRegistrationPromise(channel);
        regFuture.addListener(new ChannelFutureListener() {
            @Override
            public void operationComplete(ChannelFuture future) throws Exception {
                Throwable cause = future.cause();
                if (cause != null) {
                    promise.setFailure(cause);
                } else {
                    promise.registered();

                    doBind0(regFuture, channel, localAddress, promise);
                }
            }
        });
        return promise;
    }
}
```

前面一大段，都是initAndRegister的深入查看，下面继续查看咱们的端口绑定：

```java
        // 端口绑定操作
        doBind0(regFuture, channel, localAddress, promise);
```

> io.netty.bootstrap.AbstractBootstrap#doBind0

```java
private static void doBind0(
    final ChannelFuture regFuture, final Channel channel,
    final SocketAddress localAddress, final ChannelPromise promise) {
    // This method is invoked before channelRegistered() is triggered.  Give user handlers a chance to set up
    // the pipeline in its channelRegistered() implementation.
    channel.eventLoop().execute(new Runnable() {
        @Override
        public void run() {
            if (regFuture.isSuccess()) {
                // 注册到selector成功了, 则进行端口的绑定
                channel.bind(localAddress, promise).addListener(ChannelFutureListener.CLOSE_ON_FAILURE);
            } else {
                promise.setFailure(regFuture.cause());
            }
        }
    });
}
```

> io.netty.channel.AbstractChannel#bind(java.net.SocketAddress, io.netty.channel.ChannelPromise)

```java
    // 端口绑定
    @Override
    public ChannelFuture bind(SocketAddress localAddress, ChannelPromise promise) {
        return pipeline.bind(localAddress, promise);
    }
```

```java
@Override
public final ChannelFuture bind(SocketAddress localAddress, ChannelPromise promise) {
    return tail.bind(localAddress, promise);
}
```

> io.netty.channel.AbstractChannelHandlerContext#bind(java.net.SocketAddress, io.netty.channel.ChannelPromise)

```java
// 端口的绑定操作
@Override
public ChannelFuture bind(final SocketAddress localAddress, final ChannelPromise promise) {
    ObjectUtil.checkNotNull(localAddress, "localAddress");
    if (isNotValidPromise(promise, false)) {
        // cancelled
        return promise;
    }
    // 调用下一个Outbound进行绑定, 此处应该是head
    final AbstractChannelHandlerContext next = findContextOutbound(MASK_BIND);
    EventExecutor executor = next.executor();
    if (executor.inEventLoop()) {
        // 绑定
        next.invokeBind(localAddress, promise);
    } else {
        safeExecute(executor, new Runnable() {
            @Override
            public void run() {
                next.invokeBind(localAddress, promise);
            }
        }, promise, null, false);
    }
    return promise;
}
```

> io.netty.channel.AbstractChannelHandlerContext#invokeBind

```java
// 调用handler的绑定端口操作
private void invokeBind(SocketAddress localAddress, ChannelPromise promise) {
    if (invokeHandler()) {
        try {
            ((ChannelOutboundHandler) handler()).bind(this, localAddress, promise);
        } catch (Throwable t) {
            notifyOutboundHandlerException(t, promise);
        }
    } else {
        bind(localAddress, promise);
    }
}
```

> io.netty.channel.DefaultChannelPipeline.HeadContext#bind

```java
// 真实的端口绑定操作
@Override
public void bind(
    ChannelHandlerContext ctx, SocketAddress localAddress, ChannelPromise promise) {
    unsafe.bind(localAddress, promise);
}
```

> io.netty.channel.AbstractChannel.AbstractUnsafe#bind

```java
// 端口绑定操作
@Override
public final void bind(final SocketAddress localAddress, final ChannelPromise promise) {
    assertEventLoop();

    if (!promise.setUncancellable() || !ensureOpen(promise)) {
        return;
    }

    // See: https://github.com/netty/netty/issues/576
    if (Boolean.TRUE.equals(config().getOption(ChannelOption.SO_BROADCAST)) &&
        localAddress instanceof InetSocketAddress &&
        !((InetSocketAddress) localAddress).getAddress().isAnyLocalAddress() &&
        !PlatformDependent.isWindows() && !PlatformDependent.maybeSuperUser()) {
        // Warn a user about the fact that a non-root user can't receive a
        // broadcast packet on *nix if the socket is bound on non-wildcard address.
        logger.warn(
            "A non-root user can't receive a broadcast packet if the socket " +
            "is not bound to a wildcard address; binding to a non-wildcard " +
            "address (" + localAddress + ") anyway as requested.");
    }

    boolean wasActive = isActive();
    try {
        // 绑定操作 jdk的nio操作
        doBind(localAddress);
    } catch (Throwable t) {
        safeSetFailure(promise, t);
        closeIfClosed();
        return;
    }

    if (!wasActive && isActive()) {
        invokeLater(new Runnable() {
            @Override
            public void run() {
                // 调用pipeline中的 channelActive
                pipeline.fireChannelActive();
            }
        });
    }
    safeSetSuccess(promise);
}
```

> io.netty.channel.socket.nio.NioServerSocketChannel#doBind

```java
// 端口的绑定操作
@SuppressJava6Requirement(reason = "Usage guarded by java version check")
@Override
protected void doBind(SocketAddress localAddress) throws Exception {
    // 进行端口的绑定操作  此处就是 jdk的调用了
    if (PlatformDependent.javaVersion() >= 7) {
        javaChannel().bind(localAddress, config.getBacklog());
    } else {
        javaChannel().socket().bind(localAddress, config.getBacklog());
    }
}
```

> sun.nio.ch.ServerSocketChannelImpl#bind

最终的端口绑定，就是JDK中的绑定操作了。到这里，端口的绑定就完成了。

















































