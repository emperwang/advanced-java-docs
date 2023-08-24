[TOC]

# Aop对容器中的aspect的解析

上篇分析到Aop注解向容器中注册了一个后置处理器，其在bean实例化前后有操作，以及bean初始化前后也有操作，本篇分析一下此后置处理器在bean实例化前后的操作。

再看一下此AnnotationAwareAspectJAutoProxyCreator 处理器的类图：

![](AnnotationAwareAspectJAutoProxyCreator.png)

回顾一下在bean实例化前后调用后置处理器的点：

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
        // 这里初始化了 aop的advisor
        // 在这里调用了  bean实例化前的 处理器
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

        return beanInstance;
    }
    catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
        throw ex;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
      mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
    }
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#resolveBeforeInstantiation

```java
@Nullable
protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
    Object bean = null;
    if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
        // Make sure bean class is actually resolved at this point.
        if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
            Class<?> targetType = determineTargetType(beanName, mbd);
            if (targetType != null) {
                // 调用 InstantiationAwareBeanPostProcessor 后置处理器
                // 在这里调用了bean的实例化前处理
                // 如果在这里创建了代理对象
                bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
                if (bean != null) {
                    // 那么就对 创建的代理对象 调用 初始化后的处理
                    bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
                }
            }
        }
        mbd.beforeInstantiationResolved = (bean != null);
    }
    return bean;
}
```

这里的实例化前方法调用了注册的AnnotationAwareAspectJAutoProxyCreator 方法，看一下其具体处理

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#applyBeanPostProcessorsBeforeInstantiation

```java
@Nullable
protected Object applyBeanPostProcessorsBeforeInstantiation(Class<?> beanClass, String beanName) {
    for (BeanPostProcessor bp : getBeanPostProcessors()) {
        if (bp instanceof InstantiationAwareBeanPostProcessor) {
            InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
            Object result = ibp.postProcessBeforeInstantiation(beanClass, beanName);
            if (result != null) {
                return result;
            }
        }
    }
    return null;
}
```

> org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#postProcessBeforeInstantiation

```java
// 在bean实例化之前就判断那些bean需要被代理
@Override
public Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) {
    Object cacheKey = getCacheKey(beanClass, beanName);

    if (!StringUtils.hasLength(beanName) || !this.targetSourcedBeans.contains(beanName)) {
        if (this.advisedBeans.containsKey(cacheKey)) {
            return null;
        }
        // 重点 重点
        // 判读class是否是Infrastructure类型的  判断是否需要跳过(根据beanName进行判断)
        // shouldSkip AspectJAwareAdvisorAutoProxyCreator.shouldSkip的方法
        // 之后再 AspectJAwareAdvisorAutoProxyCreator.shouldSkip中就会对容器中的advisors 进行解析
        if (isInfrastructureClass(beanClass) || shouldSkip(beanClass, beanName)) {
            this.advisedBeans.put(cacheKey, Boolean.FALSE);
            return null;
        }
    }

    // Create proxy here if we have a custom TargetSource.
    // Suppresses unnecessary default instantiation of the target bean:
    // The TargetSource will handle target instances in a custom fashion.
    // 如果设置了 customTargetSourceCreators,那么在这里可能会创建代理
    TargetSource targetSource = getCustomTargetSource(beanClass, beanName);
    if (targetSource != null) {
        if (StringUtils.hasLength(beanName)) {
            this.targetSourcedBeans.add(beanName);
        }
        // 获取容器中 advisors
        Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(beanClass, beanName, targetSource);
        //
        Object proxy = createProxy(beanClass, beanName, specificInterceptors, targetSource);
        this.proxyTypes.put(cacheKey, proxy.getClass());
        return proxy;
    }

    return null;
}
```

看一下shouldSkip，在注释中已经标记的比较清楚了，很重要的一个方法：

> org.springframework.aop.aspectj.autoproxy.AspectJAwareAdvisorAutoProxyCreator#shouldSkip

```java
// 是否应该跳过
@Override
protected boolean shouldSkip(Class<?> beanClass, String beanName) {
    // TODO: Consider optimization by caching the list of the aspect names
    // 查找候选的 advisors
    List<Advisor> candidateAdvisors = findCandidateAdvisors();
    for (Advisor advisor : candidateAdvisors) {
        if (advisor instanceof AspectJPointcutAdvisor &&
            ((AspectJPointcutAdvisor) advisor).getAspectName().equals(beanName)) {
            return true;
        }
    }
    return super.shouldSkip(beanClass, beanName);
}
```

> org.springframework.aop.aspectj.annotation.AnnotationAwareAspectJAutoProxyCreator#findCandidateAdvisors

```java
// 查找备选的 advisors
// 查找advisors 是从这里为入口开始
@Override
protected List<Advisor> findCandidateAdvisors() {
    // Add all the Spring advisors found according to superclass rules.
    // 找到容器中所有的 Advisor 实例
    List<Advisor> advisors = super.findCandidateAdvisors();
    // Build Advisors for all AspectJ aspects in the bean factory.
    if (this.aspectJAdvisorsBuilder != null) {
        advisors.addAll(this.aspectJAdvisorsBuilder.buildAspectJAdvisors());
    }
    return advisors;
}
```

看一下aspectJAdvisorsBuilder的初始化：

```java
@Override
protected void initBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    super.initBeanFactory(beanFactory);
    if (this.aspectJAdvisorFactory == null) {
        this.aspectJAdvisorFactory = new ReflectiveAspectJAdvisorFactory(beanFactory);
    }
    // aspectJ 的builder
    // 重点  重点 重点
    this.aspectJAdvisorsBuilder =
        new BeanFactoryAspectJAdvisorsBuilderAdapter(beanFactory, this.aspectJAdvisorFactory);
}
```

看一下其父类的初始化：

> org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#initBeanFactory

```java
protected void initBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    // advisor retrieval : 获取advisor的帮助 handler
    // 重点 重点 重点
    this.advisorRetrievalHelper = new BeanFactoryAdvisorRetrievalHelperAdapter(beanFactory);
}
```

再拉回来，继续主干往下看，查找候选的advisors：

> org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#findCandidateAdvisors

```java
// 查找容器中的Advisorbean
public List<Advisor> findAdvisorBeans() {
    // Determine list of advisor bean names, if not cached already.
    String[] advisorNames = this.cachedAdvisorBeanNames;
    if (advisorNames == null) {
        // Do not initialize FactoryBeans here: We need to leave all regular beans
        // uninitialized to let the auto-proxy creator apply to them!
        // 从父子容器中获取所有的advisor
        advisorNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
            this.beanFactory, Advisor.class, true, false);
        // 把获取到的所有的advisorName缓存起来
        this.cachedAdvisorBeanNames = advisorNames;
    }
    // 如果没有找到合适的名字
    // 则返回一个空数组
    if (advisorNames.length == 0) {
        return new ArrayList<>();
    }
    // 保存所有解析到的advisor实例
    List<Advisor> advisors = new ArrayList<>();
    for (String name : advisorNames) {
        if (isEligibleBean(name)) {
            if (this.beanFactory.isCurrentlyInCreation(name)) {
                if (logger.isTraceEnabled()) {
                    logger.trace("Skipping currently created advisor '" + name + "'");
                }
            }
            else {
                try {
                    // 从容器中获取其advisor的实例
                    advisors.add(this.beanFactory.getBean(name, Advisor.class));
                }
                catch (BeanCreationException ex) {
                    Throwable rootCause = ex.getMostSpecificCause();
                    if (rootCause instanceof BeanCurrentlyInCreationException) {
                        BeanCreationException bce = (BeanCreationException) rootCause;
                        String bceBeanName = bce.getBeanName();
                        if (bceBeanName != null && this.beanFactory.isCurrentlyInCreation(bceBeanName)) {
                            if (logger.isTraceEnabled()) {
                                logger.trace("Skipping advisor '" + name +
                       "' with dependency on currently created bean: " + ex.getMessage());
                            }
                            continue;
                        }
                    }
                    throw ex;
                }
            }
        }
    }
    return advisors;
}

```

上面主要是查找类型为 Advisor类型的bean.

> org.springframework.aop.aspectj.annotation.BeanFactoryAspectJAdvisorsBuilder#buildAspectJAdvisors

```java
public List<Advisor> buildAspectJAdvisors() {
    List<String> aspectNames = this.aspectBeanNames;

    if (aspectNames == null) {
        synchronized (this) {
            aspectNames = this.aspectBeanNames;
            if (aspectNames == null) {
                List<Advisor> advisors = new ArrayList<>();
                aspectNames = new ArrayList<>();
                // 这里是获取 Object类型的bean的beanName
                // 相当于是获取容器中所有的bean了
                String[] beanNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
                    this.beanFactory, Object.class, true, false);
                for (String beanName : beanNames) {
                    if (!isEligibleBean(beanName)) {
                        continue;
                    }
                    // 获取一个bean的 class 类型
                    Class<?> beanType = this.beanFactory.getType(beanName);
                    if (beanType == null) {
                        continue;
                    }
                    // 判断一个beanTpe是否是 advisor
                    // 1. 查看类上是否有 Aspect 注解
                    // 2. 不是被Ajc 编译
                    if (this.advisorFactory.isAspect(beanType)) {
                        // 如果是 aspect 则记录下来
                        aspectNames.add(beanName);
                        // 保存此 aspect的 源数据
                        AspectMetadata amd = new AspectMetadata(beanType, beanName);
                        if (amd.getAjType().getPerClause().getKind() == PerClauseKind.SINGLETON) {
                            MetadataAwareAspectInstanceFactory factory =
                                new BeanFactoryAspectInstanceFactory(this.beanFactory, beanName);
                            // 此操作就会获取 容器中所有的advisor 以及 aspect
                            // ****重点*****
                            List<Advisor> classAdvisors = this.advisorFactory.getAdvisors(factory);
                            if (this.beanFactory.isSingleton(beanName)) {
                                this.advisorsCache.put(beanName, classAdvisors);
                            }
                            else {
                                // 如果不是单例,则存储进缓存
                                this.aspectFactoryCache.put(beanName, factory);
                            }
                            advisors.addAll(classAdvisors);
                        }
                        else {
                            // Per target or per this.
                            if (this.beanFactory.isSingleton(beanName)) {
                                throw new IllegalArgumentException("Bean with name '" + beanName +
                      "' is a singleton, but aspect instantiation model is not singleton");
                            }
                            MetadataAwareAspectInstanceFactory factory =
                                new PrototypeAspectInstanceFactory(this.beanFactory, beanName);
                            // 记录非单例的advisor
                            this.aspectFactoryCache.put(beanName, factory);
                            advisors.addAll(this.advisorFactory.getAdvisors(factory));
                        }
                    }
                }
                this.aspectBeanNames = aspectNames;
                return advisors;
            }
        }
    }

    if (aspectNames.isEmpty()) {
        return Collections.emptyList();
    }
    List<Advisor> advisors = new ArrayList<>();
    for (String aspectName : aspectNames) {
        List<Advisor> cachedAdvisors = this.advisorsCache.get(aspectName);
        if (cachedAdvisors != null) {
            advisors.addAll(cachedAdvisors);
        }
        else {
            MetadataAwareAspectInstanceFactory factory = this.aspectFactoryCache.get(aspectName);
            advisors.addAll(this.advisorFactory.getAdvisors(factory));
        }
    }
    return advisors;
}
```

方法比较长，主要有几个工作：

1. 查找容器中类型为Object的beanName
2. 如果类是 Aspect注解的， 则解析类中的 advice，也就是解析其中中各种通知方法

判断是否是Aspect:

> org.springframework.aop.aspectj.annotation.AbstractAspectJAdvisorFactory#isAspect

```java
@Override
public boolean isAspect(Class<?> clazz) {
    return (hasAspectAnnotation(clazz) && !compiledByAjc(clazz));
}

private boolean hasAspectAnnotation(Class<?> clazz) {
    return (AnnotationUtils.findAnnotation(clazz, Aspect.class) != null);
}

```

下面开始对类中的通知方法开始解析：

> org.springframework.aop.aspectj.annotation.ReflectiveAspectJAdvisorFactory#getAdvisors

```java
// 重点 重点
// 获取容器中的advisors
@Override
public List<Advisor> getAdvisors(MetadataAwareAspectInstanceFactory aspectInstanceFactory) {
    // aspect的全类名
    Class<?> aspectClass = aspectInstanceFactory.getAspectMetadata().getAspectClass();
    // aspect的名字
    String aspectName = aspectInstanceFactory.getAspectMetadata().getAspectName();
    // 校验
    validate(aspectClass);

    // We need to wrap the MetadataAwareAspectInstanceFactory with a decorator
    // so that it will only instantiate once.
    MetadataAwareAspectInstanceFactory lazySingletonAspectInstanceFactory =
        new LazySingletonAspectInstanceFactoryDecorator(aspectInstanceFactory);
    // 获取 容器中配置的 advisors
    List<Advisor> advisors = new ArrayList<>();
    for (Method method : getAdvisorMethods(aspectClass)) {
        // getAdvisor 重点方法
        Advisor advisor = getAdvisor(method, lazySingletonAspectInstanceFactory, advisors.size(), aspectName);
        if (advisor != null) {
            advisors.add(advisor);
        }
    }
    // If it's a per target aspect, emit the dummy instantiating aspect.
    if (!advisors.isEmpty() && lazySingletonAspectInstanceFactory.getAspectMetadata().isLazilyInstantiated()) {
        Advisor instantiationAdvisor = new SyntheticInstantiationAdvisor(lazySingletonAspectInstanceFactory);
        advisors.add(0, instantiationAdvisor);
    }

    // Find introduction fields.
    for (Field field : aspectClass.getDeclaredFields()) {
        Advisor advisor = getDeclareParentsAdvisor(field);
        if (advisor != null) {
            advisors.add(advisor);
        }
    }

    return advisors;
}
```

遍历方法的方式：

> org.springframework.aop.aspectj.annotation.ReflectiveAspectJAdvisorFactory#getAdvisorMethods

```java
	// 查找有 Pointcut 注解的method
	private List<Method> getAdvisorMethods(Class<?> aspectClass) {
		final List<Method> methods = new ArrayList<>();
		// 此处是获取 aspect中除了  Pointcut注解的方法
		ReflectionUtils.doWithMethods(aspectClass, method -> {
			// Exclude pointcuts
			if (AnnotationUtils.getAnnotation(method, Pointcut.class) == null) {
				methods.add(method);
			}
		});
		methods.sort(METHOD_COMPARATOR);
		return methods;
	}
```



>  org.springframework.aop.aspectj.annotation.ReflectiveAspectJAdvisorFactory#getAdvisor

```java
// 获取方法上的 advisor
@Override
@Nullable
public Advisor getAdvisor(Method candidateAdviceMethod, MetadataAwareAspectInstanceFactory aspectInstanceFactory,
                          int declarationOrderInAspect, String aspectName) {

    validate(aspectInstanceFactory.getAspectMetadata().getAspectClass());
    // 第一次是获取方法上的 pointCut
    // 之后会获取 aspect中的 advice
    // 之后获取advice后,会在advice中记录 pointcut expression
    AspectJExpressionPointcut expressionPointcut = getPointcut(
        candidateAdviceMethod, aspectInstanceFactory.getAspectMetadata().getAspectClass());
    if (expressionPointcut == null) {
        return null;
    }
    // 在此创建  InstantiationModelAwarePointcutAdvisorImpl
    // 用于保存 pointCut 表达式
    return new InstantiationModelAwarePointcutAdvisorImpl(expressionPointcut, candidateAdviceMethod,
                                                          this, aspectInstanceFactory, declarationOrderInAspect, aspectName);
}
```

> org.springframework.aop.aspectj.annotation.ReflectiveAspectJAdvisorFactory#getPointcut

```java
// 重点 重点
// 获取配置的
@Nullable
private AspectJExpressionPointcut getPointcut(Method candidateAdviceMethod, Class<?> candidateAspectClass) {
    // 查找对应的class 中某个方法是否是 advice
    AspectJAnnotation<?> aspectJAnnotation =
        AbstractAspectJAdvisorFactory.findAspectJAnnotationOnMethod(candidateAdviceMethod);
    if (aspectJAnnotation == null) {
        return null;
    }
    AspectJExpressionPointcut ajexp =
        new AspectJExpressionPointcut(candidateAspectClass, new String[0], new Class<?>[0]);
    // 记录 pointcut 表达式
    ajexp.setExpression(aspectJAnnotation.getPointcutExpression());
    if (this.beanFactory != null) {
        ajexp.setBeanFactory(this.beanFactory);
    }
    return ajexp;
}

```

> org.springframework.aop.aspectj.annotation.AbstractAspectJAdvisorFactory#findAspectJAnnotationOnMethod

```java
private static final Class<?>[] ASPECTJ_ANNOTATION_CLASSES = new Class<?>[] {
    Pointcut.class, Around.class, Before.class, After.class, AfterReturning.class, AfterThrowing.class};

@SuppressWarnings("unchecked")
@Nullable
protected static AspectJAnnotation<?> findAspectJAnnotationOnMethod(Method method) {
    // 可以看到查找advice的方式,就是 method上有没有指定的注解
    // Pointcut.class, Around.class, Before.class, After.class, AfterReturning.class, AfterThrowing.class
    for (Class<?> clazz : ASPECTJ_ANNOTATION_CLASSES) {
        // 具体的查找方法  findAnnotation
        AspectJAnnotation<?> foundAnnotation = findAnnotation(method, (Class<Annotation>) clazz);
        if (foundAnnotation != null) {
            return foundAnnotation;
        }
    }
    return null;
}
```

> org.springframework.aop.aspectj.annotation.AbstractAspectJAdvisorFactory#findAnnotation

```java
// 查找 method上的 toLookFor, 一般是查找方法上的注解
@Nullable
private static <A extends Annotation> AspectJAnnotation<A> findAnnotation(Method method, Class<A> toLookFor) {
    // 查找方法上的注解信息
    A result = AnnotationUtils.findAnnotation(method, toLookFor);
    if (result != null) {
        return new AspectJAnnotation<>(result);
    }
    else {
        return null;
    }
}
```

> org.springframework.core.annotation.AnnotationUtils#findAnnotation(java.lang.reflect.Method, java.lang.Class<A>)

```java
// 查找方法上的注解
// 1. 直接在方法上查找
// 2. 在接口方法上查找
// 3. 在父类方法中查找
@SuppressWarnings("unchecked")
@Nullable
public static <A extends Annotation> A findAnnotation(Method method, @Nullable Class<A> annotationType) {
    Assert.notNull(method, "Method must not be null");
    if (annotationType == null) {
        return null;
    }
    // 用于缓存的key
    //************缓存中查找***************
    AnnotationCacheKey cacheKey = new AnnotationCacheKey(method, annotationType);
    // 查看缓存中是否有
    A result = (A) findAnnotationCache.get(cacheKey);
    // 缓存中没有,则进行查找
    if (result == null) {
        Method resolvedMethod = BridgeMethodResolver.findBridgedMethod(method);
        //************直接在方法  中查找***************
        result = findAnnotation((AnnotatedElement) resolvedMethod, annotationType);
        if (result == null) {
            // 从接口方法中 查找是否有注解
            //************接口中 查找***************
            result = searchOnInterfaces(method, annotationType, method.getDeclaringClass().getInterfaces());
        }

        Class<?> clazz = method.getDeclaringClass();
        // 如果接口中还没有查找到,则从父类中查找注解信息
        //************父类  中 查找***************
        while (result == null) {
            clazz = clazz.getSuperclass();
            if (clazz == null || clazz == Object.class) {
                break;
            }
            Set<Method> annotatedMethods = getAnnotatedMethodsInBaseType(clazz);
            if (!annotatedMethods.isEmpty()) {
                for (Method annotatedMethod : annotatedMethods) {
                    if (isOverride(method, annotatedMethod)) {
                        Method resolvedSuperMethod = BridgeMethodResolver.findBridgedMethod(annotatedMethod);
                        result = findAnnotation((AnnotatedElement) resolvedSuperMethod, annotationType);
                        if (result != null) {
                            break;
                        }
                    }
                }
            }
            if (result == null) {
                // 从接口方法中查找 注解信息
                //************接口中 查找***************
                result = searchOnInterfaces(method, annotationType, clazz.getInterfaces());
            }
        }
        if (result != null) {
            result = synthesizeAnnotation(result, method);
            findAnnotationCache.put(cacheKey, result);
        }
    }
    return result;
}

```

查找到了，则进行一些包装：

> org.springframework.aop.aspectj.annotation.AbstractAspectJAdvisorFactory.AspectJAnnotation#AspectJAnnotation

```java
public AspectJAnnotation(A annotation) {
    this.annotation = annotation;
    this.annotationType = determineAnnotationType(annotation);
    try {
        // 解析 advice 对应的 pointcut 表达式
        this.pointcutExpression = resolveExpression(annotation);
        Object argNames = AnnotationUtils.getValue(annotation, "argNames");
        this.argumentNames = (argNames instanceof String ? (String) argNames : "");
    }
    catch (Exception ex) {
        throw new IllegalArgumentException(annotation + " is not a valid AspectJ annotation", ex);
    }
}

private static final String[] EXPRESSION_ATTRIBUTES = new String[] {"pointcut", "value"};
// 解析 advice对应的 pointcut表达式
private String resolveExpression(A annotation) {
    for (String attributeName : EXPRESSION_ATTRIBUTES) {
        Object val = AnnotationUtils.getValue(annotation, attributeName);
        if (val instanceof String) {
            String str = (String) val;
            if (!str.isEmpty()) {
                return str;
            }
        }
    }
    throw new IllegalStateException("Failed to resolve expression: " + annotation);
}
```

上面说了那么多，希望没有看眼花。总的来说，上面做了几件事：

1. 获取容器中所有 Object 类型的bean，就是获取所有的bean
2. 判断bean是否是aspect，也就是类上是否有 aspect注解
3. 如果是aspect，那么遍历类中除了 Pointcut注解的所有方法，也就是解析由 Around.class, Before.class, After.class, AfterReturning.class, AfterThrowing.class注解的方法，也就是得到了容器中所有的advisor

到此，容器中所有的advisor在bean实例化前就解析完成了。

下篇分析一下Aop的创建。







































































































































































































