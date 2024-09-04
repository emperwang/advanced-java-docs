---
tags:
  - https
  - SSL/TLS
---

### 1. how client verify server certificate ?  (客户端如何校验服务器端证书)



### 2. Do server need send certificate chan to client ? need or no need, explain the reason.  (服务器端需要发送证书链到客户端吗?  请接释原因)

### 3. when server send certificate chan to client, which need include CA certificate as well?   (当服务器发送证书链时,  需要发送CA证书吗? )

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