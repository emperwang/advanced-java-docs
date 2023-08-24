[TOC]

# AnnotationConfigApplicationContext初始化

本篇分析一下关于此AnnotationConfigApplicationContext类的初始化。

看一下此类的类图:

![](AnnotationConfigApplicationContext.png)

先看一下具体的dmeo入口函数：

```java
public class BeanStarter {
    public static void main(String[] args) {
        AnnotationConfigApplicationContext applicationContext =
            new AnnotationConfigApplicationContext(BeanConfig.class);
        Person person = (Person) applicationContext.getBean("person");

        System.out.println(person.toString());
    }
}
```

> AnnotationConfigApplicationContext 的构造函数

```java
// 构造函数	
public AnnotationConfigApplicationContext(Class<?>... annotatedClasses) {
		// 初始化
		this();
		/**
		 *  注册这个配置类
		 */
		register(annotatedClasses);
		/**
		 *  ioc 容器的刷新
		 */
		refresh();
	}

	// this()
	public AnnotationConfigApplicationContext() {
		/**
		 *  先调用父类的构造器，创建工厂类
		 *  创建两个解析bean定义的类
		 */
		// AnnotatedBeanDefinitionReader 此初始化会注册一些注解的公共处理类到容器
		this.reader = new AnnotatedBeanDefinitionReader(this);
        // 此ClassPathBeanDefinitionScanner 主要是获取classpath中的 类并封装为 beanDefinition
        // 这里等使用到了,再具体细说, 在这里就知道其 创建是在这里就好
		this.scanner = new ClassPathBeanDefinitionScanner(this);
	}
```

先看一下this()构造器中初始化的两个实例：

> org.springframework.context.annotation.AnnotatedBeanDefinitionReader

```java
	// 在这里会创建系统变量environment bean
	public AnnotatedBeanDefinitionReader(BeanDefinitionRegistry registry) {
		this(registry, getOrCreateEnvironment(registry));
	}
```

> org.springframework.context.annotation.AnnotatedBeanDefinitionReader#getOrCreateEnvironment

```java
	// 如果ioc中已经存在了Environment,那么就使用此存在的environment,否则创建一个
	private static Environment getOrCreateEnvironment(BeanDefinitionRegistry registry) {
		Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
		if (registry instanceof EnvironmentCapable) {
			return ((EnvironmentCapable) registry).getEnvironment();
		}
		return new StandardEnvironment();
	}
```

> org.springframework.context.annotation.AnnotatedBeanDefinitionReader#AnnotatedBeanDefinitionReader

```java
	public AnnotatedBeanDefinitionReader(BeanDefinitionRegistry registry, Environment environment) {
		Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
		Assert.notNull(environment, "Environment must not be null");
		this.registry = registry;
		// conditional 注解的处理
		this.conditionEvaluator = new ConditionEvaluator(registry, environment, null);
		// 具体注册公共处理类到容器的方法
		AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
	}
```

> org.springframework.context.annotation.AnnotationConfigUtils#registerAnnotationConfigProcessors

```java
	// 注册注解的公共处理类到容器
	public static void registerAnnotationConfigProcessors(BeanDefinitionRegistry registry) {
		registerAnnotationConfigProcessors(registry, null);
	}
```



```java
// 注册了很多的 后置处理器到容器中，用于对一些 注解 以及 注入的操作
// 注册注解的公共处理类
public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
    BeanDefinitionRegistry registry, @Nullable Object source) {

    DefaultListableBeanFactory beanFactory = unwrapDefaultListableBeanFactory(registry);
    if (beanFactory != null) {
        if (!(beanFactory.getDependencyComparator() instanceof AnnotationAwareOrderComparator)) {
            beanFactory.setDependencyComparator(AnnotationAwareOrderComparator.INSTANCE);
        }
        if (!(beanFactory.getAutowireCandidateResolver() instanceof ContextAnnotationAutowireCandidateResolver)) {
            beanFactory.setAutowireCandidateResolver(new ContextAnnotationAutowireCandidateResolver());
        }
    }

    Set<BeanDefinitionHolder> beanDefs = new LinkedHashSet<>(8);
    // 具体的注册动作
    if (!registry.containsBeanDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        // 注册bean ConfigurationClassPostProcessor
        // 主要用来解析 import  configuration importResource 配置类
        RootBeanDefinition def = new RootBeanDefinition(ConfigurationClassPostProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        // 注册bean  AutowiredAnnotationBeanPostProcessor
        // 处理自动注入的操作
        RootBeanDefinition def = new RootBeanDefinition(AutowiredAnnotationBeanPostProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    // Check for JSR-250 support, and if present add the CommonAnnotationBeanPostProcessor.
    if (jsr250Present && !registry.containsBeanDefinition(COMMON_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        // 注册 bean CommonAnnotationBeanPostProcessor
        // // 对PostConstruct   PreDestroy  Resource  注解的处理
        RootBeanDefinition def = new RootBeanDefinition(CommonAnnotationBeanPostProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, COMMON_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    // Check for JPA support, and if present add the PersistenceAnnotationBeanPostProcessor.
    if (jpaPresent && !registry.containsBeanDefinition(PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition();
        try {
            // 注册bean PersistenceAnnotationBeanPostProcessor
            def.setBeanClass(ClassUtils.forName(PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME,
                                                AnnotationConfigUtils.class.getClassLoader()));
        }
        catch (ClassNotFoundException ex) {
            throw new IllegalStateException(
                "Cannot load optional framework class: " + PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME, ex);
        }
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(EVENT_LISTENER_PROCESSOR_BEAN_NAME)) {
        // 注册 bean EventListenerMethodProcessor
        RootBeanDefinition def = new RootBeanDefinition(EventListenerMethodProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(EVENT_LISTENER_FACTORY_BEAN_NAME)) {
        // 注册bean  DefaultEventListenerFactory
        RootBeanDefinition def = new RootBeanDefinition(DefaultEventListenerFactory.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_FACTORY_BEAN_NAME));
    }

    return beanDefs;
}
```

注册bean到容器中，看一下具体的注册的动作：

> org.springframework.context.annotation.AnnotationConfigUtils#registerPostProcessor

```java
	// 注册 beanDefinition到容器的动作
	// 最终: beanDefinitionMap.put(beanName, beanDefinition)
	private static BeanDefinitionHolder registerPostProcessor(
			BeanDefinitionRegistry registry, RootBeanDefinition definition, String beanName) {

		definition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
		registry.registerBeanDefinition(beanName, definition);
		return new BeanDefinitionHolder(definition, beanName);
	}
```

> org.springframework.beans.factory.support.DefaultListableBeanFactory#registerBeanDefinition

```java
// 注册beanDefinition 到容器中
@Override
public void registerBeanDefinition(String beanName, BeanDefinition beanDefinition)
    throws BeanDefinitionStoreException {

    Assert.hasText(beanName, "Bean name must not be empty");
    Assert.notNull(beanDefinition, "BeanDefinition must not be null");
    // 如果是AbstractBeanDefinition,则进行一下校验
    if (beanDefinition instanceof AbstractBeanDefinition) {
        try {
            ((AbstractBeanDefinition) beanDefinition).validate();
        }
        catch (BeanDefinitionValidationException ex) {
            throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription(), beanName,
                                                   "Validation of bean definition failed", ex);
        }
    }
    // 根据名字,先去容器中获取一下,看能不能获取到
    BeanDefinition existingDefinition = this.beanDefinitionMap.get(beanName);
    // 如果获取到了
    if (existingDefinition != null) {
        // 如果不允许覆盖,则直接报错
        if (!isAllowBeanDefinitionOverriding()) {
            throw new BeanDefinitionOverrideException(beanName, beanDefinition, existingDefinition);
        }
        // 如果已经存在的 beanDefinition 角色 小于 要注册的bean的橘色,则打印日志
        else if (existingDefinition.getRole() < beanDefinition.getRole()) {
            // e.g. was ROLE_APPLICATION, now overriding with ROLE_SUPPORT or ROLE_INFRASTRUCTURE
            if (logger.isInfoEnabled()) {
                logger.info("Overriding user-defined bean definition for bean '" + beanName +
                            "' with a framework-generated bean definition: replacing [" +
                            existingDefinition + "] with [" + beanDefinition + "]");
            }
        }
        // 如果两个beanDefinition 不相等,则打印日志
        else if (!beanDefinition.equals(existingDefinition)) {
            if (logger.isDebugEnabled()) {
                logger.debug("Overriding bean definition for bean '" + beanName +
                             "' with a different definition: replacing [" + existingDefinition +
                             "] with [" + beanDefinition + "]");
            }
        }
        else {
            if (logger.isTraceEnabled()) {
                logger.trace("Overriding bean definition for bean '" + beanName +
                             "' with an equivalent definition: replacing [" + existingDefinition +
                             "] with [" + beanDefinition + "]");
            }
        }
        // 放入到 容器map中,进行了beanDefinition的覆盖操作
        this.beanDefinitionMap.put(beanName, beanDefinition);
    }
    else {
        // 如果已经开始创建,
        if (hasBeanCreationStarted()) {
            // Cannot modify startup-time collection elements anymore (for stable iteration)
            // 则 使用同步锁 进行更新
            synchronized (this.beanDefinitionMap) {
                this.beanDefinitionMap.put(beanName, beanDefinition);
                List<String> updatedDefinitions = new ArrayList<>(this.beanDefinitionNames.size() + 1);
                updatedDefinitions.addAll(this.beanDefinitionNames);
                updatedDefinitions.add(beanName);
                this.beanDefinitionNames = updatedDefinitions;
                if (this.manualSingletonNames.contains(beanName)) {
                    Set<String> updatedSingletons = new LinkedHashSet<>(this.manualSingletonNames);
                    updatedSingletons.remove(beanName);
                    this.manualSingletonNames = updatedSingletons;
                }
            }
        }
        else {
            // Still in startup registration phase
            //如果 还没有开始创建bean的创建
            this.beanDefinitionMap.put(beanName, beanDefinition);
            this.beanDefinitionNames.add(beanName);
            this.manualSingletonNames.remove(beanName);
        }
        this.frozenBeanDefinitionNames = null;
    }

    if (existingDefinition != null || containsSingleton(beanName)) {
        resetBeanDefinition(beanName);
    }
}
```

看到了哦，具体的注册动作，其实就是把beanDefinition 存储到一个map中。

到这里，this()构造函数就看完了，继续向下看：

> org.springframework.context.annotation.AnnotationConfigApplicationContext#register

```java
	// 把annotatedClasses 封装到beanDefinition中并注册到容器中
	public void register(Class<?>... annotatedClasses) {
		Assert.notEmpty(annotatedClasses, "At least one annotated class must be specified");
		this.reader.register(annotatedClasses);
	}
```

> org.springframework.context.annotation.AnnotatedBeanDefinitionReader#register

```java
	// 把annotatedClasses 定义为beanDefinition 并注册到容器中
	public void register(Class<?>... annotatedClasses) {
		for (Class<?> annotatedClass : annotatedClasses) {
			registerBean(annotatedClass);
		}
	}
```

> org.springframework.context.annotation.AnnotatedBeanDefinitionReader#registerBean(java.lang.Class<?>)

```java
	//  注册一个注解声明的配置类
	public void registerBean(Class<?> annotatedClass) {
		doRegisterBean(annotatedClass, null, null, null);
	}
```



```java
// 注册bean 到容器中
<T> void doRegisterBean(Class<T> annotatedClass, @Nullable Supplier<T> instanceSupplier, @Nullable String name,
                        @Nullable Class<? extends Annotation>[] qualifiers, BeanDefinitionCustomizer... definitionCustomizers) {

    AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(annotatedClass);
    if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
        return;
    }
    abd.setInstanceSupplier(instanceSupplier);
    ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(abd);
    abd.setScope(scopeMetadata.getScopeName());
    String beanName = (name != null ? name : this.beanNameGenerator.generateBeanName(abd, this.registry));
    // 对此类中的一般注册进行处理如: lazy  dependOn  primary
    AnnotationConfigUtils.processCommonDefinitionAnnotations(abd);
    if (qualifiers != null) {
        for (Class<? extends Annotation> qualifier : qualifiers) {
            if (Primary.class == qualifier) {
                abd.setPrimary(true);
            }
            else if (Lazy.class == qualifier) {
                abd.setLazyInit(true);
            }
            else {
                abd.addQualifier(new AutowireCandidateQualifier(qualifier));
            }
        }
    }
    for (BeanDefinitionCustomizer customizer : definitionCustomizers) {
        customizer.customize(abd);
    }

    BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(abd, beanName);
    definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
    // 注册beanDefinition 到容器中
    BeanDefinitionReaderUtils.registerBeanDefinition(definitionHolder, this.registry);
}
```

> org.springframework.beans.factory.support.BeanDefinitionReaderUtils#registerBeanDefinition

```java
	// 注册一个BeanDefinition 到容器中
	public static void registerBeanDefinition(
			BeanDefinitionHolder definitionHolder, BeanDefinitionRegistry registry)
			throws BeanDefinitionStoreException {

		// Register bean definition under primary name.
		// 注册beanDefinition
		String beanName = definitionHolder.getBeanName();
		registry.registerBeanDefinition(beanName, definitionHolder.getBeanDefinition());

		// Register aliases for bean name, if any.
		// 注册别名
		String[] aliases = definitionHolder.getAliases();
		if (aliases != null) {
			for (String alias : aliases) {
				registry.registerAlias(beanName, alias);
			}
		}
	}
```

可以看到这里的注册bean到容器中，和上面的注册动作是很类似的，都是把beanDefinition存储到map中。

> org.springframework.context.support.AbstractApplicationContext#refresh

大概了解过spring源码，应该都知道这里函数把，其重要性就不用多说了，容器中的主要功能Bean实例化，bean生命周期的各个阶段，bean的自动注入后置处理器等都是在这里进行的。咱们在这里先进行一个开头，后面按照功能在具体讲解：

```java
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // Prepare this context for refreshing.
        // 第一步  ioc容器开始启动前的准备工作,如  记录启动时间,修改容器是否启动的标志
        prepareRefresh();

        // Tell the subclass to refresh the internal bean factory.
        // 第二步 获取BeanFactory
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // Prepare the bean factory for use in this context.
        // 对bean工厂进行一些配置
        /**
			 * 第三步
			 * 1. 设置类加载器
			 * 2. 设置El表达式解析器
			 * 3. 设置PropertyEditorRegistrar
			 * 4. 配置两个后置处理器
			 * 5. 配置一些不需要自动装配的bean
			 * 6. 配置一些自动装配时固定类型的bean
			 * 7. 添加环境相关的bean到容器
			 */
        prepareBeanFactory(beanFactory);

        try {
            // Allows post-processing of the bean factory in context subclasses.
            // 用于子类进行扩展
            // 对于web工程是有做扩展操作的,等看到web源码时,在细看
            // 第四步
            postProcessBeanFactory(beanFactory);

            // Invoke factory processors registered as beans in the context.
            /**
				 * 第五步
				 * 1. 调用 所有的BeanDefinitionRegistryPostProcessor 后置处理器
				 * 2. 调用所有的BeanFactoryPostProcessor 后置处理器
				 */
            invokeBeanFactoryPostProcessors(beanFactory);

            // Register bean processors that intercept bean creation.
            // 注册BeanPostProcessor 后置处理器
            // 第六步
            registerBeanPostProcessors(beanFactory);

            // Initialize message source for this context.
            // 初始化国际消息组件 -- 后看
            // 第七步
            initMessageSource();

            // Initialize event multicaster for this context.
            // 第八步  为此上下文初始化 事件多播器
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
            // 第九步  此主要用于子类进行扩展
            onRefresh();

            // Check for listener beans and register them.
            // 第十步  注册监听器
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
            // 第十一步 重点  重点  重点
            // 此方法会实例化所有的非懒加载的bean
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
            // 完成refresh
            // 第十二步
            // LifeCycle 的调用在这里
            finishRefresh();
        }

        catch (BeansException ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Exception encountered during context initialization - " +
                            "cancelling refresh attempt: " + ex);
            }
            // 第十三步 Destroy already created singletons to avoid dangling resources.
            destroyBeans();
            // 第十四步  Reset 'active' flag.
            cancelRefresh(ex);
            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // 第十五步  might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}
```

























































































































