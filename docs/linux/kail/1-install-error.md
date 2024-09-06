---
tags:
  - kail
---
安装程序报错:
```shell
apt install telnet
正在读取软件包列表... 完成
正在分析软件包的依赖关系树       
正在读取状态信息... 完成       
下列【新】软件包将被安装：
  telnet
升级了 0 个软件包，新安装了 1 个软件包，要卸载 0 个软件包，有 33 个软件包未被升级。
需要下载 70.4 kB 的归档。
解压缩后会消耗 167 kB 的额外空间。
忽略:1 http://mirrors.ustc.edu.cn/kali kali-rolling/main amd64 telnet amd64 0.17-41.2
忽略:1 http://mirrors.aliyun.com/kali kali-rolling/main amd64 telnet amd64 0.17-41.2
忽略:1 http://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling/main amd64 telnet amd64 0.17-41.2
错误:1 http://http.kali.org/kali kali-rolling/main amd64 telnet amd64 0.17-41.2
  404  Not Found [IP: 202.141.176.110 80]
E: 无法下载 http://http.kali.org/kali/pool/main/n/netkit-telnet/telnet_0.17-41.2_amd64.deb  404  Not Found [IP: 202.141.176.110 80]
E: 有几个软件包无法下载，要不运行 apt-get update 或者加上 --fix-missing 的选项再试试？
root@kali:~/桌面# apt-get update
获取:1 http://mirrors.ustc.edu.cn/kali kali-rolling InRelease [41.5 kB]
获取:2 http://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling InRelease [41.5 kB]
获取:3 http://mirrors.aliyun.com/kali kali-rolling InRelease [41.5 kB]    
错误:1 http://mirrors.ustc.edu.cn/kali kali-rolling InRelease             
  下列签名无效： EXPKEYSIG ED444FF07D8D0BF6 Kali Linux Repository <devel@kali.org>

```


查看使用中的key
```shell
$ apt-key list

/etc/apt/trusted.gpg.d/debian-archive-jessie-automatic.gpg
----------------------------------------------------------
pub   rsa4096 2014-11-21 [SC] [过期于：2022-11-19]
      126C 0D24 BD8A 2942 CC7D  F8AC 7638 D044 2B90 D010
uid           [ 已过期 ] Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>

/etc/apt/trusted.gpg.d/debian-archive-jessie-security-automatic.gpg
-------------------------------------------------------------------
pub   rsa4096 2014-11-21 [SC] [过期于：2022-11-19]
      D211 6914 1CEC D440 F2EB  8DDA 9D6D 8F6B C857 C906
uid           [ 已过期 ] Debian Security Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>

/etc/apt/trusted.gpg.d/debian-archive-jessie-stable.gpg
-------------------------------------------------------
pub   rsa4096 2013-08-17 [SC] [过期于：2021-08-15]
      75DD C3C4 A499 F1A1 8CB5  F3C8 CBF8 D6FD 518E 17E1
uid           [ 已过期 ] Jessie Stable Release Key <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
-----------------------------------------------
pub   rsa4096 2012-03-05 [SC] [过期于：2023-01-16]
      44C6 513A 8E4F B3D3 0875  F758 ED44 4FF0 7D8D 0BF6
uid           [ 已过期 ] Kali Linux Repository <devel@kali.org>

```

可以看到很多key 都过期了。

```shell
wget http://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2024.1_all.deb

sudo dpkg -i kali-archive-keyring_2024.1_all.deb
```
