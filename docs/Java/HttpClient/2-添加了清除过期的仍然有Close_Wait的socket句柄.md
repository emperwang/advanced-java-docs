[TOC]

# httpClient连接未释放

上次分析时，由于是代码书写不对。进行了修改后发现，仍然由很多的连接未释放，而且是好几天才进行了释放，修改后的代码为：

```java
    private static PoolingHttpClientConnectionManager pool;

    static {
        pool = new PoolingHttpClientConnectionManager();
        pool.setMaxTotal(20);
        pool.setDefaultMaxPerRoute(20);

    }

    public static CloseableHttpClient httpClientPooled(Integer connectTimeout,Integer socketTime){
        RequestConfig requestConfig = RequestConfig.custom().setConnectTimeout(connectTimeout).setSocketTimeout(socketTime).build();
        Set<HttpRoute> routes = pool.getRoutes();
        for (HttpRoute route : routes) {
            log.info("route:{}", route.toString());
        }
        // 这里有个定时任务,会定时调用这里的closeExpiredConnections closeIdleConnections
        pool.closeExpiredConnections();
        pool.closeIdleConnections(50L, TimeUnit.SECONDS);
        CloseableHttpClient client = HttpClients.custom().setConnectionManager(pool)
                .setDefaultRequestConfig(requestConfig)
                .build();
        return client;
    }
```

这里呢相当于是有一个定时任务来调用清除过期以及idle过长的连接，但是呢，线上发现还是有未释放的连接，很奇怪。

当然了在HttpClientBuilder中也会创建一个后台线程来调用此两个参数，以达到清理的过程，需修改配置如下：

```java
    private static PoolingHttpClientConnectionManager pool;

    static {
        pool = new PoolingHttpClientConnectionManager();
        pool.closeExpiredConnections();
        pool.setMaxTotal(20);
        pool.setDefaultMaxPerRoute(20);
        pool.closeIdleConnections(50L, TimeUnit.SECONDS);
    }

    public static CloseableHttpClient httpClientPooled(Integer connectTimeout,Integer socketTime){
        RequestConfig requestConfig = RequestConfig.custom().setConnectTimeout(connectTimeout).setSocketTimeout(socketTime).build();
        CloseableHttpClient client = HttpClients.custom().setConnectionManager(pool)
            // 主要是配置下面两个
                .evictExpiredConnections()
                .evictIdleConnections(50, TimeUnit.SECONDS)
                .setDefaultRequestConfig(requestConfig)
                .build();
        return client;
    }
```

这里接着分析上面的问题，为什么closeExpiredConnections和closeIdleConnections函数没有生效呢？

咱们先看一下此两个函数的具体作用：

```java
@Override
public void closeIdleConnections(final long idleTimeout, final TimeUnit timeUnit) {
    if (this.log.isDebugEnabled()) {
        this.log.debug("Closing connections idle longer than " + idleTimeout + " " + timeUnit);
    }
    // 关闭 idle的连接
    this.pool.closeIdle(idleTimeout, timeUnit);
}

// 关闭idle
public void closeIdle(final long idletime, final TimeUnit timeUnit) {
    Args.notNull(timeUnit, "Time unit");
    long time = timeUnit.toMillis(idletime);
    if (time < 0) {
        time = 0;
    }
    final long deadline = System.currentTimeMillis() - time;
    // 这里指定了回调函数,来对连接进行测试
    enumAvailable(new PoolEntryCallback<T, C>() {
        @Override
        public void process(final PoolEntry<T, C> entry) {
            if (entry.getUpdated() <= deadline) {
                entry.close();
            }
        }
    });
}

// 遍历所有的可用连接,并使用对调函数进行处理
protected void enumAvailable(final PoolEntryCallback<T, C> callback) {
    this.lock.lock();
    try {
        final Iterator<E> it = this.available.iterator();
        while (it.hasNext()) {
            final E entry = it.next();
            callback.process(entry);
            if (entry.isClosed()) {
                final RouteSpecificPool<T, C, E> pool = getPool(entry.getRoute());
                pool.remove(entry);
                it.remove();
            }
        }
        purgePoolMap();
    } finally {
        this.lock.unlock();
    }
}
```

再看一下另一个:

```java
    // 关闭那些过期的连接
    @Override
    public void closeExpiredConnections() {
        this.log.debug("Closing expired connections");
        // 也就是 now > expire 时间后,就进行关闭
        this.pool.closeExpired();
    }

	// 遍历所有可用的连接, 关闭过期的连接
    public void closeExpired() {
        final long now = System.currentTimeMillis();
        enumAvailable(new PoolEntryCallback<T, C>() {
		// 判断连接是否过期,过期则清除
            @Override
            public void process(final PoolEntry<T, C> entry) {
                if (entry.isExpired(now)) {
                    entry.close();
                }
            }
        });
    }
```

这里咱们看一下对于每一个连接的expire时间 和 update时间时如何来的.

这里只看重点:

先看一下PoolingHttpClientConnectionManager的构造函数:

```java
    public PoolingHttpClientConnectionManager() {
        this(getDefaultRegistry());
    }

    public PoolingHttpClientConnectionManager(
            final Registry<ConnectionSocketFactory> socketFactoryRegistry) {
        this(socketFactoryRegistry, null, null);
    }
	// 这里设置了 ttl 为-1
    public PoolingHttpClientConnectionManager(
            final Registry<ConnectionSocketFactory> socketFactoryRegistry,
            final HttpConnectionFactory<HttpRoute, ManagedHttpClientConnection> connFactory,
            final DnsResolver dnsResolver) {
        this(socketFactoryRegistry, connFactory, null, dnsResolver, -1, TimeUnit.MILLISECONDS);
    }

    public PoolingHttpClientConnectionManager(
            final Registry<ConnectionSocketFactory> socketFactoryRegistry,
            final HttpConnectionFactory<HttpRoute, ManagedHttpClientConnection> connFactory,
            final SchemePortResolver schemePortResolver,
            final DnsResolver dnsResolver,
            final long timeToLive, final TimeUnit timeUnit) {
        this(
                // 创建 DefaultHttpClientConnectionOperator,即对http 连接的操作
    new DefaultHttpClientConnectionOperator(socketFactoryRegistry, schemePortResolver, dnsResolver),
            connFactory,
            timeToLive, timeUnit
        );
    }



   // 如果使用的是无参的构造函数,则此处的 ttl=-1, timeunit=TimeUnit.MILLISECONDS
    public PoolingHttpClientConnectionManager(
        final HttpClientConnectionOperator httpClientConnectionOperator,
        final HttpConnectionFactory<HttpRoute, ManagedHttpClientConnection> connFactory,
        final long timeToLive, final TimeUnit timeUnit) {
        super();
        // 记录配置数据
        this.configData = new ConfigData();
        // 创建CPool,存储连接; 从无参过来时,默认的connFactory=null
        this.pool = new CPool(new InternalConnectionFactory(
                this.configData, connFactory), 2, 20, timeToLive, timeUnit);
        // Inactivity 后多久进行一次 validate
        this.pool.setValidateAfterInactivity(2000);
        this.connectionOperator = Args.notNull(httpClientConnectionOperator, "HttpClientConnectionOperator");
        this.isShutDown = new AtomicBoolean(false);
    }
```

从这里可看出，使用无参的构造函数，创建连接池时，timeToLive=-1。

在看一下创建连接时的时间设置：

> org.apache.http.impl.conn.CPool#createEntry

```java
    // 创建一个 CPoolEntry
    @Override
    protected CPoolEntry createEntry(final HttpRoute route, final ManagedHttpClientConnection conn) {
        final String id = Long.toString(COUNTER.getAndIncrement());
        return new CPoolEntry(this.log, id, route, conn, this.timeToLive, this.timeUnit);
    }
```

此处使用的timeToLive是类属性，此属性由构造函数传递进来的：

```java
    public CPool(
            final ConnFactory<HttpRoute, ManagedHttpClientConnection> connFactory,
            final int defaultMaxPerRoute, final int maxTotal,
            final long timeToLive, final TimeUnit timeUnit) {
        super(connFactory, defaultMaxPerRoute, maxTotal);
        // ttl time to live
        this.timeToLive = timeToLive;
        // 时间单位
        this.timeUnit = timeUnit;
    }
```

此处的timeTolive呢，是由PoolingHttpClientConnectionManager传递的，值为-1。

而CPoolEntry是PoolEntry的子类，看一下CPoolEntry和PoolEntey的构造：

```java
    // 创建 CPoolEntry
    public CPoolEntry(
            final Log log,
            final String id,
            final HttpRoute route,
            final ManagedHttpClientConnection conn,
            final long timeToLive, final TimeUnit timeUnit) {
        super(id, route, conn, timeToLive, timeUnit);
        // 日志
        this.log = log;
    }

    public PoolEntry(final String id, final T route, final C conn,
            final long timeToLive, final TimeUnit timeUnit) {
        super();
        Args.notNull(route, "Route");
        Args.notNull(conn, "Connection");
        Args.notNull(timeUnit, "Time unit");
        // 此entry id
        this.id = id;
        // route
        this.route = route;
        // 连接
        this.conn = conn;
        // 创建时间
        this.created = System.currentTimeMillis();
        // 第一次时,更新时间就是 创建时间
        this.updated = this.created;
        // 如果设置了  timeToLive
        if (timeToLive > 0) {
            // 那么 dataline就是  创建时间+timetolive
            final long deadline = this.created + timeUnit.toMillis(timeToLive);
            // If the above overflows then default to Long.MAX_VALUE
            this.validityDeadline = deadline > 0 ? deadline : Long.MAX_VALUE;
        } else {
            // 如果没有设置 timeTolive, 则 validityDeadline=Long.MAX_VALUE
            this.validityDeadline = Long.MAX_VALUE;
        }
        // 如果没有设置 timeToLive呢,expiry=validityDeadline=Long.MAX_VALUE
        this.expiry = this.validityDeadline;
    }
```

CPoolEntry和PoolEntry是连接池中对连接的封装，判定expire或idle超时时，都是在此处进行的，看一下：

判断expire： 

> org.apache.http.impl.conn.CPoolEntry#isExpired

```java
    @Override
    public boolean isExpired(final long now) {
        // 由 poolEntry 来检测是否 超时
        final boolean expired = super.isExpired(now);
        if (expired && this.log.isDebugEnabled()) {
            this.log.debug("Connection " + this + " expired @ " + new Date(getExpiry()));
        }
        return expired;
    }
```

```java
    public synchronized boolean isExpired(final long now) {
        return now >= this.expiry;
    }
```

判断expire就是根据是当前时间是否大于expired，而当没有设置timeToLive呢，expiry=validityDeadline=Long.MAX_VALUE，所以基本不会有连接判断为expire。

判断idle：

> org.apache.http.pool.AbstractConnPool#closeIdle

```java
    public void closeIdle(final long idletime, final TimeUnit timeUnit) {
        Args.notNull(timeUnit, "Time unit");
        long time = timeUnit.toMillis(idletime);
        if (time < 0) {
            time = 0;
        }
        final long deadline = System.currentTimeMillis() - time;
        enumAvailable(new PoolEntryCallback<T, C>() {
            @Override
            public void process(final PoolEntry<T, C> entry) {
                if (entry.getUpdated() <= deadline) {
                    entry.close();
                }
            }
        });
    }
```

就是updatetime 小于 等于 deadline时，就说明超时了，进行关闭。

看一下此updatetime的获取：

```java
    public synchronized long getUpdated() {
        return this.updated;
    }
```

当entry第一次创建时，updatetime就是当时创建的时间，在看一下更新updatime的操作：

```java
// 此主要是更新 一个连接entry的expire时间,time主要是 从http header中的timeout字段获取    
public synchronized void updateExpiry(final long time, final TimeUnit timeUnit) {
        Args.notNull(timeUnit, "Time unit");
        // 更新为当前时间
        this.updated = System.currentTimeMillis();
        final long newExpiry;
        if (time > 0) {
            newExpiry = this.updated + timeUnit.toMillis(time);
        } else {
            newExpiry = Long.MAX_VALUE;
        }
  		// 选择一个较小值
        this.expiry = Math.min(newExpiry, this.validityDeadline);
    }
```

updateExpiry 更新过期时间，并且更新了updatetime，如果http header中设置了timeout时间，那么在这里就会使用到；如果没有设置呢，那么newExpiry = Long.MAX_VALUE，而且validityDeadline本身就是Long.MAX_VALUE，所以过期时间，也是Long.MAX_VALUE。

问题：

这里closeIdle时判断的是updatetime，如果连接没有使用，那么就没有人来更新此updatetime，那通过closeidle也可以释放那些连接，真实的情况却相反，没有释放。



当然了这里的expire的判断，通过分析也比较清楚了，因为没有设置timeToLive所以expire为Long.MAX_VALUE，也不会过期。

解决后的代码：

```java
private static PoolingHttpClientConnectionManager pool; 
static {
     // 主要是这里添加了参数, 指定了timeToLive的值
        pool = new PoolingHttpClientConnectionManager(50, TimeUnit.SECONDS);
        pool.setMaxTotal(20);
        pool.setDefaultMaxPerRoute(20);
    }

    public static CloseableHttpClient httpClientPooled(Integer connectTimeout,Integer socketTime){
        RequestConfig requestConfig = RequestConfig.custom().setConnectTimeout(connectTimeout).setSocketTimeout(socketTime).build();
        pool.closeExpiredConnections();
        pool.closeIdleConnections(50L, TimeUnit.SECONDS);
        CloseableHttpClient client = HttpClients.custom().setConnectionManager(pool)
                .evictExpiredConnections()
                .evictIdleConnections(50, TimeUnit.SECONDS)
                .setDefaultRequestConfig(requestConfig)
                .build();
        return client;
    }
```

进线上测试，连接释放。

































































