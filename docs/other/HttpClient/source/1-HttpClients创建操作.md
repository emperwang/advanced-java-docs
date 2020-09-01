[TOC]

#   httpClients的创建操作

本篇开始，来看一下httpClient的源码，主要脉络从httpClient的使用入手来进行查看。

看一下httpClient使用demo：

```java
    private static PoolingHttpClientConnectionManager pool;
    static {
        pool = new PoolingHttpClientConnectionManager(50, TimeUnit.SECONDS);
        pool.setMaxTotal(20);
        pool.setDefaultMaxPerRoute(20);
    }
	// httpClient 的创建
    public static CloseableHttpClient httpClientPooled(Integer connectTimeout,Integer socketTime){
        RequestConfig requestConfig = RequestConfig.custom().setConnectTimeout(connectTimeout).setSocketTimeout(socketTime).build();
        pool.closeExpiredConnections();
        pool.closeIdleConnections(50L, TimeUnit.SECONDS);
        Set<HttpRoute> routes = pool.getRoutes();
        for (HttpRoute route : routes) {
            log.info("route:{}", route.toString());
        }
        CloseableHttpClient client = HttpClients.custom().setConnectionManager(pool)
                .evictExpiredConnections()
                .evictIdleConnections(50, TimeUnit.SECONDS)
                .setDefaultRequestConfig(requestConfig)
                .build();
        return client;
    }
```

```java
// 客户端 请求执行   
public static Map<String,String>  httpPutMethodWithStatusCode(HttpConfig httpConfig){
        logger.debug("httpclient put method start,the url is{}",httpConfig.getUrl());
        CloseableHttpResponse response = null;
        HttpPut request = (HttpPut) getRequest(httpConfig.getUrl(),httpConfig.getMethods());
        Map<String,String> result = new HashMap<>(2);
        Integer statusCode = null;
        String entityString = "";
        try {
            configRequest(request,httpConfig);
            configParamEntity(request,httpConfig);
            response = (CloseableHttpResponse) httpConfig.getClient().execute(request);
            statusCode = response.getStatusLine().getStatusCode();
            logger.info("httpPutMethodWithStatusCode statusCode is {}",statusCode);
            if (200 != statusCode && 201 != statusCode) {
                entityString = convertResponseToString(response);
            }
            result.put("code",statusCode.toString());
            result.put("message",entityString);
            if (logger.isDebugEnabled()){
                logger.debug("httpPutMethodWithStatusCode response:{}",result.toString());
            }
            return result;
        } catch (Exception e) {
            logger.error("Httpclient httpPutMethodWithStatusCode error,the url is{},the error msg is{}", httpConfig.getUrl(),e.getMessage());
            if (null != statusCode){
                result.put("code",statusCode.toString());
            }else{
                result.put("code","500");
            }
            if (!"".equals(entityString)){
                result.put("message", entityString);
            }else {
                result.put("message", e.getMessage());
            }
            return result;
        }finally {
            close((CloseableHttpClient) httpConfig.getClient(),response);
        }
    }
```

这里就从创建开始了解源码:

> org.apache.http.impl.client.HttpClients#custom

```java
// 静态创建方法
public static HttpClientBuilder custom() {
    return HttpClientBuilder.create();
}
```

> org.apache.http.impl.client.HttpClientBuilder#create

```java
// builder 类
public static HttpClientBuilder create() {
    return new HttpClientBuilder();
}
```

> org.apache.http.impl.client.HttpClientBuilder#build

```java
// 创建httpClient 实例
public CloseableHttpClient build() {
    // Create main request executor
    // We copy the instance fields to avoid changing them, and rename to avoid accidental use of the wrong version
    // 尾缀匹配器
    PublicSuffixMatcher publicSuffixMatcherCopy = this.publicSuffixMatcher;
    // 1.如果没有配置呢,就使用一个默认值
    if (publicSuffixMatcherCopy == null) {
        publicSuffixMatcherCopy = PublicSuffixMatcherLoader.getDefault();
    }
    // 执行器
    HttpRequestExecutor requestExecCopy = this.requestExec;
    // 2.如果没有设置执行器,则配置默认的执行器
    if (requestExecCopy == null) {
        requestExecCopy = new HttpRequestExecutor();
    }
    // 连接池
    HttpClientConnectionManager connManagerCopy = this.connManager;
    // 3. 如果没有配置连接池,则也会配置一个
    if (connManagerCopy == null) {
        LayeredConnectionSocketFactory sslSocketFactoryCopy = this.sslSocketFactory;
        // 3.1 这里主要是 创建sslSocketFactory
        if (sslSocketFactoryCopy == null) {
            // 3.2  获取配置的系统属性
            // 支持的https 协议
            final String[] supportedProtocols = systemProperties ? split(
                System.getProperty("https.protocols")) : null;
            // 支持的 https 算法
            final String[] supportedCipherSuites = systemProperties ? split(
                System.getProperty("https.cipherSuites")) : null;
            // 3.3 设置主机名校验
            HostnameVerifier hostnameVerifierCopy = this.hostnameVerifier;
            // 没有配置主机名校验,则使用默认的校验规则
            if (hostnameVerifierCopy == null) {
                hostnameVerifierCopy = new DefaultHostnameVerifier(publicSuffixMatcherCopy);
            }
            // 3.4 创建 SSLConnectionSocketFactory
            // 如果设置了 sslContext,就加载了证书的context
            // 那么就使用此指定的 sslContext来常见 sslConnectionSocketFactory
            if (sslContext != null) {
                sslSocketFactoryCopy = new SSLConnectionSocketFactory(
                    sslContext, supportedProtocols, supportedCipherSuites, hostnameVerifierCopy);
            } else {
                // 如果没有配置sslContext,但是设置了系统属性,那么就使用系统属性来 创建 SSLConnectionSocketFactory
                if (systemProperties) {
                    sslSocketFactoryCopy = new SSLConnectionSocketFactory(
                        (SSLSocketFactory) SSLSocketFactory.getDefault(),
                        supportedProtocols, supportedCipherSuites, hostnameVerifierCopy);
                } else {
                    // 系统属性 sslContext 都没有设置,则创建一个默认的
                    sslSocketFactoryCopy = new SSLConnectionSocketFactory(
                        SSLContexts.createDefault(),
                        hostnameVerifierCopy);
                }
            }
        }
        // 3.5 创建连接池
        @SuppressWarnings("resource")
        final PoolingHttpClientConnectionManager poolingmgr = new PoolingHttpClientConnectionManager(
            RegistryBuilder.<ConnectionSocketFactory>create()
            .register("http", PlainConnectionSocketFactory.getSocketFactory())
            .register("https", sslSocketFactoryCopy)
            .build(),
            null,
            null,
            dnsResolver,
            connTimeToLive,
            connTimeToLiveTimeUnit != null ? connTimeToLiveTimeUnit : TimeUnit.MILLISECONDS);
        // 3.6 属性以及设置的配置
        if (defaultSocketConfig != null) {
            poolingmgr.setDefaultSocketConfig(defaultSocketConfig);
        }
        if (defaultConnectionConfig != null) {
            poolingmgr.setDefaultConnectionConfig(defaultConnectionConfig);
        }
        if (systemProperties) {
            // 是否设置了 http.keepAlive
            String s = System.getProperty("http.keepAlive", "true");
            if ("true".equalsIgnoreCase(s)) {
                // 最大连接数
                s = System.getProperty("http.maxConnections", "5");
                final int max = Integer.parseInt(s);
                // 设置默认的 route数为  http.maxConnections
                poolingmgr.setDefaultMaxPerRoute(max);
                // 最大连接数为 两倍的 http.maxConnections
                poolingmgr.setMaxTotal(2 * max);
            }
        }
        // 设置最大连接数
        if (maxConnTotal > 0) {
            poolingmgr.setMaxTotal(maxConnTotal);
        }
        // maxRoute
        if (maxConnPerRoute > 0) {
            poolingmgr.setDefaultMaxPerRoute(maxConnPerRoute);
        }
        // 记录连接池
        connManagerCopy = poolingmgr;
    }
    // 4. 连接重用的策略
    ConnectionReuseStrategy reuseStrategyCopy = this.reuseStrategy;
    // 4.1 如果没有设置 连接重用的策略
    if (reuseStrategyCopy == null) {
        // 4.2 如果使用系统属性,则判断是否设置http.keepAlive
        if (systemProperties) {
            final String s = System.getProperty("http.keepAlive", "true");
            // 如果配置了http.keepAlive,则创建默认额 连接重用策略
            if ("true".equalsIgnoreCase(s)) {
                reuseStrategyCopy = DefaultClientConnectionReuseStrategy.INSTANCE;
            } else {
                // 否则 没有连接重用策略
                reuseStrategyCopy = NoConnectionReuseStrategy.INSTANCE;
            }
        } else {
            // 4.3 如果不适用系统属性,则创建默认的连接重用策略
            reuseStrategyCopy = DefaultClientConnectionReuseStrategy.INSTANCE;
        }
    }
    // 5. keepAlive的 策略
    ConnectionKeepAliveStrategy keepAliveStrategyCopy = this.keepAliveStrategy;
    // 5.1 如果没有设置,则配置一个默认的  keepAlive的策略
    if (keepAliveStrategyCopy == null) {
        keepAliveStrategyCopy = DefaultConnectionKeepAliveStrategy.INSTANCE;
    }
    // 6. 目标机器的认证的策略
    AuthenticationStrategy targetAuthStrategyCopy = this.targetAuthStrategy;
    if (targetAuthStrategyCopy == null) {
        targetAuthStrategyCopy = TargetAuthenticationStrategy.INSTANCE;
    }
    // 7. 代理机器的 认证策略
    AuthenticationStrategy proxyAuthStrategyCopy = this.proxyAuthStrategy;
    if (proxyAuthStrategyCopy == null) {
        proxyAuthStrategyCopy = ProxyAuthenticationStrategy.INSTANCE;
    }
    // 8. useToken的处理
    UserTokenHandler userTokenHandlerCopy = this.userTokenHandler;
    if (userTokenHandlerCopy == null) {
        if (!connectionStateDisabled) {
            userTokenHandlerCopy = DefaultUserTokenHandler.INSTANCE;
        } else {
            userTokenHandlerCopy = NoopUserTokenHandler.INSTANCE;
        }
    }
    // 9. userAgent的处理
    String userAgentCopy = this.userAgent;
    if (userAgentCopy == null) {
        if (systemProperties) {
            userAgentCopy = System.getProperty("http.agent");
        }
        // agent的设置
        if (userAgentCopy == null && !defaultUserAgentDisabled) {
            userAgentCopy = VersionInfo.getUserAgent("Apache-HttpClient",
                                                     "org.apache.http.client", getClass());
        }
    }
    // 10. 创建主要的执行器
    ClientExecChain execChain = createMainExec(
        requestExecCopy,
        connManagerCopy,
        reuseStrategyCopy,
        keepAliveStrategyCopy,
        new ImmutableHttpProcessor(new RequestTargetHost(), new RequestUserAgent(userAgentCopy)),
        targetAuthStrategyCopy,
        proxyAuthStrategyCopy,
        userTokenHandlerCopy);
    // 11 装饰执行链
    execChain = decorateMainExec(execChain);
    // 12. 创建httpProcessor
    // 这里的 httpProcessor保存了众多的 拦截器,用于对http协议的各种处理
    HttpProcessor httpprocessorCopy = this.httpprocessor;
    if (httpprocessorCopy == null) {
        // 12.1 先创建一个 builder 来创建 httpProcessor
        final HttpProcessorBuilder b = HttpProcessorBuilder.create();
        // 12.2 如果设置了request的拦截器,则添加到 builder中
        if (requestFirst != null) {
            for (final HttpRequestInterceptor i: requestFirst) {
                b.addFirst(i);
            }
        }
        // 12.3 response的拦截器
        if (responseFirst != null) {
            for (final HttpResponseInterceptor i: responseFirst) {
                b.addFirst(i);
            }
        }
        // 12.4 添加各种拦截器
        b.addAll(
            new RequestDefaultHeaders(defaultHeaders),
            new RequestContent(),
            new RequestTargetHost(),
            new RequestClientConnControl(),
            new RequestUserAgent(userAgentCopy),
            new RequestExpectContinue());
        // 12.5 cookie 拦截器
        if (!cookieManagementDisabled) {
            b.add(new RequestAddCookies());
        }
        // 允许的 压缩类型 拦截器
        // 是否允许压缩
        // 12.6 允许的压缩类型 拦截器
        if (!contentCompressionDisabled) {
            if (contentDecoderMap != null) {
                final List<String> encodings = new ArrayList<String>(contentDecoderMap.keySet());
                Collections.sort(encodings);
                b.add(new RequestAcceptEncoding(encodings));
            } else {
                b.add(new RequestAcceptEncoding());
            }
        }
        // 12.7 认证缓存烂机器
        if (!authCachingDisabled) {
            b.add(new RequestAuthCache());
        }
        // 12.8 cookie 管理
        if (!cookieManagementDisabled) {
            b.add(new ResponseProcessCookies());
        }
        // 响应的content 是否允许压缩
        // 12.9 添加responseContent编码
        if (!contentCompressionDisabled) {
            if (contentDecoderMap != null) {
                final RegistryBuilder<InputStreamFactory> b2 = RegistryBuilder.create();
                for (final Map.Entry<String, InputStreamFactory> entry: contentDecoderMap.entrySet()) {
                    b2.register(entry.getKey(), entry.getValue());
                }
                b.add(new ResponseContentEncoding(b2.build()));
            } else {
                b.add(new ResponseContentEncoding());
            }
        }
        // 12.10 request最后的一个 拦截器
        if (requestLast != null) {
            for (final HttpRequestInterceptor i: requestLast) {
                b.addLast(i);
            }
        }
        // 12.11 response的最后一个拦截器
        if (responseLast != null) {
            for (final HttpResponseInterceptor i: responseLast) {
                b.addLast(i);
            }
        }
        // 12.12 根据 添加的拦截器 创建个月 processor
        httpprocessorCopy = b.build();
    }
    // 对http 协议的处理
    // 13. 装饰者模式, 根据创建的Httpprocessor 来装饰具体的执行器,即在执行前和执行后,调用各种拦截器
    execChain = new ProtocolExec(execChain, httpprocessorCopy);
    // 装饰
    execChain = decorateProtocolExec(execChain);

    // Add request retry executor, if not disabled
    // 14. 如果允许失败重试,则再次使用装饰者模式,对主要执行器进行包装,即catch异常,并进行重试
    if (!automaticRetriesDisabled) {
        HttpRequestRetryHandler retryHandlerCopy = this.retryHandler;
        if (retryHandlerCopy == null) {
            retryHandlerCopy = DefaultHttpRequestRetryHandler.INSTANCE;
        }
        // 14.1 重试机制
        execChain = new RetryExec(execChain, retryHandlerCopy);
    }
    // 15. router 计划者,用来解析route信息,其中就包含了代理
    HttpRoutePlanner routePlannerCopy = this.routePlanner;
    if (routePlannerCopy == null) {
        // scheme对应的port的解析器
        SchemePortResolver schemePortResolverCopy = this.schemePortResolver;
        if (schemePortResolverCopy == null) {
            schemePortResolverCopy = DefaultSchemePortResolver.INSTANCE;
        }
        if (proxy != null) {
            routePlannerCopy = new DefaultProxyRoutePlanner(proxy, schemePortResolverCopy);
        } else if (systemProperties) {
            routePlannerCopy = new SystemDefaultRoutePlanner(
                schemePortResolverCopy, ProxySelector.getDefault());
        } else {
            routePlannerCopy = new DefaultRoutePlanner(schemePortResolverCopy);
        }
    }

    // Optionally, add service unavailable retry executor
    // 15. 装饰者, 服务不可用是的重试
    final ServiceUnavailableRetryStrategy serviceUnavailStrategyCopy = this.serviceUnavailStrategy;
    if (serviceUnavailStrategyCopy != null) {
        execChain = new ServiceUnavailableRetryExec(execChain, serviceUnavailStrategyCopy);
    }

    // Add redirect executor, if not disabled
    // 16. 重定向的执行 -- 装饰者
    if (!redirectHandlingDisabled) {
        RedirectStrategy redirectStrategyCopy = this.redirectStrategy;
        // 重定向
        if (redirectStrategyCopy == null) {
            redirectStrategyCopy = DefaultRedirectStrategy.INSTANCE;
        }
        execChain = new RedirectExec(execChain, routePlannerCopy, redirectStrategyCopy);
    }

    // Optionally, add connection back-off executor
    // connection backOff
    // 17. 装饰者 -- 重试的间隔
    if (this.backoffManager != null && this.connectionBackoffStrategy != null) {
        execChain = new BackoffStrategyExec(execChain, this.connectionBackoffStrategy, this.backoffManager);
    }
    // 18. auth是的scheme 提供者
    Lookup<AuthSchemeProvider> authSchemeRegistryCopy = this.authSchemeRegistry;
    if (authSchemeRegistryCopy == null) {
        authSchemeRegistryCopy = RegistryBuilder.<AuthSchemeProvider>create()
            .register(AuthSchemes.BASIC, new BasicSchemeFactory())
            .register(AuthSchemes.DIGEST, new DigestSchemeFactory())
            .register(AuthSchemes.NTLM, new NTLMSchemeFactory())
            .register(AuthSchemes.SPNEGO, new SPNegoSchemeFactory())
            .register(AuthSchemes.KERBEROS, new KerberosSchemeFactory())
            .build();
    }
    // 19. cookie 相关
    Lookup<CookieSpecProvider> cookieSpecRegistryCopy = this.cookieSpecRegistry;
    if (cookieSpecRegistryCopy == null) {
        cookieSpecRegistryCopy = CookieSpecRegistries.createDefault(publicSuffixMatcherCopy);
    }
    // 20. cookie 的存储
    CookieStore defaultCookieStore = this.cookieStore;
    if (defaultCookieStore == null) {
        defaultCookieStore = new BasicCookieStore();
    }
    // 21. credential 提供者
    CredentialsProvider defaultCredentialsProvider = this.credentialsProvider;
    if (defaultCredentialsProvider == null) {
        if (systemProperties) {
            defaultCredentialsProvider = new SystemDefaultCredentialsProvider();
        } else {
            defaultCredentialsProvider = new BasicCredentialsProvider();
        }
    }
    // 22. 记录需要关闭的资源
    // 即记录那些需要关闭的资源,当httpClient关闭时,把记录额这些资源也同样关闭
    List<Closeable> closeablesCopy = closeables != null ? new ArrayList<Closeable>(closeables) : null;
    // 连接池 是否是共用的,如果是那么需要用户来进行管理,如果不是,则httpClient 来管理
    if (!this.connManagerShared) {
        if (closeablesCopy == null) {
            closeablesCopy = new ArrayList<Closeable>(1);
        }
        // 记录连接池
        final HttpClientConnectionManager cm = connManagerCopy;
        // 22.1 如果允许 关闭过期和idle超时的连接,则创建一个线程来关闭
        if (evictExpiredConnections || evictIdleConnections) {
            final IdleConnectionEvictor connectionEvictor = new IdleConnectionEvictor(cm,
                                                                                      maxIdleTime > 0 ? maxIdleTime : 10, maxIdleTimeUnit != null ? maxIdleTimeUnit : TimeUnit.SECONDS,
                                                                                      maxIdleTime, maxIdleTimeUnit);
            // 22.2 把此线程也记录下来,是需要关闭的资源
            closeablesCopy.add(new Closeable() {

                @Override
                public void close() throws IOException {
                    connectionEvictor.shutdown();
                    try {
                        connectionEvictor.awaitTermination(1L, TimeUnit.SECONDS);
                    } catch (final InterruptedException interrupted) {
                        Thread.currentThread().interrupt();
                    }
                }

            });
            // 线程开始
            connectionEvictor.start();
        }
        // 22.3 把线程池记录下来
        closeablesCopy.add(new Closeable() {

            @Override
            public void close() throws IOException {
                cm.shutdown();
            }

        });
    }
    // 23. 创建了 InternalHttpClient
    return new InternalHttpClient(
        execChain,
        connManagerCopy,
        routePlannerCopy,
        cookieSpecRegistryCopy,
        authSchemeRegistryCopy,
        defaultCookieStore,
        defaultCredentialsProvider,
        defaultRequestConfig != null ? defaultRequestConfig : RequestConfig.DEFAULT,
        closeablesCopy);
}
```

此函数比较长，做了很多的工作，也有很多可以去分析，小结一下这里的工作：

1. 如果没有设置，则创建尾缀匹配器---PublicSuffixMatcher
2.  如果没有设置执行器,则配置默认的执行器
3.  如果没有配置连接池,则也会配置一个
   1. 这里主要是 创建sslSocketFactory
   2.  获取配置的系统属性 (支持的https 协议,支持的 https 算法 )
   3.  设置主机名校验 方式
   4.  创建 SSLConnectionSocketFactory
   5.  创建连接池
   6.  属性以及设置的配置
4.  连接重用的策略
   1.  如果没有设置 连接重用的策略
   2.  如果使用系统属性,则判断是否设置http.keepAlive, 如果配置了http.keepAlive,则创建默认额 连接重用策略
   3.  如果不使用系统属性,则创建默认的连接重用策略
5.   如果没有设置,则配置一个默认的  keepAlive的策略
6.  目标机器的认证的策略
7.  代理机器的 认证策略
8.  useToken的处理
9.   userAgent的处理
10.  创建主要的执行器
11.  创建httpProcessor--- 这里的 httpProcessor保存了众多的 拦截器,用于对http协议的各种处理
    1.  先创建一个 builder 来创建 httpProcessor
    2.  如果设置了request的拦截器,则添加到 builder中
    3.  response的拦截器
    4.  添加各种拦截器
    5.  cookie 拦截器
    6.  允许的压缩类型 拦截器
    7.  认证缓存拦截器
    8.  cookie 管理
    9.   添加responseContent编码
    10.  request最后的一个 拦截器
    11.  response的最后一个拦截器
    12.  根据 添加的拦截器 创建个月 processor
12.  装饰者模式, 根据创建的Httpprocessor 来装饰具体的执行器,即在执行前和执行后,调用各种拦截器
13.  如果允许失败重试,则再次使用装饰者模式,对主要执行器进行包装,即catch异常,并进行重试
14.  router 计划者,用来解析route信息,其中就包含了代理
15.  装饰者, 服务不可用时的重试
16.  重定向的执行 -- 装饰者
17.  装饰者 -- 重试的间隔
18.  auth时的scheme 提供者
19.  cookie 相关
20.  cookie 的存储
21.  credential 提供者
22.  记录需要关闭的资源--即记录那些需要关闭的资源,当httpClient关闭时,把记录额这些资源也同样关闭
    1.  连接池 是否是共用的,如果是那么需要用户来进行管理,如果不是,则httpClient 来管理
    2.  如果允许 关闭过期和idle超时的连接,则创建一个线程来关闭
    3.  把此线程也记录下来,是需要关闭的资源
    4.  把连接池记录下来
23.  创建了 InternalHttpClient

可以看到此函数配置了许多的默认值，所以用户使用起来才比较简单，最终创建了InternalHttpClient，也就是请求执行时，是由此函数执行的。这里也使用了装饰者设计模式，故可以了解到httpClient重试机制，backoff机制等是通过装饰者模式实现的。

本篇创建就到此，下篇看一下具体的执行。





















































