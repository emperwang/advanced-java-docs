# springboot启动分析三(调用listener处理ApplicationStartingEvent事件)

那今天可以看一下run方法是如何把项目启动起来的。不过run方法做的工作比较多，咱们分开步骤慢慢分析。

先看一下run方法全貌把:

```java
public ConfigurableApplicationContext run(String... args) {
    	// stopWatch一个监听器，springboot每次启动最后的启动使用了多长时间，就是这个stopWatch实现的
		StopWatch stopWatch = new StopWatch();
		stopWatch.start();
    	// context，springboot上下文
		ConfigurableApplicationContext context = null;
    	// 错误报告函数
		Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
    	// awt配置（先不分析awt，先知道这里就好）
		configureHeadlessProperty();
        // 得到Listening，并执行onApplicationEvent方法
		SpringApplicationRunListeners listeners = getRunListeners(args);
		listeners.starting();
		try {
            // 参数，也是main函数传递进来的
			ApplicationArguments applicationArguments = new DefaultApplicationArguments(
					args);
            // 准备环境
			ConfigurableEnvironment environment = prepareEnvironment(listeners,
					applicationArguments);
            // 配置忽略的bean
			configureIgnoreBeanInfo(environment);
            // 打印banner，也就是启动时候的那个logo
			Banner printedBanner = printBanner(environment);
            // 创建applicationContext
			context = createApplicationContext();
            // 获取异常报告类的实例
			exceptionReporters = getSpringFactoriesInstances(
					SpringBootExceptionReporter.class,
					new Class[] { ConfigurableApplicationContext.class }, context);
            // 准备context
			prepareContext(context, environment, listeners, applicationArguments,
					printedBanner);
            // 刷新context
			refreshContext(context);
            // 刷新完context之后做的操作
			afterRefresh(context, applicationArguments);
            // stopWatch停止
			stopWatch.stop();
            // 此操作，就是打印最后的项目启动时间
			if (this.logStartupInfo) {
				new StartupInfoLogger(this.mainApplicationClass)
						.logStarted(getApplicationLog(), stopWatch);
			}
            // 监听器启动
			listeners.started(context);
            // 运行ApplicationRunner和CommandLineRunner
			callRunners(context, applicationArguments);
		}
		catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, listeners);
			throw new IllegalStateException(ex);
		}

		try {
            // 发布ApplicationReadyEvent消息
			listeners.running(context);
		}
		catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, null);
			throw new IllegalStateException(ex);
		}
		return context;
	}
```

好了，大概流程如上所示了，那么咱们就按部就班的来层层拨开把。

## 启动时间记录

既然时间记录先调用，那就先看一下项目启动时间的记录吧:

```java
	// 无参构造函数
	public StopWatch() {
		this("");
	}
	public StopWatch(String id) {
		this.id = id;
	}
	// 启动stopWatch
	public void start() throws IllegalStateException {
		start("");
	}
	// 记录两个信息，当前task的名字和当前时间
	public void start(String taskName) throws IllegalStateException {
		if (this.currentTaskName != null) {
			throw new IllegalStateException("Can't start StopWatch: it's already running");
		}
		this.currentTaskName = taskName;
		this.startTimeMillis = System.currentTimeMillis();
	}
	// 记录一个启动消耗的时间，并清空task名字
	public void stop() throws IllegalStateException {
		if (this.currentTaskName == null) {
			throw new IllegalStateException("Can't stop StopWatch: it's not running");
		}
        // 项目启动时间
		long lastTime = System.currentTimeMillis() - this.startTimeMillis;
        // 记录总时间
		this.totalTimeMillis += lastTime;
		this.lastTaskInfo = new TaskInfo(this.currentTaskName, lastTime);
		if (this.keepTaskList) {
			this.taskList.add(this.lastTaskInfo);
		}
		++this.taskCount;
        // 清空当前的taskName
		this.currentTaskName = null;
	}
```

功能比较清晰了，项目启动时，记录一个开始时间，项目结束时得到一个结束时的时间，两个时间相减，得到一个启动时间。

## 接下来看一下第一次得到Listening，要listening做什么呢？

```java
// 得到SpringApplicationRunListener的实现类的实例
private SpringApplicationRunListeners getRunListeners(String[] args) {
    Class<?>[] types = new Class<?>[] { SpringApplication.class, String[].class };
    return new SpringApplicationRunListeners(logger, getSpringFactoriesInstances(
        SpringApplicationRunListener.class, types, this, args));
}
// 如何得到呢？
// 就是通过此函数了。是不是似曾相识的感觉呢？对的，初始化函数的监听器也是通过此函数去得到的嘛。
// 如果忘了，就看看上一篇吧。当然了，在好好看看本篇的注释也是可以的。
private <T> Collection<T> getSpringFactoriesInstances(Class<T> type,
                                                      Class<?>[] parameterTypes, Object... args) {
    ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
    // 这里就是关键点了
    // SpringFactoriesLoader.loadFactoryNames此函数就是得到实现类的全限定名集合
    Set<String> names = new LinkedHashSet<>(
        SpringFactoriesLoader.loadFactoryNames(type, classLoader));
    // 这里就是通过限定名集合去得到具体类的实例
    List<T> instances = createSpringFactoriesInstances(type, parameterTypes,
                                                       classLoader, args, names);
    // 排个序
    AnnotationAwareOrderComparator.sort(instances);
    // 返回创建好的实例了。
    return instances;
}
// 那这里就是获取限定名的函数了
public static List<String> loadFactoryNames(Class<?> factoryClass, @Nullable ClassLoader classLoader) {
    String factoryClassName = factoryClass.getName();
    return loadSpringFactories(classLoader).getOrDefault(factoryClassName, Collections.emptyList());
}
// 这里就是从jar包中的spring.factories中得到key-value值(此时是不是有印象了呢？是的，没错，你想的对，就是spring.factories文件记录了有哪些实现类，并且key就是接口名，也是参数type的值),这里的value呢，就是实现类的限定名的集合
private static Map<String, List<String>> loadSpringFactories(@Nullable ClassLoader classLoader) {
    // 当前了，如果之前加载过，缓存中会有
    MultiValueMap<String, String> result = cache.get(classLoader);
    if (result != null) {
        return result;
    }

    try {
        // 如果第一次调用呢，就再次从文件中读取其内容
        Enumeration<URL> urls = (classLoader != null ?
                                 classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
                                 ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
        result = new LinkedMultiValueMap<>();
        while (urls.hasMoreElements()) {
            URL url = urls.nextElement();
            UrlResource resource = new UrlResource(url);
            Properties properties = PropertiesLoaderUtils.loadProperties(resource);
            for (Map.Entry<?, ?> entry : properties.entrySet()) {
                List<String> factoryClassNames = Arrays.asList(
                    StringUtils.commaDelimitedListToStringArray((String) entry.getValue()));
                result.addAll((String) entry.getKey(), factoryClassNames);
            }
        }
        // 读取完了，存入缓存中，留待下次查找使用。
        cache.put(classLoader, result);
        return result;
    }
    catch (IOException ex) {
        throw new IllegalArgumentException("Unable to load factories from location [" +
                                           FACTORIES_RESOURCE_LOCATION + "]", ex);
    }
}
	// 得到了限定名集合，肯定就是要通过反射区得到其实例对象了
	// 实现方法呢，就是此函数了
	private <T> List<T> createSpringFactoriesInstances(Class<T> type,
			Class<?>[] parameterTypes, ClassLoader classLoader, Object[] args,
			Set<String> names) {
		List<T> instances = new ArrayList<>(names.size());
		for (String name : names) {
			try {
                // 先看一下类是否加载
				Class<?> instanceClass = ClassUtils.forName(name, classLoader);
				Assert.isAssignable(type, instanceClass);
                // 加载了呢，就获取其构造器函数
				Constructor<?> constructor = instanceClass
						.getDeclaredConstructor(parameterTypes);
                // 然后实例化其对象
				T instance = (T) BeanUtils.instantiateClass(constructor, args);
				instances.add(instance);
			}
			catch (Throwable ex) {
				throw new IllegalArgumentException(
						"Cannot instantiate " + type + " : " + name, ex);
			}
		}
        // 最后呢，返回实例化的对象
		return instances;
	}
```

这里呢即是获取SpringApplicationRunListener的实现类的实例化对象的；其实现类呢，记录在spring.factories文件中，使用的是key-value结构(打开看一下就特别清除了，你会发现，这不就是properties形式吗。对的，就是这种形式).

## 那实例化了Listening类，要干什么呢？

此时就得到了所有的SpringApplicationRunListener的对象，要干什么呢？干什么呢？嗯，答案当前在代码中了。一起看一下吧.

```java
	// 调用一个starting函数，到底是启动什么呢？
	listeners.starting();
	// 哦，原来是循环调用所有得到的SpringApplicationRunListener实现类的starting方法
	public void starting() {
		for (SpringApplicationRunListener listener : this.listeners) {
			listener.starting();
		}
	}
	// 看一下EventPublishingRunListener类中的starting函数
	// 这里的操作是发布一个ApplicationStartingEvent的事件，表示项目准备启动了
	public void starting() {// initialMulticaster是SimpleApplicationEventMulticaster
		this.initialMulticaster.multicastEvent(
				new ApplicationStartingEvent(this.application, this.args));
	}
// 这里的发布函数，又是如何告诉其他的listener的呢？
	// 看一下这个发布事件函数
    public void multicastEvent(ApplicationEvent event) {
        multicastEvent(event, resolveDefaultEventType(event));
    }
	// 首先呢，要解析事件类型
	private ResolvableType resolveDefaultEventType(ApplicationEvent event) {
		return ResolvableType.forInstance(event);
	}
	// 这里的操作呢，就是使用类ResolvableType吧事件类型的class包装了一下，成为了一个ResolvableType类型
	public static ResolvableType forInstance(Object instance) {
		Assert.notNull(instance, "Instance must not be null");
		if (instance instanceof ResolvableTypeProvider) {
			ResolvableType type = ((ResolvableTypeProvider) instance).getResolvableType();
			if (type != null) {
				return type;
			}
		}
		return ResolvableType.forClass(instance.getClass());
	}

	public static ResolvableType forClass(@Nullable Class<?> clazz) {
		return new ResolvableType(clazz);
	}
	private ResolvableType(@Nullable Class<?> clazz) {
		this.resolved = (clazz != null ? clazz : Object.class);
		this.type = this.resolved;
		this.typeProvider = null;
		this.variableResolver = null;
		this.componentType = null;
		this.hash = null;
	}
	// 发布事件	
	public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
		ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
        // 遍历所有的listener
		for (final ApplicationListener<?> listener : getApplicationListeners(event, type)) {
            // 如果线程池不为空，则在线程池中执行listener
			Executor executor = getTaskExecutor();
			if (executor != null) {
				executor.execute(() -> invokeListener(listener, event));
			}
			else {
                // 否则直接调用listener
				invokeListener(listener, event);
			}
		}
	}
// 那么是如何获取到所有的Listener的呢？ 

protected Collection<ApplicationListener<?>> getApplicationListeners(
    ApplicationEvent event, ResolvableType eventType) {
    Object source = event.getSource();
    // 获取事件源的类型
    Class<?> sourceType = (source != null ? source.getClass() : null);
    // 创建缓存
    ListenerCacheKey cacheKey = new ListenerCacheKey(eventType, sourceType);

    // 这是仍是一个缓存
    ListenerRetriever retriever = this.retrieverCache.get(cacheKey);
    if (retriever != null) {
        return retriever.getApplicationListeners();
    }

    if (this.beanClassLoader == null ||
        (ClassUtils.isCacheSafe(event.getClass(), this.beanClassLoader) &&
         (sourceType == null || ClassUtils.isCacheSafe(sourceType, this.beanClassLoader)))) {
        // Fully synchronized building and caching of a ListenerRetriever
        synchronized (this.retrievalMutex) {
            // 通过创建的catchKey获取listener
            retriever = this.retrieverCache.get(cacheKey);
            if (retriever != null) {
                return retriever.getApplicationListeners();
            }
            // 如果是第一次进入，则需要初始化
            retriever = new ListenerRetriever(true);
            // 获取listener
            Collection<ApplicationListener<?>> listeners =
                retrieveApplicationListeners(eventType, sourceType, retriever);
            // 放入缓存
            this.retrieverCache.put(cacheKey, retriever);
            // 返回得到的listener
            return listeners;
        }
    }
    else {
        // No ListenerRetriever caching -> no synchronization necessary
        return retrieveApplicationListeners(eventType, sourceType, null);
    }
}
// 获取listener
private Collection<ApplicationListener<?>> retrieveApplicationListeners(
    ResolvableType eventType, @Nullable Class<?> sourceType, @Nullable ListenerRetriever retriever) {
	// 存放所有listener的容器
    List<ApplicationListener<?>> allListeners = new ArrayList<>();
    Set<ApplicationListener<?>> listeners;
    Set<String> listenerBeans;
    synchronized (this.retrievalMutex) {
        listeners = new LinkedHashSet<>(this.defaultRetriever.applicationListeners);
        listenerBeans = new LinkedHashSet<>(this.defaultRetriever.applicationListenerBeans);
    }
    // 遍历锁得到的listener，并查看listener是否支持eventType和sourceType
    // 支持则放入到容器中
    for (ApplicationListener<?> listener : listeners) {
        if (supportsEvent(listener, eventType, sourceType)) {
            if (retriever != null) {
                retriever.applicationListeners.add(listener);
            }
            allListeners.add(listener);
        }
    }
    if (!listenerBeans.isEmpty()) {
        BeanFactory beanFactory = getBeanFactory();
        // 遍历beanName，并从beanFactory中获取bean的实例
        // 并且如果实例支持对应的事件类型，则加入到allListeners容器中
        for (String listenerBeanName : listenerBeans) {
            try {
                // 从benaFactory中获取bean实例
                Class<?> listenerType = beanFactory.getType(listenerBeanName);
                if (listenerType == null || supportsEvent(listenerType, eventType)) {
                    // 不为空，且支持事件类型，则得到bean实例
                    ApplicationListener<?> listener =
                        beanFactory.getBean(listenerBeanName, ApplicationListener.class);
                    if (!allListeners.contains(listener) && supportsEvent(listener, eventType, sourceType)) {
                        if (retriever != null) { // retriever不为null，则保存一下
                            retriever.applicationListenerBeans.add(listenerBeanName);
                        }
                        // 加入到容器中
                        allListeners.add(listener);
                    }
                }
            }
            catch (NoSuchBeanDefinitionException ex) {
                // Singleton listener instance (without backing bean definition) disappeared -
                // probably in the middle of the destruction phase
            }
        }
    }
    // 给listener排个序，然后返回
    AnnotationAwareOrderComparator.sort(allListeners);
    return allListeners;
}

// 那又是如何调用所有的listener的呢？
// 调用具体的listener，并传递其event事件
protected void invokeListener(ApplicationListener<?> listener, ApplicationEvent event) {
    ErrorHandler errorHandler = getErrorHandler();
    if (errorHandler != null) {
        try {
            doInvokeListener(listener, event);
        }
        catch (Throwable err) {
            errorHandler.handleError(err);
        }
    }
    else {
        doInvokeListener(listener, event);
    }
}
// 调用Listener的函数
private void doInvokeListener(ApplicationListener listener, ApplicationEvent event) {
    try {
        // 此时是调用listener的onApplicationEvent函数
        listener.onApplicationEvent(event);
    }
    catch (ClassCastException ex) {
        String msg = ex.getMessage();
        if (msg == null || matchesClassCastMessage(msg, event.getClass().getName())) {
            // Possibly a lambda-defined listener which we could not resolve the generic event type for
            // -> let's suppress the exception and just log a debug message.
            Log logger = LogFactory.getLog(getClass());
            if (logger.isDebugEnabled()) {
                logger.debug("Non-matching event type for listener: " + listener, ex);
            }
        }
        else {
            throw ex;
        }
    }
}
// 因为不同的listener的具体实现可能不一样，这里看一下LoggingApplicationListener的实现
public void onApplicationEvent(ApplicationEvent event) {
    	// 判断事件的类型，来调用不同的事件处理
   		// 因为此时的事件类型是ApplicationStartingEvent，所以会执行这里
		if (event instanceof ApplicationStartingEvent) {
			onApplicationStartingEvent((ApplicationStartingEvent) event);
		}
		else if (event instanceof ApplicationEnvironmentPreparedEvent) {
			onApplicationEnvironmentPreparedEvent(
					(ApplicationEnvironmentPreparedEvent) event);
		}
		else if (event instanceof ApplicationPreparedEvent) {
			onApplicationPreparedEvent((ApplicationPreparedEvent) event);
		}
		else if (event instanceof ContextClosedEvent && ((ContextClosedEvent) event)
				.getApplicationContext().getParent() == null) {
			onContextClosedEvent();
		}
		else if (event instanceof ApplicationFailedEvent) {
			onApplicationFailedEvent();
		}
	}
	//	ApplicationStartingEvent事件的处理
	private void onApplicationStartingEvent(ApplicationStartingEvent event) {
		this.loggingSystem = LoggingSystem
				.get(event.getSpringApplication().getClassLoader());
		this.loggingSystem.beforeInitialize();
	}
	// 初始化前的一些操作
	public void beforeInitialize() {
		LoggerContext loggerContext = getLoggerContext();
		if (isAlreadyInitialized(loggerContext)) {
			return;
		}
		super.beforeInitialize();
		loggerContext.getTurboFilterList().add(FILTER);
	}

```

可以看出来在run函数中的两个方法调用，就分析了这么多，可见越是看起来简单，分析起来就越是封装的紧密。

那么这里就是调用所有的listener处理ApplicationStartingEvent事件。

处理过程：

1. 获取到所有的SpringApplicationRunListener
2. 发布消息ApplicationStartingEvent
3. 获取到所有的listener
4. 遍历listener，如果listener支持此信息，则进行相应的处理



