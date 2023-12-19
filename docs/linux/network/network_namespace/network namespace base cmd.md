
namespace 分类:
```
Mount namespace:  隔离主机文件系统挂载点

UTS namespace: 隔离主机名和域名信息

IPC namespace: 隔离进程间通信

PID namespace: 隔离进程的ID

user namespace:  用于隔离用户权限

network namespace: 隔离网络资源

```



```shell
# 创建一个network namespace,名为  netns1
## 此命令会在 /var/run/netns 路径下创建一个挂载点
## 此挂载点有两个作用:
### 作用一: 方便对namespace的管理
### 作用二: 使namespace即使没有进程使用也能继续存在
ip netns add netns1

# 进入network namespace, 并可以进行一些配置
## 查询netns1 中的网卡信息
ip netns exec netns1 ip link list

# 查看系统有那些 network namespace
ip netns list

# 删除network namespace
## 注意此删除只是删除了namespace对应的挂载点, 只要namespace中还有进程运行着, network namespace就会一直存在
ip netns delete netns1

# 进入并执行命令
ip netns exec netns1 ping 127.0.0.1

# bring up network device
ip netns exec netns1 ip link set dev lo up

# 添加到veth到namespace中
## 1. 创建veth 设备
ip link add veth0 type veth peer name veth1
## 2. 设置veth1到 新的network namespace中
ip link set veth1 setns netns1
## 3. bring up veth
ip netns exec netns1 ifconfig veth1 10.1.1.1/24 up
ifconfig veth0 10.1.1.2/24 up
## 4. test connectivity
ip netns exec netns1 ping 10.1.1.2

# 查看network namespace中的路由
ip netns exec netns1 route
ip netns exec netns1 iptables -L
```

有两种方式可以引用network namespace
1， 通过namespace name来直接引用（上面示例就是name）
2， 通过对应namespace的进程ID

```shell
#通过进程id来引用namespace
ip netns exec netns1 ip link set veth1 netns 1

解析此命令:
ip netns exec netns1   进入到 netns1 namespace中.
ip link set veth1 netns 1  把netns1中的veth1设备设置到 PID=1的进程所属的 namespace (此操作之所以可行，是因为当前实验中并没有PID的隔离, 也就是说不同的network namespace使用的是相同的PID namespace, 故可以通过PID来引用不同的network namespace)
```

```c
clone的标志:
CLONE_NEWIPC
CLONE_NEWNS
CLONE_NEWNET
CLONE_NEWPID
CLONE_NEWUSER
CLONE_NEWUTS
```

此/prod/PID/ns 下的每个文件都代表一个类型的namespace



