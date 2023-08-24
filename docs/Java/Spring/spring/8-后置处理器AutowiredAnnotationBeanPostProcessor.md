[TOC]

# AutowiredAnnotationBeanPostProcessor

本篇分析一下后置处理器AutowiredAnnotationBeanPostProcessor。

先看一下类图：

![](AutowiredAnnotationBeanPostProcessor1.png)



时间点记录:

```shell
# 在这里时间点调用InstantiationAwareBeanPostProcessor.postProcessProperties
# 以及 InstantiationAwareBeanPostProcessor.postProcessPropertyValues
org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#populateBean

# 在下面时间点调用SmartInstantiationAwareBeanPostProcessor.determineCandidateConstructors 来决定使用哪个构造器来创建类实例
org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBeanInstance


# SmartInstantiationAwareBeanPostProcessor.predictBeanType
# 此函数用于从容器获取某种类型的bean
org.springframework.beans.factory.support.DefaultListableBeanFactory#doGetBeanNamesForType


```

也就是populateBean中调用后置处理器进行属性注入。

这里咱们就主要看一下这里，对属性注入的操作。

看一下构造器

```java
// 初始化那些注解 要进行自动注入
@SuppressWarnings("unchecked")
public AutowiredAnnotationBeanPostProcessor() {
    this.autowiredAnnotationTypes.add(Autowired.class);
    this.autowiredAnnotationTypes.add(Value.class);
    try {
        this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
        ClassUtils.forName("javax.inject.Inject", AutowiredAnnotationBeanPostProcessor.class.getClassLoader()));
        logger.trace("JSR-330 'javax.inject.Inject' annotation found and supported for autowiring");
    }
    catch (ClassNotFoundException ex) {
        // JSR-330 API not available - simply skip.
    }
}
```

这里呢，添加了Autowired，Value，Inject注解，表示这些注解是需要进行自动注入的。

继续看一下其注入的操作：

> org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor#postProcessProperties

```java
// 对属性进行注入
@Override
public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) {
    // 查找要注入的原信息  metadata
    InjectionMetadata metadata = findAutowiringMetadata(beanName, bean.getClass(), pvs);
    try {
        // 注入操作
        metadata.inject(bean, beanName, pvs);
    }
    catch (BeanCreationException ex) {
        throw ex;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Injection of autowired dependencies failed", ex);
    }
    return pvs;
}
```

> org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor#findAutowiringMetadata

```java
// 查找此 class 等待注入的element
private InjectionMetadata findAutowiringMetadata(String beanName, Class<?> clazz, @Nullable PropertyValues pvs) {
    // Fall back to class name as cache key, for backwards compatibility with custom callers.
    // key
    String cacheKey = (StringUtils.hasLength(beanName) ? beanName : clazz.getName());
    // Quick check on the concurrent map first, with minimal locking.
    // injectionMetadataCache class 要注入的元素
    InjectionMetadata metadata = this.injectionMetadataCache.get(cacheKey);
    // 不存在  metadata
    if (InjectionMetadata.needsRefresh(metadata, clazz)) {
        synchronized (this.injectionMetadataCache) {
            metadata = this.injectionMetadataCache.get(cacheKey);
            if (InjectionMetadata.needsRefresh(metadata, clazz)) {
                if (metadata != null) {
                    metadata.clear(pvs);
                }
                // 创建要注入的 metadata
                metadata = buildAutowiringMetadata(clazz);
                this.injectionMetadataCache.put(cacheKey, metadata);
            }
        }
    }
    return metadata;
}
```

> org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor#buildAutowiringMetadata

```java
// 创建自动注入的 metaData
private InjectionMetadata buildAutowiringMetadata(final Class<?> clazz) {
    // 存储要进行注入的element
    List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
    // 记录目标类
    Class<?> targetClass = clazz;

    do {
        final List<InjectionMetadata.InjectedElement> currElements = new ArrayList<>();
        // 对targetClass 这个类中的所有field执行操作
        // *********************获取要注入的field***********************************
        ReflectionUtils.doWithLocalFields(targetClass, field -> {
            AnnotationAttributes ann = findAutowiredAnnotation(field);
            if (ann != null) {
                // 静态field 不能注入
                // 重点 注意::  static  field不能进行注入
                if (Modifier.isStatic(field.getModifiers())) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation is not supported on static fields: " + field);
                    }
                    return;
                }
                // 根据注解中的信息,判断此 field 是否是必须注入
                boolean required = determineRequiredStatus(ann);
                // 记录需要注入的field, 并记录了是否是必需的注入
                // 使用一个 AutowiredFieldElement包装要注入的field,以及此field 是否必须注入的
                currElements.add(new AutowiredFieldElement(field, required));
            }
        });
        // 对targetClass中的getDeclaredMethods方法, 查看其是否需要进行注册
        // *********************获取要注入的 method***********************************
        ReflectionUtils.doWithLocalMethods(targetClass, method -> {
            Method bridgedMethod = BridgeMethodResolver.findBridgedMethod(method);
            if (!BridgeMethodResolver.isVisibilityBridgeMethodPair(method, bridgedMethod)) {
                return;
            }
            // 查找要注入的 注解信息
            AnnotationAttributes ann = findAutowiredAnnotation(bridgedMethod);
            if (ann != null && method.equals(ClassUtils.getMostSpecificMethod(method, clazz))) {
                if (Modifier.isStatic(method.getModifiers())) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation is not supported on static methods: " + method);
                    }
                    return;
                }
                // 是否有参数
                if (method.getParameterCount() == 0) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation should only be used on methods with parameters: " + method);
                    }
                }
                // 此注入 是否是 必须的
                boolean required = determineRequiredStatus(ann);
                // 查找要注入的 value
                PropertyDescriptor pd = BeanUtils.findPropertyForMethod(bridgedMethod, clazz);
                currElements.add(new AutowiredMethodElement(method, required, pd));
            }
        });
        // 记录最终需要注入的 原信息
        elements.addAll(0, currElements);
        // 父类的信息也要进行分析
        targetClass = targetClass.getSuperclass();
    }
    while (targetClass != null && targetClass != Object.class);
    // 使用InjectionMetadata 包装clazz 及其对应的 要注入的元素
    return new InjectionMetadata(clazz, elements);
}
```

查找到所有需要注入的field和方法后，下面就该进行注入了。

```java
// 对属性进行注入
@Override
public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) {
    // 查找要注入的原信息  metadata
    InjectionMetadata metadata = findAutowiringMetadata(beanName, bean.getClass(), pvs);
    try {
        // 注入操作
        // 查找到 要注入的信息后,现在开始进行注入操作
        metadata.inject(bean, beanName, pvs);
    }
    catch (BeanCreationException ex) {
        throw ex;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Injection of autowired dependencies failed", ex);
    }
    return pvs;
}
```

> org.springframework.beans.factory.annotation.InjectionMetadata#inject

```java
// value注入的操作
public void inject(Object target, @Nullable String beanName, @Nullable PropertyValues pvs) throws Throwable {
    Collection<InjectedElement> checkedElements = this.checkedElements;
    // 获取要注入的元素 injectedElements 中存储了要注入的元素
    Collection<InjectedElement> elementsToIterate =
        (checkedElements != null ? checkedElements : this.injectedElements);
    if (!elementsToIterate.isEmpty()) {
        for (InjectedElement element : elementsToIterate) {
            if (logger.isTraceEnabled()) {
                logger.trace("Processing injected element of bean '" + beanName + "': " + element);
            }
            // 属性注入
            // 1. field属性注入
            // 2. method属性注入
            element.inject(target, beanName, pvs);
        }
    }
}
```

> org.springframework.beans.factory.annotation.InjectionMetadata.InjectedElement#inject

```java
// 属性注入操作
protected void inject(Object target, @Nullable String requestingBeanName, @Nullable PropertyValues pvs)
    throws Throwable {

    if (this.isField) {
        Field field = (Field) this.member;
        ReflectionUtils.makeAccessible(field);
        // field 反射注入
        // 重点 重点 在这
        field.set(target, getResourceToInject(target, requestingBeanName));
    }
    else {
        if (checkPropertySkipping(pvs)) {
            return;
        }
        try {
            Method method = (Method) this.member;
            ReflectionUtils.makeAccessible(method);
            // 方法的注入
            // 重点 重点 在这
            method.invoke(target, getResourceToInject(target, requestingBeanName));
        }
        catch (InvocationTargetException ex) {
            throw ex.getTargetException();
        }
    }
}
```

此函数的自动注入就完成了。当然其还有其他功能，后续会继续更新。































































































