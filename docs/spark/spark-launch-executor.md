[TOC]

# launch executor

launch executor的命令

```shell
Spark Executor Command: "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java" "-cp" "/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*" "-Xmx1024M" "-Dspark.driver.port=45157" "-Dspark.rpc.askTimeout=10s" "org.apache.spark.executor.CoarseGrainedExecutorBackend" "--driver-url" "spark://CoarseGrainedScheduler@name2:45157" "--executor-id" "0" "--hostname" "192.168.72.36" "--cores" "1" "--app-id" "app-20200715162412-0002" "--worker-url" "spark://Worker@192.168.72.36:7078"
```

