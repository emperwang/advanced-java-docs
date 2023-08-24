[TOC]

# 记录一次zabbix配置timeout配置带来的问题

## 1. 情景描述

zabbix监控线上的spark集群application，如果application异常退出，那么就发出告警，并重新提交任务。现在出现的异常是，spark应用退出，但是没有提交任务。从日志看，只有退出操作，没有执行提交操作。zabbix脚本大意如下：

```shell
检测spark application
if 正常 :
	echo 0
else
	echo 1
	stop-application # 执行一次停止操作
	sleep 5
	start-application	# 执行一次启动操作
fi
```

脚本测试过，功能是正常的。zabbix配置10分钟执行一次，那么问题是：为什么没有执行启动呢？

当前的zabbix配置的格式是主动去拉取数组，相应的对于agent就是被动模式。

## 2. 异常分析

从spark的输出日志，分析出，每次都有执行stop操作，但是就没有执行start操作。为什么呢？

而且，翻看zabbix的日志，发现一个输出：

```shell
item "name2:key" became not supported: Timeout while executing a shell script
```

从输出看，大意是执行脚本超时。那么是什么操作超时了呢？

翻看了一下zabbix的官网，发现zabbix-server和zabbix-agent都有一个Timeout的配置项，且默认值都是3，选值范围是1-30。

由此断定可能是这两个参数引起的问题，下面做实验才复现一下。

## 3. 两个配置项的深入解析

两个配置项的作用分析：

```shell
zabbix-server Timeout: 此配置项表示 server去agent拉取数据时，最多的等待时间。
zabbix-agent  Timeout: 此配置表示，agent执行脚本时，脚本执行时间不能超过此配置。
```

现象：

实验配置：

agent 配置的Timeout时间为 3

执行的脚本中添加 一个   sleep 10，也就是保证脚本执行时间大于 3.

**当agent执行脚本的时间超过 agent配置的 Timeout时间时，报错如下：**

```shell
item "name2:testtimeout" became not supported: Timeout while executing a shell script
```



实验配置：

server的配置 Timeout 为 5

agent的配置 Timeout 为 7

且让脚本执行时间超过5，添加一个 sleep 6； 要保证时间大于5.

**当server去拉取数据的时间超过 server配置的Timeout时，报错如下：**

```shell
resuming Zabbix agent checks on host "name2": connection restored
  9306:20200628:135707.352 Zabbix agent item "testtimeout" on host "name2" failed: first network error, wait for 15 seconds

```

