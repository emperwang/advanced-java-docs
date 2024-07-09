---
tags:
  - kernel
  - aufs
---

在centos7上要使用AUFS文件系统, kernel默认是不支持的, 需要更新到一个支持AUFS的系统上.
记录下通过 elrepo更新系统的step
```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

# 安装 kernel-ml repo
yum --enablerepo="elrepo-kernel" install kernel-ml

# 移除旧的kernel
yum remove -y kernel-{devel,tools,tools-libs}

# install new kernel
yum install -y kernel-ml kernel-ml-{devel,tools,tools-libs} grub2-tools


# build new kernel entry
grub2-mkconfig -o /boot/grub2/grub.cfg
grep vmlinuz  /boot/grub2/grub.cfg
grub2-set-default 0

### 使用新的kernel启动有问题. 

```

