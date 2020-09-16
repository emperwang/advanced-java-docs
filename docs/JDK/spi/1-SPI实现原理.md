[TOC]

# SPI实现

本篇来分析一下jdk spi机制的实现.

来一个demo来作为入口:

```java
package com.wk.spi.iface;

public interface IFace {
    void printInfo();
}
```

实现类:

```java
package com.wk.spi.iface.impl;

import com.wk.spi.iface.IFace;
public class IFaceImplA implements IFace {
    @Override
    public void printInfo() {
        System.out.println("this is imple A");
    }
}




package com.wk.spi.iface.impl;

import com.wk.spi.iface.IFace;

public class IFaceImplB implements IFace {

    @Override
    public void printInfo() {
        System.out.println("this is imple B");
    }
}



package com.wk.spi.iface.impl;

import com.wk.spi.iface.IFace;

public class IFaceImplC implements IFace {
    @Override
    public void printInfo() {
        System.out.println("this is imple C");
    }
}

```

然后在resources目录下创建 META-INF/services/com.wk.spi.iface.IFace 文件，内容为:

```shell
com.wk.spi.iface.impl.IFaceImplA
com.wk.spi.iface.impl.IFaceImplB
com.wk.spi.iface.impl.IFaceImplC
```

启动类:

```java
package com.wk.spi;

import com.wk.spi.iface.IFace;

import java.util.Iterator;
import java.util.ServiceLoader;

/**
 * 1. 创建一个接口 com.wk.spi.iface.IFace
 * 2. 创建此接口的实现类
 * 3. 在resources目录下创建: MEAT-INF/services/com.wk.spi.iface.IFace  文件
 * 4. 在 第3步 创建的文件中 写入com.wk.spi.iface.IFace的实现类的全类名
 */
public class SpiStarter {
    public static void main(String[] args) {
        ServiceLoader<IFace> load = ServiceLoader.load(IFace.class);
        Iterator<IFace> iter = load.iterator();
        while (iter.hasNext()){
            iter.next().printInfo();
        }
    }
}
```

直接运行就可以了。下面咱们来进入serviceLoader分析一下此SPI的实现机制。

> java.util.ServiceLoader#load(Class<S>)

```java
    // 使用SPI来加载类,还有一个重载方法,可以指定使用的类加载器
    public static <S> ServiceLoader<S> load(Class<S> service) {
        // 如果没有指定,则使用当前线程的类加载器
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        // 加载
        return ServiceLoader.load(service, cl);
    }
```

```java
// 使用spi去加载类,可以指定使用的类加载器
public static <S> ServiceLoader<S> load(Class<S> service,
                                        ClassLoader loader)
{
    // 创建ServiceLoader实例
    return new ServiceLoader<>(service, loader);
}
```

相当于工厂方法，创建了ServiceLoader的实例，看一下其构造器:

```java
// 构造函数
private ServiceLoader(Class<S> svc, ClassLoader cl) {
    // 判断类型不可为空
    // 这里赋值 service 就是要加载的类
    service = Objects.requireNonNull(svc, "Service interface cannot be null");
    // 如果没有指定类加载器其,则使用系统加载器
    loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
    // securityManager
    acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
    // 重新加载
    reload();
}

public void reload() {
    // 清除缓存
    providers.clear();
    // 创建一个迭代器
    lookupIterator = new LazyIterator(service, loader);
}
```

可以看到这里创建了一个懒迭代器，之后就可以调用load.iterator来获取到实现类的实例，并进行调用，看一下load.iterator方法。

> java.util.ServiceLoader#iterator

```java
// 返回一个迭代器来对具体的实现类 进行迭代
public Iterator<S> iterator() {
    // 创建迭代器
    return new Iterator<S>() {
        // 获取 providers 容器的迭代器
        Iterator<Map.Entry<String,S>> knownProviders
            = providers.entrySet().iterator();
        // 如果providers 中有值,则使用providers中的值
        // 否则查看 lookupIterator 迭代器中的数据
        // lookupIterator 就是 LazyIterator迭代器
        public boolean hasNext() {
            if (knownProviders.hasNext())
                return true;
            return lookupIterator.hasNext();
        }
        // 下一个实现类
        public S next() {
            if (knownProviders.hasNext())
                return knownProviders.next().getValue();
            // 从providers中
            return lookupIterator.next();
        }
		// 不支持移除操作
        public void remove() {
            throw new UnsupportedOperationException();
        }

    };
}
```

```java
    // 记录创建好的实例
    // key为全限定类名, value为实例
    private LinkedHashMap<String,S> providers = new LinkedHashMap<>();

    // The current lazy-lookup iterator
    // 懒加载器
    private LazyIterator lookupIterator;
```

看到这里创建了一个Iterator迭代器的实现，这里判断是否有下一个实现类时，先去providers 缓存中查看，如果provider中存在，则就是存在，否则去lookupIterator中查看，其中lookupIterator其实就是LazyIterator，所以这里调用LazyIterator来进行判断，next()获取实现类实例同样也是这样的操作,下面就看一下此LazyIterator的实现。

> java.util.ServiceLoader.LazyIterator#hasNextService

```java
/// 是否还有下一个实现
private boolean hasNextService() {
    if (nextName != null) {
        return true;
    }
    if (configs == null) {
        try {
            // PREFIX="META-INF/services/"; 约定的目录
            // 前缀加 接口名, 得到文件名
            String fullName = PREFIX + service.getName();
            // 加载资源文件
            if (loader == null)
                configs = ClassLoader.getSystemResources(fullName);
            else
                configs = loader.getResources(fullName);
        } catch (IOException x) {
            fail(service, "Error locating configuration files", x);
        }
    }
    // 此while 会一直解析,直到解析到一个合适的配置文件
    while ((pending == null) || !pending.hasNext()) {
        if (!configs.hasMoreElements()) {
            return false;
        }
        // 解析配置文件
        pending = parse(service, configs.nextElement());
    }
    nextName = pending.next();
    return true;
}
```

这里看到先去META-INF/services/约定的目录中查找对应接口文件，当然了文件可能有多个，之后回去到此文件的url，并进行解析。

看一下解析操作:

> java.util.ServiceLoader#parse

```java
private Iterator<String> parse(Class<?> service, URL u)
    throws ServiceConfigurationError
{
    InputStream in = null;
    BufferedReader r = null;
    // 此names 存储从文件中读取的具体的实现类名
    ArrayList<String> names = new ArrayList<>();
    try {
        // 获得文件的输入流
        in = u.openStream();
        // 装饰一下 使用BufferedReader 来读取文件中内容
        r = new BufferedReader(new InputStreamReader(in, "utf-8"));
        int lc = 1;
        // 解析
        while ((lc = parseLine(service, u, r, lc, names)) >= 0);
    } catch (IOException x) {
        fail(service, "Error reading configuration file", x);
    } finally {
        try {
            if (r != null) r.close();
            if (in != null) in.close();
        } catch (IOException y) {
            fail(service, "Error closing configuration file", y);
        }
    }
    // 返回names容器的迭代器
    return names.iterator();
}
```

可以看到这里使用BufferReader修饰了输入流，之后开始解析行:

> java.util.ServiceLoader#parseLine

```java
private int parseLine(Class<?> service, URL u, BufferedReader r, int lc,
                      List<String> names)
    throws IOException, ServiceConfigurationError
{
    // 从配置文件中读取一行,一行即对应一个实现类
    String ln = r.readLine();
    if (ln == null) {
        return -1;
    }
    // # 为注释
    int ci = ln.indexOf('#');
    if (ci >= 0) ln = ln.substring(0, ci);
    ln = ln.trim();
    int n = ln.length();
    if (n != 0) {
        if ((ln.indexOf(' ') >= 0) || (ln.indexOf('\t') >= 0))
            fail(service, u, lc, "Illegal configuration-file syntax");
        int cp = ln.codePointAt(0);
        if (!Character.isJavaIdentifierStart(cp))
            fail(service, u, lc, "Illegal provider-class name: " + ln);
        for (int i = Character.charCount(cp); i < n; i += Character.charCount(cp)) {
            cp = ln.codePointAt(i);
            if (!Character.isJavaIdentifierPart(cp) && (cp != '.'))
                fail(service, u, lc, "Illegal provider-class name: " + ln);
        }
        // 此name还没有解析,则记录下此类
        if (!providers.containsKey(ln) && !names.contains(ln))
            names.add(ln);
    }
    return lc + 1;
}
```

这里比较简单了，进行了一系列的判断，之后判断此名字是否解析过，如果没有解析过，则保存此名字。

看一下是如何获取实现类实例的操作：

> java.util.ServiceLoader.LazyIterator#next

```java
// 下一个实现类
public S next() {
    if (acc == null) {
        return nextService();
    } else {
        PrivilegedAction<S> action = new PrivilegedAction<S>() {
            public S run() { return nextService(); }
        };
        return AccessController.doPrivileged(action, acc);
    }
}
```

> java.util.ServiceLoader.LazyIterator#nextService

```java
// 下一个实现类实例
private S nextService() {
    // 如果没有了,则报错
    if (!hasNextService())
        throw new NoSuchElementException();
    String cn = nextName;
    nextName = null;
    Class<?> c = null;
    try {
        // 加载类
        c = Class.forName(cn, false, loader);
    } catch (ClassNotFoundException x) {
        fail(service,
             "Provider " + cn + " not found");
    }
    if (!service.isAssignableFrom(c)) {
        fail(service,
             "Provider " + cn  + " not a subtype");
    }
    try {
        // 创建实例, 并转换为 service类型
        S p = service.cast(c.newInstance());
        // 存储起来
        // key为名字, p为实例
        providers.put(cn, p);
        return p;
    } catch (Throwable x) {
        fail(service,
             "Provider " + cn + " could not be instantiated",
             x);
    }
    throw new Error();          // This cannot happen
}
```

可以看到，迭代器的next操作就是获取到全类名，使用Class.Forname进行类的加载，之后使用class.newInstance 实例化，实例化完成后保存到providers中，key为全类名，value为实例。

到此java的spi就解析完了，总体还是比较简单的。











































































