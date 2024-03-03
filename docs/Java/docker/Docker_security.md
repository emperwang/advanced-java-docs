# Docker-Security

## 使用资源限制

### 内存

```shell
# 内存
# 使用-m或--memory参数，只是限制了物理内存的使用，并没有限制交换内存的使用
docker run -d -m 512M nginx:stable
# 通过--memory-swap 参数，可以设置容器对总内存的使用，也就是物理内存加上交换区内存的总量
docker run -d -m 512M --memory-swap 1024M nginx:stable
```

### cpu权重

```shell
# 通过-c或--cpu-shares参数设置容器占用的cpu权重
docker run -d -c 500 nginx:stable
docker run -d -c 1000 php
```

此时安布nginx和php分配为1:2，也就是说这个两个容器能分配分别33.3% 和66.6%。 注意：cpu权重不代表绝对的cpu分配上限，如果php容器处于空闲状态，cpu占用为0，那么nginx允许使用100%的zou资源。

```shell
# --cpu-period表示计算调动的周期，--cpu-quota表示在单一调度周期中，分配给这个容器的时间配置
docker run -d  --cpu-period 10000 --cpu-quota 5000 nginx
```



### 硬盘

--device-read-bps和--device-write-bps命令限制指定硬盘的读写速度，也可以通过--device-read-iops和--device-write-iops命令限制IO数量。

```shell
# 正常使用
docker run --rm ubuntu dd if=/dev/zero of=/tmp/out bs=1M count=1024 oflag=direct

# 限制
docker run --rm --device-read-bps /dev/sha:50mb ubuntu  dd=/dev/zero of=/tmp/out bs=1M count=1024 oflag=direct
```

### ulimit限制

通过ulimit可以修改Core dump文件大小，数据段大小，文件句柄数，进程栈深度，CPU时间，单一用户进程数，进程虚拟内存等。另外可以通过docker daemon中对ulimit的配置，配置容器的默认ulimit限制，所有容器的ulimit都继承于docker daemon中的默认设置。

```shell
docker run -d --name nginx --ulimit cpu=1000 nginx:stable
# 默认配置
dockerd --default-ulimit cpu=1000
```



## 运行状态监控

```shell
# 容器运行状态 
docker  ps -a

# 查看容器对资源的占用
docker stats --no-stream php

# 查看容器内部程序的输出信息
docker logs nginx
```

## 文件系统安全
```shell
# 文件系统只读
docker run -it --rm --read-only ubuntu /bin/bash
```


## 内核安全技术
```shell
# 内核能力
cat /proc/pid/status | grep cap s
#CapBnd(Boundary Capability) 系统提供给程序内核能的边界
#CapPrm(Permitted) 程序所能拥有的内核能力
#CapEff(Effective) 程序实际拥有的内核能力
#CapInh(Inheritable) 当此程序唤起其他程序时，被唤起程序能够得到的内核能力

# 去除修改文件所有者的能力
docker run -it --cap-drop chown ubuntu /bin/bash
```


## SELinux支持
```shell
dockerd --selinux-enable=true
```


