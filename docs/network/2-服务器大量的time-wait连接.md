# TIME_WAIT优化

TCP四次挥手：

```properties
      TCP A                                                TCP B

  1.  ESTABLISHED                                          ESTABLISHED

  2.  (Close)
      FIN-WAIT-1  --> <SEQ=100><ACK=300><CTL=FIN,ACK>  --> CLOSE-WAIT

  3.  FIN-WAIT-2  <-- <SEQ=300><ACK=101><CTL=ACK>      <-- CLOSE-WAIT

  4.                                                       (Close)
      TIME-WAIT   <-- <SEQ=300><ACK=101><CTL=FIN,ACK>  <-- LAST-ACK

  5.  TIME-WAIT   --> <SEQ=101><ACK=301><CTL=ACK>      --> CLOSED

  6.  (2 MSL)
      CLOSED  
```

可以看到TIME_WAIT出现在`首先调用close的一方`, 即 那端先调用close(), 此端就会有TIME_WAIT的状态.  在服务器上大量出现TIME_WAIT是因为: 

1. 高并发让服务器在短时间范围出现大量TIME_WAIT连接.
2. 短连接--`业务处理+传输数据的时间远远小于TIME_WAIT超时时间`的连接

这里有个相对长短的概念, 如: 获取一个web页面, 1s的http短链接处理完业务, 在关闭连接之后, 这个业务用过的端口会停留在TIME_WAIT状态几分钟, 而这几分钟, 其他http请求过来的时候,是无法占用此端口的.

综上所述, 持续的到达一定量的高并发短链接, 会使服务器因为端口资源不足而拒绝部分服务.  同时这些端口都是服务器临时分配的, 无法使用SO_REUSEADDR选项解决此问题.

统计连接到脚本:

```shell
netstat -ant | awk '/^tcp {++S[$NF]} END {for(a in S) print (a, S[a])}'

# 输出:
LAST_ACK 14
SYN_RECV 348
ESTABLISHED 70
FIN_WAIT1 229
FIN_WAIT2 30
CLOSING 33
TIME_WAIT 18122
```

状态解析:

```properties
CLOSED:  关闭的连接
LISTEN: 服务器正在等待呼入, 即等待连接
SYN_RECV: 一个连接请求已到达, 等待确认
SYN_SENT: SYN 同步请求发送
ESTABLISHED: 连接建立, 正常数据传输
FIN_WAIT1: 发送完成 fin 包
FIN_WAIT2: 发送fin包后, 对端响应了 fin包
ITMED_WAIT: ---??   等待所有分组死掉
CLOSING: 两边同时尝试关闭
TIME_WAIT: 接收到对端发送的fin 包
LAST_ACK:  类比上图,相当与发送fin后, 等待对端响应
```

尽量处理服务器端TIME_WAIT过多:

```properties
# 编辑/etc/sysctl.conf文件,
## sysctl.conf 使用 sysctl -p 命令让参数生效
## sysctl.conf是一个允许改变正在运行中的linux系统的接口,包含一些TCP/IP堆栈和虚拟内存的高级选项,修改内核参数永久生效

## 表示开启SYN Cookies,当出现SYN等待队列溢出时,启动cookies来处理; 可防范少量syn攻击,默认为0,表示关闭
net.ipv4.tcp_syncookies=1
## 表示开启重用. 允许将TIME_WAIT sockets重新用于新的tcp连接
net.ipv4.tcp_tw_reuse=1
## 表示开始tcp连接中 TIME_WAIT socket的快速回收
net.ipv4.tcp_tw_recycle=1
## 修改系统默认的 TIME_OUT时间
net.ipv4.tcp_fin_timeout=60(60s默认)
## 表示当keepalive起作用的时候,tcp发送keepalive消息的频度, 缺省是2小时, 改为20分钟
net.ipv4.tcp_keepalive_time=1200
## 表示用于向外连接的端口范围,缺省情况下很小,32768-61000, 修改为 1024-65000
net.ipv4.ip_local_port_range=1024 65000
## 表示SYN队列的长度, 默认为1024,加大队列长度为8192,可以容纳更多等待连接的网络连接数
net.ipv4.tcp_max_syn_backlog=8192
# 表示系统同时保持TIME_WAIT套接字的最大数量,如果超过这个数字,TIME_WAIT套接字将立刻被清除并打印警告信息. 默认为180000, 修改为5000.对于apche nginx等服务其可很好较少TIME_WAIT套接字数量,对于squid 效果不大.
net.ipv4.tcp_max_tw_buckets=5000
```

















