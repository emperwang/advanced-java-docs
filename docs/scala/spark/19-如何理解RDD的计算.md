[TOC]

# 如何理解spark中的RDD的计算

经过前面分析了解到，driver提交的任务最终其实只有两种：ShuffleMapTask和ResultTask中，看一下其在真实的执行RDD的计算时，是如何操作的：

> org.apache.spark.scheduler.ShuffleMapTask#runTask

```scala
// 具体的任务的执行
override def runTask(context: TaskContext): MapStatus = {
    // Deserialize the RDD using the broadcast variable.
    val threadMXBean = ManagementFactory.getThreadMXBean
    // 反序列化的开始时间
    val deserializeStartTime = System.currentTimeMillis()
    val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
        threadMXBean.getCurrentThreadCpuTime
    } else 0L
    val ser = SparkEnv.get.closureSerializer.newInstance()
    val (rdd, dep) = ser.deserialize[(RDD[_], ShuffleDependency[_, _, _])](
        ByteBuffer.wrap(taskBinary.value), Thread.currentThread.getContextClassLoader)
    // 记录序列化 花费的时间
    _executorDeserializeTime = System.currentTimeMillis() - deserializeStartTime
    // 反序列花费的 cpu时间
    _executorDeserializeCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
        threadMXBean.getCurrentThreadCpuTime - deserializeStartCpuTime
    } else 0L

    var writer: ShuffleWriter[Any, Any] = null
    try {
        //  获取  shuffleManager
        val manager = SparkEnv.get.shuffleManager
        // 获取 shuffle的writer函数
        writer = manager.getWriter[Any, Any](dep.shuffleHandle, partitionId, context)
        // 开始把此 stage结果记录下来
        writer.write(rdd.iterator(partition, context).asInstanceOf[Iterator[_ <: Product2[Any, Any]]])
        writer.stop(success = true).get
    } catch {
 	.....
    }
}
```

> org.apache.spark.scheduler.ResultTask#runTask

```java
 override def runTask(context: TaskContext): U = {
    // Deserialize the RDD and the func using the broadcast variables.
    val threadMXBean = ManagementFactory.getThreadMXBean
    // 反序列化的开始时间
    val deserializeStartTime = System.currentTimeMillis()
    // 反序列的cpu开始时间
    val deserializeStartCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime
    } else 0L
    // 闭包的 反序列化
    val ser = SparkEnv.get.closureSerializer.newInstance()
    // taskBinary的反序列
    // 反序列化 task 以及 rdd
    val (rdd, func) = ser.deserialize[(RDD[T], (TaskContext, Iterator[T]) => U)](
      ByteBuffer.wrap(taskBinary.value), Thread.currentThread.getContextClassLoader)
    // 反序列的花费的时间
    _executorDeserializeTime = System.currentTimeMillis() - deserializeStartTime
    // 反序列化花费的cpu 时间
    _executorDeserializeCpuTime = if (threadMXBean.isCurrentThreadCpuTimeSupported) {
      threadMXBean.getCurrentThreadCpuTime - deserializeStartCpuTime
    } else 0L
  // 使用定义的function 对rdd中内容进行执行
    func(context, rdd.iterator(partition, context))
  }
```

可以看到两者的RDD计算都是调用 rdd.iterator(partition, context) 来进行的，这里咱们看一下rdd的此操作：

> org.apache.spark.rdd.RDD#iterator

```java
// 对于一个 rdd的真实计算
final def iterator(split: Partition, context: TaskContext): Iterator[T] = {
    // 如果有进行 缓存,则先尝试从缓存中获取结果; 如果缓存中没有,则进行计算
    if (storageLevel != StorageLevel.NONE) {
        getOrCompute(split, context)
    } else {
        // 进行计算 或者 从 checkpoint中读取结果
        computeOrReadCheckpoint(split, context)
    }
}
```

如果设置了进行缓存，则从缓存中进行读取，否则进行计算；如果没有设置缓存，则尝试从checkPoint中读取，否则进行计算。

这里看一下 getOrCompute实现：

```java
    // 获取 或者 重新计算 partition的值
  private[spark] def getOrCompute(partition: Partition, context: TaskContext): Iterator[T] = {
      // 根据 rddId 和paraition的 索引生成 此 partition对应的 blockId
      // "rdd_" + rddId + "_" + splitIndex
    val blockId = RDDBlockId(id, partition.index)
    var readCachedBlock = true
    // This method is called on executors, so we need call SparkEnv.get instead of sc.env.
      // 根据blockManager 去获取  对应的 value
    SparkEnv.get.blockManager.getOrElseUpdate(blockId, storageLevel, elementClassTag, () => {
      readCachedBlock = false
      // 从 checkPoint中读取或者进行计算
      computeOrReadCheckpoint(partition, context)
    }) match {
      case Left(blockResult) =>
        if (readCachedBlock) {
          val existingMetrics = context.taskMetrics().inputMetrics
          // 更新 读取的 字节数
          existingMetrics.incBytesRead(blockResult.bytes)
          // 创建 一个 InterruptibleIterator
          new InterruptibleIterator[T](context, blockResult.data.asInstanceOf[Iterator[T]]) {
            override def next(): T = {
              existingMetrics.incRecordsRead(1)
              delegate.next()
            }
          }
        } else {
            // 返回一个 迭代器
          new InterruptibleIterator(context, blockResult.data.asInstanceOf[Iterator[T]])
        }
      case Right(iter) =>
        new InterruptibleIterator(context, iter.asInstanceOf[Iterator[T]])
    }
  }
```

> org.apache.spark.rdd.RDD#computeOrReadCheckpoint

```java
// 重新计算此rdd分区，或者 读取 checkPoint
private[spark] def computeOrReadCheckpoint(split: Partition, context: TaskContext): Iterator[T] =
{
    // 判断是否有 checkPoint
    if (isCheckpointedAndMaterialized) {
        // 返回此 rdd 依赖的第一个父类 的 iterator
        firstParent[T].iterator(split, context)
    } else {
        // 重新计算
        compute(split, context)
    }
}
```

这里看到，如果有进行checkpoint，则返回此rdd依赖的第一个parent的迭代器，否则进行计算。

这里的点要**注意**一下：

返回依赖的第一个RDD的iterator，此操作呢又是rdd计算的开始，之后又会到这里；最后会找到第一个rdd，并调用其compute方法来进行计算，计算完成后会作为下一个rdd的数据输入。 一个递归计算的开始。

RDD父类的compute方法是一个抽象方法，需要由具体的子类来实现，当然了不同的子类操作肯定不会相同，具体的实现也不尽相同； 模板模式的又一个实例。

这里看一下HadoopRDD的实现：

```scala
 // HadoopRDD的 计算
  // 由此可见此处的也只是进行了操作的定义,并没有进行计算的操作,等到需要计算时 才会进行计算
  override def compute(theSplit: Partition, context: TaskContext): InterruptibleIterator[(K, V)] = {
    // 这里创建一个 迭代器, 其中指定了 要获取数据时, 如何进行操作
    val iter = new NextIterator[(K, V)] {

      private val split = theSplit.asInstanceOf[HadoopPartition]
      logInfo("Input split: " + split.inputSplit)
      private val jobConf = getJobConf()

      private val inputMetrics = context.taskMetrics().inputMetrics
      private val existingBytesRead = inputMetrics.bytesRead

      // Sets InputFileBlockHolder for the file block's information
      split.inputSplit.value match {
        case fs: FileSplit =>
          InputFileBlockHolder.set(fs.getPath.toString, fs.getStart, fs.getLength)
        case _ =>
          InputFileBlockHolder.unset()
      }

      // Find a function that will return the FileSystem bytes read by this thread. Do this before
      // creating RecordReader, because RecordReader's constructor might read some bytes
      private val getBytesReadCallback: Option[() => Long] = split.inputSplit.value match {
        case _: FileSplit | _: CombineFileSplit =>
          Some(SparkHadoopUtil.get.getFSBytesReadOnThreadCallback())
        case _ => None
      }

      // We get our input bytes from thread-local Hadoop FileSystem statistics.
      // If we do a coalesce, however, we are likely to compute multiple partitions in the same
      // task and in the same thread, in which case we need to avoid override values written by
      // previous partitions (SPARK-13071).
      private def updateBytesRead(): Unit = {
        getBytesReadCallback.foreach { getBytesRead =>
          inputMetrics.setBytesRead(existingBytesRead + getBytesRead())
        }
      }

      private var reader: RecordReader[K, V] = null
      private val inputFormat = getInputFormat(jobConf)
      HadoopRDD.addLocalConfiguration(
        new SimpleDateFormat("yyyyMMddHHmmss", Locale.US).format(createTime),
        context.stageId, theSplit.index, context.attemptNumber, jobConf)
     // 获取读取文件数据的 reader
      reader =
        try {
          inputFormat.getRecordReader(split.inputSplit.value, jobConf, Reporter.NULL)
        } catch {
          case e: FileNotFoundException if ignoreMissingFiles =>
            logWarning(s"Skipped missing file: ${split.inputSplit}", e)
            finished = true
            null
          // Throw FileNotFoundException even if `ignoreCorruptFiles` is true
          case e: FileNotFoundException if !ignoreMissingFiles => throw e
          case e: IOException if ignoreCorruptFiles =>
            logWarning(s"Skipped the rest content in the corrupted file: ${split.inputSplit}", e)
            finished = true
            null
        }
      // Register an on-task-completion callback to close the input stream.
      // 添加一个完成监听器
      context.addTaskCompletionListener[Unit] { context =>
        // Update the bytes read before closing is to make sure lingering bytesRead statistics in
        // this thread get correctly added.
        updateBytesRead()
        closeIfNeeded()
      }

      private val key: K = if (reader == null) null.asInstanceOf[K] else reader.createKey()
      private val value: V = if (reader == null) null.asInstanceOf[V] else reader.createValue()

      override def getNext(): (K, V) = {
        try {
          finished = !reader.next(key, value)
        } catch {
          case e: FileNotFoundException if ignoreMissingFiles =>
            logWarning(s"Skipped missing file: ${split.inputSplit}", e)
            finished = true
          // Throw FileNotFoundException even if `ignoreCorruptFiles` is true
          case e: FileNotFoundException if !ignoreMissingFiles => throw e
          case e: IOException if ignoreCorruptFiles =>
            logWarning(s"Skipped the rest content in the corrupted file: ${split.inputSplit}", e)
            finished = true
        }
        if (!finished) {
          inputMetrics.incRecordsRead(1)
        }
        if (inputMetrics.recordsRead % SparkHadoopUtil.UPDATE_INPUT_METRICS_INTERVAL_RECORDS == 0) {
          updateBytesRead()
        }
        (key, value)
      }

      override def close(): Unit = {
        if (reader != null) {
          InputFileBlockHolder.unset()
          try {
            reader.close()
          } catch {
            case e: Exception =>
              if (!ShutdownHookManager.inShutdown()) {
                logWarning("Exception in RecordReader.close()", e)
              }
          } finally {
            reader = null
          }
          if (getBytesReadCallback.isDefined) {
            updateBytesRead()
          } else if (split.inputSplit.value.isInstanceOf[FileSplit] ||
                     split.inputSplit.value.isInstanceOf[CombineFileSplit]) {
            // If we can't get the bytes read from the FS stats, fall back to the split size,
            // which may be inaccurate.
            try {
              inputMetrics.incBytesRead(split.inputSplit.value.getLength)
            } catch {
              case e: java.io.IOException =>
                logWarning("Unable to get input size to set InputMetrics for task", e)
            }
          }
        }
      }
    }
    new InterruptibleIterator[(K, V)](context, iter)
  }
```

```scala
class InterruptibleIterator[+T](val context: TaskContext, val delegate: Iterator[T])
  extends Iterator[T] {

  def hasNext: Boolean = {
    // TODO(aarondav/rxin): Check Thread.interrupted instead of context.interrupted if interrupt
    // is allowed. The assumption is that Thread.interrupted does not have a memory fence in read
    // (just a volatile field in C), while context.interrupted is a volatile in the JVM, which
    // introduces an expensive read fence.
    context.killTaskIfInterrupted()
    delegate.hasNext
  }

  def next(): T = delegate.next()
}
```

此HadoopRDD的计算创建了一个NextIterator 的迭代器，并实现了其中的方法，如：next 读取下一个数据，haxNext是否有下一个数据等。 然后使用InterruptibleIterator 封装一下，进行返回。**注意：** 这里只是创建了具体的操作方法，并没有进行读取，真正的读取是到 action也就是 executor中执行计算时才真正进行了读取操作。执行过程如下：

![](rdd-compute.png)













































































