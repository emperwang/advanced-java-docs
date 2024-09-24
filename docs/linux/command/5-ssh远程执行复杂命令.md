---
tags:
  - shell
  - ssh
  - script
---
场景描述:
需要通过ansible + jenkins指令命令来执行DB的switchover(即 主从切换).  当然了单纯实现db的`switchover`通过两个命令即可实现.

问题:
DB安装在特定的server上, 很多命令都通过 `~/.bashrc` 进行了设置, 并且一些变量参数也定义在特定的文件中.  
那么执行切换虽然命令简单,  但是要在shell中配置好各种环境变量以及命令path, 通过`ssh`远程执行命令时, 需要执行很多环境环境定义文件, 以及 命令path 配置文件, 还有一些 定制化的命令脚本.  导致了很多奇怪问题出现.


解决:
通过编写特定的脚本, 把所有 `source envScript; source functionScript; source binPath` 操作在脚本中实现,  然后在ansible中使用 `script`module 远程执行脚本来实现需要的功能.








