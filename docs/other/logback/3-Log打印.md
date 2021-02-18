# log是如何打印的

今天来看一下logBack中的打印相关源码。

看一下logger类中的打印方法，其中有debug，info，trace等不同层级的打印。咱们就拿debug方法来入手。

```java
public void debug(String msg) {
    filterAndLog_0_Or3Plus(FQCN, null, Level.DEBUG, msg, null, null);
}

public void debug(String format, Object arg) {
    filterAndLog_1(FQCN, null, Level.DEBUG, format, arg, null);
}
```

重载方法有好多个，咱们看着两个常用的就好。

```java
private void filterAndLog_0_Or3Plus(final String localFQCN, final Marker marker, final Level level, final String msg, final Object[] params, final Throwable t) {
	// 先执行各个过滤操作
    final FilterReply decision = loggerContext.getTurboFilterChainDecision_0_3OrMore(marker, this, level, msg, params, t);
	// 如果最终的结果是NEUTRAL
    // 那么设置的有效的日志打印大于当前的level,则不打印
    if (decision == FilterReply.NEUTRAL) {
        if (effectiveLevelInt > level.levelInt) {
            return;
        }
        // 如果结果是deny,那么也不打印
    } else if (decision == FilterReply.DENY) {
        return;
    }
	// 打印
    buildLoggingEventAndAppend(localFQCN, marker, level, msg, params, t);
}
```

看一下这个是如果执行过滤的

```java
final FilterReply getTurboFilterChainDecision_0_3OrMore(final Marker marker, final Logger logger, final Level level, final String format,final Object[] params, final Throwable t) {
    // 如果没有顾虑器,则返回NEUTRAL
    if (turboFilterList.size() == 0) {
        return FilterReply.NEUTRAL;
    }
    // 执行过滤器链
    return turboFilterList.getTurboFilterChainDecision(marker, logger, level, format, params, t);
}

// 执行操作
public FilterReply getTurboFilterChainDecision(final Marker marker, final Logger logger, final Level level, final String format, final Object[] params,final Throwable t) {

    final int size = size();
	// 如果只有一个
    if (size == 1) {
        try {
            // 直接执行
            TurboFilter tf = get(0);
            // 返回结果
            return tf.decide(marker, logger, level, format, params, t);
        } catch (IndexOutOfBoundsException iobe) {
            return FilterReply.NEUTRAL;
        }
    }
	// 把过滤器链 转换为数组形式
    Object[] tfa = toArray();
    final int len = tfa.length;
    // 遍历进行执行操作
    for (int i = 0; i < len; i++) {
        // for (TurboFilter tf : this) {
        final TurboFilter tf = (TurboFilter) tfa[i];
        final FilterReply r = tf.decide(marker, logger, level, format, params, t);
        if (r == FilterReply.DENY || r == FilterReply.ACCEPT) {
            return r;
        }
    }
    return FilterReply.NEUTRAL;
}
```

打印操作:

```java
private void buildLoggingEventAndAppend(final String localFQCN, final Marker marker, final Level level, final String msg, final Object[] params,final Throwable t) {
    // 创建 loggingevent
    LoggingEvent le = new LoggingEvent(localFQCN, this, level, msg, t, params);
    le.setMarker(marker);
    // 调用appender进行输出
    callAppenders(le);
}


public void callAppenders(ILoggingEvent event) {
    int writes = 0;
    for (Logger l = this; l != null; l = l.parent) {
        // 调用appender
        writes += l.appendLoopOnAppenders(event);
        if (!l.additive) {
            break;
        }
    }
    // 没有appender
    if (writes == 0) {
        loggerContext.noAppenderDefinedWarning(this);
    }
}
```

```java
private int appendLoopOnAppenders(ILoggingEvent event) {
    if (aai != null) { // 调用appender
        return aai.appendLoopOnAppenders(event);
    } else {
        return 0;
    }
}



public int appendLoopOnAppenders(E e) {
    int size = 0;
    final Appender<E>[] appenderArray = appenderList.asTypedArray();
    final int len = appenderArray.length;
    // 调用appender
    for (int i = 0; i < len; i++) {
        appenderArray[i].doAppend(e);
        size++;
    }
    return size;
}



public void doAppend(E eventObject) { 
    if (Boolean.TRUE.equals(guard.get())) {
        return;
    }

    try {
        guard.set(Boolean.TRUE);
        if (!this.started) {
            if (statusRepeatCount++ < ALLOWED_REPEATS) {
    addStatus(new WarnStatus("Attempted to append to non started appender [" + name + "].", this));
            }
            return;
        }

        if (getFilterChainDecision(eventObject) == FilterReply.DENY) {
            return;
        }

        // ok, we now invoke derived class' implementation of append
        // 调用
        this.append(eventObject);
    } catch (Exception e) {
        if (exceptionCount++ < ALLOWED_REPEATS) {
            addError("Appender [" + name + "] failed to append.", e);
        }
    } finally {
        guard.set(Boolean.FALSE);
    }
}
```

```java
// OutputStreamAppender.java
protected void append(E eventObject) {
    if (!isStarted()) {
        return;
    }
    // 写入操作
    subAppend(eventObject);
}

// RollingFileAppender.java
protected void subAppend(E event) {
    // 检测是否需要滚动
    synchronized (triggeringPolicy) {
        // 策略检查
        if (triggeringPolicy.isTriggeringEvent(currentlyActiveFile, event)) {
            // 滚动操作
            rollover();
        }
    }
    // 调用父类的写入动作
    super.subAppend(event);
}

// OutputStreamAppender.java
protected void subAppend(E event) {
    if (!isStarted()) {
        return;
    }
    try {
        // this step avoids LBCLASSIC-139
        if (event instanceof DeferredProcessingAware) {
            ((DeferredProcessingAware) event).prepareForDeferredProcessing();
        }
		// 具体的写入操作
        byte[] byteArray = this.encoder.encode(event);
        writeBytes(byteArray);
    } catch (IOException ioe) {
        this.started = false;
        addStatus(new ErrorStatus("IO failure in appender", this, ioe));
    }
}
```

这是针对把文件输出到file中的分析，到这里就是真实的写入了。咱们看一下这个策略检测的操作：

```java
public boolean isTriggeringEvent(File activeFile, final E event) {
    long time = getCurrentTime();
    if (time >= nextCheck) { // 现在时间大于要检查的时间
        Date dateOfElapsedPeriod = dateInCurrentPeriod;
        addInfo("Elapsed period: " + dateOfElapsedPeriod);
        elapsedPeriodsFileName = tbrp.fileNamePatternWithoutCompSuffix.convert(dateOfElapsedPeriod);
        setDateInCurrentPeriod(time);
        // 计算下次需要检查的时间
        computeNextCheck();
        // 返回真,表示事件触发
        return true;
    } else {
        return false;
    }
}

// 文件滚动操作
// RollingFileAppender
public void rollover() {
    lock.lock();
    try {
        // 关闭写入
        this.closeOutputStream();
        // 进行滚动
        attemptRollover();
        // 尝试打开新的文件
        attemptOpenFile();
    } finally {
        lock.unlock();
    }
}
```

滚动操作:

```java
private void attemptRollover() {
    try {
        // 滚动
        rollingPolicy.rollover();
    } catch (RolloverFailure rf) {
        addWarn("RolloverFailure occurred. Deferring roll-over.");
        // we failed to roll-over, let us not truncate and risk data loss
        this.append = true;
    }
}


public void rollover() throws RolloverFailure {
    String elapsedPeriodsFileName = timeBasedFileNamingAndTriggeringPolicy.getElapsedPeriodsFileName();
    String elapsedPeriodStem = FileFilterUtil.afterLastSlash(elapsedPeriodsFileName);
    // 是否需要压缩
    if (compressionMode == CompressionMode.NONE) {
        if (getParentsRawFileProperty() != null) {
            // 不需要压缩,直接把名字进行重命名
            renameUtil.rename(getParentsRawFileProperty(), elapsedPeriodsFileName);
        } // else { nothing to do if CompressionMode == NONE and parentsRawFileProperty == null }
    } else { // 需要压缩,则把文件压缩并重命名
        if (getParentsRawFileProperty() == null) {
            compressionFuture = compressor.asyncCompress(elapsedPeriodsFileName, elapsedPeriodsFileName, elapsedPeriodStem);
        } else {
            compressionFuture = renameRawAndAsyncCompress(elapsedPeriodsFileName, elapsedPeriodStem);
        }
    }
    if (archiveRemover != null) {// 打开清理线程
        Date now = new Date(timeBasedFileNamingAndTriggeringPolicy.getCurrentTime());
        this.cleanUpFuture = archiveRemover.cleanAsynchronously(now);
    }
}
```

先看一下，不需要压缩的文件重命名

```java
public void rename(String src, String target) throws RolloverFailure {
    if (src.equals(target)) {
        addWarn("Source and target files are the same [" + src + "]. Skipping.");
        return;
    }
    // 创建源文件
    File srcFile = new File(src);
	// 源文件存在
    if (srcFile.exists()) {
        // 获取目标文件
        File targetFile = new File(target);
        // 创建中间不存在的文件
        createMissingTargetDirsIfNecessary(targetFile);
        addInfo("Renaming file [" + srcFile + "] to [" + targetFile + "]");
		// 文件重命名------------这就是重命名操作了
        boolean result = srcFile.renameTo(targetFile);
        if (!result) { // 如果重命名不正确
            addWarn("Failed to rename file [" + srcFile + "] as [" + targetFile + "].");
            // 文件是否在一个分区
            Boolean areOnDifferentVolumes = areOnDifferentVolumes(srcFile, targetFile);
            // 不在一个分区
            if (Boolean.TRUE.equals(areOnDifferentVolumes)) {
               // 拷贝重命名操作
                renameByCopying(src, target);
                return;
            } else {
                addWarn("Please consider leaving the [file] option of " + RollingFileAppender.class.getSimpleName() + " empty.");
                addWarn("See also " + RENAMING_ERROR_URL);
            }
        }
    } else {
        throw new RolloverFailure("File [" + src + "] does not exist.");
    }
}
```

判断文件是否在一个分区:

```java
Boolean areOnDifferentVolumes(File srcFile, File targetFile) throws RolloverFailure {
    if (!EnvUtil.isJDK7OrHigher())
        return false;
    try {
        // 判断是否是一个分区
        boolean onSameFileStore = FileStoreUtil.areOnSameFileStore(srcFile, parentOfTarget);
        return !onSameFileStore;
    } catch (RolloverFailure rf) {
        addWarn("Error while checking file store equality", rf);
        return null;
    }
}



static final String PATH_CLASS_STR = "java.nio.file.Path";
static final String FILES_CLASS_STR = "java.nio.file.Files";
// 判断是否同一个分区
static public boolean areOnSameFileStore(File a, File b) throws RolloverFailure {
    if (!a.exists()) {
        throw new IllegalArgumentException("File [" + a + "] does not exist.");
    }
    if (!b.exists()) {
        throw new IllegalArgumentException("File [" + b + "] does not exist.");
    }

    try {
        // 加载类
        Class<?> pathClass = Class.forName(PATH_CLASS_STR);
        Class<?> filesClass = Class.forName(FILES_CLASS_STR);
		// 获取toPath方法
        Method toPath = File.class.getMethod("toPath");
        // 获取getFileStore方法
        Method getFileStoreMethod = filesClass.getMethod("getFileStore", pathClass);
		// 调用toPath方法
        Object pathA = toPath.invoke(a);
        Object pathB = toPath.invoke(b);
		// 分别获取pathA和pathB的存储分区
        Object fileStoreA = getFileStoreMethod.invoke(null, pathA);
        Object fileStoreB = getFileStoreMethod.invoke(null, pathB);
        // 判断两个路径分区是否一致
        return fileStoreA.equals(fileStoreB);
    } catch (Exception e) {
 throw new RolloverFailure("Failed to check file store equality for [" + a + "] and [" + b + "]", e);
    }
}
```

压缩的文件重命名：

```java
Future<?> renameRawAndAsyncCompress(String nameOfCompressedFile, String innerEntryName) throws RolloverFailure {
    // 获取源文件
    String parentsRawFile = getParentsRawFileProperty();
    // 目标文件
    String tmpTarget = nameOfCompressedFile + System.nanoTime() + ".tmp";
    // 文件重命名--目标文件带.tmp尾缀
    renameUtil.rename(parentsRawFile, tmpTarget);
    // 压缩
    return compressor.asyncCompress(tmpTarget, nameOfCompressedFile, innerEntryName);
}


public Future<?> asyncCompress(String nameOfFile2Compress, String nameOfCompressedFile, String innerEntryName) throws RolloverFailure {
    // 压缩线程
    CompressionRunnable runnable = new CompressionRunnable(nameOfFile2Compress, nameOfCompressedFile, innerEntryName);
    // 线程池
    ExecutorService executorService = context.getScheduledExecutorService();
    // 提交任务
    Future<?> future = executorService.submit(runnable);
    return future;
}
```

压缩线程:

```java
class CompressionRunnable implements Runnable {
    final String nameOfFile2Compress;
    final String nameOfCompressedFile;
    final String innerEntryName;

    public CompressionRunnable(String nameOfFile2Compress, String nameOfCompressedFile, String innerEntryName) {
        this.nameOfFile2Compress = nameOfFile2Compress;
        this.nameOfCompressedFile = nameOfCompressedFile;
        this.innerEntryName = innerEntryName;
    }

    public void run() {
		// 压缩
        Compressor.this.compress(nameOfFile2Compress, nameOfCompressedFile, innerEntryName);
    }
}
```



清理线程:

```java
public Future<?> cleanAsynchronously(Date now) {
    // 同样是创建一个清理任务
    ArhiveRemoverRunnable runnable = new ArhiveRemoverRunnable(now);
    //  把任务提交到线程池中
    ExecutorService executorService = context.getScheduledExecutorService();
    Future<?> future = executorService.submit(runnable);
    return future;
}
```

清理线程:

```java
public class ArhiveRemoverRunnable implements Runnable {
    Date now;

    ArhiveRemoverRunnable(Date now) {
        this.now = now;
    }

    @Override
    public void run() {
        clean(now);
        if (totalSizeCap != UNBOUNDED_TOTAL_SIZE_CAP && totalSizeCap > 0) {
            capTotalSize(now);
        }
    }
}
```

清理函数:

```java
public void clean(Date now) {
    long nowInMillis = now.getTime();
    // for a live appender periodsElapsed is expected to be 1
    int periodsElapsed = computeElapsedPeriodsSinceLastClean(nowInMillis);
    lastHeartBeat = nowInMillis;
    if (periodsElapsed > 1) {
        addInfo("Multiple periods, i.e. " + periodsElapsed + " periods, seem to have elapsed. This is expected at application start.");
    }
    // 获取时间内的文件,进行删除
    for (int i = 0; i < periodsElapsed; i++) {
        int offset = getPeriodOffsetForDeletionTarget() - i;
        Date dateOfPeriodToClean = rc.getEndOfNextNthPeriod(now, offset);
        // 清理操作
        cleanPeriod(dateOfPeriodToClean);
    }
}
```

今天就先分析到这里.本篇分析内容小结一下:

1. 打印到文件的appender写操作源码
2. 日志按照时间滚动的源码
3. 清理线程源码