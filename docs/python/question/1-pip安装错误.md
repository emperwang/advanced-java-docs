# pip 安装错误

> 环境
>
> centos7  python2.7.5

```shell
# 错误log
[root@name2 ~]# pip install ansible
Traceback (most recent call last):
  File "/usr/bin/pip", line 9, in <module>
    load_entry_point('pip==21.1.2', 'console_scripts', 'pip')()
  File "/usr/lib/python2.7/site-packages/pkg_resources.py", line 378, in load_entry_point
    return get_distribution(dist).load_entry_point(group, name)
  File "/usr/lib/python2.7/site-packages/pkg_resources.py", line 2566, in load_entry_point
    return ep.load()
  File "/usr/lib/python2.7/site-packages/pkg_resources.py", line 2260, in load
    entry = __import__(self.module_name, globals(),globals(), ['__name__'])
  File "/usr/lib/python2.7/site-packages/pip/__init__.py", line 1, in <module>
    from typing import List, Optional
ImportError: No module named typing
```

在安装之前使用了

```shell
# 进行了升级，升级后的版本为: pip==21.1.2
# pip在21.0 版本后, 就不再对 python2进行支持,所以把pip版本降低
pip install --upgrade pip 

pip install -U "pip < 21.0"
```

