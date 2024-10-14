---
tags:
  - Linux
  - port-range
  - tcp
  - udp
---

项目上线新机器,  启动后许多端口报 `port in use (端口占用)` 异常, 发现端口确实被其他占用, (没有权限, 看不到具体的PID).  

测试几次, 现象有些奇怪:  (业务要占用许多端口(十几个之多))
1. 每次被占用的端口,  并不一致. 
2. 被占用的端口都是 4xxxx 比较大的, 2xxxx 没有问题

最终定位到原因, 新机器的 random-port-range 设置的为 35000 -- 60999,  也就是 4xxxx 的都是随机端口.

![](./images/port-range.png)

修改方法有二:
1. 修改程序占用的端口,  改到 35000以下
2. 修改server的 random-port-range, 避开 4xxxx 端口


修改port -range
```shell
## centos7 以及 redhat. 添加下面到 /etc/sysctl.conf
net.ipv4.ip_local_port_range = 50000    60999

```























