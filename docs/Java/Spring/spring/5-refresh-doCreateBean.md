[TOC]

# refresh

本篇接着上篇继续分析bean的创建。

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean

```java
// 具体创建bean的操作
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    throws BeanCreationException {

    // Instantiate the bean.
    BeanWrapper instanceWrapper = null;
    // 如果此bean是单例的,而且将要做实例化操作,故把它从factoryBeanInstanceCache移除
    if (mbd.isSingleton()) {
        // 如果beanDefinition 记录了是单例,则把工厂创建的实例 factoryBeanInstanceCache中的实例删除
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }
    if (instanceWrapper == null) {
        // 如果factoryBeanInstanceCache中不存在，那么就创建一个
        // 重点 重点  重点
        // 最后也是调用构造器来创建实例
        // 不过这里可以设置构造器参数, 也就是通过构造器 注入
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
    final Object bean = instanceWrapper.getWrappedInstance();
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        mbd.resolvedTargetType = beanType;
    }

    // Allow post-processors to modify the merged bean definition.
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
					 /* init-method  destory-method
					 * autowired  value 等注解解析的地方
					 */
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                               "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // Eagerly cache singletons to be able to resolve circular references
    // even when triggered by lifecycle interfaces like BeanFactoryAware.
    // 此处是解决循环注入问题
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
                                      isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        if (logger.isTraceEnabled()) {
            logger.trace("Eagerly caching bean '" + beanName +
                         "' to allow for resolving potential circular references");
        }
        // 添加一个singleton的工厂方法
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    }

    // Initialize the bean instance.
    Object exposedObject = bean;
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
    catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        }
        else {
            throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }
    // 如果是要获取获取一个还没有初始化好的单例对象
    if (earlySingletonExposure) {
        // 从单例缓存池和earlySingletonObjects中去获取要得到的bean
        Object earlySingletonReference = getSingleton(beanName, false);
        if (earlySingletonReference != null) {
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            }
            else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
                // 遍历这些依赖,把已经创建好的放到actualDependentBeans
                for (String dependentBean : dependentBeans) { 
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
 "Bean with name '" + beanName + "' has been injected into other beans [" + StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +  "] in its raw version as part of a circular reference, but has eventually been " +"wrapped. This means that said other beans do not use the final version of the " + "bean. This is often the result of over-eager type matching - consider using " + "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }

    // Register bean as disposable.
    try {
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBeanInstance

```java
// 创建bean实例
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {
    // Make sure bean class is actually resolved at this point.
    // 解析此bean的class，并加载
    Class<?> beanClass = resolveBeanClass(mbd, beanName);

    // 如果不是public类则报错
    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                        "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    }
    // 如果有 supplier 提供来提供实例
    // ********************从 supplier 中获取bean的实例************************************
    Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
    if (instanceSupplier != null) {
        // 则从 instanceSupplier 来获取实例
        return obtainFromSupplier(instanceSupplier, beanName);
    }
    // 从工厂方法中创建实例
    // ********************从 工厂方法 中获取bean的实例************************************
    if (mbd.getFactoryMethodName() != null) {
        return instantiateUsingFactoryMethod(beanName, mbd, args);
    }

    // Shortcut when re-creating the same bean...
    boolean resolved = false;
    boolean autowireNecessary = false;
    if (args == null) {
        synchronized (mbd.constructorArgumentLock) {
            if (mbd.resolvedConstructorOrFactoryMethod != null) {
                resolved = true;
                autowireNecessary = mbd.constructorArgumentsResolved;
            }
        }
    }
    // ********************从 带参构造器中 创建bean的实例************************************
    if (resolved) {
        if (autowireNecessary) {
            // 构造器注入参数，然后初始化
            return autowireConstructor(beanName, mbd, null, null);
        }
        else {
            // 使用默认构造器进行初始化
            // ********************从 无参也就是默认构造器创建 bean的实例************************************
            return instantiateBean(beanName, mbd);
        }
    }

    // Candidate constructors for autowiring?
    // ********************使用带参构造器中创建 bean的实例************************************
    Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
    if (ctors != null || mbd.getResolvedAutowireMode() == AUTOWIRE_CONSTRUCTOR ||
        mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args)) {
        // 构造器注入
        // 使用带参数的构造器 来实例化类
        return autowireConstructor(beanName, mbd, ctors, args);
    }

    // Preferred constructors for default construction?
    // 在beanDefinition是否制定了优先使用的构造器,如果制定了,则使用制定的
    // ********************使用带参构造器中创建 bean的实例************************************
    ctors = mbd.getPreferredConstructors();
    if (ctors != null) {
        // 使用带参数的构造器来实例化类
        return autowireConstructor(beanName, mbd, ctors, null);
    }

    // No special handling: simply use no-arg constructor.
    // 使用默认的无参构造器
    // ********************使用 默认的无参 构造器中创建 bean的实例************************************
    return instantiateBean(beanName, mbd);
}
```

可以看到使用多种方法来创建bean的实例，此处咱们看最简单的默认的无参构造函数 来创建bean实例:

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#instantiateBean

```java
	// 使用默认构造器初始化
	protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
		try {
			Object beanInstance;
			final BeanFactory parent = this;
			//使用定义好的bean创建策略来创建bean
			if (System.getSecurityManager() != null) {
				beanInstance = AccessController.doPrivileged((PrivilegedAction<Object>) () ->
						getInstantiationStrategy().instantiate(mbd, beanName, parent),
						getAccessControlContext());
			}
			else {
				// 调用构造方法进行创建
				beanInstance = getInstantiationStrategy().instantiate(mbd, beanName, parent);
			}
			BeanWrapper bw = new BeanWrapperImpl(beanInstance);
			// 注册PropertyEditorRegistry 到beanWrapper
			initBeanWrapper(bw);
			return bw;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
		}
	}
```

> org.springframework.beans.factory.support.SimpleInstantiationStrategy#instantiate

```java

// 实例化bean
@Override
public Object instantiate(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner) {
    // Don't override the class with CGLIB if no overrides.
    if (!bd.hasMethodOverrides()) {
        Constructor<?> constructorToUse;
        synchronized (bd.constructorArgumentLock) {
            constructorToUse = (Constructor<?>) bd.resolvedConstructorOrFactoryMethod;
            if (constructorToUse == null) {
                final Class<?> clazz = bd.getBeanClass();
                if (clazz.isInterface()) {
                    throw new BeanInstantiationException(clazz, "Specified class is an interface");
                }
                try {
                    // 获取构造器
                    if (System.getSecurityManager() != null) {
                        constructorToUse = AccessController.doPrivileged(
                            (PrivilegedExceptionAction<Constructor<?>>) clazz::getDeclaredConstructor);
                    }
                    else {
                        constructorToUse = clazz.getDeclaredConstructor();
                    }
                    bd.resolvedConstructorOrFactoryMethod = constructorToUse;
                }
                catch (Throwable ex) {
                    throw new BeanInstantiationException(clazz, "No default constructor found", ex);
                }
            }
        }
        // 反射; 通过构造器来创建实例
        return BeanUtils.instantiateClass(constructorToUse);
    }
    else {
        // Must generate CGLIB subclass.
        return instantiateWithMethodInjection(bd, beanName, owner);
    }
}
```

> org.springframework.beans.BeanUtils#instantiateClass(java.lang.reflect.Constructor<T>, java.lang.Object...)

```java
// 实例化类
public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
    Assert.notNull(ctor, "Constructor must not be null");
    try {
        // 反射,使用构造器 来实例化类
        ReflectionUtils.makeAccessible(ctor);
        return (KotlinDetector.isKotlinReflectPresent() && KotlinDetector.isKotlinType(ctor.getDeclaringClass()) ?
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
```

可以看到最终仍然是通过反射来创建了实例，当然也有cglib的代理，此处没有分析。到此，一个bean就创建了，后面咱们看一下bean的自动注册以及初始化的操作。本篇就到此为止。

































