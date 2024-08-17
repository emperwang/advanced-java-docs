---
tags:
  - linux
  - Golang
  - install
---
linux环境 GO的安装。
## binary install
在linux上安装go
```shell
wget https://mirrors.aliyun.com/golang/go1.23rc1.linux-amd64.tar.gz

tar -xzvf go1.23rc1.linux-amd64.tar.gz

# 配置路径到环境变量中

```

> 一般请勿直接使用 apt/yum 安装, 比较慢, 安且安装路径以及版本不好维护.


## proxy 修改

当使用`go install xxx` 后者 `go get xxx` 会使用到GOPROXY (go env 可查看.)
不过国内的话使用下面的配置:

```
# default: GOPROXY='https://proxy.golang.org,direct'
go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
go env -w GOPROXY="https://goproxy.cn,direct"
```



