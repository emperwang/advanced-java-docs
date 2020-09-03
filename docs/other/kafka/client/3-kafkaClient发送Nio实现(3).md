[TOC]

# kafkaClient发送Nio实现(3)

上篇分析到的Nio操作中的读取操作，本篇看一下Nio操作中的写实现。

回顾：

> org.apache.kafka.common.network.Selector#pollSelectionKeys

```java
 // 对有有就绪事件 key 进行处理,即处理key对应的channel的读写事件
    void pollSelectionKeys(Set<SelectionKey> selectionKeys,
                           boolean isImmediatelyConnected,  // 表示是否是 刚刚建立的连接
                           long currentTimeNanos) {
        // determineHandlingOrder 打乱 keys的顺序
        for (SelectionKey key : determineHandlingOrder(selectionKeys)) {
            // 获取此 key 上 attach的 kafkaChannel
            KafkaChannel channel = channel(key);
            // 记录 channel的开始时间
            long channelStartTimeNanos = recordTimePerConnection ? time.nanoseconds() : 0;
            /// 省略非关键 代码
                // 尝试读取数据
                // -- 重点 ---
                // 这里尝试读取时, 首先channel对应的读事件 ready
                attemptRead(key, channel);
                // channel中是否有 缓存的数据
                if (channel.hasBytesBuffered()) {
                    // 如果有缓存的数据,则记录此key
                    keysWithBufferedRead.add(key);
                }

                // 对可写 事件的处理
                // -- ---
                if (channel.ready() && key.isWritable() && !channel.maybeBeginClientReauthentication(
                    () -> channelStartTimeNanos != 0 ? channelStartTimeNanos : currentTimeNanos)) {
                    Send send;
                    try {
                        // 发送数据
                        send = channel.write();
                    } catch (Exception e) {
                        sendFailed = true;
                        throw e;
                    }
                    if (send != null) {
                        // 记录完成发送的send
                        this.completedSends.add(send);
                        // 记录完成发送字节数
                        this.sensors.recordBytesSent(channel.id(), send.size());
                    }
                }

                /* cancel any defunct sockets */
                // key 不可用了,则进行关闭操作
                if (!key.isValid())
                    close(channel, CloseMode.GRACEFUL);

            } catch (Exception e) {
                /// 
            } finally {
                // 记录 network 时间
                maybeRecordTimePerConnection(channel, channelStartTimeNanos);
            }
        }
    }
```

本篇主要看一下channel.write() 操作的实现。

> org.apache.kafka.common.network.KafkaChannel#write

```java
// 发送数据
public Send write() throws IOException {
    Send result = null;
    // 如果此channel中send 不为null,则说明有数据要发送
    // 那么就进行数据的发送
    if (send != null && send(send)) {
        result = send;
        send = null;
    }
    return result;
}
```

发送数据，上面分析到发送那些request时，最后是封装为send并记录到kafkaChannel中，此处就是当kafkaChannel中的send存在时，进行具体的发送。

> org.apache.kafka.common.network.KafkaChannel#send

```java
// 发送数据
// ---- 重点 ---
private boolean send(Send send) throws IOException {
    midWrite = true;
    // 数据的发送
    send.writeTo(transportLayer);
    if (send.completed()) {
        midWrite = false;
        // 发送完成后,去除OP_WRITE 事件
        transportLayer.removeInterestOps(SelectionKey.OP_WRITE);
    }
    return send.completed();
}
```

> org.apache.kafka.common.network.ByteBufferSend#writeTo

```java
// 把数据写出到 channel中
@Override
public long writeTo(GatheringByteChannel channel) throws IOException {
    // 把buffer中的数据 写入到 channel中
    long written = channel.write(buffers);
    if (written < 0)
        throw new EOFException("Wrote negative bytes to channel. This shouldn't happen.");
    remaining -= written;
    // 查看 此 channel 是否有待发送的数据
    pending = TransportLayers.hasPendingWrites(channel);
    return written;
}
```

> org.apache.kafka.common.network.PlaintextTransportLayer#write(java.nio.ByteBuffer[])

```java
// 发送数据到 channel中
@Override
public long write(ByteBuffer[] srcs) throws IOException {
    // 把srcs中的数据 写入到 socketChannel中
    return socketChannel.write(srcs);
}
```

最终把数据写入到channel中，并移除channel对应的SelectionKey.OP_WRITE事件。

简单总结一下就是：

1.  ConsumerNetworkClient的send request就是把请求发送到unsent 中按照node 分类记录起来
2.  ConsumerNetworkClient的poll 操作是
   1. 先发送上面使用 ConsumerNetworkClient-> send 的数据，其把request封装为send，并记录到对应的kafakChannel中
   2. 调用NetworkClient的 poll 函数
3. NetworkClient 的poll 函数  调用 org.apache.kafka.clients.NetworkClient#selector -> poll 函数进行进一步处理
4.  org.apache.kafka.common.network.Selector#poll  此poll 函数调用 nioSelector 来对 socketChannel进行真正的读写操作.































