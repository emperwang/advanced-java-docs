# ThreadGroup

## Field

```java
private final ThreadGroup parent;
// 线程组名字
String name;
// 最大优先级
int maxPriority;
// 是否销毁
boolean destroyed;
// 是否是守护线程
boolean daemon;
boolean vmAllowSuspension;
// 没有启动的线程数
int nUnstartedThreads;
// 线程数
int nthreads;
// 保存线程
Thread[] threads;
// 几个线程组
int ngroups;
ThreadGroup[] groups;
```

## 构造函数

```java
private ThreadGroup() {
    this.nUnstartedThreads = 0;
    this.name = "system";
    this.maxPriority = 10;
    this.parent = null;
}

public ThreadGroup(String var1) {
    this(Thread.currentThread().getThreadGroup(), var1);
}

public ThreadGroup(ThreadGroup var1, String var2) {
    this(checkParentAccess(var1), var1, var2);
}

private ThreadGroup(Void var1, ThreadGroup var2, String var3) {
    this.nUnstartedThreads = 0;
    this.name = var3;
    this.maxPriority = var2.maxPriority;
    this.daemon = var2.daemon;
    this.vmAllowSuspension = var2.vmAllowSuspension;
    this.parent = var2;
    var2.add(this);
}
```



## 功能函数

### activeCount

```java
public int activeCount() {
    int var1;
    int var2;
    ThreadGroup[] var3;
    synchronized(this) {
        // 被销毁了就返回0
        if (this.destroyed) {
            return 0;
        }
        var1 = this.nthreads;
        var2 = this.ngroups;
        if (this.groups != null) {
            var3 = (ThreadGroup[])Arrays.copyOf(this.groups, var2);
        } else {
            var3 = null;
        }
    }
	// 把线程数和线程组中的线程数相加
    for(int var4 = 0; var4 < var2; ++var4) {
        var1 += var3[var4].activeCount();
    }

    return var1;
}
```



### enumerate

```java
this.enumerate((Thread[])var1, 0, true)
```

```java
private int enumerate(Thread[] var1, int var2, boolean var3) {
    int var4 = 0;
    ThreadGroup[] var5 = null;
    synchronized(this) {
        // 被销毁了，就返回0
        if (this.destroyed) {
            return 0;
        }
        // 线程数
        int var7 = this.nthreads;
        if (var7 > var1.length - var2) {
            var7 = var1.length - var2;
        }
		// 把存活的线程拷贝到var1中
        for(int var8 = 0; var8 < var7; ++var8) {
            if (this.threads[var8].isAlive()) {
                var1[var2++] = this.threads[var8];
            }
        }
		// 遍历线程组中的线程
        if (var3) {
            var4 = this.ngroups;
            if (this.groups != null) {
                var5 = (ThreadGroup[])Arrays.copyOf(this.groups, var4);
            } else {
                var5 = null;
            }
        }
    }

    if (var3) { // 把线程组中的线程添加到var1中
        for(int var6 = 0; var6 < var4; ++var6) {
            var2 = var5[var6].enumerate(var1, var2, true);
        }
    }
    return var2;
}
```


### activeGroupCount
```java
public int activeGroupCount() {
    int var1;
    ThreadGroup[] var2;
    synchronized(this) {
        // 销毁了 就返回0
        if (this.destroyed) {
            return 0;
        }
		// 线程组的数量
        var1 = this.ngroups;
        // 把线程组中的数据拷贝到var2
        if (this.groups != null) {
            var2 = (ThreadGroup[])Arrays.copyOf(this.groups, var1);
        } else {
            var2 = null;
        }
    }

    int var3 = var1;
	// 遍历var2，得到总的存活的线程组数
    for(int var4 = 0; var4 < var1; ++var4) {
        var3 += var2[var4].activeGroupCount();
    }
    return var3;
}
```

### enumerate

```java
this.enumerate((ThreadGroup[])var1, 0, true);
```

```java
private int enumerate(ThreadGroup[] var1, int var2, boolean var3) {
    int var4 = 0;
    ThreadGroup[] var5 = null;
    synchronized(this) {
        // 销毁了返回0
        if (this.destroyed) {
            return 0;
        }
		// 线程组数量
        int var7 = this.ngroups;
        if (var7 > var1.length - var2) {
            var7 = var1.length - var2;
        }
		// 拷贝到var1中
        if (var7 > 0) {
            System.arraycopy(this.groups, 0, var1, var2, var7);
            var2 += var7;
        }
		// 遍历线程组中的线程组
        if (var3) {
            var4 = this.ngroups;
            if (this.groups != null) {
                var5 = (ThreadGroup[])Arrays.copyOf(this.groups, var4);
            } else {
                var5 = null;
            }
        }
    }

    if (var3) {
        for(int var6 = 0; var6 < var4; ++var6) {
            var2 = var5[var6].enumerate(var1, var2, true);
        }
    }

    return var2;
}
```


### interrupt
```java
public final void interrupt() {
    int var1;
    ThreadGroup[] var2;
    synchronized(this) {
        this.checkAccess();
        int var4 = 0;

        while(true) {
            if (var4 >= this.nthreads) {
                var1 = this.ngroups;
                if (this.groups != null) {
                    var2 = (ThreadGroup[])Arrays.copyOf(this.groups, var1);
                } else {
                    var2 = null;
                }
                break;
            }

            this.threads[var4].interrupt();
            ++var4;
        }
    }

    for(int var3 = 0; var3 < var1; ++var3) {
        var2[var3].interrupt();
    }

}
```


### stopOrSuspend
```java
private boolean stopOrSuspend(boolean var1) {
    boolean var2 = false;
    Thread var3 = Thread.currentThread();
    ThreadGroup[] var5 = null;
    int var4;
    synchronized(this) {
        this.checkAccess();
        int var7 = 0;

        while(true) {
            if (var7 >= this.nthreads) {
                var4 = this.ngroups;
                if (this.groups != null) {
                    var5 = (ThreadGroup[])Arrays.copyOf(this.groups, var4);
                }
                break;
            }

            if (this.threads[var7] == var3) {
                var2 = true;
            } else if (var1) {
                this.threads[var7].suspend();
            } else {
                this.threads[var7].stop();
            }

            ++var7;
        }
    }

    for(int var6 = 0; var6 < var4; ++var6) {
        var2 = var5[var6].stopOrSuspend(var1) || var2;
    }

    return var2;
}
```


### destroy
```java
public final void destroy() {
    int var1;
    ThreadGroup[] var2;
    synchronized(this) {
        this.checkAccess();
        if (this.destroyed || this.nthreads > 0) {
            throw new IllegalThreadStateException();
        }

        var1 = this.ngroups;
        // 如果线程组数组不为null
        // 则记录下来
        if (this.groups != null) {
            var2 = (ThreadGroup[])Arrays.copyOf(this.groups, var1);
        } else {
            var2 = null;
        }
		// 标记为销毁
        if (this.parent != null) {
            this.destroyed = true;
            this.ngroups = 0;
            this.groups = null;
            this.nthreads = 0;
            this.threads = null;
        }
    }
	// 遍历线程组数组，进行每一个线程组的销毁
    for(int var3 = 0; var3 < var1; ++var3) {
        var2[var3].destroy();
    }
	// 把此移除
    if (this.parent != null) {
        this.parent.remove(this);
    }
}
```


### add
```java
private final void add(ThreadGroup var1) {
    synchronized(this) {
        if (this.destroyed) {
            throw new IllegalThreadStateException();
        } else {
            if (this.groups == null) {
                // 可以看到，线程组数组是第一次添加时初始化的
                // 默认数量为4
                this.groups = new ThreadGroup[4];
            } else if (this.ngroups == this.groups.length) {
                // 每次扩容都是扩大两倍
            this.groups = (ThreadGroup[])Arrays.copyOf(this.groups, this.ngroups * 2);
            }
			// 放到数组中
            this.groups[this.ngroups] = var1;
            ++this.ngroups;
        }
    }
}


void add(Thread var1) {
    synchronized(this) {
        if (this.destroyed) {
            throw new IllegalThreadStateException();
        } else {
            // 线程数组也是第一次添加时，进行的初始化
            // 默认大小时4
            if (this.threads == null) {
                this.threads = new Thread[4];
            } else if (this.nthreads == this.threads.length) {
                // 扩容时扩大2倍
               this.threads = (Thread[])Arrays.copyOf(this.threads, this.nthreads * 2);
            }
			// 添加到数组中
            this.threads[this.nthreads] = var1;
            ++this.nthreads;
            --this.nUnstartedThreads;
        }
    }
}
```
### remove
```java
// 移除一个线程组
private void remove(ThreadGroup var1) {
    synchronized(this) {
        if (!this.destroyed) {
            // 遍历数组找到相等的
            for(int var3 = 0; var3 < this.ngroups; ++var3) {
                if (this.groups[var3] == var1) {
                    --this.ngroups;
                    // 删除操作
      System.arraycopy(this.groups, var3 + 1, this.groups, var3, this.ngroups - var3);
                    this.groups[this.ngroups] = null;
                    break;
                }
            }

            if (this.nthreads == 0) {
                this.notifyAll();
            }
			// 都为0，则进行销毁操作
            if (this.daemon && this.nthreads == 0 && this.nUnstartedThreads == 0 && this.ngroups == 0) {
                this.destroy();
            }
        }
    }
}

// 移除线程
private void remove(Thread var1) {
    synchronized(this) {
        if (!this.destroyed) {
            // 遍历所有进行查找
            for(int var3 = 0; var3 < this.nthreads; ++var3) {
                // 找到则进行移除
                if (this.threads[var3] == var1) {
                    // 具体的移除操作
                    System.arraycopy(this.threads, var3 + 1, this.threads, var3, --this.nthreads - var3);
                    this.threads[this.nthreads] = null;
                    break;
                }
            }

        }
    }
}
```


### addUnstarted
```java
// 未启动线程数量增加
void addUnstarted() {
    synchronized(this) {
        if (this.destroyed) {
            throw new IllegalThreadStateException();
        } else {
            ++this.nUnstartedThreads;
        }
    }
}
```

### threadTerminated

```java
// 终止一个线程
void threadTerminated(Thread var1) {
    synchronized(this) {
        // 先从线程组中移除
        this.remove(var1);
        if (this.nthreads == 0) {
            this.notifyAll();
        }
		// 销毁线程
        if (this.daemon && this.nthreads == 0 && this.nUnstartedThreads == 0 && this.ngroups == 0) {
            this.destroy();
        }
    }
}
```