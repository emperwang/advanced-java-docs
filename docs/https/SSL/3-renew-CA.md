---
tags:
  - SSL/TLS
  - renew
  - CA
---
```shell
## make root CA
openssl req -new -X509  -keyout root.key -out oriroot.pem -days 3650 -nodes -subj "/CN=CA-dev\/emailAddress=admin@tit.com/C=CN/ST=GD/L=GZ/O=xiaomi/OU=xiaomiUnit"

## generate child cert
openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -out cert.csr  -subj "/CN=client-dev\/emailAddress=admin@tit.com/C=CN/ST=GD/L=GZ/O=xiaomi/OU=xiaomiUnit"

## sign the child cert
openssl x509 -req -in cert.csr -CA oriroot.pem -CAkey root.key -CAcreateserial -out cert.pem

## verify client cert
openssl verify -CAfile oriroot.pem -verbose cert.pem
```

![](./images/4-verify-cert1.png)

> 如果使用配置文件来生成证书.  配置文件的内容参考
> /etc/pki/tls/openssl.cnf

创建新的CA证书.
```shell
openssl req -new -key root.key -out newcsr.csr

## 这里易错点, subj 需要和原 CA一致, 否则 client的 cert找不到 CA 证书
openssl req -new -key root.key -out newcsr.csr  -subj "/CN=CA-dev\/emailAddress=admin@tit.com/C=CN/ST=GD/L=GZ/O=xiaomi/OU=xiaomiUnit"
openssl x509 -req -days 3650 -in newcsr.csr -signkey root.key -out newroot.pem 

## verify client cert with new CA
openssl verify -CAfile newroot.pem -verbose cert.pem
```

找不到CA证书的error
![](./images/5-cant-find-ca.png)


>reference
[renew CA](https://serverfault.com/questions/306345/certification-authority-root-certificate-expiry-and-renewal)
