[TOC]

# stop-all 的执行

执行过程:

```shell
[root@name2 sbin]# sh -x stop-all.sh 
+ '[' -z '' ']'
+++ dirname stop-all.sh
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
+ /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/stop-slaves.sh
name3: stopping org.apache.spark.deploy.worker.Worker
name4: no org.apache.spark.deploy.worker.Worker to stop
name2: stopping org.apache.spark.deploy.worker.Worker
+ /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/sbin/stop-master.sh
stopping org.apache.spark.deploy.master.Master
+ '[' '' == --wait ']'
```

