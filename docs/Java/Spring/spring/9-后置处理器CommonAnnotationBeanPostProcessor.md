[TOC]

# CommonAnnotationBeanPostProcessor 处理器

本篇分析一下CommonAnnotationBeanPostProcessor 处理器。老规矩，先看一下类图把：

![](CommonAnnotationBeanPostProcessor.png)

在看一下其初始化类:

```java
public CommonAnnotationBeanPostProcessor() {
    setOrder(Ordered.LOWEST_PRECEDENCE - 3);
    setInitAnnotationType(PostConstruct.class);
    setDestroyAnnotationType(PreDestroy.class);
    // 忽略的资源类型
    ignoreResourceType("javax.xml.ws.WebServiceContext");
}
```

看到初始化类，其实就可以猜想到其肯定是跟PostConstruct和PreDestroy的注解处理有关。

可以看到其是多个处理器的子类，其中常见的有beanPostProcessor，InstantiationAwareBeanPostProcessor，MergedBeanDefinitionPostProcessor，InitDestroyAnnotationBeanPostProcessor，咱们可以按照知道的顺序先看看其具体做了什么工作，其他不了解的先往后放放。

## InstantiationAwareBeanPostProcessor

```java
@Override
public Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) {
    return null;
}

@Override
public boolean postProcessAfterInstantiation(Object bean, String beanName) {
    return true;
}

@Override
public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) {
    InjectionMetadata metadata = findResourceMetadata(beanName, bean.getClass(), pvs);
    try {
        metadata.inject(bean, beanName, pvs);
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Injection of resource dependencies failed", ex);
    }
    return pvs;
}
```

可见在实例化前后，没有做工作。

至于此postProcessProperties 先往后放一下。



## beanPostProcessor

```java
/**
	 * 调用  PreDestroy和PostConstruct注解的方法
	 */
@Override
public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
    // 查找 PreDestroy和PostConstruct注解的方法
    LifecycleMetadata metadata = findLifecycleMetadata(bean.getClass());
    try {
        // 调用方法
        // 在这里调用初始化方法
        metadata.invokeInitMethods(bean, beanName);
    }
    catch (InvocationTargetException ex) {
        throw new BeanCreationException(beanName, "Invocation of init method failed", ex.getTargetException());
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Failed to invoke init method", ex);
    }
    return bean;
}

// 初始化后 看到没做什么工作
@Override
public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
    return bean;
}
```

> org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor#findLifecycleMetadata

```java
// 查找跟生命周期相关的  源数据
private LifecycleMetadata findLifecycleMetadata(Class<?> clazz) {
    if (this.lifecycleMetadataCache == null) {
        // Happens after deserialization, during destruction...
        return buildLifecycleMetadata(clazz);
    }
    // Quick check on the concurrent map first, with minimal locking.
    LifecycleMetadata metadata = this.lifecycleMetadataCache.get(clazz);
    if (metadata == null) {
        synchronized (this.lifecycleMetadataCache) {
            metadata = this.lifecycleMetadataCache.get(clazz);
            if (metadata == null) {
                metadata = buildLifecycleMetadata(clazz);
                this.lifecycleMetadataCache.put(clazz, metadata);
            }
            return metadata;
        }
    }
    return metadata;
}
```

> org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor#buildLifecycleMetadata

```java
// 构建生命周期的 源数据
private LifecycleMetadata buildLifecycleMetadata(final Class<?> clazz) {
    // 初始化方法
    List<LifecycleElement> initMethods = new ArrayList<>();
    // 销毁方法
    List<LifecycleElement> destroyMethods = new ArrayList<>();
    Class<?> targetClass = clazz;

    do {
        final List<LifecycleElement> currInitMethods = new ArrayList<>();
        final List<LifecycleElement> currDestroyMethods = new ArrayList<>();
        // 对目标clas的所有方法进行遍历
        // 查找存在 initAnnotationType注解的方法,此处是PostConstruct
        // 查找存在destroyAnnotationType注解的方法,此处是PreDestroy
        ReflectionUtils.doWithLocalMethods(targetClass, method -> {
            if (this.initAnnotationType != null && method.isAnnotationPresent(this.initAnnotationType)) {
                LifecycleElement element = new LifecycleElement(method);
                currInitMethods.add(element);
                if (logger.isTraceEnabled()) {
                    logger.trace("Found init method on class [" + clazz.getName() + "]: " + method);
                }
            }
            if (this.destroyAnnotationType != null && method.isAnnotationPresent(this.destroyAnnotationType)) {
                currDestroyMethods.add(new LifecycleElement(method));
                if (logger.isTraceEnabled()) {
                    logger.trace("Found destroy method on class [" + clazz.getName() + "]: " + method);
                }
            }
        });
        // 记录initMethod
        initMethods.addAll(0, currInitMethods);
        // 记录 destory method
        destroyMethods.addAll(currDestroyMethods);
        // 获取 目标方法的父类
        // 由此可见,在父类中添加了注解,也是可以检测到的
        targetClass = targetClass.getSuperclass();
    }
    while (targetClass != null && targetClass != Object.class);
    return new LifecycleMetadata(clazz, initMethods, destroyMethods);
}
```

在这里又发现黑科技哦，放这些注解PostConstruct，PreDestroy放在父类上，其实也是可以检测到的。

> org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor.LifecycleMetadata#invokeInitMethods

```java
// 调用初始化方法
public void invokeInitMethods(Object target, String beanName) throws Throwable {
    Collection<LifecycleElement> checkedInitMethods = this.checkedInitMethods;
    Collection<LifecycleElement> initMethodsToIterate =
        (checkedInitMethods != null ? checkedInitMethods : this.initMethods);
    if (!initMethodsToIterate.isEmpty()) {
        for (LifecycleElement element : initMethodsToIterate) {
            if (logger.isTraceEnabled()) {
                logger.trace("Invoking init method on bean '" + beanName + "': " + element.getMethod());
            }
            /**
					 *调用 PostConstruct 注解的方法
 					 */
            element.invoke(target);
        }
    }
}
```

可见在，初始化前先调用了初始化方法。 此类的其他功能，后续发现更多，后续再添加。











































































