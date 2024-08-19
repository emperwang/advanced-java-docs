---
tags:
  - Golang
  - debug
  - dlv
---

## install

```shell
go install github.com/go-delve/delve/cmd/dlv@latest

go install github.com/go-delve/delve/cmd/dlv@v1.21.1
```




## debug
```shell
dlv exec ./mydocker --  run --name bird --ti  busybox  /bin/sh


## -- 后为program的参数
```