[TOC]

# spark解析hostname错误

在使用中发现，当slaves配置文件中写的worker主机名字中有 "_" 时，会导致解析错误。

错误信息：

```shell
20/07/15 17:24:49 ERROR SparkUncaughtExceptionHandler: Uncaught exception in thread Thread[main,5,main]
org.apache.spark.SparkException: Invalid master URL: spark://name_2:7077
        at org.apache.spark.util.Utils$.extractHostPortFromSparkUrl(Utils.scala:2407)
        at org.apache.spark.rpc.RpcAddress$.fromSparkURL(RpcAddress.scala:47)
        at org.apache.spark.deploy.worker.Worker$$anonfun$16.apply(Worker.scala:810)
        at org.apache.spark.deploy.worker.Worker$$anonfun$16.apply(Worker.scala:810)
        at scala.collection.TraversableLike$$anonfun$map$1.apply(TraversableLike.scala:234)
        at scala.collection.TraversableLike$$anonfun$map$1.apply(TraversableLike.scala:234)
        at scala.collection.IndexedSeqOptimized$class.foreach(IndexedSeqOptimized.scala:33)
        at scala.collection.mutable.ArrayOps$ofRef.foreach(ArrayOps.scala:186)
        at scala.collection.TraversableLike$class.map(TraversableLike.scala:234)
        at scala.collection.mutable.ArrayOps$ofRef.map(ArrayOps.scala:186)
        at org.apache.spark.deploy.worker.Worker$.startRpcEnvAndEndpoint(Worker.scala:810)
        at org.apache.spark.deploy.worker.Worker$.main(Worker.scala:779)
        at org.apache.spark.deploy.worker.Worker.main(Worker.scala)
20/07/15 17:24:49 INFO ShutdownHookManager: Shutdown hook called

```

可以看一下hostname解析类:

> org.apache.spark.util.Utils#extractHostPortFromSparkUrl

```scala
  @throws(classOf[SparkException])
  def extractHostPortFromSparkUrl(sparkUrl: String): (String, Int) = {
    try {
        // 使用java中的类来进行解析
      val uri = new java.net.URI(sparkUrl)
        // 解析完成后,获取schema 以及 host  port等信息
      val host = uri.getHost
      val port = uri.getPort
        // 解析出错呢,就抛出异常
      if (uri.getScheme != "spark" ||
        host == null ||
        port < 0 ||
        (uri.getPath != null && !uri.getPath.isEmpty) || // uri.getPath returns "" instead of null
        uri.getFragment != null ||
        uri.getQuery != null ||
        uri.getUserInfo != null) {
        throw new SparkException("Invalid master URL: " + sparkUrl)
      }
        // 返回解析的结果
      (host, port)
    } catch {
      case e: java.net.URISyntaxException =>
        throw new SparkException("Invalid master URL: " + sparkUrl, e)
    }
  }
```

总之解析的方式还是很简单的，看起来也不像是spark的错误，看起来是 java内部类的解析错误，下面写两个demo验证一下:

```java
    @Test
    public void testUri() throws URISyntaxException {
        String str="spark://name2:7077";
        URI uri = new URI(str);
        System.out.println(uri.getScheme());
        System.out.println(uri.getHost());
        System.out.println(uri.getPort());
    }

// 结果:
spark
name2
7077
```



```java
    @Test
    public void testUri() throws URISyntaxException {
        String str1="spark://name_2:7077";
        URI uri = new URI(str1);
        System.out.println(uri.getScheme());
        System.out.println(uri.getHost());
        System.out.println(uri.getPort());
    }

// 结果
spark
null
-1
```

由上面可以看到，解析是有java的URI类引起的。