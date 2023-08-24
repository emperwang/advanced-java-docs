[TOC]

# ServerBootstrap的初始化

本篇说一下nettyserver端的入口函数ServerBootStrap的初始化以及使用。

回顾一下开头的示例代码：

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
```

先看一下其类图:

![](Bootstrap.png)

> io.netty.bootstrap.ServerBootstrap#ServerBootstrap()

```java
public ServerBootstrap() { }
```

> io.netty.bootstrap.ServerBootstrap#group

```java
public ServerBootstrap group(EventLoopGroup parentGroup, EventLoopGroup childGroup) {
    super.group(parentGroup);   // 记录boss group
    if (this.childGroup != null) {
        throw new IllegalStateException("childGroup set already");
    }
    // 记录worker group
    this.childGroup = ObjectUtil.checkNotNull(childGroup, "childGroup");
    return this;
}
```

> io.netty.bootstrap.AbstractBootstrap#group(io.netty.channel.EventLoopGroup)

```java
    public B group(EventLoopGroup group) {
        ObjectUtil.checkNotNull(group, "group");
        if (this.group != null) {
            throw new IllegalStateException("group set already");
        }
        // 记录boss group
        this.group = group;
        return self();
    }
```

> io.netty.bootstrap.AbstractBootstrap#channel

```java
    // 创建channel的工厂类 就是返回获取其 无参构造器,之后通过调用无参构造器来进行实例的创建
    public B channel(Class<? extends C> channelClass) {
        return channelFactory(new ReflectiveChannelFactory<C>(
                ObjectUtil.checkNotNull(channelClass, "channelClass")
        ));
    }
```

> io.netty.channel.ReflectiveChannelFactory#ReflectiveChannelFactory

```java
public ReflectiveChannelFactory(Class<? extends T> clazz) {
    ObjectUtil.checkNotNull(clazz, "clazz");
    try {
        // 反射获取目标类的构造器
        this.constructor = clazz.getConstructor();
    } catch (NoSuchMethodException e) {
   throw new IllegalArgumentException("Class " + StringUtil.simpleClassName(clazz) + " does not have a public non-arg constructor", e);
    }
}

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

> io.netty.bootstrap.AbstractBootstrap#channelFactory(io.netty.channel.ChannelFactory<? extends C>)

```java
// 可以看此此处的工厂类是通过类型强制转换得到的
@SuppressWarnings({ "unchecked", "deprecation" })
public B channelFactory(io.netty.channel.ChannelFactory<? extends C> channelFactory) {
    return channelFactory((ChannelFactory<C>) channelFactory);
}

public B channelFactory(ChannelFactory<? extends C> channelFactory) {
    ObjectUtil.checkNotNull(channelFactory, "channelFactory");
    if (this.channelFactory != null) {
        throw new IllegalStateException("channelFactory set already");
    }
    // 创建channel的工厂类
    this.channelFactory = channelFactory;
    return self();
}
```

> io.netty.bootstrap.AbstractBootstrap#option

```java
public <T> B option(ChannelOption<T> option, T value) {
    ObjectUtil.checkNotNull(option, "option");
    synchronized (options) {
        if (value == null) {
            options.remove(option);
        } else {
            // 记录channel的配置
            options.put(option, value);
        }
    }
    return self();
}

// 返回自身
private B self() {
    return (B) this;
}
```

> io.netty.bootstrap.AbstractBootstrap#handler(io.netty.channel.ChannelHandler)

```java
    public B handler(ChannelHandler handler) {
        this.handler = ObjectUtil.checkNotNull(handler, "handler");
        return self();
    }
```

```java
    public ServerBootstrap childHandler(ChannelHandler childHandler) {
        // child 处理器
        this.childHandler = ObjectUtil.checkNotNull(childHandler, "childHandler");
        return this;
    }
```

看完这些配置，可以看出ServerBootstrap记录了配置，handler的记录等操作





