[TOC]

# redis aof持久化文件内容解析

aof持久化的流程图:

![](../../image/redis/aof_0)

如图所示，AOF持久化功能的实现可以分为命令追加（append）、文件写入（write）、文件同步（sync）、文件重写（rewrite）和重启加载。流程如下：

* 所有的写命令会追加到AOF缓冲区中
* AOF缓存区根据对应的策略向硬盘进行同步操作
* 随着AOF文件越来越大,需要定期对AOF文件进行重写操作，达到压缩的目的
* 当redis重启时，可以加载AOF文件进行数据恢复。

## 命令追加

当AOF持久化功能打开状态时，redis在执行完一个写命令后，会以协议格式（也就是**RESP**，即redis客户端和服务器交互的通信协议）将被执行的写命令追加到redis服务器端维护的AOF缓冲区末尾。

如:

```shell
# 比如命令  set  mykey  myvalue 这条命令就以如下格式记录到AOF缓存中
"*3\r\n$3\r\nset\r\n$5\r\nmykey\r\n$7\r\nmyvalue\r\n"
```

**RESP**协议主要由以下几种数据类型组成，每种数据类型定义如下：

* 简单字符串:以+号开头,结尾为\r\n,如: +OK\r\n
* 错误信息:以-号开头,结尾为\r\n,如: -ERR Readonly\r\n
* 整数: 以 :(冒号)开头,结尾为\r\n, 开头和结尾之间为整数,如   (:1\r\n)
* 大字符串: 以$开头,随后为该字符串长度和\r\n,长度限制为512M, 最后为字符串内容和\r\n, 如上面实例所示
* 数组: 以* 开头,随后指定数组元素个数并通过\r\n划分,每个数组元素可以为上面4中,如: *1\r\n$4\r\nping\r\n



## 文件同步

redis每次结束一个事件循环之前，都会调用flushAppendOnlyFile函数，判断是否需要将AOF缓冲区中的内容写入和同步到AOF文件中。

flushAppendOnlyFile函数的行为由redis.conf中配置的appendfsync选项的值类决定，该选项有三个值：always，everysec，no。

* always：redis在每个事件循环都要将AOF缓冲区中的所有内容写入到AOF文件，并且同步AOF文件，所以always的效率是三个选项中最差的一个，但从安全性来说，也是最安全的。当发生故障停机时，AOF持久化也只会丢失一个事件循环中所产生的命令数据。
* everysec：redis在每个事件循环都要将AOF缓冲区中的所有内容写入到AOF文件中，并且每隔一秒就要在子线程中对AOF文件进行一次同步。从效率上看，该模式足够快。当发生故障时，只会丢失一秒钟的命令数据。
* no：redis在每一个事件循环都要将AOF缓冲区中的所有内容写入到AOF文件。而AOF文件的同步由操作系统控制，这种模式下速度最快，但是同步的时间间隔较长，出现故障可能会丢失较多数据。



## aof数据恢复

![](../../image/redis/aof_restart)

数据恢复步骤:

* 创建一个不带网络连接的伪客户端(fake client), 因为redis的命令只能在客户端上下文中执行, 而载入AOF文件时所使用的命令直接来源于AOF文件而不是网络连接, 所有服务器使用了一个没有网络连接的伪客户端来执行AOF文件保存的命令,  伪客户端执行命令的效果和带网络连接的客户顿执行命令的效果完全一样
* 从AOF文件中分析并取出一条写命令
* 使用伪客户端执行被读出的写命令
* 一直执行步骤2和步骤3,  直到AOF文件中的所有写命令都被处理完毕为止.



## aof文件重写

因为aof持久化是通过保存被执行的写命令来记录redis状态的,随着redis长时间运行,AOF文件中的内容会越来越多,  文件体积也会越来越大, 如果不加以控制的话, 体积过大的AOF文件很可能对redis甚至宿主机造成影响.

为了解决AOF文件过大的问题, redis提供了AOF文件重写功能。通过该功能，redis可以创建一个新的AOF文件来替代现有的AOF文件。新旧两个AOF文件所保存的redis状态相同，但是新的AOF文件不会包含任何浪费空间的冗余命令，所以新的AOF文件的提交通常小很多。

![](../../image/redis/aof_rewrite)

如上所示，重写前记录名为list的键的状态，AOF文件需要保存5条命令，而重写后，则只需要保存一条命令。**AOF文件重写并不需要对现有的AOF文件进行任何读取、分析或者写入操作，而是通过读取服务器当前的数据库状态来实现的。首先从数据库中读取键现在的值，然后用一条命令去记录键值对，代替之前记录这个键值对的多条命令，这就是AOF重写功能的原理。**

在实际过程中，为了避免在执行命令时造成客户端输入缓冲区溢出，AOF重写在处理列表、哈希表、集合、有序集合这4种可能会带有多个元素的键时，会先检查键所包含的元素数量，如果数量超过REDIS_AOF_REWRITE_ITEMS_PER_CMD（一般为64）常量，则使用多条命令记录该键的值，而不是一条命令。

rewrite触发机制：

* 手动调用bgrewriteaof命令，如果当前有正在运行的rewrite子进程，则本次rewrite会推迟执行，否则，直接触发一次rewrite。
* 通过配置指令手动开启AOF功能，如果没有RDB子进程的情况下，会触发一次rewrite，将当前数据库中的数据写入rewrite文件
* 在redis定时器中，乳沟有需要退出执行的rewrite并且没有正在运行的RDB或者rewrite子进程时，触发一次或者AOF文件大小已经到达配置的rewrite条件也会自动触发一次。

## AOF后台重写

AOF重写函数会进行大量的写入操作，调用该函数的线程将被长时间阻塞，故redis在子进程中指定AOF重写操作。

* 子进程进行AOF重写期间，redis进程可以继续处理客户端命令请求
* 子进程带有父进程的内存数据拷贝副本，在不适用锁的情况下，也可以包保证数据的安全性

但是在子进程进行AOF重启期间，redis接收客户端命令，会对现有数据库状态进行修改，从而导致数据当前状态和重写后的AOF文件所保存的数据库状态不一致。为此redis设置了一个AOF重写缓冲区，这个缓冲区在服务器创建子进程之后开始使用，当redis执行完一个写命令之后，它会同时将这个命令AOF缓冲区和AOF重写缓冲器。

![](../../image/redis/aof_rewrite1)

当子进程完成AOF重写工作后，它会向父进程发送信号，父进程在接收到该信号后，会调用一个信号处理函数，并执行以下工作：

* 将AOF重写缓冲区中的所有内容写入到新的AOF文件中，包装新的AOF文件保存的数据库状态和服务器当前状态一直
* 对新的AOF文件进行改名，原子的覆盖现有AOF文件，完成新旧文件的替换
* 继续处理客户端请求命令

在整个AOF后台重写过程中，只有信号处理函数执行时会对redis主进程造成阻塞，其他时候AOF后台重写都不会阻塞主进程。

![](../../image/redis/aof_rewrite2)



























