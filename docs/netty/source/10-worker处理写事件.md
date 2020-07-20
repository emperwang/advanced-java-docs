[TOC]

# worker 写事件的处理

本篇说一下worker的write操作。

看一下自定义的业务代码：

```java
public class ServerHandler extends ChannelInboundHandlerAdapter {
    // 当一个链接建立时 回调
    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        Channel channel = ctx.channel();
        System.out.println(channel.remoteAddress() + " 上线..");
    }

    // 当一个链接退出时 回调
    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        Channel channel = ctx.channel();
        System.out.println(channel.remoteAddress() + " 离线了...");
    }

    // 读取数据
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg;
        System.out.println("server receive msg  : " + buf.toString(CharsetUtil.UTF_8));
        DateTimeFormatter format = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        String se = "server received msg {"+ buf.toString(CharsetUtil.UTF_8) +"} " + LocalDateTime.now().format(format);
        
        
        // 就以此为入口
        ctx.writeAndFlush(Unpooled.copiedBuffer(se,
                                                CharsetUtil.UTF_8));
    }


    // 异常处理
    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}
```

> io.netty.channel.AbstractChannelHandlerContext#writeAndFlush

```java
    // 写数据
    @Override
    public ChannelFuture writeAndFlush(Object msg) {
        return writeAndFlush(msg, newPromise());
    }
```

> io.netty.channel.AbstractChannelHandlerContext#writeAndFlush

```java
// 下操作
@Override
public ChannelFuture writeAndFlush(Object msg, ChannelPromise promise) {
    // 此write方法,通过 中间参数 flush 来进行判断,write之后是否进行flush操作; flush也就是把缓存的数据真实写入到操作系统
    write(msg, true, promise);
    return promise;
}
```

> io.netty.channel.AbstractChannelHandlerContext#write

```java
// 具体的写操作
private void write(Object msg, boolean flush, ChannelPromise promise) {
    ObjectUtil.checkNotNull(msg, "msg");
    try {
        if (isNotValidPromise(promise, true)) {
            ReferenceCountUtil.release(msg);
            // cancelled
            return;
        }
    } catch (RuntimeException e) {
        ReferenceCountUtil.release(msg);
        throw e;
    }
    // 查找pipeline中的下一个 outBound handler
    final AbstractChannelHandlerContext next = findContextOutbound(flush ?(MASK_WRITE | MASK_FLUSH) : MASK_WRITE);
    final Object m = pipeline.touch(msg, next);
    EventExecutor executor = next.executor();
    if (executor.inEventLoop()) {
        if (flush) {
            // 如果需要 flush操作呢, 就调用这里
            next.invokeWriteAndFlush(m, promise);
        } else {
            // 如果不进行flush, 就从这里处理了
            next.invokeWrite(m, promise);
        }
    } else {
        final WriteTask task = WriteTask.newInstance(next, m, promise, flush);
        if (!safeExecute(executor, task, promise, m, !flush)) {
            task.cancel();
        }
    }
}
```

```java
    //  查找pipeline中的Outbound
    private AbstractChannelHandlerContext findContextOutbound(int mask) {
        AbstractChannelHandlerContext ctx = this;
        EventExecutor currentExecutor = executor();
        do {
            ctx = ctx.prev;
        } while (skipContext(ctx, currentExecutor, mask, MASK_ONLY_OUTBOUND));
        return ctx;
    }
```

```java
void invokeWriteAndFlush(Object msg, ChannelPromise promise) {
    if (invokeHandler()) {
        // 写操作
        invokeWrite0(msg, promise);
        // flush 操作
        invokeFlush0();
    } else {
        writeAndFlush(msg, promise);
    }
}
```

> io.netty.channel.AbstractChannelHandlerContext#invokeWrite0

```java
private void invokeWrite0(Object msg, ChannelPromise promise) {
    try {
        // 这里最终会调用到head进行处理; 直接看一下head如何做的?
        ((ChannelOutboundHandler) handler()).write(this, msg, promise);
    } catch (Throwable t) {
        notifyOutboundHandlerException(t, promise);
    }
}
```

此处就先省略其他的handler，直接看

> io.netty.channel.DefaultChannelPipeline.HeadContext#write

```java
// 写操作
@Override
public void write(ChannelHandlerContext ctx, Object msg, ChannelPromise promise) {
    // 调用unsafe方法来进行真实的操作
    unsafe.write(msg, promise);
}
```

> io.netty.channel.AbstractChannel.AbstractUnsafe#write

```java
@Override
public final void write(Object msg, ChannelPromise promise) {
    assertEventLoop();
    /**
             * todo 重点  此outboundBuffer就是把写write的消息缓存起来
             * 是一个链表结构
             */
    ChannelOutboundBuffer outboundBuffer = this.outboundBuffer;
    if (outboundBuffer == null) {
        // If the outboundBuffer is null we know the channel was closed and so
        // need to fail the future right away. If it is not null the handling of the rest
        // will be done in flush0()
        // See https://github.com/netty/netty/issues/2362
        safeSetFailure(promise, newClosedChannelException(initialCloseCause));
        // release message now to prevent resource-leak
        ReferenceCountUtil.release(msg);
        return;
    }

    int size;
    try {
        /**
                 *  filter 过滤操作
                 *  1. 把bytebuf 封装为 directBuf
                 *  2. 是FileRegion 这个类型的 直接返回
                 *  3. 不是上述两种类型则报错
                 */
        msg = filterOutboundMessage(msg);
        size = pipeline.estimatorHandle().size(msg);
        if (size < 0) {
            size = 0;
        }
    } catch (Throwable t) {
        safeSetFailure(promise, t);
        ReferenceCountUtil.release(msg);
        return;
    }
    // 把要write的消息,添加到 outboundBuffer
    outboundBuffer.addMessage(msg, size, promise);
}
```

> io.netty.channel.ChannelOutboundBuffer#addMessage

```java
public void addMessage(Object msg, int size, ChannelPromise promise) {
    Entry entry = Entry.newInstance(msg, size, total(msg), promise);
    // 1. 如果是第一次添加,则tailEntry   flushEntry初始化为 null
    if (tailEntry == null) {
        flushedEntry = null;
    } else {
        // 2. 不是第一次,则在 tailEntry后面进行追加
        Entry tail = tailEntry;
        tail.next = entry;
    }
    // 3. 更新tailEntry的位置
    tailEntry = entry;
    // 4. 如果是第一次添加,则把unflushedEntry设置为要添加的  entry
    if (unflushedEntry == null) {
        unflushedEntry = entry;
    }
    // 记录要flush的消息的个数
    incrementPendingOutboundBytes(entry.pendingSize, false);
}
```

由此可见，真实的写入其实就是先把消息缓存起来，缓存到一个链表中。

> io.netty.channel.AbstractChannel.AbstractUnsafe#flush

```java
// 把缓存的msg进行真实的写入;
@Override
public final void flush() {
    assertEventLoop();
    // 获取缓存的msg
    ChannelOutboundBuffer outboundBuffer = this.outboundBuffer;
    // 如果没有msg呢, 直接返回
    if (outboundBuffer == null) {
        return;
    }
    // 先对缓存msg的链表进行一些update,以备下面的flush
    outboundBuffer.addFlush();
    // flush
    flush0();
}
```

> io.netty.channel.ChannelOutboundBuffer#addFlush

```java
public void addFlush() {
    // 获取等待flush的链表的第一个节点
    Entry entry = unflushedEntry;
    // 如果节点存在,则更新到flushedEntry上
    if (entry != null) {
        if (flushedEntry == null) {
            // there is no flushedEntry yet, so start with the entry
            flushedEntry = entry;
        }
        do {
            flushed ++;
            if (!entry.promise.setUncancellable()) {
                int pending = entry.cancel();
                decrementPendingOutboundBytes(pending, false, true);
            }
            entry = entry.next;
        } while (entry != null);

        // All flushed so reset unflushedEntry
        // 把unflushedEntry置空
        unflushedEntry = null;
    }
}
```

> io.netty.channel.nio.AbstractNioChannel.AbstractNioUnsafe#flush0

```java
@Override
protected final void flush0() {
    if (!isFlushPending()) {
        super.flush0();
    }
}
```

> io.netty.channel.AbstractChannel.AbstractUnsafe#flush0

```java
protected void flush0() {
    if (inFlush0) {
        // Avoid re-entrance
        return;
    }
    // 判断是否有等待 flush的msg
    final ChannelOutboundBuffer outboundBuffer = this.outboundBuffer;
    if (outboundBuffer == null || outboundBuffer.isEmpty()) {
        return;
    }
    // 更新标志, 防止重复执行
    inFlush0 = true;

    // Mark all pending write requests as failure if the channel is inactive.
    if (!isActive()) {
        try {
            if (isOpen()) {
                outboundBuffer.failFlushed(new NotYetConnectedException(), true);
            } else {
                // Do not trigger channelWritabilityChanged because the channel is closed already.
                outboundBuffer.failFlushed(newClosedChannelException(initialCloseCause), false);
            }
        } finally {
            inFlush0 = false;
        }
        return;
    }

    try {
        // flush
        // 真实的写操作
        doWrite(outboundBuffer);
    } catch (Throwable t) {
        if (t instanceof IOException && config().isAutoClose()) {
            initialCloseCause = t;
            // 如果发生exception, 则此处调用close() 来更新对应channel的状态
            close(voidPromise(), t, newClosedChannelException(t), false);
        } else {
            try {
                // 执行JDK NIO中的close方法
                shutdownOutput(voidPromise(), t);
            } catch (Throwable t2) {
                initialCloseCause = t;
                close(voidPromise(), t2, newClosedChannelException(t), false);
            }
        }
    } finally {
        inFlush0 = false;
    }
}
```

> io.netty.channel.socket.nio.NioSocketChannel#doWrite

```java
// 真实的写操作
@Override
protected void doWrite(ChannelOutboundBuffer in) throws Exception {
    SocketChannel ch = javaChannel();
    int writeSpinCount = config().getWriteSpinCount();
    do {
        if (in.isEmpty()) {
            // All written so clear OP_WRITE
            clearOpWrite();
            // Directly return here so incompleteWrite(...) is not called.
            return;
        }
        // Ensure the pending writes are made of ByteBufs only.
        int maxBytesPerGatheringWrite = ((NioSocketChannelConfig) config).getMaxBytesPerGatheringWrite();
        ByteBuffer[] nioBuffers = in.nioBuffers(1024, maxBytesPerGatheringWrite);
        int nioBufferCnt = in.nioBufferCount();
        switch (nioBufferCnt) {
            case 0:
                // 写入操作
                writeSpinCount -= doWrite0(in);
                break;
            case 1: {
                ByteBuffer buffer = nioBuffers[0];
                int attemptedBytes = buffer.remaining();
                final int localWrittenBytes = ch.write(buffer);
                if (localWrittenBytes <= 0) {
                    incompleteWrite(true);
                    return;
                }
                adjustMaxBytesPerGatheringWrite(attemptedBytes, localWrittenBytes, maxBytesPerGatheringWrite);
                in.removeBytes(localWrittenBytes);
                --writeSpinCount;
                break;
            }
            default: {
                long attemptedBytes = in.nioBufferSize();
                final long localWrittenBytes = ch.write(nioBuffers, 0, nioBufferCnt);
                if (localWrittenBytes <= 0) {
                    incompleteWrite(true);
                    return;
                }
                // Casting to int is safe because we limit the total amount of data in the nioBuffers to int above.
                adjustMaxBytesPerGatheringWrite((int) attemptedBytes, (int) localWrittenBytes, maxBytesPerGatheringWrite);
                in.removeBytes(localWrittenBytes);
                --writeSpinCount;
                break;
            }
        }
    } while (writeSpinCount > 0);

    incompleteWrite(writeSpinCount < 0);
}
```

> io.netty.channel.nio.AbstractNioByteChannel#doWrite0

```java
protected final int doWrite0(ChannelOutboundBuffer in) throws Exception {
    Object msg = in.current();
    if (msg == null) {
        // Directly return here so incompleteWrite(...) is not called.
        return 0;
    }
    return doWriteInternal(in, in.current());
}
```

> io.netty.channel.nio.AbstractNioByteChannel#doWriteInternal

```java
private int doWriteInternal(ChannelOutboundBuffer in, Object msg) throws Exception {
    if (msg instanceof ByteBuf) {
        ByteBuf buf = (ByteBuf) msg;
        // 如果此byteBuf消息不可读,则删除
        if (!buf.isReadable()) {
            in.remove();
            return 0;
        }
        // 写入 并返回写入的字节数
        // 重点 **********  真实的写入
        final int localFlushedAmount = doWriteBytes(buf);
        if (localFlushedAmount > 0) {
            in.progress(localFlushedAmount);
            if (!buf.isReadable()) {
           // 1. 判断msg是否write完,完了则把flushedEntry unflushEntry tailEntry置为null
                // 2. 没有写完,则flushEntry指向下一个要write的msg, 来进行write
                in.remove();
            }
            return 1;
        }
    } else if (msg instanceof FileRegion) {
        FileRegion region = (FileRegion) msg;
        if (region.transferred() >= region.count()) {
            in.remove();
            return 0;
        }
        // 调用jdk来进行文件的写入
        long localFlushedAmount = doWriteFileRegion(region);
        if (localFlushedAmount > 0) {
            in.progress(localFlushedAmount);
            if (region.transferred() >= region.count()) {
                in.remove();
            }
            return 1;
        }
    } else {
        // Should not reach here.
        throw new Error();
    }
    return WRITE_STATUS_SNDBUF_FULL;
}
```

> io.netty.channel.nio.AbstractNioByteChannel#doWriteBytes

```java
@Override
protected int doWriteBytes(ByteBuf buf) throws Exception {
    // 获取可写入的字节数
    final int expectedWrittenBytes = buf.readableBytes();
    // 写入操作,看到此javaChannel就可了解到  马上进入到JDK NIO了
    return buf.readBytes(javaChannel(), expectedWrittenBytes);
}

```

> io.netty.buffer.UnpooledHeapByteBuf#readBytes

```java
// 写数据到 channel
@Override
public int readBytes(GatheringByteChannel out, int length) throws IOException {
    checkReadableBytes(length);
    int readBytes = getBytes(readerIndex, out, length, true);
    readerIndex += readBytes;
    return readBytes;
}
```

> io.netty.buffer.UnpooledHeapByteBuf#getBytes

```java
// 真实 写入 channel数据的操作
private int getBytes(int index, GatheringByteChannel out, int length, boolean internal) throws IOException {
    ensureAccessible();
    ByteBuffer tmpBuf;
    if (internal) {
        tmpBuf = internalNioBuffer();
    } else {
        tmpBuf = ByteBuffer.wrap(array);
    }
    // 写入
    return out.write((ByteBuffer) tmpBuf.clear().position(index).limit(index + length));
}
```

> sun.nio.ch.SocketChannelImpl#write(java.nio.ByteBuffer)

最后仍然是调用JDK中的写入动作。