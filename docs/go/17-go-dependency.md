---
tags:
  - Golang
  - mod
  - dependency
  - go-vendor
---

环境:
```
# go version
go version go1.22.5 linux/amd64
```


简述以下go的依赖管理.
GOPATH:  指的是 通过 go get 等下载依赖时, 默认的下载路径
GOROOT:  指的是 go的安装路径
go get:   下载依赖
go install:  安装依赖
go mod vendor : 把 项目中的依赖拷贝到项目 vendor目录下



使用顺序:
```shell
go mod init

go get xxx
go get xxx

go mod vendor

```


