---
tags:
  - linux
  - SELinux
  - command
---

## command

```shell
# secontext
## system_u:object_r:unlabeled_t:s0
user:role:type:sensitivity

```

```shell
semanage # manage se context 
	
chcon    # update file se context

restorecon  # restore default se context

sesearch   # search se audio log

fixfiles  # check/restore  file 



```



> semanage

```shell
##  修改目录的 fcontext
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
