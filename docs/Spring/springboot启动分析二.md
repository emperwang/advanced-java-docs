# spring启动分析二(实例化初始化类和监听器)

根据上文，再创建SpringApplication时会加载初始化类和监听器，再看一下相关代码:

```java
	public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
		this.resourceLoader = resourceLoader;
		Assert.notNull(primarySources, "PrimarySources must not be null");
		this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
         // 判断是什么类型的applicationContext
		this.webApplicationType = deduceWebApplicationType();
        // 记载初始化类； 重点就看这里
		setInitializers((Collection) getSpringFactoriesInstances(
				ApplicationContextInitializer.class));
        // 加载监听器；重点就是这个函数
		setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
		this.mainApplicationClass = deduceMainApplicationClass();
	}
```

## 那么这个设置初始化类的方法是如何加载初始化类的呢？

```java
    // 创建一个容器ArrayList保存初始化类的实例
	public void setInitializers(
        Collection<? extends ApplicationContextInitializer<?>> initializers) {
        this.initializers = new ArrayList<>();
        this.initializers.addAll(initializers);
    }
	// 获取初始化类的方法
	private <T> Collection<T> getSpringFactoriesInstances(Class<T> type) {
		return getSpringFactoriesInstances(type, new Class<?>[] {});
	}

	private <T> Collection<T> getSpringFactoriesInstances(Class<T> type,
			Class<?>[] parameterTypes, Object... args) {
        // 获取类加载器
		ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
		// 获取要加载的类的全类名
		Set<String> names = new LinkedHashSet<>(
				SpringFactoriesLoader.loadFactoryNames(type, classLoader));
        // 实例化
		List<T> instances = createSpringFactoriesInstances(type, parameterTypes,
				classLoader, args, names);
        // 排序
		AnnotationAwareOrderComparator.sort(instances);
		return instances;
	}

	public static List<String> loadFactoryNames(Class<?> factoryClass, @Nullable ClassLoader classLoader) {
		String factoryClassName = factoryClass.getName();
		return loadSpringFactories(classLoader).getOrDefault(factoryClassName, Collections.emptyList());
	}
	// 要加载的资源的名字,也就是要加载的类的名字写在这个文件中
	public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories";
	// 把在spring.factories的内容，按照key-value结构读取到一个map容器中
	private static Map<String, List<String>> loadSpringFactories(@Nullable ClassLoader classLoader) {
        // 先从缓存中获取，如果缓存为空，则从文件中读取
		MultiValueMap<String, String> result = cache.get(classLoader);
		if (result != null) {
			return result;
		}

		try {
            // 读取各个jar中的文件的路径
			Enumeration<URL> urls = (classLoader != null ?
					classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
					ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
            // 存放最后结果的容器
			result = new LinkedMultiValueMap<>();
            // 循环读取各个spring.factories文件中的key-value结构
			while (urls.hasMoreElements()) {
				URL url = urls.nextElement();
				UrlResource resource = new UrlResource(url);
                // key-value结构，key为类名字，value为需要实例化的具体类全类名
				Properties properties = PropertiesLoaderUtils.loadProperties(resource);
				for (Map.Entry<?, ?> entry : properties.entrySet()) {
                    // 把value的值转换为一个list，因为value可能是有多个
					List<String> factoryClassNames = Arrays.asList(
							StringUtils.commaDelimitedListToStringArray((String) entry.getValue()));
                    // 把结果放到一个map中
					result.addAll((String) entry.getKey(), factoryClassNames);
				}
			}
            // 也放到缓存中一份
			cache.put(classLoader, result);
			return result;
		}
		catch (IOException ex) {
			throw new IllegalArgumentException("Unable to load factories from location [" +
					FACTORIES_RESOURCE_LOCATION + "]", ex);
		}
	}
	// 返回spring.factories文件中的指定key(key一般为某种类型的接口类，如监听器ApplicationListener)的对应的要加载的实现类的list集合
    default V getOrDefault(Object key, V defaultValue) {
        V v;
        return (((v = get(key)) != null) || containsKey(key))
            ? v
            : defaultValue;
    }
```

到这里，函数执行完毕，spring.factories文件中的内容，就被全部读取到一个map集合中,并通过getOrDefault方法获取指定的接口的要加载的实现类的list集合。

看一下这个spring.factories的内容: （部分内容）

```java
# Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.autoconfigure.SharedMetadataReaderFactoryContextInitializer,\
org.springframework.boot.autoconfigure.logging.ConditionEvaluationReportLoggingListener

# Application Listeners
org.springframework.context.ApplicationListener=\
org.springframework.boot.autoconfigure.BackgroundPreinitializer

# Auto Configuration Import Listeners
org.springframework.boot.autoconfigure.AutoConfigurationImportListener=\
org.springframework.boot.autoconfigure.condition.ConditionEvaluationReportAutoConfigurationImportListener

# Auto Configuration Import Filters
org.springframework.boot.autoconfigure.AutoConfigurationImportFilter=\
org.springframework.boot.autoconfigure.condition.OnClassCondition

# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration,\
org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration,\
org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration,\
......
```

### 得到的某种接口的实现类的list集合，接下来要如何做呢？

得到了类的全类名，接下来如何操作呢？想想看，平时使用类都是使用其实例方法，所以得到系限定名，接下来一般会通过反射或其他方法创建实例，接下来才能进行初始化或其他操作，否则得到的限定名，也就没什么大的用处了，你说是吧。

那咱就来看看，是不是如刚才猜测一样。

```java
	private <T> Collection<T> getSpringFactoriesInstances(Class<T> type,
			Class<?>[] parameterTypes, Object... args) {
		ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
		// 在这里得到了接口的实现类的限定名集合
        Set<String> names = new LinkedHashSet<>(
				SpringFactoriesLoader.loadFactoryNames(type, classLoader));
        // 接下来就是执行这里。那就看看你做了什么把。
		List<T> instances = createSpringFactoriesInstances(type, parameterTypes,
				classLoader, args, names);
		AnnotationAwareOrderComparator.sort(instances);
		return instances;
	}
	// 看名字是创建spring工厂实例；是不是呢？进入看看就知道了.
	private <T> List<T> createSpringFactoriesInstances(Class<T> type,
			Class<?>[] parameterTypes, ClassLoader classLoader, Object[] args,
			Set<String> names) {
        // 先得到一个集合，存放接下来要创建的实例
		List<T> instances = new ArrayList<>(names.size());
		for (String name : names) {// 遍历名字
			try {
                // 看看名字对应的类是否加载
				Class<?> instanceClass = ClassUtils.forName(name, classLoader);
                // 如果类型是找到的实例
				Assert.isAssignable(type, instanceClass);
                // 那么就调用该类的构造方式
				Constructor<?> constructor = instanceClass
						.getDeclaredConstructor(parameterTypes);
                // 创建一个该类的实例化对象，并对象放到容器种
				T instance = (T) BeanUtils.instantiateClass(constructor, args);
				instances.add(instance);
			}
			catch (Throwable ex) {
				throw new IllegalArgumentException(
						"Cannot instantiate " + type + " : " + name, ex);
			}
		}
		return instances;
	}

	// 那看一下，具体是如何创建的对象把; 技术就得打破沙锅，找到底
	public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
		Assert.notNull(ctor, "Constructor must not be null");
		try {
            // 通过反射设置其为可Accessible
			ReflectionUtils.makeAccessible(ctor);
            // 这里就是具体的创建实例了。
            // 如果是Kotlin类型，就是调用私有的构造函数进行创建
            // 不然就正常创建
			return (KotlinDetector.isKotlinType(ctor.getDeclaringClass()) ?
					KotlinDelegate.instantiateClass(ctor, args) : ctor.newInstance(args));
		}
		catch (InstantiationException ex) {
			throw new BeanInstantiationException(ctor, "Is it an abstract class?", ex);
		}
		catch (IllegalAccessException ex) {
			throw new BeanInstantiationException(ctor, "Is the constructor accessible?", ex);
		}
		catch (IllegalArgumentException ex) {
			throw new BeanInstantiationException(ctor, "Illegal arguments for constructor", ex);
		}
		catch (InvocationTargetException ex) {
			throw new BeanInstantiationException(ctor, "Constructor threw exception", ex.getTargetException());
		}
	}
	// 调用私有构造器
    public static <T> T instantiateClass(Constructor<T> ctor, Object... args)
        throws IllegalAccessException, InvocationTargetException, InstantiationException {

        KFunction<T> kotlinConstructor = ReflectJvmMapping.getKotlinFunction(ctor);
        if (kotlinConstructor == null) {
            return ctor.newInstance(args);
        }
        List<KParameter> parameters = kotlinConstructor.getParameters();
        Map<KParameter, Object> argParameters = new HashMap<>(parameters.size());
        Assert.isTrue(args.length <= parameters.size(),
                      "Number of provided arguments should be less of equals than number of constructor parameters");
        for (int i = 0 ; i < args.length ; i++) {
            if (!(parameters.get(i).isOptional() && args[i] == null)) {
                argParameters.put(parameters.get(i), args[i]);
            }
        }
        return kotlinConstructor.callBy(argParameters);
    }
	// 正常创建实例
    public T newInstance(Object ... initargs)
        throws InstantiationException, IllegalAccessException,
               IllegalArgumentException, InvocationTargetException
    {
        if (!override) {
            if (!Reflection.quickCheckMemberAccess(clazz, modifiers)) {
                Class<?> caller = Reflection.getCallerClass();
                checkAccess(caller, clazz, null, modifiers);
            }
        }
        if ((clazz.getModifiers() & Modifier.ENUM) != 0)
            throw new IllegalArgumentException("Cannot reflectively create enum objects");
        ConstructorAccessor ca = constructorAccessor;   // read volatile
        if (ca == null) {
            ca = acquireConstructorAccessor();
        }
        @SuppressWarnings("unchecked")
        T inst = (T) ca.newInstance(initargs);
        return inst;
    }

```

那最后确实是通过限定名，去反射调用其构造器进行实例化对象的创建。

那设置初始化类和设置监听器步骤查不到：

1. 先从spring.factories文件种加载所有的key-value内容到一个map容器中，也就是缓存。
2. 得到ApplicationContextInitializer的实现类的限定名集合
3. 通过反射调用各个实现类的构造器创建实例集合，并返回
4. 得到ApplicationListener监听器的实现类的限定名集合
5. 通过反射创建其实例
6. 设置监听器实例

到此，初始化函数和监听器就设置完毕

那函数还有最后一步操作，看一下，是做什么呢？

```java
	public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
		this.resourceLoader = resourceLoader;
		Assert.notNull(primarySources, "PrimarySources must not be null");
		this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
		this.webApplicationType = deduceWebApplicationType();
		setInitializers((Collection) getSpringFactoriesInstances(
				ApplicationContextInitializer.class));
		setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
        // 看一次此步骤是做什么呢?
		this.mainApplicationClass = deduceMainApplicationClass();
	}
	//  此函数作用看来就是得到main函数所在的类
	private Class<?> deduceMainApplicationClass() {
		try {
            // 获取调用函数栈
			StackTraceElement[] stackTrace = new RuntimeException().getStackTrace();
            // 对栈中的函数进行遍历，得到main函数在哪一个类中
			for (StackTraceElement stackTraceElement : stackTrace) {
				if ("main".equals(stackTraceElement.getMethodName())) {
					return Class.forName(stackTraceElement.getClassName());
				}
			}
		}
		catch (ClassNotFoundException ex) {
			// Swallow and continue
		}
		return null;
	}
```

你实例化初始化类和监听器，接下来咱们看一下run是如何把项目启动起来的。