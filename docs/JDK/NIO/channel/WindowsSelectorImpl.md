# WindowsSelectorImpl

## Field

```java
private final int INIT_CAP = 8;
private static final int MAX_SELECTABLE_FDS = 1024;
private SelectionKeyImpl[] channelArray = new SelectionKeyImpl[8];
private PollArrayWrapper pollWrapper = new PollArrayWrapper(8);
private int totalChannels = 1;
private int threadsCount = 0;
private final List<WindowsSelectorImpl.SelectThread> threads = new ArrayList();
private final Pipe wakeupPipe = Pipe.open();
private final int wakeupSourceFd;
private final int wakeupSinkFd;
private Object closeLock = new Object();
private final WindowsSelectorImpl.FdMap fdMap = new WindowsSelectorImpl.FdMap();
// poll 函数
private final WindowsSelectorImpl.SubSelector subSelector = new WindowsSelectorImpl.SubSelector();
private long timeout;
private final Object interruptLock = new Object();
private volatile boolean interruptTriggered = false;
private final WindowsSelectorImpl.StartLock startLock = new WindowsSelectorImpl.StartLock();
private final WindowsSelectorImpl.FinishLock finishLock = new WindowsSelectorImpl.FinishLock();
private long updateCount = 0L;
```



静态初始化代码：

```java
static {
    IOUtil.load();
}
```



## 构造函数

```java
WindowsSelectorImpl(SelectorProvider var1) throws IOException {
    super(var1);
    this.wakeupSourceFd = ((SelChImpl)this.wakeupPipe.source()).getFDVal();
    SinkChannelImpl var2 = (SinkChannelImpl)this.wakeupPipe.sink();
    var2.sc.socket().setTcpNoDelay(true);
    this.wakeupSinkFd = var2.getFDVal();
    this.pollWrapper.addWakeupSocket(this.wakeupSourceFd, 0);
}
```



## 功能函数

### doSelect

```java
protected int doSelect(long var1) throws IOException {
    if (this.channelArray == null) {
        throw new ClosedSelectorException();
    } else {
        this.timeout = var1;
        this.processDeregisterQueue();
        if (this.interruptTriggered) {
            this.resetWakeupSocket();
            return 0;
        } else {
            this.adjustThreadsCount();
            this.finishLock.reset();
            this.startLock.startThreads();
            try {
                this.begin();
                try {
                    // poll执行
                    this.subSelector.poll();
                } catch (IOException var7) {
                    this.finishLock.setException(var7);
                }
                if (this.threads.size() > 0) {
                    this.finishLock.waitForHelperThreads();
                }
            } finally {
                this.end();
            }
            this.finishLock.checkForException();
            this.processDeregisterQueue();
            int var3 = this.updateSelectedKeys();
            this.resetWakeupSocket();
            return var3;
        }
    }
}


// 处理deregister 操作
void processDeregisterQueue() throws IOException {
    Set var1 = this.cancelledKeys();
    synchronized(var1) {
        if (!var1.isEmpty()) {
            Iterator var3 = var1.iterator();
            while(var3.hasNext()) {
                SelectionKeyImpl var4 = (SelectionKeyImpl)var3.next();
                try {
                    // 具体的取消操作
                    this.implDereg(var4);
                } catch (SocketException var11) {
                    throw new IOException("Error deregistering key", var11);
                } finally {
                    var3.remove();
                }
            }
        }
    }
}

// 调整轮询线程
private void adjustThreadsCount() {
    int var1;
    if (this.threadsCount > this.threads.size()) {
        for(var1 = this.threads.size(); var1 < this.threadsCount; ++var1) {
            WindowsSelectorImpl.SelectThread var2 = new WindowsSelectorImpl.SelectThread(var1);
            this.threads.add(var2);
            var2.setDaemon(true);
            var2.start();
        }
    } else if (this.threadsCount < this.threads.size()) {
        for(var1 = this.threads.size() - 1; var1 >= this.threadsCount; --var1) {
            ((WindowsSelectorImpl.SelectThread)this.threads.remove(var1)).makeZombie();
        }
    }

}
```



```java
protected void implDereg(SelectionKeyImpl var1) throws IOException {
    int var2 = var1.getIndex();
    assert var2 >= 0;
    Object var3 = this.closeLock;
    synchronized(this.closeLock) {
        if (var2 != this.totalChannels - 1) {
            SelectionKeyImpl var4 = this.channelArray[this.totalChannels - 1];
            this.channelArray[var2] = var4;
            var4.setIndex(var2);
            // 更改
   this.pollWrapper.replaceEntry(this.pollWrapper, this.totalChannels - 1, this.pollWrapper, var2);
        }
        var1.setIndex(-1);
    }
    // 置空
    this.channelArray[this.totalChannels - 1] = null;
    // 总的channel数减少
    --this.totalChannels;
    if (this.totalChannels != 1 && this.totalChannels % 1024 == 1) {
        --this.totalChannels;
        --this.threadsCount;
    }
	// 对应的信息删除
    this.fdMap.remove(var1);
    this.keys.remove(var1);
    this.selectedKeys.remove(var1);
    this.deregister(var1);
    SelectableChannel var7 = var1.channel();
    if (!var7.isOpen() && !var7.isRegistered()) {
        ((SelChImpl)var7).kill();
    }

}
```



```java
public void putEventOps(SelectionKeyImpl var1, int var2) {
    Object var3 = this.closeLock;
    synchronized(this.closeLock) {
        if (this.pollWrapper == null) {
            throw new ClosedSelectorException();
        } else {
            int var4 = var1.getIndex();
            if (var4 == -1) {
                throw new CancelledKeyException();
            } else {
                // 封装
                this.pollWrapper.putEventOps(var4, var2);
            }
        }
    }
}
```



### wake

```java
// 唤醒线程
public Selector wakeup() {
    Object var1 = this.interruptLock;
    synchronized(this.interruptLock) {
        if (!this.interruptTriggered) {
            this.setWakeupSocket();
            this.interruptTriggered = true;
        }
        return this;
    }
}

private void setWakeupSocket() {
    this.setWakeupSocket0(this.wakeupSinkFd);
}

private native void setWakeupSocket0(int var1);
```



## 内部类

### FdMap

就是一个HashMap，存储的元素时MapEntry

```java
private static final class FdMap extends HashMap<Integer, WindowsSelectorImpl.MapEntry> {
    static final long serialVersionUID = 0L;

    private FdMap() {
    }

    private WindowsSelectorImpl.MapEntry get(int var1) {
        return (WindowsSelectorImpl.MapEntry)this.get(new Integer(var1));
    }

    private WindowsSelectorImpl.MapEntry put(SelectionKeyImpl var1) {
        return (WindowsSelectorImpl.MapEntry)this.put(new Integer(var1.channel.getFDVal()), new WindowsSelectorImpl.MapEntry(var1));
    }

    private WindowsSelectorImpl.MapEntry remove(SelectionKeyImpl var1) {
        Integer var2 = new Integer(var1.channel.getFDVal());
        WindowsSelectorImpl.MapEntry var3 = (WindowsSelectorImpl.MapEntry)this.get(var2);
        return var3 != null && var3.ski.channel == var1.channel ? (WindowsSelectorImpl.MapEntry)this.remove(var2) : null;
    }
}
```



### FinishLock

field

```java
private int threadsToFinish;
IOException exception;
```

构造函数

```java
private FinishLock() {
    this.exception = null;
}
```

功能函数

```java
private void reset() {
    this.threadsToFinish = WindowsSelectorImpl.this.threads.size();
}
```

```java
private synchronized void threadFinished() {
    if (this.threadsToFinish == WindowsSelectorImpl.this.threads.size()) {
        WindowsSelectorImpl.this.wakeup();
    }

    --this.threadsToFinish;
    if (this.threadsToFinish == 0) {
        this.notify();
    }
}
```

```java
private synchronized void waitForHelperThreads() {
    if (this.threadsToFinish == WindowsSelectorImpl.this.threads.size()) {
        WindowsSelectorImpl.this.wakeup();
    }
    while(this.threadsToFinish != 0) {
        try {
            // 线程等待
            WindowsSelectorImpl.this.finishLock.wait();
        } catch (InterruptedException var2) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```java
private void checkForException() throws IOException {
    if (this.exception != null) {
        StringBuffer var1 = new StringBuffer("An exception occurred during the execution of select(): \n");
        var1.append(this.exception);
        var1.append('\n');
        this.exception = null;
        throw new IOException(var1.toString());
    }
}
```



### MapEntry

```java
private static final class MapEntry {
    SelectionKeyImpl ski;
    long updateCount = 0L;
    long clearedCount = 0L;

    MapEntry(SelectionKeyImpl var1) {
        this.ski = var1;
    }
}
```



### SelectThread

field

```java
private final int index;
final WindowsSelectorImpl.SubSelector subSelector;
private long lastRun;
private volatile boolean zombie;
```

构造函数

```java
private SelectThread(int var2) {
    this.lastRun = 0L;
    this.index = var2;
    this.subSelector = WindowsSelectorImpl.this.new SubSelector(var2);
    this.lastRun = WindowsSelectorImpl.this.startLock.runsCounter;
}
```

功能方法

```java
public void run() {
    for(; !WindowsSelectorImpl.this.startLock.waitForStart(this); WindowsSelectorImpl.this.finishLock.threadFinished()) {
        try {
            this.subSelector.poll(this.index);
        } catch (IOException var2) {
            WindowsSelectorImpl.this.finishLock.setException(var2);
        }
    }
}
```



### StartLock

```java
private final class StartLock {
    private long runsCounter;

    private StartLock() {
    }

    private synchronized void startThreads() {
        ++this.runsCounter;
        this.notifyAll();
    }

    private synchronized boolean waitForStart(WindowsSelectorImpl.SelectThread var1) {
        while(this.runsCounter == var1.lastRun) {
            try {
                WindowsSelectorImpl.this.startLock.wait();
            } catch (InterruptedException var3) {
                Thread.currentThread().interrupt();
            }
        }

        if (var1.isZombie()) {
            return true;
        } else {
            var1.lastRun = this.runsCounter;
            return false;
        }
    }
}
```



### SubSelector

field

```java
private final int pollArrayIndex;
private final int[] readFds;
private final int[] writeFds;
private final int[] exceptFds;
```



构造函数

```java
private SubSelector() {
    this.readFds = new int[1025];
    this.writeFds = new int[1025];
    this.exceptFds = new int[1025];
    this.pollArrayIndex = 0;
}

private SubSelector(int var2) {
    this.readFds = new int[1025];
    this.writeFds = new int[1025];
    this.exceptFds = new int[1025];
    this.pollArrayIndex = (var2 + 1) * 1024;
}
```



功能函数:

poll:

```java
private int poll() throws IOException {
    return this.poll0(WindowsSelectorImpl.this.pollWrapper.pollArrayAddress, Math.min(WindowsSelectorImpl.this.totalChannels, 1024), this.readFds, this.writeFds, this.exceptFds, WindowsSelectorImpl.this.timeout);
}

private int poll(int var1) throws IOException {
    return this.poll0(WindowsSelectorImpl.this.pollWrapper.pollArrayAddress + (long)(this.pollArrayIndex * PollArrayWrapper.SIZE_POLLFD), Math.min(1024, WindowsSelectorImpl.this.totalChannels - (var1 + 1) * 1024), this.readFds, this.writeFds, this.exceptFds, WindowsSelectorImpl.this.timeout);
}

private native int poll0(long var1, int var3, int[] var4, int[] var5, int[] var6, long var7);
```

processSelectedKeys

```java
private int processSelectedKeys(long var1) {
    byte var3 = 0;
    int var4 = var3 + this.processFDSet(var1, this.readFds, Net.POLLIN, false);
    var4 += this.processFDSet(var1, this.writeFds, Net.POLLCONN | Net.POLLOUT, false);
    var4 += this.processFDSet(var1, this.exceptFds, Net.POLLIN | Net.POLLCONN | Net.POLLOUT, true);
    return var4;
}
```

processFDSet:

```java
private int processFDSet(long var1, int[] var3, int var4, boolean var5) {
    int var6 = 0;
    // 遍历所有的fd
    for(int var7 = 1; var7 <= var3[0]; ++var7) {
        int var8 = var3[var7];
        if (var8 == WindowsSelectorImpl.this.wakeupSourceFd) {
            synchronized(WindowsSelectorImpl.this.interruptLock) {
                WindowsSelectorImpl.this.interruptTriggered = true;
            }
        } else {
            // 获取fs对应的MapEntry
            WindowsSelectorImpl.MapEntry var9 = WindowsSelectorImpl.this.fdMap.get(var8);
            if (var9 != null) {// 存在
                SelectionKeyImpl var10 = var9.ski;
                if (!var5 || !(var10.channel() instanceof SocketChannelImpl) ||                                           !WindowsSelectorImpl.this.discardUrgentData(var8)) {
                    if (WindowsSelectorImpl.this.selectedKeys.contains(var10)) {
                        if (var9.clearedCount != var1) {
                            // 设置就绪后的ops操作
                            if (var10.channel.translateAndSetReadyOps(var4, var10) && 											 var9.updateCount != var1) {
                                var9.updateCount = var1;
                                ++var6;
                            }
                            // 更新ready的Ops操作
                        } else if (var10.channel.translateAndUpdateReadyOps(var4, var10) &&                                              var9.updateCount != var1) {
                            var9.updateCount = var1;
                            ++var6;
                        }
                        var9.clearedCount = var1;
                    } else { // 不包含在此poll之列
                        if (var9.clearedCount != var1) {
                            var10.channel.translateAndSetReadyOps(var4, var10);
                            if ((var10.nioReadyOps() & var10.nioInterestOps()) != 0) {
                                // 添加到selectKeys
                                WindowsSelectorImpl.this.selectedKeys.add(var10);
                                var9.updateCount = var1;
                                ++var6;
                            }
                        } else {
                            var10.channel.translateAndUpdateReadyOps(var4, var10);
                            if ((var10.nioReadyOps() & var10.nioInterestOps()) != 0) {
                                // 添加
                                WindowsSelectorImpl.this.selectedKeys.add(var10);
                                var9.updateCount = var1;
                                ++var6;
                            }
                        }
                        var9.clearedCount = var1;
                    }
                }
            }
        }
    }
    return var6;
}
```

