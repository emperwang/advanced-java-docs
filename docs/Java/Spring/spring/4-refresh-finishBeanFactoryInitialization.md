[TOC]

# refresh -- finishBeanFactoryInitialization

上一篇分析时，把函数finishBeanFactoryInitialization开了一个头，没有分析完，本篇来单独分析一下此函数，并且看看为什么此函数成为refresh的灵魂。

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
    // waverAware 相关的配置,此处不表
    String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
    for (String weaverAwareName : weaverAwareNames) {
        getBean(weaverAwareName);
    }

    // Stop using the temporary ClassLoader for type matching.
    // 清空临时加载器
    beanFactory.setTempClassLoader(null);

    // Allow for caching all bean definition metadata, not expecting further changes.
    // 设置标志位, 表示不允许再进行修改
    beanFactory.freezeConfiguration();

    // Instantiate all remaining (non-lazy-init) singletons.
    // 初始化单例bean
    beanFactory.preInstantiateSingletons();
}

@Override
public void freezeConfiguration() {
    this.configurationFrozen = true;
    this.frozenBeanDefinitionNames = StringUtils.toStringArray(this.beanDefinitionNames);
}

```

> org.springframework.beans.factory.support.DefaultListableBeanFactory#preInstantiateSingletons

```java
// 实例化单例的前奏
@Override
public void preInstantiateSingletons() throws BeansException {
    if (logger.isTraceEnabled()) {
        logger.trace("Pre-instantiating singletons in " + this);
    }

    // Iterate over a copy to allow for init methods which in turn register new bean definitions.
    // While this may not be part of the regular factory bootstrap, it does otherwise work fine.
    // 得到所有的beanDefinition的名字
    List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);

    // Trigger initialization of all non-lazy singleton beans...
    // 遍历所有beanDefinition的name 来进行bean的实例化
    for (String beanName : beanNames) {
        // getMergedLocalBeanDefinition 把子bean和parent bean的属性等信息进行合并
        RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
        // 如果此bean 不是抽象类、 是单例、 不是懒加载; 则进行下面的动作
        if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
            // 如果bean是factorybean
            if (isFactoryBean(beanName)) {
                // 如果是factryBean,那么获取bean时,就需要添加&前缀
                Object bean = getBean(FACTORY_BEAN_PREFIX + beanName);
                // 如果是factorybean,则进行强转, 然后嗲用FactoryBean的isEagerInit方法
                if (bean instanceof FactoryBean) {
                    final FactoryBean<?> factory = (FactoryBean<?>) bean;
                    boolean isEagerInit;
                    if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
                        // 此bean是否需要 eager 初始化
                        // 如果需要,则会调用工厂方法,获取实例
                        isEagerInit = AccessController.doPrivileged((PrivilegedAction<Boolean>)
                       ((SmartFactoryBean<?>) factory)::isEagerInit, getAccessControlContext());
                    }
                    else {
                        isEagerInit = (factory instanceof SmartFactoryBean &&
                                       ((SmartFactoryBean<?>) factory).isEagerInit());
                    }
                    // 如果需要eager 初始化,则实例化bean
                    if (isEagerInit) {
                        // 如果急需初始化,则从容器中获取,也就是实例化bean
                        getBean(beanName);
                    }
                }
            }
            else {
                // 如果不是factorybean,则直接从容器中获取
                // getBean操作,就是对bean的初始化
                getBean(beanName);
            }
        }
    }

    // Trigger post-initialization callback for all applicable beans...
    // 对于创建好的各个单例对象,判断类型是否是SmartInitializingSingleton
    // 如果是,那么调用其afterSingletonsInstantiated方法,进行一些特定的操作
    // 如果不是此类型,则do nothing
    for (String beanName : beanNames) {
        Object singletonInstance = getSingleton(beanName);
        if (singletonInstance instanceof SmartInitializingSingleton) {
            final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
            if (System.getSecurityManager() != null) {
                AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
                    smartSingleton.afterSingletonsInstantiated();
                    return null;
                }, getAccessControlContext());
            }
            else {
                smartSingleton.afterSingletonsInstantiated();
            }
        }
    }
}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#getMergedLocalBeanDefinition

```java
// 获取一个 rootBeanDefinition, 会把参数中指定的beanName对应的beanDefinition和其parent beanDefinition进行属性的合并
protected RootBeanDefinition getMergedLocalBeanDefinition(String beanName) throws BeansException {
    // Quick check on the concurrent map first, with minimal locking.
    RootBeanDefinition mbd = this.mergedBeanDefinitions.get(beanName);
    if (mbd != null) {
        return mbd;
    }
    // 获取一个 rootBeanDefinition, 会把参数中指定的beanName对应的beanDefinition和其parent beanDefinition进行属性的合并
    return getMergedBeanDefinition(beanName, getBeanDefinition(beanName));
}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#getMergedBeanDefinition

```java
	// 获取一个 rootBeanDefinition, 会把参数中指定的bd和bd的parent beanDefinition进行属性的合并
	protected RootBeanDefinition getMergedBeanDefinition(String beanName, BeanDefinition bd)
			throws BeanDefinitionStoreException {

		return getMergedBeanDefinition(beanName, bd, null);
	}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#getMergedBeanDefinition

```java
protected RootBeanDefinition getMergedBeanDefinition(
    String beanName, BeanDefinition bd, @Nullable BeanDefinition containingBd)
    throws BeanDefinitionStoreException {

    synchronized (this.mergedBeanDefinitions) {
        RootBeanDefinition mbd = null;

        // Check with full lock now in order to enforce the same merged instance.
        if (containingBd == null) {
            mbd = this.mergedBeanDefinitions.get(beanName);
        }
        // mergedBeanDefinitions中不存在此beanName对应的合并的beanDefinition
        if (mbd == null) {
            // 此beanDefinition 没有父 beanDefinition
            if (bd.getParentName() == null) {
                // Use copy of given root bean definition.
                // 如果是 rootBeanDefinition,则直接拷贝一份
                if (bd instanceof RootBeanDefinition) {
                    mbd = ((RootBeanDefinition) bd).cloneBeanDefinition();
                }
                else {
                    // 不是RootBeanDefinition,则包装一下
                    mbd = new RootBeanDefinition(bd);
                }
            }
            else {
                // Child bean definition: needs to be merged with parent.
                // 存在 父的rootBeanDefinition
                BeanDefinition pbd;
                try {
                    // 从别名中 获取真正的beanName
                    String parentBeanName = transformedBeanName(bd.getParentName());
                    if (!beanName.equals(parentBeanName)) {
                        pbd = getMergedBeanDefinition(parentBeanName);
                    }
                    else {
                        // 如果存在父容器,则回去父容器中进行查找parentBeanName
                        BeanFactory parent = getParentBeanFactory();
                        if (parent instanceof ConfigurableBeanFactory) {
                            pbd = ((ConfigurableBeanFactory) parent).getMergedBeanDefinition(parentBeanName);
                        }
                        else {
                            throw new NoSuchBeanDefinitionException(parentBeanName,
     "Parent name '" + parentBeanName + "' is equal to bean name '" + beanName + "': cannot be resolved without an AbstractBeanFactory parent");
                        }
                    }
                }
                catch (NoSuchBeanDefinitionException ex) {
                    throw new BeanDefinitionStoreException(bd.getResourceDescription(), beanName,
"Could not resolve parent bean definition '" + bd.getParentName() + "'", ex);
                }
                // Deep copy with overridden values.
                mbd = new RootBeanDefinition(pbd);
                // 把bd中的配置 设置到 mbd
                // 重点  重点 重点
                // 此才是 mdb的合并操作
                mbd.overrideFrom(bd);
            }

            // Set default singleton scope, if not configured before.
            if (!StringUtils.hasLength(mbd.getScope())) {
                mbd.setScope(RootBeanDefinition.SCOPE_SINGLETON);
            }

            // A bean contained in a non-singleton bean cannot be a singleton itself.
            // Let's correct this on the fly here, since this might be the result of
            // parent-child merging for the outer bean, in which case the original inner bean
            // definition will not have inherited the merged outer bean's singleton status.
            if (containingBd != null && !containingBd.isSingleton() && mbd.isSingleton()) {
                mbd.setScope(containingBd.getScope());
            }

            // Cache the merged bean definition for the time being
            // (it might still get re-merged later on in order to pick up metadata changes)
            if (containingBd == null && isCacheBeanMetadata()) {
                // 记录创建的rootBeanDefinition
                this.mergedBeanDefinitions.put(beanName, mbd);
            }
        }
        // 返回合并后的mdb
        return mbd;
    }
}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#getBean

```java
	// 获取bean
	@Override
	public Object getBean(String name) throws BeansException {
		return doGetBean(name, null, null, false);
	}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#doGetBean

```java
// 先从缓存中获取bean,如果没有就创建
@SuppressWarnings("unchecked")
protected <T> T doGetBean(final String name, @Nullable final Class<T> requiredType,
                          @Nullable final Object[] args, boolean typeCheckOnly) throws BeansException {
    /**
		 * 此处的transformedBeanName 解析bean的别名
		 */
    final String beanName = transformedBeanName(name);
    Object bean;

    // Eagerly check singleton cache for manually registered singletons.
    /**
		 * getSingleton去单例缓存池中获取对象
		 * 当然第一次从 单例池中来获取,肯定是不存在的
		 */
    Object sharedInstance = getSingleton(beanName);
    if (sharedInstance != null && args == null) {
        if (logger.isTraceEnabled()) {
            // 此bean是否正在创建中
            if (isSingletonCurrentlyInCreation(beanName)) {
                logger.trace("Returning eagerly cached instance of singleton bean '" + beanName +
                             "' that is not fully initialized yet - a consequence of a circular reference");
            }
            else {
                logger.trace("Returning cached instance of singleton bean '" + beanName + "'");
            }
        }
        // 如果要获取的bean是null对象,则直接返回
        // 如果bean对应的对象是FactoryBean,则调用工厂方法获取对象
        // 如果mdb为null,则尝试从容器中获取此FactoryBean的实例来创建对象
        bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
    }

    else {
        // Fail if we're already creating this bean instance:
        // We're assumably within a circular reference.
        /**
			 *  检测是否是循环创建
			 */
        if (isPrototypeCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(beanName);
        }

        // Check if bean definition exists in this factory.
        // 获取父容器
        BeanFactory parentBeanFactory = getParentBeanFactory();
        // 如果存在父容器,则当前容器不包括要查找的bean,则从父容器中进行查找
        if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
            // Not found -> check parent.
            // 获取bean的真实名字
            String nameToLookup = originalBeanName(name);
            if (parentBeanFactory instanceof AbstractBeanFactory) {
                // 从父容器中获取对象
                return ((AbstractBeanFactory) parentBeanFactory).doGetBean(
                    nameToLookup, requiredType, args, typeCheckOnly);
            }
            else if (args != null) {
                // Delegation to parent with explicit args.
                // 如果有参数,也委托父容器进行查找
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            }
            else if (requiredType != null) {
                // No args -> delegate to standard getBean method.
                // 如果有对应的类型, 同样委托父容器进行查找
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
            else {
                return (T) parentBeanFactory.getBean(nameToLookup);
            }
        }
        // 记录当前bean到alreadyCreated容器中
        if (!typeCheckOnly) {
            markBeanAsCreated(beanName);
        }

        try {
            /**
				 *  获取要创建的bean的BeanDefinition
				 */
            final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            // 检测是否是抽象类
            checkMergedBeanDefinition(mbd, beanName, args);

            // Guarantee initialization of beans that the current bean depends on.
            /**
				 *  获取要创建类的 dependOn类，然后先去创建dependOn类
				 */
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                for (String dep : dependsOn) {
                    if (isDependent(beanName, dep)) {
                        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                                        "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                    }
                    // 把此bean的依赖bean 关系注册到容器中
                    registerDependentBean(dep, beanName);
                    try {
                        // 去创建dependOn类
                        getBean(dep);
                    }
                    catch (NoSuchBeanDefinitionException ex) {
                        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                                        "'" + beanName + "' depends on missing bean '" + dep + "'", ex);
                    }
                }
            }

            // Create bean instance.
            // 如果是 单例对象
            // ************************单例 类的创建*********************************
            // 单例每次会创建完成后,会放在单例池中一份,用于以后再用
            if (mbd.isSingleton()) {
                // 创建此单例对象
                // 重点 重点 重点
                sharedInstance = getSingleton(beanName, () -> {
                    try {
                        // 真正创建bean的地方
                        // 重点 重点 重点
                        return createBean(beanName, mbd, args);
                    }
                    catch (BeansException ex) {
                 // Explicitly remove instance from singleton cache: It might have been put there
                 // eagerly by the creation process, to allow for circular reference resolution.
                        // Also remove any beans that received a temporary reference to the bean.
                        destroySingleton(beanName);
                        throw ex;
                    }
                });
                // 真正从factoryBean获取实例的方法
                bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            }
            // 原型创建
            // ************************原型 类的创建*********************************
            // 原型类的创建 每次都会进行创建
            else if (mbd.isPrototype()) {
                // It's a prototype -> create a new instance.
                Object prototypeInstance = null;
                try {
                    // 创建前的操作
                    beforePrototypeCreation(beanName);
                    // 1. 创建bean实例
                    // 2. 组装bean的field
                    // 3. 调用postProcessor
                    prototypeInstance = createBean(beanName, mbd, args);
                }
                finally {
                    // 创建后的操作
                    afterPrototypeCreation(beanName);
                }
                // 如果上面创建的prototypeInstance是一个工厂,则调用此工厂来获取最终要得到的bean
                bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            }

            else {
                // ************************scope 类的创建*********************************
                // 从beanDefinition获取此bean的scope
                String scopeName = mbd.getScope();
                // 如果不存在设置的scope,则报错
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
         throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                }
                try {
                   // scope 每次获取bean,先从scope中获取
                    // scope中不存在时,则调用工厂方法,创建bean
                    Object scopedInstance = scope.get(beanName, () -> {
                        beforePrototypeCreation(beanName);
                        try {
                            return createBean(beanName, mbd, args);
                        }
                        finally {
                            afterPrototypeCreation(beanName);
                        }
                    });
                    // 如果创建的实例是工厂类,则从工厂类中获取实例
                    bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                }
                catch (IllegalStateException ex) {
                    throw new BeanCreationException(beanName,
"Scope '" + scopeName + "' is not active for the current thread; consider " + "defining a scoped proxy for this bean if you intend to refer to it from a singleton",ex);
                }
            }
        }
        catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }

    // Check if required type matches the type of the actual bean instance.
    // 如果指定了类型呢,就对创建好的bean进行一次 类型转换,转换失败呢, 也会报错
    if (requiredType != null && !requiredType.isInstance(bean)) {
        try {
            T convertedBean = getTypeConverter().convertIfNecessary(bean, requiredType);
            if (convertedBean == null) {
                throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
            }
            return convertedBean;
        }
        catch (TypeMismatchException ex) {
            if (logger.isTraceEnabled()) {
                logger.trace("Failed to convert bean '" + name + "' to required type '" +
                             ClassUtils.getQualifiedName(requiredType) + "'", ex);
            }
            throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
        }
    }
    return (T) bean;
}
```

由上面可知，对类的创建时大体顺序：

1. 先去单例池中获取，如果存在且不是工厂类，则返回；如果是工厂类，则调用工厂类来获取实例
2. 如果存在父容器，则去父容器中查找
3. 如果此bean存在依赖，则先实例化依赖bean
4. 对于 单例 bean的创建
5. 对于 原型bean的创建
6. 对于 scope bean的创建

对于下面的单例类，原型类，scope类创建bean的方法都比较类似，之后后续的处理有些许差异；

1. 单例创建好之后会放入到单例池中
2. 原型类创建好之后则不会放入到单例吃中。
3. scope类型bean每次都先从scope中获取，如果不存在则会进行创建
4. 对于每次创建完的bean实例，都会检测器是否是factoryBean，如果是呢则会调用其工程方法类创建具体类。
5. 如果指定了requireType，在最后则会进行一次类型转换

> org.springframework.beans.factory.support.AbstractBeanFactory#transformedBeanName

```java
// 对beanName的一些转换
protected String transformedBeanName(String name) {
    return canonicalName(BeanFactoryUtils.transformedBeanName(name));
}


// 对bean的名字进行一下转换
// 如果不是&开头的factoryBean的名字,直接返回
// 如果是 & 开头的name,则去除此& 符号
public static String transformedBeanName(String name) {
    Assert.notNull(name, "'name' must not be null");
    // 如果beanName不是以 & 开头,则直接返回
    if (!name.startsWith(BeanFactory.FACTORY_BEAN_PREFIX)) {
        return name;
    }
    // 如果beanName是以& 开头的,则把此 & 开头去除
    return transformedBeanNameCache.computeIfAbsent(name, beanName -> {
        do {
            beanName = beanName.substring(BeanFactory.FACTORY_BEAN_PREFIX.length());
        }
        while (beanName.startsWith(BeanFactory.FACTORY_BEAN_PREFIX));
        return beanName;
    });
}



// 从别名获取到真实的名字
public String canonicalName(String name) {
    String canonicalName = name;
    // Handle aliasing...
    String resolvedName;
    do {
        resolvedName = this.aliasMap.get(canonicalName);
        if (resolvedName != null) {
            canonicalName = resolvedName;
        }
    }
    while (resolvedName != null);
    return canonicalName;
}
```

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#getSingleton

```java
	// 获取一个单例
	@Override
	@Nullable
	public Object getSingleton(String beanName) {
		return getSingleton(beanName, true);
	}
```

```java
// 获取单里的方法
// 1. 先从单例池中获取,池中有,则直接返回
// 2. 单例池中没有, 则尝试此 beanname是否是工厂类, 如果是工厂类,则使用工厂类创建一个实例
// 工厂类创建完实例后,会删除此工厂类
@Nullable
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    // this.singletonObjects单例缓存池，从此缓存池中获取对象
    Object singletonObject = this.singletonObjects.get(beanName);
    // 单例缓存池中没有,且此beanName对应的bean正在创建中
    if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
        synchronized (this.singletonObjects) {
            // 那么就尝试从earlySingletonObjects中获取
            singletonObject = this.earlySingletonObjects.get(beanName);
         // 如果earlySingletonObjects 中没有,且allowEarlyReference为true,那么就尝试使用是否有对应的工厂类
            if (singletonObject == null && allowEarlyReference) {
                // 得到beanName对应的工厂类
                ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
                // 如果存在工厂类,那么就使用工厂类进行创建
                if (singletonFactory != null) {
                    singletonObject = singletonFactory.getObject();
                    // 把创建好的实例放到单例缓存池中
                    this.earlySingletonObjects.put(beanName, singletonObject);
                    // 把工厂类移除
                    this.singletonFactories.remove(beanName);
                }
            }
        }
    }
    return singletonObject;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#getObjectForBeanInstance

```java
	@Override
	protected Object getObjectForBeanInstance(
			Object beanInstance, String name, String beanName, @Nullable RootBeanDefinition mbd) {
		// 获取当前正在创建的bean
		String currentlyCreatedBean = this.currentlyCreatedBean.get();
		if (currentlyCreatedBean != null) {
			registerDependentBean(beanName, currentlyCreatedBean);
		}
		return super.getObjectForBeanInstance(beanInstance, name, beanName, mbd);
	}
```

> org.springframework.beans.factory.support.AbstractBeanFactory#getObjectForBeanInstance

```java
// 从beanInstance中获取对象, 也就是说如果bean已经实例化,则直接返回
// 如果此bean是factoryBean,则从容器中获取此factoryBean的实例, 并调用其创建对象的方法获取对象
protected Object getObjectForBeanInstance(
    Object beanInstance, String name, String beanName, @Nullable RootBeanDefinition mbd) {

    // Don't let calling code try to dereference the factory if the bean isn't a factory.
    // 判断beanname是否是获取factorybean
    if (BeanFactoryUtils.isFactoryDereference(name)) {
        if (beanInstance instanceof NullBean) {
            return beanInstance;
        }
        if (!(beanInstance instanceof FactoryBean)) {
            throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
        }
    }

    // Now we have the bean instance, which may be a normal bean or a FactoryBean.
    // If it's a FactoryBean, we use it to create a bean instance, unless the
    // caller actually wants a reference to the factory.
    // 如果beanInstance实例不是FactoryBean,且name也不是&开头, 则直接返回此实例
    if (!(beanInstance instanceof FactoryBean) || BeanFactoryUtils.isFactoryDereference(name)) {
        return beanInstance;
    }

    Object object = null;
    // 如果beanDefinition 为null,则尝试获取beanName对应的Factorybean
    if (mbd == null) {
        object = getCachedObjectForFactoryBean(beanName);
    }
    if (object == null) {
        // Return bean instance from factory.
        FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
        // Caches object obtained from FactoryBean if it is a singleton.
        if (mbd == null && containsBeanDefinition(beanName)) {
            mbd = getMergedLocalBeanDefinition(beanName);
        }
        boolean synthetic = (mbd != null && mbd.isSynthetic());
        // 从factorybean中获取具体的实体
        object = getObjectFromFactoryBean(factory, beanName, !synthetic);
    }
    return object;
}
```

> org.springframework.beans.factory.support.FactoryBeanRegistrySupport#getObjectFromFactoryBean

```java
// 调用factoryBean来创建bean实例
protected Object getObjectFromFactoryBean(FactoryBean<?> factory, String beanName, boolean shouldPostProcess) {
    if (factory.isSingleton() && containsSingleton(beanName)) {
        synchronized (getSingletonMutex()) {
            // 先看 factoryBean创建的实例缓存中是否已经存在
            Object object = this.factoryBeanObjectCache.get(beanName);
            // 如果不存在,则进行实例的创建
            if (object == null) {
                // 真正从factorybean中获取实例的的动作
                // 重点, 具体创建bean
                object = doGetObjectFromFactoryBean(factory, beanName);
                // Only post-process and store if not put there already during getObject() call above
                // (e.g. because of circular reference processing triggered by custom getBean calls)
                Object alreadyThere = this.factoryBeanObjectCache.get(beanName);
                if (alreadyThere != null) {
                    object = alreadyThere;
                }
                else {
                    if (shouldPostProcess) {
                        if (isSingletonCurrentlyInCreation(beanName)) {
                            // Temporarily return non-post-processed object, not storing it yet..
                            return object;
                        }
                        beforeSingletonCreation(beanName);
                        try {
                            // 对创建的bean调用后置处理器 的 postProcessAfterInitialization方法
                            object = postProcessObjectFromFactoryBean(object, beanName);
                        }
                        catch (Throwable ex) {
throw new BeanCreationException(beanName,"Post-processing of FactoryBean's singleton object failed", ex);
                        }
                        finally {
                            afterSingletonCreation(beanName);
                        }
                    }
                    if (containsSingleton(beanName)) {
                        // 缓存工厂类创建的实例
                        this.factoryBeanObjectCache.put(beanName, object);
                    }
                }
            }
            return object;
        }
    }
    else {
        // 如果此factoryBean不是单例,或者单例缓存池中没有包含此beanName, 那就直接调用factoryBean的getObject创建一个对象
        Object object = doGetObjectFromFactoryBean(factory, beanName);
        if (shouldPostProcess) {
            try {
                object = postProcessObjectFromFactoryBean(object, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(beanName, "Post-processing of FactoryBean's object failed", ex);
            }
        }
        return object;
    }
}
```

> org.springframework.beans.factory.support.FactoryBeanRegistrySupport#doGetObjectFromFactoryBean

```java
// 调用factorybean.getObject方法,真实创建一个bean
private Object doGetObjectFromFactoryBean(final FactoryBean<?> factory, final String beanName)
    throws BeanCreationException {

    Object object;
    try {
        // 调用 工厂类的 getObject 来获取对象
        if (System.getSecurityManager() != null) {
            AccessControlContext acc = getAccessControlContext();
            try {
                object = AccessController.doPrivileged((PrivilegedExceptionAction<Object>) factory::getObject, acc);
            }
            catch (PrivilegedActionException pae) {
                throw pae.getException();
            }
        }
        // 调用factoryBean的getObject方法来后去实例
        else {
            object = factory.getObject();
        }
    }
    catch (FactoryBeanNotInitializedException ex) {
        throw new BeanCurrentlyInCreationException(beanName, ex.toString());
    }
    catch (Throwable ex) {
    throw new BeanCreationException(beanName, "FactoryBean threw exception on object creation", ex);
    }

    // Do not accept a null value for a FactoryBean that's not fully
    // initialized yet: Many FactoryBeans just return null then.
    if (object == null) {
        if (isSingletonCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(
                beanName, "FactoryBean which is currently in creation returned null from getObject");
        }
        object = new NullBean();
    }
    return object;
}
```

可见getObjectForBeanInstance函数对创建的bean或者从单例池中获取的bean，都会检测其是否是factorybean，如果是，则会调用其工厂方法来创建具体的实例并缓存；如果不是呢，则会直接返回创建的bean实例.

看一下单例的具体创建方法:

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#getSingleton

```java
// 获取beanName对应的单例,如果没有则使用singletonFactory创建一个并进行注册
public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
    Assert.notNull(beanName, "Bean name must not be null");
    synchronized (this.singletonObjects) {
        // 尝试从单例缓存池中获取
        Object singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
            // 如果当前单例的状态是正在销毁中,则报错
            if (this.singletonsCurrentlyInDestruction) {
                throw new BeanCreationNotAllowedException(beanName,"Singleton bean creation not allowed while singletons of this factory are in destruction " + "(Do not request a bean from a BeanFactory in a destroy method implementation!)");
            }
            if (logger.isDebugEnabled()) {
                logger.debug("Creating shared instance of singleton bean '" + beanName + "'");
            }
            // 检测是否正在创建中
            // 如果此beanname 正在创建,则同样会报错
            beforeSingletonCreation(beanName);
            boolean newSingleton = false;
            boolean recordSuppressedExceptions = (this.suppressedExceptions == null);
            if (recordSuppressedExceptions) {
                this.suppressedExceptions = new LinkedHashSet<>();
            }
            try {
                /**
					 *  此处的singletonFactory.getObject最终就会调用
					 *  createBean函数， 此函数就是具体创建实例的方法
					 */
                // 创建实例
                // 重点  重点  重点
                // 创建实例
                singletonObject = singletonFactory.getObject();
                newSingleton = true;
            }
            catch (IllegalStateException ex) {
                // Has the singleton object implicitly appeared in the meantime ->
                // if yes, proceed with it since the exception indicates that state.
                singletonObject = this.singletonObjects.get(beanName);
                if (singletonObject == null) {
                    throw ex;
                }
            }
            catch (BeanCreationException ex) {
                if (recordSuppressedExceptions) {
                    for (Exception suppressedException : this.suppressedExceptions) {
                        ex.addRelatedCause(suppressedException);
                    }
                }
                throw ex;
            }
            finally {
                if (recordSuppressedExceptions) {
                    this.suppressedExceptions = null;
                }
                afterSingletonCreation(beanName);
            }
            if (newSingleton) {
                /**
					 *  如果创建好了实例，则把实例放入到容器中
					 */
                // 把创建好的bean实例放到单例缓存池中
                addSingleton(beanName, singletonObject);
            }
        }
        return singletonObject;
    }
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean

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

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean

限于篇幅，本篇就先分析到这里，下面接着doCreateBean来解析分析bean的创建。















































































































