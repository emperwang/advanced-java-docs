# docker安装

既然要说docker，那肯定得安装一个环境了。

docker基于linux，windows都可以安装，不过windows必须是10以上，linux内核最好是3.10以上。今天安装的环境是centos7。

## 1. 查看一下内核版本

```shell
[root@bogon ~]# uname -a
```

![](uname.png)

## 2.使用root更新一下centos
```shell
[root@bogon ~]# yum update
```


## 3. 卸载旧版本的docker
```powershell
[root@bogon ~]# rpm -qa docker
docker-1.13.1-88.git07f3374.el7.centos.x86_64
[root@bogon ~]# yum remove docker-1.13.1-88.git07f3374.el7.centos.x86_64
```

![](remove_docker.png)

## 4. 安装需要的软件

yum-util 提供yum-config-manager功能，另外两个是devicemapper驱动依赖的.

```shell
 [root@bogon ~]# yum install -y yum-utils device-mapper-persistent-data lvm2
```


## 5. 设置docker的yum源
```shell
[root@bogon ~]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

![](add_docker_repo.png)

## 6. 查看所有的docker版本

```shell
[root@bogon ~]# yum list docker-ce --showduplicates |sort -r
```

![](list_docker.png)

## 7. 安装docker

```shell
[root@bogon ~]# yum install -y docker-ce-17.12.1.ce
```

![](install_docker.png)

## 8. 启动docker

```shell
[root@bogon ~]# systemctl start docker
```

