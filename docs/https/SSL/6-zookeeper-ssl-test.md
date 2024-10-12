---
tags:
  - SSL
  - zookeeper
  - truststore
  - keystore
---

config:

```
# server
RPATH=/mnt/apache-zookeeper-3.8.4-bin/bin/certs
PASS=123456
#echo "CLASSPATH=$CLASSPATH"
export SERVER_JVMFLAGS="
-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
-Dzookeeper.ssl.keyStore.location=${RPATH}/server.p12
-Dzookeeper.ssl.keyStore.password=1234
-Dzookeeper.ssl.trustStore.location=${RPATH}/server_trust.jks
-Dzookeeper.ssl.trustStore.password=${PASS}
-Dzookeeper.ssl.hostnameVerification=false
-Dzookeeper.ssl.quorum.hostnameVerification=false
-Djavax.net.debug=all
"


# client
export CLIENT_JVMFLAGS="
-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty
-Dzookeeper.client.secure=true
-Dzookeeper.ssl.keyStore.location=${RPATH}/client.p12
-Dzookeeper.ssl.keyStore.password=1234
-Dzookeeper.ssl.trustStore.location=${RPATH}/client_trust.jks
-Dzookeeper.ssl.trustStore.password=${PASS}
-Dzookeeper.ssl.hostnameVerification=false
-Dzookeeper.ssl.quorum.hostnameVerification=false
-Djavax.net.debug=all
"

```

```cfg
secureClientPort=2281
ssl.protocol=TLSv1.2
ssl.enabledProtocols=TLSv1.2
ssl.ciphersuites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
ssl.keyStore.location= /opt/gcache/secure/Certs/keystore.jks
ssl.keyStore.password= 
ssl.trustStore.location= /opt/gcache/secure/Certs/truststore.jks
ssl.trustStore.password= 
ssl.switch=on 
    #on表示密码配置密文有效，off表示密码配置明文无效
```




## 报错记录

#### no cipher suites in common
```shell
## server端报错
2024-10-12 17:04:27,697 [myid:] - WARN  [nioEventLoopGroup-4-2:o.a.z.s.NettyServerCnxnFactory$CnxnChannelHandler@304] - Exception caught
io.netty.handler.codec.DecoderException: javax.net.ssl.SSLHandshakeException: no cipher suites in common
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:499)
        at io.netty.handler.codec.ByteToMessageDecoder.channelRead(ByteToMessageDecoder.java:290)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:444)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420)
        at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:412)
        at io.netty.channel.DefaultChannelPipeline$HeadContext.channelRead(DefaultChannelPipeline.java:1410)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:440)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420)
        at io.netty.channel.DefaultChannelPipeline.fireChannelRead(DefaultChannelPipeline.java:919)
        at io.netty.channel.nio.AbstractNioByteChannel$NioByteUnsafe.read(AbstractNioByteChannel.java:166)
        at io.netty.channel.nio.NioEventLoop.processSelectedKey(NioEventLoop.java:788)
        at io.netty.channel.nio.NioEventLoop.processSelectedKeysOptimized(NioEventLoop.java:724)
        at io.netty.channel.nio.NioEventLoop.processSelectedKeys(NioEventLoop.java:650)
        at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:562)
        at io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:997)
        at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)
        at io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30)
        at java.lang.Thread.run(Thread.java:748)
Caused by: javax.net.ssl.SSLHandshakeException: no cipher suites in common
        at sun.security.ssl.Handshaker.checkThrown(Handshaker.java:1521)
        at sun.security.ssl.SSLEngineImpl.checkTaskThrown(SSLEngineImpl.java:528)
        at sun.security.ssl.SSLEngineImpl.readNetRecord(SSLEngineImpl.java:802)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:766)
        at javax.net.ssl.SSLEngine.unwrap(SSLEngine.java:624)
        at io.netty.handler.ssl.SslHandler$SslEngineType$3.unwrap(SslHandler.java:310)
        at io.netty.handler.ssl.SslHandler.unwrap(SslHandler.java:1445)
        at io.netty.handler.ssl.SslHandler.decodeJdkCompatible(SslHandler.java:1338)
        at io.netty.handler.ssl.SslHandler.decode(SslHandler.java:1387)
        at io.netty.handler.codec.ByteToMessageDecoder.decodeRemovalReentryProtection(ByteToMessageDecoder.java:529)
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:468)
        ... 17 common frames omitted


```


```shell
## client 报错:
2024-10-12 17:04:27,696 [myid:] - ERROR [nioEventLoopGroup-2-1:o.a.z.ClientCnxnSocketNetty$ZKClientHandler@531] - Unexpected throwable
io.netty.handler.codec.DecoderException: javax.net.ssl.SSLException: Received fatal alert: handshake_failure
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:499)
        at io.netty.handler.codec.ByteToMessageDecoder.channelRead(ByteToMessageDecoder.java:290)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:444)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420)
        at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:412)
        at io.netty.channel.DefaultChannelPipeline$HeadContext.channelRead(DefaultChannelPipeline.java:1410)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:440)
        at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420)
        at io.netty.channel.DefaultChannelPipeline.fireChannelRead(DefaultChannelPipeline.java:919)
        at io.netty.channel.nio.AbstractNioByteChannel$NioByteUnsafe.read(AbstractNioByteChannel.java:166)
        at io.netty.channel.nio.NioEventLoop.processSelectedKey(NioEventLoop.java:788)
        at io.netty.channel.nio.NioEventLoop.processSelectedKeysOptimized(NioEventLoop.java:724)
        at io.netty.channel.nio.NioEventLoop.processSelectedKeys(NioEventLoop.java:650)
        at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:562)
        at io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:997)
        at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)
        at io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30)
        at java.lang.Thread.run(Thread.java:748)
Caused by: javax.net.ssl.SSLException: Received fatal alert: handshake_failure
        at sun.security.ssl.Alerts.getSSLException(Alerts.java:208)
        at sun.security.ssl.SSLEngineImpl.fatal(SSLEngineImpl.java:1647)
        at sun.security.ssl.SSLEngineImpl.fatal(SSLEngineImpl.java:1615)
        at sun.security.ssl.SSLEngineImpl.recvAlert(SSLEngineImpl.java:1781)
        at sun.security.ssl.SSLEngineImpl.readRecord(SSLEngineImpl.java:1070)
        at sun.security.ssl.SSLEngineImpl.readNetRecord(SSLEngineImpl.java:896)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:766)
        at javax.net.ssl.SSLEngine.unwrap(SSLEngine.java:624)
        at io.netty.handler.ssl.SslHandler$SslEngineType$3.unwrap(SslHandler.java:310)
        at io.netty.handler.ssl.SslHandler.unwrap(SslHandler.java:1445)
        at io.netty.handler.ssl.SslHandler.decodeJdkCompatible(SslHandler.java:1338)
        at io.netty.handler.ssl.SslHandler.decode(SslHandler.java:1387)
        at io.netty.handler.codec.ByteToMessageDecoder.decodeRemovalReentryProtection(ByteToMessageDecoder.java:529)
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:468)
        ... 17 common frames omitted
```

原因：
server 的 keystore (not trustStore) 是空的.

解决方法:
使用PKCS12的 keystore 重新启动.


#### unable to find valid certification path to requested target
```shell
## client error:
failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target (
"throwable" : {
  sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```

reason:
 client 验证不了 server发送过来的证书.
 [[日志1]]

resolve:
在客户端导入CA 证书



#### javax.net.ssl.SSLHandshakeException: Empty server certificate chain

server端日志
[[server-日志]]
client端日志
[[client-日志]]

报错细节如上的日志文件所示:
```shell
## server
Caused by: javax.net.ssl.SSLHandshakeException: Empty server certificate chain

## client
Caused by: javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
```

那么server端为什么报这个错呢？  通过client端的日志分析， 可以看到如下:

![](./images/tls_client_cert.png)
client没有找到一个有效的证书来发送.

那么我们就要分析一下,  zookeeper client是如何选取证书的呢?
看一下分析:
[[zookeeper-client-certificate-select]]





