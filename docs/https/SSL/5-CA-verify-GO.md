---
tags:
  - certificate
  - ssl-verify
  - SSL/TLS
---

## 问题场景:
使用Go 编写的客户端程序, 访问一个内部的https 服务来获取数据信息.   服务使用的证书是内部的CA签名的.  
Go 客户端没有指定CA证书,  全部使用默认的.

## 问题现象:
报错:  不能校验服务器端的证书


## 问题解析:
Go客户端既没有加载 服务器端的证书, 也没有加载 签名服务器证书的 CA证书, 那么 不能校验对端证书, 也属正常.


## 解决方式

方法一:  信任对方证书
```go
func HttpClientWithCACerts() *http.Client {
    tr := &http.Transport{
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: true,   // 信任对方证书
        },
    }
    client := &http.Client{
        Timeout:   50 * time.Second,
        Transport: tr,
    }
    return client
}
```


方法二: 加载签名服务器证书的CA证书
```go
func HttpClientWithCACerts() *http.Client {
	// 加载 签名服务器的 CA根证书
    CAs := LoadCert(certPath)
    tr := &http.Transport{
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,
            RootCAs:            CAs,  // 使用加载的CA 证书
 // 对应证书中的 DNS name; 当对端证书的DNS name和 访问的URL中的hostname不一致时,可以通过设置此 serverName来通过验证
            ServerName:         "server-name", 
        },
    }
    client := &http.Client{
        Timeout:   50 * time.Second,
        Transport: tr,
    }
    return client
}
```


方法三: 加载服务器证书
```go
func HttpClientWithCACerts() *http.Client {
// 加载服务器证书
    CAs := LoadCert(certPath)
    tr := &http.Transport{
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,
            RootCAs:            CAs, // 使用加载的服务器证书
            ServerName:         "", // 对应证书中的 DNS name; 当对端证书的DNS name和 访问的URL中的hostname不一致时,可以通过设置此 serverName来通过验证
        },
    }
    client := &http.Client{
        Timeout:   50 * time.Second,
        Transport: tr,
    }
    return client
}
```





