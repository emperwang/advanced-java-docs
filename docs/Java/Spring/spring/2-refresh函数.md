[TOC]

# refresh 函数

本篇咱们接着上篇的继续分析，看一下refresh函数的工作。refresh中的每一个函数，基本就是一个步骤，这里咱们分析的基调就是按照每一步进行分析，也就是一个函数一个函数的进行分析，当然了根据每个函数的功能不同，其难易程度以及代码深度也是不一样的。先回顾一下refresh函数:

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

## refresh--> prepareRefresh

> org.springframework.context.support.AbstractApplicationContext#prepareRefresh

```java
// 准备进行容器刷新操作前的准备
protected void prepareRefresh() {
    // 记录容器启动的时间
    this.startupDate = System.currentTimeMillis();
    // 设置容器的标志
    this.closed.set(false);
    this.active.set(true);
    // 日志的打印
    if (logger.isDebugEnabled()) {
        if (logger.isTraceEnabled()) {
            logger.trace("Refreshing " + this);
        }
        else {
            logger.debug("Refreshing " + getDisplayName());
        }
    }

    // Initialize any placeholder property sources in the context environment
    // do nothing  此方法用于子类的扩展
    // 对servlet中的 servletContextInitParams  servletConfigInitParams属性的配置
    initPropertySources();

    // Validate that all properties marked as required are resolvable
    // see ConfigurablePropertyResolver#setRequiredProperties
    // 创建环境变量的map  并进行校验
    getEnvironment().validateRequiredProperties();

    // Allow for the collection of early ApplicationEvents,
    // to be published once the multicaster is available...
    // applicationd的前期的事件, 此处创建了一个hashSet,用于存储事件
    this.earlyApplicationEvents = new LinkedHashSet<>();
}
```

## refresh --> obtainFreshBeanFactory

```java
// 第二步 获取BeanFactory
ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
```

> org.springframework.context.support.AbstractApplicationContext#obtainFreshBeanFactory

```java
	// 获取 beanFactory,也就是bean容器
	protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
		// 刷新容器
		// 也就是设置容器刷新的标志位
		refreshBeanFactory();
		// 获取beanFactory,就是获取创建好的 DefaultListableBeanFactory
		return getBeanFactory();
	}
```

> org.springframework.context.support.GenericApplicationContext#refreshBeanFactory

```java
@Override
protected final void refreshBeanFactory() throws IllegalStateException {
    // 容器刷新操作,更新标志位
    if (!this.refreshed.compareAndSet(false, true)) {
        throw new IllegalStateException(
 "GenericApplicationContext does not support multiple refresh attempts: just call 'refresh' once");
    }
    // 相当于记录一个容器的唯一标志位
    this.beanFactory.setSerializationId(getId());
}

```

> org.springframework.context.support.AbstractApplicationContext#getId

```java
private String id = ObjectUtils.identityToString(this);	

@Override
public String getId() {
    return this.id;
}


// 对容器生成一个 唯一性名字
public static String identityToString(@Nullable Object obj) {
    if (obj == null) {
        return EMPTY_STRING;
    }
    // 类名 + @ + 生成的 Hex码
    return obj.getClass().getName() + "@" + getIdentityHexString(obj);
}
```

> org.springframework.beans.factory.support.DefaultListableBeanFactory#setSerializationId

```java
// 记录此容器的唯一标识位
public void setSerializationId(@Nullable String serializationId) {
    if (serializationId != null) {
        serializableFactories.put(serializationId, new WeakReference<>(this));
    }
    else if (this.serializationId != null) {
        serializableFactories.remove(this.serializationId);
    }
    this.serializationId = serializationId;
}
```

> org.springframework.context.support.GenericApplicationContext#getBeanFactory

```java
// 获取beanFactory
public final ConfigurableListableBeanFactory getBeanFactory() {
    return this.beanFactory;
}

// 此beanFactory是在 GenericApplicationContext的构造方法中生成的
public GenericApplicationContext() {
    /**
		 *  创建工厂类
		 */
    this.beanFactory = new DefaultListableBeanFactory();
}
```



## refresh --> prepareBeanFactory

```java
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
```

```java
// 配置beanFactory
// 1. 配置类加载器
// 2. 配置EL表达式解析器
// 3. 配置ResourceEditorRegistrar
// 4. 添加ApplicationContextAwareProcessor  ApplicationListenerDetector后置处理器 以及各种Aware接口处理器
// 5. 配置一些不需要自动装配的bean
// 6. 配置一些固定类型的bean
// 7. 添加环境相关的bean到容器中
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    // Tell the internal bean factory to use the context's class loader etc.
    beanFactory.setBeanClassLoader(getClassLoader());
    beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
    beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));

    // Configure the bean factory with context callbacks.
    // 添加一个后置处理器 ApplicationContextAwareProcessor,此处理器会在bean初始化前调用各种Aware接口
    beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
    // 下面添加的这些接口类, 不需要进行自动装配
    beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
    beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
    beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
    beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);

    // BeanFactory interface not registered as resolvable type in a plain factory.
    // MessageSource registered (and found for autowiring) as a bean.
    // 下面注册的这些类,相当于是给类指定好了准备类型.
    // BeanFactory.class 类型的装配bean是  beanFactory
   // ResourceLoader.class   ApplicationEventPublisher.class  ApplicationContext.class 装配对象是当前类
    beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
    beanFactory.registerResolvableDependency(ResourceLoader.class, this);
    beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
    beanFactory.registerResolvableDependency(ApplicationContext.class, this);

    // Register early post-processor for detecting inner beans as ApplicationListeners.
    // 注册一个后置处理器,此后置处理器的工作
    // 1.在postProcessMergedBeanDefinition方法中记录此bean是否是单例
    // 2.初始化前没有动作
    // 3.初始化后根据此bean是监听器并且是单例,则放入到容器中
    // 4.销毁前,如果是监听器,则把此bean实例从容器中的监听器中去除
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

    // Detect a LoadTimeWeaver and prepare for weaving, if found.
    // 对于loadTimeWeaver的特殊处理, 暂且不表
    if (beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        // Set a temporary ClassLoader for type matching.
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }

    // Register default environment beans.
    // 注册环境bean(environment)到容器中
    if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
    }
    // 注册系统属性bean(systemEnvironment)到容器中
    if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
    }
    // 注册系统属性bean(systemEnvironment)到容器中
    if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
    }
}
```

看一下此类中注册单例的操作；

> org.springframework.beans.factory.support.DefaultListableBeanFactory#registerSingleton

```java
// 注册单例操作
@Override
public void registerSingleton(String beanName, Object singletonObject) throws IllegalStateException {
    super.registerSingleton(beanName, singletonObject); // 父类的注册动作
    // 如果容器已经开始创建
    if (hasBeanCreationStarted()) {
        // Cannot modify startup-time collection elements anymore (for stable iteration)
        // 则在添加时,使用 synchronized 同步字段进行添加
        synchronized (this.beanDefinitionMap) {
            if (!this.beanDefinitionMap.containsKey(beanName)) {
           Set<String> updatedSingletons = new LinkedHashSet<>(this.manualSingletonNames.size() + 1);
                updatedSingletons.addAll(this.manualSingletonNames);
                updatedSingletons.add(beanName);
                this.manualSingletonNames = updatedSingletons;
            }
        }
    }
    else {
        // Still in startup registration phase
        // 如果还没有开始创建,则直接进行添加
        if (!this.beanDefinitionMap.containsKey(beanName)) {
            this.manualSingletonNames.add(beanName);
        }
    }
    clearByTypeCache();
}

```

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#registerSingleton

```java
// 注册单例操作
@Override
public void registerSingleton(String beanName, Object singletonObject) throws IllegalStateException {
    Assert.notNull(beanName, "Bean name must not be null");
    Assert.notNull(singletonObject, "Singleton object must not be null");
    // 同步进行添加的操作
    synchronized (this.singletonObjects) {
        // 查看是否已经注册此单例,如果已经注册此单例,则抛出异常
        Object oldObject = this.singletonObjects.get(beanName);
        if (oldObject != null) {
            throw new IllegalStateException("Could not register object [" + singletonObject +
                                            "] under bean name '" + beanName + "': there is already object [" + oldObject + "] bound");
        }
        // 添加单例
        addSingleton(beanName, singletonObject);
    }
}

// 添加单例到 容器中
protected void addSingleton(String beanName, Object singletonObject) {
    /**
		 * 把创建好的对象放入到对应的map
		 */
    synchronized (this.singletonObjects) {
        // 把创建好的singletonObject放到单例缓存池
        this.singletonObjects.put(beanName, singletonObject);
        // 把此bean从工厂map中移除
        this.singletonFactories.remove(beanName);
        // 此次beanName对应的bean从earlySingletonObjects移除
        this.earlySingletonObjects.remove(beanName);
        // 因为是注册单例,故把此beanName放到registeredSingletons中
        this.registeredSingletons.add(beanName);
    }
}
```

## refresh --> postProcessBeanFactory

```java
// Allows post-processing of the bean factory in context subclasses.
// 用于子类进行扩展
// 对于web工程是有做扩展操作的,等看到web源码时,在细看
// 第四步
postProcessBeanFactory(beanFactory);
```

这里咱们看一下webContext的类图，开一个头，了解做了什么工作，不会深入解析，等后面解析到web后，在进行分析：

![](GenericWebApplicationContext.png)

> org.springframework.web.context.support.GenericWebApplicationContext#postProcessBeanFactory

```java
	// 向web容器中注册 基础的 bean容器
	@Override
	protected void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
		if (this.servletContext != null) {
			beanFactory.addBeanPostProcessor(new ServletContextAwareProcessor(this.servletContext));
			beanFactory.ignoreDependencyInterface(ServletContextAware.class);
		}
		// 注册web的scope
		WebApplicationContextUtils.registerWebApplicationScopes(beanFactory, this.servletContext);
		// 注册servlet的环境变量: servletContextInitParameter   servletContextAttribute
		WebApplicationContextUtils.registerEnvironmentBeans(beanFactory, this.servletContext);
	}
```

> org.springframework.web.context.support.WebApplicationContextUtils#registerWebApplicationScopes

```java
// 向beanFactory中注册 servletContext
public static void registerWebApplicationScopes(ConfigurableListableBeanFactory beanFactory,
                                                @Nullable ServletContext sc) {

    beanFactory.registerScope(WebApplicationContext.SCOPE_REQUEST, new RequestScope());
    beanFactory.registerScope(WebApplicationContext.SCOPE_SESSION, new SessionScope());
    if (sc != null) {
        ServletContextScope appScope = new ServletContextScope(sc);
        beanFactory.registerScope(WebApplicationContext.SCOPE_APPLICATION, appScope);
        // Register as ServletContext attribute, for ContextCleanupListener to detect it.
        sc.setAttribute(ServletContextScope.class.getName(), appScope);
    }
    // 记录 特定 type对应的 value
    beanFactory.registerResolvableDependency(ServletRequest.class, new RequestObjectFactory());
    beanFactory.registerResolvableDependency(ServletResponse.class, new ResponseObjectFactory());
    beanFactory.registerResolvableDependency(HttpSession.class, new SessionObjectFactory());
    beanFactory.registerResolvableDependency(WebRequest.class, new WebRequestObjectFactory());
    if (jsfPresent) {
        FacesDependencyRegistrar.registerFacesDependencies(beanFactory);
    }
}
```

> org.springframework.web.context.support.WebApplicationContextUtils#registerEnvironmentBeans

```java
// 注册 servlet的环境变量值
public static void registerEnvironmentBeans(ConfigurableListableBeanFactory bf, @Nullable ServletContext sc) {
    registerEnvironmentBeans(bf, sc, null);
}
```

```java
// 1. 向beanFactory中注册 servletContext
// 2. 向beanFactory中注册 servletConfig
// 3. 向beanFactory中注册 contextParameters
// 4. 向beanFactory中注册 contextAttributes
public static void registerEnvironmentBeans(ConfigurableListableBeanFactory bf,
                                            @Nullable ServletContext servletContext, @Nullable ServletConfig servletConfig) {
    // 把servletContext 注册到 beanFactory中
    if (servletContext != null && !bf.containsBean(WebApplicationContext.SERVLET_CONTEXT_BEAN_NAME)) {
        bf.registerSingleton(WebApplicationContext.SERVLET_CONTEXT_BEAN_NAME, servletContext);
    }
    // 把servletConfig 注册到 beanFactory中
    if (servletConfig != null && !bf.containsBean(ConfigurableWebApplicationContext.SERVLET_CONFIG_BEAN_NAME)) {
        bf.registerSingleton(ConfigurableWebApplicationContext.SERVLET_CONFIG_BEAN_NAME, servletConfig);
    }
    // 把servletContext.getInitParameterNames 注册到 beanFactory中
    if (!bf.containsBean(WebApplicationContext.CONTEXT_PARAMETERS_BEAN_NAME)) {
        Map<String, String> parameterMap = new HashMap<>();
        if (servletContext != null) {
            Enumeration<?> paramNameEnum = servletContext.getInitParameterNames();
            while (paramNameEnum.hasMoreElements()) {
                String paramName = (String) paramNameEnum.nextElement();
                parameterMap.put(paramName, servletContext.getInitParameter(paramName));
            }
        }
        if (servletConfig != null) {
            Enumeration<?> paramNameEnum = servletConfig.getInitParameterNames();
            while (paramNameEnum.hasMoreElements()) {
                String paramName = (String) paramNameEnum.nextElement();
                parameterMap.put(paramName, servletConfig.getInitParameter(paramName));
            }
        }
        bf.registerSingleton(WebApplicationContext.CONTEXT_PARAMETERS_BEAN_NAME,
                             Collections.unmodifiableMap(parameterMap));
    }
    // 把servletContext.getAttributeNames 注册到 beanFactory中
    if (!bf.containsBean(WebApplicationContext.CONTEXT_ATTRIBUTES_BEAN_NAME)) {
        Map<String, Object> attributeMap = new HashMap<>();
        if (servletContext != null) {
            Enumeration<?> attrNameEnum = servletContext.getAttributeNames();
            while (attrNameEnum.hasMoreElements()) {
                String attrName = (String) attrNameEnum.nextElement();
                attributeMap.put(attrName, servletContext.getAttribute(attrName));
            }
        }
        bf.registerSingleton(WebApplicationContext.CONTEXT_ATTRIBUTES_BEAN_NAME,
                             Collections.unmodifiableMap(attributeMap));
    }
}
```

可以看到此函数主要是对web环境的一个配置。

## refresh-->invokeBeanFactoryPostProcessors

```java
/**
				 * 第五步
				 * 1. 调用 所有的BeanDefinitionRegistryPostProcessor 后置处理器
				 * 2. 调用所有的BeanFactoryPostProcessor 后置处理器
				 */
invokeBeanFactoryPostProcessors(beanFactory);
```

> org.springframework.context.support.AbstractApplicationContext#invokeBeanFactoryPostProcessors

```java
// 实例化并调用所有注册的 BeanFactoryPostProcessor 后置处理器
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    // 获取所有的BeanFactoryPostProcessor后置处理器
    // 并调用
    PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());

    // Detect a LoadTimeWeaver and prepare for weaving, if found in the meantime
    // (e.g. through an @Bean method registered by ConfigurationClassPostProcessor)
    // 关于LoadTimeWeaver 此处先不解析
    if (beanFactory.getTempClassLoader() == null && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
}
```

> org.springframework.context.support.AbstractApplicationContext#getBeanFactoryPostProcessors

```java
// 记录容器中所有的 BeanFactoryPostProcessor
private final List<BeanFactoryPostProcessor> beanFactoryPostProcessors = new ArrayList<>();	
public List<BeanFactoryPostProcessor> getBeanFactoryPostProcessors() {
    return this.beanFactoryPostProcessors;
}
```

> org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanFactoryPostProcessors

```java
// 调用 beanFactoryPostProcessors
public static void invokeBeanFactoryPostProcessors(
    ConfigurableListableBeanFactory beanFactory, List<BeanFactoryPostProcessor> beanFactoryPostProcessors) {

    // Invoke BeanDefinitionRegistryPostProcessors first, if any.
    Set<String> processedBeans = new HashSet<>();

    if (beanFactory instanceof BeanDefinitionRegistry) {
        BeanDefinitionRegistry registry = (BeanDefinitionRegistry) beanFactory;
        List<BeanFactoryPostProcessor> regularPostProcessors = new ArrayList<>();
        List<BeanDefinitionRegistryPostProcessor> registryProcessors = new ArrayList<>();
        // 遍历所有的后置处理器,如果是BeanDefinitionRegistryPostProcessor后置处理器则调用
        // 并添加到registryProcessors
        for (BeanFactoryPostProcessor postProcessor : beanFactoryPostProcessors) {
            if (postProcessor instanceof BeanDefinitionRegistryPostProcessor) {
                BeanDefinitionRegistryPostProcessor registryProcessor =
                    (BeanDefinitionRegistryPostProcessor) postProcessor;
                // 此操作可以注册更多的beanDefinition到容器中
                // 具体的解析操作
                registryProcessor.postProcessBeanDefinitionRegistry(registry);
                registryProcessors.add(registryProcessor);
            }
            else {
                regularPostProcessors.add(postProcessor);
            }
        }

        // Do not initialize FactoryBeans here: We need to leave all regular beans
        // uninitialized to let the bean factory post-processors apply to them!
        // Separate between BeanDefinitionRegistryPostProcessors that implement
        // PriorityOrdered, Ordered, and the rest.
        List<BeanDefinitionRegistryPostProcessor> currentRegistryProcessors = new ArrayList<>();

        // First, invoke the BeanDefinitionRegistryPostProcessors that implement PriorityOrdered.
        // 获取所有的BeanDefinitionRegistryPostProcessor的bean定义
        String[] postProcessorNames =
            beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        // 遍历获取到的后置处理器BeanDefinitionRegistryPostProcessor,如果实现了PriorityOrdered,则添加到currentRegistryProcessors
        for (String ppName : postProcessorNames) {
            if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        // 把获取到的实现了PriorityOrdered的BeanDefinitionRegistryPostProcessor进行排序操作
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        // 按顺序调用currentRegistryProcessors中的后置处理器
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        // 调用完之后，清空
        currentRegistryProcessors.clear();

        // Next, invoke the BeanDefinitionRegistryPostProcessors that implement Ordered.
        // 再次获取所有的BeanDefinitionRegistryPostProcessor
        postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        // 遍历得到实现了Ordered接口的BeanDefinitionRegistryPostProcessors
        for (String ppName : postProcessorNames) {
            if (!processedBeans.contains(ppName) && beanFactory.isTypeMatch(ppName, Ordered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        // 对后置处理进行排序
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        // 调用排好序的后置处理器,调用完成后情况容器
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        currentRegistryProcessors.clear();

        // Finally, invoke all other BeanDefinitionRegistryPostProcessors until no further ones appear.
        boolean reiterate = true;
        while (reiterate) {
            // 获取上面两次都没有获取到的BeanDefinitionRegistryPostProcessor处理器
            reiterate = false;
            postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
            for (String ppName : postProcessorNames) {
                if (!processedBeans.contains(ppName)) {
                    currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                    processedBeans.add(ppName);
                    reiterate = true;
                }
            }
            // 同样是对处理器进行排序,添加到registryProcessors, 调用, 然后清空容器
            sortPostProcessors(currentRegistryProcessors, beanFactory);
            registryProcessors.addAll(currentRegistryProcessors);
            invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
            currentRegistryProcessors.clear();
        }

        // Now, invoke the postProcessBeanFactory callback of all processors handled so far.
        // 现在调用所有的BeanFactoryPostProcessor.postProcessBeanFactory 方法,对ioc容器中的beanDefinition进行修改
        invokeBeanFactoryPostProcessors(registryProcessors, beanFactory);
        invokeBeanFactoryPostProcessors(regularPostProcessors, beanFactory);
    }

    else {
        // Invoke factory processors registered with the context instance.
        invokeBeanFactoryPostProcessors(beanFactoryPostProcessors, beanFactory);
    }

    // Do not initialize FactoryBeans here: We need to leave all regular beans
    // uninitialized to let the bean factory post-processors apply to them!
    /**
		 * 第二个阶段调用BeanFactoryPostProcessor
		 * 1. 上面阶段调用过的就不会调用了
		 * 2.先对实现了此接口PriorityOrdered的处理器进行排序,然后调用,最后清空容器
		 * 3.再对实现了Ordered接口额处理器排序,调用, 之后清空容易
		 * 4.最后对没有实现排序接口的处理器进行调用
		 * 5. 最后清空那些缓存bean名字对应bean 类型的缓存
		 */
    String[] postProcessorNames =
        beanFactory.getBeanNamesForType(BeanFactoryPostProcessor.class, true, false);

    // Separate between BeanFactoryPostProcessors that implement PriorityOrdered,
    // Ordered, and the rest.
    List<BeanFactoryPostProcessor> priorityOrderedPostProcessors = new ArrayList<>();
    List<String> orderedPostProcessorNames = new ArrayList<>();
    List<String> nonOrderedPostProcessorNames = new ArrayList<>();
    for (String ppName : postProcessorNames) {
        if (processedBeans.contains(ppName)) {
            // skip - already processed in first phase above
        }
        else if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            priorityOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanFactoryPostProcessor.class));
        }
        else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            orderedPostProcessorNames.add(ppName);
        }
        else {
            nonOrderedPostProcessorNames.add(ppName);
        }
    }

    // First, invoke the BeanFactoryPostProcessors that implement PriorityOrdered.
    sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
    invokeBeanFactoryPostProcessors(priorityOrderedPostProcessors, beanFactory);

    // Next, invoke the BeanFactoryPostProcessors that implement Ordered.
    List<BeanFactoryPostProcessor> orderedPostProcessors = new ArrayList<>();
    for (String postProcessorName : orderedPostProcessorNames) {
        orderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
    }
    sortPostProcessors(orderedPostProcessors, beanFactory);
    invokeBeanFactoryPostProcessors(orderedPostProcessors, beanFactory);

    // Finally, invoke all other BeanFactoryPostProcessors.
    List<BeanFactoryPostProcessor> nonOrderedPostProcessors = new ArrayList<>();
    for (String postProcessorName : nonOrderedPostProcessorNames) {
        nonOrderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
    }
    invokeBeanFactoryPostProcessors(nonOrderedPostProcessors, beanFactory);

    // Clear cached merged bean definitions since the post-processors might have
    // modified the original metadata, e.g. replacing placeholders in values...
    beanFactory.clearMetadataCache();
}
```

看一下具体的调用动作：

> org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanDefinitionRegistryPostProcessors

```java
private static void invokeBeanDefinitionRegistryPostProcessors(
    Collection<? extends BeanDefinitionRegistryPostProcessor> postProcessors, BeanDefinitionRegistry registry) {
	// 调用beanFactory的后置处理器
    for (BeanDefinitionRegistryPostProcessor postProcessor : postProcessors) {
        postProcessor.postProcessBeanDefinitionRegistry(registry);
    }
}
```

> org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanFactoryPostProcessors

```java
private static void invokeBeanFactoryPostProcessors(
    Collection<? extends BeanFactoryPostProcessor> postProcessors, ConfigurableListableBeanFactory beanFactory) {
    // 调用后置处理器
    for (BeanFactoryPostProcessor postProcessor : postProcessors) {
        postProcessor.postProcessBeanFactory(beanFactory);
    }
}
```

限于篇幅，本篇就先分析到这里，后面开篇继续进行此函数的分析。



















































































