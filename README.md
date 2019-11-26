# 目录

## 搭建本web浏览

* [doscify_github搭建](docs/doscify_github搭建.md)

## JDK源码解析

### 并发编程锁

* [AQS概述](docs/JDK/并发编程之锁/AQS-概述.md)

* [AQS之独占锁](docs/JDK/并发编程之锁/AQS-独占锁(ReentrantLock).md)

- [AQS之共享锁](docs/JDK/并发编程之锁/AQS共享锁(semaphore).md)
- [CountDownLatch分析](docs/JDK/并发编程之锁/CountDownLatch.md)
- [ReentrantLock之Condition](docs/JDK/并发编程之锁/ReentrantLock之condition使用.md)

### 线程及线程池

- [Thread解析(没有实现)](docs/JDK/线程及线程池/Thread解析.md)
- [FutureTask](docs/JDK/线程及线程池/FutureTask.md)
- [Executors(实现不完整)](docs/JDK/线程及线程池/Exceutors.md)
- [ThreadPoolExecutor](docs/JDK/线程及线程池/ThreadPoolExecutor.md)
- [ForkJoinPool](docs/JDK/线程及线程池/ForkJoinPool.md)
- [RecursiveAction(没有实现)](docs/JDK/线程及线程池/RecursiveAction.md)
- [RecursiveTask(没有实现)](docs/JDK/线程及线程池/RecursiveTask.md)
- [ForkJoinWorkerThread(没有实现)](docs/JDK/线程及线程池/ForkJoinWorkerThread.md)
- [ForkJoinTask(没有实现)](docs/JDK/线程及线程池/ForkJoinTask.md)

### 类加载器

* [ServiceLoader](docs/JDK/类加载器/ServiceLoader.md)
* [ClassLoader](docs/JDK/类加载器/ClassLoader.md)
* [Launcher](docs/JDK/类加载器/Launcher.md)  
* [URLClassLoader](docs/JDK/类加载器/URLClassLoader.md)
* [URLClassPath](docs/JDK/类加载器/URLClassPath.md)
* [Class](docs/JDK/类加载器/Class.md)

### Reflect

- [Constructor](docs/JDK/reflect/Constructor.md)
- [Field](docs/JDK/reflect/Field.md)
- [Method](docs/JDK/reflect/Method.md)
- [Modifier](docs/JDK/reflect/Modifier.md)
- [Parameter](docs/JDK/reflect/Parameter.md)
- [Proxy](docs/JDK/reflect/Proxy.md)

### NIO

* [Buffer](docs/JDK/NIO/Buffer.md)
* [ByteBuffer](docs/JDK/NIO/ByteBuffer.md)
* [ByteOrder](docs/JDK/NIO/ByteOrder.md)
* [CharBuffer](docs/JDK/NIO/CharBuffer.md)
* [ShortBuffer](docs/JDK/NIO/ShortBuffer.md)
* [IntBuffer](docs/JDK/NIO/IntBuffer.md)
* [FloatBuffer](docs/JDK/NIO/FloatBuffer.md)
* [DoubleBuffer](docs/JDK/NIO/DoubleBuffer.md)
* [LongBuffer](docs/JDK/NIO/LongBuffer.md)
* [MappedByteBuffer](docs/JDK/NIO/MappedByteBuffer.md)

### 容器

#### 非并发包

* [IdentityHashMap](docs/JDK/容器/IdentityHashMap.md)
* [HashTable](docs/JDK/容器/HashTable.md)
* [HashSet](docs/JDK/容器/HashSet.md)
* [LinkedHashMap](docs/JDK/容器/LinkedHashMap.md)
* [WeakHashMap](docs/JDK/容器/WeakHashMap.md)
* [LinkedHashSet](docs/JDK/容器/LinkedHashSet.md)
* [Properties](docs/JDK/容器/Properties.md)
* [EnumMap](docs/JDK/容器/EnumMap.md)
* [EnumSet](docs/JDK/容器/EnumSet.md)
* [TreeMap](docs/JDK/容器/TreeMapmd)
* [TreeSet](docs/JDK/容器/TreeSet.md)
* [ArrayList](docs/JDK/容器/ArrayList.md)
* [ArrayDeque](docs/JDK/容器/ArrayDeque.md)
* [LinkedList](docs/JDK/容器/LinkedList.md)
* [Vector](docs/JDK/容器/Vector.md)

#### 并发包

* [ConcurrentLinkedQueue](docs/JDK/并发容器/ConcurrentLinkedQueue.md)
* [LinkedBlockingDeque](docs/JDK/并发容器/LinkedBlockingDeque.md)
* [ConcurrentHashMap](docs/JDK/并发容器/ConcurrentHashMap.md)
* [CopyOnWriteArrayList](docs/JDK/并发容器/CopyOnWriteArrayList.md)
* [CopyOnWriteArraySet](docs/JDK/并发容器/CopyOnWriteArraySet.md)
* [LinkedBlockingQueue](docs/JDK/并发容器/LinkedBlockingQueue.md)
* [LinkedTransferQueue](docs/JDK/并发容器/LinkedTransferQueue.md)
* [ArrayBlockingQueue](docs/JDK/并发容器/ArrayBlockingQueue.md)
* [DelayQueue](docs/JDK/并发容器/DelayQueue.md)
* [SynchronousQueue](docs/JDK/并发容器/SynchronousQueue.md)

#### 引用

* [Reference示例](docs/JDK/reference/Reference的使用.md)
* [Reference](docs/JDK/reference/Reference.md)
* [ReferenceQueue](docs/JDK/reference/ReferenceQueue.md)
* [AtomicMarkableReference](JDK/Atomic/AtomicMarkableReference.md)
* [AtomicStampedReference](JDK/Atomic/AtomicStampedReference.md)
### IO

* [File](docs/JDK/IO/File.md)
* [FileDescriptor](docs/JDK/IO/FileDescriptor.md)
* [InputStream](docs/JDK/IO/InputStream/InputStream.md)
* [FilterInputStream](docs/JDK/IO/InputStream/FilterInputStream.md)
  * [BufferedInputStream](docs/JDK/IO/InputStream/FilterInputStream/BufferedInputStream.md)
  * [DataInputStream](docs/JDK/IO/InputStream/FilterInputStream/DataInputStream.md)
  * [LineNumberInputStream](docs/JDK/IO/InputStream/FilterInputStream/LineNumberInputStream.md)
  * [PushbackInputStream](docs/JDK/IO/InputStream/FilterInputStream/PushbackInputStream.md)
* [SequenceInputStream](docs/JDK/IO/InputStream/SequenceInputStream.md)
* [ByteArrayInputStream](docs/JDK/IO/InputStream/ByteArrayInputStream.md)
* [FileInputStream](docs/JDK/IO/InputStream/FileInputStream.md)
* [PipedInputStream](docs/JDK/IO/InputStream/PipedInputStream.md)
* [ByteArrayOutputStream](docs/JDK/IO/OuputStream/ByteArrayOutputStream.md)
* [FileOutputStream](docs/JDK/IO/OuputStream/FileOutputStream.md)
* [FilterOutputStream](docs/JDK/IO/OuputStream/FilterOutputStream.md)
  * [BufferedOutputStream](docs/JDK/IO/OuputStream/FilterOutputStream/BufferedOutputStream.md)
  * [DataOutputStream](docs/JDK/IO/OuputStream/FilterOutputStream/DataOutputStream.md)
  * [PrintStream](docs/JDK/IO/OuputStream/FilterOutputStream/PrintStream.md)
* [Reader](docs/JDK/IO/Reader/Reader.md)
* [BufferedReader](docs/JDK/IO/Reader/BufferedReader.md)
* [CharArrayReader](docs/JDK/IO/Reader/CharArrayReader.md)
* [FilterReader](docs/JDK/IO/Reader/FilterReader.md)
* [InputStreamReader](docs/JDK/IO/Reader/InputStreamReader.md)
* [PipedReader](docs/JDK/IO/Reader/PipedReader.md)
* [StringReader](docs/JDK/IO/Reader/StringReader.md)
* [PipedWriter](docs/JDK/IO/Writer/PipedWriter.md)
* [BufferedWriter](docs/JDK/IO/Writer/BufferedWriter.md)
* [CharArrayWriter](docs/JDK/IO/Writer/CharArrayWriter.md)
* [FilterWriter](docs/JDK/IO/Writer/FilterWriter.md)
* [OutputStreamWriter](docs/JDK/IO/Writer/OutputStreamWriter.md)
* [PrintWriter](docs/JDK/IO/Writer/PrintWriter.md)
* [StringWriter](docs/JDK/IO/Writer/StringWriter.md)

### Atomic

* [AtomicInteger](docs/JDK/Atomic/AtomicInteger.md)
* [AtomicIntegerFieldUpdater](docs/JDK/Atomic/AtomicIntegerFieldUpdater.md)
* [AtomicReference](docs/JDK/Atomic/AtomicReference.md)
* [AtomicMarkableReference](docs/JDK/Atomic/AtomicMarkableReference.md)
* [AtomicStampedReference](docs/JDK/Atomic/AtomicStampedReference.md)
* [DoubleAccumulator](docs/JDK/Atomic/DoubleAccumulator.md)
* [DoubleAdder](docs/JDK/Atomic/DoubleAdder.md)

### net

* [socket](docs/JDK/net/Socket.md)
* [SocketImpl](docs/JDK/net/SocketImpl.md)
* [AbstractPlainSocketImpl](docs/JDK/net/AbstractPlainSocketImpl.md)
* [PlainSocketImpl](docs/JDK/net/PlainSocketImpl.md)
* [DualStackPlainSocketImpl](docs/JDK/net/DualStackPlainSocketImpl.md)
* [TwoStacksPlainSocketImpl](docs/JDK/net/TwoStacksPlainSocketImpl.md)
* [SocketInputStream](docs/JDK/net/SocketInputStream.md)
* [SocketOutputStream](docs/JDK/net/SocketOutputStream.md)

## Spring

* [springboot启动流程分析一(总流程分析)](docs/Spring/springboot启动分析一.md)
* [springboot启动流程分析二(实例化初始化类和监听器)](docs/Spring/springboot启动分析二.md)
* [springboot启动流程分析三(调用listener处理ApplicationStartingEvent事件)](docs/Spring/springboot启动分析三.md)
* [springboot启动流程分析四(准备environment)](docs/Spring/springboot启动分析四.md)
* [springboot启动流程分析五(没有实现)](docs/Spring/springboot启动分析五.md)
* [springboot启动流程分析六(没有实现)](docs/Spring/springboot启动分析六.md)
* [springboot启动流程分析七(没有实现)](docs/Spring/springboot启动分析七.md)
* [springboot启动流程分析八(没有实现)](docs/Spring/springboot启动分析八.md)



## JVM

* [垃圾收集器](docs/JVM/垃圾收集器.md)
* [CMS收集介绍](docs/JVM/CMS收集介绍.md)
* [G1收集器](docs/JVM/G1收集介绍.md)
* [JVM内存区](docs/JVM/JVM内存区.md)
* [类加载阶段解析](docs/JVM/类加载阶段解析.md)
* [HotSpot栈帧组成](docs/JVM/HotSpot栈帧组成.md)
* [JVM字节码](docs/JVM/JVM字节码.md)

## Docker

* [docker安装](docs/docker/docker-安装.md)
* [镜像管理](docs/docker/镜像管理.md)
* [容器管理](docs/docker/容器管理.md)
* [数据卷管理](docs/docker/数据卷管理.md)
* [dockerfile-cmd](docs/docker/dockerfile-cmd.md)
* [Docker_network](docs/docker/Docker_network.md)
* [Docker_security](docs/docker/Docker_security.md)
* [ubuntu_sshd镜像](docs/docker/ubuntu_sshd镜像.md)
* [Docker-machine(没有实现)](docs/docker/Docker-machine.md)
* [Docker-swarm(没有实现)](docs/docker/Docker-swarm.md)

## 数据库

### postgresql

- [postgresql-command](docs/database/postgresql/postgresql-command.md)

### MySql

* [MySql-Command](docs/database/Mysql/MySql-Command.md)
* [MySQl-function-procedure](docs/database/Mysql/MySQl-function-procedure.md)
* [MySQL-lock](docs/database/Mysql/MySQL-lock.md)
* [MySQl-transaction-lock](docs/database/Mysql/MySQl-transaction-lock.md)
* [SQL-Statement-优化](docs/database/Mysql/SQL-Statement-优化.md)

## HTTPS

- [generateKey](docs/https/generateKey.sh)
- [make-certificate](docs/https/make-certificate.md)
- [SSL-TLS协议简介](docs/https/SSL-TLS协议简介.md)
- [wireShark解析https报文](docs/https/wireShark解析https报文.md)

## Java_command

- [记录JDB调试程序](docs/java_command/记录JDB调试程序.md)

## maven

- [0-maven-lifecycle](docs/maven/plugins/0-maven-lifecycle.md)
- [1-maven-resources](docs/maven/plugins/1-maven-resources.md)
- [2-maven-surefire](docs/maven/plugins/2-maven-surefire.md)
- [3-maven-jar](docs/maven/plugins/3-maven-jar.md)
- [4-maven-dependency](docs/maven/plugins/4-maven-dependency.md)
- [5-maven-shade](docs/maven/plugins/5-maven-shade.md)
- [6-maven-assembly](docs/maven/plugins/6-maven-assembly.md)
- [6-maven-assembly-example](docs/maven/plugins/6-maven-assembly-example.md)
- [7-maven-springboot-plugins](docs/maven/plugins/7-maven-springboot-plugins.md)



## mybatis

- [0-mybatis概述](docs/mybatis/0-mybatis概述.md)
- [1配置文件解析](docs/mybatis/1配置文件解析.md)
- [2-接口和xml文件的对应关系](docs/mybatis/2-接口和xml文件的对应关系.md)
- [3-一个接口函数的执行流程](docs/mybatis/3-一个接口函数的执行流程.md)
- [4-sql参数的配置](docs/mybatis/4-sql参数的配置.md)
- [5-连接池](docs/mybatis/5-连接池.md)
- [6-事务管理](docs/mybatis/6-事务管理.md)
- [7-查询结果如何映射到java类中](docs/mybatis/7-查询结果如何映射到java类中.md)

## other

* [自动更新配置文件](docs/other/自动更新配置文件.md)

### logBack

* [logback初始化](docs/other/logback/logback初始化.md)
* [getLogger操作](docs/other/logback/getLogger操作.md)
* [Log打印](docs/other/logback/Log打印.md)

### kafka

* [kafka集群模式安装](docs/other/kafka/kafka集群模式安装.md)

### nginx

* [Nginx-install](docs/other/nginx/Nginx-install.md)

### redis

* [redis集群模式安装](docs/other/redis/redis集群模式安装.md)

### zookeeper

* [zookeeper集群模式安装](docs/other/zookeeper/zookeeper集群模式安装.md) 

## python

* [python-index](docs/python/0-index.md)