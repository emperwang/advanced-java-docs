# Reference的使用

Java中有4中引用存在，引用强度从高到低依次是：

1， StrongReference

​	这个引用在Java中没有相应的类与之对应，但是强引用比骄傲普遍，例如：Object obj = new Object(); 这里的obj就是强引用，如果一个对象具有强引用，则垃圾回收器始终不会回收此对象。当内存不足时，JVM会抛出OOM异常使程序异常终止也不会靠回收强引用的对象来解决内存不足的问题。

2， SoftReference

​	如果一个对象只有软引用，在内存虫族的情况下是不会回收此对象的。但是在内存不足即将要抛出OOM异常时，就会回收此对象类解决内存不足的问题。

```java
import java.lang.ref.*;

public class TestMAin {
    private static ReferenceQueue queue = new ReferenceQueue<Object>();

    public static void main(String[] args) throws InterruptedException {
        Object o = new Object();
        SoftReference softReference = new SoftReference(o, queue);
        System.out.println(softReference.get()!=null);
        o = null;
        System.gc();
        System.out.println(softReference.get()!=null);
    }
}
```

运行结果全为：true

这也说明了当内存充足的时候，一个对象只有软引用也不会被JVM回收。

3，WeakReference

WeakReference的回收策略有所不同。

只要GC发现一个对象只有弱引用，则就会回收此弱引用对象。但是由于GC所在的线程优先级比较低，不会立即发现所有弱引用并进行回收。只要GC进行扫描时发现了弱引用对象，就进行回收。

```java
import java.lang.ref.*;

public class TestMAin {
    private static ReferenceQueue queue = new ReferenceQueue<Object>();

    public static void main(String[] args) throws InterruptedException {
        Object o = new Object();
        WeakReference weakReference = new WeakReference(o, queue);
        System.out.println(weakReference.get()!=null);
        o = null; // 释放强引用
        System.gc();
        System.out.println(weakReference.get()!=null);
    }
}
```

运行结果: true  false

4，PhantomReference

PhantomReference，即虚引用，虚引用并不会影响对象的生命周期；虚引用的作用为：跟踪垃圾回收器收集对象这一活动的情况。

当GC一旦发现虚引用对象，则会将PhantomReference对象插入ReferenceQueue队列，而此时PhantomReference对象并没有被垃圾回收器回收，而是需要等到ReferenceQueue被你真正的处理后才会回收。

注意：PhantomReference必须要和ReferenceQueue联合使用，SoftReference和WeakReference可以选择和ReferenceQueue联合使用也可以不选择，这是他们的区别之一。

```java
import java.lang.ref.*;

public class TestMAin {
    private static ReferenceQueue queue = new ReferenceQueue<Object>();

    public static void main(String[] args) throws InterruptedException {
        Object o = new Object();
        PhantomReference phantomReference = new PhantomReference(o, queue);
        System.out.println(phantomReference.get());
        o = null;
        System.gc();
        System.out.println(phantomReference.get());
        Reference poll = queue.poll();
        if (poll != null){
            System.out.println("回收");
        }
    }
}
```

结果：null null  回收

* PhantomReference的get方法就是返回null。此可以在源码中看到
* o=null，当GC发现虚引用，GC会将PhantomReference对象放入到queue中，注意此时phantomReference所指向的对象并没有被回收，在我们真实调用了queue.poll(),返回Reference对象之后,当GC第二次返现虚引用,此时JVM就将phantomReference插入到队列queue失败,此时GC才会对虚引用对象进行回收.

