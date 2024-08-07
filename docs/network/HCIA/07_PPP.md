---
tags:
  - network
  - HCIA
  - PPP
---
实验:
1. PPP 连接, 以及设置时钟
2. PPP 的PAP 认证
3. PPP的CHAP 认证

![](./images/0700/0700_topo.png)
### IP 配置
```
R1
system-view 
	sysname R1
	display interface s4/0/0
	interface s4/0/0    # 配置serial端口
		virtualbaudrate 115200   # 配置波特率
		link-protocol ppp        # 端口使用的 协议
		ip address 192.168.1.1 24
R2
system-view 
	sysname R2
	display interface s4/0/0
	interface s4/0/0    # 配置serial端口
		virtualbaudrate 115200   # 配置波特率
		link-protocol ppp        # 端口使用的 协议
		ip address 192.168.1.1 24



```

配置R1 serial端口前：
![](./images/0700/0700_r1_serial_interface.png)

配置后
![](./images/0700/0700_r1_config_after.png)

![](./images/0700/0700_r2_ping_r1.png)

此时两个路由就可通信了.



### PAP 认证
PAP 单向认证
```
### R1作为认证方
#### 首先在R1创建认证账户,并打开PPP认证
#### R2 配置R1的验证信息
R1
aaa
	local-user R1 password cipher huawei 
	local-user R1 service-type ppp
interface s4/0/0
	ppp authentication-mode pap 

R2
interface s4/0/0
	ppp pap local-user R1 password cipher huawei
```


PAP 双向认证
```
### R1 R2 同时验证对方身份
#### R1 R2 分别创建验证账户
#### R1 R2 打开PPP认证
#### R1 R2 分别配置对方的验证信息
R1
aaa
	local-user R1 password cipher huawei 
	local-user R1 service-type ppp
interface s4/0/0
	ppp authentication-mode pap 
	ppp pap local-user R2 password cipher kunpeng
	
R2
aaa
	local-user R2 password cipher kunpeng
	local-user R2 service-type ppp
interface s4/0/0
	ppp authentication-mode pap
	ppp pap local-user R1 password cipher huawei


```

![](./images/0700/0700_ppp_pap_packet.png)
![](./images/0700/0700_ppp_pap_auth_pwd.png)

### CHAP 认证
CHAP 单向认证
```
### R1作为认证方
#### 首先在R1创建认证账户,并打开PPP认证
#### R2 配置R1的验证信息
R1
aaa
	local-user R1 password cipher huawei 
	local-user R1 service-type ppp
interface s4/0/0
	ppp authentication-mode chap

R2
interface s4/0/0
	ppp chap user R1 
	ppp chap password cipher huawei


```
![](./images/0700/0700_chap_pwd.png)
可以看到CHAP认证信息是加密后传输.

CHAP 双向认证
```
### R1 R2 同时验证对方身份
#### R1 R2 分别创建验证账户
#### R1 R2 打开PPP认证
#### R1 R2 分别配置对方的验证信息
R1
aaa
	local-user R1 password cipher huawei 
	local-user R1 service-type ppp
interface s4/0/0
	ppp authentication-mode chap 
	ppp chap user R2 
	ppp chap password cipher kunpeng
	
R2
aaa
	local-user R2 password cipher kunpeng
	local-user R2 service-type ppp
interface s4/0/0
	ppp authentication-mode chap
	ppp chap user R1 
	ppp chap password cipher huawei


```










  