---
tags:
  - linux
  - SELinux
  - command
---

## knowledge

SELinux 运行模式

```shell

Subject:  主体, 可以看成就是 进程

Object:  目标,  目标资源, 一般就是文件系统

Policy: 政策. 会根据某些服务来制定基本的存取安全性政策,政策内还会有详细的规则 rule 来指定不同的服务开放某些资源的存取. 在目前的 Centos7 中有3 个主要的政策:
	targeted:  针对网络服务限制较多,针对本机限制较少,是预设的政策
	minimum: 由targeted修正而来, 仅针对选择的进程来保护
	mls:  完整的SELinux 限制, 限制方面比较严格

Security Context:  安全性上下文.  主体是否能存取目标除了政策指定之外,  主体与目标的安全性文本必须一致才能顺利存取.  security context类似于文件系统的rwx, 如果设置错误,  某些服务(主体进程) 就无法存取文件系统(目标资源), 就会出现权限不符的错误信息.

domain 需要与 type 搭配, 该进程才能够顺利读取文件资源.

```

![](./images/1-selinux.png)

```shell
# secontext
## system_u:object_r:unlabeled_t:s0
user:role:type:sensitivity
or
identity:role:type:sensitivity
or
identity:role:type:domain
or
identify:role:type:level


## 字段含义
identify: 相当于是账户方面的身份识别, 常见有以下集中类型
	unconfined_u: 不受限的用户
	该文件来自不受限的进程所产生的,一般来说, 可以使用可登录账户来取得bash,  预设的bash是不受SELinux管制的,  因为bash并不是什么特别的网络服务,  因此在该bash进程所产生的文件, 其身份识别大多就是该类型了.
	system_u: 系统用户.
	 进本上, 如果是系统软件本身多提供的文件,  大多就是该类型, 如果是用户通过bash自己建立的文件,  大多则是不受限的 unconfined_u 身份, 如果是网络服务所产生的文件,  或是系统服务运行过程中所产生的文件, 则大部分是 system_u.
	

role: 角色.
	通过该字段, 可以知道这个资料是属于进程,文件资源还是代表使用者,  一本的角色由:
	object_r: 代表的是文件或目录等 文件资源
	system_r: 代表的是进程, 不过一般使用者也会被指定为 system_r

type: 类型. (在tergeted中 最重要)
在预设的targeted政策中,  identify 与 role字段基本上是不重要的,而type是最重要的,  基本上一个主体进程能不能读取到这个文件资源,  与类型字段有关,  而类型字段在文件与进程的定义不同.
	type:  在文件资源(object) 上面称为 type.
	domain: 在主体进程(subject)则称为 领域 (domain)




```

## command


```shell
semanage # manage se context 
	
chcon    # update file se context

restorecon  # restore default se context

sesearch   # search se audio log

fixfiles  # check/restore  file 

seinfo

sestatus

getenforce

setenforce

```



> semanage

```shell
##  修改目录的默认 fcontext
semanage fcontext -a -t httpd_sys_content_t '/src/www(/.*)?'

# list se user
semanage user -l 
semanage login -l
semanage fcontext -l

## 


```


> chcon

```shell
# 改变文件的 user/role/type
chcon [OPTION]... [-u USER] [-r ROLE] [-l RANGE] [-t TYPE] FILE...
```

> restorecon

```shell
## restore default context
restorecon -Rv  /src/www

```

> fixfiles
```shell
##  check file 
fixfiles check filename

## relabel /tmp default context
fixfiles relabel

## restore file context to default
fixfiles restore ftpExpect.sh


```

> sesearch
```shell
## check allow action
sesearch -A/--allow

## neverallow
sesearch --neverallow 

## dont audit rule
sesearch -D

## all rules
sesearch --all

## display rules which [httpd_t] domain is allowed to access
sesearch -s httpd_t --allow

## display allowed rules which domain can access to [httpd_sys_script_exec_t]  type
sesearch -t httpd_sys_script_exec_t --allow

## display allowed rules which domain can write to [shadow_t type] files
sesearch -t shadow_t -c file -p write --allow


```

> sestatus

```shell
sestatus -vb

-v: 检查 /etc/sestatus.conf 内的文件与进程的安全性文本内容
-b: 将目前政策的规则boolean值列出.  即某些规则rule是否启动

```

> reference

[鸟哥selinux](https://zq99299.github.io/linux-tutorial/tutorial-basis/16/05.html#selinux-%E7%9A%84%E8%BF%90%E4%BD%9C%E6%A8%A1%E5%BC%8F)


