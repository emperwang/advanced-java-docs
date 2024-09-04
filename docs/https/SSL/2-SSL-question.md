---
tags:
  - https
  - SSL/TLS
---

### 1. how client verify server certificate ?  (客户端如何校验服务器端证书)
当client 接收到server发送过来的证书后, 会做一下几件事:
1. 读取证书中的 `issuer`, 然后从 trustCertificateList 中找到对应的CA证书
2. 如果没找到,  则直接发送 alert.  
3. 找到CA后, 会用CA中的 公钥 解密证书中的签名. **digital certificate=CSR + encrpted(hash(CSR))**
4. 读取证书中的 CSR (certificate signing  Request), 并根据 证书中`签名算法` 做 hash操作.
5. 如果hash后的值  == 解密后的签名, 那么证书校验通过
6. (optional) DNS校验, 即 证书中的DNS域名和 访问的 server的域名一致. 
		
### 2. Do server need send certificate chan to client ? need or no need, explain the reason.  (服务器端需要发送证书链到客户端吗?  请接释原因)
首先说一下, 证书的三种分类.
证书可以简单分为 两种:
`CA 证书`:  用于签发其他 client证书的证书, 称为CA证书, 也成为 根证书
`client certificate`:  有 CA 颁发的 client 证书.
再细分, 就是`CA`还有一种.  
`intermediate CA`: 即有 根证书(root CA) 签发的 中间证书.  中间证书也可用于签发 client 证书.

> 从下图可以看到,  root CA 是属于自签名的证书
![](./images/2-root-ca.png)

然后再接释一下, 什么是证书链.
> 证书链:  就是证书文件中, 不光包含了client certificate, 同时包含了对其签名的 intermediate certificate.  也可以包含 root CA.

下面是一个浏览器展示的证书链. 既包含了root CA,  intermediate CA 以及 End-User certificate.
![](./images/1-ssl-level.png)

```shell
## 证书文件中(PEM) 的证书链, 格式和下面类似
## 第一个为 客户端证书
1.end-user-certificate  issued to: baidu.com - issued by: Authority1
2.Authority1-cert      issued to: Authority1 - issued by: Authority2
3.Authority2-cert      issued to: Authority2 - issued by: Authority3
4.Authority3-cert     issued to: Authority3 - issued by: Authority4
5.Authority4-cert     issued to: Authority4 - issued by: root CA
```
那么回到正题, server会发送证书链吗?
如果server的证书由 intermediate CA 签名,  那么就会发送证书链到client.

为什么呢?
因为签名的 intermediate CA有可能没有存储在client 端,  那为了校验成功, 就会进行证书链的校验, 同 **问题4 证书链校验**.   如果不发送证书链的话, 那么在 client 端 trustCertificateList中找不到 对应的CA证书,  校验会失败.

### 3. when server send certificate chan to client, which need include root CA certificate as well?   (当服务器发送证书链时,  需要发送root CA证书吗? )
了解了为什么发送证书链,  就可以判断,  其实不发送root CA也没有关系.  
1.  不发送root CA.  那么通过证书链中的 intermediate CA 也可以在 client端找到签名的根证书,  也能保证handshake 成功.
2. 发送root CA. 因为root CA是 自签名证书, 那么发送root CA, 也能使 client找到对应的CA证书 来进行 handshake.
### 4. how client verify server certificate chan? (客户端如何校验服务器端的证书链?)




### 5. when server send a certificate chan to client, how client knows which one is server certifcate ? (服务器发送了证书链到客户端, 那么客户端如何才能知道哪个证书是服务器证书?  )

### 6. As we know, client have many CA certificates, when client begin verify server certificate, how client knows which CA certificate to user ? ( 我们都知道, 客户端有很多的CA证书,  那么当client需要对 服务器证书校验时,  如何知道要使用那个CA 证书?)


### 7. what need to do when CA certificate expires?   (如果CA证书过期了, 那么怎么做?)









> reference

[CA expires](https://serverfault.com/questions/306345/certification-authority-root-certificate-expiry-and-renewal)
[server send CA certifcate? ](https://security.stackexchange.com/questions/93157/in-ssl-server-handshake-does-server-also-send-ca-certificate)
[how client verify server certificate](https://stackoverflow.com/questions/35374491/how-does-the-client-verify-servers-certificate-in-ssl)
[client verify server certificate](https://docs.oracle.com/cd/E19693-01/819-0997/aakhb/index.html)
[client verify server certificates](https://web.archive.org/web/20230810153801/https://docs.oracle.com/cd/E19693-01/819-0997/aakhb/index.html)
[which certifcate to select when client have multiple cert](https://stackoverflow.com/questions/58590849/which-ssl-certificate-will-be-selected-if-client-has-multiple-certificates-in-ke)