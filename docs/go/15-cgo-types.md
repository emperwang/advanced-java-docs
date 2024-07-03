---
tags:
  - CGO
  - Golang
---
通过[[14-cgo]] 了解到go如何调用C,  但是在调用时的类型需要做一些特殊处理.
通过 `import "C"` 导入C后, 通过 C可以调用C的类型.

```
// C 类型
C.int
C.char
*C.char   --> string
C.CString --> *C.char --> char*


```






