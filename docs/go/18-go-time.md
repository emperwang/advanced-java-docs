---
tags:
  - Golang
  - time
  - format
---



```go
# 当使用go来获取时间字符串时 format layout 必须使用2006-01-02 15:04:05, 如果使用其他时间, 则会出错. 

createTime := time.Now().Format("2006-01-02 15:04:05")

```

此格式类似是 code中hardcode的, 没有特别原因