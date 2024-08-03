---
tags:
  - linux
  - shell
  - ssh
  - proxycommand
---
在项目环境中, 项目是部署在内部网络的, 而客户要连接进来, 是通过防火墙后连接到DMZ的server。

>DMZ: demilitarized zone  非军事区

![dmz](dmz-server)
> 注意:
> DMZ 不可访问内网.  内网机器可单向访问DMZ

其中client是通过firewall后连接到DMZ机器上的服务,  之后内网中的服务同样连接到DMZ机器上的服务,  这样client就可以和真正的服务交互了.  
当然了, 整个过程对客户是透明的.

我们的环境中, 内网也只有部分的机器可以访问DMZ(可访问的机器称为 jumper),  故在任意的内网机器上, 想要操作DMZ server, 需要通过jumper作为跳板, 然后才可操作.

具体的命令exmaple如下：
```shell
ssh -q -v -o StrictHostKeyChecking=no -o ProxyCommand="ssh -q -W %h:%p username@jumper"  username@desthost  "cmd"

```


然后就发现, 通过jumperA就正常,  通过jumperB 操作就失败.
```shell
# 成功
ssh -q -v -o StrictHostKeyChecking=no -o ProxyCommand="ssh -q -W %h:%p username@jumperA"  username@desthost  "cmd"

#失败
ssh -q -v -o StrictHostKeyChecking=no -o ProxyCommand="ssh -q -W %h:%p username@jumperB"  username@desthost  "cmd"
```

报错信息如下:
```shell
$ ssh  -v -o StrictHostkeyChecking=no -o ProxyCommand="ssh -W %h:%p 192.168.30.18" 192.168.30.19

OpenSSH_7.4p1, OpenSSL 1.0.2k-fips  26 Jan 2017
debug1: Reading configuration data /etc/ssh/ssh_config
debug1: /etc/ssh/ssh_config line 58: Applying options for *
debug1: Executing proxy command: exec ssh -W 192.168.30.19:22 192.168.30.18
debug1: permanently_set_uid: 0/0
debug1: permanently_drop_suid: 0
debug1: identity file /root/.ssh/id_rsa type 1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_rsa-cert type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_dsa type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_dsa-cert type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_ecdsa type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_ecdsa-cert type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_ed25519 type -1
debug1: key_load_public: No such file or directory
debug1: identity file /root/.ssh/id_ed25519-cert type -1
debug1: Enabling compatibility mode for protocol 2.0
debug1: Local version string SSH-2.0-OpenSSH_7.4
channel 0: open failed: administratively prohibited: open failed
stdio forwarding failed
ssh_exchange_identification: Connection closed by remote host

```

> 这里注意: 
> 在发现异常后, 要把ssh的 -q 选项去除, 这样才能暴漏更多的异常消息, 益于排查.

> channel 0: open failed: administratively prohibited: open failed
stdio forwarding failed

此为关键的异常信息,  表明在sshd中配置了禁止此类跳转的操作.
![](./images/ssh/tcp_forward.png)

把 `AllowTcpForwarding` 设置为yes， 重启sshd就可以了。












































