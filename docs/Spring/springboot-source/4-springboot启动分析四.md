# springboot启动分析四(环境准备)

上一篇整篇就分析了一个ApplicationStartingEvent事件的发布，以及相关的listener的调用处理。

那么这一篇接着来分析run方法剩下的操作。为了分析方便，来一个run方法的全貌：

```java
public ConfigurableApplicationContext run(String... args) {
    	// 时间的记录
		StopWatch stopWatch = new StopWatch();
		stopWatch.start();
		ConfigurableApplicationContext context = null;
		Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
		configureHeadlessProperty();
    	// 获取Runlistener，并且发布ApplicationStartingEvent时间，并调用相关的Listener进行处理
		SpringApplicationRunListeners listeners = getRunListeners(args);
		listeners.starting();
    	// 那，上一篇呢就分析到这里了
		try {
            // 咱们接着往下吧
            // 封装参数
			ApplicationArguments applicationArguments = new DefaultApplicationArguments(
					args);
            // 准备环境
			ConfigurableEnvironment environment = prepareEnvironment(listeners,
					applicationArguments);
            // 配置忽略的bean的信息
			configureIgnoreBeanInfo(environment);
            // 启动logo的打印
			Banner printedBanner = printBanner(environment);
			context = createApplicationContext();
			exceptionReporters = getSpringFactoriesInstances(
					SpringBootExceptionReporter.class,
					new Class[] { ConfigurableApplicationContext.class }, context);
			prepareContext(context, environment, listeners, applicationArguments,
					printedBanner);
			refreshContext(context);
			afterRefresh(context, applicationArguments);
			stopWatch.stop();
			if (this.logStartupInfo) {
				new StartupInfoLogger(this.mainApplicationClass)
						.logStarted(getApplicationLog(), stopWatch);
			}
			listeners.started(context);
			callRunners(context, applicationArguments);
		}
		catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, listeners);
			throw new IllegalStateException(ex);
		}

		try {
			listeners.running(context);
		}
		catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, null);
			throw new IllegalStateException(ex);
		}
		return context;
	}
```

先不注释那么多，分析到哪，咱们就注释带哪，省的看的迷糊。

## 看下封装参数是怎么封装的？

```java
	// 看见参数封装，会把命令行的参数也都封装进来。
	// 现在主要分析关于springboot的启动，命令行参数的具体封装细节，可以后面单开一篇进行解析，所以在这里就不深入分析了。
	public DefaultApplicationArguments(String[] args) {
		Assert.notNull(args, "Args must not be null");
		this.source = new Source(args);
		this.args = args;
	}

    Source(String[] args) {
        super(args);
    }

	public SimpleCommandLinePropertySource(String... args) {
		super(new SimpleCommandLineArgsParser().parse(args));
	}
```





## 那么环境准备，到底准备的什么环境呢?

```java
	private ConfigurableEnvironment prepareEnvironment(
			SpringApplicationRunListeners listeners,
			ApplicationArguments applicationArguments) {
		// Create and configure the environment
		ConfigurableEnvironment environment = getOrCreateEnvironment();
		configureEnvironment(environment, applicationArguments.getSourceArgs());
        // 发布ApplicationEnvironmentPreparedEvent事件，并调用相关的listener
		listeners.environmentPrepared(environment);
        // springApplication和enviroment的绑定操作
		bindToSpringApplication(environment);
        // 如果不是web项目，此才会执行
		if (this.webApplicationType == WebApplicationType.NONE) {
			environment = new EnvironmentConverter(getClassLoader())
					.convertToStandardEnvironmentIfNecessary(environment);
		}
        // 给enviroment添加一个ConfigurationPropertySources
		ConfigurationPropertySources.attach(environment);
		return environment;
	}
	// 创建一个enviroment
	private ConfigurableEnvironment getOrCreateEnvironment() {
		if (this.environment != null) {
			return this.environment;
		}
        // 因为此项目是servlet，故会执行这里，创建一个StandardServletEnviroment
		if (this.webApplicationType == WebApplicationType.SERVLET) {
			return new StandardServletEnvironment();
		}
		return new StandardEnvironment();
	}

	protected void configureEnvironment(ConfigurableEnvironment environment,
			String[] args) {
        // 配置属性源
		configurePropertySources(environment, args);
        // 配置active profile
		configureProfiles(environment, args);
	}

	protected void configurePropertySources(ConfigurableEnvironment environment,
			String[] args) {
		MutablePropertySources sources = environment.getPropertySources();
		if (this.defaultProperties != null && !this.defaultProperties.isEmpty()) {
			sources.addLast(
					new MapPropertySource("defaultProperties", this.defaultProperties));
		}
		// 命令行的设置
		if (this.addCommandLineProperties && args.length > 0) {
			String name = CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME;
			if (sources.contains(name)) {
				PropertySource<?> source = sources.get(name);
				CompositePropertySource composite = new CompositePropertySource(name);
				composite.addPropertySource(new SimpleCommandLinePropertySource(
						"springApplicationCommandLineArgs", args));
				composite.addPropertySource(source);
				sources.replace(name, composite);
			}
			else {
				sources.addFirst(new SimpleCommandLinePropertySource(args));
			}
		}
	}

	//  调用获取的所有的listener，执行其environmentPrepared函数
	public void environmentPrepared(ConfigurableEnvironment environment) {
		for (SpringApplicationRunListener listener : this.listeners) {
			listener.environmentPrepared(environment);
		}
	}
	// EventPublishingRunListener--环境准备
	public void environmentPrepared(ConfigurableEnvironment environment) {
        // 创建ApplicationEnvironmentPreparedEvent事件，并进行发布
		this.initialMulticaster.multicastEvent(new ApplicationEnvironmentPreparedEvent(
				this.application, this.args, environment));
	}
	// 好，咱们再看一下事件发布函数，温故知新嘛
	// 发布事件之前，先解析事件类型(也就是使用resolveDefaultEventType类再把事件包装一下)
	// 然后调用发布函数，进行事件的发布
	public void multicastEvent(ApplicationEvent event) {
		multicastEvent(event, resolveDefaultEventType(event));
	}
	// 这就是包装事件的方法了，具体可细看一下；当前了之前也有过分析的
	private ResolvableType resolveDefaultEventType(ApplicationEvent event) {
		return ResolvableType.forInstance(event);
	}
	// ok，这就是具体的发布事件咯
	public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
		ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
        // 得到所有的listener，并进行遍历操作
		for (final ApplicationListener<?> listener : getApplicationListeners(event, type)) {
			Executor executor = getTaskExecutor();
            // 如果有线程池呢，那么就在线程池中调用
			if (executor != null) {
				executor.execute(() -> invokeListener(listener, event));
			}
			else {
                // 直接调用
				invokeListener(listener, event);
			}
		}
	}
	// 调用listener
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
	// 调用listener的onApplicationEvent的函数
	private void doInvokeListener(ApplicationListener listener, ApplicationEvent event) {
		try {
			listener.onApplicationEvent(event);
		}
		catch (ClassCastException ex) {
			String msg = ex.getMessage();
			if (msg == null || matchesClassCastMessage(msg, event.getClass().getName())) {
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
	// 当然了，不同的listener完成不同的功能，其具体实现也会不一样，这里分析一下ConfigFileApplicationListener的函数
	public void onApplicationEvent(ApplicationEvent event) {
        // 对于ApplicationEnvironmentPreparedEvent事件的处理
		if (event instanceof ApplicationEnvironmentPreparedEvent) {
			onApplicationEnvironmentPreparedEvent(
					(ApplicationEnvironmentPreparedEvent) event);
		}
		if (event instanceof ApplicationPreparedEvent) {
			onApplicationPreparedEvent(event);
		}
	}
    // 那对于这个事件是怎么处理的呢？
    // 还是的看一下处理函数
	private void onApplicationEnvironmentPreparedEvent(
			ApplicationEnvironmentPreparedEvent event) {
        // 获取后置处理器
		List<EnvironmentPostProcessor> postProcessors = loadPostProcessors();
		postProcessors.add(this);
		AnnotationAwareOrderComparator.sort(postProcessors);
        // 调用每个后置处理器的postProcessEnvironment函数，分别对enviroment进行处理
		for (EnvironmentPostProcessor postProcessor : postProcessors) {
			postProcessor.postProcessEnvironment(event.getEnvironment(),
					event.getSpringApplication());
		}
	}
	// 那么又是如何加载的后置处理器呢？
	// 调用loadFactories方法加载EnvironmentPostProcessor接口类的实现类
	// 那么到这里是否感觉熟悉呢?
	List<EnvironmentPostProcessor> loadPostProcessors() {
		return SpringFactoriesLoader.loadFactories(EnvironmentPostProcessor.class,
				getClass().getClassLoader());
	}
	//如果上面没有的话，那这里肯定会很熟悉啦。
	// 没错。就是从spring.factories中加载具体的类，并进行实例化的
	public static <T> List<T> loadFactories(Class<T> factoryClass, @Nullable ClassLoader classLoader) {
		Assert.notNull(factoryClass, "'factoryClass' must not be null");
		ClassLoader classLoaderToUse = classLoader;
		if (classLoaderToUse == null) {
			classLoaderToUse = SpringFactoriesLoader.class.getClassLoader();
		}
        // 这里，对就是这里，获取到类的全限定名的
		List<String> factoryNames = loadFactoryNames(factoryClass, classLoaderToUse);
		if (logger.isTraceEnabled()) {
			logger.trace("Loaded [" + factoryClass.getName() + "] names: " + factoryNames);
		}
		List<T> result = new ArrayList<>(factoryNames.size());
		for (String factoryName : factoryNames) {
			result.add(instantiateFactory(factoryName, factoryClass, classLoaderToUse));
		}
		AnnotationAwareOrderComparator.sort(result);
		return result;
	}
	// 那这就是实例化的函数了，都到这里了，是吧，那就憋不住看一眼把，就一眼。
    private static <T> T instantiateFactory(String instanceClassName, Class<T> factoryClass, ClassLoader classLoader) {
        try {
            // 判断对应的类是否加载
            Class<?> instanceClass = ClassUtils.forName(instanceClassName, classLoader);
            if (!factoryClass.isAssignableFrom(instanceClass)) {
                throw new IllegalArgumentException(
                    "Class [" + instanceClassName + "] is not assignable to [" + factoryClass.getName() + "]");
            }
            // 反射调用相应的构造函数进行实例化。嗯，豁然开朗了把。
            return (T) ReflectionUtils.accessibleConstructor(instanceClass).newInstance();
        }
        catch (Throwable ex) {
            throw new IllegalArgumentException("Unable to instantiate factory class: " + factoryClass.getName(), ex);
        }
    }
```

对，你说的没错，咱们这里是去分析启动流程的，知道在启动流程中有哪些启动步骤，是吧。

那么具体的后置处理器对enviroment做了什么，咱们先放放，先撩清其中的骨干，具体的神经末梢(实现细节)咱们分篇具体分析。

在这里，就知道调用了后置函数去偷摸对enviroment做了一些人们看不到的事(回头分析了就看到了)，知道这个就可以了。接着看prepareEnvironment还做了什么呢?

**嗯，这里还不是很清楚做的动作的影响，就先不进行分析，免得误导大家。当然了大家也可以告诉你的分析。**

```java
bindToSpringApplication(environment);
```

```java
	// 给enviroment添加一个ConfigurationPropertySourcesPropertySource
	public static void attach(Environment environment) {
		Assert.isInstanceOf(ConfigurableEnvironment.class, environment);
		MutablePropertySources sources = ((ConfigurableEnvironment) environment)
				.getPropertySources();
		PropertySource<?> attached = sources.get(ATTACHED_PROPERTY_SOURCE_NAME);
		if (attached != null && attached.getSource() != sources) {
			sources.remove(ATTACHED_PROPERTY_SOURCE_NAME);
			attached = null;
		}
		if (attached == null) {// 在集合的第一个位置添加ConfigurationPropertySourcesPropertySource
			sources.addFirst(new ConfigurationPropertySourcesPropertySource(
					ATTACHED_PROPERTY_SOURCE_NAME,
					new SpringConfigurationPropertySources(sources)));
		}
	}
```

## 设置要忽略的bean的信息

```java
	private void configureIgnoreBeanInfo(ConfigurableEnvironment environment) {
        // 也就是设置此系统属性
        // CachedIntrospectionResults.IGNORE_BEANINFO_PROPERTY_NAME
		if (System.getProperty(
				CachedIntrospectionResults.IGNORE_BEANINFO_PROPERTY_NAME) == null) {
			Boolean ignore = environment.getProperty("spring.beaninfo.ignore",
					Boolean.class, Boolean.TRUE);
			System.setProperty(CachedIntrospectionResults.IGNORE_BEANINFO_PROPERTY_NAME,
					ignore.toString());
		}
	}
```



## 启动logo如何打印的呢？

```java
	// 打印系统启动logo
	private Banner printBanner(ConfigurableEnvironment environment) {
        // 如果设置了不打印， 则直接返回，不进行打印
		if (this.bannerMode == Banner.Mode.OFF) {
			return null;
		}
        // 否则就会在家资源进行打印操作
        // 获取资源加载器
		ResourceLoader resourceLoader = (this.resourceLoader != null)
				? this.resourceLoader : new DefaultResourceLoader(getClassLoader());
        // 创建一个SpringApplicationBannerPrinter
		SpringApplicationBannerPrinter bannerPrinter = new SpringApplicationBannerPrinter(
				resourceLoader, this.banner);
        // 模式是否是LOG
		if (this.bannerMode == Mode.LOG) {
			return bannerPrinter.print(environment, this.mainApplicationClass, logger);
		}
        // 打印
		return bannerPrinter.print(environment, this.mainApplicationClass, System.out);
	}
	SpringApplicationBannerPrinter(ResourceLoader resourceLoader, Banner fallbackBanner) {
		this.resourceLoader = resourceLoader;
		this.fallbackBanner = fallbackBanner;
	}
	// 打印
	public Banner print(Environment environment, Class<?> sourceClass, PrintStream out) {
        // 从enviroment中获取banner(如果用户自定义了，那么就会起作用)
		Banner banner = getBanner(environment);
		banner.printBanner(environment, sourceClass, out);
		return new PrintedBanner(banner, sourceClass);
	}

	private Banner getBanner(Environment environment) {
		Banners banners = new Banners();
        // 添加image格式的banner
		banners.addIfNotNull(getImageBanner(environment));
        // 添加text格式的banner
		banners.addIfNotNull(getTextBanner(environment));
        // 如果存在的话，直接返回
		if (banners.hasAtLeastOneBanner()) {
			return banners;
		}
		if (this.fallbackBanner != null) {
			return this.fallbackBanner;
		}
        // 否则，返回默认的banner
		return DEFAULT_BANNER;
	}
	// 打印banner，其实也就是打印字符串
	public void printBanner(Environment environment, Class<?> sourceClass,
			PrintStream printStream) {
        // 打印默认的banner
		for (String line : BANNER) {
			printStream.println(line);
		}
		String version = SpringBootVersion.getVersion();
		version = (version != null) ? " (v" + version + ")" : "";
		StringBuilder padding = new StringBuilder();
		while (padding.length() < STRAP_LINE_SIZE
				- (version.length() + SPRING_BOOT.length())) {
			padding.append(" ");
		}

		printStream.println(AnsiOutput.toString(AnsiColor.GREEN, SPRING_BOOT,
				AnsiColor.DEFAULT, padding.toString(), AnsiStyle.FAINT, version));
		printStream.println();
	}
```

默认的BANNER内容:

```java
private static final String[] BANNER = { "",
			"  .   ____          _            __ _ _",
			" /\\\\ / ___'_ __ _ _(_)_ __  __ _ \\ \\ \\ \\",
			"( ( )\\___ | '_ | '_| | '_ \\/ _` | \\ \\ \\ \\",
			" \\\\/  ___)| |_)| | | | | || (_| |  ) ) ) )",
			"  '  |____| .__|_| |_|_| |_\\__, | / / / /",
			" =========|_|==============|___/=/_/_/_/" };
```

好了，今天就先分析到这里

再来回顾一下，系统启动到这里，做了什么：

1. 封装参数，参数可以来源与命令行等方式
2. 准备enviroment
   1. 先把相关的命令行参数封装到environment
   2. 发布ApplicationEnvironmentPreparedEvent事件，调用相关的listener进行处理
   3. 加载相关的EnvironmentPostProcessor实现类，依次对environment进行操作
   4. 注册相关的要忽略的类的信息
3. 到这里呢，environment就准备好
4. 打印启动logo