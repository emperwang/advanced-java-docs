[TOC]

# redis集群运维常见问题

环境：6个redis节点，三主三从，均匀分布在三台机器。

## 1. 权限问题

之前先用root等超级用户启动，后来使用指定用户，如fcaps启动时，导致启动失败。

解决：

把redis相关的配置，以及data目录修改权限为指定用户的权限。

## 2.主备切换问题

redis集群一个master节点意外退出，导致程序连接时报redis集群异常。

问题：挂掉一个master节点，slave节点晋升为master时间过长。

解决：

把配置中cluster-node-timeout 和 cluster-replica-validity-factor的值修改小一些。