# Channel

javaDoc:

```java
 Utility methods for channels and streams.
 This class defines static methods that support the interoperation of the
 stream classes of the java.io package with the channel
 classes of this package.
```



## 构造方法

```java
private Channels() { }   
```



## 功能函数

### writeFullyImpl

```java
	/** Write all remaining bytes in buffer to the given channel.
     * If the channel is selectable then it must be configured blocking.
     */
private static void writeFullyImpl(WritableByteChannel ch, ByteBuffer bb)
    throws IOException
    {
        while (bb.remaining() > 0) {
            int n = ch.write(bb);
            if (n <= 0)
                throw new RuntimeException("no bytes written");
        }
    }
```

### writeFully

```java
/* Write all remaining bytes in buffer to the given channel.  */
private static void writeFully(WritableByteChannel ch, ByteBuffer bb)
    throws IOException
    {
        if (ch instanceof SelectableChannel) {
            SelectableChannel sc = (SelectableChannel)ch;
            synchronized (sc.blockingLock()) {
                if (!sc.isBlocking())
                    throw new IllegalBlockingModeException();
                    // 写操作
                writeFullyImpl(ch, bb);
            }
        } else {
            writeFullyImpl(ch, bb);
        }
    }
```

### newInputStream

```java
    /** Constructs a stream that reads bytes from the given channel. 
     * The <tt>read</tt> methods of the  resulting stream will throw an
     * IllegalBlockingModeException if invoked while the underlying
     * channel is in non-blocking mode.  The stream will not be buffered, and
     * it will not support the  InputStream#mark mark or  InputStream#reset reset methods.  The 		 * stream will be safe for access by
     * multiple concurrent threads.  Closing the stream will in turn cause the
     * channel to be closed.*/
public static InputStream newInputStream(ReadableByteChannel ch) {
    checkNotNull(ch, "ch");
    return new sun.nio.ch.ChannelInputStream(ch);
}
```

### newOutputStream

```java
    /** Constructs a stream that writes bytes to the given channel.
     * The <tt>write</tt> methods of the resulting stream will throw an
     * {@link IllegalBlockingModeException} if invoked while the underlying
     * channel is in non-blocking mode.  The stream will not be buffered.  The
     * stream will be safe for access by multiple concurrent threads.  Closing
     * the stream will in turn cause the channel to be closed.  */
public static OutputStream newOutputStream(final WritableByteChannel ch) {
    checkNotNull(ch, "ch");
    return new OutputStream() {
        private ByteBuffer bb = null;
        private byte[] bs = null;       // Invoker's previous array
        private byte[] b1 = null;

        public synchronized void write(int b) throws IOException {
            if (b1 == null)
                b1 = new byte[1];
            b1[0] = (byte)b;
            this.write(b1);
        }

        public synchronized void write(byte[] bs, int off, int len)
            throws IOException
        {
            if ((off < 0) || (off > bs.length) || (len < 0) ||
                ((off + len) > bs.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return;
            }
            ByteBuffer bb = ((this.bs == bs)
                             ? this.bb
                             : ByteBuffer.wrap(bs));
            bb.limit(Math.min(off + len, bb.capacity()));
            bb.position(off);
            this.bb = bb;
            this.bs = bs;
            // 写入操作
            Channels.writeFully(ch, bb);
        }

        public void close() throws IOException {
            ch.close();
        }
    };
}
```

### newInputStream

```java
    /* Constructs a stream that reads bytes from the given channel.
     * The stream will not be buffered, and it will not support the {@link
     * InputStream#mark mark} or {@link InputStream#reset reset} methods.  The
     * stream will be safe for access by multiple concurrent threads.  Closing
     * the stream will in turn cause the channel to be closed. */
public static InputStream newInputStream(final AsynchronousByteChannel ch) {
    checkNotNull(ch, "ch");
    return new InputStream() {

        private ByteBuffer bb = null;
        private byte[] bs = null;           // Invoker's previous array
        private byte[] b1 = null;

        @Override
        public synchronized int read() throws IOException {
            if (b1 == null)
                b1 = new byte[1];
            int n = this.read(b1);
            if (n == 1)
                return b1[0] & 0xff;
            return -1;
        }

        @Override
        public synchronized int read(byte[] bs, int off, int len)
            throws IOException
        {
            if ((off < 0) || (off > bs.length) || (len < 0) ||
                ((off + len) > bs.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0)
                return 0;
			// 数组包装成buffer
            ByteBuffer bb = ((this.bs == bs)
                             ? this.bb
                             : ByteBuffer.wrap(bs));
            bb.position(off);
            bb.limit(Math.min(off + len, bb.capacity()));
            this.bb = bb;
            this.bs = bs;
            boolean interrupted = false;
            try {
                for (;;) {
                    try {
                        // 从channel中读取数据到数组
                        return ch.read(bb).get();
                    } catch (ExecutionException ee) {
                        throw new IOException(ee.getCause());
                    } catch (InterruptedException ie) {
                        interrupted = true;
                    }
                }
            } finally {
                if (interrupted)
                    Thread.currentThread().interrupt();
            }
        }

        @Override
        public void close() throws IOException {
            ch.close();
        }
    };
}
```

### newOutputStream

```java
    /**
     * Constructs a stream that writes bytes to the given channel.
     * The stream will not be buffered. The stream will be safe for access
     * by multiple concurrent threads.  Closing the stream will in turn cause
     * the channel to be closed.  */
    public static OutputStream newOutputStream(final AsynchronousByteChannel ch) {
        checkNotNull(ch, "ch");
        return new OutputStream() {
            private ByteBuffer bb = null;
            private byte[] bs = null;   // Invoker's previous array
            private byte[] b1 = null;
            @Override
            public synchronized void write(int b) throws IOException {
               if (b1 == null)
                    b1 = new byte[1];
                b1[0] = (byte)b;
                this.write(b1);
            }

            @Override
            public synchronized void write(byte[] bs, int off, int len)
                throws IOException
            {
                if ((off < 0) || (off > bs.length) || (len < 0) ||
                    ((off + len) > bs.length) || ((off + len) < 0)) {
                    throw new IndexOutOfBoundsException();
                } else if (len == 0) {
                    return;
                }
                // 包数组包装成buffer
                ByteBuffer bb = ((this.bs == bs)
                                 ? this.bb
                                 : ByteBuffer.wrap(bs));
                bb.limit(Math.min(off + len, bb.capacity()));
                bb.position(off);
                this.bb = bb;
                this.bs = bs;

                boolean interrupted = false;
                try {
                    while (bb.remaining() > 0) {
                        try {
                            // 把数据写入到channel中
                            ch.write(bb).get();
                        } catch (ExecutionException ee) {
                            throw new IOException(ee.getCause());
                        } catch (InterruptedException ie) {
                            interrupted = true;
                        }
                    }
                } finally {
                    if (interrupted)
                        Thread.currentThread().interrupt();
                }
            }

            @Override
            public void close() throws IOException {
                ch.close();
            }
        };
    }
```

### newChannel

```java
    /** Constructs a channel that reads bytes from the given stream.
     * The resulting channel will not be buffered; it will simply redirect
     * its I/O operations to the given stream.  Closing the channel will in
     * turn cause the stream to be closed. */
    public static ReadableByteChannel newChannel(final InputStream in) {
        checkNotNull(in, "in");

        if (in instanceof FileInputStream &&
            FileInputStream.class.equals(in.getClass())) {
            return ((FileInputStream)in).getChannel();
        }

        return new ReadableByteChannelImpl(in);
    }
```

### newChannel

```java
    /* Constructs a channel that writes bytes to the given stream.
     * The resulting channel will not be buffered; it will simply redirect
     * its I/O operations to the given stream.  Closing the channel will in
     * turn cause the stream to be closed. */
    public static WritableByteChannel newChannel(final OutputStream out) {
        checkNotNull(out, "out");

        if (out instanceof FileOutputStream &&
            FileOutputStream.class.equals(out.getClass())) {
                return ((FileOutputStream)out).getChannel();
        }

        return new WritableByteChannelImpl(out);
    }
```

### newReader

```java
   /** Constructs a reader that decodes bytes from the given channel using the
     * given decoder.
     * <p> The resulting stream will contain an internal input buffer of at
     * least <tt>minBufferCap</tt> bytes.  The stream's <tt>read</tt> methods
     * will, as needed, fill the buffer by reading bytes from the underlying
     * channel; if the channel is in non-blocking mode when bytes are to be
     * read then an {@link IllegalBlockingModeException} will be thrown.  The
     * resulting stream will not otherwise be buffered, and it will not support
     * the {@link Reader#mark mark} or {@link Reader#reset reset} methods.
     * Closing the stream will in turn cause the channel to be closed. */
    public static Reader newReader(ReadableByteChannel ch,
                                   CharsetDecoder dec,
                                   int minBufferCap)
    {
        checkNotNull(ch, "ch");
        return StreamDecoder.forDecoder(ch, dec.reset(), minBufferCap);
    }
```



### newReader

```java
    /** Constructs a reader that decodes bytes from the given channel according
     * to the named charset. */
    public static Reader newReader(ReadableByteChannel ch,
                                   String csName)
    {
        checkNotNull(csName, "csName");
        return newReader(ch, Charset.forName(csName).newDecoder(), -1);
    }
```



### newWriter

```java
    /* Constructs a writer that encodes characters using the given encoder and
     * writes the resulting bytes to the given channel.
     * The resulting stream will contain an internal output buffer of at
     * least <tt>minBufferCap</tt> bytes.  The stream's <tt>write</tt> methods
     * will, as needed, flush the buffer by writing bytes to the underlying
     * channel; if the channel is in non-blocking mode when bytes are to be
     * written then an {@link IllegalBlockingModeException} will be thrown.
     * The resulting stream will not otherwise be buffered.  Closing the stream
     * will in turn cause the channel to be closed.   */
    public static Writer newWriter(final WritableByteChannel ch,
                                   final CharsetEncoder enc,
                                   final int minBufferCap)
    {
        checkNotNull(ch, "ch");
        return StreamEncoder.forEncoder(ch, enc.reset(), minBufferCap);
    }
```



### newWriter

```java
    /**
     * Constructs a writer that encodes characters according to the named
     * charset and writes the resulting bytes to the given channel. */
    public static Writer newWriter(WritableByteChannel ch,
                                   String csName)
    {
        checkNotNull(csName, "csName");
        return newWriter(ch, Charset.forName(csName).newEncoder(), -1);
    }
```



## 内部类

### ReadableByteChannelImpl

#### field

```java
// 保存输入源
InputStream in;
// 最多可读取
private static final int TRANSFER_SIZE = 8192;
// 存储读取的数据
private byte buf[] = new byte[0];
private boolean open = true;
// 锁
private Object readLock = new Object();
```



#### 构造函数

```java
ReadableByteChannelImpl(InputStream in) {
    this.in = in;
}
```

#### 功能函数

read

```java
public int read(ByteBuffer dst) throws IOException {
    // 剩余有效数据
    int len = dst.remaining();
    int totalRead = 0;
    int bytesRead = 0;
    synchronized (readLock) {
        while (totalRead < len) {
            int bytesToRead = Math.min((len - totalRead),
                                       TRANSFER_SIZE);
            if (buf.length < bytesToRead)
                buf = new byte[bytesToRead];
            if ((totalRead > 0) && !(in.available() > 0))
                break; // block at most once
            try {
                begin();
                // 读取数据到数组
                bytesRead = in.read(buf, 0, bytesToRead);
            } finally {
                end(bytesRead > 0);
            }
            if (bytesRead < 0)
                break;
            else
                totalRead += bytesRead;
            // 把读取到的数据放入到dst中
            dst.put(buf, 0, bytesRead);
        }
        if ((bytesRead < 0) && (totalRead == 0))
            return -1;
        return totalRead;
    }
}
```



close:

```java
protected void implCloseChannel() throws IOException {
    in.close();
    open = false;
}
```



### WritableByteChannelImpl

#### FIeld

```java
OutputStream out;
private static final int TRANSFER_SIZE = 8192;
private byte buf[] = new byte[0];
private boolean open = true;
private Object writeLock = new Object();
```

####　构造函数

```java
WritableByteChannelImpl(OutputStream out) {
    this.out = out;
}
```



#### 功能方法

write

```java
public int write(ByteBuffer src) throws IOException {
    int len = src.remaining();
    int totalWritten = 0;
    synchronized (writeLock) {
        while (totalWritten < len) {
            int bytesToWrite = Math.min((len - totalWritten),
                                        TRANSFER_SIZE);
            if (buf.length < bytesToWrite)
                buf = new byte[bytesToWrite];
            // 把src中数据读取到buf中
            src.get(buf, 0, bytesToWrite);
            try {
                begin();
                // 写暑数据到输出流中
                out.write(buf, 0, bytesToWrite);
            } finally {
                end(bytesToWrite > 0);
            }
            totalWritten += bytesToWrite;
        }
        return totalWritten;
    }
}
```



close:

```java
protected void implCloseChannel() throws IOException {
    out.close();
    open = false;
}
```



