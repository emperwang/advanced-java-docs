
```txt
2024-10-12 23:08:35,686 [myid:] - INFO  [main:o.a.z.ZooKeeper@637] - Initiating client connection, connectString=name2:2281 sessionTimeout=30000 watcher=org.apache.zookeeper.ZooKeeperMain$MyWatcher@2a2d45ba
2024-10-12 23:08:35,692 [myid:] - INFO  [main:o.a.z.c.X509Util@78] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
2024-10-12 23:08:35,832 [myid:] - INFO  [main:o.a.z.ClientCnxnSocket@239] - jute.maxbuffer value is 1048575 Bytes
2024-10-12 23:08:35,838 [myid:] - INFO  [main:o.a.z.ClientCnxn@1747] - zookeeper.request.timeout value is 0. feature enabled=false
Welcome to ZooKeeper!
2024-10-12 23:08:35,843 [myid:name2:2281] - INFO  [main-SendThread(name2:2281):o.a.z.ClientCnxn$SendThread@1177] - Opening socket connection to server name2/192.168.30.15:2281.
2024-10-12 23:08:35,844 [myid:name2:2281] - INFO  [main-SendThread(name2:2281):o.a.z.ClientCnxn$SendThread@1179] - SASL config status: Will not attempt to authenticate using SASL (unknown error)
JLine support is enabled
[zk: name2:2281(CONNECTING) 0] javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.166 CST|X509TrustManagerImpl.java:96|adding as trusted certificates (
  "certificate" : {
    "version"            : "v1",
    "serial number"      : "00 96 72 83 A7 9A 62 86 8F",
    "signature algorithm": "SHA512withRSA",
    "issuer"             : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "not before"         : "2024-10-12 17:28:35.000 CST",
    "not  after"         : "2027-07-09 17:28:35.000 CST",
    "subject"            : "CN=client, OU=client, O=client, L=GZ, ST=GD, C=CN",
    "subject public key" : "RSA"},
  "certificate" : {
    "version"            : "v1",
    "serial number"      : "00 90 7D F2 D3 D4 58 10 AC",
    "signature algorithm": "SHA512withRSA",
    "issuer"             : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "not before"         : "2024-10-12 17:26:30.000 CST",
    "not  after"         : "2034-10-10 17:26:30.000 CST",
    "subject"            : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "subject public key" : "RSA"}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.169 CST|SSLContextImpl.java:425|System property jdk.tls.client.cipherSuites is set to 'null'
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.169 CST|SSLContextImpl.java:425|System property jdk.tls.server.cipherSuites is set to 'null'
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.184 CST|SSLCipher.java:438|jdk.tls.keyLimits:  entry = AES/GCM/NoPadding KeyUpdate 2^37. AES/GCM/NOPADDING:KEYUPDATE = 137438953472
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.195 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.195 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.196 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_256_GCM_SHA384
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_256_GCM_SHA384
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.197 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_128_GCM_SHA256
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_128_GCM_SHA256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_256_CBC_SHA256
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_256_CBC_SHA256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_anon_WITH_AES_256_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_anon_WITH_AES_256_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_256_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.198 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_256_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_128_CBC_SHA256
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_128_CBC_SHA256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_anon_WITH_AES_128_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_anon_WITH_AES_128_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_DH_anon_WITH_AES_128_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_DH_anon_WITH_AES_128_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.199 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DH_anon_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DH_anon_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.200 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_RC4_128_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_RC4_128_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_anon_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_anon_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DH_anon_WITH_RC4_128_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.201 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DH_anon_WITH_RC4_128_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_DES_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_DES_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_DES_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_DES_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_DES_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_DES_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.202 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DH_anon_WITH_DES_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.203 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DH_anon_WITH_DES_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.203 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.203 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.204 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.204 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.204 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.204 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DH_anon_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DH_anon_EXPORT_WITH_DES40_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DH_anon_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DH_anon_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_RSA_WITH_NULL_SHA256
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.205 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_RSA_WITH_NULL_SHA256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_NULL_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_NULL_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_NULL_SHAjavax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_NULL_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_NULL_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.206 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.207 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_anon_WITH_NULL_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.207 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_anon_WITH_NULL_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.207 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_NULL_MD5javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.208 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_NULL_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.208 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.209 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.209 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_3DES_EDE_CBC_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.209 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_3DES_EDE_CBC_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.209 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_RC4_128_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.209 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_RC4_128_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_RC4_128_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_RC4_128_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_DES_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_DES_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_WITH_DES_CBC_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.210 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_WITH_DES_CBC_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_EXPORT_WITH_DES_CBC_40_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_EXPORT_WITH_DES_CBC_40_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_EXPORT_WITH_DES_CBC_40_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_EXPORT_WITH_DES_CBC_40_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_EXPORT_WITH_RC4_40_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_EXPORT_WITH_RC4_40_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_KRB5_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.211 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_KRB5_EXPORT_WITH_RC4_40_MD5
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.212 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.213 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.213 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.213 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_AES_256_GCM_SHA384
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_AES_128_GCM_SHA256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.214 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.215 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.216 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.216 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.216 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.216 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.216 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.218 CST|SSLContextImpl.java:115|trigger seeding of SecureRandom
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.218 CST|SSLContextImpl.java:119|done seeding of SecureRandom
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.233 CST|SSLConfiguration.java:450|System property jdk.tls.server.SignatureSchemes is set to 'null'
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.234 CST|SSLConfiguration.java:450|System property jdk.tls.client.SignatureSchemes is set to 'null'
2024-10-12 23:08:36,249 [myid:] - INFO  [nioEventLoopGroup-2-1:o.a.z.ClientCnxnSocketNetty$ZKClientPipelineFactory@463] - SSL handler added for channel: [id: 0x154f5c9c]
2024-10-12 23:08:36,278 [myid:] - INFO  [nioEventLoopGroup-2-1:o.a.z.ClientCnxn$SendThread@1013] - Socket connection established, initiating session, client: /192.168.30.15:59724, server: name2/192.168.30.15:2281
2024-10-12 23:08:36,279 [myid:] - INFO  [nioEventLoopGroup-2-1:o.a.z.ClientCnxnSocketNetty$1@185] - channel is connected: [id: 0x154f5c9c, L:/192.168.30.15:59724 - R:name2/192.168.30.15:2281]
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.308 CST|ServerNameExtension.java:261|Unable to indicate server name
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.308 CST|SSLExtensions.java:260|Ignore, context unavailable extension: server_name
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.308 CST|SSLExtensions.java:260|Ignore, context unavailable extension: status_request
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.311 CST|SignatureScheme.java:297|Signature algorithm, ed25519, is not supported by the underlying providers
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.311 CST|SignatureScheme.java:297|Signature algorithm, ed448, is not supported by the underlying providers
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.322 CST|SignatureScheme.java:384|Ignore unsupported signature scheme: ed25519
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.322 CST|SignatureScheme.java:384|Ignore unsupported signature scheme: ed448
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.324 CST|SignatureScheme.java:403|Ignore disabled signature scheme: rsa_md5
javax.net.ssl|INFO|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.325 CST|AlpnExtension.java:178|No available application protocols
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.325 CST|SSLExtensions.java:260|Ignore, context unavailable extension: application_layer_protocol_negotiation
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.326 CST|SSLExtensions.java:260|Ignore, context unavailable extension: status_request_v2
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.326 CST|SSLExtensions.java:260|Ignore, context unavailable extension: renegotiation_info
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.327 CST|ClientHello.java:564|Produced ClientHello handshake message (
"ClientHello": {
  "client version"      : "TLSv1.2",
  "random"              : "3A 98 F3 35 EF 29 6A 6A 40 75 82 32 D0 81 BA C7 3D 68 E2 18 2B BA 27 5F 9C 93 83 A0 07 C4 D1 53",
  "session id"          : "",
  "cipher suites"       : "[TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384(0xC02C), TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256(0xC02B), TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384(0xC030), TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256(0xC02F), TLS_DHE_RSA_WITH_AES_256_GCM_SHA384(0x009F), TLS_DHE_DSS_WITH_AES_256_GCM_SHA384(0x00A3), TLS_DHE_RSA_WITH_AES_128_GCM_SHA256(0x009E), TLS_DHE_DSS_WITH_AES_128_GCM_SHA256(0x00A2), TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384(0xC024), TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384(0xC028), TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256(0xC023), TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256(0xC027), TLS_DHE_RSA_WITH_AES_256_CBC_SHA256(0x006B), TLS_DHE_DSS_WITH_AES_256_CBC_SHA256(0x006A), TLS_DHE_RSA_WITH_AES_128_CBC_SHA256(0x0067), TLS_DHE_DSS_WITH_AES_128_CBC_SHA256(0x0040), TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384(0xC02E), TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384(0xC032), TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256(0xC02D), TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256(0xC031), TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384(0xC026), TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384(0xC02A), TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256(0xC025), TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256(0xC029), TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA(0xC00A), TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA(0xC014), TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA(0xC009), TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA(0xC013), TLS_DHE_RSA_WITH_AES_256_CBC_SHA(0x0039), TLS_DHE_DSS_WITH_AES_256_CBC_SHA(0x0038), TLS_DHE_RSA_WITH_AES_128_CBC_SHA(0x0033), TLS_DHE_DSS_WITH_AES_128_CBC_SHA(0x0032), TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA(0xC005), TLS_ECDH_RSA_WITH_AES_256_CBC_SHA(0xC00F), TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA(0xC004), TLS_ECDH_RSA_WITH_AES_128_CBC_SHA(0xC00E), TLS_RSA_WITH_AES_256_GCM_SHA384(0x009D), TLS_RSA_WITH_AES_128_GCM_SHA256(0x009C), TLS_RSA_WITH_AES_256_CBC_SHA256(0x003D), TLS_RSA_WITH_AES_128_CBC_SHA256(0x003C), TLS_RSA_WITH_AES_256_CBC_SHA(0x0035), TLS_RSA_WITH_AES_128_CBC_SHA(0x002F), TLS_EMPTY_RENEGOTIATION_INFO_SCSV(0x00FF)]",
  "compression methods" : "00",
  "extensions"          : [
    "supported_groups (10)": {
      "versions": [secp256r1, secp384r1, secp521r1, ffdhe2048, ffdhe3072, ffdhe4096, ffdhe6144, ffdhe8192]
    },
    "ec_point_formats (11)": {
      "formats": [uncompressed]
    },
    "signature_algorithms (13)": {
      "signature schemes": [ecdsa_secp256r1_sha256, ecdsa_secp384r1_sha384, ecdsa_secp521r1_sha512, rsa_pss_rsae_sha256, rsa_pss_rsae_sha384, rsa_pss_rsae_sha512, rsa_pss_pss_sha256, rsa_pss_pss_sha384, rsa_pss_pss_sha512, rsa_pkcs1_sha256, rsa_pkcs1_sha384, rsa_pkcs1_sha512, dsa_sha256, ecdsa_sha224, rsa_sha224, dsa_sha224, ecdsa_sha1, rsa_pkcs1_sha1, dsa_sha1]
    },
    "signature_algorithms_cert (50)": {
      "signature schemes": [ecdsa_secp256r1_sha256, ecdsa_secp384r1_sha384, ecdsa_secp521r1_sha512, rsa_pss_rsae_sha256, rsa_pss_rsae_sha384, rsa_pss_rsae_sha512, rsa_pss_pss_sha256, rsa_pss_pss_sha384, rsa_pss_pss_sha512, rsa_pkcs1_sha256, rsa_pkcs1_sha384, rsa_pkcs1_sha512, dsa_sha256, ecdsa_sha224, rsa_sha224, dsa_sha224, ecdsa_sha1, rsa_pkcs1_sha1, dsa_sha1]
    },
    "extended_master_secret (23)": {
      <empty>
    },
    "supported_versions (43)": {
      "versions": [TLSv1.2]
    }
  ]
}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.376 CST|SSLEngineOutputRecord.java:505|WRITE: TLS12 handshake, length = 258
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.379 CST|SSLEngineOutputRecord.java:523|Raw write (
  0000: 16 03 03 01 02 01 00 00   FE 03 03 3A 98 F3 35 EF  ...........:..5.
  0010: 29 6A 6A 40 75 82 32 D0   81 BA C7 3D 68 E2 18 2B  )jj@u.2....=h..+
  0020: BA 27 5F 9C 93 83 A0 07   C4 D1 53 00 00 56 C0 2C  .'_.......S..V.,
  0030: C0 2B C0 30 C0 2F 00 9F   00 A3 00 9E 00 A2 C0 24  .+.0./.........$
  0040: C0 28 C0 23 C0 27 00 6B   00 6A 00 67 00 40 C0 2E  .(.#.'.k.j.g.@..
  0050: C0 32 C0 2D C0 31 C0 26   C0 2A C0 25 C0 29 C0 0A  .2.-.1.&.*.%.)..
  0060: C0 14 C0 09 C0 13 00 39   00 38 00 33 00 32 C0 05  .......9.8.3.2..
  0070: C0 0F C0 04 C0 0E 00 9D   00 9C 00 3D 00 3C 00 35  ...........=.<.5
  0080: 00 2F 00 FF 01 00 00 7F   00 0A 00 12 00 10 00 17  ./..............
  0090: 00 18 00 19 01 00 01 01   01 02 01 03 01 04 00 0B  ................
  00A0: 00 02 01 00 00 0D 00 28   00 26 04 03 05 03 06 03  .......(.&......
  00B0: 08 04 08 05 08 06 08 09   08 0A 08 0B 04 01 05 01  ................
  00C0: 06 01 04 02 03 03 03 01   03 02 02 03 02 01 02 02  ................
  00D0: 00 32 00 28 00 26 04 03   05 03 06 03 08 04 08 05  .2.(.&..........
  00E0: 08 06 08 09 08 0A 08 0B   04 01 05 01 06 01 04 02  ................
  00F0: 03 03 03 01 03 02 02 03   02 01 02 02 00 17 00 00  ................
  0100: 00 2B 00 03 02 03 03                               .+.....
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.719 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.721 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.721 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.722 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.723 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:399|Ignore disabled cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.724 CST|SSLContextImpl.java:408|Ignore unsupported cipher suite: SSL_RSA_WITH_3DES_EDE_CBC_SHA
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.725 CST|SSLContextImpl.java:115|trigger seeding of SecureRandom
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.725 CST|SSLContextImpl.java:119|done seeding of SecureRandom
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.727 CST|SSLContextImpl.java:115|trigger seeding of SecureRandom
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.728 CST|SSLContextImpl.java:119|done seeding of SecureRandom
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.737 CST|SSLEngineInputRecord.java:177|Raw read (
  0000: 16 03 03 07 6E 02 00 00   51 03 03 32 AF 87 21 77  ....n...Q..2..!w
  0010: E7 7D 47 1A 84 D3 3A 3D   45 5D 56 19 E2 DD B7 13  ..G...:=E]V.....
  0020: 9C 35 C8 D6 0D BD FB 3E   13 65 49 20 5C 37 D3 EB  .5.....>.eI \7..
  0030: 61 FD 6F 42 2F C0 D4 96   F8 24 10 BB 71 36 A4 6D  a.oB/....$..q6.m
  0040: 1E 2B 77 11 7B 3E 63 94   12 D6 AC 09 C0 30 00 00  .+w..>c......0..
  0050: 09 00 17 00 00 FF 01 00   01 00 0B 00 04 34 00 04  .............4..
  0060: 31 00 04 2E 30 82 04 2A   30 82 03 12 02 09 00 96  1...0..*0.......
  0070: 72 83 A7 9A 62 86 8E 30   0D 06 09 2A 86 48 86 F7  r...b..0...*.H..
  0080: 0D 01 01 0D 05 00 30 54   31 0B 30 09 06 03 55 04  ......0T1.0...U.
  0090: 06 13 02 43 4E 31 0B 30   09 06 03 55 04 08 0C 02  ...CN1.0...U....
  00A0: 47 44 31 0B 30 09 06 03   55 04 07 0C 02 47 5A 31  GD1.0...U....GZ1
  00B0: 0D 30 0B 06 03 55 04 0A   0C 04 63 65 72 74 31 0D  .0...U....cert1.
  00C0: 30 0B 06 03 55 04 0B 0C   04 72 6F 6F 74 31 0D 30  0...U....root1.0
  00D0: 0B 06 03 55 04 03 0C 04   72 6F 6F 74 30 1E 17 0D  ...U....root0...
  00E0: 32 34 31 30 31 32 30 39   32 38 30 30 5A 17 0D 32  241012092800Z..2
  00F0: 37 30 37 30 39 30 39 32   38 30 30 5A 30 5A 31 0B  70709092800Z0Z1.
  0100: 30 09 06 03 55 04 06 13   02 43 4E 31 0B 30 09 06  0...U....CN1.0..
  0110: 03 55 04 08 0C 02 47 44   31 0B 30 09 06 03 55 04  .U....GD1.0...U.
  0120: 07 0C 02 47 5A 31 0F 30   0D 06 03 55 04 0A 0C 06  ...GZ1.0...U....
  0130: 73 65 72 76 65 72 31 0F   30 0D 06 03 55 04 0B 0C  server1.0...U...
  0140: 06 73 65 72 76 65 72 31   0F 30 0D 06 03 55 04 03  .server1.0...U..
  0150: 0C 06 73 65 72 76 65 72   30 82 02 22 30 0D 06 09  ..server0.."0...
  0160: 2A 86 48 86 F7 0D 01 01   01 05 00 03 82 02 0F 00  *.H.............
  0170: 30 82 02 0A 02 82 02 01   00 A3 9C 35 B7 A2 21 B2  0..........5..!.
  0180: C0 48 72 C2 CB F6 C5 B1   AD AE D1 03 DF E4 09 E0  .Hr.............
  0190: A1 E0 1B 17 45 9A FF E1   18 36 4B FF D5 F0 C7 6B  ....E....6K....k
  01A0: 35 75 85 04 C3 C7 42 CE   7D C8 16 30 0C 16 3D 7B  5u....B....0..=.
  01B0: 2E FD B4 54 90 43 BF 95   95 8D 89 12 86 53 85 0B  ...T.C.......S..
  01C0: 65 2F 80 B6 BB C9 0C 8C   14 46 9F 78 C2 7C 9E 7F  e/.......F.x....
  01D0: 4B B6 C0 16 D2 08 62 8E   46 72 33 35 DC 0A 6B 36  K.....b.Fr35..k6
  01E0: B8 C8 F6 32 84 57 5A A3   7A 42 F9 AC 2E DF 40 B6  ...2.WZ.zB....@.
  01F0: 7B 51 CC 27 88 1F 53 0C   48 D6 FB 69 97 A4 73 5A  .Q.'..S.H..i..sZ
  0200: 4C 8E 56 A0 01 82 B7 8B   67 E3 B3 AF 54 65 A9 C5  L.V.....g...Te..
  0210: B1 01 F7 8C 63 83 B2 C4   5A 48 30 F5 8F 54 3D 01  ....c...ZH0..T=.
  0220: 69 E2 A0 4B CE 7F 4C D0   53 DA 36 7E 33 E6 76 9C  i..K..L.S.6.3.v.
  0230: B4 8B DF 63 EE 5B AC 5D   C6 CC 27 FF 6C 70 EB 15  ...c.[.]..'.lp..
  0240: E5 E4 F1 0B F2 FC B7 D7   58 A8 E5 24 E0 59 F9 DC  ........X..$.Y..
  0250: CD 0E F9 40 08 5F E6 D4   1D 6D 0B 4B F2 38 CA 77  ...@._...m.K.8.w
  0260: 4D 25 B7 AB C3 CD 86 91   88 9C 16 D1 57 D1 55 36  M%..........W.U6
  0270: 0B AD A8 5C B0 44 D3 63   54 55 DE 7D EB E1 3A 24  ...\.D.cTU....:$
  0280: E5 88 D0 EF 7B 3C DB 39   19 5D AD 1C 01 23 6B 21  .....<.9.]...#k!
  0290: C2 2B 7D 89 60 03 A9 7B   22 A1 84 1D 2A C0 CE 71  .+..`..."...*..q
  02A0: 5B 0A 9C 1A 50 EE AA 76   6D D6 02 37 68 0A 5E A9  [...P..vm..7h.^.
  02B0: AB DA 0E 98 F6 6B 07 B6   F7 48 74 EC 95 CE C1 5D  .....k...Ht....]
  02C0: 7A 42 D4 0C F2 94 DA 9F   ED 82 95 67 66 DC BC B6  zB.........gf...
  02D0: 95 5A B4 97 78 69 52 6B   8B 53 F9 BE 4A 91 3A 8C  .Z..xiRk.S..J.:.
  02E0: 88 A1 57 95 53 4C D7 D0   96 18 84 F1 6F 4A F6 EE  ..W.SL......oJ..
  02F0: C8 5A F2 7C 1E E2 80 F4   7D CD 8A 0C 0B DD 0E 2D  .Z.............-
  0300: 7D 47 D0 F8 B5 37 19 08   74 DB 5C 8C 79 2E 8E AF  .G...7..t.\.y...
  0310: 1F FD EC D3 96 40 04 7F   19 7D 9F BE 41 A9 85 40  .....@......A..@
  0320: 46 31 9F 2E AC 5E 0E 7A   52 A3 BB 1D 34 A8 22 41  F1...^.zR...4."A
  0330: BF 17 A3 54 7F 6E D2 0D   3B F9 4D DA 35 BD D3 1D  ...T.n..;.M.5...
  0340: B5 55 61 50 9B 77 EC 8C   5C 78 37 BD EF EC 30 B3  .UaP.w..\x7...0.
  0350: 97 A7 BC 0A BF 2B 52 55   B3 00 B1 09 F5 E9 9F F6  .....+RU........
  0360: 01 B1 71 CA 41 7F 99 76   57 51 72 1E 5D 72 3A 59  ..q.A..vWQr.]r:Y
  0370: 22 3A 65 62 3B 00 4F E0   37 02 03 01 00 01 30 0D  ":eb;.O.7.....0.
  0380: 06 09 2A 86 48 86 F7 0D   01 01 0D 05 00 03 82 01  ..*.H...........
  0390: 01 00 C3 B9 67 EF 13 A1   B9 38 7B F8 C7 D7 FD B8  ....g....8......
  03A0: 58 FD 51 E4 E6 6D E9 F6   A5 D4 97 82 E2 5B DC EA  X.Q..m.......[..
  03B0: 3A 2A 8C 41 93 BE EB 0F   C0 C8 E4 EB A1 67 EF A8  :*.A.........g..
  03C0: AE D9 39 B4 C8 54 5B EB   DA 05 66 50 BA 3D 66 2D  ..9..T[...fP.=f-
  03D0: 4A 5E F4 75 64 0E A8 2A   0A 26 0D 91 5C 9C 65 AE  J^.ud..*.&..\.e.
  03E0: 4E F4 BD 94 7F B4 B9 B9   3E CB 48 DD 19 C0 4B 7A  N.......>.H...Kz
  03F0: 85 99 68 0A 99 EA 74 37   0F AA 45 E4 6A 97 92 E0  ..h...t7..E.j...
  0400: 96 CE 20 F5 11 18 85 62   C2 CD 86 D5 5B 49 A1 CD  .. ....b....[I..
  0410: 73 CD 23 AB D6 B0 16 68   4C 08 6E AD 2B AF 1A 2B  s.#....hL.n.+..+
  0420: F1 55 89 ED 96 A9 70 6B   37 2C FD A9 12 E4 13 20  .U....pk7,..... 
  0430: 78 16 31 0E E5 F1 D0 6E   A4 D8 DD 5D 67 6B 7D F9  x.1....n...]gk..
  0440: 83 60 1F 3F A3 F0 A1 75   94 7B 18 A2 54 29 76 55  .`.?...u....T)vU
  0450: E8 08 99 60 BD 28 10 C4   E9 CF 11 D3 7F 09 F7 64  ...`.(.........d
  0460: F9 91 27 2B 48 31 36 0A   FD 65 C6 46 8A 5D 31 66  ..'+H16..e.F.]1f
  0470: B8 8B 8F 29 0C 86 14 FB   F4 FF 78 6F A9 6F B4 54  ...)......xo.o.T
  0480: 24 94 09 F7 54 2A B8 5D   AA 66 1C B2 45 F8 E8 FC  $...T*.].f..E...
  0490: 4B AD 0C 00 02 49 03 00   17 41 04 EC 4B C9 39 79  K....I...A..K.9y
  04A0: 4D 3C 63 0B FD E2 57 E1   9E 53 D1 18 97 80 11 4B  M<c...W..S.....K
  04B0: DE F1 C7 87 A4 0D 39 86   C0 24 8A 02 51 47 34 21  ......9..$..QG4!
  04C0: 0E C1 62 BB DF CE 10 A2   AB AE CB 3A 9A 75 53 AF  ..b........:.uS.
  04D0: 12 B4 9E 88 CA 9D F3 01   45 45 B4 08 04 02 00 7F  ........EE......
  04E0: EF E2 5B 8B 8B D7 AB FA   59 15 DC DF 9C F7 96 95  ..[.....Y.......
  04F0: 18 05 64 A1 99 FD 79 D1   AC 32 D1 02 B6 EA 5F 81  ..d...y..2...._.
  0500: 10 58 72 2C CD 4D 5C 82   0D 9B BA A4 91 53 4C AD  .Xr,.M\......SL.
  0510: 08 71 A8 E4 95 A1 B7 94   93 A9 61 60 01 F3 0F F8  .q........a`....
  0520: B0 9A D4 FB 72 4E 7E 85   42 20 66 09 1A 3F 0C 24  ....rN..B f..?.$
  0530: DD 21 55 D0 BF 78 32 F3   D6 76 22 F0 54 C4 A1 22  .!U..x2..v".T.."
  0540: 8A 5B 27 4D 60 82 6B F2   73 8A A8 59 15 23 8B 27  .['M`.k.s..Y.#.'
  0550: CF E1 7F 5A 36 75 C6 68   CF A2 74 AE 16 4D 52 5E  ...Z6u.h..t..MR^
  0560: A2 EB F4 7E 33 4E 6D 70   22 5D 7E 33 5F 4B F3 BC  ....3Nmp"].3_K..
  0570: 9C 68 6B F6 64 CA 55 7C   0D F2 F9 E8 9C 9C A8 B0  .hk.d.U.........
  0580: 74 51 35 C0 4F E6 30 C0   96 72 45 91 E6 ED 6E 09  tQ5.O.0..rE...n.
  0590: 7D 0A 76 BD 90 E8 23 35   2F BF 3E 89 06 EC 33 74  ..v...#5/.>...3t
  05A0: A2 71 8C EB 9D 87 E5 F7   9C 9A 25 C5 E4 C4 1E 95  .q........%.....
  05B0: 17 A0 3E 43 B6 99 47 41   64 AF 5B 46 73 01 7E 3C  ..>C..GAd.[Fs..<
  05C0: D1 A9 EB 7A 27 D4 4E E4   B5 D6 61 C7 F4 30 4E 9F  ...z'.N...a..0N.
  05D0: FF 23 45 B5 E3 50 AE 55   A4 BF 49 A5 A9 0C 9E 0A  .#E..P.U..I.....
  05E0: 9E 31 10 3E D6 7F C4 70   43 6B 12 5B 4F 5A 44 E4  .1.>...pCk.[OZD.
  05F0: 75 0F 26 3E 70 F6 BF 06   8D 81 CB AB E4 97 99 70  u.&>p..........p
  0600: 72 C7 7A 63 20 A4 54 02   E4 03 AF 03 46 8C 1F CA  r.zc .T.....F...
  0610: CA AC C1 81 E5 87 B8 DB   57 FE 02 8A 43 D4 ED 7A  ........W...C..z
  0620: 63 DD 0F 8C D3 97 27 B2   67 2B 77 7C 3F B9 C2 78  c.....'.g+w.?..x
  0630: AD CF CA DD A3 92 EC 06   59 81 03 0A C8 61 6C C0  ........Y....al.
  0640: 67 1D F2 0F 0D C4 5A 7C   91 86 8F BF A0 89 22 07  g.....Z.......".
  0650: E9 A4 46 8F 3D F4 82 09   B2 94 15 FE 27 D6 B6 B0  ..F.=.......'...
  0660: 87 57 87 04 13 B5 F5 65   9A 42 D4 5B 08 D3 E1 74  .W.....e.B.[...t
  0670: 8E FB D4 62 3A E5 D3 4D   2C 2E 67 88 90 B0 22 47  ...b:..M,.g..."G
  0680: D7 28 D0 DD 02 4A B6 54   31 0F 66 97 C6 40 9A 43  .(...J.T1.f..@.C
  0690: 4D E9 F0 D5 99 1E 50 28   D6 37 7E 98 D2 6C C8 9C  M.....P(.7...l..
  06A0: B7 E1 55 3A A4 53 72 D4   A5 E6 7C 3C 87 D8 64 D2  ..U:.Sr....<..d.
  06B0: 37 BD 87 6C EA F0 48 77   A6 0A DF BF FF 4E 6F 33  7..l..Hw.....No3
  06C0: 89 AE E8 04 A5 EA 10 62   AE 2A F0 9A 7F F5 F4 70  .......b.*.....p
  06D0: 2F 8C AC 96 21 E7 82 4E   AE A2 0B 9A 48 DC 64 0D  /...!..N....H.d.
  06E0: 00 00 8C 03 40 01 02 00   26 04 03 05 03 06 03 08  ....@...&.......
  06F0: 04 08 05 08 06 08 09 08   0A 08 0B 04 01 05 01 06  ................
  0700: 01 04 02 03 03 03 01 03   02 02 03 02 01 02 02 00  ................
  0710: 5E 00 5C 30 5A 31 0B 30   09 06 03 55 04 06 13 02  ^.\0Z1.0...U....
  0720: 43 4E 31 0B 30 09 06 03   55 04 08 0C 02 47 44 31  CN1.0...U....GD1
  0730: 0B 30 09 06 03 55 04 07   0C 02 47 5A 31 0F 30 0D  .0...U....GZ1.0.
  0740: 06 03 55 04 0A 0C 06 73   65 72 76 65 72 31 0F 30  ..U....server1.0
  0750: 0D 06 03 55 04 0B 0C 06   73 65 72 76 65 72 31 0F  ...U....server1.
  0760: 30 0D 06 03 55 04 03 0C   06 73 65 72 76 65 72 0E  0...U....server.
  0770: 00 00 00                                           ...
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.738 CST|SSLEngineInputRecord.java:214|READ: TLSv1.2 handshake, length = 1902
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.740 CST|ServerHello.java:863|Consuming ServerHello handshake message (
"ServerHello": {
  "server version"      : "TLSv1.2",
  "random"              : "32 AF 87 21 77 E7 7D 47 1A 84 D3 3A 3D 45 5D 56 19 E2 DD B7 13 9C 35 C8 D6 0D BD FB 3E 13 65 49",
  "session id"          : "5C 37 D3 EB 61 FD 6F 42 2F C0 D4 96 F8 24 10 BB 71 36 A4 6D 1E 2B 77 11 7B 3E 63 94 12 D6 AC 09",
  "cipher suite"        : "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384(0xC030)",
  "compression methods" : "00",
  "extensions"          : [
    "extended_master_secret (23)": {
      <empty>
    },
    "renegotiation_info (65,281)": {
      "renegotiated connection": [<no renegotiated connection>]
    }
  ]
}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.740 CST|SSLExtensions.java:173|Ignore unavailable extension: supported_versions
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.740 CST|ServerHello.java:955|Negotiated protocol version: TLSv1.2
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.741 CST|SSLExtensions.java:192|Consumed extension: renegotiation_info
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.741 CST|SSLExtensions.java:173|Ignore unavailable extension: server_name
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.741 CST|SSLExtensions.java:173|Ignore unavailable extension: max_fragment_length
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:173|Ignore unavailable extension: status_request
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:173|Ignore unavailable extension: ec_point_formats
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:173|Ignore unavailable extension: status_request_v2
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:192|Consumed extension: extended_master_secret
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:192|Consumed extension: renegotiation_info
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLSessionImpl.java:215|Session initialized:  Session(1728745716742|TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.742 CST|SSLExtensions.java:207|Ignore unavailable extension: server_name
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:207|Ignore unavailable extension: max_fragment_length
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:207|Ignore unavailable extension: status_request
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:207|Ignore unavailable extension: ec_point_formats
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:207|Ignore unavailable extension: application_layer_protocol_negotiation
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:207|Ignore unavailable extension: status_request_v2
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:215|Ignore impact of unsupported extension: extended_master_secret
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.743 CST|SSLExtensions.java:215|Ignore impact of unsupported extension: renegotiation_info
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.747 CST|CertificateMessage.java:366|Consuming server Certificate handshake message (
"Certificates": [
  "certificate" : {
    "version"            : "v1",
    "serial number"      : "00 96 72 83 A7 9A 62 86 8E",
    "signature algorithm": "SHA512withRSA",
    "issuer"             : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "not before"         : "2024-10-12 17:28:00.000 CST",
    "not  after"         : "2027-07-09 17:28:00.000 CST",
    "subject"            : "CN=server, OU=server, O=server, L=GZ, ST=GD, C=CN",
    "subject public key" : "RSA"}
]
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.762 CST|X509TrustManagerImpl.java:294|Found trusted certificate (
  "certificate" : {
    "version"            : "v1",
    "serial number"      : "00 90 7D F2 D3 D4 58 10 AC",
    "signature algorithm": "SHA512withRSA",
    "issuer"             : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "not before"         : "2024-10-12 17:26:30.000 CST",
    "not  after"         : "2034-10-10 17:26:30.000 CST",
    "subject"            : "CN=root, OU=root, O=cert, L=GZ, ST=GD, C=CN",
    "subject public key" : "RSA"}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.770 CST|ECDHServerKeyExchange.java:531|Consuming ECDH ServerKeyExchange handshake message (
"ECDH ServerKeyExchange": {
  "parameters": {
    "named group": "secp256r1"
    "ecdh public": {
      0000: 04 EC 4B C9 39 79 4D 3C   63 0B FD E2 57 E1 9E 53  ..K.9yM<c...W..S
      0010: D1 18 97 80 11 4B DE F1   C7 87 A4 0D 39 86 C0 24  .....K......9..$
      0020: 8A 02 51 47 34 21 0E C1   62 BB DF CE 10 A2 AB AE  ..QG4!..b.......
      0030: CB 3A 9A 75 53 AF 12 B4   9E 88 CA 9D F3 01 45 45  .:.uS.........EE
      0040: B4                                                 .
    },
  },
  "digital signature":  {
    "signature algorithm": "rsa_pss_rsae_sha256"
    "signature": {
      0000: 7F EF E2 5B 8B 8B D7 AB   FA 59 15 DC DF 9C F7 96  ...[.....Y......
      0010: 95 18 05 64 A1 99 FD 79   D1 AC 32 D1 02 B6 EA 5F  ...d...y..2...._
      0020: 81 10 58 72 2C CD 4D 5C   82 0D 9B BA A4 91 53 4C  ..Xr,.M\......SL
      0030: AD 08 71 A8 E4 95 A1 B7   94 93 A9 61 60 01 F3 0F  ..q........a`...
      0040: F8 B0 9A D4 FB 72 4E 7E   85 42 20 66 09 1A 3F 0C  .....rN..B f..?.
      0050: 24 DD 21 55 D0 BF 78 32   F3 D6 76 22 F0 54 C4 A1  $.!U..x2..v".T..
      0060: 22 8A 5B 27 4D 60 82 6B   F2 73 8A A8 59 15 23 8B  ".['M`.k.s..Y.#.
      0070: 27 CF E1 7F 5A 36 75 C6   68 CF A2 74 AE 16 4D 52  '...Z6u.h..t..MR
      0080: 5E A2 EB F4 7E 33 4E 6D   70 22 5D 7E 33 5F 4B F3  ^....3Nmp"].3_K.
      0090: BC 9C 68 6B F6 64 CA 55   7C 0D F2 F9 E8 9C 9C A8  ..hk.d.U........
      00A0: B0 74 51 35 C0 4F E6 30   C0 96 72 45 91 E6 ED 6E  .tQ5.O.0..rE...n
      00B0: 09 7D 0A 76 BD 90 E8 23   35 2F BF 3E 89 06 EC 33  ...v...#5/.>...3
      00C0: 74 A2 71 8C EB 9D 87 E5   F7 9C 9A 25 C5 E4 C4 1E  t.q........%....
      00D0: 95 17 A0 3E 43 B6 99 47   41 64 AF 5B 46 73 01 7E  ...>C..GAd.[Fs..
      00E0: 3C D1 A9 EB 7A 27 D4 4E   E4 B5 D6 61 C7 F4 30 4E  <...z'.N...a..0N
      00F0: 9F FF 23 45 B5 E3 50 AE   55 A4 BF 49 A5 A9 0C 9E  ..#E..P.U..I....
      0100: 0A 9E 31 10 3E D6 7F C4   70 43 6B 12 5B 4F 5A 44  ..1.>...pCk.[OZD
      0110: E4 75 0F 26 3E 70 F6 BF   06 8D 81 CB AB E4 97 99  .u.&>p..........
      0120: 70 72 C7 7A 63 20 A4 54   02 E4 03 AF 03 46 8C 1F  pr.zc .T.....F..
      0130: CA CA AC C1 81 E5 87 B8   DB 57 FE 02 8A 43 D4 ED  .........W...C..
      0140: 7A 63 DD 0F 8C D3 97 27   B2 67 2B 77 7C 3F B9 C2  zc.....'.g+w.?..
      0150: 78 AD CF CA DD A3 92 EC   06 59 81 03 0A C8 61 6C  x........Y....al
      0160: C0 67 1D F2 0F 0D C4 5A   7C 91 86 8F BF A0 89 22  .g.....Z......."
      0170: 07 E9 A4 46 8F 3D F4 82   09 B2 94 15 FE 27 D6 B6  ...F.=.......'..
      0180: B0 87 57 87 04 13 B5 F5   65 9A 42 D4 5B 08 D3 E1  ..W.....e.B.[...
      0190: 74 8E FB D4 62 3A E5 D3   4D 2C 2E 67 88 90 B0 22  t...b:..M,.g..."
      01A0: 47 D7 28 D0 DD 02 4A B6   54 31 0F 66 97 C6 40 9A  G.(...J.T1.f..@.
      01B0: 43 4D E9 F0 D5 99 1E 50   28 D6 37 7E 98 D2 6C C8  CM.....P(.7...l.
      01C0: 9C B7 E1 55 3A A4 53 72   D4 A5 E6 7C 3C 87 D8 64  ...U:.Sr....<..d
      01D0: D2 37 BD 87 6C EA F0 48   77 A6 0A DF BF FF 4E 6F  .7..l..Hw.....No
      01E0: 33 89 AE E8 04 A5 EA 10   62 AE 2A F0 9A 7F F5 F4  3.......b.*.....
      01F0: 70 2F 8C AC 96 21 E7 82   4E AE A2 0B 9A 48 DC 64  p/...!..N....H.d
    },
  }
}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.771 CST|CertificateRequest.java:692|Consuming CertificateRequest handshake message (
"CertificateRequest": {
  "certificate types": [ecdsa_sign, rsa_sign, dss_sign]
  "supported signature algorithms": [ecdsa_secp256r1_sha256, ecdsa_secp384r1_sha384, ecdsa_secp521r1_sha512, rsa_pss_rsae_sha256, rsa_pss_rsae_sha384, rsa_pss_rsae_sha512, rsa_pss_pss_sha256, rsa_pss_pss_sha384, rsa_pss_pss_sha512, rsa_pkcs1_sha256, rsa_pkcs1_sha384, rsa_pkcs1_sha512, dsa_sha256, ecdsa_sha224, rsa_sha224, dsa_sha224, ecdsa_sha1, rsa_pkcs1_sha1, dsa_sha1]
  "certificate authorities": [CN=server, OU=server, O=server, L=GZ, ST=GD, C=CN]
}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.772 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.772 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.773 CST|X509Authentication.java:215|No X.509 cert selected for EC
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.773 CST|CertificateRequest.java:809|Unavailable authentication scheme: ecdsa_secp256r1_sha256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.773 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.773 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.773 CST|X509Authentication.java:215|No X.509 cert selected for EC
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.774 CST|CertificateRequest.java:809|Unavailable authentication scheme: ecdsa_secp384r1_sha384
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.774 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.774 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.774 CST|X509Authentication.java:215|No X.509 cert selected for EC
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.774 CST|CertificateRequest.java:809|Unavailable authentication scheme: ecdsa_secp521r1_sha512
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.775 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.776 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.776 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.776 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pss_rsae_sha256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pss_rsae_sha384
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.777 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pss_rsae_sha512
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|CertificateRequest.java:796|Unsupported authentication scheme: rsa_pss_pss_sha256
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|CertificateRequest.java:753|Unsupported authentication scheme: rsa_pss_pss_sha384
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|CertificateRequest.java:753|Unsupported authentication scheme: rsa_pss_pss_sha512
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.778 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pkcs1_sha256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pkcs1_sha384
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pkcs1_sha512
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.779 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|X509Authentication.java:215|No X.509 cert selected for DSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|CertificateRequest.java:809|Unavailable authentication scheme: dsa_sha256
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|X509Authentication.java:215|No X.509 cert selected for EC
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.780 CST|CertificateRequest.java:809|Unavailable authentication scheme: ecdsa_sha224
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_sha224
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.781 CST|X509Authentication.java:215|No X.509 cert selected for DSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|CertificateRequest.java:809|Unavailable authentication scheme: dsa_sha224
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|X509Authentication.java:215|No X.509 cert selected for EC
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|CertificateRequest.java:809|Unavailable authentication scheme: ecdsa_sha1
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|X509KeyManagerImpl.java:783|Ignore alias client: issuers do not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.782 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|X509Authentication.java:215|No X.509 cert selected for RSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|CertificateRequest.java:809|Unavailable authentication scheme: rsa_pkcs1_sha1
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|X509KeyManagerImpl.java:766|Ignore alias client: key algorithm does not match
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|X509KeyManagerImpl.java:404|KeyMgr: no matching key found
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|X509Authentication.java:215|No X.509 cert selected for DSA
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|CertificateRequest.java:809|Unavailable authentication scheme: dsa_sha1
javax.net.ssl|WARNING|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.783 CST|CertificateRequest.java:819|No available authentication scheme
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.784 CST|ServerHelloDone.java:151|Consuming ServerHelloDone handshake message (
<empty>
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.784 CST|CertificateMessage.java:299|No X.509 certificate for client authentication, use empty Certificate message instead
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.784 CST|CertificateMessage.java:330|Produced client Certificate handshake message ("Certificates": <empty list>
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.801 CST|ECDHClientKeyExchange.java:398|Produced ECDHE ClientKeyExchange handshake message (
"ECDH ClientKeyExchange": {
  "ecdh public": {
    0000: 04 F0 F3 A0 06 2C C0 56   42 CE A8 1C 3F 91 36 2C  .....,.VB...?.6,
    0010: 3C 35 C8 AE 56 D8 93 28   2F 00 4E 3D D4 26 3A BE  <5..V..(/.N=.&:.
    0020: 82 37 2B 48 EC 3D C0 BA   82 9B EB 77 E1 5F 22 B0  .7+H.=.....w._".
    0030: DC 12 80 2C EC 06 EB 09   55 54 EA A5 D3 7D 71 BD  ...,....UT....q.
    0040: 12                                                 .
  },
}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.817 CST|ChangeCipherSpec.java:115|Produced ChangeCipherSpec message
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.817 CST|Finished.java:396|Produced client Finished handshake message (
"Finished": {
  "verify data": {
    0000: 42 06 3D DB 55 ED 0B 33   E4 A5 05 CF 
  }'}
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.817 CST|SSLEngineOutputRecord.java:505|WRITE: TLS12 handshake, length = 77
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.818 CST|SSLEngineOutputRecord.java:523|Raw write (
  0000: 16 03 03 00 4D 0B 00 00   03 00 00 00 10 00 00 42  ....M..........B
  0010: 41 04 F0 F3 A0 06 2C C0   56 42 CE A8 1C 3F 91 36  A.....,.VB...?.6
  0020: 2C 3C 35 C8 AE 56 D8 93   28 2F 00 4E 3D D4 26 3A  ,<5..V..(/.N=.&:
  0030: BE 82 37 2B 48 EC 3D C0   BA 82 9B EB 77 E1 5F 22  ..7+H.=.....w._"
  0040: B0 DC 12 80 2C EC 06 EB   09 55 54 EA A5 D3 7D 71  ....,....UT....q
  0050: BD 12                                              ..
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.818 CST|SSLEngineOutputRecord.java:505|WRITE: TLS12 change_cipher_spec, length = 1
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.818 CST|SSLEngineOutputRecord.java:523|Raw write (
  0000: 14 03 03 00 01 01                                  ......
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.818 CST|SSLEngineOutputRecord.java:505|WRITE: TLS12 handshake, length = 16
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.847 CST|SSLCipher.java:1720|Plaintext before ENCRYPTION (
  0000: 14 00 00 0C 42 06 3D DB   55 ED 0B 33 E4 A5 05 CF  ....B.=.U..3....
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.847 CST|SSLEngineOutputRecord.java:523|Raw write (
  0000: 16 03 03 00 28 00 00 00   00 00 00 00 00 94 3E 43  ....(.........>C
  0010: 70 A3 AC DA F2 5F 24 94   56 AC AD F9 C5 61 34 F8  p...._$.V....a4.
  0020: 01 48 AA 12 49 95 43 40   3B F3 F4 23 75           .H..I.C@;..#u
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.854 CST|SSLEngineInputRecord.java:177|Raw read (
  0000: 15 03 03 00 02 02 2A                               ......*
)
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.854 CST|SSLEngineInputRecord.java:214|READ: TLSv1.2 alert, length = 2
javax.net.ssl|FINE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.855 CST|Alert.java:238|Received alert message (
"Alert": {
  "level"      : "fatal",
  "description": "bad_certificate"
}
)
javax.net.ssl|SEVERE|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.855 CST|TransportContext.java:347|Fatal (BAD_CERTIFICATE): Received fatal alert: bad_certificate (
"throwable" : {
  javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
        at sun.security.ssl.Alert.createSSLException(Alert.java:131)
        at sun.security.ssl.Alert.createSSLException(Alert.java:117)
        at sun.security.ssl.TransportContext.fatal(TransportContext.java:342)
        at sun.security.ssl.Alert$AlertConsumer.consume(Alert.java:293)
        at sun.security.ssl.TransportContext.dispatch(TransportContext.java:185)
        at sun.security.ssl.SSLTransport.decode(SSLTransport.java:156)
        at sun.security.ssl.SSLEngineImpl.decode(SSLEngineImpl.java:588)
        at sun.security.ssl.SSLEngineImpl.readRecord(SSLEngineImpl.java:544)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:411)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:390)
        at javax.net.ssl.SSLEngine.unwrap(SSLEngine.java:629)
        at io.netty.handler.ssl.SslHandler$SslEngineType$3.unwrap(SslHandler.java:310)
        at io.netty.handler.ssl.SslHandler.unwrap(SslHandler.java:1445)
        at io.netty.handler.ssl.SslHandler.decodeJdkCompatible(SslHandler.java:1338)
        at io.netty.handler.ssl.SslHandler.decode(SslHandler.java:1387)
        at io.netty.handler.codec.ByteToMessageDecoder.decodeRemovalReentryProtection(ByteToMessageDecoder.java:529)
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:468)
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
        at java.lang.Thread.run(Thread.java:750)}

)
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.856 CST|SSLSessionImpl.java:805|Invalidated session:  Session(1728745716234|SSL_NULL_WITH_NULL_NULL)
javax.net.ssl|ALL|0E|nioEventLoopGroup-2-1|2024-10-12 23:08:36.856 CST|SSLSessionImpl.java:805|Invalidated session:  Session(1728745716742|TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384)
2024-10-12 23:08:36,863 [myid:] - ERROR [nioEventLoopGroup-2-1:o.a.z.ClientCnxnSocketNetty$ZKClientHandler@531] - Unexpected throwable
io.netty.handler.codec.DecoderException: javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
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
        at java.lang.Thread.run(Thread.java:750)
Caused by: javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
        at sun.security.ssl.Alert.createSSLException(Alert.java:131)
        at sun.security.ssl.Alert.createSSLException(Alert.java:117)
        at sun.security.ssl.TransportContext.fatal(TransportContext.java:342)
        at sun.security.ssl.Alert$AlertConsumer.consume(Alert.java:293)
        at sun.security.ssl.TransportContext.dispatch(TransportContext.java:185)
        at sun.security.ssl.SSLTransport.decode(SSLTransport.java:156)
        at sun.security.ssl.SSLEngineImpl.decode(SSLEngineImpl.java:588)
        at sun.security.ssl.SSLEngineImpl.readRecord(SSLEngineImpl.java:544)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:411)
        at sun.security.ssl.SSLEngineImpl.unwrap(SSLEngineImpl.java:390)
        at javax.net.ssl.SSLEngine.unwrap(SSLEngine.java:629)
        at io.netty.handler.ssl.SslHandler$SslEngineType$3.unwrap(SslHandler.java:310)
        at io.netty.handler.ssl.SslHandler.unwrap(SslHandler.java:1445)
        at io.netty.handler.ssl.SslHandler.decodeJdkCompatible(SslHandler.java:1338)
        at io.netty.handler.ssl.SslHandler.decode(SslHandler.java:1387)
        at io.netty.handler.codec.ByteToMessageDecoder.decodeRemovalReentryProtection(ByteToMessageDecoder.java:529)
        at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:468)
        ... 17 common frames omitted

```

