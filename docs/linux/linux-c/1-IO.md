# 文件IO

## 1. 常用函数

### 1.1 open

```c
// 函数原型
// 所需的同文件
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
/**
 打开文件，pathname表示文件名字， flag哪种方式打开文件
*/
int open(const char *pathname, int flags);
// 创建文件时才使用此函数， mode表示创建的文件格式
int open(const char *pathname, int flags, mode_t mode);

flag:
O_RDONLY	只读打开
O_WRONLY	只写打开
O_RDWR		读写打开
O_APPEND	每次写都追加到文件尾端
O_CREAT		若文件不存在则创建它
O_EXCL		不可和O_CREAT同时使用。 测试文件是否存在，不存在则创建此文件，原子操作
O_TRUNC		如果文件存在，且为只读或只写成功打开，则将其长度截短为0
O_NOCTTY	如果pathname为终端设备，则不将此设备作为此进程的控制终端
O_NONBLOCK	如果pathname指一个FIFO，一个块特殊文件或一个字符特殊文件，则此选项为此文件的本次打开操作和后续的IO操作设置为非阻塞方式
O_SYNC		同步操作。使每次write都等到物理IO操作完成

只有当flag为 O_CREAT 时才使用mode参数:
mode:
S_IRWXU  00700 user (file owner) has read, write and execute permission
S_IRUSR  00400 user has read permission
S_IWUSR  00200 user has write permission
S_IXUSR  00100 user has execute permission
S_IRWXG  00070 group has read, write and execute permission
S_IRGRP  00040 group has read permission
S_IWGRP  00020 group has write permission
S_IXGRP  00010 group has execute permission
S_IRWXO  00007 others have read, write and execute permission
S_IROTH  00004 others have read permission
S_IWOTH  00002 others have write permission
S_IXOTH  00001 others have execute permission
```



### 1.2 create

```c
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int creat(const char *pathname, mode_t mode);
```



### 1.3 close

### 1.4 lseek

### 1.5 read

### 1.6 write

### 1.7 dup

### 1.8  fcntl

### 1.9 ioctl

