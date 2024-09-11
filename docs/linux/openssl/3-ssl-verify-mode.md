---
tags:
  - SSL
  - ssl-verify
---

```shell
- SSL_VERIFY_NONE
    
    **Server mode:** the server will not send a client certificate request to the client, so the client will not send a certificate.
    
    **Client mode:** if not using an anonymous cipher (by default disabled), the server will send a certificate which will be checked. The result of the certificate verification process can be checked after the TLS/SSL handshake using the [SSL_get_verify_result(3)](https://docs.openssl.org/3.2/man3/SSL_get_verify_result/) function. The handshake will be continued regardless of the verification result.
    
- SSL_VERIFY_PEER
    
    **Server mode:** the server sends a client certificate request to the client. The certificate returned (if any) is checked. If the verification process fails, the TLS/SSL handshake is immediately terminated with an alert message containing the reason for the verification failure. The behaviour can be controlled by the additional SSL_VERIFY_FAIL_IF_NO_PEER_CERT, SSL_VERIFY_CLIENT_ONCE and SSL_VERIFY_POST_HANDSHAKE flags.
    
    **Client mode:** the server certificate is verified. If the verification process fails, the TLS/SSL handshake is immediately terminated with an alert message containing the reason for the verification failure. If no server certificate is sent, because an anonymous cipher is used, SSL_VERIFY_PEER is ignored.
    
- SSL_VERIFY_FAIL_IF_NO_PEER_CERT
    
    **Server mode:** if the client did not return a certificate, the TLS/SSL handshake is immediately terminated with a "handshake failure" alert. This flag must be used together with SSL_VERIFY_PEER.
    
    **Client mode:** ignored (see BUGS)
    
- SSL_VERIFY_CLIENT_ONCE
    
    **Server mode:** only request a client certificate once during the connection. Do not ask for a client certificate again during renegotiation or post-authentication if a certificate was requested during the initial handshake. This flag must be used together with SSL_VERIFY_PEER.
    
    **Client mode:** ignored (see BUGS)
    
- SSL_VERIFY_POST_HANDSHAKE
    
    **Server mode:** the server will not send a client certificate request during the initial handshake, but will send the request via SSL_verify_client_post_handshake(). This allows the SSL_CTX or SSL to be configured for post-handshake peer verification before the handshake occurs. This flag must be used together with SSL_VERIFY_PEER. TLSv1.3 only; no effect on pre-TLSv1.3 connections.
    
    **Client mode:** ignored (see BUGS)
```





> reference

[openssl](https://docs.openssl.org/3.2/man3/SSL_CTX_set_verify/#description)



