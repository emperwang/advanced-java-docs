[TOC]

# slave的启动脚本

启动slave的脚本: start-slave.sh; 启动时需要执行 master的地址:

```shell
sh -x start-slave.sh spark://name2:7077
```

```shell
#!/usr/bin/env bash
# Starts a slave on the machine this script is executed on.
#
# Environment Variables
#
#   SPARK_WORKER_INSTANCES  The number of worker instances to run on this
#                           slave.  Default is 1.
#   SPARK_WORKER_PORT       The base port number for the first worker. If set,
#                           subsequent workers will increment this number.  If
#                           unset, Spark will find a valid port number, but
#                           with no guarantee of a predictable pattern.
#   SPARK_WORKER_WEBUI_PORT The base port for the web interface of the first
#                           worker.  Subsequent workers will increment this
#                           number.  Default is 8081.
# spark home的配置
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# NOTE: This exact class name is matched downstream by SparkSubmit.
# Any changes need to be reflected there.

# worker 的class
CLASS="org.apache.spark.deploy.worker.Worker"
#  如果没有给参数 或者 参数给出的是 --help 或 -h  则打印 帮助信息
if [[ $# -lt 1 ]] || [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  echo "Usage: ./sbin/start-slave.sh <master> [options]"
  pattern="Usage:"
  pattern+="\|Using Spark's default log4j profile:"
  pattern+="\|Registered signal handlers for"
  # 可见帮助信息是由  spark-class $CLASS产生的
  "${SPARK_HOME}"/bin/spark-class $CLASS --help 2>&1 | grep -v "$pattern" 1>&2
  exit 1
fi
# 运行环境的配置
. "${SPARK_HOME}/sbin/spark-config.sh"

. "${SPARK_HOME}/bin/load-spark-env.sh"

# First argument should be the master; we need to store it aside because we may
# need to insert arguments between it and the other arguments
# 记录 命令行传递的 master的地址
MASTER=$1
shift

# Determine desired worker port
# 配置默认的 slave的webui的端口号
if [ "$SPARK_WORKER_WEBUI_PORT" = "" ]; then
  SPARK_WORKER_WEBUI_PORT=8081
fi

# Start up the appropriate number of workers on this machine.
# quick local function to start a worker
# 启动实例的函数
function start_instance {
  # 要启动的实例的 num
  WORKER_NUM=$1
  shift
  #
  if [ "$SPARK_WORKER_PORT" = "" ]; then
    PORT_FLAG=
    PORT_NUM=
  else
    PORT_FLAG="--port"
    PORT_NUM=$(( $SPARK_WORKER_PORT + $WORKER_NUM - 1 ))
  fi
  # webui的端口; 当启动多个worker 实例时, 端口号往后移动
  WEBUI_PORT=$(( $SPARK_WORKER_WEBUI_PORT + $WORKER_NUM - 1 ))
  # 启动
  # 重点  : 真正的启动还是调用 spark-daemon.sh 来执行的
  "${SPARK_HOME}/sbin"/spark-daemon.sh start $CLASS $WORKER_NUM \
     --webui-port "$WEBUI_PORT" $PORT_FLAG $PORT_NUM $MASTER "$@"
}
# 如果没有配置 SPARK_WORKER_INSTANCES 则默认的worker的实例数 为1
if [ "$SPARK_WORKER_INSTANCES" = "" ]; then
  start_instance 1 "$@"
else
  # 如果配置了 SPARK_WORKER_INSTANCES 则循环启动多个 worker实例
  for ((i=0; i<$SPARK_WORKER_INSTANCES; i++)); do
    start_instance $(( 1 + $i )) "$@"
  done
fi
```

脚本的执行过程:

```shell
[root@name2 sbin]# sh -x start-slave.sh spark://name2:7077
+ '[' -z '' ']'
+++ dirname start-slave.sh
++ cd ./..
++ pwd
+ export SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ CLASS=org.apache.spark.deploy.worker.Worker
+ [[ 1 -lt 1 ]]
+ [[ spark://name2:7077 = *--help ]]
+ [[ spark://name2:7077 = *-h ]]
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/spark-config.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -z '' ']'
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYSPARK_PYTHONPATH_SET=1
++ PYSPARK_PYTHONPATH_SET=1
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/load-spark-env.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.12
++ [[ -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
++ SPARK_SCALA_VERSION=2.12
+ MASTER=spark://name2:7077
+ shift
+ '[' 8081 = '' ']'
+ '[' '' = '' ']'
+ start_instance 1
+ WORKER_NUM=1
+ shift
+ '[' 7078 = '' ']'
+ PORT_FLAG=--port
+ PORT_NUM=7078
+ WEBUI_PORT=8081
+ /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/spark-daemon.sh start org.apache.spark.deploy.worker.Worker 1 --webui-port 8081 --port 7078 spark://name2:7077
starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out

```

spark-daemon.sh 的启动参数:

> spark-2.4.6-bin-hadoop2.6/sbin/spark-daemon.sh start org.apache.spark.deploy.worker.Worker 1 --webui-port 8081 --port 7078 spark://name2:7077

```shell
#!/usr/bin/env bash
# Runs a Spark command as a daemon.
# Environment Variables
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
# 打印 最终的启动命令到 终端
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
    (class) # 一般启动 master slave 都会到此
    # 可见启动 由spark-class执行
      execute_command nice -n "$SPARK_NICENESS" "${SPARK_HOME}"/bin/spark-class "$command" "$@"
      ;;

    (submit)  # 提交任务 会执行此
    # 任务提交由 spark-submit 执行
      execute_command nice -n "$SPARK_NICENESS" bash "${SPARK_HOME}"/bin/spark-submit --class "$command" "$@"
      ;;
    (*) # 启动模式 只能是上面两种
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

```shell
[root@name2 sbin]# sh -x start-slave.sh spark://name2:7077
+ '[' -z '' ']'
+++ dirname start-slave.sh
++ cd ./..
++ pwd
+ export SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ CLASS=org.apache.spark.deploy.worker.Worker
+ [[ 1 -lt 1 ]]
+ [[ spark://name2:7077 = *--help ]]
+ [[ spark://name2:7077 = *-h ]]
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/spark-config.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -z '' ']'
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYSPARK_PYTHONPATH_SET=1
++ PYSPARK_PYTHONPATH_SET=1
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/load-spark-env.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.12
++ [[ -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
[root@name2 sbin]# sh -x spark-daemon.sh start org.apache.spark.deploy.worker.Worker 1 --webui-port 8081 --port 7078 spark://name2:7077
+ usage='Usage: spark-daemon.sh [--config <conf-dir>] (start|stop|submit|status) <spark-command> <spark-instance-number> <args...>'
+ '[' 8 -le 1 ']'
+ '[' -z '' ']'
+++ dirname spark-daemon.sh
++ cd ./..
++ pwd
+ export SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/spark-config.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -z '' ']'
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ PYTHONPATH=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python/lib/py4j-0.10.7-src.zip:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/python:
++ export PYSPARK_PYTHONPATH_SET=1
++ PYSPARK_PYTHONPATH_SET=1
+ '[' start == --config ']'
+ option=start
+ shift
+ command=org.apache.spark.deploy.worker.Worker
+ shift
+ instance=1
+ shift
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/load-spark-env.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.12
++ [[ -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
++ SPARK_SCALA_VERSION=2.12
+ '[' '' = '' ']'
+ export SPARK_IDENT_STRING=root
+ SPARK_IDENT_STRING=root
+ export SPARK_PRINT_LAUNCH_COMMAND=1
+ SPARK_PRINT_LAUNCH_COMMAND=1
+ '[' '' = '' ']'
+ export SPARK_LOG_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs
+ SPARK_LOG_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs
+ mkdir -p /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs
+ touch /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/.spark_test
+ TEST_LOG_DIR=0
+ '[' 0 = 0 ']'
+ rm -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/.spark_test
+ '[' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work = '' ']'
+ log=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
+ pid=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work/spark-root-org.apache.spark.deploy.worker.Worker-1.pid
+ '[' '' = '' ']'
+ export SPARK_NICENESS=0
+ SPARK_NICENESS=0
+ case $option in
+ run_command class --webui-port 8081 --port 7078 spark://name2:7077
+ mode=class
+ shift
+ mkdir -p /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work/spark-root-org.apache.spark.deploy.worker.Worker-1.pid ']'
+ '[' '' '!=' '' ']'
+ spark_rotate_log /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
+ log=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
+ num=5
+ '[' -n '' ']'
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out ']'
+ '[' 5 -gt 1 ']'
++ expr 5 - 1
+ prev=4
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.4 ']'
+ num=4
+ '[' 4 -gt 1 ']'
++ expr 4 - 1
+ prev=3
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.3 ']'
+ num=3
+ '[' 3 -gt 1 ']'
++ expr 3 - 1
+ prev=2
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.2 ']'
+ num=2
+ '[' 2 -gt 1 ']'
++ expr 2 - 1
+ prev=1
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.1 ']'
+ mv /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.1 /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.2
+ num=1
+ '[' 1 -gt 1 ']'
+ mv /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out.1
+ echo 'starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out'
starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
+ case "$mode" in
+ execute_command nice -n 0 /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/spark-class org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077
+ '[' -z ']'
+ newpid=8123
+ echo 8123
+ for i in '{1..10}'
+ nohup -- nice -n 0 /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/spark-class org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077
++ ps -p 8123 -o comm=
+ [[ bash =~ java ]]
+ sleep 0.5
+ for i in '{1..10}'
++ ps -p 8123 -o comm=
+ [[ java =~ java ]]
+ break
+ sleep 2
++ ps -p 8123 -o comm=
+ [[ ! java =~ java ]]
```

此spark-daemon.sh最终是调用 spark-class来执行:

> nohup -- nice -n 0 /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/spark-class org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077

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

此命令的执行过程:

> spark-class org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077

```shell
[root@name2 bin]# sh -x spark-class org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077
+ '[' -z '' ']'
++ dirname spark-class
+ source ./find-spark-home
++++ dirname spark-class
+++ cd .
+++ pwd
++ FIND_SPARK_HOME_PYTHON_SCRIPT=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/find_spark_home.py
++ '[' '!' -z '' ']'
++ '[' '!' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/find_spark_home.py ']'
++++ dirname spark-class
+++ cd ./..
+++ pwd
++ export SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
++ SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/load-spark-env.sh
++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ '[' -z '' ']'
++ export SPARK_ENV_LOADED=1
++ SPARK_ENV_LOADED=1
++ export SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ SPARK_CONF_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf
++ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh ']'
++ set -a
++ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-env.sh
+++ export 'SPARK_DAEMON_JAVA_OPTS=-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_DAEMON_JAVA_OPTS='-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster'
+++ SPARK_MASTER_PORT=7077
+++ SPARK_MASTER_WEBUI_PORT=8080
+++ SPARK_PID_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_CORES=1
+++ SPARK_WORKER_MEMORY=1g
+++ SPARK_WORKER_PORT=7078
+++ SPARK_WORKER_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work
+++ SPARK_WORKER_WEBUI_PORT=8081
++ set +a
++ '[' -z '' ']'
++ ASSEMBLY_DIR2=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11
++ ASSEMBLY_DIR1=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.12
++ [[ -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ]]
++ '[' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/assembly/target/scala-2.11 ']'
++ export SPARK_SCALA_VERSION=2.12
++ SPARK_SCALA_VERSION=2.12
+ '[' -n /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64 ']'
+ RUNNER=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java
+ '[' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars ']'
+ SPARK_JARS_DIR=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars
+ '[' '!' -d /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars ']'
+ LAUNCH_CLASSPATH='/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*'
+ '[' -n '' ']'
+ [[ -n '' ]]
+ set +o posix
+ CMD=()
+ IFS=
+ read -d '' -r ARG
+ CMD+=("$ARG")
+ IFS=+ read -d '' -r ARG+ CMD+=("$ARG")
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
++ printf '%d\0' 0
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ COUNT=14
+ LAST=13
+ LAUNCHER_EXIT_CODE=0
+ [[ 0 =~ ^[0-9]+$ ]]
+ '[' 0 '!=' 0 ']'
+ CMD=("${CMD[@]:0:$LAST}")
+ exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster -Xmx1g org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077
20/07/15 10:08:26 INFO Worker: Started daemon with process name: 8235@name2
20/07/15 10:08:26 INFO SignalUtils: Registered signal handler for TERM
20/07/15 10:08:26 INFO SignalUtils: Registered signal handler for HUP
20/07/15 10:08:26 INFO SignalUtils: Registered signal handler for INT
20/07/15 10:08:28 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
20/07/15 10:08:29 INFO SecurityManager: Changing view acls to: root
20/07/15 10:08:29 INFO SecurityManager: Changing modify acls to: root
20/07/15 10:08:29 INFO SecurityManager: Changing view acls groups to: 
20/07/15 10:08:29 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 10:08:29 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
20/07/15 10:08:30 WARN Utils: Service 'sparkWorker' could not bind on port 7078. Attempting port 7079.
20/07/15 10:08:30 INFO Utils: Successfully started service 'sparkWorker' on port 7079.
20/07/15 10:08:31 INFO Worker: Starting Spark worker 192.168.72.35:7079 with 1 cores, 1024.0 MB RAM
20/07/15 10:08:31 INFO Worker: Running Spark version 2.4.6
20/07/15 10:08:31 INFO Worker: Spark home: /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
20/07/15 10:08:32 WARN Utils: Service 'WorkerUI' could not bind on port 8081. Attempting port 8082.
20/07/15 10:08:32 WARN Utils: Service 'WorkerUI' could not bind on port 8082. Attempting port 8083.
20/07/15 10:08:32 INFO Utils: Successfully started service 'WorkerUI' on port 8083.
20/07/15 10:08:32 INFO WorkerWebUI: Bound WorkerWebUI to 0.0.0.0, and started at http://name2:8083
20/07/15 10:08:32 INFO Worker: Connecting to master name2:7077...
20/07/15 10:08:33 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:7077 after 241 ms (0 ms spent in bootstraps)
20/07/15 10:08:33 INFO Worker: Successfully registered with master spark://name2:7077
```

可见最终的启动 slave的命令:

>  exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster -Xmx1g org.apache.spark.deploy.worker.Worker --webui-port 8081 --port 7078 spark://name2:7077