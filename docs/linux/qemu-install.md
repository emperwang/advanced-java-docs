# qemu-3.0.0 安装

## 1.安装epel库

```shell
yum install epel-release
```



## 2. 安装依赖

```shell
yum install SDL2-devel libjpeg-turbo-devel libcurl-devel spice-server spice-protocol-devel  spice-protocol-devel zlib-devel zlib gtk3-devel
```

注意:如果不安装 epel库，那么SDL2就找不到依赖包，SDL2没有安装的话，启动系统就没有图形化界面.

## 3.配置

```shell
## 执行下面的脚本

#!/bin/sh
./configure --target-list="arm-softmmu,i386-softmmu,x86_64-softmmu,arm-linux-user,i386-linux-user,x86_64-linux-user" --enable-debug --enable-sdl --enable-gtk --enable-vnc --enable-vnc-jpeg --enable-vnc-png --enable-kvm --enable-curl  --enable-tools
```



## 4. 编译安装

```shell
make && make install 
```



## 5. 测试启动

```shell
## 硬盘启动
qemu-system-i386 -hda linux-0.11-devel-060625.qcow2  -no-reboot -m 16
## 软盘启动
qemu-system-i386 -fda floppy.img -boot a

-hda: 硬盘启动
-fda: 软盘启动
-boot a: 启动顺序
-m: 指定内存
```

