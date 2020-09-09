[TOC]

# tomcat-nio-2

上篇看了tomcat中对连接的处理，以及读事件的处理，本篇看一下tomcat-nio中对写事件的处理。

```java
HttpServlet httpServlet = new HttpServlet() {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().write("hello, this is tomcat source.");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
};
```

以上面的为入口，看一下写处理的整个流程。

> org.apache.catalina.connector.Response#getWriter

```java
// 获取 写数据的handler
@Override
public PrintWriter getWriter()
    throws IOException {

    if (usingOutputStream) {
        throw new IllegalStateException
            (sm.getString("coyoteResponse.getWriter.ise"));
    }

    if (ENFORCE_ENCODING_IN_GET_WRITER) {
        setCharacterEncoding(getCharacterEncoding());
    }

    usingWriter = true;
    // 检测outputBuffer 是否设置了转换器,如果没有设置 则创建一个
    outputBuffer.checkConverter();
    if (writer == null) {
        // 创建一个 writer
        writer = new CoyoteWriter(outputBuffer);
    }
    return writer;
}
```

这里首先对outputBuffer创建了编码转换器，之后创建了CoyoteWriter。编码器就不看了，直接看写入操作：

> org.apache.catalina.connector.CoyoteWriter#write(java.lang.String)

```java
// 想outputBuffer中写出数据
@Override
public void write(String s) {
    write(s, 0, s.length());
}
```

> org.apache.catalina.connector.CoyoteWriter#write(java.lang.String, int, int)

```java
// 把数据写入到 buffer
@Override
public void write(String s, int off, int len) {

    if (error) {
        return;
    }
    // 把数据写入到 outputBuffer中
    try {
        // 写出操作
        ob.write(s, off, len);
    } catch (IOException e) {
        error = true;
    }
}
```

> org.apache.catalina.connector.OutputBuffer#write(java.lang.String, int, int)

```java
@Override
public void write(String s, int off, int len) throws IOException {
    if (suspended) {
        return;
    }
    if (s == null) {
        throw new NullPointerException(sm.getString("outputBuffer.writeNull"));
    }

    int sOff = off;
    int sEnd = off + len;
    while (sOff < sEnd) {
        int n = transfer(s, sOff, sEnd - sOff, cb);
        sOff += n;
        // 如果cb buffer 已经满了,则flush一次
        if (isFull(cb)) {
            // 这里的flush会对 buffer中的数据进行编码 并 写出到 socketChannel中
            // --- ----
            flushCharBuffer();
        }
    }
    charsWritten += len;
}
```

> org.apache.catalina.connector.OutputBuffer#flushCharBuffer

```java
// flush操作, 是封装了编码和 写出操作
private void flushCharBuffer() throws IOException {
    realWriteChars(cb.slice());
    clear(cb);
}
```

```java
public void realWriteChars(CharBuffer from) throws IOException {

    while (from.remaining() > 0) {
        // 把from中的数据编码 并放入到 bb  buffer中
        conv.convert(from, bb);
        if (bb.remaining() == 0) {
            // Break out of the loop if more chars are needed to produce any output
            break;
        }
        if (from.remaining() > 0) {
            // 写出数据到 socketChannel中
            flushByteBuffer();
        } else if (conv.isUndeflow() && bb.limit() > bb.capacity() - 4) {
            flushByteBuffer();
        }
    }
}
```

```java
private void flushByteBuffer() throws IOException {
    // 写出数据到 socketChannel中
    realWriteBytes(bb.slice());
    clear(bb);
}
```

```java
public void realWriteBytes(ByteBuffer buf) throws IOException {

    if (closed) {
        return;
    }
    if (coyoteResponse == null) {
        return;
    }

    // If we really have something to write
    if (buf.remaining() > 0) {
        // real write to the adapter
        try {
            // 写出数据到 socketChannel中
            coyoteResponse.doWrite(buf);
        } catch (CloseNowException e) {
            throw e;
        } catch (IOException e) {
            throw new ClientAbortException(e);
        }
    }

}
```

> org.apache.coyote.Response#doWrite(java.nio.ByteBuffer)

```java
public void doWrite(ByteBuffer chunk) throws IOException {
    int len = chunk.remaining();
    // 写出数据到 socketChannel中
    outputBuffer.doWrite(chunk);
    contentWritten += len - chunk.remaining();
}
```

> org.apache.coyote.http11.Http11OutputBuffer#doWrite(java.nio.ByteBuffer)

```java
@Override
public int doWrite(ByteBuffer chunk) throws IOException {
    if (!response.isCommitted()) {
        // Send the connector a request for commit. The connector should
        // then validate the headers, send them (using sendHeaders) and
        // set the filters accordingly.
        response.action(ActionCode.COMMIT, null);
    }
    if (lastActiveFilter == -1) {
        // 写出数据到 socketChannel中 或者 写入到 socketBufferHandler的 writeBuffer中
        return outputStreamOutputBuffer.doWrite(chunk);
    } else {
        return activeFilters[lastActiveFilter].doWrite(chunk);
    }
}
```

> org.apache.coyote.http11.Http11OutputBuffer.SocketOutputBuffer#doWrite(java.nio.ByteBuffer)

```java
@Override
public int doWrite(ByteBuffer chunk) throws IOException {
    try {
        int len = chunk.remaining();
        // 写出数据到 socketChannel中
        socketWrapper.write(isBlocking(), chunk);
        len -= chunk.remaining();
        byteCount += len;
        return len;
    } catch (IOException ioe) {
        response.action(ActionCode.CLOSE_NOW, ioe);
        // Re-throw
        throw ioe;
    }
}
```

> org.apache.tomcat.util.net.SocketWrapperBase#write(boolean, java.nio.ByteBuffer)

```java
// 写出数据到socketChannel中
public final void write(boolean block, ByteBuffer from) throws IOException {
    if (from == null || from.remaining() == 0) {
        return;
    }
    if (block) {
        writeBlocking(from);
    } else {
        // 把from中数据写入到 socketChannel中 或 写入到 socketBufferHandler的 writeBuffer中
        writeNonBlocking(from);
    }
}
```

> org.apache.tomcat.util.net.SocketWrapperBase#writeNonBlocking(java.nio.ByteBuffer)

```java
protected void writeNonBlocking(ByteBuffer from)
    throws IOException {
    // 写数据到 socketBufferHandler的writeBuffer 或者 直接写入到 socketChannel中
    if (nonBlockingWriteBuffer.isEmpty() && socketBufferHandler.isWriteBufferWritable()) {
        writeNonBlockingInternal(from);
    }

    if (from.remaining() > 0) {
        // Remaining data must be buffered
        nonBlockingWriteBuffer.add(from);
    }
}
```

> org.apache.tomcat.util.net.SocketWrapperBase#writeNonBlockingInternal

```java
protected void writeNonBlockingInternal(ByteBuffer from) throws IOException {
    if (socketBufferHandler.isWriteBufferEmpty()) {
        // 写入到 socketBufferHandler的writeBuffer
        // 或者 直接写入到 scoketChannel中
        writeNonBlockingDirect(from);
    } else {
        // 配置writeBuffer 可写
        socketBufferHandler.configureWriteBufferForWrite();
        // 把 from中的数据 拷贝到 socketBufferHandler中的writeBuffer中
        transfer(from, socketBufferHandler.getWriteBuffer());
        // 如果现在 writeBuffer不可写了
        if (!socketBufferHandler.isWriteBufferWritable()) {
            doWrite(false);
            if (socketBufferHandler.isWriteBufferWritable()) {
                writeNonBlockingDirect(from);
            }
        }
    }
}
```

> org.apache.tomcat.util.net.SocketWrapperBase#writeNonBlockingDirect

```java
protected void writeNonBlockingDirect(ByteBuffer from) throws IOException {
    // socketBufferHandler writebuffer的大小
    int limit = socketBufferHandler.getWriteBuffer().capacity();
    int fromLimit = from.limit();
    // 如果 from buffer中数据 大于 socketBufferHandler中writebuffer 的容量
    // 则把数据写入到 socketChannel中,并注册 此socketChannel的 write 事件
    while (from.remaining() >= limit) {
        int newLimit = from.position() + limit;
        from.limit(newLimit);
        // 把数据写入到 socketChannel中,并注册为 write事件
        doWrite(false, from);
        from.limit(fromLimit);
        if (from.position() != newLimit) {
            // Didn't write the whole amount of data in the last
            // non-blocking write.
            // Exit the loop.
            return;
        }
    }
    // 把数据写入到 socketBufferHandler中的writeBuffer中
    if (from.remaining() > 0) {
        socketBufferHandler.configureWriteBufferForWrite();
        transfer(from, socketBufferHandler.getWriteBuffer());
    }
}
```

这里看到写出时，如果写出的数据太大，大于socketBufferHandler的writeBuffer的大小，则直接写出到socketChannel中，否则把数据写出到socketBufferHandler的writeBuffer中。

> org.apache.tomcat.util.net.NioEndpoint.NioSocketWrapper#doWrite

```java
// 写数据到 SocketChannel中
@Override
protected void doWrite(boolean block, ByteBuffer from) throws IOException {
    long writeTimeout = getWriteTimeout();
    Selector selector = null;
    try {
        selector = pool.get();
    } catch (IOException x) {
        // Ignore
    }
    try {
        // 写入到 socketChannel中
        pool.write(from, getSocket(), selector, writeTimeout, block);
        if (block) {
            // Make sure we are flushed
            do {
                if (getSocket().flush(true, selector, writeTimeout)) {
                    break;
                }
            } while (true);
        }
        // 更新写时间
        updateLastWrite();
    } finally {
        if (selector != null) {
            pool.put(selector);
        }
    }
}
```

> org.apache.tomcat.util.net.NioSelectorPool#write

```java
public int write(ByteBuffer buf, NioChannel socket, Selector selector,
                 long writeTimeout, boolean block) throws IOException {
    if ( SHARED && block ) {
        // 把buf中的数据写入到 socketChannel中
        // 阻塞写入
        return blockingSelector.write(buf,socket,writeTimeout);
    }
    SelectionKey key = null;
    int written = 0;
    boolean timedout = false;
    int keycount = 1; //assume we can write
    long time = System.currentTimeMillis(); //start the timeout timer
    try {
        while ( (!timedout) && buf.hasRemaining() ) {
            int cnt = 0;
            if ( keycount > 0 ) { //only write if we were registered for a write
                // 把数据写入到 socketChannel中
                // --- 重点-----
                cnt = socket.write(buf); //write the data
                if (cnt == -1) throw new EOFException();

                written += cnt;
                if (cnt > 0) {
                    time = System.currentTimeMillis(); //reset our timeout timer
                    continue; //we successfully wrote, try again without a selector
                }
                if (cnt==0 && (!block)) break; //don't block
            }
            if ( selector != null ) {
                //register OP_WRITE to the selector
                // 重新把此 socketChannel注册为 write 事件
                if (key==null) key = socket.getIOChannel().register(selector, SelectionKey.OP_WRITE);
                else key.interestOps(SelectionKey.OP_WRITE);
                // 如果 writeTimeout =0,且 buf中还数据没有写完,则表示超时
                if (writeTimeout==0) {
                    timedout = buf.hasRemaining();
                    // writeTimeout小于0, 已经超时,则进行一次 网络io
                } else if (writeTimeout<0) {
                    keycount = selector.select();
                } else {
                    // 进行一次 网络io,有超时时间的,相当于进行一次 网络io
                    keycount = selector.select(writeTimeout);
                }
            }
            // 判断是否超时
            // 写时间 超过了 writeTimeout,则表示已经超时了
            if (writeTimeout > 0 && (selector == null || keycount == 0) )
                timedout = (System.currentTimeMillis()-time)>=writeTimeout;
        }//while
        if ( timedout ) throw new SocketTimeoutException();
    } finally {
        if (key != null) {
            key.cancel();
            if (selector != null) selector.selectNow();//removes the key from this selector
        }
    }
    return written;
}
```

这里的写入操作，先把数据写入到socketChannel中，如果存在selector，则把socketChannel注册到此selector中，感兴趣事件为write，之后进行一次keycount = selector.select(writeTimeout) 即进行一次网络IO；此处是一个while循环，持续在进行写操作。



大家可能还记得上篇分析的内容，其中有一个对写操作的处理，其中有没有对数据的写出呢？ 

最终处理都在这里进行：

> org.apache.coyote.AbstractProcessorLight#process

```java
@Override
public SocketState process(SocketWrapperBase<?> socketWrapper, SocketEvent status)
    throws IOException {

    SocketState state = SocketState.CLOSED;
    Iterator<DispatchType> dispatches = null;
    do {
        if (dispatches != null) {
            DispatchType nextDispatch = dispatches.next();
            state = dispatch(nextDispatch.getSocketStatus());
        } else if (status == SocketEvent.DISCONNECT) {
            // Do nothing here, just wait for it to get recycled
        } else if (isAsync() || isUpgrade() || state == SocketState.ASYNC_END) {
            //  分发操作
            // 这里有对 写操作的 flush 操作
            state = dispatch(status);
            if (state == SocketState.OPEN) {
                // 重点  重点
                // 对socke记性处理
                // 生成request  response ,调用adaptor.service
                state = service(socketWrapper);
            }
        } else if (status == SocketEvent.OPEN_WRITE) {
            // Extra write event likely after async, ignore
            state = SocketState.LONG;
        } else if (status == SocketEvent.OPEN_READ){
            // 这里主要是调用service方法来进行处理
            state = service(socketWrapper);
        } else {
            // Default to closing the socket if the SocketEvent passed in
            // is not consistent with the current state of the Processor
            state = SocketState.CLOSED;
        }
        if (state != SocketState.CLOSED && isAsync()) {
            state = asyncPostProcess();
            if (getLog().isDebugEnabled()) {
                getLog().debug("Socket: [" + socketWrapper +
                               "], State after async post processing: [" + state + "]");
            }
        }
        if (dispatches == null || !dispatches.hasNext()) {
            // Only returns non-null iterator if there are
            // dispatches to process.
            dispatches = getIteratorAndClearDispatches();
        }
    } while (state == SocketState.ASYNC_END ||
             dispatches != null && state != SocketState.CLOSED);
    return state;
}
```

从中:

```java
else if (status == SocketEvent.OPEN_WRITE) {
    // Extra write event likely after async, ignore
    state = SocketState.LONG;
```

可以看到，对于write事件其实只是修改了状态，并没有进行一些进一步的操作。

tomcat-nio写操作就先分析到这里。

















