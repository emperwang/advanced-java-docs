---
tags:
  - production
  - exception
---


最近在使用Jenkins来打包stash仓库中的源码时, 发现Jenkins老是报错.

```
#  错误example
java.nio.FileSystemException:........Filename too long

```

仔细检查过文件名并没有超出文件系统的规定(255), 打开Jenkins builde job中的workspace, 发现出错的文件找不到, Jenkins对于symbolic link文件默认是不显示的.
通过git检查文件, 发现repository中的中对应的文件类型确实是 symblic link,  删除重建文件后,  问题得到解决.

```
git ls-files -s path/file
```




> git参考文件
[[1-如何检查git中的文件类型]]


