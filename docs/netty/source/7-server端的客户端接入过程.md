[TOC]

# server端的客户端的接入

这里接着NioEventLoop的处理来看一下server端对客户端接入的操作。

> io.netty.channel.nio.NioEventLoop#run

```java
/**
     * todo  重要 重要
     * 此函数就是具体工作的入口点
     * 如果是 boss呢, 此函数就是处理 刚accept上的socket,并把其注册到  worker上 进行具体的读写操作
     * 如果是worker呢, 此函数就是处理 从boss注册到此上的socket的具体的读写事件
     * 1. 先看一下 boss的处理逻辑
     * 2. 再看一下worker的处理逻辑
     */
@Override
protected void run() {
    int selectCnt = 0;
    for (;;) {
        try {
            int strategy;
            try {
                /**
                     * 此处的策略选择:
                     * 1. 有任务,则执行一次 selectNow()
                     * 2. 没有任务则返回 select策略
                     */
    strategy = selectStrategy.calculateStrategy(selectNowSupplier, hasTasks());
                switch (strategy) {
                    case SelectStrategy.CONTINUE:
                        continue;
                    case SelectStrategy.BUSY_WAIT:
                    case SelectStrategy.SELECT:
                        long curDeadlineNanos = nextScheduledTaskDeadlineNanos();
                        if (curDeadlineNanos == -1L) {
                            curDeadlineNanos = NONE; // nothing on the calendar
                        }
                        nextWakeupNanos.set(curDeadlineNanos);
                        try {
                            if (!hasTasks()) {
                                strategy = select(curDeadlineNanos);
                            }
                        } finally {
                            nextWakeupNanos.lazySet(AWAKE);
                        }
                    default:
                }
            } catch (IOException e) {
                rebuildSelector0();
                selectCnt = 0;
                handleLoopException(e);
                continue;
            }
            // 增加select 次数
            selectCnt++;
            cancelledKeys = 0;
            needsToSelectAgain = false;
            final int ioRatio = this.ioRatio;
            boolean ranTasks;
            if (ioRatio == 100) {
                try {
                    if (strategy > 0) {
                        // 处理select 事件
                        processSelectedKeys();
                    }
                } finally {
                    // Ensure we always run tasks.
                    // 处理taskQueue 以及 scheduledTaskQueue 中的任务
                    ranTasks = runAllTasks();
                }
            } else if (strategy > 0) {
                final long ioStartTime = System.nanoTime();
                try {
                    processSelectedKeys();
                } finally {
                    // Ensure we always run tasks.
                    final long ioTime = System.nanoTime() - ioStartTime;
                    ranTasks = runAllTasks(ioTime * (100 - ioRatio) / ioRatio);
                }
            } else {
            ranTasks = runAllTasks(0); // This will run the minimum number of tasks
            }
            if (ranTasks || strategy > 0) {
                if (selectCnt > MIN_PREMATURE_SELECTOR_RETURNS && logger.isDebugEnabled()) {
                    logger.debug("Selector.select() returned prematurely {} times in a row for Selector {}.",selectCnt - 1, selector);
                }
                selectCnt = 0;
            } else if (unexpectedSelectorWakeup(selectCnt)) { // Unexpected wakeup (unusual case)
                selectCnt = 0;
            }
        } catch (CancelledKeyException e) {
            // Harmless exception - log anyway
            if (logger.isDebugEnabled()) {
                logger.debug(CancelledKeyException.class.getSimpleName() + " raised by a Selector {} - JDK bug?",selector, e);
            }
        } catch (Throwable t) {
            handleLoopException(t);
        }
        // Always handle shutdown even if the loop processing threw an exception.
        try {
            if (isShuttingDown()) {
                closeAll();
                if (confirmShutdown()) {
                    return;
                }
            }
        } catch (Throwable t) {
            handleLoopException(t);
        }
    }
}
```

> io.netty.channel.nio.NioEventLoop#processSelectedKeys

```java
// 对selector事件的处理
private void processSelectedKeys() {
    if (selectedKeys != null) {
        processSelectedKeysOptimized();
    } else {
        /**
             * todo  处理select查询到的事件
             */
        processSelectedKeysPlain(selector.selectedKeys());
    }
}

```

> io.netty.channel.nio.NioEventLoop#processSelectedKeysPlain

```java
// 处理selector的事件
private void processSelectedKeysPlain(Set<SelectionKey> selectedKeys) {
    // 如果没有查询到,则直接返回了
    if (selectedKeys.isEmpty()) {
        return;
    }
    // 获取 查询到的key的遍历器
    Iterator<SelectionKey> i = selectedKeys.iterator();
    // 循环遍历查询到的selectKey,来进行处理
    for (;;) {
        // 获取key
        final SelectionKey k = i.next();
        // 获取其 attach的 对象
        final Object a = k.attachment();
        // 从selectKey中 删除此要处理的key  k
        i.remove();
        if (a instanceof AbstractNioChannel) {
            // 继续处理
            processSelectedKey(k, (AbstractNioChannel) a);
        } else {
            @SuppressWarnings("unchecked")
            NioTask<SelectableChannel> task = (NioTask<SelectableChannel>) a;
            processSelectedKey(k, task);
        }

        if (!i.hasNext()) {
            break;
        }
        // 再执行一次select 操作, 并遍历处理
        if (needsToSelectAgain) {
            selectAgain();
            selectedKeys = selector.selectedKeys();

            // Create the iterator again to avoid ConcurrentModificationException
            if (selectedKeys.isEmpty()) {
                break;
            } else {
                i = selectedKeys.iterator();
            }
        }
    }
}
```

> io.netty.channel.nio.NioEventLoop#processSelectedKey

```java
// 对selector 事件的处理
private void processSelectedKey(SelectionKey k, AbstractNioChannel ch) {
    // channel对应的处理函数
    final AbstractNioChannel.NioUnsafe unsafe = ch.unsafe();
    if (!k.isValid()) {
        final EventLoop eventLoop;
        try {
            eventLoop = ch.eventLoop();
        } catch (Throwable ignored) {
            return;
        }
        if (eventLoop == this) {
            unsafe.close(unsafe.voidPromise());
        }
        return;
    }

    try {
        // 获取k上就绪的事件
        int readyOps = k.readyOps();
        // We first need to call finishConnect() before try to trigger a read(...) or write(...) as otherwise
        // the NIO JDK channel implementation may throw a NotYetConnectedException.
        // 处理connect事件
        if ((readyOps & SelectionKey.OP_CONNECT) != 0) {
            int ops = k.interestOps();
            ops &= ~SelectionKey.OP_CONNECT;
            // 清除connect事件
            k.interestOps(ops);
            // finishConnect事件的处理
            unsafe.finishConnect();
        }

        // Process OP_WRITE first as we may be able to write some queued buffers and so free memory.
        // 处理write事件
        if ((readyOps & SelectionKey.OP_WRITE) != 0) {
            ch.unsafe().forceFlush();
        }
        /**
             * 处理读事件
             * 1. 如果是NioServerSocketChannel  那么会执行NioMessageUnsafe 读取操作
             * 2. 如果是NioSocketChannel       NioByteUnsafe 读取操作
             * 3. 调用child类的  .childHandler(new CustomServerInitializer());  方法来添加handler到pipeline中
             */
        if ((readyOps & (SelectionKey.OP_READ | SelectionKey.OP_ACCEPT)) != 0 || readyOps == 0) {
            // 重点  读操作
            unsafe.read();
        }
    } catch (CancelledKeyException ignored) {
        unsafe.close(unsafe.voidPromise());
    }
}
```

> io.netty.channel.nio.AbstractNioMessageChannel.NioMessageUnsafe#read

```java
// server端channel读取操作
@Override
public void read() {
    assert eventLoop().inEventLoop();
    // 获取此channel的 配置
    final ChannelConfig config = config();
    // 获取此channel的 pipeline
    final ChannelPipeline pipeline = pipeline();
    // 在DefaultChannelConfig中创建了recvBuffer的分配器
    final RecvByteBufAllocator.Handle allocHandle = unsafe().recvBufAllocHandle();
    allocHandle.reset(config);

    boolean closed = false;
    Throwable exception = null;
    try {
        try {
            do {
                // 读取连接的的NioSocketChannel
                // 并放到readBuf 这个list中
                // 具体读
                int localRead = doReadMessages(readBuf);
                if (localRead == 0) {
                    break;
                }
                if (localRead < 0) {
                    closed = true;
                    break;
                }
                // 统计信息增加
                allocHandle.incMessagesRead(localRead);
            } while (allocHandle.continueReading());
        } catch (Throwable t) {
            exception = t;
        }
        // 获取读取到了 多少个 NioSocketChannel,也就是客户端
        int size = readBuf.size();
        // 遍历读取到的 NioSocketChannel, 并把其放入到pipeline的下一个进行操作
        // 此处的下一个pipeline handler应该是 Acceptor那个handler, 此handler就会把
        // 接收到的socketChannel注册到childGroup中.
        for (int i = 0; i < size; i ++) {
            readPending = false;
            pipeline.fireChannelRead(readBuf.get(i));
        }
        readBuf.clear();
        allocHandle.readComplete();
        // channelReadComplete操作
        pipeline.fireChannelReadComplete();
        if (exception != null) {
            closed = closeOnReadError(exception);
            // 异常处理
            pipeline.fireExceptionCaught(exception);
        }

        if (closed) {
            inputShutdown = true;
            if (isOpen()) {
                close(voidPromise());
            }
        }
    } finally {
        if (!readPending && !config.isAutoRead()) {
            removeReadOp();
        }
    }
}
}
```

> io.netty.channel.socket.nio.NioServerSocketChannel#doReadMessages

```java
// server端 读取 客户端的连接
@Override
protected int doReadMessages(List<Object> buf) throws Exception {
    // 接收新的客户端连接
    SocketChannel ch = SocketUtils.accept(javaChannel());
    try {
        // 如果接收的连接不为null, 则封装为NioSocketChannel
        if (ch != null) {
            //  把读取的客户端连接  放入到 参数列表中
            buf.add(new NioSocketChannel(this, ch));
            return 1;
        }
    } catch (Throwable t) {
        logger.warn("Failed to create a new channel from an accepted socket.", t);
        try {
            ch.close();
        } catch (Throwable t2) {
            logger.warn("Failed to close a socket.", t2);
        }
    }
    return 0;
}
```

> io.netty.channel.DefaultChannelPipeline#fireChannelRead

```java
// 从head开始调用pipeline的 channelRead 事件的处理函数
@Override
public final ChannelPipeline fireChannelRead(Object msg) {
    AbstractChannelHandlerContext.invokeChannelRead(head, msg);
    return this;
}
```

> io.netty.channel.AbstractChannelHandlerContext#invokeChannelRead

```java
// 调用 channelRead 事件的处理函数
static void invokeChannelRead(final AbstractChannelHandlerContext next, Object msg) {
    final Object m = next.pipeline.touch(ObjectUtil.checkNotNull(msg, "msg"), next);
    EventExecutor executor = next.executor();
    if (executor.inEventLoop()) {
        // 第一次的时候,此处的 next 应该是 head
        next.invokeChannelRead(m);
    } else {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                next.invokeChannelRead(m);
            }
        });
    }
}
```

> io.netty.channel.AbstractChannelHandlerContext#invokeChannelRead

```java
// 调用 handler的 channelRead事件的处理方法
private void invokeChannelRead(Object msg) {
    if (invokeHandler()) {
        try {
            // 调用 channelRead
            ((ChannelInboundHandler) handler()).channelRead(this, msg);
        } catch (Throwable t) {
            invokeExceptionCaught(t);
        }
    } else {
        fireChannelRead(msg);
    }
}
```

> io.netty.channel.DefaultChannelPipeline.HeadContext#channelRead

```java
// channel的读 事件
@Override
public void channelRead(ChannelHandlerContext ctx, Object msg) {
    ctx.fireChannelRead(msg);
}
```

这里就到pipeline的处理了，此处是pipeline的head  handler进行处理。

> io.netty.channel.AbstractChannelHandlerContext#fireChannelRead

```java
   @Override
    public ChannelHandlerContext fireChannelRead(final Object msg) {
        invokeChannelRead(findContextInbound(MASK_CHANNEL_READ), msg);
        return this;
    }
```

下面开始调用下一个handler进行处理，也就是headContext处理器 就是向下传播事件：

> io.netty.bootstrap.ServerBootstrap.ServerBootstrapAcceptor#channelRead

```java
/**
* 可以看到此 此handler的读取事件,其实读取的就是channel, 读取之后
* 把此channel注册到 childGroup中; 之后的读写事件就由childGroup来进行处理了.
*/
@Override
@SuppressWarnings("unchecked")
public void channelRead(ChannelHandlerContext ctx, Object msg) {
    final Channel child = (Channel) msg;
    // 动态添加childHandler
    child.pipeline().addLast(childHandler);
    // 设置此 channel的 option
    setChannelOptions(child, childOptions, logger);
    // 设置此 channel的 attribute
    setAttributes(child, childAttrs);

    try {
        /**
         * 把child注册到childGroup上
         * 这里childGroup 是哪个呢?
         * NioEventLoopGroup parent = new NioEventLoopGroup(1);
         * NioEventLoopGroup child = new NioEventLoopGroup();
         * ServerBootstrap serverBootstrap = new ServerBootstrap()
         *   .group(parent, child)
         * 就是此处的child
         */
        // 这里看着熟悉不？
        // 是的, 此处就是把接收到channel注册到 childGroup中
        childGroup.register(child).addListener(new ChannelFutureListener() {
            // 注册一个方法,如果没有成功,则执行关闭操作
            @Override
            public void operationComplete(ChannelFuture future) throws Exception {
                if (!future.isSuccess()) {
                    forceClose(child, future.cause());
                }
            }
        });
    } catch (Throwable t) {
        forceClose(child, t);
    }
}
```

分析到这里可见server接收到客户端连接后，转而把客户端注册到child中进行进一步的处理。











