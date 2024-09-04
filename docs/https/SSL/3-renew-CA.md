---
tags:
  - SSL/TLS
  - renew
  - CA
---
```shell
## make root CA
openssl req -new -X509  -keyout root.key -out oriroot.pem -days 3650 -nodes

## generate child cert
openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -out cert.csr

## sign the child cert
openssl x509 -req cert.csr -CA oriroot.pem -CAkey root.key -create_serial -out cert.pem

## verify client cert
openssl verify -CAfile oriroot.pem -verbose cert.pem
```


创建新的CA证书.
```shell
openssl req -new -key root.key -out newcsr.csr
openssl x509 -req -days 3650 -in newcsr.csr -signkey root.key -out newroot.pem 

## verify client cert with new CA
openssl verify -CAfile newroot.pem -verbose cert.pem
```



>reference
[renew CA](https://serverfault.com/questions/306345/certification-authority-root-certificate-expiry-and-renewal)
