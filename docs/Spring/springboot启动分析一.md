# springboot启动分析

今天从main方法入手，分析一下springboot的一个启动流程。

现面去启动的一个流程，当然其中做了好多事情，先说总流程，具体做的事情，后面会分开介绍各个功能。

## 启动流程

```java
// 入口main函数
@SpringBootApplication
public class StarterMain {
    public static void main(String[] args) {
        SpringApplication.run(StarterMain.class,args);
    }
}

// 静态run方法
public static ConfigurableApplicationContext run(Class<?> primarySource,
                                                 String... args) {
    return run(new Class<?>[] { primarySource }, args);
}

public static ConfigurableApplicationContext run(Class<?>[] primarySources,
                                                 String[] args) {
    // 创建SpringApplication并执行run方法
    return new SpringApplication(primarySources).run(args);
}
// 创构造函数
public SpringApplication(Class<?>... primarySources) {
    this(null, primarySources);
}
// 构造函数执行
public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
    this.resourceLoader = resourceLoader;
    Assert.notNull(primarySources, "PrimarySources must not be null");
    this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
    // 判断是否是web工厂
    this.webApplicationType = deduceWebApplicationType();
    // 设置ApplicationContextInitializer函数；
    // 也就是找到其实现类，会在后面根据顺序进行执行
    setInitializers((Collection) getSpringFactoriesInstances(
        ApplicationContextInitializer.class));
    // 设置Listener监听器
    // 也是获取ApplicationListener的实现类，并在后面会执行调用
    setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
    // 返回main函数
    this.mainApplicationClass = deduceMainApplicationClass();
}

public ConfigurableApplicationContext run(String... args) {
    // stopWatch一个监听作用
    StopWatch stopWatch = new StopWatch();
    stopWatch.start();
    ConfigurableApplicationContext context = null;
    Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
    // awt的配置
    configureHeadlessProperty();
    // 得到Listening，并执行onApplicationEvent方法
    SpringApplicationRunListeners listeners = getRunListeners(args);
    listeners.starting();
    try {
        // application参数
        ApplicationArguments applicationArguments = new DefaultApplicationArguments(
            args);
        // 准备环境变量
        ConfigurableEnvironment environment = prepareEnvironment(listeners,
                                                                 applicationArguments);
        // 设置要忽略的类
        configureIgnoreBeanInfo(environment);
        // 打印启动logog
        Banner printedBanner = printBanner(environment);
        // 创建applicaiton上下文
        context = createApplicationContext();
        // 得到错误报告类信息
        exceptionReporters = getSpringFactoriesInstances(
            SpringBootExceptionReporter.class,
            new Class[] { ConfigurableApplicationContext.class }, context);
        // 准备上下文
        prepareContext(context, environment, listeners, applicationArguments,
                       printedBanner);
        // 刷新上下文， 此函数执行完后，项目就已经启动起来了。因为servlet容器会创建完毕
        refreshContext(context);
        // 刷新之后的操作
        afterRefresh(context, applicationArguments);
        stopWatch.stop();
        if (this.logStartupInfo) {
            new StartupInfoLogger(this.mainApplicationClass)
                .logStarted(getApplicationLog(), stopWatch);
        }
        // 发布消息ApplicationStartEvent
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

### 那么是如何判断是否context是什么类型呢？

```java
# 一共有几种类型呢？
public enum WebApplicationType {
	/**
	 * The application should not run as a web application and should not start an
	 * embedded web server.
	 */
	NONE,
	/**
	 * The application should run as a servlet-based web application and should start an
	 * embedded servlet web server.
	 */
	SERVLET,
	/**
	 * The application should run as a reactive web application and should start an
	 * embedded reactive web server.
	 */
	REACTIVE
}

private static final String REACTIVE_WEB_ENVIRONMENT_CLASS = "org.springframework."
			+ "web.reactive.DispatcherHandler";
private static final String MVC_WEB_ENVIRONMENT_CLASS = "org.springframework."
			+ "web.servlet.DispatcherServlet";
private static final String JERSEY_WEB_ENVIRONMENT_CLASS = "org.glassfish.jersey.server.ResourceConfig";
private static final String[] WEB_ENVIRONMENT_CLASSES = { "javax.servlet.Servlet",
			"org.springframework.web.context.ConfigurableWebApplicationContext" };
// 是根据某些类是否存在来判断的； 具体的类如上所示
private WebApplicationType deduceWebApplicationType() {
		if (ClassUtils.isPresent(REACTIVE_WEB_ENVIRONMENT_CLASS, null)
				&& !ClassUtils.isPresent(MVC_WEB_ENVIRONMENT_CLASS, null)
				&& !ClassUtils.isPresent(JERSEY_WEB_ENVIRONMENT_CLASS, null)) {
			return WebApplicationType.REACTIVE;
		}
		for (String className : WEB_ENVIRONMENT_CLASSES) {
			if (!ClassUtils.isPresent(className, null)) {
				return WebApplicationType.NONE;
			}
		}
		return WebApplicationType.SERVLET;
	}
```

那来看一下具体的判断函数是如何来判断的把:

```java
	public static boolean isPresent(String className, @Nullable ClassLoader classLoader) {
		try {
            // 判断类是否存在，如果没有抛出错误，那么就是存在
			forName(className, classLoader);
			return true;
		}
		catch (Throwable ex) {
			// Class or one of its dependencies is not present...
			return false;
		}
	}

	public static Class<?> forName(String name, @Nullable ClassLoader classLoader)
			throws ClassNotFoundException, LinkageError {

		Assert.notNull(name, "Name must not be null");
		// 解析是否是原始类(基本数据类型，Integer，String等类型)
		Class<?> clazz = resolvePrimitiveClassName(name);
        // 如果不是，那么从缓存中查找
		if (clazz == null) {
			clazz = commonClassCache.get(name);
		}
        // 如果找到了，那么就直接返回
		if (clazz != null) {
			return clazz;
		}
		// 下面是三种具体的类型判断的标准，当前也是调用forName函数实现
		// "java.lang.String[]" style arrays
		if (name.endsWith(ARRAY_SUFFIX)) {
			String elementClassName = name.substring(0, name.length() - ARRAY_SUFFIX.length());
			Class<?> elementClass = forName(elementClassName, classLoader);
			return Array.newInstance(elementClass, 0).getClass();
		}

		// "[Ljava.lang.String;" style arrays
		if (name.startsWith(NON_PRIMITIVE_ARRAY_PREFIX) && name.endsWith(";")) {
			String elementName = name.substring(NON_PRIMITIVE_ARRAY_PREFIX.length(), name.length() - 1);
			Class<?> elementClass = forName(elementName, classLoader);
			return Array.newInstance(elementClass, 0).getClass();
		}

		// "[[I" or "[[Ljava.lang.String;" style arrays
		if (name.startsWith(INTERNAL_ARRAY_PREFIX)) {
			String elementName = name.substring(INTERNAL_ARRAY_PREFIX.length());
			Class<?> elementClass = forName(elementName, classLoader);
			return Array.newInstance(elementClass, 0).getClass();
		}

		ClassLoader clToUse = classLoader;
		if (clToUse == null) {
            // 获取默认加载器
			clToUse = getDefaultClassLoader();
		}
		try { // 再次查找并加载类
			return (clToUse != null ? clToUse.loadClass(name) : Class.forName(name));
		}
		catch (ClassNotFoundException ex) { // 如果没有找到类
			int lastDotIndex = name.lastIndexOf(PACKAGE_SEPARATOR);
			if (lastDotIndex != -1) {
				String innerClassName =
						name.substring(0, lastDotIndex) + INNER_CLASS_SEPARATOR + name.substring(lastDotIndex + 1);
				try {// 会尝试再次加载
					return (clToUse != null ? clToUse.loadClass(innerClassName) : Class.forName(innerClassName));
				}
				catch (ClassNotFoundException ex2) {
					// Swallow - let original exception get through
				}
			}
			throw ex; // 最终还没有找到，则抛出异常
		}
	}
```

那么这些数组以及基本类型是什么时候放到缓存的呢？

就是ClassUtil类加载时，在其静态代码块中初始化的.

```java
	/**
	 * Map with primitive wrapper type as key and corresponding primitive
	 * type as value, for example: Integer.class -> int.class.
	 */
	private static final Map<Class<?>, Class<?>> primitiveWrapperTypeMap = new IdentityHashMap<>(8);

	/**
	 * Map with primitive type as key and corresponding wrapper
	 * type as value, for example: int.class -> Integer.class.
	 */
	private static final Map<Class<?>, Class<?>> primitiveTypeToWrapperMap = new IdentityHashMap<>(8);

	/**
	 * Map with primitive type name as key and corresponding primitive
	 * type as value, for example: "int" -> "int.class".
	 */
	private static final Map<String, Class<?>> primitiveTypeNameMap = new HashMap<>(32);

	/**
	 * Map with common Java language class name as key and corresponding Class as value.
	 * Primarily for efficient deserialization of remote invocations.
	 */
	private static final Map<String, Class<?>> commonClassCache = new HashMap<>(64);

	/**
	 * Common Java language interfaces which are supposed to be ignored
	 * when searching for 'primary' user-level interfaces.
	 */
	private static final Set<Class<?>> javaLanguageInterfaces;
	static {
		primitiveWrapperTypeMap.put(Boolean.class, boolean.class);
		primitiveWrapperTypeMap.put(Byte.class, byte.class);
		primitiveWrapperTypeMap.put(Character.class, char.class);
		primitiveWrapperTypeMap.put(Double.class, double.class);
		primitiveWrapperTypeMap.put(Float.class, float.class);
		primitiveWrapperTypeMap.put(Integer.class, int.class);
		primitiveWrapperTypeMap.put(Long.class, long.class);
		primitiveWrapperTypeMap.put(Short.class, short.class);

		primitiveWrapperTypeMap.forEach((key, value) -> {
			primitiveTypeToWrapperMap.put(value, key);
			registerCommonClasses(key);
		});

		Set<Class<?>> primitiveTypes = new HashSet<>(32);
		primitiveTypes.addAll(primitiveWrapperTypeMap.values());
		Collections.addAll(primitiveTypes, boolean[].class, byte[].class, char[].class,
				double[].class, float[].class, int[].class, long[].class, short[].class);
		primitiveTypes.add(void.class);
		for (Class<?> primitiveType : primitiveTypes) {
			primitiveTypeNameMap.put(primitiveType.getName(), primitiveType);
		}

		registerCommonClasses(Boolean[].class, Byte[].class, Character[].class, Double[].class,
				Float[].class, Integer[].class, Long[].class, Short[].class);
		registerCommonClasses(Number.class, Number[].class, String.class, String[].class,
				Class.class, Class[].class, Object.class, Object[].class);
		registerCommonClasses(Throwable.class, Exception.class, RuntimeException.class,
				Error.class, StackTraceElement.class, StackTraceElement[].class);
		registerCommonClasses(Enum.class, Iterable.class, Iterator.class, Enumeration.class,
				Collection.class, List.class, Set.class, Map.class, Map.Entry.class, Optional.class);

		Class<?>[] javaLanguageInterfaceArray = {Serializable.class, Externalizable.class,
				Closeable.class, AutoCloseable.class, Cloneable.class, Comparable.class};
		registerCommonClasses(javaLanguageInterfaceArray);
		javaLanguageInterfaces = new HashSet<>(Arrays.asList(javaLanguageInterfaceArray));
	}
```

这篇就先说到这里，下一篇咱们说一下如何加载初始化类和加载监听器。