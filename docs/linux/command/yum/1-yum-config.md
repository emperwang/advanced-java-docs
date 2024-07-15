---
tags:
  - linux
  - yum
---

记录一些yum的配置

```
# 使用ali source
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 获取阿里云epel源
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all && yum makecache

# 添加repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo


# list package
yum list docker-ce --showduplicates 

# list enabled repo
yum listrepo enabled

# list package in repo
yum --enablerepo="elrepo"  list available
```






