---
tags:
  - JVM
  - threaddump
  - issue
  - question
  - java
  - linux
---
功能上线前, 需要做一个整合测试,  即把线上的数据在UAT环境使用更新后的代码运行以下, 并验证处理后的数据和线上的数据一致, 以此保证新增功能对现有功能无影响.

数据流如下:

[[1-测试数据流]]

进程开始时，进程正常启动并且没有报错， 不过在测试过程中，消息始终发送不到MQ.  排查方式如下:
1) MQ 配置正常
2) 处理过程中并无报错.



但是其他的机器无此问题.  苦思冥想始终不得解.  最终通过对比正常和不正常java process的threaddump来查看有无特别之处.

```shell
jstack  pid
```



最终发现在异常机器上时, java process的main thread 阻塞在MQ交互时.  由此判断和MQ的连接有问题, 排查到是 server firewall引起 连接异常.








