# FutureTask

## 实现的接口

```java
public class FutureTask<V> implements RunnableFuture<V> {
    
}

public interface RunnableFuture<V> extends Runnable, Future<V> {
    void run();
}

public interface Runnable {
    public abstract void run();
}

public interface Future<V> {
	// 取消任务
    boolean cancel(boolean mayInterruptIfRunning);
	// 任务是否取消
    boolean isCancelled();
	// 任务是否完成
    boolean isDone();
	// 获取计算结果
    V get() throws InterruptedException, ExecutionException;
	// 在规定时间获取结果
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

## field

```java
	
	// 线程的状态标识
	/*
	* Possible state transitions:
     * NEW -> COMPLETING -> NORMAL
     * NEW -> COMPLETING -> EXCEPTIONAL
     * NEW -> CANCELLED
     * NEW -> INTERRUPTING -> INTERRUPTED
     */
	// 线程状态s
    private volatile int state;
    private static final int NEW          = 0;
    private static final int COMPLETING   = 1;
    private static final int NORMAL       = 2;
    private static final int EXCEPTIONAL  = 3;
    private static final int CANCELLED    = 4;
    private static final int INTERRUPTING = 5;
    private static final int INTERRUPTED  = 6;

	/** The underlying callable; nulled out after running */
    private Callable<V> callable;
    /** 要返回的结果*/
    private Object outcome; // non-volatile, protected by state reads/writes
    /** The thread running the callable; CASed during run() */
    private volatile Thread runner;
    /** Treiber stack of waiting threads */
    private volatile WaitNode waiters;

	// CASC操作的函数
    private static final sun.misc.Unsafe UNSAFE;
	// 一些状态的偏移量
    private static final long stateOffset;
    private static final long runnerOffset;
    private static final long waitersOffset;
    static {
        try { // 静态代码块，在类加载时获得偏移量的值（也就是这些变量对应的内存地址）
            UNSAFE = sun.misc.Unsafe.getUnsafe();
            Class<?> k = FutureTask.class;
            stateOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("state"));
            runnerOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("runner"));
            waitersOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("waiters"));
        } catch (Exception e) {
            throw new Error(e);
        }
    }
```

## 内部类

```java
    static final class WaitNode {
        volatile Thread thread;
        volatile WaitNode next;
        WaitNode() { thread = Thread.currentThread(); }
    }
```



## 创建一个FutureTask

```java
    public FutureTask(Callable<V> callable) {
        if (callable == null)
            throw new NullPointerException();
        this.callable = callable;
        this.state = NEW;       // ensure visibility of callable
    }

    public FutureTask(Runnable runnable, V result) {
        // 设计模式：适配器模式，把Runnable转换为Callable
        this.callable = Executors.callable(runnable, result);
        this.state = NEW;       // ensure visibility of callable
    }

    public static <T> Callable<T> callable(Runnable task, T result) {
        if (task == null)
            throw new NullPointerException();
        return new RunnableAdapter<T>(task, result);
    }
	//  适配器模式的具体实现
    static final class RunnableAdapter<T> implements Callable<T> {
        final Runnable task;
        final T result;
        RunnableAdapter(Runnable task, T result) {
            this.task = task;
            this.result = result;
        }
        public T call() {
            task.run();
            return result;
        }
    }
```



## 任务执行的run方法

```java
    // 线程运行的方法
	public void run() {
        // 如果状态不是NEW 或 设置运行线程为当前线程失败，则直接返回
        if (state != NEW ||
            !UNSAFE.compareAndSwapObject(this, runnerOffset,
                                         null, Thread.currentThread()))
            return;
        try {
            Callable<V> c = callable;
            if (c != null && state == NEW) {
                V result;   // 暂存结果的局部变量
                boolean ran;
                try {
                    result = c.call();  // 运行callable接口的具体实现函数
                    ran = true;
                } catch (Throwable ex) {
                    result = null;
                    ran = false;
                    setException(ex);  // 设置异常
                }
                // 如果运行了，则把结果赋值到outcome中
                if (ran)
                    set(result);
            }
        } finally {
			// 设置运行线程为null，放置重复调用运行
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            int s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);  // 处理可能出现的中断或取消操作
        }
    }

    protected void setException(Throwable t) {
        // 设置state状态为COMPLETING，设置成功，则把异常赋值给outcome
        if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
            outcome = t;
            // 设置线程最终状态为EXCEPTIONAL
            UNSAFE.putOrderedInt(this, stateOffset, EXCEPTIONAL); // final state
            finishCompletion(); // 唤醒等待线程
        }
    }

    private void finishCompletion() {
        // 遍历等待线程，并把其唤醒
        for (WaitNode q; (q = waiters) != null;) {
            // 把等待线程设置为null
            if (UNSAFE.compareAndSwapObject(this, waitersOffset, q, null)) {
                for (;;) {
                    // 获得的等待线程中的第一个线程
                    Thread t = q.thread;
                    if (t != null) {
                        q.thread = null;
                        // 唤醒线程
                        LockSupport.unpark(t);
                    }
                    // 获得下一个waiter
                    WaitNode next = q.next;
                    if (next == null)
                        break;
                    q.next = null; // unlink to help gc
                    q = next;
                }
                break;
            }
        }
        done();
        callable = null;        // to reduce footprint
    }
	
	protected void done() { }
	// 把call函数的结果赋值到outcome中
    protected void set(V v) {
        // 把futureTask状态设置为COMPLETING
        if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
            // 赋值结果
            outcome = v;
            // 设置最终状态为NORMAL
            UNSAFE.putOrderedInt(this, stateOffset, NORMAL); // final state
            finishCompletion(); // 唤醒其他等待线程
        }
    }

    private void handlePossibleCancellationInterrupt(int s) {
        // It is possible for our interrupter to stall before getting a
        // chance to interrupt us.  Let's spin-wait patiently.
        if (s == INTERRUPTING)
            while (state == INTERRUPTING)
                Thread.yield(); // wait out pending interrupt
    }
```

## 获取任务结果

```java
   // 获取最终结果
	public V get() throws InterruptedException, ExecutionException {
        int s = state;
        // 如果状态为正在运行或 新建， 则等待任务执行完毕
        if (s <= COMPLETING)
            s = awaitDone(false, 0L);
        // 通过返回的futureTask的状态，报告相应的值；
        // 结果1：正常的计算记过
        // 结果2：异常信息
        return report(s);
    }
	
	// 规定超时时间，在规定时间没有获取到值，则抛出异常
    public V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException {
        if (unit == null)
            throw new NullPointerException();
        int s = state;
        if (s <= COMPLETING &&
            (s = awaitDone(true, unit.toNanos(timeout))) <= COMPLETING)
            throw new TimeoutException();
        return report(s);
    }
	// 等待任务执行完成，并返回futureTask状态
    private int awaitDone(boolean timed, long nanos)
        throws InterruptedException {
        final long deadline = timed ? System.nanoTime() + nanos : 0L;
        WaitNode q = null;
        boolean queued = false;
        for (;;) {//  死循环执行，也就是获取不到值，就阻塞
            // 如果当前线程中断了，则移除掉等待的线程，并抛出中断异常
            if (Thread.interrupted()) {
                removeWaiter(q);
                throw new InterruptedException();
            }

            int s = state;
            // 获取futureTask的状态，如果状态大于COMPLETING，则表示已经运行完毕
            // 则返回其状态
            if (s > COMPLETING) {
                if (q != null)
                    q.thread = null;
                return s;
            }
            // 如果是正在运行，则当前线程让出cpu
            else if (s == COMPLETING) // cannot time out yet
                Thread.yield();
            // 添加一个等待线程
            else if (q == null)
                q = new WaitNode();
            // 如果不允许排队，则设置等待线程为q
            else if (!queued)
                queued = UNSAFE.compareAndSwapObject(this, waitersOffset,
                                                     q.next = waiters, q);
            // 如果设置超时时间
            else if (timed) {
                // 那么在规定时间没有运行完，就把waitnode移除，并返回futureTask状态
                nanos = deadline - System.nanoTime();
                if (nanos <= 0L) {
                    removeWaiter(q);
                    return state;
                }
                // 并阻塞当前线程
                LockSupport.parkNanos(this, nanos);
            }
            else
                // 阻塞当前线程
                LockSupport.park(this);
        }
    }
	
    private void removeWaiter(WaitNode node) {
        // 先把要删除的node的thread设置为null
        // 这样下面循环删除thread为null的node时，才能删除调
        if (node != null) {
            node.thread = null;
            retry:
            for (;;) {          // 删除threda为null的节点
                for (WaitNode pred = null, q = waiters, s; q != null; q = s) {
                    s = q.next;
                    if (q.thread != null)
                        pred = q;
                    else if (pred != null) {
                        pred.next = s;
                        if (pred.thread == null) // check for race
                            continue retry;
                    }
                    else if (!UNSAFE.compareAndSwapObject(this, waitersOffset,
                                                          q, s))
                        continue retry;
                }
                break;
            }
        }
    }
	
	// 这里的参数s表示futureTask的状态
    private V report(int s) throws ExecutionException {
        Object x = outcome;
        // 如果状态正常，则outcome为计算结果正常返回
        if (s == NORMAL)
            return (V)x;
        // 如果状态为取消 或 中断
        // 则抛出取消异常
        if (s >= CANCELLED)
            throw new CancellationException();
        // 其他错误则outcome就是异常信息
        throw new ExecutionException((Throwable)x);
    }
```



## 取消任务

```java
    public boolean cancel(boolean mayInterruptIfRunning) {
        // 如果状态为NEW，并且把状态设置为INTERRUPT 或者 CALNCELLED成功，则向下执行
        if (!(state == NEW &&
              UNSAFE.compareAndSwapInt(this, stateOffset, NEW,
                  mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
            return false;
        try {    // 如果设置了可能中断为true，则中断当前正在运行的线程
            if (mayInterruptIfRunning) {
                try {
                    Thread t = runner;
                    if (t != null)
                        t.interrupt();
                } finally { // 并设置最终状态为INTERRUPTED
                    UNSAFE.putOrderedInt(this, stateOffset, INTERRUPTED);
                }
            }
        } finally { // 唤醒等待队列中的线程
            finishCompletion();
        }
        return true;
    }
```



