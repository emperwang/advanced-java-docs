[TOC]

# spark-submit 提交任务

client模式提交任务的命令:

```shell
sh -x spark-submit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5
```

client模式提交任务 spark的详细打印信息

```shell
[root@name2 bin]# ./spark-submit -v --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5
Using properties file: /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf
Parsed arguments:
  master                  spark://name2:7077
  deployMode              null
  executorMemory          null
  executorCores           null
  totalExecutorCores      null
  propertiesFile          /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf
  driverMemory            null
  driverCores             null
  driverExtraClassPath    null
  driverExtraLibraryPath  null
  driverExtraJavaOptions  null
  supervise               false
  queue                   null
  numExecutors            null
  files                   null
  pyFiles                 null
  archives                null
  mainClass               org.apache.spark.examples.SparkPi
  primaryResource         file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6  name                    org.apache.spark.examples.SparkPi
  childArgs               [5]
  jars                    null
  packages                null
  packagesExclusions      null
  repositories            null
  verbose                 true

Spark properties used, including those specified through
 --conf and those from the properties file /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf:
  

    
20/07/16 17:08:17 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Main class:
org.apache.spark.examples.SparkPi		# client模式下,直接就是目标任务; driver启动是在 
Arguments:
5
Spark config:
(spark.app.name,org.apache.spark.examples.SparkPi)
(spark.master,spark://name2:7077)
(spark.submit.deployMode,client)
(spark.jars,file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar)
Classpath elements:
file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar
```



执行log:

```shell
[root@name2 bin]# sh -x spark-submit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5
+ '[' -z '' ']'
++ dirname spark-submit
+ source ./find-spark-home
++++ dirname spark-submit
+++ cd .
+++ pwd
++ FIND_SPARK_HOME_PYTHON_SCRIPT=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/find_spark_home.py
++ '[' '!' -z '' ']'
++ '[' '!' -f /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/find_spark_home.py ']'
++++ dirname spark-submit
+++ cd ./..
+++ pwd
++ export SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
++ SPARK_HOME=/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6
+ export PYTHONHASHSEED=0
+ PYTHONHASHSEED=0
+ exec /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/spark-class org.apache.spark.deploy.SparkSubmit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar 5
20/07/15 16:14:26 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
20/07/15 16:14:29 INFO SparkContext: Running Spark version 2.4.6
20/07/15 16:14:29 INFO SparkContext: Submitted application: Spark Pi
20/07/15 16:14:30 INFO SecurityManager: Changing view acls to: root
20/07/15 16:14:30 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:14:30 INFO SecurityManager: Changing view acls groups to: 
20/07/15 16:14:30 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:14:30 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
20/07/15 16:14:33 INFO Utils: Successfully started service 'sparkDriver' on port 42359.
20/07/15 16:14:33 INFO SparkEnv: Registering MapOutputTracker
20/07/15 16:14:34 INFO SparkEnv: Registering BlockManagerMaster
20/07/15 16:14:34 INFO BlockManagerMasterEndpoint: Using org.apache.spark.storage.DefaultTopologyMapper for getting topology information
20/07/15 16:14:34 INFO BlockManagerMasterEndpoint: BlockManagerMasterEndpoint up
20/07/15 16:14:34 INFO DiskBlockManager: Created local directory at /tmp/blockmgr-7d8ed3d1-6bcc-4eff-bced-046e860ea8ef
20/07/15 16:14:34 INFO MemoryStore: MemoryStore started with capacity 413.9 MB
20/07/15 16:14:34 INFO SparkEnv: Registering OutputCommitCoordinator
20/07/15 16:14:36 INFO Utils: Successfully started service 'SparkUI' on port 4040.
20/07/15 16:14:37 INFO SparkUI: Bound SparkUI to 0.0.0.0, and started at http://name2:4040
20/07/15 16:14:37 INFO SparkContext: Added JAR file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar at spark://name2:42359/jars/spark-examples_2.11-2.4.6.jar with timestamp 1594800877692
20/07/15 16:14:39 INFO StandaloneAppClient$ClientEndpoint: Connecting to master spark://name2:7077...
20/07/15 16:14:40 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:7077 after 430 ms (0 ms spent in bootstraps)
20/07/15 16:14:41 INFO StandaloneSchedulerBackend: Connected to Spark cluster with app ID app-20200715161441-0000
20/07/15 16:14:41 INFO Utils: Successfully started service 'org.apache.spark.network.netty.NettyBlockTransferService' on port 33671.
20/07/15 16:14:41 INFO NettyBlockTransferService: Server created on name2:33671
20/07/15 16:14:41 INFO BlockManager: Using org.apache.spark.storage.RandomBlockReplicationPolicy for block replication policy
20/07/15 16:14:42 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200715161441-0000/0 on worker-20200715105234-192.168.72.37-7078 (192.168.72.37:7078) with 1 core(s)
20/07/15 16:14:42 INFO StandaloneSchedulerBackend: Granted executor ID app-20200715161441-0000/0 on hostPort 192.168.72.37:7078 with 1 core(s), 1024.0 MB RAM
20/07/15 16:14:42 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200715161441-0000/1 on worker-20200715105208-192.168.72.36-7078 (192.168.72.36:7078) with 1 core(s)
20/07/15 16:14:42 INFO StandaloneSchedulerBackend: Granted executor ID app-20200715161441-0000/1 on hostPort 192.168.72.36:7078 with 1 core(s), 1024.0 MB RAM
20/07/15 16:14:42 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200715161441-0000/2 on worker-20200715105234-192.168.72.35-7078 (192.168.72.35:7078) with 1 core(s)
20/07/15 16:14:42 INFO StandaloneSchedulerBackend: Granted executor ID app-20200715161441-0000/2 on hostPort 192.168.72.35:7078 with 1 core(s), 1024.0 MB RAM
20/07/15 16:14:42 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200715161441-0000/1 is now RUNNING
20/07/15 16:14:42 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200715161441-0000/0 is now RUNNING
20/07/15 16:14:43 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200715161441-0000/2 is now RUNNING
20/07/15 16:14:43 INFO BlockManagerMaster: Registering BlockManager BlockManagerId(driver, name2, 33671, None)
20/07/15 16:14:43 INFO BlockManagerMasterEndpoint: Registering block manager name2:33671 with 413.9 MB RAM, BlockManagerId(driver, name2, 33671, None)
20/07/15 16:14:43 INFO BlockManagerMaster: Registered BlockManager BlockManagerId(driver, name2, 33671, None)
20/07/15 16:14:43 INFO BlockManager: Initialized BlockManager: BlockManagerId(driver, name2, 33671, None)
20/07/15 16:14:46 INFO StandaloneSchedulerBackend: SchedulerBackend is ready for scheduling beginning after reached minRegisteredResourcesRatio: 0.0
20/07/15 16:14:58 INFO SparkContext: Starting job: reduce at SparkPi.scala:38
20/07/15 16:14:58 INFO DAGScheduler: Got job 0 (reduce at SparkPi.scala:38) with 5 output partitions
20/07/15 16:14:58 INFO DAGScheduler: Final stage: ResultStage 0 (reduce at SparkPi.scala:38)
20/07/15 16:14:58 INFO DAGScheduler: Parents of final stage: List()
20/07/15 16:14:58 INFO DAGScheduler: Missing parents: List()
20/07/15 16:14:58 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Registered executor NettyRpcEndpointRef(spark-client://Executor) (192.168.72.36:40646) with ID 1
20/07/15 16:14:59 INFO DAGScheduler: Submitting ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34), which has no missing parents
20/07/15 16:14:59 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Registered executor NettyRpcEndpointRef(spark-client://Executor) (192.168.72.37:55126) with ID 0
20/07/15 16:15:00 INFO BlockManagerMasterEndpoint: Registering block manager 192.168.72.36:41685 with 413.9 MB RAM, BlockManagerId(1, 192.168.72.36, 41685, None)
20/07/15 16:15:01 INFO BlockManagerMasterEndpoint: Registering block manager 192.168.72.37:46205 with 413.9 MB RAM, BlockManagerId(0, 192.168.72.37, 46205, None)
20/07/15 16:15:02 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 2.0 KB, free 413.9 MB)
20/07/15 16:15:03 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 1381.0 B, free 413.9 MB)
20/07/15 16:15:03 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on name2:33671 (size: 1381.0 B, free: 413.9 MB)
20/07/15 16:15:03 INFO SparkContext: Created broadcast 0 from broadcast at DAGScheduler.scala:1163
20/07/15 16:15:03 INFO DAGScheduler: Submitting 5 missing tasks from ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34) (first 15 tasks are for partitions Vector(0, 1, 2, 3, 4))
20/07/15 16:15:03 INFO TaskSchedulerImpl: Adding task set 0.0 with 5 tasks
20/07/15 16:15:03 INFO TaskSetManager: Starting task 0.0 in stage 0.0 (TID 0, 192.168.72.36, executor 1, partition 0, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:15:03 INFO TaskSetManager: Starting task 1.0 in stage 0.0 (TID 1, 192.168.72.37, executor 0, partition 1, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:15:07 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on 192.168.72.36:41685 (size: 1381.0 B, free: 413.9 MB)
20/07/15 16:15:08 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on 192.168.72.37:46205 (size: 1381.0 B, free: 413.9 MB)
20/07/15 16:15:10 INFO TaskSetManager: Starting task 2.0 in stage 0.0 (TID 2, 192.168.72.36, executor 1, partition 2, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:15:10 INFO TaskSetManager: Finished task 0.0 in stage 0.0 (TID 0) in 6994 ms on 192.168.72.36 (executor 1) (1/5)
20/07/15 16:15:11 INFO TaskSetManager: Starting task 3.0 in stage 0.0 (TID 3, 192.168.72.36, executor 1, partition 3, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:15:11 INFO TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 676 ms on 192.168.72.36 (executor 1) (2/5)
20/07/15 16:15:11 INFO TaskSetManager: Starting task 4.0 in stage 0.0 (TID 4, 192.168.72.37, executor 0, partition 4, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:15:11 INFO TaskSetManager: Finished task 1.0 in stage 0.0 (TID 1) in 7368 ms on 192.168.72.37 (executor 0) (3/5)
20/07/15 16:15:11 INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 422 ms on 192.168.72.36 (executor 1) (4/5)
20/07/15 16:15:11 INFO TaskSetManager: Finished task 4.0 in stage 0.0 (TID 4) in 248 ms on 192.168.72.37 (executor 0) (5/5)
20/07/15 16:15:11 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool 
20/07/15 16:15:11 INFO DAGScheduler: ResultStage 0 (reduce at SparkPi.scala:38) finished in 11.610 s
20/07/15 16:15:11 INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 13.705253 s
Pi is roughly 3.1403342806685615
20/07/15 16:15:12 INFO SparkUI: Stopped Spark web UI at http://name2:4040
20/07/15 16:15:12 INFO StandaloneSchedulerBackend: Shutting down all executors
20/07/15 16:15:12 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Asking each executor to shut down
20/07/15 16:15:12 INFO MapOutputTrackerMasterEndpoint: MapOutputTrackerMasterEndpoint stopped!
20/07/15 16:15:13 INFO MemoryStore: MemoryStore cleared
20/07/15 16:15:13 INFO BlockManager: BlockManager stopped
20/07/15 16:15:13 INFO BlockManagerMaster: BlockManagerMaster stopped
20/07/15 16:15:13 INFO OutputCommitCoordinator$OutputCommitCoordinatorEndpoint: OutputCommitCoordinator stopped!
20/07/15 16:15:13 INFO SparkContext: Successfully stopped SparkContext
20/07/15 16:15:13 INFO ShutdownHookManager: Shutdown hook called
20/07/15 16:15:13 INFO ShutdownHookManager: Deleting directory /tmp/spark-dc00fddf-aadb-4f21-9dd5-a6b50ea7d594
20/07/15 16:15:13 INFO ShutdownHookManager: Deleting directory /tmp/spark-c5d3ad5e-fa77-4bd3-a6e1-19523a2f922c
```

最终的任务提交命令：

```shell
 exec /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/spark-class org.apache.spark.deploy.SparkSubmit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar 5
```

执行过程:

```shell
[root@name2 bin]# sh -x spark-class org.apache.spark.deploy.SparkSubmit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar 10
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
++ build_command org.apache.spark.deploy.SparkSubmit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar 10
++ /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -Xmx128m -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' org.apache.spark.launcher.Main org.apache.spark.deploy.SparkSubmit --class org.apache.spark.examples.SparkPi --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar 10
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
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
++ printf '%d\0' 0
+ CMD+=("$ARG")
+ IFS=
+ read -d '' -r ARG
+ COUNT=12
+ LAST=11
+ LAUNCHER_EXIT_CODE=0
+ [[ 0 =~ ^[0-9]+$ ]]
+ '[' 0 '!=' 0 ']'
+ CMD=("${CMD[@]:0:$LAST}")
+ exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' -Xmx1g org.apache.spark.deploy.SparkSubmit --master spark://name2:7077 --class org.apache.spark.examples.SparkPi ../examples/jars/spark-examples_2.11-2.4.6.jar 10
20/07/16 09:35:48 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
20/07/16 09:35:50 INFO SparkContext: Running Spark version 2.4.6
20/07/16 09:35:50 INFO SparkContext: Submitted application: Spark Pi
20/07/16 09:35:51 INFO SecurityManager: Changing view acls to: root
20/07/16 09:35:51 INFO SecurityManager: Changing modify acls to: root
20/07/16 09:35:51 INFO SecurityManager: Changing view acls groups to: 
20/07/16 09:35:51 INFO SecurityManager: Changing modify acls groups to: 
20/07/16 09:35:51 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
20/07/16 09:35:52 INFO Utils: Successfully started service 'sparkDriver' on port 39198.
20/07/16 09:35:52 INFO SparkEnv: Registering MapOutputTracker
20/07/16 09:35:52 INFO SparkEnv: Registering BlockManagerMaster
20/07/16 09:35:52 INFO BlockManagerMasterEndpoint: Using org.apache.spark.storage.DefaultTopologyMapper for getting topology information
20/07/16 09:35:53 INFO BlockManagerMasterEndpoint: BlockManagerMasterEndpoint up
20/07/16 09:35:53 INFO DiskBlockManager: Created local directory at /tmp/blockmgr-504e4c3e-9e60-4691-966a-b0041e99055d
20/07/16 09:35:53 INFO MemoryStore: MemoryStore started with capacity 413.9 MB
20/07/16 09:35:53 INFO SparkEnv: Registering OutputCommitCoordinator
20/07/16 09:35:54 INFO Utils: Successfully started service 'SparkUI' on port 4040.
20/07/16 09:35:54 INFO SparkUI: Bound SparkUI to 0.0.0.0, and started at http://name2:4040
20/07/16 09:35:54 INFO SparkContext: Added JAR file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar at spark://name2:39198/jars/spark-examples_2.11-2.4.6.jar with timestamp 1594863354723
20/07/16 09:35:55 INFO StandaloneAppClient$ClientEndpoint: Connecting to master spark://name2:7077...
20/07/16 09:35:55 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:7077 after 263 ms (0 ms spent in bootstraps)
20/07/16 09:35:56 INFO StandaloneSchedulerBackend: Connected to Spark cluster with app ID app-20200716093556-0001
20/07/16 09:35:56 INFO Utils: Successfully started service 'org.apache.spark.network.netty.NettyBlockTransferService' on port 46220.
20/07/16 09:35:56 INFO NettyBlockTransferService: Server created on name2:46220
20/07/16 09:35:56 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200716093556-0001/0 on worker-20200716093409-192.168.72.36-7078 (192.168.72.36:7078) with 1 core(s)
20/07/16 09:35:56 INFO BlockManager: Using org.apache.spark.storage.RandomBlockReplicationPolicy for block replication policy
20/07/16 09:35:56 INFO StandaloneSchedulerBackend: Granted executor ID app-20200716093556-0001/0 on hostPort 192.168.72.36:7078 with 1 core(s), 1024.0 MB RAM
20/07/16 09:35:56 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200716093556-0001/1 on worker-20200716093123-192.168.72.35-7078 (192.168.72.35:7078) with 1 core(s)
20/07/16 09:35:56 INFO StandaloneSchedulerBackend: Granted executor ID app-20200716093556-0001/1 on hostPort 192.168.72.35:7078 with 1 core(s), 1024.0 MB RAM
20/07/16 09:35:57 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200716093556-0001/0 is now RUNNING
20/07/16 09:35:57 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200716093556-0001/1 is now RUNNING
20/07/16 09:35:57 INFO BlockManagerMaster: Registering BlockManager BlockManagerId(driver, name2, 46220, None)
20/07/16 09:35:57 INFO BlockManagerMasterEndpoint: Registering block manager name2:46220 with 413.9 MB RAM, BlockManagerId(driver, name2, 46220, None)
20/07/16 09:35:57 INFO BlockManagerMaster: Registered BlockManager BlockManagerId(driver, name2, 46220, None)
20/07/16 09:35:57 INFO BlockManager: Initialized BlockManager: BlockManagerId(driver, name2, 46220, None)
20/07/16 09:35:59 INFO StandaloneSchedulerBackend: SchedulerBackend is ready for scheduling beginning after reached minRegisteredResourcesRatio: 0.0
20/07/16 09:36:04 INFO SparkContext: Starting job: reduce at SparkPi.scala:38
20/07/16 09:36:05 INFO DAGScheduler: Got job 0 (reduce at SparkPi.scala:38) with 10 output partitions
20/07/16 09:36:05 INFO DAGScheduler: Final stage: ResultStage 0 (reduce at SparkPi.scala:38)
20/07/16 09:36:05 INFO DAGScheduler: Parents of final stage: List()
20/07/16 09:36:05 INFO DAGScheduler: Missing parents: List()
20/07/16 09:36:05 INFO DAGScheduler: Submitting ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34), which has no missing parents
20/07/16 09:36:06 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Registered executor NettyRpcEndpointRef(spark-client://Executor) (192.168.72.36:41796) with ID 0
20/07/16 09:36:07 INFO BlockManagerMasterEndpoint: Registering block manager 192.168.72.36:33537 with 413.9 MB RAM, BlockManagerId(0, 192.168.72.36, 33537, None)
20/07/16 09:36:07 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 2.0 KB, free 413.9 MB)
20/07/16 09:36:07 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 1381.0 B, free 413.9 MB)
20/07/16 09:36:07 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on name2:46220 (size: 1381.0 B, free: 413.9 MB)
20/07/16 09:36:07 INFO SparkContext: Created broadcast 0 from broadcast at DAGScheduler.scala:1163
20/07/16 09:36:08 INFO DAGScheduler: Submitting 10 missing tasks from ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34) (first 15 tasks are for partitions Vector(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
20/07/16 09:36:08 INFO TaskSchedulerImpl: Adding task set 0.0 with 10 tasks
20/07/16 09:36:08 INFO TaskSetManager: Starting task 0.0 in stage 0.0 (TID 0, 192.168.72.36, executor 0, partition 0, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:10 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on 192.168.72.36:33537 (size: 1381.0 B, free: 413.9 MB)
20/07/16 09:36:11 INFO TaskSetManager: Starting task 1.0 in stage 0.0 (TID 1, 192.168.72.36, executor 0, partition 1, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:11 INFO TaskSetManager: Finished task 0.0 in stage 0.0 (TID 0) in 3434 ms on 192.168.72.36 (executor 0) (1/10)
20/07/16 09:36:11 INFO TaskSetManager: Starting task 2.0 in stage 0.0 (TID 2, 192.168.72.36, executor 0, partition 2, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:11 INFO TaskSetManager: Finished task 1.0 in stage 0.0 (TID 1) in 204 ms on 192.168.72.36 (executor 0) (2/10)
20/07/16 09:36:11 INFO TaskSetManager: Starting task 3.0 in stage 0.0 (TID 3, 192.168.72.36, executor 0, partition 3, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 187 ms on 192.168.72.36 (executor 0) (3/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 4.0 in stage 0.0 (TID 4, 192.168.72.36, executor 0, partition 4, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 119 ms on 192.168.72.36 (executor 0) (4/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 5.0 in stage 0.0 (TID 5, 192.168.72.36, executor 0, partition 5, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 4.0 in stage 0.0 (TID 4) in 117 ms on 192.168.72.36 (executor 0) (5/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 6.0 in stage 0.0 (TID 6, 192.168.72.36, executor 0, partition 6, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 5.0 in stage 0.0 (TID 5) in 147 ms on 192.168.72.36 (executor 0) (6/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 7.0 in stage 0.0 (TID 7, 192.168.72.36, executor 0, partition 7, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 6.0 in stage 0.0 (TID 6) in 133 ms on 192.168.72.36 (executor 0) (7/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 8.0 in stage 0.0 (TID 8, 192.168.72.36, executor 0, partition 8, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 7.0 in stage 0.0 (TID 7) in 166 ms on 192.168.72.36 (executor 0) (8/10)
20/07/16 09:36:12 INFO TaskSetManager: Starting task 9.0 in stage 0.0 (TID 9, 192.168.72.36, executor 0, partition 9, PROCESS_LOCAL, 7870 bytes)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 8.0 in stage 0.0 (TID 8) in 120 ms on 192.168.72.36 (executor 0) (9/10)
20/07/16 09:36:12 INFO TaskSetManager: Finished task 9.0 in stage 0.0 (TID 9) in 127 ms on 192.168.72.36 (executor 0) (10/10)
20/07/16 09:36:12 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool 
20/07/16 09:36:12 INFO DAGScheduler: ResultStage 0 (reduce at SparkPi.scala:38) finished in 7.342 s
20/07/16 09:36:12 INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 8.159472 s
Pi is roughly 3.1432951432951435
20/07/16 09:36:13 INFO SparkUI: Stopped Spark web UI at http://name2:4040
20/07/16 09:36:13 INFO StandaloneSchedulerBackend: Shutting down all executors
20/07/16 09:36:13 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Asking each executor to shut down
20/07/16 09:36:13 INFO MapOutputTrackerMasterEndpoint: MapOutputTrackerMasterEndpoint stopped!
20/07/16 09:36:13 INFO MemoryStore: MemoryStore cleared
20/07/16 09:36:13 INFO BlockManager: BlockManager stopped
20/07/16 09:36:13 INFO BlockManagerMaster: BlockManagerMaster stopped
20/07/16 09:36:13 INFO OutputCommitCoordinator$OutputCommitCoordinatorEndpoint: OutputCommitCoordinator stopped!
20/07/16 09:36:13 INFO SparkContext: Successfully stopped SparkContext
20/07/16 09:36:13 INFO ShutdownHookManager: Shutdown hook called
20/07/16 09:36:13 INFO ShutdownHookManager: Deleting directory /tmp/spark-9a69e6ca-6c45-4d37-8e8c-e3bc8c558ed6
20/07/16 09:36:13 INFO ShutdownHookManager: Deleting directory /tmp/spark-505d0652-222b-4d3f-bd71-e7f07ada7a40

```

最终执行的命令:

```shell
exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' -Xmx1g org.apache.spark.deploy.SparkSubmit --master spark://name2:7077 --class org.apache.spark.examples.SparkPi ../examples/jars/spark-examples_2.11-2.4.6.jar 10
```

到这里就知道提交任务到spark集群执行时，可以从SparkSubmit此类作为入口查看。





集群模式提交:

>  spark-submit --class org.apache.spark.examples.SparkPi --deploy-mode cluster  --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5

集群提交时的一些spark详细打印信息

```shell
[root@name2 bin]# ./spark-submit -v --class org.apache.spark.examples.SparkPi --deploy-mode cluster  --master spark://name2:7077 ../examples/jars/spark-examples_2.11-2.4.6.jar  5                                                              
Using properties file: /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf
Parsed arguments:
  master                  spark://name2:7077
  deployMode              cluster
  executorMemory          null
  executorCores           null
  totalExecutorCores      null
  propertiesFile          /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf
  driverMemory            null
  driverCores             null
  driverExtraClassPath    null
  driverExtraLibraryPath  null
  driverExtraJavaOptions  null
  supervise               false
  queue                   null
  numExecutors            null
  files                   null
  pyFiles                 null
  archives                null
  mainClass               org.apache.spark.examples.SparkPi
  primaryResource         file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar
  name                    org.apache.spark.examples.SparkPi
  childArgs               [5]
  jars                    null
  packages                null
  packagesExclusions      null
  repositories            null
  verbose                 true

Spark properties used, including those specified through
 --conf and those from the properties file /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/spark-defaults.conf:
  

    
Main class:
org.apache.spark.deploy.ClientApp		# 任务集群模式,由此启动driver
Arguments:
launch
spark://name2:7077
file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar
org.apache.spark.examples.SparkPi
5
Spark config:
(spark.jars,file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spark-examples_2.11-2.4.6.jar)
(spark.driver.supervise,false)
(spark.app.name,org.apache.spark.examples.SparkPi)
(spark.submit.deployMode,cluster)
(spark.master,spark://name2:7077)
Classpath elements:

```



driver日志：

```shell
Launch Command: "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java" "-cp" "/mnt/spark-alone/spark-2.
4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*" "-Xmx1024M" "-Dspark.driver.supervise=false" 
"-Dspark.app.name=org.apache.spark.examples.SparkPi" "-Dspark.master=spark://name2:7077" "-Dspark.submit.deployMode=clus
ter" "-Dspark.rpc.askTimeout=10s" "-Dspark.jars=file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spa
rk-examples_2.11-2.4.6.jar" "org.apache.spark.deploy.worker.DriverWrapper" "spark://Worker@192.168.72.35:7078" "/mnt/spa
rk-alone/spark-2.4.6-bin-hadoop2.6/work/driver-20200715162357-0000/spark-examples_2.11-2.4.6.jar" "org.apache.spark.exam
ples.SparkPi" "5"
========================================

20/07/15 16:24:02 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java cl
asses where applicable
20/07/15 16:24:03 INFO SecurityManager: Changing view acls to: root
20/07/15 16:24:03 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:24:03 INFO SecurityManager: Changing view acls groups to: 
20/07/15 16:24:03 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:24:03 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view per
missions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify 
permissions: Set()
20/07/15 16:24:05 INFO Utils: Successfully started service 'Driver' on port 36084.
20/07/15 16:24:05 INFO DriverWrapper: Driver address: 192.168.72.35:36084
20/07/15 16:24:05 INFO WorkerWatcher: Connecting to worker spark://Worker@192.168.72.35:7078
20/07/15 16:24:05 INFO SecurityManager: Changing view acls to: root
20/07/15 16:24:05 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:24:05 INFO SecurityManager: Changing view acls groups to: 
20/07/15 16:24:05 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:24:05 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view per
missions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify 
permissions: Set()
20/07/15 16:24:05 INFO TransportClientFactory: Successfully created connection to /192.168.72.35:7078 after 400 ms (0 ms
 spent in bootstraps)
20/07/15 16:24:05 INFO WorkerWatcher: Successfully connected to spark://Worker@192.168.72.35:7078
20/07/15 16:24:07 INFO SparkContext: Running Spark version 2.4.6
20/07/15 16:24:07 INFO SparkContext: Submitted application: Spark Pi
20/07/15 16:24:08 INFO SecurityManager: Changing view acls to: root
20/07/15 16:24:08 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:24:08 INFO SecurityManager: Changing view acls groups to:
20/07/15 16:24:08 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:24:08 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
20/07/15 16:24:08 INFO Utils: Successfully started service 'sparkDriver' on port 45157.
20/07/15 16:24:09 INFO SparkEnv: Registering MapOutputTracker
20/07/15 16:24:09 INFO SparkEnv: Registering BlockManagerMaster
20/07/15 16:24:09 INFO BlockManagerMasterEndpoint: Using org.apache.spark.storage.DefaultTopologyMapper for getting topology information
20/07/15 16:24:09 INFO BlockManagerMasterEndpoint: BlockManagerMasterEndpoint up
20/07/15 16:24:09 INFO DiskBlockManager: Created local directory at /tmp/blockmgr-3563f803-537f-4bdc-b2bc-192631c76fa1
20/07/15 16:24:09 INFO MemoryStore: MemoryStore started with capacity 413.9 MB
20/07/15 16:24:09 INFO SparkEnv: Registering OutputCommitCoordinator
20/07/15 16:24:11 INFO Utils: Successfully started service 'SparkUI' on port 4040.
20/07/15 16:24:11 INFO SparkUI: Bound SparkUI to 0.0.0.0, and started at http://name2:4040
20/07/15 16:24:11 INFO SparkContext: Added JAR file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/bin/../examples/jars/spar
k-examples_2.11-2.4.6.jar at spark://name2:45157/jars/spark-examples_2.11-2.4.6.jar with timestamp 1594801451855
20/07/15 16:24:12 INFO StandaloneAppClient$ClientEndpoint: Connecting to master spark://name2:7077...
20/07/15 16:24:12 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:7077 after 26 ms (
0 ms spent in bootstraps)
20/07/15 16:24:12 INFO StandaloneSchedulerBackend: Connected to Spark cluster with app ID app-20200715162412-0002
20/07/15 16:24:13 INFO Utils: Successfully started service 'org.apache.spark.network.netty.NettyBlockTransferService' on
 port 37529.
20/07/15 16:24:13 INFO NettyBlockTransferService: Server created on name2:37529
20/07/15 16:24:13 INFO BlockManager: Using org.apache.spark.storage.RandomBlockReplicationPolicy for block replication p
olicy
20/07/15 16:24:13 INFO BlockManagerMaster: Registering BlockManager BlockManagerId(driver, name2, 37529, None)
20/07/15 16:24:13 INFO BlockManagerMasterEndpoint: Registering block manager name2:37529 with 413.9 MB RAM, BlockManager
Id(driver, name2, 37529, None)
20/07/15 16:24:13 INFO BlockManagerMaster: Registered BlockManager BlockManagerId(driver, name2, 37529, None)
20/07/15 16:24:13 INFO BlockManager: Initialized BlockManager: BlockManagerId(driver, name2, 37529, None)
20/07/15 16:24:15 INFO StandaloneSchedulerBackend: SchedulerBackend is ready for scheduling beginning after reached minR
egisteredResourcesRatio: 0.0
20/07/15 16:24:17 INFO SparkContext: Starting job: reduce at SparkPi.scala:38
20/07/15 16:24:17 INFO DAGScheduler: Got job 0 (reduce at SparkPi.scala:38) with 5 output partitions
20/07/15 16:24:17 INFO DAGScheduler: Final stage: ResultStage 0 (reduce at SparkPi.scala:38)
20/07/15 16:24:17 INFO DAGScheduler: Final stage: ResultStage 0 (reduce at SparkPi.scala:38)
20/07/15 16:24:17 INFO DAGScheduler: Parents of final stage: List()
20/07/15 16:24:17 INFO DAGScheduler: Missing parents: List()
20/07/15 16:24:17 INFO DAGScheduler: Submitting ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34), which has no missing parents
20/07/15 16:24:18 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 2.0 KB, free 413.9 MB)
20/07/15 16:24:18 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 1381.0 B, free 413.9 MB)
20/07/15 16:24:18 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on name2:37529 (size: 1381.0 B, free: 413.9 MB)
20/07/15 16:24:18 INFO SparkContext: Created broadcast 0 from broadcast at DAGScheduler.scala:1163
20/07/15 16:24:19 INFO DAGScheduler: Submitting 5 missing tasks from ResultStage 0 (MapPartitionsRDD[1] at map at SparkPi.scala:34) (first 15 tasks are for partitions Vector(0, 1, 2, 3, 4))
20/07/15 16:24:19 INFO TaskSchedulerImpl: Adding task set 0.0 with 5 tasks
20/07/15 16:35:58 INFO StandaloneAppClient$ClientEndpoint: Executor added: app-20200715162412-0002/0 on worker-20200715163555-192.168.72.36-7078 (192.168.72.36:7078) with 1 core(s)
20/07/15 16:35:58 INFO StandaloneSchedulerBackend: Granted executor ID app-20200715162412-0002/0 on hostPort 192.168.72.36:7078 with 1 core(s), 1024.0 MB RAM
20/07/15 16:35:58 INFO StandaloneAppClient$ClientEndpoint: Executor updated: app-20200715162412-0002/0 is now RUNNING
20/07/15 16:36:04 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
20/07/15 16:36:08 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Registered executor NettyRpcEndpointRef(spark-client://Executor) (192.168.72.36:43934) with ID 0
20/07/15 16:36:08 INFO TaskSetManager: Starting task 0.0 in stage 0.0 (TID 0, 192.168.72.36, executor 0, partition 0, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:36:09 INFO BlockManagerMasterEndpoint: Registering block manager 192.168.72.36:46517 with 413.9 MB RAM, BlockManagerId(0, 192.168.72.36, 46517, None)
20/07/15 16:36:11 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on 192.168.72.36:46517 (size: 1381.0 B, free: 413.9 MB)
20/07/15 16:36:12 INFO TaskSetManager: Starting task 1.0 in stage 0.0 (TID 1, 192.168.72.36, executor 0, partition 1, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:36:12 INFO TaskSetManager: Finished task 0.0 in stage 0.0 (TID 0) in 4068 ms on 192.168.72.36 (executor 0) (
1/5)
20/07/15 16:36:13 INFO TaskSetManager: Starting task 2.0 in stage 0.0 (TID 2, 192.168.72.36, executor 0, partition 2, PR
OCESS_LOCAL, 7870 bytes)
20/07/15 16:36:13 INFO TaskSetManager: Finished task 1.0 in stage 0.0 (TID 1) in 225 ms on 192.168.72.36 (executor 0) (2
/5)
20/07/15 16:36:13 INFO TaskSetManager: Starting task 3.0 in stage 0.0 (TID 3, 192.168.72.36, executor 0, partition 3, PR
OCESS_LOCAL, 7870 bytes)
20/07/15 16:36:13 INFO TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 162 ms on 192.168.72.36 (executor 0) (3
/5)
20/07/15 16:36:13 INFO TaskSetManager: Starting task 4.0 in stage 0.0 (TID 4, 192.168.72.36, executor 0, partition 4, PR
OCESS_LOCAL, 7870 bytes)
20/07/15 16:36:13 INFO TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 162 ms on 192.168.72.36 (executor 0) (3/5)
20/07/15 16:36:13 INFO TaskSetManager: Starting task 4.0 in stage 0.0 (TID 4, 192.168.72.36, executor 0, partition 4, PROCESS_LOCAL, 7870 bytes)
20/07/15 16:36:13 INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 132 ms on 192.168.72.36 (executor 0) (4/5)
20/07/15 16:36:13 INFO TaskSetManager: Finished task 4.0 in stage 0.0 (TID 4) in 130 ms on 192.168.72.36 (executor 0) (5/5)
20/07/15 16:36:13 INFO DAGScheduler: ResultStage 0 (reduce at SparkPi.scala:38) finished in 716.003 s
20/07/15 16:36:13 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool 
20/07/15 16:36:13 INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 716.397496 s
20/07/15 16:36:13 INFO SparkUI: Stopped Spark web UI at http://name2:4040
20/07/15 16:36:13 INFO StandaloneSchedulerBackend: Shutting down all executors
20/07/15 16:36:13 INFO CoarseGrainedSchedulerBackend$DriverEndpoint: Asking each executor to shut down
20/07/15 16:36:13 INFO MapOutputTrackerMasterEndpoint: MapOutputTrackerMasterEndpoint stopped!
20/07/15 16:36:14 INFO MemoryStore: MemoryStore cleared
20/07/15 16:36:14 INFO BlockManager: BlockManager stopped
20/07/15 16:36:14 INFO BlockManagerMaster: BlockManagerMaster stopped
20/07/15 16:36:14 INFO OutputCommitCoordinator$OutputCommitCoordinatorEndpoint: OutputCommitCoordinator stopped!
20/07/15 16:36:14 INFO SparkContext: Successfully stopped SparkContext
20/07/15 16:36:14 INFO ShutdownHookManager: Shutdown hook called
20/07/15 16:36:14 INFO ShutdownHookManager: Deleting directory /tmp/spark-24fc38ee-987b-41e7-aeef-f6aba520028d
20/07/15 16:36:14 INFO ShutdownHookManager: Deleting directory /tmp/spark-2a385261-9312-489b-8fed-0b48c7f408bb

```

application日志

```shell
Spark Executor Command: "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java" "-cp" "/mnt/spark-alone/
spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*" "-Xmx1024M" "-Dspark.driver.port=4515
7" "-Dspark.rpc.askTimeout=10s" "org.apache.spark.executor.CoarseGrainedExecutorBackend" "--driver-url" "spark://CoarseG
rainedScheduler@name2:45157" "--executor-id" "0" "--hostname" "192.168.72.36" "--cores" "1" "--app-id" "app-202007151624
12-0002" "--worker-url" "spark://Worker@192.168.72.36:7078"
========================================

20/07/15 16:36:02 INFO CoarseGrainedExecutorBackend: Started daemon with process name: 12443@name3
20/07/15 16:36:02 INFO SignalUtils: Registered signal handler for TERM
20/07/15 16:36:02 INFO SignalUtils: Registered signal handler for HUP
20/07/15 16:36:02 INFO SignalUtils: Registered signal handler for INT
20/07/15 16:36:03 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java cl
asses where applicable
20/07/15 16:36:04 INFO SecurityManager: Changing view acls to: root
20/07/15 16:36:04 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:36:04 INFO SecurityManager: Changing view acls groups to: 
20/07/15 16:36:04 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:36:04 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view per
missions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify 
permissions: Set()
20/07/15 16:36:06 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:45157 after 363 ms
 (0 ms spent in bootstraps)
20/07/15 16:36:06 INFO SecurityManager: Changing view acls to: root
20/07/15 16:36:06 INFO SecurityManager: Changing modify acls to: root
20/07/15 16:36:06 INFO SecurityManager: Changing view acls groups to: 
20/07/15 16:36:06 INFO SecurityManager: Changing modify acls groups to: 
20/07/15 16:36:06 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view per
missions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify 
permissions: Set()
20/07/15 16:36:07 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:45157 after 12 ms 
(0 ms spent in bootstraps)
20/07/15 16:36:07 INFO DiskBlockManager: Created local directory at /tmp/spark-819fbed2-74c7-4d25-98e5-0aa6862242bb/exec
utor-cb376648-3595-446b-98f8-dc67cd3af9b7/blockmgr-59fe6090-19f0-4e1c-bf43-e6d19b9ef6cd
20/07/15 16:36:07 INFO MemoryStore: MemoryStore started with capacity 413.9 MB
20/07/15 16:36:08 INFO WorkerWatcher: Connecting to worker spark://Worker@192.168.72.36:7078
20/07/15 16:36:08 INFO CoarseGrainedExecutorBackend: Connecting to driver: spark://CoarseGrainedScheduler@name2:45157
20/07/15 16:36:08 INFO TransportClientFactory: Successfully created connection to /192.168.72.36:7078 after 21 ms (0 ms 
spent in bootstraps)
20/07/15 16:36:08 INFO WorkerWatcher: Successfully connected to spark://Worker@192.168.72.36:7078
20/07/15 16:36:08 INFO CoarseGrainedExecutorBackend: Successfully registered with driver
20/07/15 16:36:08 INFO Executor: Starting executor ID 0 on host 192.168.72.36
20/07/15 16:36:09 INFO Utils: Successfully started service 'org.apache.spark.network.netty.NettyBlockTransferService' on port 46517.
20/07/15 16:36:09 INFO NettyBlockTransferService: Server created on 192.168.72.36:46517
20/07/15 16:36:09 INFO BlockManager: Using org.apache.spark.storage.RandomBlockReplicationPolicy for block replication policy
20/07/15 16:36:09 INFO BlockManagerMaster: Registering BlockManager BlockManagerId(0, 192.168.72.36, 46517, None)
20/07/15 16:36:09 INFO BlockManagerMaster: Registered BlockManager BlockManagerId(0, 192.168.72.36, 46517, None)
20/07/15 16:36:09 INFO BlockManager: Initialized BlockManager: BlockManagerId(0, 192.168.72.36, 46517, None)
20/07/15 16:36:09 INFO CoarseGrainedExecutorBackend: Got assigned task 0
20/07/15 16:36:09 INFO Executor: Running task 0.0 in stage 0.0 (TID 0)
20/07/15 16:36:09 INFO Executor: Fetching spark://name2:45157/jars/spark-examples_2.11-2.4.6.jar with timestamp 1594801451855
20/07/15 16:36:09 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:45157 after 48 ms (0 ms spent in bootstraps)
20/07/15 16:36:09 INFO Utils: Fetching spark://name2:45157/jars/spark-examples_2.11-2.4.6.jar to /tmp/spark-819fbed2-74c7-4d25-98e5-0aa6862242bb/executor-cb376648-3595-446b-98f8-dc67cd3af9b7/spark-b198cd58-2365-480f-abaa-63fa9eb4ebb5/fetchFileTemp9113747687450336075.tmp
20/07/15 16:36:10 INFO Utils: Copying /tmp/spark-819fbed2-74c7-4d25-98e5-0aa6862242bb/executor-cb376648-3595-446b-98f8-dc67cd3af9b7/spark-b198cd58-2365-480f-abaa-63fa9eb4ebb5/-8286224401594801451855_cache to /mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work/app-20200715162412-0002/0/./spark-examples_2.11-2.4.6.jar
20/07/15 16:36:10 INFO Executor: Adding file:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/work/app-20200715162412-0002/0/./spark-examples_2.11-2.4.6.jar to class loader
20/07/15 16:36:10 INFO TorrentBroadcast: Started reading broadcast variable 0
20/07/15 16:36:11 INFO TransportClientFactory: Successfully created connection to name2/192.168.72.35:37529 after 45 ms (0 ms spent in bootstraps)
20/07/15 16:36:11 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 1381.0 B, free 413.9 MB)
20/07/15 16:36:11 INFO TorrentBroadcast: Reading broadcast variable 0 took 682 ms
20/07/15 16:36:11 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 2.0 KB, free 413.9 MB)
20/07/15 16:36:12 INFO Executor: Finished task 0.0 in stage 0.0 (TID 0). 910 bytes result sent to driver
20/07/15 16:36:12 INFO CoarseGrainedExecutorBackend: Got assigned task 1
20/07/15 16:36:12 INFO Executor: Running task 1.0 in stage 0.0 (TID 1)
20/07/15 16:36:12 INFO Executor: Finished task 1.0 in stage 0.0 (TID 1). 824 bytes result sent to driver
20/07/15 16:36:12 INFO CoarseGrainedExecutorBackend: Got assigned task 2
20/07/15 16:36:12 INFO Executor: Running task 2.0 in stage 0.0 (TID 2)
20/07/15 16:36:13 INFO Executor: Finished task 2.0 in stage 0.0 (TID 2). 867 bytes result sent to driver
20/07/15 16:36:13 INFO CoarseGrainedExecutorBackend: Got assigned task 3
20/07/15 16:36:13 INFO Executor: Running task 3.0 in stage 0.0 (TID 3)
20/07/15 16:36:13 INFO Executor: Finished task 3.0 in stage 0.0 (TID 3). 867 bytes result sent to driver
20/07/15 16:36:13 INFO CoarseGrainedExecutorBackend: Got assigned task 4
20/07/15 16:36:13 INFO Executor: Running task 4.0 in stage 0.0 (TID 4)
20/07/15 16:36:13 INFO Executor: Finished task 4.0 in stage 0.0 (TID 4). 824 bytes result sent to driver
20/07/15 16:36:13 INFO CoarseGrainedExecutorBackend: Driver commanded a shutdown
20/07/15 16:36:13 INFO MemoryStore: MemoryStore cleared
20/07/15 16:36:13 INFO Bl
```

