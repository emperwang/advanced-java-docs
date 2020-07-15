[TOC]

# slave的停止脚本

```shell

```



停止脚本的执行过程:

```shell
[root@name2 sbin]# sh -x stop-slave.sh 
+ '[' -z '' ']'
+++ dirname stop-slave.sh
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
+ . /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/load-spark-env.sh++ '[' -z /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6 ']'
++ '[' -z '' ']'++ export SPARK_ENV_LOADED=1
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
+ /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/spark-daemon.sh stop org.apache.spark.deploy.worker.Worker 1
stopping org.apache.spark.deploy.worker.Worker

```

