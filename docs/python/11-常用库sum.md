# 标准库

## 1. os

os模块提供了不少与操作系统相关的函数。

```shell
## 导入
import os
## 获取当前的工作目录
os.getcwd()

## 修改当前目录
os.chdir("/mnt/data")

## 执行系统命令
os.system('mkdir today')
```

常看帮助：

```shell
>>>dir(os)    # 返回所有函数名
>>>help(os)   # 详细的帮助说明
```

## 2. glob 文件通配符

glob模块提供了一个函数用于从目录通配符所有中生成文件列表

## 3. sys 命令行参数

通常工具脚本经常调用命令行参数。 这些命令行参数以链表形式存储与sys模块的argv变量。

```python
import sys
print(sys.argv)
```

错误输出重定向和程序终止：

```python
sys.stderr.write("Warning, log file not found....")	# 错误输出
sys.stdin	# 标准输入
ssy.stdout	# 标准输出
sys.exit()   # 程序终止
```

## 4. re 正则

```shell
>>> import re
>>> re.findall(r'\bf[a-z]*','which foot or hand fell fastest')
['foot', 'fell', 'fastest']
>>>
```



## 5. 数学

```python
>>> import math
>>> math.cos(math.pi/4)
0.7071067811865476
>>>
```



## 6.随机

```shell
>>> import random
>>> random.choice(['apple','peer','banana'])
'peer'
>>> random.random()
0.17342896177504574
>>> random.randrange(6)
2
```

## 7.访问互联网

smtplib 电子邮件，urllib。

## 8. 日期和事件

datetime模块为日期和事件处理同时提供了简单和复杂的方法。

```shell
>>> from datetime import *
>>> date.today()
datetime.date(2019, 11, 26)
```



## 9.数据压缩

zlib模块直接支持通用的数据打包和压缩格式：zlib, gzip, bz2, zipfile, tarfile