# thread

python3中由两个线程模块：

* _thread
* threading(推荐使用)

thread模块已经被废弃，用户可以使用threading模块代替。在python3中不能再使用thread模块，为了兼容python2，将其重命名为_thread.

### _thread

```python
_thread.start_new_thread(function,args[, kwargs])

function: 线程函数
args: 传递给线程函数的参数，它必须是个tuple类型
kwargs: 可选参数
```

```python
#!/usr/bin/python3
# coding=utf-8
import _thread
import time


# 为线程定义一个函数
def print_time(threadName, delay):
    count = 0
    while count <= 5:
        time.sleep(delay)
        count += 1
        print("%s:%s"%(threadName, time.ctime(time.time())))

# 创建两个线程
try:
    _thread.start_new_thread(print_time, ("Thread-1", 2,))
    _thread.start_new_thread(print_time, ("Thread-3", 4,))
except Exception as e:
    print("Error, can not start thread")

while 1:
    pass


### 输出：
Thread-1:Tue Nov 26 23:02:45 2019
Thread-3:Tue Nov 26 23:02:47 2019
Thread-1:Tue Nov 26 23:02:47 2019
Thread-1:Tue Nov 26 23:02:49 2019
Thread-3:Tue Nov 26 23:02:51 2019
Thread-1:Tue Nov 26 23:02:51 2019
Thread-1:Tue Nov 26 23:02:53 2019
Thread-3:Tue Nov 26 23:02:55 2019
Thread-1:Tue Nov 26 23:02:55 2019
```



### threading

_thread提供了低级别的，原始的线程以及一个简单的锁，相比于threading模块的功能还是比较有限的。threading模块除了包含 _thread 模块中所有方法外，还提供其他方法：

* threading.currentThread()  : 返回当前的线程变量
* threading.enumerate() : 返回一个包含正在运行的线程的list. 正在运行指线程启动后,结束前, 不包括启动前和终止后的线程
* threading.activeCount(): 返回正在运行的线程的梳理. 与 len(threading.enumerate()) 由相同的结果

除了使用方法外，线程模块通用提供了Thread类处理线程，Thread提供以下方法：

* run(): 用以表示线程活动的方法
* start(): 启动线程活动
* join([time]): 等待线程终止。这阻塞调用线程直至join()方法被调用终止-正常退出或抛出未处理的异常或是可选的超时发生
* isAlive(): 返回线程是否活动的
* getName(): 返回线程名字
*  setName(): 设置线程名字

```python
#!/usr/bin/python3
# coding=utf-8
import threading
import time

exitFlag = 0

class myThread(threading.Thread):
    def __init__(self, threadID, name, counter):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.counter = counter

    def run(self):
        print("thread starting...")
        print_time(self.name, 5, self.counter)


def print_time(threadName, delay, counter):
    while counter:
        if exitFlag:
            threadName.exit()
        time.sleep(delay)
        print("%s:%s"%(threadName, time.ctime(time.time())))
        counter -= 1


thread1 = myThread(1, "Thread-1", 1)
thread2 = myThread(2,"thread-2", 3)

thread1.start()
thread2.start()

thread1.join()
thread2.join()
print("exist from main ....")


### 输出
thread starting...
thread starting...
Thread-1:Tue Nov 26 23:19:26 2019
thread-2:Tue Nov 26 23:19:26 2019
thread-2:Tue Nov 26 23:19:31 2019
thread-2:Tue Nov 26 23:19:36 2019
exist from main ....
```

### 线程同步

使用Thread对象的Lock和Rlock可以实现简单的线程同步，这两个对象都有acquire和release方法，对于那些需要每次只允许一个线程操作的数据，可以将其操作放到acquire和release之间。

```python
#!/usr/bin/python3
# coding=utf-8
import threading
import time

class MyThread(threading.Thread):
    def __init__(self, threadID, name, counter):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.counter = counter
    def run(self):
        print("starting thread...")
        threadLock.acquire()
        print_time(self.name, 5, self.counter)
        threadLock.release()

threadLock = threading.Lock()
threadRlock = threading.RLock()
threads = []

def print_time(threadName, delay, counter):
    while counter:
        time.sleep(delay)
        print("%s:%s" % (threadName, time.ctime(time.time())))
        counter -= 1

thread1 = MyThread(1, "Thread-1",2)
thread2 = MyThread(1, "Thread-2", 4)

threads.append(thread1)
threads.append(thread2)

thread1.start()
thread2.start()

for i in threads:
    i.join()

print("exist .....")

## 输出结果
starting thread...
starting thread...
Thread-1:Tue Nov 26 23:30:05 2019
Thread-1:Tue Nov 26 23:30:10 2019
Thread-2:Tue Nov 26 23:30:15 2019
Thread-2:Tue Nov 26 23:30:20 2019
Thread-2:Tue Nov 26 23:30:25 2019
Thread-2:Tue Nov 26 23:30:30 2019
exist .....
```





### 队列

