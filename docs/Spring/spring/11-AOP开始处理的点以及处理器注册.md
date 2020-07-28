[TOC]

# AOP 开始处理的点以及处理器注册

IOC，AOP，DI，事务这些都是耳熟能详的spring-core的功能了。前面大篇幅的分析了Spring的IOC以及DI的功能，从本篇，咱们开始进入AOP的功能解析。

先看一下Aop使用时的一些配置：

```java
@Configuration
// 此注解向容器中注入了aop相关的bean
@EnableAspectJAutoProxy
public class AopConfig {
	@Bean
	public Calculator calc(){
		return new CalculatorImpl();
	}

	@Bean
	public AspectConfig config(){
		return new AspectConfig();
	}
}
```

```java
@Aspect
public class AspectConfig {

	@Pointcut(value = "execution(* com.wk.aop.api.*.*(..))")
	public void MyPointcut(){}

	@Before(value = "MyPointcut()")
	public void beforeAdvise(JoinPoint jpt){
		System.out.printf("args : "+ Arrays.asList(jpt.getArgs()));
		System.out.println("before advise");
	}

	@After(value = "MyPointcut()")
	public void afterAdvise(){
		System.out.println("after advise");
	}

	@Around(value = "MyPointcut()")
	public Object around(ProceedingJoinPoint pjp){
		System.out.println("start around.");
		Object res = null;
		try {
			 res = pjp.proceed();
		} catch (Throwable throwable) {
			throwable.printStackTrace();
		}

		System.out.println("around end.");
		return res;
	}
}
```

```java
public class AopStarter {
	public static void main(String[] args) {
		// 注意AnnotationConfigApplicationContext的初始化,此初始化就会注册一些公共处理类到容器中
		AnnotationConfigApplicationContext applicationContext = new AnnotationConfigApplicationContext(AopConfig.class);

		Calculator calc = (Calculator) applicationContext.getBean("calc");
		calc.add(1,2);
	}
}
```



那么要开始分析Aop功能的话，从何入手呢？

前面咱们分析IOC以及DI的功能，就是根据applicationContext的一个初始化流程来分析，难道Aop不可以这么做吗？答案是可以这么做，不过刚开始分析的话，根本无从了解其开始的点，那么这个方法就不太可行。

还有一个点可以把握，在使用Aop时，多了一个注解：@EnableAspectJAutoProxy。可以从这个注解开始进行。

看一些这个注解：

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
// 向容器中注入了AspectJAutoProxyRegistrar bean
@Import(AspectJAutoProxyRegistrar.class)
public @interface EnableAspectJAutoProxy {
	boolean proxyTargetClass() default false;

	boolean exposeProxy() default false;

}
```

这里可以看到，这里向容器中注入了一个类：AspectJAutoProxyRegistrar，看一下其实现：

```java
// 此类呢,又向容器中注册了AnnotationAwareAspectJAutoProxyCreator 这个bean
class AspectJAutoProxyRegistrar implements ImportBeanDefinitionRegistrar {
    /**
	 * Register, escalate, and configure the AspectJ auto proxy creator based on the value
	 * of the @{@link EnableAspectJAutoProxy#proxyTargetClass()} attribute on the importing
	 * {@code @Configuration} class.
	 */
    @Override
    public void registerBeanDefinitions(
        AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        // 向容器中注册bean AnnotationAwareAspectJAutoProxyCreator
        // 可以看到此bean是一个beanPostProcessor,也就是说创建代理的时间点为bean初始化(也就是调用初始化方法后)后再创建的aop代理
        // 当前其同时 InstantiationAwareBeanPostProcessor, 猜测其在bean实例化(实例化就是调用其构造器方法) 前解析相关的aop切面信息
        // 那么就具体看一下这个类的实现
        AopConfigUtils.registerAspectJAnnotationAutoProxyCreatorIfNecessary(registry);

        AnnotationAttributes enableAspectJAutoProxy =
            AnnotationConfigUtils.attributesFor(importingClassMetadata, EnableAspectJAutoProxy.class);
        if (enableAspectJAutoProxy != null) {
            // 如有容器中存在internalAutoProxyCreator此bean,那么就设置其proxyTargetClass为true
            // 如果不存在, 则什么也不做
            if (enableAspectJAutoProxy.getBoolean("proxyTargetClass")) {
                AopConfigUtils.forceAutoProxyCreatorToUseClassProxying(registry);
            }
            // 如果容器中存在internalAutoProxyCreator 此bean, 那么就设置exposeProxy属性为true
            // 否则什么也 不做
            if (enableAspectJAutoProxy.getBoolean("exposeProxy")) {
                AopConfigUtils.forceAutoProxyCreatorToExposeProxy(registry);
            }
        }
    }

}
```

继续看一下注入的操作：

> org.springframework.aop.config.AopConfigUtils#registerAspectJAnnotationAutoProxyCreatorIfNecessary

```java
public static BeanDefinition registerAspectJAnnotationAutoProxyCreatorIfNecessary(BeanDefinitionRegistry registry) {
    return registerAspectJAnnotationAutoProxyCreatorIfNecessary(registry, null);
}

@Nullable
public static BeanDefinition registerAspectJAnnotationAutoProxyCreatorIfNecessary(
    BeanDefinitionRegistry registry, @Nullable Object source) {

    return registerOrEscalateApcAsRequired(AnnotationAwareAspectJAutoProxyCreator.class, registry, source);
}

```

> org.springframework.aop.config.AopConfigUtils#registerOrEscalateApcAsRequired

```java
// 注册或者 包装
@Nullable
private static BeanDefinition registerOrEscalateApcAsRequired(
    Class<?> cls, BeanDefinitionRegistry registry, @Nullable Object source) {

    Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
    // 如果容器中存在 这个AUTO_PROXY_CREATOR_BEAN_NAME bean,则进行一定的包装操作
    if (registry.containsBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME)) {
        BeanDefinition apcDefinition = registry.getBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME);
        if (!cls.getName().equals(apcDefinition.getBeanClassName())) {
            int currentPriority = findPriorityForClass(apcDefinition.getBeanClassName());
            int requiredPriority = findPriorityForClass(cls);
            if (currentPriority < requiredPriority) {
                apcDefinition.setBeanClassName(cls.getName());
            }
        }
        return null;
    }
    // 如果容器中不存在 AUTO_PROXY_CREATOR_BEAN_NAME 这个bean,那么就创建一个  并注册到容器中
    RootBeanDefinition beanDefinition = new RootBeanDefinition(cls);
    beanDefinition.setSource(source);
    beanDefinition.getPropertyValues().add("order", Ordered.HIGHEST_PRECEDENCE);
    beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
    registry.registerBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME, beanDefinition);
    return beanDefinition;
}
```

这里呢，主要的动作其实就是向容器中注入了AnnotationAwareAspectJAutoProxyCreator这个类。

看一下这个类的类图：

![](../../image/spring/AnnotationAwareAspectJAutoProxyCreator.png)

可以看到其是一个BeanPostProcessor，一个后置处理器，从名字也可以看出是跟Aop代理创建有关。由此可见Aop的处理是在bean 初始化之前或者初始化之后做的，后面咱们可以进入此AnnotationAwareAspectJAutoProxyCreator 中的 beanPostProcessor处理方法，具体看一下处理的时间点。

而且也看到此类是InstantiationAwareBeanPostProcessor的子类，而在类的处理是在bean初始化前做的，这一步又做了什么呢？ 这里就不卖关子了，这里解析了容器中的aspect，以及advisors。

下一篇咱们看一下对容器中aspect的解析。





































































