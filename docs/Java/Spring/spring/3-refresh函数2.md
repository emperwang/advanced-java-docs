[TOC]

# refresh函数

本篇接着上篇继续对refresh的分析.

## refresh --> registerBeanPostProcessors

```java
				// 注册BeanPostProcessor 后置处理器
				// 第六步
				registerBeanPostProcessors(beanFactory);
```

> org.springframework.context.support.AbstractApplicationContext#registerBeanPostProcessors

```java
// 注册所有的 BeanPostProcessor 处理器
protected void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.registerBeanPostProcessors(beanFactory, this);
}
```

> org.springframework.context.support.PostProcessorRegistrationDelegate#registerBeanPostProcessors

```java
// 注册 beanPostProcessor 后置处理器
public static void registerBeanPostProcessors(
    ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {
    // 获取所有的BeanPostProcessor的bean name
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);

    // Register BeanPostProcessorChecker that logs an info message when
    // a bean is created during BeanPostProcessor instantiation, i.e. when
    // a bean is not eligible for getting processed by all BeanPostProcessors.
    // 获取后置处理器的数量
    int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
    // 处理添加一个新的 beanPostProcessor后置处理器,用于对beanPostProcessor的校验
    beanFactory.addBeanPostProcessor(new BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));

    // Separate between BeanPostProcessors that implement PriorityOrdered,
    // Ordered, and the rest.
    // 把是实现了PriorityOrdered接口的后置处理器 和 实现了Ordered的处理器  以及都没有实现的处理器,
    // 分别放入到不同的容器中
    List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList<>();
    // 是MergedBeanDefinitionPostProcessor类型的后置处理器
    List<BeanPostProcessor> internalPostProcessors = new ArrayList<>();
    List<String> orderedPostProcessorNames = new ArrayList<>();
    List<String> nonOrderedPostProcessorNames = new ArrayList<>();
    for (String ppName : postProcessorNames) {
        // 得到实现了此PriorityOrdered接口的后置处理器
        if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            // 此处获取 后置处理的实例,实际上也是后置处理器的 初始化
            BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
            priorityOrderedPostProcessors.add(pp);
            if (pp instanceof MergedBeanDefinitionPostProcessor) {
                internalPostProcessors.add(pp);
            }
        }
        // 获取实现了Ordered接口的处理器
        else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            orderedPostProcessorNames.add(ppName);
        }
        else { // 什么都没有实现的处理器
            nonOrderedPostProcessorNames.add(ppName);
        }
    }

    // First, register the BeanPostProcessors that implement PriorityOrdered.
    // 对处理器进行排序
    sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
    // 注册处理器到容器中
    registerBeanPostProcessors(beanFactory, priorityOrderedPostProcessors);

    // Next, register the BeanPostProcessors that implement Ordered.
    List<BeanPostProcessor> orderedPostProcessors = new ArrayList<>();
    for (String ppName : orderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        orderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    // 把orider的处理器排序,同时也注册到容器中
    sortPostProcessors(orderedPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, orderedPostProcessors);

    // Now, register all regular BeanPostProcessors.
    List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList<>();
    for (String ppName : nonOrderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        nonOrderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    // 现在把那些没有排序的处理器添加到容器中
    registerBeanPostProcessors(beanFactory, nonOrderedPostProcessors);

    // Finally, re-register all internal BeanPostProcessors.
    sortPostProcessors(internalPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, internalPostProcessors);

    // Re-register post-processor for detecting inner beans as ApplicationListeners,
    // moving it to the end of the processor chain (for picking up proxies etc).
    // 注册ApplicationListenerDetector处理器, 自动侦测ApplicationListener类
    // 这里再添加一个后置处理器  ApplicationListenerDetector
    // 相当于自动侦测 ApplicationListener 类型的bean
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
}
```

注册beanPostProcessor的操作:

>  org.springframework.context.support.PostProcessorRegistrationDelegate#registerBeanPostProcessors

```java
	private static void registerBeanPostProcessors(
			ConfigurableListableBeanFactory beanFactory, List<BeanPostProcessor> postProcessors) {
		// 遍历后置处理器, 把其注册到容器中
		for (BeanPostProcessor postProcessor : postProcessors) {
			beanFactory.addBeanPostProcessor(postProcessor);
		}
	}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#addBeanPostProcessor

```java
// 添加后置处理器到容器中
@Override
public void addBeanPostProcessor(BeanPostProcessor beanPostProcessor) {
    Assert.notNull(beanPostProcessor, "BeanPostProcessor must not be null");
    // Remove from old position, if any
    // 先进行了移除,以防已经存在
    this.beanPostProcessors.remove(beanPostProcessor);
    // Track whether it is instantiation/destruction aware
   // 记录是否注册有 InstantiationAwareBeanPostProcessor  DestructionAwareBeanPostProcessor 这两个处理器
    if (beanPostProcessor instanceof InstantiationAwareBeanPostProcessor) {
        this.hasInstantiationAwareBeanPostProcessors = true;
    }
    if (beanPostProcessor instanceof DestructionAwareBeanPostProcessor) {
        this.hasDestructionAwareBeanPostProcessors = true;
    }
    // Add to end of list
    // 最后把处理器放到容器中
    this.beanPostProcessors.add(beanPostProcessor);
}
```

## refersh-->initMessageSource

```java
protected void initMessageSource() {
    // 获取beanFactory
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    // 查看beanFactory中有没有messageSource 类型的bean
    if (beanFactory.containsLocalBean(MESSAGE_SOURCE_BEAN_NAME)) {
        // 有,则进行初始化
        this.messageSource = beanFactory.getBean(MESSAGE_SOURCE_BEAN_NAME, MessageSource.class);
        // Make MessageSource aware of parent MessageSource.
        // 后去parent source
        if (this.parent != null && this.messageSource instanceof HierarchicalMessageSource) {
            HierarchicalMessageSource hms = (HierarchicalMessageSource) this.messageSource;
            if (hms.getParentMessageSource() == null) {
                // Only set parent context as parent MessageSource if no parent MessageSource
                // registered already.
                hms.setParentMessageSource(getInternalParentMessageSource());
            }
        }
        if (logger.isTraceEnabled()) {
            logger.trace("Using MessageSource [" + this.messageSource + "]");
        }
    }
    else {
        // Use empty MessageSource to be able to accept getMessage calls.
        // 如果 beanFactory中没有 messageSource
        // 则创建一个 DelegatingMessageSource 实例
        DelegatingMessageSource dms = new DelegatingMessageSource();
        dms.setParentMessageSource(getInternalParentMessageSource());
        this.messageSource = dms;
        beanFactory.registerSingleton(MESSAGE_SOURCE_BEAN_NAME, this.messageSource);
        if (logger.isTraceEnabled()) {
     logger.trace("No '" + MESSAGE_SOURCE_BEAN_NAME + "' bean, using [" + this.messageSource + "]");
        }
    }
}
```



## refresh-->initApplicationEventMulticaster

```java
				// Initialize event multicaster for this context.
				// 第八步  为此上下文初始化 事件多播器
				initApplicationEventMulticaster();
```

> org.springframework.context.support.AbstractApplicationContext#initApplicationEventMulticaster

```java
// 初始化applicationEventMulticaster, 如果容器中已经存在,则使用容器中的
// 如果没有存在,则使用SimpleApplicationEventMulticaster
protected void initApplicationEventMulticaster() {
    // 获取beanFactory
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    // 查看容器中是否有 applicationEventMulticaster 类型的bean
    if (beanFactory.containsLocalBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME)) {
        // 如果存在,则实例化
        this.applicationEventMulticaster =
            beanFactory.getBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
        if (logger.isTraceEnabled()) {
       logger.trace("Using ApplicationEventMulticaster [" + this.applicationEventMulticaster + "]");
        }
    }
    else {
        // 如果不存在,则创建一个SimpleApplicationEventMulticaster, 并注册到 容器中
        this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
        beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this.applicationEventMulticaster);
        if (logger.isTraceEnabled()) {
            logger.trace("No '" + APPLICATION_EVENT_MULTICASTER_BEAN_NAME + "' bean, using " +
                         "[" + this.applicationEventMulticaster.getClass().getSimpleName() + "]");
        }
    }
}
```

## refresh-->onRefresh

```java
// 第九步  此主要用于子类进行扩展
onRefresh();
```

在webApp中有使用到，在springboot中也有使用到此方法。

## refresh --> registerListeners

```java
// 第十步  注册监听器
registerListeners();
```

> org.springframework.context.support.AbstractApplicationContext#registerListeners

```java
// 注册监听器
protected void registerListeners() {
    // Register statically specified listeners first.
    for (ApplicationListener<?> listener : getApplicationListeners()) {
        getApplicationEventMulticaster().addApplicationListener(listener);
    }

    // 把容器中注册的applicationListener 注册到 多播器中
    // Do not initialize FactoryBeans here: We need to leave all regular beans
    // uninitialized to let post-processors apply to them!
    String[] listenerBeanNames = getBeanNamesForType(ApplicationListener.class, true, false);
    for (String listenerBeanName : listenerBeanNames) {
        getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
    }

    // 发布earlyApplicationEvents 事件
    // Publish early application events now that we finally have a multicaster...
    // 此earlyApplicationEvents 是在 refresh开始时就创建的一个容器,用于存储创建期间发布的事件
    Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
    this.earlyApplicationEvents = null;
    // 如果有事件,则现在把事件发送到 listener
    if (earlyEventsToProcess != null) {
        for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
            getApplicationEventMulticaster().multicastEvent(earlyEvent);
        }
    }
}
```

## refresh --> finishBeanFactoryInitialization

```java
// 第十一步 重点  重点  重点
// 此方法会实例化所有的非懒加载的bean
finishBeanFactoryInitialization(beanFactory);
```

> org.springframework.context.support.AbstractApplicationContext#finishBeanFactoryInitialization

```java
// 初始化所有的单例bean
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    // Initialize conversion service for this context.
    // 设置容器的 conversionService, 也就是前端参数到controller参数的转换,例如:前端传递的字符串转换为date
    if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME) &&
        beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
        beanFactory.setConversionService(
            beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
    }

    // Register a default embedded value resolver if no bean post-processor
    // (such as a PropertyPlaceholderConfigurer bean) registered any before:
    // at this point, primarily for resolution in annotation attribute values.
    if (!beanFactory.hasEmbeddedValueResolver()) {
        beanFactory.addEmbeddedValueResolver(strVal -> getEnvironment().resolvePlaceholders(strVal));
    }

    // Initialize LoadTimeWeaverAware beans early to allow for registering their transformers early.
    String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
    for (String weaverAwareName : weaverAwareNames) {
        getBean(weaverAwareName);
    }

    // Stop using the temporary ClassLoader for type matching.
    beanFactory.setTempClassLoader(null);

    // Allow for caching all bean definition metadata, not expecting further changes.
    // 设置标志位, 表示不允许再进行修改
    beanFactory.freezeConfiguration();

    // Instantiate all remaining (non-lazy-init) singletons.
    // 初始化单例bean
    beanFactory.preInstantiateSingletons();
}
```

此方法又是此函数的灵魂，篇幅比较大，咱们先接着分析其他函数，此函数单独一篇进行分析。



## refresh --> finishRefresh

```java
// 完成refresh
// 第十二步
// LifeCycle 的调用在这里
finishRefresh();
```

> org.springframework.context.support.AbstractApplicationContext#finishRefresh

```java
protected void finishRefresh() {
		// 清楚资源缓存
		// Clear context-level resource caches (such as ASM metadata from scanning).
		clearResourceCaches();

		// Initialize lifecycle processor for this context.
		// 此处主要是获取 LifeCycle的处理器
		// 1. 先去容器中获取,也就是说用户可以自定义,如果用户自定义了,则使用用户自己的
		// 2. 如果用户没有自定义处理器,则创建一个默认的DefaultLifecycleProcessor
		initLifecycleProcessor();

		// Propagate refresh to lifecycle processor first.
		// 重新调用一次Lifecycle类型bean的start方法
		//
		getLifecycleProcessor().onRefresh();

		// Publish the final event.
		// 发布一个事件
		publishEvent(new ContextRefreshedEvent(this));

		// Participate in LiveBeansView MBean, if active.
		// MBean 操作
		LiveBeansView.registerApplicationContext(this);
	}
```

> org.springframework.context.support.AbstractApplicationContext#initLifecycleProcessor

```java
// 初始化Lifecycle类型的bean
protected void initLifecycleProcessor() {
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    // 先看容器中是否有 LifeCycle processor(LifeCycle 处理器)
    // 如果容器中已经存在,则使用已经存在的
    if (beanFactory.containsLocalBean(LIFECYCLE_PROCESSOR_BEAN_NAME)) {
        this.lifecycleProcessor =
            beanFactory.getBean(LIFECYCLE_PROCESSOR_BEAN_NAME, LifecycleProcessor.class);
        if (logger.isTraceEnabled()) {
            logger.trace("Using LifecycleProcessor [" + this.lifecycleProcessor + "]");
        }
    }
    else {
        // 如果容器中目前没有 LifeCycle 的处理器,则创建一个默认的: DefaultLifecycleProcessor
        DefaultLifecycleProcessor defaultProcessor = new DefaultLifecycleProcessor();
        // 记录bean工厂到 处理器中
        defaultProcessor.setBeanFactory(beanFactory);
        // 记录处理器
        this.lifecycleProcessor = defaultProcessor;
        // 把处理器注册到容器中
        beanFactory.registerSingleton(LIFECYCLE_PROCESSOR_BEAN_NAME, this.lifecycleProcessor);
        if (logger.isTraceEnabled()) {
            logger.trace("No '" + LIFECYCLE_PROCESSOR_BEAN_NAME + "' bean, using " +
                         "[" + this.lifecycleProcessor.getClass().getSimpleName() + "]");
        }
    }
}
```

> org.springframework.context.support.DefaultLifecycleProcessor#onRefresh

```java
	// 刷新操作，重新调用所有Lifecycle类型的bean的start方法
	// 调用bean的 LifeCycle SmartLifeCycle bean的start方法
	@Override
	public void onRefresh() {
		startBeans(true);
		this.running = true;
	}
```

> org.springframework.context.support.DefaultLifecycleProcessor#startBeans

```java
// 这里其实就是 lifeCycle接口中的 start方法调用
private void startBeans(boolean autoStartupOnly) {
    // 获取所有的Lifecyel类型的bean
    Map<String, Lifecycle> lifecycleBeans = getLifecycleBeans();
    Map<Integer, LifecycleGroup> phases = new HashMap<>();
    // 遍历所有的bean,把bean根据不同的阶段进行分组
    // 对SmartLifeCycle类型的bean的处理
    lifecycleBeans.forEach((beanName, bean) -> {
        if (!autoStartupOnly || (bean instanceof SmartLifecycle && ((SmartLifecycle) bean).isAutoStartup())) {
            // 调用Phased类型bean的 getPhase方法,获取此bean的 phase
            int phase = getPhase(bean);
            LifecycleGroup group = phases.get(phase);
            if (group == null) {
                /*
					this.phase = phase;
					this.timeout = timeoutPerShutdownPhase;
					this.lifecycleBeans = lifecycleBeans;
					this.autoStartupOnly = autoStartupOnly;
					 */
                group = new LifecycleGroup(phase, this.timeoutPerShutdownPhase, lifecycleBeans, autoStartupOnly);
                phases.put(phase, group);
            }
            // 把相同的 phase 的bean 放到同一个 group中
            group.add(beanName, bean);
        }
    });
    // 把不同阶段的bean进行排序,并按照顺序进行启动
    if (!phases.isEmpty()) {
        List<Integer> keys = new ArrayList<>(phases.keySet());
        Collections.sort(keys);
        // 调用LifeCycle的start 方法
        for (Integer key : keys) {
            phases.get(key).start();
        }
    }
}
```

事件发布：

> org.springframework.context.support.AbstractApplicationContext#publishEvent

```java
	// 发布事件到所有的listener
	@Override
	public void publishEvent(ApplicationEvent event) {
		publishEvent(event, null);
	}

```

```java
// 发布事件
protected void publishEvent(Object event, @Nullable ResolvableType eventType) {
    Assert.notNull(event, "Event must not be null");

    // Decorate event as an ApplicationEvent if necessary
    ApplicationEvent applicationEvent;
    if (event instanceof ApplicationEvent) {
        applicationEvent = (ApplicationEvent) event;
    }
    else {
        applicationEvent = new PayloadApplicationEvent<>(this, event);
        if (eventType == null) {
            eventType = ((PayloadApplicationEvent) applicationEvent).getResolvableType();
        }
    }
    // Multicast right now if possible - or lazily once the multicaster is initialized
    if (this.earlyApplicationEvents != null) {
        this.earlyApplicationEvents.add(applicationEvent);
    }
    else {
        getApplicationEventMulticaster().multicastEvent(applicationEvent, eventType);
    }

    // Publish event via parent context as well...
    // 如果还有 父容器,则在父容器中也进行事件的分发
    if (this.parent != null) {
        if (this.parent instanceof AbstractApplicationContext) {
            ((AbstractApplicationContext) this.parent).publishEvent(event, eventType);
        }
        else {
            this.parent.publishEvent(event);
        }
    }
}
```

> org.springframework.context.event.SimpleApplicationEventMulticaster#multicastEvent

```java
// 调用容器中的监听器(ApplicationListener)对事件进行处理
@Override
public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
    // 解析事件类型
    ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
    // 获取所有的listener 来对事件进行处理
    for (final ApplicationListener<?> listener : getApplicationListeners(event, type)) {
        // 获取线程池
        Executor executor = getTaskExecutor();
        // 如果有线程池,则在线程池中进行事件的处理
        if (executor != null) {
            executor.execute(() -> invokeListener(listener, event));
        }
        else {
            // 调用监听器
            // 如果没有线程池,则在当前线程中进行 事件的处理
            invokeListener(listener, event);
        }
    }
}
```



## refresh --> destroyBeans

```java
// 第十三步 Destroy already created singletons to avoid dangling resources.
destroyBeans();
```

> org.springframework.context.support.AbstractApplicationContext#destroyBeans

```java
	// 销毁单例
	@Override
	public void destroySingletons() {
		super.destroySingletons();
		this.manualSingletonNames.clear();
		clearByTypeCache();
	}
```

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#destroySingletons

```java
// 销毁单例
public void destroySingletons() {
    if (logger.isTraceEnabled()) {
        logger.trace("Destroying singletons in " + this);
    }
    // 标注当前状态是正在销毁
    synchronized (this.singletonObjects) {
        this.singletonsCurrentlyInDestruction = true;
    }

    String[] disposableBeanNames;
    // 得到有销毁方法的bean的名字
    synchronized (this.disposableBeans) {
        disposableBeanNames = StringUtils.toStringArray(this.disposableBeans.keySet());
    }
    for (int i = disposableBeanNames.length - 1; i >= 0; i--) {
        destroySingleton(disposableBeanNames[i]);
    }
    // 把容器清空
    this.containedBeanMap.clear();
    this.dependentBeanMap.clear();
    this.dependenciesForBeanMap.clear();

    clearSingletonCache();
}


public void destroySingleton(String beanName) {
    // Remove a registered singleton of the given name, if any.
    //  从缓存中移除beanName
    removeSingleton(beanName);

    // Destroy the corresponding DisposableBean instance.
    DisposableBean disposableBean;
    synchronized (this.disposableBeans) {
        disposableBean = (DisposableBean) this.disposableBeans.remove(beanName);
    }
    // 销毁bean以及其依赖的bean
    destroyBean(beanName, disposableBean);
}
```

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#destroyBean

```java
// destroy bean; 但是在销毁bean之前先销毁其依赖的bean
protected void destroyBean(String beanName, @Nullable DisposableBean bean) {
    // Trigger destruction of dependent beans first...
    Set<String> dependencies;
    synchronized (this.dependentBeanMap) {
        // Within full synchronization in order to guarantee a disconnected Set
        // 返回值为其依赖的bean
        dependencies = this.dependentBeanMap.remove(beanName);
    }
    // 如果有依赖的bean,则把依赖的bean也进行销毁
    if (dependencies != null) {
        if (logger.isTraceEnabled()) {
            logger.trace("Retrieved dependent beans for bean '" + beanName + "': " + dependencies);
        }
        for (String dependentBeanName : dependencies) {
            destroySingleton(dependentBeanName);
        }
    }
    // Actually destroy the bean now...
    if (bean != null) {
        try {
            // 调用其 销毁方法
            bean.destroy();
        }
        catch (Throwable ex) {
            if (logger.isInfoEnabled()) {
          logger.info("Destroy method on bean with name '" + beanName + "' threw an exception", ex);
            }
        }
    }

    // Trigger destruction of contained beans...
    Set<String> containedBeans;
    synchronized (this.containedBeanMap) {
        // Within full synchronization in order to guarantee a disconnected Set
        // 得到要销毁bean包含的其他bean，并销毁
        containedBeans = this.containedBeanMap.remove(beanName);
    }
    if (containedBeans != null) {
        for (String containedBeanName : containedBeans) {
            destroySingleton(containedBeanName);
        }
    }

    // Remove destroyed bean from other beans' dependencies.
    synchronized (this.dependentBeanMap) {
        for (Iterator<Map.Entry<String, Set<String>>> it = this.dependentBeanMap.entrySet().iterator(); it.hasNext();) {
            Map.Entry<String, Set<String>> entry = it.next();
            Set<String> dependenciesToClean = entry.getValue();
            dependenciesToClean.remove(beanName);
            if (dependenciesToClean.isEmpty()) {
                it.remove();
            }
        }
    }

    // Remove destroyed bean's prepared dependency information.
    this.dependenciesForBeanMap.remove(beanName);
}
```

## refresh --> cancelRefresh

> org.springframework.context.support.AbstractApplicationContext#cancelRefresh

```java
	protected void cancelRefresh(BeansException ex) {
		this.active.set(false);
	}
```













