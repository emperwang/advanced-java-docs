---
tags:
  - Golang
  - env
---
通过 `go env` 可以看到go环境变量的一些设置.  其中比较重要的如: `GOROOT  GOPATH GOPROXY`等.

在Linux环境中, 一个容易出现的事故点
> 在.bashrc中配置了 GOROOT GOPATH GOPROXY, 但是在后续进行package 下载, 以及使用私有仓库时,  发现配置的 GOPROXY以及GOPATH并没有生效.  同时检查环境变量,  发现设置的值是正确的.  那么问题在哪? 

通过`go env`查看时,  可以发现对应的变量并没有更改.  也就是说设置到 `.bashrc`中的值并没有生效,  仍然使用的是  `go env`中的配置.

针对此种情况, 通过更新 go env中的变量才可以。
```shell
go env -w GOPRXY=private_repo

go env -w GOPATH=realpath

go env -W GOROOT=install_path
```










