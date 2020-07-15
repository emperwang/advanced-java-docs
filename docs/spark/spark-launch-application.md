[TOC]

# launch application

提交任务的命令:

```shell
spark-submit --class org.apache.spark.examples.SparkPi --deploy-mode cluster  --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5
```

也就是说， 这是集群模式提交的任务。

launch application的命令

```shell
Launch Command: "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java" "-cp" "/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*" "-Xmx1024M" "-Dspark.driver.supervise=false" "-Dspark.app.name=org.apache.spark.examples.SparkPi" "-Dspark.master=spark://name2:7077" "-Dspark.submit.deployMode=cluster" "-Dspark.rpc.askTimeout=10s" "-Dspark.jars=file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar" "org.apache.spark.deploy.worker.DriverWrapper" "spark://Worker@192.168.72.35:7078" "/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work/driver-20200715162357-0000/spark-examples_2.11-2.4.6.jar" "org.apache.spark.examples.SparkPi" "5"
```

现象：

```txt
当时的集群环境：
	一个master实例
	一个worker实例    （drive最终运行在此，因为只有一个worker）

现象：
	提交任务后，webui页面显示已经有了driver，以及application信息，不过application只是挂在哪里，在集群中没有任何关于app的日志信息。
	driver有警告信息：
20/07/15 16:24:19 INFO TaskSchedulerImpl: Adding task set 0.0 with 5 tasks
20/07/15 16:24:34 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
20/07/15 16:24:49 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
20/07/15 16:25:04 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
20/07/15 16:25:19 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources

之后再启动一个worker实例2，发现application会运行在worker实例2上，并且在此实例上有相关的app日志信息。

由此可见，集群模式下：
1. 先找一个worker启动了 driver
2. 再找一个worker 启动executor来运行application任务，并且之后application向driver报告情况

出现上述情况原因是：只有一个集群中只有一个worker，这样的话worker启动driver后，就没有worker来运行application的任务了。
```

