# pg 使用中的错误

## 1. 非法字符

异常信息：

```shell
org.postgresql.util.PSQLException: ERROR: invalid byte sequence for encoding "UTF-8": 0x00
```



```shell
# 此异常大意时: 插入数据时有非法字符:0x00. 
# 根据Stack Overflow中查询, postgresql不能插入null字符.

# 如果是java程序,修改如下: str.replaceAll("\u0000","");
# 即把非法字符剔除就好
```





