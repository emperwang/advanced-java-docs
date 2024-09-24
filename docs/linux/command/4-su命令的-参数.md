---
tags:
  - su
  - shell
  - script
---

通常会通过 `su - username` 来切换用户, 那么命令中 `-` 是什么作用呢?

```shell
# man su

  -, -l, --login
              Starts the shell as login shell with an environment similar to a real login:

     o  clears all environment variables except for TERM

     o  initializes the environment variables HOME, SHELL, USER, LOGNAME, PATH

     o  changes to the target user's home directory

     o  sets argv[0] of the shell to '-' in order to make the shell a login shell

```

可见 `-`的作用还挺大的, 通过 man 可以看到主要的作用有以上所述:
1. 清除 除了 TERM 的环境变量
2. 初始化环境变量, 像HOME  SHELL USER LOGNAME PATH
3. 切换到用户的家目录
4. 设置shell的 argv[0] 为 '-', 为了把 shell 作为 login shell





