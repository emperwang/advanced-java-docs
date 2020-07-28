[TOC]

# Aop的创建

上篇总体分析了容器是如何以及什么时候解析了所有的advisor的，advisor分析完了，那么下面就可以创建Aop了。

再看一下AnnotationAwareAspectJAutoProxyCreator的类图，类图还是很重要的：

![](../../image/spring/AnnotationAwareAspectJAutoProxyCreator.png)

可以看到AnnotationAwareAspectJAutoProxyCreator还是BeanPostProcessor的子类，也就是其是一个后置处理器，看一下其处理器做了什么工作：

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#postProcessBeforeInitialization

```java
	public Object postProcessBeforeInitialization(Object bean, String beanName) {
		return bean;
	}
```

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#postProcessAfterInitialization

```java
// 在后置处理器这里, 进行代理点的设置
// 也就是在bean初始化后之后
@Override
public Object postProcessAfterInitialization(@Nullable Object bean, String beanName) {
    if (bean != null) {
        Object cacheKey = getCacheKey(bean.getClass(), beanName);
        if (!this.earlyProxyReferences.contains(cacheKey)) {
            // 如果需要创建代理，那在这里进行具体的创建动作
            return wrapIfNecessary(bean, beanName, cacheKey);
        }
    }
    return bean;
}
```

这里就要开始处理Aop的创建了.

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#wrapIfNecessary

```java
// 如果需要就创建代理
protected Object wrapIfNecessary(Object bean, String beanName, Object cacheKey) {
    if (StringUtils.hasLength(beanName) && this.targetSourcedBeans.contains(beanName)) {
        return bean;
    }
    if (Boolean.FALSE.equals(this.advisedBeans.get(cacheKey))) {
        return bean;
    }
    //shouldSkip 如果没有advisor还没有解析呢，仍然会解析一次
    // 不过在执行到这里前,就已经解析了
    if (isInfrastructureClass(bean.getClass()) || shouldSkip(bean.getClass(), beanName)) {
        // 如果是指定bean   或者 应该跳过,就记录下来
        this.advisedBeans.put(cacheKey, Boolean.FALSE);
        return bean;
    }

    // Create proxy if we have advice.
    // 获取容器中此bean对应的advice
    // getAdvicesAndAdvisorsForBean此方法会吧容器中的bean遍历一遍,以此得到所有的advice方法以及pointcut也就是advisor
    // 深入看一下getAdvicesAndAdvisorsForBean
    // 重点 重点
    Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
    // 如果存在对应的advice,那么就把此bean放到advisedBeans容器中,并为此bean创建代理
    if (specificInterceptors != DO_NOT_PROXY) {
        // 记录其此bean 需要进行aop代理
        this.advisedBeans.put(cacheKey, Boolean.TRUE);
        // 具体创建代理的过程
        // 重点 重点 重点
        Object proxy = createProxy(
            bean.getClass(), beanName, specificInterceptors, new SingletonTargetSource(bean));
        // 缓存代理
        // 记录 创建好的代理
        this.proxyTypes.put(cacheKey, proxy.getClass());
        return proxy;
    }

    this.advisedBeans.put(cacheKey, Boolean.FALSE);
    return bean;
}
```

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#getAdvicesAndAdvisorsForBean

```java
	// 解析容器中是否有对应bean的Advisor
	@Override
	@Nullable
	protected Object[] getAdvicesAndAdvisorsForBean(
			Class<?> beanClass, String beanName, @Nullable TargetSource targetSource) {
		// 查找合格的advisor
		// 重点 重点
		List<Advisor> advisors = findEligibleAdvisors(beanClass, beanName);
		if (advisors.isEmpty()) {
			return DO_NOT_PROXY;
		}
		return advisors.toArray();
	}
```

> org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#findEligibleAdvisors

```java
// 从容器中查找合适于参数的advisor
protected List<Advisor> findEligibleAdvisors(Class<?> beanClass, String beanName) {
    // findCandidateAdvisors此会解析容器中所有的advisor
    List<Advisor> candidateAdvisors = findCandidateAdvisors();
    // findAdvisorsThatCanApply从获取到的bean实例中找到所有能应用到参数对应类型上的advisor
    List<Advisor> eligibleAdvisors = findAdvisorsThatCanApply(candidateAdvisors, beanClass, beanName);
    // 对advice调用链进行扩展; 如果调用链中不存在ExposeInvocationInterceptor则在index=0的位置添加一个
    extendAdvisors(eligibleAdvisors);
    if (!eligibleAdvisors.isEmpty()) {
        eligibleAdvisors = sortAdvisors(eligibleAdvisors);
    }
    return eligibleAdvisors;
}
```

此findCandidateAdvisors，仍然是调用org.springframework.aop.aspectj.annotation.AnnotationAwareAspectJAutoProxyCreator#findCandidateAdvisors方法来获取，上篇已经解析了此函数，这里就不多说了。

> org.springframework.aop.aspectj.annotation.AnnotationAwareAspectJAutoProxyCreator#findCandidateAdvisors

此函数直接看上篇分析Advisors时的解析，跳过此函数，继续向下：

> org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#findAdvisorsThatCanApply

```java
	protected List<Advisor> findAdvisorsThatCanApply(
			List<Advisor> candidateAdvisors, Class<?> beanClass, String beanName) {
		// 记录正在进行aop 的beanName
		ProxyCreationContext.setCurrentProxiedBeanName(beanName);
		try {
			// 从candidateAdvisors中找到适合于beanClass的advisor
			return AopUtils.findAdvisorsThatCanApply(candidateAdvisors, beanClass);
		}
		finally {
			ProxyCreationContext.setCurrentProxiedBeanName(null);
		}
	}
```

> org.springframework.aop.support.AopUtils#findAdvisorsThatCanApply

```java
// 查到 对于 clazz 可用的 advisor
public static List<Advisor> findAdvisorsThatCanApply(List<Advisor> candidateAdvisors, Class<?> clazz) {
    // 没有候选的 advisor,直接返回空列表
    if (candidateAdvisors.isEmpty()) {
        return candidateAdvisors;
    }
    //
    List<Advisor> eligibleAdvisors = new ArrayList<>();
    for (Advisor candidate : candidateAdvisors) {
        // 条件: 首先候选的advisor必须是IntroductionAdvisor类型
        // canApply 根据pointcut是进行判断
        if (candidate instanceof IntroductionAdvisor && canApply(candidate, clazz)) {
            eligibleAdvisors.add(candidate);
        }
    }
    boolean hasIntroductions = !eligibleAdvisors.isEmpty();
    for (Advisor candidate : candidateAdvisors) {
        if (candidate instanceof IntroductionAdvisor) {
            // already processed
            continue;
        }
        if (canApply(candidate, clazz, hasIntroductions)) {
            eligibleAdvisors.add(candidate);
        }
    }
    return eligibleAdvisors;
}

```

> org.springframework.aop.support.AopUtils#canApply(org.springframework.aop.Advisor, java.lang.Class<?>)

```java
	// 判断advisor是否能应用到targetClass
	public static boolean canApply(Advisor advisor, Class<?> targetClass) {
		return canApply(advisor, targetClass, false);
	}
```

> org.springframework.aop.support.AopUtils#canApply(org.springframework.aop.Pointcut, java.lang.Class<?>, boolean)

```java
public static boolean canApply(Pointcut pc, Class<?> targetClass, boolean hasIntroductions) {
    Assert.notNull(pc, "Pointcut must not be null");
    if (!pc.getClassFilter().matches(targetClass)) {
        return false;
    }
    // 如果pointcut为AnnotationMatchingPointcut,则其 matchet,就是MethodMatcher.TRUE
    MethodMatcher methodMatcher = pc.getMethodMatcher();
    if (methodMatcher == MethodMatcher.TRUE) {
        // No need to iterate the methods if we're matching any method anyway...
        return true;
    }

    IntroductionAwareMethodMatcher introductionAwareMethodMatcher = null;
    if (methodMatcher instanceof IntroductionAwareMethodMatcher) {
        introductionAwareMethodMatcher = (IntroductionAwareMethodMatcher) methodMatcher;
    }

    Set<Class<?>> classes = new LinkedHashSet<>();
    if (!Proxy.isProxyClass(targetClass)) {
        classes.add(ClassUtils.getUserClass(targetClass));
    }
    classes.addAll(ClassUtils.getAllInterfacesForClassAsSet(targetClass));

    for (Class<?> clazz : classes) {
        // 获取所有声明的方法
        Method[] methods = ReflectionUtils.getAllDeclaredMethods(clazz);
        for (Method method : methods) {
            // 如果是事务创建代理, 会走methodMatcher.matches这里,这个方法会解析方法的注解信息
            // introductionAwareMethodMatcher.matches 使用pointCut表达式调用AspectJ 来进行匹配操作
            if (introductionAwareMethodMatcher != null ?
                introductionAwareMethodMatcher.matches(method, targetClass, hasIntroductions) :
                methodMatcher.matches(method, targetClass)) {
                return true;
            }
        }
    }
    return false;
}
```

> org.springframework.aop.aspectj.AspectJExpressionPointcut#matches

```java
// 使用pointcut expression 来进行match
@Override
public boolean matches(Method method, Class<?> targetClass, boolean hasIntroductions) {
    // 获取pointcut expression
    obtainPointcutExpression();
    // 进行匹配操作
    ShadowMatch shadowMatch = getTargetShadowMatch(method, targetClass);
    if (shadowMatch.alwaysMatches()) {
        return true;
    }
    else if (shadowMatch.neverMatches()) {
        return false;
    }
    else {
        // the maybe case
        if (hasIntroductions) {
            return true;
        }
        RuntimeTestWalker walker = getRuntimeTestWalker(shadowMatch);
        return (!walker.testsSubtypeSensitiveVars() || walker.testTargetInstanceOfResidue(targetClass));
    }
}
```

>  org.springframework.aop.aspectj.AspectJExpressionPointcut#getTargetShadowMatch

```java
// 根据pointcut expression 进行匹配
private ShadowMatch getTargetShadowMatch(Method method, Class<?> targetClass) {
    Method targetMethod = AopUtils.getMostSpecificMethod(method, targetClass);
    // 如果目标类是一个接口
    if (targetMethod.getDeclaringClass().isInterface()) {
        // Try to build the most specific interface possible for inherited methods to be
        // considered for sub-interface matches as well, in particular for proxy classes.
        // Note: AspectJ is only going to take Method.getDeclaringClass() into account.
        Set<Class<?>> ifcs = ClassUtils.getAllInterfacesForClassAsSet(targetClass);
        if (ifcs.size() > 1) {
            try {
                Class<?> compositeInterface = ClassUtils.createCompositeInterface(
                    ClassUtils.toClassArray(ifcs), targetClass.getClassLoader());
                targetMethod = ClassUtils.getMostSpecificMethod(targetMethod, compositeInterface);
            }
            catch (IllegalArgumentException ex) {
                // Implemented interfaces probably expose conflicting method signatures...
                // Proceed with original target method.
            }
        }
    }
    // 匹配操作
    return getShadowMatch(targetMethod, method);
}
```

> org.springframework.aop.aspectj.AspectJExpressionPointcut#getShadowMatch

```java
// pointcut expression的匹配
	private ShadowMatch getShadowMatch(Method targetMethod, Method originalMethod) {
		// Avoid lock contention for known Methods through concurrent access...
		ShadowMatch shadowMatch = this.shadowMatchCache.get(targetMethod);
		if (shadowMatch == null) {
			synchronized (this.shadowMatchCache) {
				// Not found - now check again with full lock...
				PointcutExpression fallbackExpression = null;
				shadowMatch = this.shadowMatchCache.get(targetMethod);
				if (shadowMatch == null) {
					Method methodToMatch = targetMethod;
					try {
						try {
							// 这里调用 aspectJ 进行匹配
							shadowMatch = obtainPointcutExpression().matchesMethodExecution(methodToMatch);
						}
                        
                        .....  // 省略部分
                    }
                }
            }
        }
```

可以看到进行匹配操作的动作，最终还是调用AspectJ来进行。

找适合的advisor就结束了，继续拉回到主干，对找到的advisor进行扩展操作:

回顾一下:

```java
// 从容器中查找合适于参数的advisor
protected List<Advisor> findEligibleAdvisors(Class<?> beanClass, String beanName) {
    // findCandidateAdvisors此会解析容器中所有的advisor
    List<Advisor> candidateAdvisors = findCandidateAdvisors();
    // findAdvisorsThatCanApply从获取到的bean实例中找到所有能应用到参数对应类型上的advisor
    List<Advisor> eligibleAdvisors = findAdvisorsThatCanApply(candidateAdvisors, beanClass, beanName);
    // 对advice调用链进行扩展; 如果调用链中不存在ExposeInvocationInterceptor则在index=0的位置添加一个
    extendAdvisors(eligibleAdvisors);
    if (!eligibleAdvisors.isEmpty()) {
        eligibleAdvisors = sortAdvisors(eligibleAdvisors);
    }
    return eligibleAdvisors;
}
```



> org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#extendAdvisors

```java
// 对advice调用链进行扩展; 如果调用链中不存在ExposeInvocationInterceptor则在index=0的位置添加一个
@Override
protected void extendAdvisors(List<Advisor> candidateAdvisors) {
    AspectJProxyUtils.makeAdvisorChainAspectJCapableIfNecessary(candidateAdvisors);
}
```

> org.springframework.aop.aspectj.AspectJProxyUtils#makeAdvisorChainAspectJCapableIfNecessary

```java
// 对advisor调用链进行扩展; 如果调用链中不存在ExposeInvocationInterceptor则在index=0的位置添加一个
public static boolean makeAdvisorChainAspectJCapableIfNecessary(List<Advisor> advisors) {
    // Don't add advisors to an empty list; may indicate that proxying is just not required
    if (!advisors.isEmpty()) {
        boolean foundAspectJAdvice = false;
        for (Advisor advisor : advisors) {
            // Be careful not to get the Advice without a guard, as
            // this might eagerly instantiate a non-singleton AspectJ aspect
            if (isAspectJAdvice(advisor)) {
                foundAspectJAdvice = true;
            }
        }
        // 在拦截链中添加 ExposeInvocationInterceptor
        if (foundAspectJAdvice && !advisors.contains(ExposeInvocationInterceptor.ADVISOR)) {
            advisors.add(0, ExposeInvocationInterceptor.ADVISOR);
            return true;
        }
    }
    return false;
}
```

这里主要就是向拦截链的开头中添加一个ExposeInvocationInterceptor。

现在拦截链也创建完了，继续往回拉，

```java
// 如果需要就创建代理
protected Object wrapIfNecessary(Object bean, String beanName, Object cacheKey) {
    if (StringUtils.hasLength(beanName) && this.targetSourcedBeans.contains(beanName)) {
        return bean;
    }
    if (Boolean.FALSE.equals(this.advisedBeans.get(cacheKey))) {
        return bean;
    }
    if (isInfrastructureClass(bean.getClass()) || shouldSkip(bean.getClass(), beanName)) {
        // 如果是指定bean   或者 应该跳过,就记录下来
        this.advisedBeans.put(cacheKey, Boolean.FALSE);
        return bean;
    }

    // Create proxy if we have advice.
    // 获取容器中此bean对应的advice
    // getAdvicesAndAdvisorsForBean此方法会吧容器中的bean遍历一遍,以此得到所有的advice方法以及pointcut也就是advisor
    // 深入看一下getAdvicesAndAdvisorsForBean
    // 重点 重点
    // 找到了 拦截链，下面就轮到创建的动作了
    Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
    // 如果存在对应的advice,那么就把此bean放到advisedBeans容器中,并为此bean创建代理
    if (specificInterceptors != DO_NOT_PROXY) {
        // 记录其此bean 需要进行aop代理
        this.advisedBeans.put(cacheKey, Boolean.TRUE);
        // 具体创建代理的过程
        // 重点 重点 重点
        Object proxy = createProxy(
            bean.getClass(), beanName, specificInterceptors, new SingletonTargetSource(bean));
        // 缓存代理
        // 记录 创建好的代理
        this.proxyTypes.put(cacheKey, proxy.getClass());
        return proxy;
    }

    this.advisedBeans.put(cacheKey, Boolean.FALSE);
    return bean;
}
```

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#createProxy

```java
// 创建代理; 也就是为给定的bean创建aop代理
protected Object createProxy(Class<?> beanClass, @Nullable String beanName,
                             @Nullable Object[] specificInterceptors, TargetSource targetSource) {

    if (this.beanFactory instanceof ConfigurableListableBeanFactory) {
        // 设置beanName对应的beanDefinition的originalTargetClass属性
        // 记录原来的beanclass
        AutoProxyUtils.exposeTargetClass((ConfigurableListableBeanFactory) this.beanFactory, beanName, beanClass);
    }
    // 创建一个ProxyFactory，此类用于对目标bean进行包装
    ProxyFactory proxyFactory = new ProxyFactory();
    proxyFactory.copyFrom(this);
    // 判断proxy-target-class 配置，如果为true,那么就使用cglib创建代理,如果没有设置默认为false
    if (!proxyFactory.isProxyTargetClass()) {
        // 判断是此bean对应的beanDefinition是否设置了preserveTargetClass属性为true;如果为true,那么也使用cglib
        if (shouldProxyTargetClass(beanClass, beanName)) {
            proxyFactory.setProxyTargetClass(true);
        }
        else {
            // 获取beanClass的接口类信息，如果有则添加到proxyFactory中;如果没有则也使用cglib生成代理
            evaluateProxyInterfaces(beanClass, proxyFactory);
        }
    }
    // 得到此beanName对应的advisor以及interceptor
    // 重点  重点
    Advisor[] advisors = buildAdvisors(beanName, specificInterceptors);
    // 设置proxyFactory的advisor 以及 保存原class
    proxyFactory.addAdvisors(advisors);
    proxyFactory.setTargetSource(targetSource);
    // 对proxyFactory进行一些定制化操作,此处主要是用于子类进行扩展
    customizeProxyFactory(proxyFactory);

    proxyFactory.setFrozen(this.freezeProxy);
    if (advisorsPreFiltered()) {
        proxyFactory.setPreFiltered(true);
    }
    // 使用proxyFactory来进行代理的创建
    // 重点  重点
    return proxyFactory.getProxy(getProxyClassLoader());
}
```

> org.springframework.aop.framework.ProxyFactory#getProxy(java.lang.ClassLoader)

```java
// 创建代理
public Object getProxy(@Nullable ClassLoader classLoader) {
    // 先创建一个AopProxy类, 然后使用AopProxy进行具体的代理创建
    return createAopProxy().getProxy(classLoader);
}
```

> org.springframework.aop.framework.ProxyCreatorSupport#createAopProxy

```java
// 创建AopProxy实例
protected final synchronized AopProxy createAopProxy() {
    if (!this.active) {
        // 这里会调用监听器
        activate();
    }
    // 创建动作
    return getAopProxyFactory().createAopProxy(this);
}
```

> org.springframework.aop.framework.DefaultAopProxyFactory#createAopProxy

```java
// 具体创建AopProxy的动作
@Override
public AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException {
    if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {
        Class<?> targetClass = config.getTargetClass();
        if (targetClass == null) {
            throw new AopConfigException("TargetSource cannot determine target class: " +
            "Either an interface or a target is required for proxy creation.");
        }
        // 创建JDK动态代理
        if (targetClass.isInterface() || Proxy.isProxyClass(targetClass)) {
            return new JdkDynamicAopProxy(config);
        }
        // 创建cglib代理
        return new ObjenesisCglibAopProxy(config);
    }
    else {
        return new JdkDynamicAopProxy(config);
    }
}
```

这里咱们看一下JDk代理的创建：

> org.springframework.aop.framework.JdkDynamicAopProxy#getProxy(java.lang.ClassLoader)

```java
	// 创建代理
	@Override
	public Object getProxy(@Nullable ClassLoader classLoader) {
		if (logger.isTraceEnabled()) {
			logger.trace("Creating JDK dynamic proxy: " + this.advised.getTargetSource());
		}
		// 得到所有需要实现的接口
		Class<?>[] proxiedInterfaces = AopProxyUtils.completeProxiedInterfaces(this.advised, true);
		// 是否重载 equals 和hasCode方法
		findDefinedEqualsAndHashCodeMethods(proxiedInterfaces);
		// 创建代理
        // 这里重点了  重点 
		return Proxy.newProxyInstance(classLoader, proxiedInterfaces, this);
	}
```

可以看到，最后创建好调用链后，使用了JDK代理来创建代理。































































