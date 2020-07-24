[TOC]

# zabbix使用遇见的一个奇怪问题

环境：

centos7

zabbix4.0.12

情景描述：

zabbix使用被动模式来上报数据，今天发现一个问题是这样，zabbix-agent 正常使用，数据上报也正常，但是当zabbix-agent关闭一段时间，直到server出现"first network  error , wait  15 seconds " 这样的错误日志时， 再次重启zabbix-agent，发现无论如何server都不会过来拉取数据，等多久都是这样。

排查 ：

1. 看server以及agnet相关的日志，没有什么报错
2. 没有被防火墙拦截，相关的端口已经打开，并且可以telnet
3. SElinux已经关闭

所有方式测试了，发现还是不行。

一个同事说可以试试把server端的数据库推倒重来，没办法了，按照这个方法测试了一下，操作完之后，就可以了。