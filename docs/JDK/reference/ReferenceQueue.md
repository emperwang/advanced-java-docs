# ReferenceQueue

## Field

```java
    static ReferenceQueue<Object> NULL = new Null<>(); // Inactive队列
    static ReferenceQueue<Object> ENQUEUED = new Null<>();  // 加入队列
    private Lock lock = new Lock();
    private volatile Reference<? extends T> head = null;
    private long queueLength = 0;
```



## 构造方法

```java
    public ReferenceQueue() { }
```

## 加入数据

```java
    // 把pending状态的节点加入到队列中
	boolean enqueue(Reference<? extends T> r) { /* Called only by Reference class */
        synchronized (lock) {
			// 获取到该引用对应的节点
            ReferenceQueue<?> queue = r.queue;
            // 判断是否由队列   或者 是否已经被添加到队列中
            if ((queue == NULL) || (queue == ENQUEUED)) {
                return false;
            }
            assert queue == this;
            // 添加到队列(可以看到添加到队列，只是修改对应队列的值)
            r.queue = ENQUEUED;
            // 设置head和next的值
            // 可以看到next其实会指向当前节点的前一个节点，且此链表是一个单向链表
            // 也就是每次加入时，都是从头部添加，后进先出
            r.next = (head == null) ? r : head;
            head = r;
            queueLength++; // 长度加1 
            if (r instanceof FinalReference) {
                sun.misc.VM.addFinalRefCount(1);
            }
            lock.notifyAll();
            return true;
        }
    }
```



## 删除数据

```java
    // 删除数据
	public Reference<? extends T> remove() throws InterruptedException {
        return remove(0);
    }
	// 有超时的删除
    public Reference<? extends T> remove(long timeout)
        throws IllegalArgumentException, InterruptedException
    {
        if (timeout < 0) {
            throw new IllegalArgumentException("Negative timeout value");
        }
        synchronized (lock) {
        	// 从队列中获取元素
            Reference<? extends T> r = reallyPoll();
            // 获取到了，直接返回获取到的元素
            if (r != null) return r;
            long start = (timeout == 0) ? 0 : System.nanoTime();
            for (;;) {
            	// 没有获取到元素，则等待
                lock.wait(timeout);
                // 等待时间后，再次获取
                r = reallyPoll();
                // 获取到了，则返回
                if (r != null) return r;
                if (timeout != 0) {
                    long end = System.nanoTime();
                    timeout -= (end - start) / 1000_000;
                    if (timeout <= 0) return null;
                    start = end;
                }
            }
        }
    }
```



## 获取数据

```java
    // 从队列中获取数据，并把获取到的数据删除
	public Reference<? extends T> poll() {
        if (head == null)
            return null;
        synchronized (lock) {
            return reallyPoll();
        }
    }
	// 从队列中获取数据
	// 从head开始遍历获取
    private Reference<? extends T> reallyPoll() {       /* Must hold lock */
        Reference<? extends T> r = head;
        // 头节点不为null
        if (r != null) {
            // 如果有下一个元素，head=下一个元素，否则head=null
            head = (r.next == r) ?
                null :
                r.next; // Unchecked due to the next field having a raw type in Reference
            // 把获取到的元素的队列置为null
            r.queue = NULL;
            // next也指向自己
            // 从队列中删除
            r.next = r;
            // 队列长度减1
            queueLength--;
            if (r instanceof FinalReference) {
                sun.misc.VM.addFinalRefCount(-1);
            }
            return r; // 返回找到的元素
        }
        return null;
    }
```




