[TOC]

# worker 读事件的处理

前篇介绍了 boss接收到请求后，会把请求注册到worker中来进行进一步的读写请求，本篇就介绍下worker对read事件的处理。

前篇回顾，注册操作：

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
        // 这里看着熟悉不？
        // 是的, 此处就是把接收到channel注册到 childGroup中
        // 就是在这里吧 channel注册到了 worker中的NioEventLoop中
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

前面也分析过NioEventLoop，其才是真正的处理操作。

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
                    case SelectStrategy.BUSY_WAITStrategy.SELECT:
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
                        // fall through
                    default:
                }
            } catch (IOException e) {
               ....
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
                       
                        processSelectedKeys();
                    }
                } finally {
                    // 处理taskQueue 以及 scheduledTaskQueue 中的任务
                    ranTasks = runAllTasks();
                }
            } else if (strategy > 0) {
                final long ioStartTime = System.nanoTime();
                try {
                     // 处理select 事件
                    processSelectedKeys();
                } finally {
                    // Ensure we always run tasks.
                    final long ioTime = System.nanoTime() - ioStartTime;
                    ranTasks = runAllTasks(ioTime * (100 - ioRatio) / ioRatio);
                }
            } else {
                ranTasks = runAllTasks(0); 
            }
            if (ranTasks || strategy > 0) {
                if (selectCnt > MIN_PREMATURE_SELECTOR_RETURNS && logger.isDebugEnabled()) { logger.debug("Selector.select() returned prematurely {} times in a row for Selector {}.", selectCnt - 1, selector);
                }
                selectCnt = 0;
            } else if (unexpectedSelectorWakeup(selectCnt)) { 
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
        // 具体是执行这里
        processSelectedKeysOptimized();
    } else {
        /**
             * todo  处理select查询到的事件
             */
        processSelectedKeysPlain(selector.selectedKeys());
    }
}
```

> io.netty.channel.nio.NioEventLoop#processSelectedKeysOptimized

```java
// selector 事件的处理
private void processSelectedKeysOptimized() {
    // 遍历所有的key 获取此key对应的channel
    for (int i = 0; i < selectedKeys.size; ++i) {
        final SelectionKey k = selectedKeys.keys[i];
        selectedKeys.keys[i] = null;
		// 获取key 对应的channel
        final Object a = k.attachment();
        if (a instanceof AbstractNioChannel) {
            // 进一步处理 此channel
            processSelectedKey(k, (AbstractNioChannel) a);
        } else {
            @SuppressWarnings("unchecked")
            NioTask<SelectableChannel> task = (NioTask<SelectableChannel>) a;
            processSelectedKey(k, task);
        }
        if (needsToSelectAgain) {
            selectedKeys.reset(i + 1);
            selectAgain();
            i = -1;
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
            // close the channel if the key is not valid anymore
            unsafe.close(unsafe.voidPromise());
        }
        return;
    }

    try {
        // 获取k上就绪的事件
        int readyOps = k.readyOps();
        // 处理connect事件
        if ((readyOps & SelectionKey.OP_CONNECT) != 0) {
            int ops = k.interestOps();
            ops &= ~SelectionKey.OP_CONNECT;
            // 清除connect事件
            k.interestOps(ops);
            // finishConnect事件的处理
            unsafe.finishConnect();
        }
        // 处理write事件
        if ((readyOps & SelectionKey.OP_WRITE) != 0) {
            // flush操作
            ch.unsafe().forceFlush();
        }
        /**
             * 处理读事件
             * 1. 如果是NioServerSocketChannel  那么会执行NioMessageUnsafe 读取操作
             * 2. 如果是NioSocketChannel       NioByteUnsafe 读取操作
             * 3. 调用child类的  .childHandler(new CustomServerInitializer());  方法来添加handler到pipeline中
             */
        if ((readyOps & (SelectionKey.OP_READ | SelectionKey.OP_ACCEPT)) != 0 || readyOps == 0) {
            // 此处的 unsafe是 NioByteUnsafe
            unsafe.read();
        }
    } catch (CancelledKeyException ignored) {
        unsafe.close(unsafe.voidPromise());
    }
}
```

> io.netty.channel.nio.AbstractNioByteChannel.NioByteUnsafe#read

```java
/**
         * todo 重要 重要
         *  worker group的read操作
         * 此操作才是真正的读取操作
         */
@Override
public final void read() {
    final ChannelConfig config = config();
    if (shouldBreakReadReady(config)) {
        clearReadPending();
        return;
    }
    // 获取 pipeline
    final ChannelPipeline pipeline = pipeline();
    // 获取内存分配器
    final ByteBufAllocator allocator = config.getAllocator();
    // 接收内存分配器
    final RecvByteBufAllocator.Handle allocHandle = recvBufAllocHandle();
    // 把 一些 config中的 数据记录: 获取每次读取最大的字节数,读取的消息清零
    allocHandle.reset(config);
    ByteBuf byteBuf = null;
    boolean close = false;
    try {
        // while 循环, 持续从channel中读取数据
        do {
            // 使用内存分配器 分配 一块内存
            byteBuf = allocHandle.allocate(allocator);
            // doReadBytes 真实读取数据
            // allocHandle.lastBytesRead 记录上次读取的字节数
            allocHandle.lastBytesRead(doReadBytes(byteBuf));
            if (allocHandle.lastBytesRead() <= 0) {
                // nothing was read. release the buffer.
                // 如果没有读取到数据呢  就释放buffer  并退出循环
                byteBuf.release();
                byteBuf = null;
                close = allocHandle.lastBytesRead() < 0;
                if (close) {
                    // There is nothing left to read as we received an EOF.
                    readPending = false;
                }
                break;
            }
            // 增加信息读取的次数
            allocHandle.incMessagesRead(1);
            readPending = false;
            // 执行pipeline中 channelRead事件, 来对buf中的数据进行处理
            // 也就是处理读取的数据
            // 此处就是用户设置的 业务代码处理了
            pipeline.fireChannelRead(byteBuf);
            byteBuf = null;
            /**
                     * 停止读取的条件:
                     * bytesToRead > 0 && maybeMoreDataSupplier.get() -- 此是下面的函数, 判断 attemptBytesRead 和 lastBytesRead是否相等
                     * private final UncheckedBooleanSupplier defaultMaybeMoreSupplier = new UncheckedBooleanSupplier() {
                     *             @Override
                     *             public boolean get() {
                     *                 return attemptBytesRead == lastBytesRead;
                     *             }
                     *         };
                     *
                     * 也就是 读取的字节数  等于 要读取的字节数
                     */
        } while (allocHandle.continueReading());
        // 读取完成  readComplete 事件
        allocHandle.readComplete();
        // 调用 readComplete事件
        // 用户自定义的  readComplete
        pipeline.fireChannelReadComplete();

        if (close) {
            closeOnRead(pipeline);
        }
    } catch (Throwable t) {
        // 1.如果buf中仍然有数据,则对数据继续进行处理
        // 2.对异常进行处理
        handleReadException(pipeline, byteBuf, t, close, allocHandle);
    } finally {
        if (!readPending && !config.isAutoRead()) {
            removeReadOp();
        }
    }
}
}
```

看到此函数总结一下就是：

1. 分配一块内存(内存分为：堆内存，堆外内存)
2. 从channel中读取数据
3. 并把读取的数据存入到分配的内存中。
4. 把读取到数据传递到下一个handler的 ChannelRead 函数进行处理
5. 最后触发 ChannelReadComplete事件







































