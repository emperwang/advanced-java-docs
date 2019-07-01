# sshd镜像

镜像的创建有两种方式，一种是新建容器，并在容器中根据需求进行修改，再将容器提交为新的镜像。另一种方式是把构建命令全部写到dockerfile中，再使用docker build进行创建。

创建镜像推荐使用dockerfile，因为dockerfile拥有更清晰的结构，更好的可以移植性，更一致的构建结构。不过直接使用dockerfile创建容器出错，一般的构建容器方式是在新建容器中根据需求进行修改，并把命令记录下来，全部完成后，并没有出错，再把命令写入到dockerfile中，使用docker build进行创建。

## 1. 新建容器创建sshd镜像

```shell
1. 新建容器
docker pull ubuntu:latest
2. 进入容器进行按需进行操作
docker run -it ubuntu:latest /bin/bash
3. 更新镜像
apt-get update
4.安装sshd服务
apt-get install -y openssh-server
5. 创建sshd工作目录
mkdir -p /var/lib/sshd
6. 创建root用户的授权公钥
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
在把虚拟机中的id_rsa.pub内容拷贝到文件中

7. 注释掉pam要求
sed -ri 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd

8. 运行sshd服务
/usr/sbin/sshd -D
```



## 2. dockerfile创建镜像

```shell
# 基础镜像
FROM ubuntu:latest
# 安装服务
RUN apt-get update && apt-get install -y openssh-server
# 创建工作目录
RUN mkdir -p /var/lib/sshd && mkdir -p /root/.ssh
# 拷贝授权码
ADD authorized_keys /root/.ssh
# 注释掉pam模块
RUN sed -ri 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd
# 添加启动脚本
ADD run.sh /run.sh
# 给启动脚本添加运行权限
RUN chmod 755 /run.sh
# 暴露22端口
EXPOSE 22
# 镜像启动命令
CMD ["/run.sh"]
```

run.sh内容

```shell
#!/bin.bash
/usr/sbin/sshd -D
```

构建镜像:

```shell
docker build -t sshd:ubuntu dockerFile所在目录
```

测试:

```shell
docker run -d -p 8888:22 --name sshd 5d424da276fd
-d: 后天运行
-p: 映射端口
--name: 指定名字
```

