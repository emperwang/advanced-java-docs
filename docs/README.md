# 目录

## 搭建本web浏览

* [doscify_github搭建](doscify_github搭建.md)

## JDK源码解析

### 并发编程锁

* [AQS概述](JDK/并发编程之锁/AQS-概述.md)
* [AQS之独占锁](JDK/并发编程之锁/AQS-独占锁(ReentrantLock).md)
* [AQS之共享锁](JDK/并发编程之锁/AQS共享锁(semaphore).md)
* [CountDownLatch分析](JDK/并发编程之锁/CountDownLatch.md)
* [ReentrantLock之Condition](JDK/并发编程之锁/ReentrantLock之condition使用.md)

### 线程及线程池

* [Thread解析(没有实现)](JDK/线程及线程池/Thread解析.md)
* [FutureTask](JDK/线程及线程池/FutureTask.md)
* [Executors](JDK/线程及线程池/Exceutors.md)
* [ThreadPoolExecutor](JDK/线程及线程池/ThreadPoolExecutor.md)
* [ForkJoinPool](JDK/线程及线程池/ForkJoinPool.md)
* [RecursiveAction(没有实现)](JDK/线程及线程池/RecursiveAction.md)
* [RecursiveTask(没有实现)](JDK/线程及线程池/RecursiveTask.md)
* [ForkJoinWorkerThread(没有实现)](JDK/线程及线程池/ForkJoinWorkerThread.md)
* [ForkJoinTask(没有实现)](JDK/线程及线程池/ForkJoinTask.md)

### 类加载器

- [ServiceLoader](JDK/类加载器/ServiceLoader.md)
- [ClassLoader](JDK/类加载器/ClassLoader.md)
- [Launcher](JDK/类加载器/Launcher.md)  
- [URLClassLoader](JDK/类加载器/URLClassLoader.md)
- [URLClassPath](JDK/类加载器/URLClassPath.md)
- [Class](JDK/类加载器/Class.md)

### Reflect

* [Constructor](JDK/reflect/Constructor.md)
* [Field](JDK/reflect/Field.md)
* [Method](JDK/reflect/Method.md)
* [Modifier](JDK/reflect/Modifier.md)
* [Parameter](JDK/reflect/Parameter.md)
* [Proxy](JDK/reflect/Proxy.md)

### NIO

* [Buffer](JDK/NIO/Buffer.md)
* [ByteBuffer](JDK/NIO/ByteBuffer.md)
* [ByteOrder](JDK/NIO/ByteOrder.md)
* [CharBuffer](JDK/NIO/CharBuffer.md)
* [ShortBuffer](JDK/NIO/ShortBuffer.md)
* [IntBuffer](JDK/NIO/IntBuffer.md)
* [FloatBuffer](JDK/NIO/FloatBuffer.md)
* [DoubleBuffer](JDK/NIO/DoubleBuffer.md)
* [LongBuffer](JDK/NIO/LongBuffer.md)
* [MappedByteBuffer](JDK/NIO/MappedByteBuffer.md)
* [Channels](JDK/NIO/channel/Channels.md)
* [FileChannel](JDK/NIO/channel/FileChannel.md)
* [FileChannelImpl](JDK/NIO/channel/FileChannelImpl.md)
* [Selector](JDK/NIO/channel/Selector.md)
* [SelectorImpl](JDK/NIO/channel/SelectorImpl.md)
* [WindowsSelectorImpl](JDK/NIO/channel/WindowsSelectorImpl.md)
* [SelectionKey](JDK/NIO/channel/SelectionKey.md)
* [SelectionKeyImpl](JDK/NIO/channel/SelectionKeyImpl.md)

### 容器

#### 非并发包

* [IdentityHashMap](JDK/容器/IdentityHashMap.md)
* [HashTable](JDK/容器/HashTable.md)
* [HashSet](JDK/容器/HashSet.md)
* [LinkedHashMap](JDK/容器/LinkedHashMap.md)
* [WeakHashMap](JDK/容器/WeakHashMap.md)
* [LinkedHashSet](JDK/容器/LinkedHashSet.md)
* [Properties](JDK/容器/Properties.md)
* [EnumMap](JDK/容器/EnumMap.md)
* [EnumSet](JDK/容器/EnumSet.md)
* [TreeMap](JDK/容器/TreeMap.md)
* [TreeSet](JDK/容器/TreeSet.md)
* [ArrayList](JDK/容器/ArrayList.md)
* [ArrayDeque](JDK/容器/ArrayDeque.md)
* [LinkedList](JDK/容器/LinkedList.md)
* [Vector](JDK/容器/Vector.md)

#### 并发包

* [ConcurrentLinkedQueue](JDK/并发容器/ConcurrentLinkedQueue.md)
* [LinkedBlockingDeque](JDK/并发容器/LinkedBlockingDeque.md)
* [ConcurrentHashMap](JDK/并发容器/ConcurrentHashMap.md)
* [CopyOnWriteArrayList](JDK/并发容器/CopyOnWriteArrayList.md)
* [CopyOnWriteArraySet](JDK/并发容器/CopyOnWriteArraySet.md)
* [LinkedBlockingQueue](JDK/并发容器/LinkedBlockingQueue.md)
* [LinkedTransferQueue](JDK/并发容器/LinkedTransferQueue.md)
* [ArrayBlockingQueue](JDK/并发容器/ArrayBlockingQueue.md)
* [DelayQueue](JDK/并发容器/DelayQueue.md)
* [SynchronousQueue](JDK/并发容器/SynchronousQueue.md)

#### 引用

* [Reference示例](JDK/reference/Reference的使用.md)
* [Reference](JDK/reference/Reference.md)
* [ReferenceQueue](JDK/reference/ReferenceQueue.md)

### IO

* [File](JDK/IO/File.md)
* [FileDescriptor](JDK/IO/FileDescriptor.md)
* [InputStream](JDK/IO/InputStream/InputStream.md)
* [FilterInputStream](JDK/IO/InputStream/FilterInputStream.md)
  * [BufferedInputStream](JDK/IO/InputStream/FilterInputStream/BufferedInputStream.md)
  * [DataInputStream](JDK/IO/InputStream/FilterInputStream/DataInputStream.md)
  * [LineNumberInputStream](JDK/IO/InputStream/FilterInputStream/LineNumberInputStream.md)
  * [PushbackInputStream](JDK/IO/InputStream/FilterInputStream/PushbackInputStream.md)
* [SequenceInputStream](JDK/IO/InputStream/SequenceInputStream.md)
* [ByteArrayInputStream](JDK/IO/InputStream/ByteArrayInputStream.md)
* [FileInputStream](JDK/IO/InputStream/FileInputStream.md)
* [PipedInputStream](JDK/IO/InputStream/PipedInputStream.md)
* [ByteArrayOutputStream](JDK/IO/OuputStream/ByteArrayOutputStream.md)
* [FileOutputStream](JDK/IO/OuputStream/FileOutputStream.md)
* [FilterOutputStream](JDK/IO/OuputStream/FilterOutputStream.md)
  * [BufferedOutputStream](JDK/IO/OuputStream/FilterOutputStream/BufferedOutputStream.md)
  * [DataOutputStream](JDK/IO/OuputStream/FilterOutputStream/DataOutputStream.md)
  * [PrintStream](JDK/IO/OuputStream/FilterOutputStream/PrintStream.md)
* [Reader](JDK/IO/Reader/Reader.md)
* [BufferedReader](JDK/IO/Reader/BufferedReader.md)
* [CharArrayReader](JDK/IO/Reader/CharArrayReader.md)
* [FilterReader](JDK/IO/Reader/FilterReader.md)
* [InputStreamReader](JDK/IO/Reader/InputStreamReader.md)
* [PipedReader](JDK/IO/Reader/PipedReader.md)
* [StringReader](JDK/IO/Reader/StringReader.md)
* [PipedWriter](JDK/IO/Writer/PipedWriter.md)
* [BufferedWriter](JDK/IO/Writer/BufferedWriter.md)
* [CharArrayWriter](JDK/IO/Writer/CharArrayWriter.md)
* [FilterWriter](JDK/IO/Writer/FilterWriter.md)
* [OutputStreamWriter](JDK/IO/Writer/OutputStreamWriter.md)
* [PrintWriter](JDK/IO/Writer/PrintWriter.md)
* [StringWriter](JDK/IO/Writer/StringWriter.md)

### Atomic

* [AtomicInteger](JDK/Atomic/AtomicInteger.md)
* [AtomicIntegerFieldUpdater](JDK/Atomic/AtomicIntegerFieldUpdater.md)
* [AtomicReference](JDK/Atomic/AtomicReference.md)
* [AtomicMarkableReference](JDK/Atomic/AtomicMarkableReference.md)
* [AtomicStampedReference](JDK/Atomic/AtomicStampedReference.md)
* [DoubleAccumulator(没有实现)](JDK/Atomic/DoubleAccumulator.md)
* [DoubleAdder(没有实现)](JDK/Atomic/DoubleAdder.md)

### net

* [socket](JDK/net/Socket.md)
* [SocketImpl](JDK/net/SocketImpl.md)
* [AbstractPlainSocketImpl](JDK/net/AbstractPlainSocketImpl.md)
* [PlainSocketImpl](JDK/net/PlainSocketImpl.md)
* [DualStackPlainSocketImpl](JDK/net/DualStackPlainSocketImpl.md)
* [TwoStacksPlainSocketImpl](JDK/net/TwoStacksPlainSocketImpl.md)
* [SocketInputStream](JDK/net/SocketInputStream.md)
* [SocketOutputStream](JDK/net/SocketOutputStream.md)

## spring

* [springboot启动流程分析一(总流程分析)](Spring/springboot启动分析一.md)
* [springboot启动流程分析二(实例化初始化类和监听器)](Spring/springboot启动分析二.md)
* [springboot启动流程分析三(调用listener处理ApplicationStartingEvent事件)](Spring/springboot启动分析三.md)
* [springboot启动流程分析四(准备environment)](Spring/springboot启动分析四.md)
* [springboot启动流程分析五(没有实现)](Spring/springboot启动分析五.md)
* [springboot启动流程分析六(没有实现)](Spring/springboot启动分析六.md)
* [springboot启动流程分析七(没有实现)](Spring/springboot启动分析七.md)
* [springboot启动流程分析八(没有实现)](Spring/springboot启动分析八.md)

## JVM

* [JVM-index](JVM/0-index.md)

## Docker

* [docker安装](docker-安装.md)
* [镜像管理](镜像管理.md)
* [容器管理](容器管理.md)
* [数据卷管理](数据卷管理.md)
* [dockerfile-cmd](dockerfile-cmd.md)
* [Docker_network](Docker_network.md)
* [Docker_security](Docker_security.md)
* [ubuntu_sshd镜像](ubuntu_sshd镜像.md)
* [Docker-machine(没有实现)](Docker-machine.md)
* [Docker-swarm(没有实现)](Docker-swarm.md)

## 数据库
### postgresql

* [postgresql-command](database/postgresql/postgresql-command.md)

### MySql

- [MySql-Command](database/Mysql/MySql-Command.md)
- [MySQl-function-procedure](database/Mysql/MySQl-function-procedure.md)
- [MySQL-lock](database/Mysql/MySQL-lock.md)
- [MySQl-transaction-lock](database/Mysql/MySQl-transaction-lock.md)
- [SQL-Statement-优化](database/Mysql/SQL-Statement-优化.md)

## HTTPS

* [generateKey](https/generateKey.sh)
* [make-certificate](https/make-certificate.md)
* [1-SSL-TLS协议简介](1-SSL-TLS协议简介.md)
* [wireShark解析https报文](https/wireShark解析https报文.md)

## Java_command

* [记录JDB调试程序](记录JDB调试程序.md)

## maven

* [0-maven-lifecycle](maven/plugins/0-maven-lifecycle.md)
* [1-maven-resources](1-maven-resources.md)
* [2-maven-surefire](2-maven-surefire.md)
* [3-maven-jar](3-maven-jar.md)
* [4-maven-dependency](4-maven-dependency.md)
* [5-maven-shade](5-maven-shade.md)
* [6-maven-assembly](6-maven-assembly.md)
* [6-maven-assembly-example](6-maven-assembly-example.md)
* [7-maven-springboot-plugins](7-maven-springboot-plugins.md)



## mybatis

* [0-mybatis概述](0-mybatis概述.md)
* [1配置文件解析](1配置文件解析.md)
* [2-接口和xml文件的对应关系](2-接口和xml文件的对应关系.md)
* [3-一个接口函数的执行流程](3-一个接口函数的执行流程.md)
* [4-sql参数的配置](4-sql参数的配置.md)
* [5-连接池](5-连接池.md)
* [6-事务管理](6-事务管理.md)
* [7-查询结果如何映射到java类中](7-查询结果如何映射到java类中.md)


## other

* [自动更新配置文件](Java/自动更新配置文件.md)

### logBack

- [logback初始化](other/logback/logback初始化.md)
- [getLogger操作](other/logback/getLogger操作.md)
- [Log打印](other/logback/Log打印.md)

### kafka

- [kafka集群模式安装](other/kafka/kafka集群模式安装.md)

### nginx

- [Nginx-install](other/nginx/Nginx-install.md)

### redis

- [redis集群模式安装](other/redis/redis集群模式安装.md)

### zookeeper

- [zookeeper集群模式安装](other/zookeeper/zookeeper集群模式安装.md) 



## python

* [0-index](python/0-index.md)