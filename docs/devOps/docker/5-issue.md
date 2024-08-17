---
tags:
  - mydocker
  - issue
  - docker
---

## issue 1
编译mydocker成功, 并且能成功运行并创建容器.  
不过当第二次执行时, 报错
```shell
./mydocker run -ti /bin/sh 
{"level":"error","msg":"fork/exec /proc/self/exe: no such file or directory","time":"2024-08-04T11:35:08+08:00"}
```

这是因为 namespace的一些使用问题.
> https://blog.csdn.net/qq_27068845/article/details/90705925


## issue 2

```shell
ERRO[0000]/root/gotest/cgroups/cgroup_manager.go:28 tutorial/GoLearn/cgroups.(*CgroupManager).Apply() manager apply pid error: write /sys/fs/cgroup/cpuset/mydocker-cgroup/tasks: no space left on device 
```

> https://stackoverflow.com/questions/28348627/echo-tasks-gives-no-space-left-on-device-when-trying-to-use-cpuset

当设置  cpuset的task时, 需要先设置 `cpuset.mems` 和 `cpuset.cpus`.  或者直接继承父类的配置.
```shell
## solution 1
echo 0 > /sys/fs/cgroups/cpuset/mtest/cpuset.mems
echo 1 > /sys/fs/cgroups/cpuset/mtest/cpuset.mems

## solution 2
# 可以设置父类配置可直接继承
echo 1 > /sys/fs/cgroups/cpuset/cgroup.clone_children

```


