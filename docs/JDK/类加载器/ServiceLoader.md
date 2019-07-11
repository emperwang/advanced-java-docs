# ServiceLoader

## Field
```java
    // 加载类的路径(SPI实现类会通过此方式进行查找)
	private static final String PREFIX = "META-INF/services/";

    // The class or interface representing the service being loaded
	// 服务类
    private final Class<S> service;

    // The class loader used to locate, load, and instantiate providers
	// 类加载器
    private final ClassLoader loader;

    // The access control context taken when the ServiceLoader is created
	// 访问方式控制
    private final AccessControlContext acc;

    // Cached providers, in instantiation order
    private LinkedHashMap<String,S> providers = new LinkedHashMap<>();

    // The current lazy-lookup iterator
    private LazyIterator lookupIterator;
```

## 构造器

[ClassLoader](ClassLoader.md)对比查看。

```java
private ServiceLoader(Class<S> svc, ClassLoader cl) {
    // 加载的类不能为空
    service = Objects.requireNonNull(svc, "Service interface cannot be null");
    // 类加载器
    // 此处可以查看classLoader的分析
    loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
    // 控制器
    acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
    reload();
}
```


## 内部类
### Field
```java
// 服务接口
Class<S> service;
// 加载器
ClassLoader loader;
Enumeration<URL> configs = null;
// 实现类的迭代器
Iterator<String> pending = null;
// 下一个要解析的类
String nextName = null;
```
### 构造函数
```java
private LazyIterator(Class<S> service, ClassLoader loader) {
    this.service = service;
    this.loader = loader;
}
```


### 功能方法

#### hasNextService
```java
        private boolean hasNextService() {
            if (nextName != null) {
                return true;
            }
            if (configs == null) {
                try {
                    // 放置服务的文件名
                    String fullName = PREFIX + service.getName();
                    // 获取文件中的实现类全限定名
                    if (loader == null)
                        configs = ClassLoader.getSystemResources(fullName);
                    else
                        configs = loader.getResources(fullName);
                } catch (IOException x) {
                    fail(service, "Error locating configuration files", x);
                }
            }
            while ((pending == null) || !pending.hasNext()) {
                if (!configs.hasMoreElements()) {
                    return false;
                }
                // 解析出所有实现类的名字
                pending = parse(service, configs.nextElement());
            }
            // 获取下一个名字
            nextName = pending.next();
            return true;
        }
```
#### nextService
```java
        private S nextService() {
            if (!hasNextService())
                throw new NoSuchElementException();
            String cn = nextName;
            nextName = null;
            Class<?> c = null;
            try {
                // 加载实现类
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
                S p = service.cast(c.newInstance());
                // 缓存类，key为类型，value为实例
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
#### hasNext
```java
        public boolean hasNext() {
            if (acc == null) {
                return hasNextService();
            } else {
                PrivilegedAction<Boolean> action = new PrivilegedAction<Boolean>() {
                    public Boolean run() { return hasNextService(); }
                };
                return AccessController.doPrivileged(action, acc);
            }
        }
```
#### next
```java
        public S next() {
            // 返回实现类实例
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
#### remove

```java
        public void remove() {
            throw new UnsupportedOperationException();
        }
```




## 功能函数

### load
```java
public static <S> ServiceLoader<S> load(Class<S> service,ClassLoader loader){
    // 创建ServiceLoader实例
    return new ServiceLoader<>(service, loader);
}

public static <S> ServiceLoader<S> load(Class<S> service) {
    // 获取当前线程的类加载器
    ClassLoader cl = Thread.currentThread().getContextClassLoader();
    // 创建ServiceLoader的实例
    return ServiceLoader.load(service, cl);
}
```


### reload
```java
    public void reload() {
        // 清楚缓存
        providers.clear();
        // 创建新的懒加载器
        lookupIterator = new LazyIterator(service, loader);
    }
```


### fail
```java
// 直接抛异常
private static void fail(Class<?> service, String msg, Throwable cause)
    throws ServiceConfigurationError {
        throw new ServiceConfigurationError(service.getName() + ": " + msg, cause);
    }

private static void fail(Class<?> service, String msg)
    throws ServiceConfigurationError {
    throw new ServiceConfigurationError(service.getName() + ": " + msg);
}

private static void fail(Class<?> service, URL u, int line, String msg)
    throws ServiceConfigurationError {
    fail(service, u + ":" + line + ": " + msg);
}
```


### parseLine
```java
    // 解析一行名字
	// 一行就表示一个实现类
	private int parseLine(Class<?> service, URL u, BufferedReader r, int lc,
                          List<String> names)
        throws IOException, ServiceConfigurationError
    {
    	// 一行一行读取
        String ln = r.readLine();
        if (ln == null) {
            return -1;
        }
        // 表示注释
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
            // 没有缓存，并且names不包含此类
            // 则添加
            if (!providers.containsKey(ln) && !names.contains(ln))
                names.add(ln);
        }
        return lc + 1;
    }
```


### pase
```java
    // 解析实现类
	private Iterator<String> parse(Class<?> service, URL u)
        throws ServiceConfigurationError
    {
        InputStream in = null;
        BufferedReader r = null;
        ArrayList<String> names = new ArrayList<>();
        try {
        	// 打开文件输出流
            in = u.openStream();
            // 读取文件内容
            r = new BufferedReader(new InputStreamReader(in, "utf-8"));
            int lc = 1;
            // 解析类名字
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
        // 返回所有实现类的名字
        return names.iterator();
    }
```


### iterator

```java
    public Iterator<S> iterator() {
        return new Iterator<S>() {
            Iterator<Map.Entry<String,S>> knownProviders
                = providers.entrySet().iterator();
			
            // 从缓存中读取 或
            // 再次分析文件去查找
            public boolean hasNext() {
                if (knownProviders.hasNext())
                    return true;
                return lookupIterator.hasNext();
            }

            public S next() {
                if (knownProviders.hasNext())
                    return knownProviders.next().getValue();
                return lookupIterator.next();
            }

            public void remove() {
                throw new UnsupportedOperationException();
            }

        };
    }
```

### loadInstalled

```java
    public static <S> ServiceLoader<S> loadInstalled(Class<S> service) {
        // 获取加载器
        ClassLoader cl = ClassLoader.getSystemClassLoader();
        ClassLoader prev = null;
        while (cl != null) {
            prev = cl;
            cl = cl.getParent();
        }
        // 使用顶层父类加载服务
        return ServiceLoader.load(service, prev);
    }
```

