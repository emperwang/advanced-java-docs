[TOC]

# refresh

上篇说到bean的实例化完成，本篇看一下bean的自动注入。

回顾一下上篇：

```java
// 具体创建bean的操作
// 只看一下重点
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    throws BeanCreationException {
.....
    if (instanceWrapper == null) {
        // 如果factoryBeanInstanceCache中不存在，那么就创建一个
        // 重点 重点  重点
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
	......
    try {
        // 此处是为bean的属性进行赋值操作
        // InstantiationAwareBeanPostProcessor后置处理器的调用,postProcessAfterInstantiation在bean实例化的一些操作
        // InstantiationAwareBeanPostProcessor后置处理器postProcessPropertyValues 方法
        // 重点  重点  重点
        populateBean(beanName, mbd, instanceWrapper);
        // 次数就是调用bean的初始化函数,如init-method 指定的方法
        // 调用aware方法
        // 回调BeanPostProcessor的postProcessBeforeInitialization方法
        // 调用初始化方法  先调用InitializingBean  在调用自定义的初始化方法
        // 回调BeanPostProcessor的postProcessAfterInitialization方法
        // 重点 重点  重点
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
	.....

    return exposedObject;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#populateBean

```java
// 对创建的bean的value注入
// 简单说 自动注入
@SuppressWarnings("deprecation")  // for postProcessPropertyValues
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
    // 如果参数中要配置的 bw是null,且beanDefinition中有属性,则报错
    if (bw == null) {
        if (mbd.hasPropertyValues()) {
            throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
        }
        else {
            // Skip property population phase for null instance.
            return;
        }
    }
    boolean continueWithPropertyPopulation = true;
    // 调用beanPostProcessor  InstantiationAwareBeanPostProcessor
    // 实例化后的处理
    // 在这里使用这个后置处理器可以 控制对一个bean是否进行 继续自动注入的操作
    // 重点 重点
    // postProcessAfterInstantiation 对特定的bean返回false,就不会对那个bean进行注入操作
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
                    continueWithPropertyPopulation = false;
                    break;
                }
            }
        }
    }
    if (!continueWithPropertyPopulation) {
        return;
    }

    PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);
    // 通过名字  或者 类型进行属性注入
    if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_NAME || mbd.getResolvedAutowireMode() == AUTOWIRE_BY_TYPE) {
        // 存储要注入的属性 及其 value
        MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
        // Add property values based on autowire by name if applicable.
        // 根据 名字来进行注入的操作
        // 在这里也就是  根据名字取获取要注入的值
        if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_NAME) {
            autowireByName(beanName, mbd, bw, newPvs);
        }
        // Add property values based on autowire by type if applicable.
        // 根据类型来进行注入
        // 也就是根据类型来获取要注入的 value
        if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_TYPE) {
            autowireByType(beanName, mbd, bw, newPvs);
        }
        pvs = newPvs;
    }

    boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
    boolean needsDepCheck = (mbd.getDependencyCheck() != AbstractBeanDefinition.DEPENDENCY_CHECK_NONE);

    PropertyDescriptor[] filteredPds = null;
    if (hasInstAwareBpps) {
        if (pvs == null) {
            pvs = mbd.getPropertyValues();
        }
        // 在此调用后置处理器InstantiationAwareBeanPostProcessor.postProcessPropertyValues
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                // 在这里调用各种后置处理器,进行具体的 field的注入操作
  PropertyValues pvsToUse = ibp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
                if (pvsToUse == null) {
                    if (filteredPds == null) {
      filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
                    }
  pvsToUse = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
                    if (pvsToUse == null) {
                        return;
                    }
                }
                pvs = pvsToUse;
            }
        }
    }
    if (needsDepCheck) {
        if (filteredPds == null) {
            filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
        }
        checkDependencies(beanName, mbd, filteredPds, pvs);
    }
    // 其他属性的注入
    // 最后依然是通过 反射来 进行的value的注入
    if (pvs != null) {
        applyPropertyValues(beanName, mbd, bw, pvs);
    }
}
```

这里总的来说会按照配置的注入方式:(按照名字，按照类型)，来根据注入方式来获取注入的value。

获取注入值：

1. 注入类型 按照名字 --- 获取value时，根据名字获取要注入的value
2. 注入类型 按照类型 --- 获取要注入的value时， 根据类型来获取要注入的value

注入操作：

1. 使用各种后置处理器，如AutowiredAnnotationBeanPostProcessor 处理Autowired value inject 自动注入的操作；来进行各种注解的注入操作
2. 最后一些特殊的会使用其他特定handler来进行注入
3. 最终的注入方式，依然是使用反射



> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#autowireByName

```java
// 按照名字进行属性注入
protected void autowireByName(
    String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {

    String[] propertyNames = unsatisfiedNonSimpleProperties(mbd, bw);
    // 遍历所有的许注入的属性
    for (String propertyName : propertyNames) {
        // 如果容器中存在，则从容器中获取，并注入
        if (containsBean(propertyName)) {
            // 从容器获取 propertyName bean的实例
            Object bean = getBean(propertyName);
            // 记录要注入的属性的名字 以及 其value
            pvs.add(propertyName, bean);
            // 把此bean依赖的bean注入到容器map中
            registerDependentBean(propertyName, beanName);
            if (logger.isTraceEnabled()) {
                logger.trace("Added autowiring by name from bean name '" + beanName +
               "' via property '" + propertyName + "' to bean named '" + propertyName + "'");
            }
        }
        else {
            if (logger.isTraceEnabled()) {
                logger.trace("Not autowiring property '" + propertyName + "' of bean '" + beanName +
                             "' by name: no matching bean found");
            }
        }
    }
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#autowireByType

```java
// 根据类型进行属性的注入
protected void autowireByType(
    String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {
    // 获取类型转换器
    TypeConverter converter = getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }
    // 待注入的beanName
    Set<String> autowiredBeanNames = new LinkedHashSet<>(4);
    // 获取所有需要注入的属性
    String[] propertyNames = unsatisfiedNonSimpleProperties(mbd, bw);
    // 遍历所有需要注入的 property, 去容器中获取值
    for (String propertyName : propertyNames) {
        try {
            PropertyDescriptor pd = bw.getPropertyDescriptor(propertyName);
            // Don't try autowiring by type for type Object: never makes sense,
            // even if it technically is a unsatisfied, non-simple property.
            if (Object.class != pd.getPropertyType()) {
                MethodParameter methodParam = BeanUtils.getWriteMethodParameter(pd);
                // Do not allow eager init for type matching in case of a prioritized post-processor.
                boolean eager = !PriorityOrdered.class.isInstance(bw.getWrappedInstance());
                DependencyDescriptor desc = new AutowireByTypeDependencyDescriptor(methodParam, eager);
                // 解析依赖
                Object autowiredArgument = resolveDependency(desc, beanName, autowiredBeanNames, converter);
                if (autowiredArgument != null) {
                    // 记录property 及其 value
                    pvs.add(propertyName, autowiredArgument);
                }
                for (String autowiredBeanName : autowiredBeanNames) {
                    // 注册此bean依赖的其他bean
                    registerDependentBean(autowiredBeanName, beanName);
                    if (logger.isTraceEnabled()) {
                        logger.trace("Autowiring by type from bean name '" + beanName + "' via property '" + propertyName + "' to bean named '" + autowiredBeanName + "'");
                    }
                }
                autowiredBeanNames.clear();
            }
        }
        catch (BeansException ex) {
            throw new UnsatisfiedDependencyException(mbd.getResourceDescription(), beanName, propertyName, ex);
        }
    }
}
```

这里看一个处理注入的后置处理器的操作：

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
                // 重点  重点 重点
                // 创建要注入的 metadata
                metadata = buildAutowiringMetadata(clazz);
                this.injectionMetadataCache.put(cacheKey, metadata);
            }
        }
    }
    return metadata;
}
```



```java
// 创建自动注入的 metaData
private InjectionMetadata buildAutowiringMetadata(final Class<?> clazz) {
    List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
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
                        logger.info("Autowired annotation should only be used on methods with parameters: " +method);
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
        targetClass = targetClass.getSuperclass();
    }
    while (targetClass != null && targetClass != Object.class);
    // 使用InjectionMetadata 包装clazz 及其对应的 要注入的元素
    return new InjectionMetadata(clazz, elements);
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
        // 遍历所有 field 及其value 进行注入
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
            method.invoke(target, getResourceToInject(target, requestingBeanName));
        }
        catch (InvocationTargetException ex) {
            throw ex.getTargetException();
        }
    }
}
```

可以看到属性输入最终是通过反射来进行了.































