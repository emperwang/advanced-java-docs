[TOC]

# start-slaves.sh

上面说了一下启动本机slave的脚本，本篇说一下启动所有slave的脚本：start-slaves.sh

```shell
#!/usr/bin/env bash
# Starts a slave instance on each machine specified in the conf/slaves file.
# spark home的设置
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi
# 运行环境的设置
. "${SPARK_HOME}/sbin/spark-config.sh"
. "${SPARK_HOME}/bin/load-spark-env.sh"

# Find the port number for the master
# 设置默认的 master的端口号
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi
# 默认的master的 host地址为 本机
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
# 调用slaves.sh 来启动所有的slave; 其实就是ssh 到slave所在的机器,来执行sbin/start-slave.sh命令
# Launch the slaves
# 此处就是调用 slaves.sh脚本, 并把启动slave的命令作为参数传递进来
"${SPARK_HOME}/sbin/slaves.sh" cd "${SPARK_HOME}" \; "${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
```

执行过程:

```shell
[root@name2 sbin]# sh -x start-slaves.sh 
+ '[' -z '' ']'
+++ dirname start-slaves.sh
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
+ '[' 7077 = '' ']'
+ '[' '' = '' ']'
+ case `uname` in
++ uname
++ hostname -f
+ SPARK_MASTER_HOST=name2
+ /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/slaves.sh cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077
name3: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name3.out
name2: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
name4: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name4.out

```

可见start-slaves.sh 最终是调用slaves.sh 脚本来进行启动的.

> slaves.sh cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077

```shell
#!/usr/bin/env bash
# Run a shell command on all slave hosts.
# Environment Variables
#   SPARK_SLAVES    File naming remote hosts.
#     Default is ${SPARK_CONF_DIR}/slaves.
#   SPARK_CONF_DIR  Alternate conf dir. Default is ${SPARK_HOME}/conf.
#   SPARK_SLAVE_SLEEP Seconds to sleep between spawning remote commands.
#   SPARK_SSH_OPTS Options passed to ssh when running remote commands.
##
# 传递的参数
#slaves.sh" cd "${SPARK_HOME}" \; "${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
usage="Usage: slaves.sh [--config <conf-dir>] command..."

# if no args specified, show usage
# 没有传递参数,则 打印帮助信息
if [ $# -le 0 ]; then
  echo $usage
  exit 1
fi

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

. "${SPARK_HOME}/sbin/spark-config.sh"

# If the slaves file is specified in the command line,
# then it takes precedence over the definition in
# spark-env.sh. Save it here.
if [ -f "$SPARK_SLAVES" ]; then
  HOSTLIST=`cat "$SPARK_SLAVES"`
fi

# Check if --config is passed as an argument. It is an optional parameter.
# Exit if the argument is not a directory.
# 配置目录的指定
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
# 运行环境的配置
. "${SPARK_HOME}/bin/load-spark-env.sh"
# 要启动slave的host
if [ "$HOSTLIST" = "" ]; then
  if [ "$SPARK_SLAVES" = "" ]; then
    if [ -f "${SPARK_CONF_DIR}/slaves" ]; then
      HOSTLIST=`cat "${SPARK_CONF_DIR}/slaves"`
    else
      HOSTLIST=localhost
    fi
  else
    HOSTLIST=`cat "${SPARK_SLAVES}"`
  fi
fi

# By default disable strict host key checking
## ssh的参数
if [ "$SPARK_SSH_OPTS" = "" ]; then
  SPARK_SSH_OPTS="-o StrictHostKeyChecking=no"
fi
## 遍历所有的slave 通过ssh 来执行启动操作
for slave in `echo "$HOSTLIST"|sed  "s/#.*$//;/^$/d"`; do
  if [ -n "${SPARK_SSH_FOREGROUND}" ]; then
    ssh $SPARK_SSH_OPTS "$slave" $"${@// /\\ }" \
      2>&1 | sed "s/^/$slave: /"
  else
    ssh $SPARK_SSH_OPTS "$slave" $"${@// /\\ }" \
      2>&1 | sed "s/^/$slave: /" &
  fi
  if [ "$SPARK_SLAVE_SLEEP" != "" ]; then
    sleep $SPARK_SLAVE_SLEEP
  fi
done
# 注意此wait命令哦, 相当于高级语言中的多线程同步
wait
```

执行过程:

```shell
[root@name2 sbin]# sh -x slaves.sh cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077
+ usage='Usage: slaves.sh [--config <conf-dir>] command...'
+ '[' 5 -le 0 ']'
+ '[' -z '' ']'
+++ dirname slaves.sh
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
+ '[' -f '' ']'
+ '[' cd == --config ']'
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
+ '[' '' = '' ']'
+ '[' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/slaves ']'
++ cat /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/slaves
+ HOSTLIST='#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# A Spark Worker will be started on each of the machines listed below.
name2
name3
name4'
+ '[' '' = '' ']'
+ SPARK_SSH_OPTS='-o StrictHostKeyChecking=no'
++ sed 's/#.*$//;/^$/d'
++ echo '#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# A Spark Worker will be started on each of the machines listed below.
name2
name3
name4'
+ for slave in '`echo "$HOSTLIST"|sed  "s/#.*$//;/^$/d"`'
+ '[' -n '' ']'
+ '[' '' '!=' '' ']'
+ for slave in '`echo "$HOSTLIST"|sed  "s/#.*$//;/^$/d"`'
+ '[' -n '' ']'
+ '[' '' '!=' '' ']'
+ for slave in '`echo "$HOSTLIST"|sed  "s/#.*$//;/^$/d"`'
+ '[' -n '' ']'
+ '[' '' '!=' '' ']'
+ wait
+ sed 's/^/name4: /'
+ sed 's/^/name3: /'
### 可以看到是 ssh到目标机器 来进行 worker的启动
+ ssh -o StrictHostKeyChecking=no name4 cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077
+ sed 's/^/name2: /'
+ ssh -o StrictHostKeyChecking=no name3 cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077
+ ssh -o StrictHostKeyChecking=no name2 cd /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ';' /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/start-slave.sh spark://name2:7077
name3: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name3.out
name2: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name2.out
name4: starting org.apache.spark.deploy.worker.Worker, logging to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-name4.out
```















































