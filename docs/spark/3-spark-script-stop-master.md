[TOC]

# stop-master脚本





执行过程:

```shell
[root@name2 sbin]# sh -x stop-master.sh 
+ '[' -z '' ']'
+++ dirname stop-master.sh
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
+ /mnt/spark-2.4.3-bin-alone/sbin/spark-daemon.sh stop org.apache.spark.deploy.master.Master 1
stopping org.apache.spark.deploy.master.Master
```

调用的停止命令

> /mnt/spark-2.4.3-bin-alone/sbin/spark-daemon.sh stop org.apache.spark.deploy.master.Master 1

```shell

```

