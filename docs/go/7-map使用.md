# go map 容器使用

## map的初始化
```go
// 声明, 但未初始化
var mapname map[keytype] valuetype

mapname := make(map[keyType] valueType)

mapname := map[keyType] valueType {}
```

## map的基本操作
```go
mapname := make(map[String] String)
// 增
mapname[key1] = value1
// 删
delete(mapname, key1)

// 改
mapname[key1] = value2

// 查
mapname[key1]

```

