[TOC]

# 变量

## 1. 组变量

```shell
# 方式一: 在group_vars中定义一个以组名字命名的文件,可以用于为此组定义变量
group_vars/groupName

# 方式二: 在group_vars中创建一个组命名的目录,然后在此目录中可以分类创建对应的变量
group_vars/groupName/db_settings
group_vars/groupName/cluster_settings
```



```ini
[group1]
182.169.72.35
182.169.72.36
182.169.72.37

# 定义对应的group变量
[group1:vars]
some_server=foo.example.com
sccape_pode=2
address=bj
```

```yaml
# 主机定义
all:
  hosts:
    example.com
  children:
    webservers:
      hosts:
        example2.com
        example1.com
     dbservers:
       hosts:
         one.com
         two.com
```

上面yaml对应的ini配置

```ini
examle.com

[webservers]
example1.cpm
example2.com

[dbservers]
one.com
two.com
```





## 2. 主机变量

```shell
# 方式一: 创建对应的hostName命名的文件,可以以此定义对应的host变量
host_vars/hostName

# 方式二: 创建对应的目录.分类设置变量
host_vars/hostName/db_setting
host_vars/hostName/cluster_setting
```

```ini
# 为一个host定义变量
[targets]
localhost  		ansible_connection=local
exampl1.com		ansible_connection=ssh		ansible_user=myuser
exampl2.com		ansible_connection=ssh		ansible_user=otherUser
```

