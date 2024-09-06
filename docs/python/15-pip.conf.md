---
tags:
  - pip
  - python
  - pip_conf
---
获取 pip.conf的加载顺序
```shell
$ pip config -v list
For variant 'global', will try loading 'C:\ProgramData\pip\pip.ini'
For variant 'user', will try loading 'C:\Users\Sparks\pip\pip.ini'
For variant 'user', will try loading 'C:\Users\Sparks\AppData\Roaming\pip\pip.ini'
For variant 'site', will try loading 'C:\Python312\pip.ini'
```


设置url的配置
```pip.conf
[global]
index-url = https://username:pwd@pypi.tuna.tsinghua.edu.cn/simple
timeout=60


[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
cert = path/ca-boundle.crt
```

```shell
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = https://pypi.tuna.tsinghua.edu.cn
```
