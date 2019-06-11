# ThreadPoolExecutor

## field

### 线程池状态的field

```java
    // 线程池状态相关的field
	// ctl：pool control state，线程池的状态
    private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
    private static final int COUNT_BITS = Integer.SIZE - 3;
    private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

    // 接受新任务并处理队列中的任务
    private static final int RUNNING    = -1 << COUNT_BITS;
	// 不接收新任务，但是处理队列中的任务
    private static final int SHUTDOWN   =  0 << COUNT_BITS;
	// 不接收新任务，不处理队列中的任务，并且打断正在执行的任务
    private static final int STOP       =  1 << COUNT_BITS;
	// 所有任务已经停止，workerCount=0，任务状态转换为TIDIYING,将要执行terminated()
    private static final int TIDYING    =  2 << COUNT_BITS;
	// terminated()执行
    private static final int TERMINATED =  3 << COUNT_BITS;
	
	// 判断当前状态，运行或停止
    private static int runStateOf(int c)     { return c & ~CAPACITY; }
	// 返回线程池中的活跃的线程数
    private static int workerCountOf(int c)  { return c & CAPACITY; }
    private static int ctlOf(int rs, int wc) { return rs | wc; }
```





## 创建函数参数解析

```java
    /**
    	corePoolSize: 存活线程的数量
    	maximumPoolSize: 最大线程数
    	keepAliveTime: 线程idle时，存活时间
    	unit: 存活时间的单位
    	workQueue: 当线程池中的线程被占满时，任务的存放队列
    	threadFactory: 创建线程的工厂方法
    	handler: 当队列满时，一个拒绝策略
    */
	public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
        if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
            throw new IllegalArgumentException();
        if (workQueue == null || threadFactory == null || handler == null)
            throw new NullPointerException();
        this.acc = System.getSecurityManager() == null ?
                null :
                AccessController.getContext();
        this.corePoolSize = corePoolSize;
        this.maximumPoolSize = maximumPoolSize;
        this.workQueue = workQueue;
        this.keepAliveTime = unit.toNanos(keepAliveTime);
        this.threadFactory = threadFactory;
        this.handler = handler;
    }
```

## 提交一个任务到线程池时，线程池做了什么?

```java
 	// 提交任务到线程池中运行
	public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
     	// 提交任务由三种情况
     	// 获取当前线程池状态
        int c = ctl.get();
     	// 情况一: 线程数小于coresize，则创建一个新线程运行任务
     	// 如果活跃线程数小于corePoolSize，则添加一个worker运行任务
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true))
                return;
            c = ctl.get();
        }
     	// 情况二: 线程池运行且添加队列成功(double-check线程池状态，因此此时可能由其他线程运行完毕或线程池关闭)，如果线程关闭则拒绝该任务，否则创建一个新线程运行任务
     	// 如果线程池状态正在运行，并且添加到队列成功
        if (isRunning(c) && workQueue.offer(command)) {
            // 再次检查一下状态，因为此时可能由其他线程运行完毕，或线程池关闭
            int recheck = ctl.get();
            // 如果线程池已经关闭，移除任务
            if (! isRunning(recheck) && remove(command))
                // 使用具体的拒绝策略去处理任务
                reject(command);
            // 创建新线程运行任务
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
     	// 情况三: 添加队列不成功或者新建线程运行任务失败
        else if (!addWorker(command, false))
            // 使用具体的拒绝策略处理
            reject(command);
    }

   private boolean addWorker(Runnable firstTask, boolean core) {
        retry:
        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // 当线程池状态不是running返回false
            // 当线程池状态为shutdown，或队列为空，firstTask为null时也返回false
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false;

            for (;;) {
                int wc = workerCountOf(c);
                // 当容量大于线程池设置的corePoolsize或max值时，失败
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                // 增加c值时，跳出循环
                if (compareAndIncrementWorkerCount(c))
                    break retry;
                c = ctl.get();  // Re-read ctl
                if (runStateOf(c) != rs)
                    continue retry;
                // else CAS failed due to workerCount change; retry inner loop
            }
        }

        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            // 给任务添加一个线程
            w = new Worker(firstTask);
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                try {
                    // 再次检查线程池状态，因此可能出现线程池关闭,创建worker失败
                    int rs = runStateOf(ctl.get());
					
                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        if (t.isAlive()) // precheck that t is startable
                            throw new IllegalThreadStateException();
                        // 添加到worker容器中，并调大线程池最大值
                        workers.add(w);
                        int s = workers.size();
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                // 添加成功，则运行线程
                if (workerAdded) {
                    t.start();
                    workerStarted = true;
                }
            }
        } finally {
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }
 	// t.start();调用后，就会调用worker的run方法
        public void run() {
            runWorker(this);
        }
	// 完成具体任务
    final void runWorker(Worker w) {
        Thread wt = Thread.currentThread();
        Runnable task = w.firstTask;
        w.firstTask = null;
        w.unlock(); // allow interrupts
        boolean completedAbruptly = true;
        try {
            // rask为null，则从workQueue中获取任务
            while (task != null || (task = getTask()) != null) {
                w.lock();
                // If pool is stopping, ensure thread is interrupted;
                // if not, ensure thread is not interrupted.  This
                // requires a recheck in second case to deal with
                // shutdownNow race while clearing interrupt
                if ((runStateAtLeast(ctl.get(), STOP) ||
                     (Thread.interrupted() &&
                      runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                    wt.interrupt();
                try {
                    // 任务执行前
                    beforeExecute(wt, task);
                    Throwable thrown = null;
                    try {
                        task.run();
                    } catch (RuntimeException x) {
                        thrown = x; throw x;
                    } catch (Error x) {
                        thrown = x; throw x;
                    } catch (Throwable x) {
                        thrown = x; throw new Error(x);
                    } finally {
                        // 任务执行后
                        afterExecute(task, thrown);
                    }
                } finally {
                    task = null;
                    w.completedTasks++;
                    w.unlock();
                }
            }
            completedAbruptly = false;
        } finally {
            processWorkerExit(w, completedAbruptly);
        }
    }
	// 从等待队列中获取任务
    private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
                decrementWorkerCount();
                return null;
            }

            int wc = workerCountOf(c);
            // Are workers subject to culling?
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
                if (compareAndDecrementWorkerCount(c))
                    return null;
                continue;
            }

            try {
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                timedOut = true;
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }

	// 添加worker失败时，移除worker，并尝试关闭线程池
   private void addWorkerFailed(Worker w) {
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            // 移除worker
            if (w != null)
                workers.remove(w);
            // 减少ctl的值
            decrementWorkerCount();
            // 尝试关闭线程池
            tryTerminate();
        } finally {
            mainLock.unlock();
        }
    }

    final void tryTerminate() {
        for (;;) {
            int c = ctl.get();
            // 如果线程池正在运行，或者状态为TIDIYING，或状态为SHUTDOWN且工作队列为不为空
            // 则退出函数
            if (isRunning(c) ||
                runStateAtLeast(c, TIDYING) ||
                (runStateOf(c) == SHUTDOWN && ! workQueue.isEmpty()))
                return;
            // 如果ctl不为0，则中断一个线程
            if (workerCountOf(c) != 0) { // Eligible to terminate
                interruptIdleWorkers(ONLY_ONE);
                return;
            }

            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            try {
                // 如果设置ctl为0成功，则停止线程池
                if (ctl.compareAndSet(c, ctlOf(TIDYING, 0))) {
                    try {
                        terminated();
                    } finally {
                        // 把ctl状态设置为TERMINATED
                        ctl.set(ctlOf(TERMINATED, 0));
                        // 唤醒等待队列中的线程
                        termination.signalAll();
                    }
                    return;
                }
            } finally {
                mainLock.unlock();
            }
            // else retry on failed CAS
        }
    }
// 中断worker执行
 private void interruptIdleWorkers(boolean onlyOne) {
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            // 遍历工作队列，如果onlyOne为true，则只是中断一个线程
            for (Worker w : workers) {
                Thread t = w.thread;
                if (!t.isInterrupted() && w.tryLock()) {
                    try {
                        t.interrupt();
                    } catch (SecurityException ignore) {
                    } finally {
                        w.unlock();
                    }
                }
                if (onlyOne)
                    break;
            }
        } finally {
            mainLock.unlock();
        }
    }
```



## 提交一个由返回值的任务

可以查看[FutureTask](JDK/线程及线程池/FutureTask.md)相关的解析.

```java
    // 可以看到提交由返回值的任务时，使用submit函数，返回一个Future接口，通过Future接口可以获取到任务运行的结果值

	public Future<?> submit(Runnable task) {
        if (task == null) throw new NullPointerException();
        RunnableFuture<Void> ftask = newTaskFor(task, null);
        execute(ftask);
        return ftask;
    }

    public <T> Future<T> submit(Runnable task, T result) {
        if (task == null) throw new NullPointerException();
        RunnableFuture<T> ftask = newTaskFor(task, result);
        execute(ftask);
        return ftask;
    }

    public <T> Future<T> submit(Callable<T> task) {
        if (task == null) throw new NullPointerException();
        RunnableFuture<T> ftask = newTaskFor(task);
        execute(ftask);
        return ftask;
    }
	// 创建FutureTask函数
    protected <T> RunnableFuture<T> newTaskFor(Runnable runnable, T value) {
        return new FutureTask<T>(runnable, value);
    }

    protected <T> RunnableFuture<T> newTaskFor(Callable<T> callable) {
        return new FutureTask<T>(callable);
    }

// 然后调用FutureTask的get()就可以得到计算的值
```





## 拒绝策略

```java
 // 使用处理请求的线程运行任务 
public static class CallerRunsPolicy implements RejectedExecutionHandler {
        public CallerRunsPolicy() { }

        /**
         * Executes task r in the caller's thread, unless the executor
         * has been shut down, in which case the task is discarded.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            if (!e.isShutdown()) {
                r.run();
            }
        }
    }

// 抛出异常
public static class AbortPolicy implements RejectedExecutionHandler {
        public AbortPolicy() { }

        /**
         * Always throws RejectedExecutionException.
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         * @throws RejectedExecutionException always
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            throw new RejectedExecutionException("Task " + r.toString() +
                                                 " rejected from " +
                                                 e.toString());
        }
    }

// 什么也不做，舍弃
public static class DiscardPolicy implements RejectedExecutionHandler {
        public DiscardPolicy() { }

        /**
         * Does nothing, which has the effect of discarding task r.
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        }
    }
		
	// 把让的线程运行任务
    public static class DiscardOldestPolicy implements RejectedExecutionHandler {
        public DiscardOldestPolicy() { }

        /**
         * Obtains and ignores the next task that the executor
         * would otherwise execute, if one is immediately available,
         * and then retries execution of task r, unless the executor
         * is shut down, in which case task r is instead discarded.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            if (!e.isShutdown()) {
                e.getQueue().poll();
                e.execute(r);
            }
        }
    }
```

