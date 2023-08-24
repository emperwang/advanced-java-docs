[TOC]

# zkServer script

项目中一直在使用zk作为中间件来提供服务，现在想深入了解一下其原理；server间是如何同步数据，又是什么情况下发生了脑裂，为什么会有脑裂.... 种种疑问，那就看一下其实现把。

想看其实现，那么如何入手呢？

还是先从脚本作为入手点，看其实如何启动的，之后又是如何初始化等操作。

此次是使用3.5.7版本进行分析。

先看server的启动脚本吧。

```shell
#!/usr/bin/env bash
# use POSTIX interface, symlink is followed automatically
## 获取脚本名称
ZOOBIN="${BASH_SOURCE-$0}"
## 获取脚本所在目录
ZOOBIN="$(dirname "${ZOOBIN}")"
# 获取脚本的全目录
ZOOBINDIR="$(cd "${ZOOBIN}"; pwd)"
## 如果存在 zkEnv 则先执行此zkEnv脚本
if [ -e "$ZOOBIN/../libexec/zkEnv.sh" ]; then
  . "$ZOOBINDIR/../libexec/zkEnv.sh"
else
  . "$ZOOBINDIR/zkEnv.sh"
fi

# See the following page for extensive details on setting
# up the JVM to accept JMX remote management:
# http://java.sun.com/javase/6/docs/technotes/guides/management/agent.html
# by default we allow local JMX connections
# 是否开启了JMX
if [ "x$JMXLOCALONLY" = "x" ]
then
    JMXLOCALONLY=false
fi

if [ "x$JMXDISABLE" = "x" ] || [ "$JMXDISABLE" = 'false' ]
then
  echo "ZooKeeper JMX enabled by default" >&2
  if [ "x$JMXPORT" = "x" ]
  then
    # for some reason these two options are necessary on jdk6 on Ubuntu
    #   accord to the docs they are not necessary, but otw jconsole cannot
    #   do a local attach
    # zk的JMX设置
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=$JMXLOCALONLY org.apache.zookeeper.server.quorum.QuorumPeerMain"
  else
    if [ "x$JMXAUTH" = "x" ]
    then
      JMXAUTH=false
    fi
    if [ "x$JMXSSL" = "x" ]
    then
      JMXSSL=false
    fi
    if [ "x$JMXLOG4J" = "x" ]
    then
      JMXLOG4J=true
    fi
    echo "ZooKeeper remote JMX Port set to $JMXPORT" >&2
    echo "ZooKeeper remote JMX authenticate set to $JMXAUTH" >&2
    echo "ZooKeeper remote JMX ssl set to $JMXSSL" >&2
    echo "ZooKeeper remote JMX log4j set to $JMXLOG4J" >&2
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMXPORT -Dcom.sun.management.jmxremote.authenticate=$JMXAUTH -Dcom.sun.management.jmxremote.ssl=$JMXSSL -Dzookeeper.jmx.log4j.disable=$JMXLOG4J org.apache.zookeeper.server.quorum.QuorumPeerMain"
  fi
else
    echo "JMX disabled by user request" >&2
    ZOOMAIN="org.apache.zookeeper.server.quorum.QuorumPeerMain"
fi
# JVM 
if [ "x$SERVER_JVMFLAGS"  != "x" ]
then
    JVMFLAGS="$SERVER_JVMFLAGS $JVMFLAGS"
fi
# config文件的设置
if [ "x$2" != "x" ]
then
    ZOOCFG="$ZOOCFGDIR/$2"
fi

# if we give a more complicated path to the config, don't screw around in $ZOOCFGDIR
if [ "x$(dirname "$ZOOCFG")" != "x$ZOOCFGDIR" ]
then
    ZOOCFG="$2"
fi
# 对cygwin的匹配处理
if $cygwin
then
    ZOOCFG=`cygpath -wp "$ZOOCFG"`
    # cygwin has a "kill" in the shell itself, gets confused
    KILL=/bin/kill
else
    KILL=kill
fi

echo "Using config: $ZOOCFG" >&2

case "$OSTYPE" in
*solaris*)
  GREP=/usr/xpg4/bin/grep
  ;;
*)
  GREP=grep
  ;;
esac
# pid存储文件的创建
if [ -z "$ZOOPIDFILE" ]; then
	# 如果还不存在 dataDir(配置文件中配置),那么就创建此目录
    ZOO_DATADIR="$($GREP "^[[:space:]]*dataDir" "$ZOOCFG" | sed -e 's/.*=//')"
    if [ ! -d "$ZOO_DATADIR" ]; then
        mkdir -p "$ZOO_DATADIR"
    fi
    # 记录pid的文件
    ZOOPIDFILE="$ZOO_DATADIR/zookeeper_server.pid"
else
    # ensure it exists, otw stop will fail
    mkdir -p "$(dirname "$ZOOPIDFILE")"
fi
# log目录存在且可写,取反; 则创建 log目录
if [ ! -w "$ZOO_LOG_DIR" ] ; then
mkdir -p "$ZOO_LOG_DIR"
fi
# zookeeper线程的输出
_ZOO_DAEMON_OUT="$ZOO_LOG_DIR/zookeeper.out"

# 根据不同命令的处理; 启动  停止  状态
case $1 in
start)
    echo  -n "Starting zookeeper ... "
    # 检测pid文件是否存在
    if [ -f "$ZOOPIDFILE" ]; then	# kill -0 检测进程是否存在
      if kill -0 `cat "$ZOOPIDFILE"` > /dev/null 2>&1; then
         echo $command already running as process `cat "$ZOOPIDFILE"`. 
         exit 0
      fi
    fi
    # 启动
    nohup "$JAVA" "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" "-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}" \
    -cp "$CLASSPATH" $JVMFLAGS $ZOOMAIN "$ZOOCFG" > "$_ZOO_DAEMON_OUT" 2>&1 < /dev/null &
    # 启动没有问题,则记录启动进程的id号
    if [ $? -eq 0 ]
    then
      case "$OSTYPE" in
      *solaris*)
        /bin/echo "${!}\\c" > "$ZOOPIDFILE"
        ;;
      *)
        /bin/echo -n $! > "$ZOOPIDFILE"
        ;;
      esac
      if [ $? -eq 0 ];
      then
        sleep 1
        echo STARTED
      else
        echo FAILED TO WRITE PID
        exit 1
      fi
    else
      echo SERVER DID NOT START
      exit 1
    fi
    ;;
start-foreground)
    ZOO_CMD=(exec "$JAVA")
    if [ "${ZOO_NOEXEC}" != "" ]; then
      ZOO_CMD=("$JAVA")
    fi
    # 前台启动
    "${ZOO_CMD[@]}" "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" "-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}" \
    -cp "$CLASSPATH" $JVMFLAGS $ZOOMAIN "$ZOOCFG"
    ;;
print-cmd)    # 打印命令
    echo "\"$JAVA\" -Dzookeeper.log.dir=\"${ZOO_LOG_DIR}\" -Dzookeeper.root.logger=\"${ZOO_LOG4J_PROP}\" -cp \"$CLASSPATH\" $JVMFLAGS $ZOOMAIN \"$ZOOCFG\" > \"$_ZOO_DAEMON_OUT\" 2>&1 < /dev/null"
    ;;
stop)  # 停止操作
    echo -n "Stopping zookeeper ... "
    # 如果文件不存在,则报错
    if [ ! -f "$ZOOPIDFILE" ]
    then
      echo "no zookeeper to stop (could not find file $ZOOPIDFILE)"
    else	# 文件存在,则停止文件中记录的id对应的进程
      $KILL -9 $(cat "$ZOOPIDFILE")
      rm "$ZOOPIDFILE"
      echo STOPPED
    fi
    exit 0
    ;;
upgrade)
    shift
    echo "upgrading the servers to 3.*"
    "$JAVA" "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" "-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}" \
    -cp "$CLASSPATH" $JVMFLAGS org.apache.zookeeper.server.upgrade.UpgradeMain ${@}
    echo "Upgrading ... "
    ;;
restart)	# 重启操作
    shift
    "$0" stop ${@}
    sleep 3
    "$0" start ${@}
    ;;
status)	# 状态查看
    # -q is necessary on some versions of linux where nc returns too quickly, and no stat result is output
    clientPortAddress=`$GREP "^[[:space:]]*clientPortAddress[^[:alpha:]]" "$ZOOCFG" | sed -e 's/.*=//'`
    if ! [ $clientPortAddress ]
    then
	clientPortAddress="localhost"
    fi
    clientPort=`$GREP "^[[:space:]]*clientPort[^[:alpha:]]" "$ZOOCFG" | sed -e 's/.*=//'`
    STAT=`"$JAVA" "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" "-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}" \
             -cp "$CLASSPATH" $JVMFLAGS org.apache.zookeeper.client.FourLetterWordMain \
             $clientPortAddress $clientPort srvr 2> /dev/null    \
          | $GREP Mode`
    if [ "x$STAT" = "x" ]
    then
        echo "Error contacting service. It is probably not running."
        exit 1
    else
        echo $STAT
        exit 0
    fi
    ;;
*)	# 帮助信息
    echo "Usage: $0 {start|start-foreground|stop|restart|status|upgrade|print-cmd}" >&2
esac
```

看一下zkEnv脚本

```shell
#!/usr/bin/env bash
# zk的bin目录
ZOOBINDIR="${ZOOBINDIR:-/usr/bin}"
# 设置一个前缀，此目录表示 zk目录中bin目录的上层目录
ZOOKEEPER_PREFIX="${ZOOBINDIR}/.."
# 获取命令行参数指定的 配置文件
if [ $# -gt 1 ]
then
    if [ "--config" = "$1" ]
	  then
	      shift
	      confdir=$1
	      shift
	      ZOOCFGDIR=$confdir
    fi
fi

# 是否设置了ZOOCFGDIR;没有则进行配置
if [ "x$ZOOCFGDIR" = "x" ]
then	# 没有配置呢,就是用zk目录中的conf作为配置文件的目录
  if [ -e "${ZOOKEEPER_PREFIX}/conf" ]; then
    ZOOCFGDIR="$ZOOBINDIR/../conf"
  else	# 如果配置了ZOOCFGDIR,则使用配置的
    ZOOCFGDIR="$ZOOBINDIR/../etc/zookeeper"
  fi
fi
# 如果存在zookeeper-env这个脚本,则执行一次
if [ -f "${ZOOCFGDIR}/zookeeper-env.sh" ]; then
  . "${ZOOCFGDIR}/zookeeper-env.sh"
fi
# 默认的配置文件为 zoo.cfg
if [ "x$ZOOCFG" = "x" ]
then
    ZOOCFG="zoo.cfg"
fi
# 配置文件的全路径
ZOOCFG="$ZOOCFGDIR/$ZOOCFG"
# 如果存在java.env文件,则执行一次
if [ -f "$ZOOCFGDIR/java.env" ]
then
    . "$ZOOCFGDIR/java.env"
fi
# 此处是设置日志目录,默认为当前目录; 换句话说, 在哪里启动zk,就在哪里生成日志文件
# 一般情况下,会做修改
if [ "x${ZOO_LOG_DIR}" = "x" ]
then
	# 修改后: ZOO_LOG_DIR="$ZOOKEEPER_PREFIX/logs/"
    ZOO_LOG_DIR="."
fi
# log4j的配置
if [ "x${ZOO_LOG4J_PROP}" = "x" ]
then
    ZOO_LOG4J_PROP="INFO,CONSOLE"
fi
# java_home的配置
if [ "$JAVA_HOME" != "" ]; then
  JAVA="$JAVA_HOME/bin/java"
else
  JAVA=java
fi

#add the zoocfg dir to classpath
CLASSPATH="$ZOOCFGDIR:$CLASSPATH"
# 添加依赖包到 classpath
for i in "$ZOOBINDIR"/../zookeeper-server/src/main/resources/lib/*.jar
do
    CLASSPATH="$i:$CLASSPATH"
done

#make it work in the binary package
#(use array for LIBPATH to account for spaces within wildcard expansion)
## 添加zookeeper*.jar包到classpath,以及设置 libpath
if [ -e "${ZOOKEEPER_PREFIX}"/share/zookeeper/zookeeper-*.jar ]; then
  LIBPATH=("${ZOOKEEPER_PREFIX}"/share/zookeeper/*.jar)
else
  #release tarball format
  for i in "$ZOOBINDIR"/../zookeeper-*.jar
  do
    CLASSPATH="$i:$CLASSPATH"
  done
  LIBPATH=("${ZOOBINDIR}"/../lib/*.jar)
fi
# 把libpath中的jar包添加到  classpath
for i in "${LIBPATH[@]}"
do
    CLASSPATH="$i:$CLASSPATH"
done

#make it work for developers
for d in "$ZOOBINDIR"/../build/lib/*.jar
do
   CLASSPATH="$d:$CLASSPATH"
done

for d in "$ZOOBINDIR"/../zookeeper-server/target/lib/*.jar
do
   CLASSPATH="$d:$CLASSPATH"
done

#make it work for developers
CLASSPATH="$ZOOBINDIR/../build/classes:$CLASSPATH"

#make it work for developers
CLASSPATH="$ZOOBINDIR/../zookeeper-server/target/classes:$CLASSPATH"

case "`uname`" in
    CYGWIN*) cygwin=true ;;
    *) cygwin=false ;;
esac

if $cygwin
then
    CLASSPATH=`cygpath -wp "$CLASSPATH"`
fi

```



执行过程

```shell
[root@name2 bin]# sh -x zkServer.sh start 
+ '[' x = x ']'
+ JMXLOCALONLY=false
+ '[' x = x ']'
+ echo 'JMX enabled by default'
JMX enabled by default
+ ZOOMAIN='-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain'
+ ZOOBIN=zkServer.sh
++ dirname zkServer.sh
+ ZOOBIN=.
++ cd .
++ pwd
+ ZOOBINDIR=/mnt/zookeeper-3.4.5-cdh5.12.0/bin
+ '[' -e ./../libexec/zkEnv.sh ']'
+ . /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../libexec/zkEnv.sh
++ ZOOBINDIR=/mnt/zookeeper-3.4.5-cdh5.12.0/bin
++ ZOOKEEPER_PREFIX=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/..
++ '[' x = x ']'
++ '[' -e /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf ']'
++ ZOOCFGDIR=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf
++ '[' -f /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zookeeper-env.sh ']'
++ '[' x = x ']'
++ ZOOCFG=zoo.cfg
++ ZOOCFG=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
++ '[' -f /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/java.env ']'
++ '[' x = x ']'
++ ZOO_LOG_DIR=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../logs
++ '[' x = x ']'
++ ZOO_LOG4J_PROP=INFO,CONSOLE
++ '[' /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64 '!=' '' ']'
++ JAVA=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java
++ CLASSPATH=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:
++ for i in '"$ZOOBINDIR"/../src/java/lib/*.jar'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ '[' -e /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/zookeeper-3.4.5-cdh5.12.0.jar ']'
++ LIBPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/*.jar'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-log4j12-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for i in '${LIBPATH}'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/zookeeper-3.4.5-cdh5.12.0.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-log4j12-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ for d in '"$ZOOBINDIR"/../build/lib/*.jar'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../build/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/zookeeper-3.4.5-cdh5.12.0.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-log4j12-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ CLASSPATH='/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../build/classes:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../build/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/zookeeper-3.4.5-cdh5.12.0.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-log4j12-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:'
++ case "`uname`" in
+++ uname
++ cygwin=false
++ false
+ '[' x '!=' x ']'
+ '[' x '!=' x ']'
++ dirname /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
+ '[' x/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf '!=' x/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf ']'
+ false
+ KILL=kill
+ echo 'Using config: /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg'
Using config: /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
++ sed -e 's/.*=//'
++ grep '^[[:space:]]*dataDir' /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
+ ZOO_DATADIR=/mnt/zookeeper-3.4.5-cdh5.12.0/data
++ sed -e 's/.*=//'
++ grep '^[[:space:]]*dataLogDir' /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
+ ZOO_DATALOGDIR=/mnt/zookeeper-3.4.5-cdh5.12.0/logs
+ '[' -n '' ']'
+ '[' -z '' ']'
+ '[' '!' -d /mnt/zookeeper-3.4.5-cdh5.12.0/data ']'
+ ZOOPIDFILE=/mnt/zookeeper-3.4.5-cdh5.12.0/data/zookeeper_server.pid
+ '[' '!' -w /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../logs ']'
+ _ZOO_DAEMON_OUT=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../logs/zookeeper.out
+ case $1 in
+ echo -n 'Starting zookeeper ... '
Starting zookeeper ... + '[' -f /mnt/zookeeper-3.4.5-cdh5.12.0/data/zookeeper_server.pid ']'
+ '[' 0 -eq 0 ']'
+ /bin/echo -n 8653
+ nohup /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -Dzookeeper.log.dir=/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../logs -Dzookeeper.root.logger=INFO,CONSOLE -cp '/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../build/classes:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../build/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/zookeeper-3.4.5-cdh5.12.0.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-log4j12-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/slf4j-api-1.7.5.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/netty-3.10.5.Final.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/log4j-1.2.16.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../share/zookeeper/jline-2.11.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../src/java/lib/*.jar:/mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf:' -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain /mnt/zookeeper-3.4.5-cdh5.12.0/bin/../conf/zoo.cfg
+ sleep 1
+ echo STARTED
STARTED
```

从脚本中，可以看到主要的启动类是

```java
org.apache.zookeeper.server.quorum.QuorumPeerMain
```

那接下来，就可以以此为入口，进入程序进行查看了。