# 证书的创建

## root证书

1.私钥生成

```shell
> openssl genrsa  -des3 -out root.key
```

![](../image/https/certificate/openssl-genrsa.png)

2.证书请求生成

```shell
> openssl req  -new  -key  root.key  -out root.csr

## 通过参数指定 subject
> openssl req -new -key cert.key -out cert.csr  -subj "/CN=service-dev\/emailAddress=admin@tit.com/C=CN/ST=GD/L=GZ/O=xiaomi/OU=xiaomiUnit"

## 如果通过配置文件来生成证书.  请参考文件 /etc/pki/tls/openssl.cnf
```

![](../image/https/certificate/openssl-req.png)

**注意：在httpclient中有一个关于hostName的验证, 对应证书中的 DNS

3.证书生成

```shell
> openssl x509  -req  -days  3650  -sha1  -extensions v3_ca -sigkey root.key -in root.csr  -out  root.crt
```

![](../image/https/certificate/openssl-crt.png)

4.查看证书内容
```shell
> openssl x509  -in  root.crt  -text
```

![](../image/https/certificate/openssl-text.png)

5.pem格式的证书

```shell
> cat  root.key  root.crt  > root.pem
```



## server端证书

1.私钥生成
```shell
> openssl genrsa -des3 -out server.key 2048

> openssl rsa  -in  server.key  -out  server2.key
```

![](../image/https/certificate/server-key.png)

![](../image/https/certificate/server2-key.png)

2.证书请求生成

```shell
> openssl  req  -new  -key  server2.key  -out  server.csr
```

![](../image/https/certificate/server-csr.png)
3.证书生成

```shell
> openssl x509  -req  -days 1000 -sha1 -extensions v3_req  -CA root.crt  -CAkey root.key -CAserial root.srl -CAcreateserial -in server.csr  -out  server.crt

# 生成root.srl文件，就是证书的序列号
```

![](../image/https/certificate/server-crt.png)
4.导出证书为pkcs12格式

```shell
> openssl pkcs12  -export  -out  server.p12  -in server.crt  -inkey server2.key  -name name1
# -name 别名
```

![](../image/https/certificate/server-p12.png)

5.查看pkcs12格式的证书内容

```shell
[root@name1 server]# openssl pkcs12 -info -in server.p12
Enter Import Password:
MAC Iteration 2048
MAC verified OK
PKCS7 Encrypted data: pbeWithSHA1And40BitRC2-CBC, Iteration 2048
Certificate bag
Bag Attributes
    friendlyName: name1
    localKeyID: 73 AB 33 C5 2B 8F 72 42 D0 91 18 4C A3 DE DD 3D 5F 37 48 8E
subject=/C=CN/ST=GD/L=GD/O=er/OU=er/CN=name1/emailAddress=544094478@qq.com
issuer=/C=CN/ST=GD/L=GD/O=er/OU=er/CN=name1/emailAddress=544094478@qq.com
-----BEGIN CERTIFICATE-----
MIIC3zCCAkgCCQC7mVfb62LFrDANBgkqhkiG9w0BAQUFADByMQswCQYDVQQGEwJD
TjELMAkGA1UECAwCR0QxCzAJBgNVBAcMAkdEMQswCQYDVQQKDAJlcjELMAkGA1UE
CwwCZXIxDjAMBgNVBAMMBW5hbWUxMR8wHQYJKoZIhvcNAQkBFhA1NDQwOTQ0NzhA
cXEuY29tMB4XDTE5MDkwMjEyMTAxNloXDTIyMDUyOTEyMTAxNlowcjELMAkGA1UE
BhMCQ04xCzAJBgNVBAgMAkdEMQswCQYDVQQHDAJHRDELMAkGA1UECgwCZXIxCzAJ
BgNVBAsMAmVyMQ4wDAYDVQQDDAVuYW1lMTEfMB0GCSqGSIb3DQEJARYQNTQ0MDk0
NDc4QHFxLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM1A3tPe
/Jlkh/EQzOG8GfApJtnBHoiSaoN/FMUCTzub55KR3bQz4yXK9BvClI0uGtzLnABz
MSMBsopIZS+y9BKuJe2Xcd+MP5WkR775xRd2QJHMRkJmE/ViVJs26enlvTX5rtzR
EnXjcSo62I5/p6A6LAjVjTy2LZUFXvSDSwfuMmvz8c7oJJ3tKDnBeP4uJpdRRBEF
OFidyo2bJsXfYKLy+LaPmeOcLcsURayb4M+JLJnHJXReb983az3T67IdGYo93MF+
OvmQeUwi4MRDvuGDjkAEvb7g89g2bESc5SFcT0Zz1EtlpuFIpkxlLMw7QTwzy/TX
EHlDldbqaGfxlIMCAwEAATANBgkqhkiG9w0BAQUFAAOBgQCjrINMjl1gyF8U/vPN
ijA1KA6k39vzFKFKJvDy5gVobeCufMfGDnKnkhc9OPqBmp3jp8MhJ+j9qDzYPupS
t2E6tPMW5jIzOfPyBdhxRLP65Q4brMQs3tMxH2oc7fV8Z2nsb2JuhORXCfkyzedt
qPqeBRMReBJNXwW8bccXobMlIw==
-----END CERTIFICATE-----
PKCS7 Data
Shrouded Keybag: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
Bag Attributes
    friendlyName: name1
    localKeyID: 73 AB 33 C5 2B 8F 72 42 D0 91 18 4C A3 DE DD 3D 5F 37 48 8E
Key Attributes: <No Attributes>
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFDjBABgkqhkiG9w0BBQ0wMzAbBgkqhkiG9w0BBQwwDgQIEWuV88jffiECAggA
MBQGCCqGSIb3DQMHBAggqRDkcpXXmgSCBMjXpO7tnKOq5HClbp9nBvHFCdZsKxre
PWIpXLHVudzOWIdW2ePUq31dzcwGiBIuyEjGQsB3UB/Amn/8pZpWC2p0tvWdk1tz
Xapg+EY3znwpKX6QcC8LNnfbsuE4DlCzVk4vD6A+DurqGfMz1aB6ZeZHax6PsIkr
Qhk1E1xTJ0SUyOf87ugIWdGasymgmvxy56w3VctZdUjdAMHU8ptlBzFZ4wg4kgz/
RXjk1uHwgANdEmGdLSB4uvdF3CIXQleohtgqV1pUzzet0EttZ6jbRkzLgB5HaFUH
ubpa1IIHm3jatIc0rec3fmMpYWpW/294BIQRWpjFhk+iyiQ/nyocI+W+00CVNstx
x2GXHS+YXUzt8/7ji4HTARGuus1Fv27LD49Dud8aTkFIzSV2yBSO3/CnbRRTKvzh
V42stOHT9kL7eMjdAt9DB8uo/GqiZj4Dwbcbyq0M3C46A38H3g561bquRPremGKz
AhehwTbmJUcJoD86W7xYbf5VQ0xNHdJMz1pZmoIdM07GT0kowJ9rqfdg0R93NC4q
ZncUDNkADrUmWx6HSRIArxC6/vFvK8RgNlk6Zq+7ociJyY5iy5XRy35AQelaQyYr
almpQH+jpszvb8qP6VuUjVDVcYIJfQrzDpm6Zp1ozCk1I/wYnSZj473yW8RqvD/y
WgsD3c7oMKvghaPfNEcaVpkAu6eq84EB7cX0i4K0s558Bd9uEzmOk6l8qMgoVtca
7jW/2ogJ12chG/nGx+ViVYGGDH3/xcc9fKa91qIZbGV5NOxq38S7Zk2fqbWcPrYT
mQ6/U4Jnrndr80dUs4pZUIjTycEAk0WXC6NuxSeqOOn7XqVxExo1plbq65jVHlRR
gya9LNB9GbaDJwA/fkiU6xd8CSlph75vzoAwHAlXnSv5+pyikZUn9Qluzym9frNM
IQ5xSvX3orwGz7/uw+2bMzXATeRzahwNwPKco1YSpwdeV2S7qALJqKH0Uczbk4QK
KrMKolbdRsRWp0J5Gzy+6pBnlCMr1KWNrZR0r0+jt/hZuWeoj2ye2oA3cAGex983
4GmRySie6K4rqNbKlD0Goc07zb3jKakvAEDH14iSDsDbUhjZKsNOVPVSJrZS/cr0
vjbSLcns91shA6xLEzf8tOvUIXgME5cjImPAAjoYXY1tMhO31xn06lk7t7QxufUV
RX6a0TgjZGlgw06mGu7JlhRnD9m4ImPO1LXh8ushAImUztexE3do6MkpZiFHYoSn
aZUM1ydBchKljxOU7jOp2gFPXnEqOm6qDOxOfFcK9n8oaDWyZYGqpf8/gW7tbwHa
42qoDHHU8yb4o9AiT6RUxUz0XcLS7a2Ofo0WvQ9V/p2sYclmZ0W4oEycNq6AlkTL
vDV1RGBnXwF1u3UhRlDDOWX8Setti6c9NdblMSzA+Hln+61v+pR7L0Usb+wZ2nI+
ZUKWdwj00PJsyjYwf5yUURE2CwFZwS5y15LUrhqr4qEwTI9TGYEAzuKXvfTxwLMI
gLJkdb8bNkL5YcAdlB3k7QEhir0oWp7m59QAnRWsd5xbiINwMvtKRPBJWjbJ9Kof
wrBp7GiIW69u4J/jrF6jqpUOwUD5uXSbZtEQ311MkIyOwr2YJRI5QOAxp+I1jI9t
S4g=
-----END ENCRYPTED PRIVATE KEY-----
```

6.pem格式证书

```shell
>  cat  server2.key  server.crt  > server.pem
```

7.证书格式转换JKS

```shell
> keytool -importkeystore -srckeystore server.p12 -destkeystore server.keystore -srcstoretype PKCS12 -deststoretype JKS  -deststorepass 123456  -srcalias name  -destalias name
```

8.查看JKS证书

```shell
> keytool -list -v -keystore server.keystore
```



## client端

1.私钥生成
```shell
> openssl genrsa -des3  -out  client.key 2048
```

![](../image/https/certificate/client-key.png)
2.证书请求生成

```shell
> openssl req -new -key client.key -out client.csr
```

![](../image/https/certificate/client-req.png)
3.证书生成

```shell
> openssl x509  -req -days 1000 -sha1  -extensions -v3_req -CA root.crt -CAkey root.key  -CAserial root.srl  -CAcreateserial -in  client.csr  -out client.crt
```

![](../image/https/certificate/client-crt.png)
4.pkcs12格式证书

```shell
> openssl pkcs12  -export -out client.p12 -in client.crt -inkey client.key -name name1
```

![](../image/https/certificate/client-p12.png)
5.查看pkcs12格式证书

```shell
> openssl pkcs12 -info  -in client.p12
```

6.导入trustKeyStore

```shell
> keytool -import -alias name1 -keystore clientTrust.key  -file root.crt -storepass 123456 
```



## 测试

```shell
> curl --cacert root.pem  --cert server.pem  -tlsv1.2 -X POST -H 'Content-Type:application/json' -i https://ip:port/uri  -d '{"username":"123","pass"}'
```



