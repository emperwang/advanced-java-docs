[TOC]

# spark 脚本之start-master.sh

既然看源码，肯定的找个点来入手。茫茫代码，看起来让人头大，不知从何入手。简单想想，平时使用时任务提交，master的启动，slave的启动....这一些列操作，其实都是框架为用户提供的使用入口，而用户当然也可以以此为入口，来进行源码的阅读。

本篇就从master的启动脚本来入口，看看脚本做了什么工作，是如何把master启动的。脚本内容如下:

```shell
#!/usr/bin/env bash
# 检测 SPARK_HOME 是否设置
# 没有设置,则为当前的上级目录的全路径
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi
# 要启动的scala类
CLASS="org.apache.spark.deploy.master.Master"
# 打印帮助信息
if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  echo "Usage: ./sbin/start-master.sh [options]"
  pattern="Usage:"
  pattern+="\|Using Spark's default log4j profile:"
  pattern+="\|Registered signal handlers for"
  # 可以看到这里调用spark-class来打印 帮助信息
  "${SPARK_HOME}"/bin/spark-class $CLASS --help 2>&1 | grep -v "$pattern" 1>&2
  exit 1
fi
# 保存源参数
ORIGINAL_ARGS="$@"
# config 以及 env脚本的执行
. "${SPARK_HOME}/sbin/spark-config.sh"

. "${SPARK_HOME}/bin/load-spark-env.sh"
# 设置端口
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi
# 
if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
	  SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
	  ;;
      (*)
	  SPARK_MASTER_HOST="`hostname -f`"
	  ;;
  esac
fi
# webui端口
if [ "$SPARK_MASTER_WEBUI_PORT" = "" ]; then
  SPARK_MASTER_WEBUI_PORT=8080
fi
# 可以看到真正 运行任务是通过 spark-daemon.sh 脚本
"${SPARK_HOME}/sbin"/spark-daemon.sh start $CLASS 1 \
  --host $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT \
  $ORIGINAL_ARGS

```

执行过程:

```shell
[root@name2 sbin]# sh -x start-master.sh 
+ '[' -z '' ']'
+++ dirname start-master.sh
++ cd ./..
++ pwd
+ export SPARK_HOME=/mnt/spark-2.4.3-bin-alone
+ SPARK_HOME=/mnt/spark-2.4.3-bin-alone
+ CLASS=org.apache.spark.deploy.master.Master
+ [[ '' = *--help ]]
+ [[ '' = *-h ]]
+ ORIGINAL_ARGS=
+ . /mnt/spark-2.4.3-bin-alone/sbin/spark-config.sh
++ '[' -z /mnt/spark-2.4.3-bin-alone ']'
++ export SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ PYSPARK_PYTHONPATH_SET=1
+ . /mnt/spark-2.4.3-bin-alone/bin/load-spark-env.sh
++ '[' -z /mnt/spark-2.4.3-bin-alone ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ '[' -f /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-2.4.3-bin-alone/work+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-2.4.3-bin-alone/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.12
++ [[ -d /mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
++ SPARK_SCALA_VERSION=2.12
+ '[' 7077 = '' ']'
+ '[' '' = '' ']'
+ case `uname` in
++ uname
++ hostname -f
+ SPARK_MASTER_HOST=name2
+ '[' 8080 = '' ']'
+ /mnt/spark-2.4.3-bin-alone/sbin/spark-daemon.sh start org.apache.spark.deploy.master.Master 1 --host name2 --port 7077 --webui-port 8080
starting org.apache.spark.deploy.master.Master, logging to /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out
```



最终看到是通过调用spark-daemon.sh 脚本来继续启动的操作， 继续看看此脚本

```shell
#!/usr/bin/env bash
# Runs a Spark command as a daemon.
# Environment Variables
#
#   SPARK_CONF_DIR  Alternate conf dir. Default is ${SPARK_HOME}/conf.
#   SPARK_LOG_DIR   Where log files are stored. ${SPARK_HOME}/logs by default.
#   SPARK_MASTER    host:path where spark code should be rsync'd from
#   SPARK_PID_DIR   The pid files are stored. /tmp by default.
#   SPARK_IDENT_STRING   A string representing this instance of spark. $USER by default
#   SPARK_NICENESS The scheduling priority for daemons. Defaults to 0.
#   SPARK_NO_DAEMONIZE   If set, will run the proposed command in the foreground. It will not output a PID file.
##
# 使用方法
usage="Usage: spark-daemon.sh [--config <conf-dir>] (start|stop|submit|status) <spark-command> <spark-instance-number> <args...>"

# if no args specified, show usage
# 如果没有传递参数,则打印使用方法
if [ $# -le 1 ]; then
  echo $usage
  exit 1
fi
# 设置SPARK_HOME,没有设置的话,则设置为当前目录的上级目录的全路径
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi
# 配置脚本
. "${SPARK_HOME}/sbin/spark-config.sh"

# 由此可见,可以通过--config 参数来配置配置文件的目录
if [ "$1" == "--config" ]
then
  shift
  conf_dir="$1"
  if [ ! -d "$conf_dir" ]
  then
    echo "ERROR : $conf_dir is not a directory"
    echo $usage
    exit 1
  else
    export SPARK_CONF_DIR="$conf_dir"
  fi
  shift
fi

# 启动master 传递的参数
# spark-daemon.sh start $CLASS 1 \
#  --host $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT \
#  $ORIGINAL_ARGS
# 此三个变量,分别获取 start  #CLASS  1
option=$1
shift
command=$1
shift
instance=$1
shift
# 滚动日志
spark_rotate_log ()
{
  # 记录文件名
    log=$1;
    # 滚动的个数
    num=5;
    # 第二个参数 表示 通过参数2 可以指定 num的值
    if [ -n "$2" ]; then
	    num=$2
    fi
    # 存在日志文件,则进行滚动操作
    if [ -f "$log" ]; then # rotate logs
    # 滚动操作, 备份文件; 此赋值会覆盖; 最终日志文件就是 num个
	while [ $num -gt 1 ]; do
	    prev=`expr $num - 1`
	    [ -f "$log.$prev" ] && mv "$log.$prev" "$log.$num"
	    num=$prev
	done
	mv "$log" "$log.$num";
    fi
}
# 执行env,配置运行环境
. "${SPARK_HOME}/bin/load-spark-env.sh"
# 执行此脚本的 用户
if [ "$SPARK_IDENT_STRING" = "" ]; then
  export SPARK_IDENT_STRING="$USER"
fi
export SPARK_PRINT_LAUNCH_COMMAND="1"

# get log directory
# 配置日志目录
if [ "$SPARK_LOG_DIR" = "" ]; then
  export SPARK_LOG_DIR="${SPARK_HOME}/logs"
fi
# 创建日志目录
mkdir -p "$SPARK_LOG_DIR"
# 创建一个隐形文件进行测试
touch "$SPARK_LOG_DIR"/.spark_test > /dev/null 2>&1
# 获取测试的结果
TEST_LOG_DIR=$?
# 在日志目录创建文件成功, 则进行杀出
if [ "${TEST_LOG_DIR}" = "0" ]; then
  rm -f "$SPARK_LOG_DIR"/.spark_test
else  # 给目录切换属主
  chown "$SPARK_IDENT_STRING" "$SPARK_LOG_DIR"
fi
# 存储进程id的文件目录
if [ "$SPARK_PID_DIR" = "" ]; then
  SPARK_PID_DIR=/tmp
fi

# some variables
# 日志以及pid文件的名字指定
log="$SPARK_LOG_DIR/spark-$SPARK_IDENT_STRING-$command-$instance-$HOSTNAME.out"
pid="$SPARK_PID_DIR/spark-$SPARK_IDENT_STRING-$command-$instance.pid"

# Set default scheduling priority
# 调度优先级
if [ "$SPARK_NICENESS" = "" ]; then
    export SPARK_NICENESS=0
fi
# 执行命令
# execute_command nice -n "$SPARK_NICENESS" "${SPARK_HOME}"/bin/spark-class "$command" "$@"
# execute_command nice -n "$SPARK_NICENESS" bash "${SPARK_HOME}"/bin/spark-submit --class "$command" "$@"
execute_command() {
  #SPARK_NO_DAEMONIZE 表示前台启动,不会生成pid文件
  # ${SPARK_NO_DAEMONIZE+set}  表示SPARK_NO_DAEMONIZE此声明了,值就是set,没有声明,则为null
  # 此处是,没有设置,就运行then; 设置了运行else
  if [ -z ${SPARK_NO_DAEMONIZE+set} ]; then
    # 这个启动命令 很有意思
      nohup -- "$@" >> $log 2>&1 < /dev/null &
      newpid="$!"

      echo "$newpid" > "$pid"

      # Poll for up to 5 seconds for the java process to start
      # 等待 5s ,让java程序启动
      for i in {1..10}
      do
        if [[ $(ps -p "$newpid" -o comm=) =~ "java" ]]; then
           break
        fi
        sleep 0.5
      done

      sleep 2
      # Check if the process has died; in that case we'll tail the log so the user can see
      # 如果启动失败,则打印日志文件的最后10行
      if [[ ! $(ps -p "$newpid" -o comm=) =~ "java" ]]; then
        echo "failed to launch: $@"
        tail -10 "$log" | sed 's/^/  /'
        echo "full log in $log"
      fi
  else
      # 启动启动程序
      "$@"
  fi
}

run_command() {
  # mode 记录模式,是运行class 还是提交任务
  mode="$1"
  shift
  # 创建pid目录
  mkdir -p "$SPARK_PID_DIR"
  # 检测pid 文件是否存在
  if [ -f "$pid" ]; then
    TARGET_ID="$(cat "$pid")"
    if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then   # pid文件存在,且程序在运行,则输出提示信息
      echo "$command running as process $TARGET_ID.  Stop it first."
      exit 1
    fi
  fi
  # 数据的同步, 从 spark-master机器 把 master的文件同步过来
  if [ "$SPARK_MASTER" != "" ]; then
    echo rsync from "$SPARK_MASTER"
    rsync -a -e ssh --delete --exclude=.svn --exclude='logs/*' --exclude='contrib/hod/logs/*' "$SPARK_MASTER/" "${SPARK_HOME}"
  fi
  # 滚动日志
  spark_rotate_log "$log"
  echo "starting $command, logging to $log"
  # 根据模式  执行不同的操作
  case "$mode" in
    (class)
      execute_command nice -n "$SPARK_NICENESS" "${SPARK_HOME}"/bin/spark-class "$command" "$@"
      ;;

    (submit)
      execute_command nice -n "$SPARK_NICENESS" bash "${SPARK_HOME}"/bin/spark-submit --class "$command" "$@"
      ;;

    (*)
      echo "unknown mode: $mode"
      exit 1
      ;;
  esac
}

case $option in
  # 提交任务时,执行的命令
  (submit)
    run_command submit "$@"
    ;;
  # 启动执行的命令
  (start)
    run_command class "$@"
    ;;
  # 停止执行的目录
  (stop)
  # 先检测 存储pid的文件是否存在
    if [ -f $pid ]; then
      TARGET_ID="$(cat "$pid")"  # 文件存在,则获取进程的pid号
      if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then  # 如果是个java程序,则继续执行
        echo "stopping $command"
        kill "$TARGET_ID" && rm -f "$pid"   # 使用kill 停止程序, 并删除 pid文件
      else
        echo "no $command to stop"  # 如果不是java程序,则说明程序没有在运行
      fi
    else
      echo "no $command to stop"   # pid文件不存在,说明 程序没有在运行
    fi
    ;;
  # 检测状态
  (status)
  # 先判断 pid文件
    if [ -f $pid ]; then
      TARGET_ID="$(cat "$pid")"
      if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then # 文件存在,程序在运行,则正常
        echo $command is running.
        exit 0
      else      # 文件存在,但是程序不再,则没有运行
        echo $pid file is present but $command not running
        exit 1
      fi
    else  # pid 文件不存在, 说明程序就没有运行
      echo $command not running.
      exit 2
    fi
    ;;
  # 输入其他参数,则打印 帮助信息
  (*)
    echo $usage
    exit 1
    ;;

esac
```

执行过程:

> spark-daemon.sh start org.apache.spark.deploy.master.Master 1 --host name2 --port 7077 --webui-port 8080

```shell
[root@name2 sbin]# sh -x spark-daemon.sh start org.apache.spark.deploy.master.Master 1 --host name2 --port 7077 --webui-port 8080
+ usage='Usage: spark-daemon.sh [--config <conf-dir>] (start|stop|submit|status) <spark-command> <spark-instance-number> <args...>'
+ '[' 9 -le 1 ']'
+ '[' -z '' ']'
+++ dirname spark-daemon.sh
++ cd ./..
++ pwd
+ export SPARK_HOME=/mnt/spark-2.4.3-bin-alone
+ SPARK_HOME=/mnt/spark-2.4.3-bin-alone
+ . /mnt/spark-2.4.3-bin-alone/sbin/spark-config.sh
++ '[' -z /mnt/spark-2.4.3-bin-alone ']'
++ export SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ '[' -z '' ']'
++ export PYTHONPATH=/mnt/spark-2.4.3-bin-alone/python:
++ PYTHONPATH=/mnt/spark-2.4.3-bin-alone/python:
++ export PYTHONPATH=/mnt/spark-2.4.3-bin-alone/python/lib/py4j-0.10.7-src.zip:/mnt/spark-2.4.3-bin-alone/python:
++ PYTHONPATH=/mnt/spark-2.4.3-bin-alone/python/lib/py4j-0.10.7-src.zip:/mnt/spark-2.4.3-bin-alone/python:
++ export PYSPARK_PYTHONPATH_SET=1
++ PYSPARK_PYTHONPATH_SET=1
+ '[' start == --config ']'
+ option=start
+ shift
+ command=org.apache.spark.deploy.master.Master
+ shift
+ instance=1
+ shift
+ . /mnt/spark-2.4.3-bin-alone/bin/load-spark-env.sh
++ '[' -z /mnt/spark-2.4.3-bin-alone ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ '[' -f /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-2.4.3-bin-alone/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-2.4.3-bin-alone/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.12
++ [[ -d /mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-2.4.3-bin-alone/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
++ SPARK_SCALA_VERSION=2.12
+ '[' '' = '' ']'
+ export SPARK_IDENT_STRING=root
+ SPARK_IDENT_STRING=root
+ export SPARK_PRINT_LAUNCH_COMMAND=1
+ SPARK_PRINT_LAUNCH_COMMAND=1
+ '[' '' = '' ']'
+ export SPARK_LOG_DIR=/mnt/spark-2.4.3-bin-alone/logs
+ SPARK_LOG_DIR=/mnt/spark-2.4.3-bin-alone/logs
+ mkdir -p /mnt/spark-2.4.3-bin-alone/logs
+ touch /mnt/spark-2.4.3-bin-alone/logs/.spark_test
+ TEST_LOG_DIR=0
+ '[' 0 = 0 ']'
+ rm -f /mnt/spark-2.4.3-bin-alone/logs/.spark_test
+ '[' /mnt/spark-2.4.3-bin-alone/work = '' ']'
+ log=/mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out
+ pid=/mnt/spark-2.4.3-bin-alone/work/spark-root-org.apache.spark.deploy.master.Master-1.pid
+ '[' '' = '' ']'
+ export SPARK_NICENESS=0
+ SPARK_NICENESS=0
+ case $option in
+ run_command class --host name2 --port 7077 --webui-port 8080
+ mode=class
+ shift
+ mkdir -p /mnt/spark-2.4.3-bin-alone/work
+ '[' -f /mnt/spark-2.4.3-bin-alone/work/spark-root-org.apache.spark.deploy.master.Master-1.pid ']'
+ '[' '' '!=' '' ']'
+ spark_rotate_log /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out
+ log=/mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out
+ num=5
+ '[' -n '' ']'
+ '[' -f /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out ']'
+ num=4
+ '[' 4 -gt 1 ']'
++ expr 4 - 1
+ prev=3
+ '[' -f /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.3 ']'
+ num=3
+ '[' 3 -gt 1 ']'
++ expr 3 - 1
+ prev=2
+ '[' -f /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.2 ']'
+ num=2
+ '[' 2 -gt 1 ']'
++ expr 2 - 1
+ prev=1
+ '[' -f /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.1 ']'
+ mv /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.1 /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.2
+ num=1
+ '[' 1 -gt 1 ']'
+ mv /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out.1
+ echo 'starting org.apache.spark.deploy.master.Master, logging to /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out'
starting org.apache.spark.deploy.master.Master, logging to /mnt/spark-2.4.3-bin-alone/logs/spark-root-org.apache.spark.deploy.master.Master-1-name2.out
+ case "$mode" in+ execute_command nice -n 0 /mnt/spark-2.4.3-bin-alone/bin/spark-class org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080+ '[' -z ']'
+ newpid=9312
+ echo 9312+ for i in '{1..10}'
+ nohup -- nice -n 0 /mnt/spark-2.4.3-bin-alone/bin/spark-class org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
++ ps -p 9312 -o comm=
+ [[ bash =~ java ]]
+ sleep 0.5
+ for i in '{1..10}'
++ ps -p 9312 -o comm=
+ [[ java =~ java ]]
+ break
+ sleep 2
++ ps -p 9312 -o comm=
+ [[ ! java =~ java ]]
```



可以看到最终是执行spark-class

```shell
#!/usr/bin/env bash
# spark_home的设置
if [ -z "${SPARK_HOME}" ]; then
  source "$(dirname "$0")"/find-spark-home
fi
# 配置运行环境
. "${SPARK_HOME}"/bin/load-spark-env.sh

# Find the java binary
# java程序
if [ -n "${JAVA_HOME}" ]; then
  RUNNER="${JAVA_HOME}/bin/java"
else
  # commnad 为bash buildin命令, command -v 可以得到java的全路径
  if [ "$(command -v java)" ]; then
    RUNNER="java"
  else
    echo "JAVA_HOME is not set" >&2
    exit 1
  fi
fi

# Find Spark jars.
# spark jar 目录
if [ -d "${SPARK_HOME}/jars" ]; then
  SPARK_JARS_DIR="${SPARK_HOME}/jars"
else
  SPARK_JARS_DIR="${SPARK_HOME}/assembly/target/scala-$SPARK_SCALA_VERSION/jars"
fi

if [ ! -d "$SPARK_JARS_DIR" ] && [ -z "$SPARK_TESTING$SPARK_SQL_TESTING" ]; then
  echo "Failed to find Spark jars directory ($SPARK_JARS_DIR)." 1>&2
  echo "You need to build Spark with the target \"package\" before running this program." 1>&2
  exit 1
else
  LAUNCH_CLASSPATH="$SPARK_JARS_DIR/*"   # 把jar的路径添加到LAUNCH_CLASSPATH
fi

# Add the launcher build dir to the classpath if requested.
if [ -n "$SPARK_PREPEND_CLASSES" ]; then
  LAUNCH_CLASSPATH="${SPARK_HOME}/launcher/target/scala-$SPARK_SCALA_VERSION/classes:$LAUNCH_CLASSPATH"
fi

# For tests
if [[ -n "$SPARK_TESTING" ]]; then
  unset YARN_CONF_DIR
  unset HADOOP_CONF_DIR
fi

# 运行命令 是使用java 来运行 org.apache.spark.launcher.Main这个类
# 通过此 org.apache.spark.launcher.Main 类来创建具体的启动命令
build_command() {
  "$RUNNER" -Xmx128m -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main "$@"
  printf "%d\0" $?
}

# Turn off posix mode since it does not allow process substitution
set +o posix
# 存储命令的数组
CMD=()
# 从终端中读取 org.apache.spark.launcher.Main 构建的命令
while IFS= read -d '' -r ARG; do
  CMD+=("$ARG")
done < <(build_command "$@")
# 数组的长度
COUNT=${#CMD[@]}
# 最后一个元素的index
LAST=$((COUNT - 1))
LAUNCHER_EXIT_CODE=${CMD[$LAST]}

# Certain JVM failures result in errors being printed to stdout (instead of stderr), which causes
# the code that parses the output of the launcher to get confused. In those cases, check if the
# exit code is an integer, and if it's not, handle it as a special error case.
if ! [[ $LAUNCHER_EXIT_CODE =~ ^[0-9]+$ ]]; then
  echo "${CMD[@]}" | head -n-1 1>&2
  exit 1
fi

if [ $LAUNCHER_EXIT_CODE != 0 ]; then
  exit $LAUNCHER_EXIT_CODE
fi
# 数组切片操作
CMD=("${CMD[@]:0:$LAST}")
# exec执行命令
exec "${CMD[@]}"

```

> nice -n 0 /mnt/spark-2.4.3-bin-alone/bin/spark-class org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080

```shell
[root@name2 sbin]# sh -x spark-daemon.sh start org.apache.spark.deploy.master.Master 1 --host name2 --port 7077 --webui-port 8080
+ '[' -z '' ']'
++ dirname /mnt/spark-2.4.3-bin-alone/bin/spark-class
+ source /mnt/spark-2.4.3-bin-alone/bin/find-spark-home
++++ dirname /mnt/spark-2.4.3-bin-alone/bin/spark-class
+++ cd /mnt/spark-2.4.3-bin-alone/bin
+++ pwd
++ FIND_SPARK_HOME_PYTHON_SCRIPT=/mnt/spark-2.4.3-bin-alone/bin/find_spark_home.py
++ '[' '!' -z '' ']'
++ '[' '!' -f /mnt/spark-2.4.3-bin-alone/bin/find_spark_home.py ']'
++++ dirname /mnt/spark-2.4.3-bin-alone/bin/spark-class
+++ cd /mnt/spark-2.4.3-bin-alone/bin/..
+++ pwd
++ export SPARK_HOME=/mnt/spark-2.4.3-bin-alone
++ SPARK_HOME=/mnt/spark-2.4.3-bin-alone
+ . /mnt/spark-2.4.3-bin-alone/bin/load-spark-env.sh
++ '[' -z /mnt/spark-2.4.3-bin-alone ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ SPARK_CONF_DIR=/mnt/spark-2.4.3-bin-alone/conf
++ '[' -f /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-2.4.3-bin-alone/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-2.4.3-bin-alone/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-2.4.3-bin-alone/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")+ IFS=
+ read -d '' -r ARG
++ printf '%d\0' 0
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ COUNT=15
+ LAST=14
+ LAUNCHER_EXIT_CODE=0
+ [[ 0 =~ ^[0-9]+$ ]]
+ '[' 0 '!=' 0 ']'
+ CMD=("${CMD[@]:0:$LAST}")
+ exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64//bin/java -cp '/mnt/spark-2.4.3-bin-alone/conf/:/mnt/spark-2.4.3-bin-alone/jars/*' -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster -Xmx1g org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
20/07/13 22:53:26 INFO Master: Started daemon with process name: 9399@name2
20/07/13 22:53:26 INFO SignalUtils: Registered signal handler for TERM
20/07/13 22:53:26 INFO SignalUtils: Registered signal handler for HUP
20/07/13 22:53:26 INFO SignalUtils: Registered signal handler for INT
20/07/13 22:53:27 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
20/07/13 22:53:28 INFO SecurityManager: Changing view acls to: root
20/07/13 22:53:28 INFO SecurityManager: Changing modify acls to: root
20/07/13 22:53:28 INFO SecurityManager: Changing view acls groups to: 
20/07/13 22:53:28 INFO SecurityManager: Changing modify acls groups to: 
20/07/13 22:53:28 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
20/07/13 22:53:29 INFO Utils: Successfully started service 'sparkMaster' on port 7077.
20/07/13 22:53:29 INFO Master: Starting Spark master at spark://name2:7077
20/07/13 22:53:29 INFO Master: Running Spark version 2.4.3
20/07/13 22:53:30 INFO Utils: Successfully started service 'MasterUI' on port 8080.
20/07/13 22:53:30 INFO MasterWebUI: Bound MasterWebUI to 0.0.0.0, and started at http://name2:8080
20/07/13 22:53:30 INFO Master: Persisting recovery state to ZooKeeper
20/07/13 22:53:31 INFO CuratorFrameworkImpl: Starting
20/07/13 22:53:31 INFO ZooKeeper: Client environment:zookeeper.version=3.4.6-1569965, built on 02/20/2014 09:09 GMT
20/07/13 22:53:31 INFO ZooKeeper: Client environment:host.name=name2
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.version=1.8.0_222
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.vendor=Oracle Corporation
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.home=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64/jre
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.class.path=/mnt/spark-2.4.3-bin-alone/conf/:/mnt/spark-2.4.3-bin-alone/jars/commons-lang3-3.5.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-kubernetes_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/arrow-format-0.10.0.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-streaming_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-yarn-common-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-mapreduce-client-jobclient-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/json4s-jackson_2.11-3.5.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-container-servlet-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/hive-jdbc-1.2.1.spark2.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-network-common_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/curator-framework-2.7.1.jar:/mnt/spark-2.4.3-bin-alone/jars/pyrolite-4.13.jar:/mnt/spark-2.4.3-bin-alone/jars/bonecp-0.8.0.RELEASE.jar:/mnt/spark-2.4.3-bin-alone/jars/hppc-0.7.2.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-network-shuffle_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/metrics-jvm-3.1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-guava-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/guice-3.0.jar:/mnt/spark-2.4.3-bin-alone/jars/super-csv-2.2.0.jar:/mnt/spark-2.4.3-bin-alone/jars/jsp-api-2.1.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-net-3.1.jar:/mnt/spark-2.4.3-bin-alone/jars/validation-api-1.1.0.Final.jar:/mnt/spark-2.4.3-bin-alone/jars/json4s-ast_2.11-3.5.3.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-repl_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-sketch_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/javax.inject-1.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-mapreduce-client-shuffle-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/orc-mapreduce-1.5.5-nohive.jar:/mnt/spark-2.4.3-bin-alone/jars/avro-ipc-1.8.2.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-encoding-1.10.1.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-container-servlet-core-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/zjsonpatch-0.3.0.jar:/mnt/spark-2.4.3-bin-alone/jars/scala-compiler-2.11.12.jar:/mnt/spark-2.4.3-bin-alone/jars/curator-client-2.7.1.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-media-jaxb-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/avro-mapred-1.8.2-hadoop2.jar:/mnt/spark-2.4.3-bin-alone/jars/antlr4-runtime-4.7.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-sql_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-module-jaxb-annotations-2.6.7.jar:/mnt/spark-2.4.3-bin-alone/jars/okhttp-3.8.1.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-core_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/leveldbjni-all-1.8.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-mapper-asl-1.9.13.jar:/mnt/spark-2.4.3-bin-alone/jars/ST4-4.0.4.jar:/mnt/spark-2.4.3-bin-alone/jars/eigenbase-properties-1.1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-jaxrs-1.9.13.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-yarn_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-annotations-2.6.7.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-module-paranamer-2.7.9.jar:/mnt/spark-2.4.3-bin-alone/jars/jdo-api-3.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-launcher_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-server-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/scala-parser-combinators_2.11-1.1.0.jar:/mnt/spark-2.4.3-bin-alone/jars/arrow-memory-0.10.0.jar:/mnt/spark-2.4.3-bin-alone/jars/hk2-utils-2.4.0-b34.jar:/mnt/spark-2.4.3-bin-alone/jars/joda-time-2.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-crypto-1.0.0.jar:/mnt/spark-2.4.3-bin-alone/jars/aopalliance-1.0.jar:/mnt/spark-2.4.3-bin-alone/jars/logging-interceptor-3.12.0.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-common-1.10.1.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-mllib-local_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/log4j-1.2.17.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-pool-1.5.4.jar:/mnt/spark-2.4.3-bin-alone/jars/xz-1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/hk2-locator-2.4.0-b34.jar:/mnt/spark-2.4.3-bin-alone/jars/libthrift-0.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/chill-java-0.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/opencsv-2.3.jar:/mnt/spark-2.4.3-bin-alone/jars/lz4-java-1.4.0.jar:/mnt/spark-2.4.3-bin-alone/jars/kubernetes-model-common-4.1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/slf4j-log4j12-1.7.16.jar:/mnt/spark-2.4.3-bin-alone/jars/calcite-core-1.2.0-incubating.jar:/mnt/spark-2.4.3-bin-alone/jars/breeze_2.11-0.13.2.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-hadoop-bundle-1.6.0.jar:/mnt/spark-2.4.3-bin-alone/jars/javax.inject-2.4.0-b34.jar:/mnt/spark-2.4.3-bin-alone/jars/metrics-json-3.1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-column-1.10.1.jar:/mnt/spark-2.4.3-bin-alone/jars/aopalliance-repackaged-2.4.0-b34.jar:/mnt/spark-2.4.3-bin-alone/jars/jcl-over-slf4j-1.7.16.jar:/mnt/spark-2.4.3-bin-alone/jars/antlr-runtime-3.4.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-jackson-1.10.1.jar:/mnt/spark-2.4.3-bin-alone/jars/httpcore-4.4.10.jar:/mnt/spark-2.4.3-bin-alone/jars/metrics-graphite-3.1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/netty-3.9.9.Final.jar:/mnt/spark-2.4.3-bin-alone/jars/guava-14.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/RoaringBitmap-0.7.45.jar:/mnt/spark-2.4.3-bin-alone/jars/jaxb-api-2.2.2.jar:/mnt/spark-2.4.3-bin-alone/jars/datanucleus-core-3.2.10.jar:/mnt/spark-2.4.3-bin-alone/jars/compress-lzf-1.0.3.jar:/mnt/spark-2.4.3-bin-alone/jars/antlr-2.7.7.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-common-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-yarn-client-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-hadoop-1.10.1.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-lang-2.6.jar:/mnt/spark-2.4.3-bin-alone/jars/datanucleus-api-jdo-3.2.6.jar:/mnt/spark-2.4.3-bin-alone/jars/orc-shims-1.5.5.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-digester-1.8.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-annotations-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jtransforms-2.4.0.jar:/mnt/spark-2.4.3-bin-alone/jars/jodd-core-3.5.2.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-hive_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/snakeyaml-1.15.jar:/mnt/spark-2.4.3-bin-alone/jars/kubernetes-client-4.1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-cli-1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/snappy-java-1.1.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/parquet-format-2.4.0.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-configuration-1.6.jar:/mnt/spark-2.4.3-bin-alone/jars/jpam-1.1.jar:/mnt/spark-2.4.3-bin-alone/jars/kryo-shaded-4.0.2.jar:/mnt/spark-2.4.3-bin-alone/jars/zookeeper-3.4.6.jar:/mnt/spark-2.4.3-bin-alone/jars/javax.ws.rs-api-2.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-core-asl-1.9.13.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-mapreduce-client-core-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/json4s-scalap_2.11-3.5.3.jar:/mnt/spark-2.4.3-bin-alone/jars/avro-1.8.2.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-yarn-api-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/api-asn1-api-1.0.0-M20.jar:/mnt/spark-2.4.3-bin-alone/jars/paranamer-2.8.jar:/mnt/spark-2.4.3-bin-alone/jars/janino-3.0.9.jar:/mnt/spark-2.4.3-bin-alone/jars/stringtemplate-3.2.1.jar:/mnt/spark-2.4.3-bin-alone/jars/apacheds-i18n-2.0.0-M15.jar:/mnt/spark-2.4.3-bin-alone/jars/apache-log4j-extras-1.2.17.jar:/mnt/spark-2.4.3-bin-alone/jars/xbean-asm6-shaded-4.8.jar:/mnt/spark-2.4.3-bin-alone/jars/curator-recipes-2.7.1.jar:/mnt/spark-2.4.3-bin-alone/jars/oro-2.0.8.jar:/mnt/spark-2.4.3-bin-alone/jars/javax.annotation-api-1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/chill_2.11-0.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hive-exec-1.2.1.spark2.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-common-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-dbcp-1.4.jar:/mnt/spark-2.4.3-bin-alone/jars/mesos-1.4.0-shaded-protobuf.jar:/mnt/spark-2.4.3-bin-alone/jars/okio-1.13.0.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-databind-2.6.7.1.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-mesos_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/netty-all-4.1.17.Final.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-compiler-3.0.9.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-math3-3.4.1.jar:/mnt/spark-2.4.3-bin-alone/jars/httpclient-4.5.6.jar:/mnt/spark-2.4.3-bin-alone/jars/jul-to-slf4j-1.7.16.jar:/mnt/spark-2.4.3-bin-alone/jars/stax-api-1.0-2.jar:/mnt/spark-2.4.3-bin-alone/jars/core-1.1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-codec-1.10.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-kvstore_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-catalyst_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/gson-2.2.4.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-tags_2.11-2.4.3-tests.jar:/mnt/spark-2.4.3-bin-alone/jars/zstd-jni-1.3.2-2.jar:/mnt/spark-2.4.3-bin-alone/jars/javolution-5.5.1.jar:/mnt/spark-2.4.3-bin-alone/jars/univocity-parsers-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/apacheds-kerberos-codec-2.0.0-M15.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-yarn-server-common-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/libfb303-0.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jersey-client-2.22.2.jar:/mnt/spark-2.4.3-bin-alone/jars/xercesImpl-2.9.1.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-collections-3.2.2.jar:/mnt/spark-2.4.3-bin-alone/jars/machinist_2.11-0.6.1.jar:/mnt/spark-2.4.3-bin-alone/jars/shims-0.7.45.jar:/mnt/spark-2.4.3-bin-alone/jars/htrace-core-3.1.0-incubating.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-graphx_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/jta-1.1.jar:/mnt/spark-2.4.3-bin-alone/jars/osgi-resource-locator-1.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/datanucleus-rdbms-3.2.9.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-unsafe_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/javassist-3.18.1-GA.jar:/mnt/spark-2.4.3-bin-alone/jars/spire-macros_2.11-0.13.0.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-mllib_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/calcite-linq4j-1.2.0-incubating.jar:/mnt/spark-2.4.3-bin-alone/jars/jline-2.14.6.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-client-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hive-metastore-1.2.1.spark2.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-yarn-server-web-proxy-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/spire_2.11-0.13.0.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-core-2.6.7.jar:/mnt/spark-2.4.3-bin-alone/jars/api-util-1.0.0-M20.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-httpclient-3.1.jar:/mnt/spark-2.4.3-bin-alone/jars/aircompressor-0.10.jar:/mnt/spark-2.4.3-bin-alone/jars/guice-servlet-3.0.jar:/mnt/spark-2.4.3-bin-alone/jars/scala-xml_2.11-1.0.5.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-mapreduce-client-common-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-beanutils-1.9.3.jar:/mnt/spark-2.4.3-bin-alone/jars/protobuf-java-2.5.0.jar:/mnt/spark-2.4.3-bin-alone/jars/hive-beeline-1.2.1.spark2.jar:/mnt/spark-2.4.3-bin-alone/jars/stream-2.7.0.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-compress-1.8.1.jar:/mnt/spark-2.4.3-bin-alone/jars/macro-compat_2.11-1.1.1.jar:/mnt/spark-2.4.3-bin-alone/jars/activation-1.1.1.jar:/mnt/spark-2.4.3-bin-alone/jars/breeze-macros_2.11-0.13.2.jar:/mnt/spark-2.4.3-bin-alone/jars/derby-10.12.1.1.jar:/mnt/spark-2.4.3-bin-alone/jars/shapeless_2.11-2.3.2.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-tags_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/minlog-1.3.0.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-logging-1.1.3.jar:/mnt/spark-2.4.3-bin-alone/jars/kubernetes-model-4.1.2.jar:/mnt/spark-2.4.3-bin-alone/jars/spark-hive-thriftserver_2.11-2.4.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hive-cli-1.2.1.spark2.jar:/mnt/spark-2.4.3-bin-alone/jars/metrics-core-3.1.5.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-module-scala_2.11-2.6.7.1.jar:/mnt/spark-2.4.3-bin-alone/jars/automaton-1.11-8.jar:/mnt/spark-2.4.3-bin-alone/jars/objenesis-2.5.1.jar:/mnt/spark-2.4.3-bin-alone/jars/json4s-core_2.11-3.5.3.jar:/mnt/spark-2.4.3-bin-alone/jars/py4j-0.10.7.jar:/mnt/spark-2.4.3-bin-alone/jars/jetty-6.1.26.jar:/mnt/spark-2.4.3-bin-alone/jars/slf4j-api-1.7.16.jar:/mnt/spark-2.4.3-bin-alone/jars/orc-core-1.5.5-nohive.jar:/mnt/spark-2.4.3-bin-alone/jars/commons-io-2.4.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-xc-1.9.13.jar:/mnt/spark-2.4.3-bin-alone/jars/scala-reflect-2.11.12.jar:/mnt/spark-2.4.3-bin-alone/jars/xmlenc-0.52.jar:/mnt/spark-2.4.3-bin-alone/jars/jetty-util-6.1.26.jar:/mnt/spark-2.4.3-bin-alone/jars/ivy-2.4.0.jar:/mnt/spark-2.4.3-bin-alone/jars/scala-library-2.11.12.jar:/mnt/spark-2.4.3-bin-alone/jars/snappy-0.2.jar:/mnt/spark-2.4.3-bin-alone/jars/jsr305-1.3.9.jar:/mnt/spark-2.4.3-bin-alone/jars/arpack_combined_all-0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/stax-api-1.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-mapreduce-client-app-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hk2-api-2.4.0-b34.jar:/mnt/spark-2.4.3-bin-alone/jars/jackson-dataformat-yaml-2.6.7.jar:/mnt/spark-2.4.3-bin-alone/jars/arrow-vector-0.10.0.jar:/mnt/spark-2.4.3-bin-alone/jars/flatbuffers-1.2.0-3f79e055.jar:/mnt/spark-2.4.3-bin-alone/jars/calcite-avatica-1.2.0-incubating.jar:/mnt/spark-2.4.3-bin-alone/jars/generex-1.0.1.jar:/mnt/spark-2.4.3-bin-alone/jars/JavaEWAH-0.3.2.jar:/mnt/spark-2.4.3-bin-alone/jars/javax.servlet-api-3.1.0.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-hdfs-2.7.3.jar:/mnt/spark-2.4.3-bin-alone/jars/hadoop-auth-2.7.3.jar
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.library.path=/usr/java/packages/lib/amd64:/usr/lib64:/lib64:/lib:/usr/lib
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.io.tmpdir=/tmp
20/07/13 22:53:31 INFO ZooKeeper: Client environment:java.compiler=<NA>
20/07/13 22:53:31 INFO ZooKeeper: Client environment:os.name=Linux
20/07/13 22:53:31 INFO ZooKeeper: Client environment:os.arch=amd64
20/07/13 22:53:31 INFO ZooKeeper: Client environment:os.version=3.10.0-957.el7.x86_64
20/07/13 22:53:31 INFO ZooKeeper: Client environment:user.name=root
20/07/13 22:53:31 INFO ZooKeeper: Client environment:user.home=/root
20/07/13 22:53:31 INFO ZooKeeper: Client environment:user.dir=/mnt/spark-2.4.3-bin-alone/sbin
20/07/13 22:53:31 INFO ZooKeeper: Initiating client connection, connectString=name2:2181,name3:2181,name4:2181 sessionTimeout=60000 watcher=org.apache.curator.ConnectionState@21264480
20/07/13 22:53:31 INFO ClientCnxn: Opening socket connection to server name4/192.168.30.17:2181. Will not attempt to authenticate using SASL (unknown error)
20/07/13 22:53:31 INFO ClientCnxn: Socket connection established to name4/192.168.30.17:2181, initiating session
20/07/13 22:53:31 INFO ClientCnxn: Session establishment complete on server name4/192.168.30.17:2181, sessionid = 0x30000330e450004, negotiated timeout = 40000
20/07/13 22:53:31 INFO ConnectionStateManager: State change: CONNECTED
20/07/13 22:53:32 INFO ZooKeeperLeaderElectionAgent: Starting ZooKeeper LeaderElection agent
20/07/13 22:53:32 INFO CuratorFrameworkImpl: Starting
20/07/13 22:53:32 INFO ZooKeeper: Initiating client connection, connectString=name2:2181,name3:2181,name4:2181 sessionTimeout=60000 watcher=org.apache.curator.ConnectionState@13cf6975
20/07/13 22:53:32 INFO ClientCnxn: Opening socket connection to server name4/192.168.30.17:2181. Will not attempt to authenticate using SASL (unknown error)
20/07/13 22:53:32 INFO ClientCnxn: Socket connection established to name4/192.168.30.17:2181, initiating session
20/07/13 22:53:32 INFO ClientCnxn: Session establishment complete on server name4/192.168.30.17:2181, sessionid = 0x30000330e450005, negotiated timeout = 40000
20/07/13 22:53:32 INFO ConnectionStateManager: State change: CONNECTED
20/07/13 22:53:32 INFO ZooKeeperLeaderElectionAgent: We have gained leadership
20/07/13 22:53:32 INFO Master: I have been elected leader! New state: ALIVE
```

