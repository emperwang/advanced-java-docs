[TOC]

# spark-master启动2-launcher.Main-命令构建

上篇分析启动脚本时，看到最终启动是在spark-class脚本中使用exec调用java命令来启动的。不过在启动之间，使用了一个java类来构建最终的启动命令：

```shell
# 此函数就是使用 java -cp 来运行org.apache.spark.launcher.Main来构建启动命令
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
```

那本篇就来看一下这个构建命令的java类：org.apache.spark.launcher.Main，调用时的参数：

```shell
# 调用spark-class的参数
spark-class org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
# build-command
build_command org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
# 执行参数构建类的命令
/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -Xmx128m -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' org.apache.spark.launcher.Main org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080

# 最终构建的命令
exec /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/bin/java -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/conf/:/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*' -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=name2:2181,name3:2181,name4:2181 -Dspark.deploy.zookeeper.dir=/spark-cluster -Xmx1g org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
```

下面咱们就分析一下这个构建命令的类：

此类就是程序的主要入口，用来把参数，以及配置文件中的项组合起来，拼接成一个java程序运行的格式，之后再把命令输出到终端中，shell 脚本读取终端的内容，把读取到的命令 作为exec参数来启动程序。

> org.apache.spark.launcher.Main#main

```java
 // 启动Master的的命令
 // java -Xmx128m -cp '/mnt/spark-alone/spark-2.4.6-bin-hadoop2.6/jars/*'
 // org.apache.spark.launcher.Main org.apache.spark.deploy.master.Master --host name2 --port 7077 --webui-port 8080
  public static void main(String[] argsArray) throws Exception {
    // 参数的个数检测
    checkArgument(argsArray.length > 0, "Not enough arguments: missing class name.");
    // 把命令行传递的参数 封装到一个 list中
    List<String> args = new ArrayList<>(Arrays.asList(argsArray));
    // 要操作的类
    String className = args.remove(0);
    //  是否打印 命令
    boolean printLaunchCommand = !isEmpty(System.getenv("SPARK_PRINT_LAUNCH_COMMAND"));
    Map<String, String> env = new HashMap<>();
    List<String> cmd;
    // 如果操作的类是 SparkSubmit, 说明是提交任务
    // 这个先放到后面, 等分析到 SparkSubmit 再进行分析
    if (className.equals("org.apache.spark.deploy.SparkSubmit")) {
      try {
        AbstractCommandBuilder builder = new SparkSubmitCommandBuilder(args);
        cmd = buildCommand(builder, env, printLaunchCommand);
      } catch (IllegalArgumentException e) {
        printLaunchCommand = false;
        System.err.println("Error: " + e.getMessage());
        System.err.println();

        MainClassOptionParser parser = new MainClassOptionParser();
        try {
          parser.parse(args);
        } catch (Exception ignored) {
          // Ignore parsing exceptions.
        }

        List<String> help = new ArrayList<>();
        if (parser.className != null) {
          help.add(parser.CLASS);
          help.add(parser.className);
        }
        help.add(parser.USAGE_ERROR);
        AbstractCommandBuilder builder = new SparkSubmitCommandBuilder(help);
        cmd = buildCommand(builder, env, printLaunchCommand);
      }
    } else {  // spark-class的操作; 此处其 spark-class的操作,故走这里
      AbstractCommandBuilder builder = new SparkClassCommandBuilder(className, args);
      // 创建命令
      cmd = buildCommand(builder, env, printLaunchCommand);
    }
    // 如果是windows系统,则进行此操作
    if (isWindows()) {
      System.out.println(prepareWindowsCommand(cmd, env));
    } else {
      // 不是windows系统,则进行此操作
      // In bash, use NULL as the arg separator since it cannot be used in an argument.
      // 针对unix系统,对构建好的命令,
      List<String> bashCmd = prepareBashCommand(cmd, env);
      // 把构建好的命令打印到终端
      for (String c : bashCmd) {
        System.out.print(c);
        System.out.print('\0'); // \0 字符串的结束符
      }
    }
  }
```



> org.apache.spark.launcher.SparkClassCommandBuilder

```java
  // 参数分别是: 要操作的class类, 以及 参数
  SparkClassCommandBuilder(String className, List<String> classArgs) {
    this.className = className;
    this.classArgs = classArgs;
  }
```

> org.apache.spark.launcher.Main#buildCommand

```java
// 构建命令
private static List<String> buildCommand(
      AbstractCommandBuilder builder,
      Map<String, String> env,
      boolean printLaunchCommand) throws IOException, IllegalArgumentException {
    // 调用builder 来构建命令
    List<String> cmd = builder.buildCommand(env);
    // 如果设置了打印命令,则把构建好的命令 打印到终端
    if (printLaunchCommand) {
      System.err.println("Spark Command: " + join(" ", cmd));
      System.err.println("========================================");
    }
    return cmd;
  }
```

> org.apache.spark.launcher.SparkClassCommandBuilder#buildCommand

```java
 // 这里命令构建根据 spark-class和submit 分为两种,此处看 spark-class的命令构建
 @Override
  public List<String> buildCommand(Map<String, String> env)
      throws IOException, IllegalArgumentException {
    List<String> javaOptsKeys = new ArrayList<>();
    String memKey = null;
    String extraClassPath = null;
    // Master, Worker, HistoryServer, ExternalShuffleService, MesosClusterDispatcher use
    // SPARK_DAEMON_JAVA_OPTS (and specific opts) + SPARK_DAEMON_MEMORY.
    // 根据不同的类, 来创建不同的 变量
    switch (className) {
      case "org.apache.spark.deploy.master.Master":
        javaOptsKeys.add("SPARK_DAEMON_JAVA_OPTS");
        javaOptsKeys.add("SPARK_MASTER_OPTS");
        extraClassPath = getenv("SPARK_DAEMON_CLASSPATH");
        memKey = "SPARK_DAEMON_MEMORY";
        break;
      case "org.apache.spark.deploy.worker.Worker":
        javaOptsKeys.add("SPARK_DAEMON_JAVA_OPTS");
        javaOptsKeys.add("SPARK_WORKER_OPTS");
        extraClassPath = getenv("SPARK_DAEMON_CLASSPATH");
        memKey = "SPARK_DAEMON_MEMORY";
        break;
      case "org.apache.spark.deploy.history.HistoryServer":
        javaOptsKeys.add("SPARK_DAEMON_JAVA_OPTS");
        javaOptsKeys.add("SPARK_HISTORY_OPTS");
        extraClassPath = getenv("SPARK_DAEMON_CLASSPATH");
        memKey = "SPARK_DAEMON_MEMORY";
        break;
      case "org.apache.spark.executor.CoarseGrainedExecutorBackend":
        javaOptsKeys.add("SPARK_EXECUTOR_OPTS");
        memKey = "SPARK_EXECUTOR_MEMORY";
        extraClassPath = getenv("SPARK_EXECUTOR_CLASSPATH");
        break;
      case "org.apache.spark.executor.MesosExecutorBackend":
        javaOptsKeys.add("SPARK_EXECUTOR_OPTS");
        memKey = "SPARK_EXECUTOR_MEMORY";
        extraClassPath = getenv("SPARK_EXECUTOR_CLASSPATH");
        break;
      case "org.apache.spark.deploy.mesos.MesosClusterDispatcher":
        javaOptsKeys.add("SPARK_DAEMON_JAVA_OPTS");
        extraClassPath = getenv("SPARK_DAEMON_CLASSPATH");
        memKey = "SPARK_DAEMON_MEMORY";
        break;
      case "org.apache.spark.deploy.ExternalShuffleService":
      case "org.apache.spark.deploy.mesos.MesosExternalShuffleService":
        javaOptsKeys.add("SPARK_DAEMON_JAVA_OPTS");
        javaOptsKeys.add("SPARK_SHUFFLE_OPTS");
        extraClassPath = getenv("SPARK_DAEMON_CLASSPATH");
        memKey = "SPARK_DAEMON_MEMORY";
        break;
      default:
        memKey = "SPARK_DRIVER_MEMORY";
        break;
    }
      // 构建java 运行格式的命令
    List<String> cmd = buildJavaCommand(extraClassPath);
    // 获取javaOptsKeys 配置项的值,遍历并添加到  cmd中
    for (String key : javaOptsKeys) {
      String envValue = System.getenv(key);
      if (!isEmpty(envValue) && envValue.contains("Xmx")) {
        String msg = String.format("%s is not allowed to specify max heap(Xmx) memory settings " +
                "(was %s). Use the corresponding configuration instead.", key, envValue);
        throw new IllegalArgumentException(msg);
      }
      addOptionString(cmd, envValue);
    }
    // 获取设定的内存
    String mem = firstNonEmpty(memKey != null ? System.getenv(memKey) : null, DEFAULT_MEM);
    // 最大内存
    cmd.add("-Xmx" + mem);
    // class的全限定类名
    cmd.add(className);
    // 参数
    cmd.addAll(classArgs);
    return cmd;
  }
```

> org.apache.spark.launcher.AbstractCommandBuilder#buildJavaCommand

```java
// 把命令拼接为 java 命令运行的格式:
List<String> buildJavaCommand(String extraClassPath) throws IOException {
    List<String> cmd = new ArrayList<>();
    String envJavaHome;
    // 构建java命令的全路径
    // 构建后如: /opt/jdk/bin/java
    if (javaHome != null) {
      cmd.add(join(File.separator, javaHome, "bin", "java"));
    } else if ((envJavaHome = System.getenv("JAVA_HOME")) != null) {
        cmd.add(join(File.separator, envJavaHome, "bin", "java"));
    } else {
        cmd.add(join(File.separator, System.getProperty("java.home"), "bin", "java"));
    }
    // Load extra JAVA_OPTS from conf/java-opts, if it exists.
    // getConfDir获取配置目录,最后添加上java-opts,就是读取配置目录中的 java-opts
    File javaOpts = new File(join(File.separator, getConfDir(), "java-opts"));
    if (javaOpts.isFile()) {
      try (BufferedReader br = new BufferedReader(new InputStreamReader(
          new FileInputStream(javaOpts), StandardCharsets.UTF_8))) {
        String line;
        while ((line = br.readLine()) != null) {  // 把从 java-opts文件中读取的配置, 添加到cmd中
          addOptionString(cmd, line);
        }
      }
    }
	// java命令的 -cp 参数; 用于启动class
    cmd.add("-cp");
    // 设置classpath
    // buildClassPath 构建运行的 classpath
    cmd.add(join(File.pathSeparator, buildClassPath(extraClassPath)));
    return cmd;
  }
```

> org.apache.spark.launcher.AbstractCommandBuilder#addOptionString

```java
// 把 options 选项设置到 cmd中
void addOptionString(List<String> cmd, String options) {
  if (!isEmpty(options)) {
    for (String opt : parseOptionString(options)) {
      cmd.add(opt);
    }
  }
}
```

> org.apache.spark.launcher.CommandBuilderUtils#join(java.lang.String, java.lang.Iterable<java.lang.String>)

```java
// 把命令拼接起来  中间使用分隔符进行隔离
static String join(String sep, Iterable<String> elements) {
    StringBuilder sb = new StringBuilder();
    for (String e : elements) {
      if (e != null) {
        if (sb.length() > 0) {
          sb.append(sep);
        }
        sb.append(e);
      }
    }
    return sb.toString();
  }
```

可见最终运行的名字由一下几个方面组成:

1. 命令行传递
2. conf/java-opts文件中的jvm参数
3. 执行运行的class

最后把命令打印到 终端中，由脚本读取传递给exec执行。





























