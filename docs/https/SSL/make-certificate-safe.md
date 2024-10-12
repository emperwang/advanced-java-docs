---
tags:
  - openssl
  - certificate
  - CA
---

[[make-certificate]] 通过此方法生成的证书, 默认使用了SHA1 算法, 那么针对生成的证书, 使用新的算法来签名.

方法:
1. 保留原来所有的key 以及 req文件
2. 删除生成的所有 certificate文件
3. 使用新的算法来签名生成新的证书

```shell
openssl x509 -req  -days  3650  -sha512  -extensions v3_ca -signkey root.key -in root.csr  -out  root.crt
```

```shell
openssl x509  -req  -days 1000 -sha512 -extensions v3_req  -CA root.crt  -CAkey root.key -CAserial root.srl -CAcreateserial -in server.csr  -out  server.crt


openssl x509  -req -days 1000 -sha512  -extensions -v3_req -CA root.crt -CAkey root.key  -CAserial root.srl  -CAcreateserial -in  client.csr  -out client.crt
```



