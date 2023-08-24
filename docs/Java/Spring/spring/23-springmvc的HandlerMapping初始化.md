[TOC]

# HandlerMapping的初始化

上一篇分析到dispatcherServlet在进行onRefresh时，会初始化其他的组件，这里就分析一下对HandlerMapping组件的初始化。

回顾：

```java
@Override
protected void onRefresh(ApplicationContext context) {
    initStrategies(context);
}

// 初始化提供服务的组件
protected void initStrategies(ApplicationContext context) {
    initMultipartResolver(context);
    initLocaleResolver(context);
    initThemeResolver(context);
    // 初始化handlerMapping
    initHandlerMappings(context);
    // 初始化HandlerAdapter
    initHandlerAdapters(context);
    // 初始化异常处理器
    // 此处会在此类ExceptionHandlerExceptionResolver中进行如下:
    // 1. controllerAdvice注解的bean的解析
    // 2. requestBodyAdvice  responseBodyAdvice切面
    initHandlerExceptionResolvers(context);
    initRequestToViewNameTranslator(context);
    initViewResolvers(context);
    initFlashMapManager(context);
}
```

具体的初始化操作：

```java
/** Detect all HandlerMappings or just expect "handlerMapping" bean?. */
// 默认 允许先去容器中获取 handlerMapper,此就给了用户去定制机会
private boolean detectAllHandlerMappings = true;

private void initHandlerMappings(ApplicationContext context) {
    this.handlerMappings = null;
    //  默认是自动从容器中进行检测,如果检测成功,那么就使用容器中定义的
    // 看到了,先从容器中检测,所有给了用户一个自定义的选择
    if (this.detectAllHandlerMappings) {
        // Find all HandlerMappings in the ApplicationContext, including ancestor contexts.
        Map<String, HandlerMapping> matchingBeans =
            BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerMapping.class, true, false);
        if (!matchingBeans.isEmpty()) {
            this.handlerMappings = new ArrayList<>(matchingBeans.values());
            // We keep HandlerMappings in sorted order.
            AnnotationAwareOrderComparator.sort(this.handlerMappings);
        }
    }
    else {
        try {
            // 如果不是自动检测,那么就按照名字如容器中获取
            HandlerMapping hm = context.getBean(HANDLER_MAPPING_BEAN_NAME, HandlerMapping.class);
            this.handlerMappings = Collections.singletonList(hm);
        }
        catch (NoSuchBeanDefinitionException ex) {
            // Ignore, we'll add a default HandlerMapping later.
        }
    }
    // Ensure we have at least one HandlerMapping, by registering
    // a default HandlerMapping if no other mappings are found.
    // 如果都没有获取到呢? 那么那个Dispatcher.properties文件中定义的默认的值,就生效了.
    if (this.handlerMappings == null) {
        // 配置默认值
        this.handlerMappings = getDefaultStrategies(context, HandlerMapping.class);
        if (logger.isTraceEnabled()) {
            logger.trace("No HandlerMappings declared for servlet '" + getServletName() +
                         "': using default strategies from DispatcherServlet.properties");
        }
    }
}
```

可以看到呢，这里初始化HandlerMapping顺序：

1. 先去容器中查看此类型的bean有没有，如果有，则使用当前容器中已经存在。默认是允许先去容器中查找的，此就给了用户机会去定制自己的handlerMapping
2. 按照名字取容器中查找
3. 上面两步都没有查找到，则使用默认策略中的类进行初始化并注入到容器中

默认策略bean：

```properties
org.springframework.web.servlet.HandlerMapping=org.springframework.web.servlet.handler.BeanNameUrlHandlerMapping,\
	org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping
```

这里咱们没有指定过，所以是使用默认策略中指定的类，看一下如何初始化默认策略的bean：

> org.springframework.web.servlet.DispatcherServlet#getDefaultStrategies

```java
@SuppressWarnings("unchecked")
protected <T> List<T> getDefaultStrategies(ApplicationContext context, Class<T> strategyInterface) {
    String key = strategyInterface.getName();
    // defaultStrategies此属性,把dispatcher.properties文件中内容加载进来了
    // 此时呢,就获取此key的默认配置
    String value = defaultStrategies.getProperty(key);
    if (value != null) {
        //名字可能有多个,这里吧名字转换为数组
        String[] classNames = StringUtils.commaDelimitedListToStringArray(value);
        List<T> strategies = new ArrayList<>(classNames.length);
        // 遍历默认配置
        // 加载name对应的class,记录下来,并进行返回
        for (String className : classNames) {
            try {
                // 加载类
                Class<?> clazz = ClassUtils.forName(className, DispatcherServlet.class.getClassLoader());
                // 注入到容器中
                // 此返回值 是进行了初始化  属性注入的bean
                Object strategy = createDefaultStrategy(context, clazz);
                strategies.add((T) strategy);
            }
            catch (ClassNotFoundException ex) {
                throw new BeanInitializationException(
                    "Could not find DispatcherServlet's default strategy class [" + className +
                    "] for interface [" + key + "]", ex);
            }
            catch (LinkageError err) {
                throw new BeanInitializationException(
                    "Unresolvable class definition for DispatcherServlet's default strategy class [" +className + "] for interface [" + key + "]", err);
            }
        }
        return strategies;
    }
    else {
        return new LinkedList<>();
    }
}

```

> org.springframework.web.servlet.DispatcherServlet#createDefaultStrategy

```java
protected Object createDefaultStrategy(ApplicationContext context, Class<?> clazz) {
    return context.getAutowireCapableBeanFactory().createBean(clazz);
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean(java.lang.Class<T>)

```java
@Override
@SuppressWarnings("unchecked")
public <T> T createBean(Class<T> beanClass) throws BeansException {
    // Use prototype bean definition, to avoid registering bean as dependent bean.
    RootBeanDefinition bd = new RootBeanDefinition(beanClass);
    bd.setScope(SCOPE_PROTOTYPE);
    bd.allowCaching = ClassUtils.isCacheSafe(beanClass, getBeanClassLoader());
    // 真值创建bean
    return (T) createBean(beanClass.getName(), bd, null);
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean(java.lang.String, org.springframework.beans.factory.support.RootBeanDefinition, java.lang.Object[])

```java
// 创建bean
@Override
protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
    throws BeanCreationException {

    if (logger.isTraceEnabled()) {
        logger.trace("Creating instance of bean '" + beanName + "'");
    }
    RootBeanDefinition mbdToUse = mbd;
    /**
		 * resolveBeanClass 获取bean的全类名,并加载
		 */
    Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        // 设置beanClass
        mbdToUse.setBeanClass(resolvedClass);
    }

    // Prepare method overrides.
    try {
        // 准备哪些需要重载的方法
        mbdToUse.prepareMethodOverrides();
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
         beanName, "Validation of method overrides failed", ex);
    }

    try {
        // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
        // 在这里调用InstantiationAwareBeanPostProcessor这个后置处理器，有可能会创建代理对象
        // 因为到这里换没有创建好bean实例, 故大可能不会创建代理对象,但是可以解析一些切面等信息
        // applyBeanPostProcessorsBeforeInstantiation
        // 这里初始化了 aop的advisor
        Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
        if (bean != null) {
            return bean;
        }
    }
    catch (Throwable ex) {
        throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
                                        "BeanPostProcessor before instantiation of bean failed", ex);
    }

    try {
        /**
			 *  具体创建实例的方法
			 *  1. 调用MergedBeanDefinitionPostProcessor-->postProcessMergedBeanDefinition 进行父子bean信息的合并
			 *
			 *  重点 重点  重点
			 */
        Object beanInstance = doCreateBean(beanName, mbdToUse, args);
        if (logger.isTraceEnabled()) {
            logger.trace("Finished creating instance of bean '" + beanName + "'");
        }
        return beanInstance;
    }
    catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
        // A previously detected exception with proper bean creation context already,
        // or illegal singleton state to be communicated up to DefaultSingletonBeanRegistry.
        throw ex;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
     mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
    }
}
```

这里关于handlerMapping就初始化完了，整体代码看起来还是很清晰的。

最后看一下HandlerMapping的类图：

![](HandlerMapping.png)









