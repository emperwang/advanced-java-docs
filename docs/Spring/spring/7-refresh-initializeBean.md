[TOC]

# refresh

前篇分析了bean实例化后对属性的自动注入操作，本篇来看看实例化后的对bean初始化，也就是bean的初始化函数的调用。回顾一下前面的创建bean函数：

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
					/**
					 * 调用MergedBeanDefinitionPostProcessor后置处理器,合并父子bean的信息
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
	.....	// 省略部分

		return exposedObject;
	}

```

>  org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#initializeBea

```java
// 初始化bean,也就是调用bean的各种init方法,像 init-method   @PostConstruct定义的方法
protected Object initializeBean(final String beanName, final Object bean, @Nullable RootBeanDefinition mbd) {
    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
            invokeAwareMethods(beanName, bean);
            return null;
        }, getAccessControlContext());
    }
    else {
        // 调用各种Aware方法
        // 也就是 通过 aware接口 注入值
        invokeAwareMethods(beanName, bean);
    }
    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        /**
			 *  回调beanPostProcessor方法,也就是初始化前的回调
			 *  在这里会调用postconstruct注解的初始化方法.
			 *
			 *  那也就是说方法调用顺序:
			 *  1.PostConstruct注解的方法
			 *  2. InitializingBean.afterPropertiesSet
			 */
        // 这里通过beanPostProcessor(CommonAnnotationBeanPostProcessor) 来调用 PostConstruct 注解方法
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }
    try {
        /**
			 * 调用初始化方法
			 * 	1. 先调用InitializingBean接口的初始化方法 .afterPropertiesSet
			 * 	2. 调用 init-method 的初始化方法 (自定义的初始化方法)
			 */
        invokeInitMethods(beanName, wrappedBean, mbd);
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
            (mbd != null ? mbd.getResourceDescription() : null),
            beanName, "Invocation of init method failed", ex);
    }
    if (mbd == null || !mbd.isSynthetic()) {
        // 回调beanPostProcessor类的初始化后的方法
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }
    return wrappedBean;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#applyBeanPostProcessorsBeforeInitialization

```java
// 回调BeanPostProcessor的postProcessBeforeInitialization
@Override
public Object applyBeanPostProcessorsBeforeInitialization(Object existingBean, String beanName)
    throws BeansException {
    /**
		 * InitDestroyAnnotationBeanPostProcessor 处理PostConstruct 和 PreDestroy注解的方法
		 */
    Object result = existingBean;
    // 这里通过beanPostProcessor 后置处理器来实现对 注解 postConstruct 处理
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        Object current = processor.postProcessBeforeInitialization(result, beanName);
        if (current == null) {
            return result;
        }
        result = current;
    }
    return result;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#invokeInitMethods

```java
// 调用 init-method   @PostConstruct  InitializingBean的初始化方法
protected void invokeInitMethods(String beanName, final Object bean, @Nullable RootBeanDefinition mbd)
    throws Throwable {

    boolean isInitializingBean = (bean instanceof InitializingBean);
    if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
        if (logger.isTraceEnabled()) {
            logger.trace("Invoking afterPropertiesSet() on bean with name '" + beanName + "'");
        }
        if (System.getSecurityManager() != null) {
            try {
                AccessController.doPrivileged((PrivilegedExceptionAction<Object>) () -> {
                    ((InitializingBean) bean).afterPropertiesSet();
                    return null;
                }, getAccessControlContext());
            }
            catch (PrivilegedActionException pae) {
                throw pae.getException();
            }
        }
        else {
            // 先调用InitializingBean接口的初始化方法
            ((InitializingBean) bean).afterPropertiesSet();
        }
    }
    // 在调用自定义的初始化方法
    if (mbd != null && bean.getClass() != NullBean.class) {
        String initMethodName = mbd.getInitMethodName();
        if (StringUtils.hasLength(initMethodName) &&
            !(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
            !mbd.isExternallyManagedInitMethod(initMethodName)) {
            // 具体的调用自定义的初始化方法
            invokeCustomInitMethod(beanName, bean, mbd);
        }
    }
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#invokeCustomInitMethod

```java
// 调用初始化方法
protected void invokeCustomInitMethod(String beanName, final Object bean, RootBeanDefinition mbd)
    throws Throwable {

    String initMethodName = mbd.getInitMethodName();
    Assert.state(initMethodName != null, "No init method set");
    // 获取初始化方法
    final Method initMethod = (mbd.isNonPublicAccessAllowed() ?
                               BeanUtils.findMethod(bean.getClass(), initMethodName) :
                               ClassUtils.getMethodIfAvailable(bean.getClass(), initMethodName));

    if (initMethod == null) {
        if (mbd.isEnforceInitMethod()) {
            throw new BeanDefinitionValidationException("Could not find an init method named '" +
                                                        initMethodName + "' on bean with name '" + beanName + "'");
        }
        else {
            if (logger.isTraceEnabled()) {
                logger.trace("No default init method named '" + initMethodName +
                             "' found on bean with name '" + beanName + "'");
            }
            // Ignore non-existent default lifecycle methods.
            return;
        }
    }

    if (logger.isTraceEnabled()) {
        logger.trace("Invoking init method  '" + initMethodName + "' on bean with name '" + beanName + "'");
    }

    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
            ReflectionUtils.makeAccessible(initMethod);
            return null;
        });
        try {
            AccessController.doPrivileged((PrivilegedExceptionAction<Object>) () ->
                                          initMethod.invoke(bean), getAccessControlContext());
        }
        catch (PrivilegedActionException pae) {
            InvocationTargetException ex = (InvocationTargetException) pae.getException();
            throw ex.getTargetException();
        }
    }
    else {
        try {
            // 初始化方法调用
            ReflectionUtils.makeAccessible(initMethod);
            initMethod.invoke(bean);
        }
        catch (InvocationTargetException ex) {
            throw ex.getTargetException();
        }
    }
}
```

从上面的初始化过程可以看到，对初始化方法的调用主要顺序是:

1. postContruct
2. InitializingBean 接口的afterPropertiesSet 方法
3. 自定义的 init-method

后置处理器在bean初始化完成后，再次进行一次处理：

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#applyBeanPostProcessorsAfterInitialization

```java
// 回调BeanPostProcessor.postProcessAfterInitialization 方法
@Override
public Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName)
    throws BeansException {

    Object result = existingBean;
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        Object current = processor.postProcessAfterInitialization(result, beanName);
        if (current == null) {
            return result;
        }
        result = current;
    }
    return result;
}
```

到处一个bean从实例化，自动注入，以及初始化函数的调用，就完成了一个bean的创建。

在看一下最后初始化完bean之后，对bean有可能带有销毁方法的处理：

> org.springframework.beans.factory.support.AbstractBeanFactory#registerDisposableBeanIfNecessary

```java
// 注册一个具有销毁方法的bean
protected void registerDisposableBeanIfNecessary(String beanName, Object bean, RootBeanDefinition mbd) {
    AccessControlContext acc = (System.getSecurityManager() != null ? getAccessControlContext() : null);
    if (!mbd.isPrototype() && requiresDestruction(bean, mbd)) {
        if (mbd.isSingleton()) { // 如果对应的bean是单例,并且有销毁方法
            // Register a DisposableBean implementation that performs all destruction
            // work for the given bean: DestructionAwareBeanPostProcessors,
            // DisposableBean interface, custom destroy method.
            // 注册一个 带有销毁方法的bean
            registerDisposableBean(beanName,new DisposableBeanAdapter(bean, beanName, mbd, getBeanPostProcessors(), acc));
        }
        else {
            // A bean with a custom scope...
            Scope scope = this.scopes.get(mbd.getScope());
            if (scope == null) {
                throw new IllegalStateException("No Scope registered for scope name '" + mbd.getScope() + "'");
            }
            // 在指定的scope注册
            scope.registerDestructionCallback(beanName, new DisposableBeanAdapter(bean, beanName, mbd, getBeanPostProcessors(), acc));
        }
    }
}

```

> org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#registerDisposableBean

```java
	// 注册一个实现了销毁方法的bean
	public void registerDisposableBean(String beanName, DisposableBean bean) {
		synchronized (this.disposableBeans) {
			this.disposableBeans.put(beanName, bean);
		}
	}

```

> org.springframework.beans.factory.support.DisposableBeanAdapter#DisposableBeanAdapte

```java
public DisposableBeanAdapter(Object bean, String beanName, RootBeanDefinition beanDefinition,
                   List<BeanPostProcessor> postProcessors, @Nullable AccessControlContext acc) {

    Assert.notNull(bean, "Disposable bean must not be null");
    this.bean = bean;
    this.beanName = beanName;
    this.invokeDisposableBean =
        (this.bean instanceof DisposableBean && !beanDefinition.isExternallyManagedDestroyMethod("destroy"));
    this.nonPublicAccessAllowed = beanDefinition.isNonPublicAccessAllowed();
    this.acc = acc;
    // 推断一个 bean的销毁方法
    String destroyMethodName = inferDestroyMethodIfNecessary(bean, beanDefinition);
    if (destroyMethodName != null && !(this.invokeDisposableBean && "destroy".equals(destroyMethodName)) &&
        !beanDefinition.isExternallyManagedDestroyMethod(destroyMethodName)) {
        this.destroyMethodName = destroyMethodName;
        // 查找销毁方法
        this.destroyMethod = determineDestroyMethod(destroyMethodName);
        if (this.destroyMethod == null) {
            if (beanDefinition.isEnforceDestroyMethod()) {
                throw new BeanDefinitionValidationException("Could not find a destroy method named '" +destroyMethodName + "' on bean with name '" + beanName + "'");
            }
        }
        else {
            Class<?>[] paramTypes = this.destroyMethod.getParameterTypes();
            if (paramTypes.length > 1) {
                throw new BeanDefinitionValidationException("Method '" + destroyMethodName + "' of bean '" + beanName + "' has more than one parameter - not supported as destroy method");
            }
            else if (paramTypes.length == 1 && boolean.class != paramTypes[0]) {
                throw new BeanDefinitionValidationException("Method '" + destroyMethodName + "' of bean '" + beanName + "' has a non-boolean parameter - not supported as destroy method");
            }
        }
    }
    // 过滤出 DestructionAwareBeanPostProcessor 类型的后置处理器
    this.beanPostProcessors = filterPostProcessors(postProcessors, bean);
}
```

最后创建了一个DisposableBeanAdapter类型的bean，此bean会调用销毁方法。

到此一个bean的创建就算是完成了，bean也初始化了，以及各种后置处理器对bean的各种增强操作也完成了。

在refresh函数 preInstantiateSingletons 中会循环容器中的所有beanName来对bean进行上面的过程，所以函数preInstantiateSingletons执行完之后，容器中的所有bean就初始化完成了，由此可见preInstantiateSingletons的初始化时非惰性的。



























































































