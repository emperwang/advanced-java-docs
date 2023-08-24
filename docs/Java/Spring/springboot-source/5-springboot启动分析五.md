[TOC]

# springBoot启动分析5

上篇分析到了banner的打印，本篇咱们继续分析。

先回顾一下:

```java
public ConfigurableApplicationContext run(String... args) {
    // 1. 开启计时器
    StopWatch stopWatch = new StopWatch();
    stopWatch.start();
    ConfigurableApplicationContext context = null;
    Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
    // 2. 设置java.awt.headless的属性值
    configureHeadlessProperty();
    // 3. 获取监听器
    SpringApplicationRunListeners listeners = getRunListeners(args);
    // 发布ApplicationStartingEvent 事件
    listeners.starting();
    try {
        // 把传递的参数 封装为一个对象 ApplicationArguments
        ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
        // 4. 准备 environment
        ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);
        // 配置要忽略的bean信息
        configureIgnoreBeanInfo(environment);
        // 5. 打印banner
        Banner printedBanner = printBanner(environment);
        // 6. 创建ApplicationContext
        // 对于web项目,应该会创建 AnnotationConfigServletWebServerApplicationContext
        // 注意:AnnotationConfigServletWebServerApplicationContext的父类 ServletWebServerApplicationContext
        // 重载了 onRefresh()方法, 当容器进行刷新操作是,会调用此方法, 此方法会创建 servlet容器
        context = createApplicationContext();
        // 获取SpringBootExceptionReporter的实例
        exceptionReporters = getSpringFactoriesInstances(SpringBootExceptionReporter.class,new Class[] { ConfigurableApplicationContext.class }, context);
        // 1). 设置一些功能bean,如: beanNameGenerate
        // 2). 调用spring.factories中的一些初始化方法
        // 3). 注册命令行参数bean到容器
        // 4). 加载资源
        // 5). 发布ApplicationPreparedEvent
        prepareContext(context, environment, listeners, applicationArguments, printedBanner);
        // 7. 容器刷新  IOC AOP 核心
        refreshContext(context);
        // 用于子类功能扩展的函数  spring的老套路
        afterRefresh(context, applicationArguments);
        // 停止计时
        stopWatch.stop();
        if (this.logStartupInfo) {
            new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), stopWatch);
        }
        // 8. 发布 ApplicationStartedEvent 事件
        listeners.started(context);
        // 9. 调用ApplicationRunner  CommandRunner的启动类
        callRunners(context, applicationArguments);
    }
    catch (Throwable ex) {
        // 处理异常
        handleRunFailure(context, ex, exceptionReporters, listeners);
        throw new IllegalStateException(ex);
    }
    try {
        // 发布ApplicationReadyEvent 事件
        listeners.running(context);
    }
    catch (Throwable ex) {
        handleRunFailure(context, ex, exceptionReporters, null);
        throw new IllegalStateException(ex);
    }
    return context;
}
```

继续向下，创建了ApplicationContext

> org.springframework.boot.SpringApplication#createApplicationContext

```java
public static final String DEFAULT_SERVLET_WEB_CONTEXT_CLASS = "org.springframework.boot."
    + "web.servlet.context.AnnotationConfigServletWebServerApplicationContext";

public static final String DEFAULT_REACTIVE_WEB_CONTEXT_CLASS = "org.springframework."
    + "boot.web.reactive.context.AnnotationConfigReactiveWebServerApplicationContext";

public static final String DEFAULT_CONTEXT_CLASS = "org.springframework.context."
    + "annotation.AnnotationConfigApplicationContext";
// 创建ApplicationContext
// 根据type，此处应该创建AnnotationConfigServletWebServerApplicationContext
protected ConfigurableApplicationContext createApplicationContext() {
    Class<?> contextClass = this.applicationContextClass;
    if (contextClass == null) {
        try {
            switch (this.webApplicationType) {
                case SERVLET:
                    contextClass = Class.forName(DEFAULT_SERVLET_WEB_CONTEXT_CLASS);
                    break;
                case REACTIVE:
                    contextClass = Class.forName(DEFAULT_REACTIVE_WEB_CONTEXT_CLASS);
                    break;
                default:
                    contextClass = Class.forName(DEFAULT_CONTEXT_CLASS);
            }
        }
        catch (ClassNotFoundException ex) {
            throw new IllegalStateException(
                "Unable create a default ApplicationContext, " + "please specify an ApplicationContextClass",ex);
        }
    }
    // 通过构造器进行创建
    return (ConfigurableApplicationContext) BeanUtils.instantiateClass(contextClass);
}
```

> org.springframework.beans.BeanUtils#instantiateClass(java.lang.Class<T>)

```java
public static <T> T instantiateClass(Class<T> clazz) throws BeanInstantiationException {
    Assert.notNull(clazz, "Class must not be null");
    if (clazz.isInterface()) {
        throw new BeanInstantiationException(clazz, "Specified class is an interface");
    } else {
        try {
            // 先获取  构造器
            // 使用构造器创建一个实例
            return instantiateClass(clazz.getDeclaredConstructor());
        } catch (NoSuchMethodException var3) {
            Constructor<T> ctor = findPrimaryConstructor(clazz);
            if (ctor != null) {
                return instantiateClass(ctor);
            } else {
                throw new BeanInstantiationException(clazz, "No default constructor found", var3);
            }
        } catch (LinkageError var4) {
            throw new BeanInstantiationException(clazz, "Unresolvable class definition", var4);
        }
    }
}
```

```java
public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
    Assert.notNull(ctor, "Constructor must not be null");
    try {
        // 使用构造器 实例化
        ReflectionUtils.makeAccessible(ctor);
        return KotlinDetector.isKotlinReflectPresent() && KotlinDetector.isKotlinType(ctor.getDeclaringClass()) ? BeanUtils.KotlinDelegate.instantiateClass(ctor, args) : ctor.newInstance(args);
    } catch (InstantiationException var3) {
        throw new BeanInstantiationException(ctor, "Is it an abstract class?", var3);
    } catch (IllegalAccessException var4) {
        throw new BeanInstantiationException(ctor, "Is the constructor accessible?", var4);
    } catch (IllegalArgumentException var5) {
        throw new BeanInstantiationException(ctor, "Illegal arguments for constructor", var5);
    } catch (InvocationTargetException var6) {
        throw new BeanInstantiationException(ctor, "Constructor threw exception", var6.getTargetException());
    }
}
```

继续向下分析，从spring.factories中获取SpringBootExceptionReporter对应的多个实例：

```java
getSpringFactoriesInstances(SpringBootExceptionReporter.class,
					new Class[] { ConfigurableApplicationContext.class }, context)
```

此处就不深入分析这里了。

继续向下，准备Context:

> org.springframework.boot.SpringApplication#prepareContext

```java
private void prepareContext(ConfigurableApplicationContext context, ConfigurableEnvironment environment,
                            SpringApplicationRunListeners listeners, ApplicationArguments applicationArguments, Banner printedBanner) {
    // 把 environment设置到 context
    context.setEnvironment(environment);
    // 1. 创建一个beanNameGenerator
    // 2. 设置classLoader
    // 3. addConversionService
    postProcessApplicationContext(context);
    // 调用从 spring.factories中加载的初始化,进行初始化一些操作
    // 执行 ApplicationContextInitializer.initialize
    applyInitializers(context);
    // 发布ApplicationContextInitializedEvent事件
    listeners.contextPrepared(context);
    if (this.logStartupInfo) {
        logStartupInfo(context.getParent() == null);
        logStartupProfileInfo(context);
    }
    // Add boot specific singleton beans
    // 把命令行传递的参数 注册到容器中
    ConfigurableListableBeanFactory beanFactory = context.getBeanFactory();
    beanFactory.registerSingleton("springApplicationArguments", applicationArguments);
    if (printedBanner != null) {
        beanFactory.registerSingleton("springBootBanner", printedBanner);
    }
    // 设置是否运行 beanDefinition的override
    if (beanFactory instanceof DefaultListableBeanFactory) {
        ((DefaultListableBeanFactory) beanFactory)
        .setAllowBeanDefinitionOverriding(this.allowBeanDefinitionOverriding);
    }
    // Load the sources
    // 获取SpringApplication.run 参数注册的 class
    Set<Object> sources = getAllSources();
    Assert.notEmpty(sources, "Sources must not be empty");
    // 加载bean到 容器中
    // 此处加载的bean,就有启动类
    // 此时 真正的启动到 就注册到 容器中了
    load(context, sources.toArray(new Object[0]));
    // 发布 ApplicationPreparedEvent 事件
    listeners.contextLoaded(context);
}
```

小结一下这里所做的工作：

1. 设置environment到 applicationContext中
2. 设置beanNameGenerator，classLoader， conversionService到applicationContext
3. 调用ApplicationContextInitializer.initialize对 applicationContext进行配置
4. 向listener 发布 ApplicationContextInitializedEvent 事件
5. 把命令行传递的参数，注册到 容器中
6. 设置是否允许beanDefinition进行覆盖
7. 获取SpringApplication.run方法通过参数注册的class，以及sources 加载到  容器中
8. 发布ApplicationPreparedEvent 事件到 listener

这里咱们深入看一下第7步，加载那些class到容器中：

> org.springframework.boot.SpringApplication#getAllSources

```java
public Set<Object> getAllSources() {
    Set<Object> allSources = new LinkedHashSet<>();
    if (!CollectionUtils.isEmpty(this.primarySources)) {
        // 此primarySources 是SpringApplication.run 参数注册的
        allSources.addAll(this.primarySources);
    }
    if (!CollectionUtils.isEmpty(this.sources)) {
        allSources.addAll(this.sources);
    }
    return Collections.unmodifiableSet(allSources);
}
```

> org.springframework.boot.SpringApplication#load

```java
protected void load(ApplicationContext context, Object[] sources) {
    if (logger.isDebugEnabled()) {
        logger.debug("Loading source " + StringUtils.arrayToCommaDelimitedString(sources));
    }
    // 创建了扫描器
    // AnnotatedBeanDefinitionReader  XmlBeanDefinitionReader  ClassPathBeanDefinitionScanner
    BeanDefinitionLoader loader = createBeanDefinitionLoader(getBeanDefinitionRegistry(context), sources);
    // 如果有 名称生成器  设置名称生成器
    if (this.beanNameGenerator != null) {
        loader.setBeanNameGenerator(this.beanNameGenerator);
    }
    // 资源加载器
    if (this.resourceLoader != null) {
        loader.setResourceLoader(this.resourceLoader);
    }
    // 设置 environment
    if (this.environment != null) {
        loader.setEnvironment(this.environment);
    }
    // 具体的加载动作
    loader.load();
}
```

```java
// 获取  beanDefinition registry
private BeanDefinitionRegistry getBeanDefinitionRegistry(ApplicationContext context) {
    if (context instanceof BeanDefinitionRegistry) {
        return (BeanDefinitionRegistry) context;
    }
    if (context instanceof AbstractApplicationContext) {
        return (BeanDefinitionRegistry) ((AbstractApplicationContext) context).getBeanFactory();
    }
    throw new IllegalStateException("Could not locate BeanDefinitionRegistry");
}
```

> org.springframework.boot.SpringApplication#createBeanDefinitionLoader

```java
protected BeanDefinitionLoader createBeanDefinitionLoader(BeanDefinitionRegistry registry, Object[] sources) {
    return new BeanDefinitionLoader(registry, sources);
}
```

```java
BeanDefinitionLoader(BeanDefinitionRegistry registry, Object... sources) {
    Assert.notNull(registry, "Registry must not be null");
    Assert.notEmpty(sources, "Sources must not be empty");
    this.sources = sources;
    // 注册扫描器
    this.annotatedReader = new AnnotatedBeanDefinitionReader(registry);
    // xml 文件扫描器
    this.xmlReader = new XmlBeanDefinitionReader(registry);
    if (isGroovyPresent()) {
        this.groovyReader = new GroovyBeanDefinitionReader(registry);
    }
    // classPath 扫描器
    this.scanner = new ClassPathBeanDefinitionScanner(registry);
    // 设置过滤器
    this.scanner.addExcludeFilter(new ClassExcludeFilter(sources));
}
```

下面就是具体的加载动作了：

> org.springframework.boot.BeanDefinitionLoader#load()

```java
// 记载资源到 容器中,资源可以是bean
public int load() {
    int count = 0;
    for (Object source : this.sources) {
        // 循环遍历,加载sources中的全部
        count += load(source);
    }
    return count;
}
```

```java
// 根据不同类型来进行加载
private int load(Object source) {
    Assert.notNull(source, "Source must not be null");
    // 如果是 class类型的加载
    if (source instanceof Class<?>) {
        return load((Class<?>) source);
    }
    // resource 类型的加载
    if (source instanceof Resource) {
        return load((Resource) source);
    }
    // packag类型的加载
    if (source instanceof Package) {
        // classPath 类型的加载
        return load((Package) source);
    }
    // 字符串类型加载
    if (source instanceof CharSequence) {
        return load((CharSequence) source);
    }
    throw new IllegalArgumentException("Invalid source type " + source.getClass());
}


// class 类型的加载
private int load(Class<?> source) {
    if (isGroovyPresent() && GroovyBeanDefinitionSource.class.isAssignableFrom(source)) {
        // Any GroovyLoaders added in beans{} DSL can contribute beans here
        GroovyBeanDefinitionSource loader = BeanUtils.instantiateClass(source, GroovyBeanDefinitionSource.class);
        load(loader);
    }
    // 判断是否是 component,即是否有@Component 注解
    if (isComponent(source)) {
        // 如果有,则使用注解扫描器进行读取
        this.annotatedReader.register(source);
        return 1;
    }
    return 0;
}
```

```java
// 判断是否是  component的方法
private boolean isComponent(Class<?> type) {
    // This has to be a bit of a guess. The only way to be sure that this type is
    // eligible is to make a bean definition out of it and try to instantiate it.
    // 有注册 Comonent 则表示就是 component
    if (AnnotationUtils.findAnnotation(type, Component.class) != null) {
        return true;
    }
    // Nested anonymous classes are not eligible for registration, nor are groovy
    // closures
    if (type.getName().matches(".*\\$_.*closure.*") || type.isAnonymousClass() || type.getConstructors() == null
        || type.getConstructors().length == 0) {
        return false;
    }
    return true;
}

```

上面就是对context的一些准备工作，继续向下，对context的一个refresh操作：

```java
// 7. 容器刷新  IOC AOP 核心
refreshContext(context);
```

> org.springframework.boot.SpringApplication#refreshContext

```java
private void refreshContext(ConfigurableApplicationContext context) {
    // 容器刷新  IOC AOP的实现
    refresh(context);
    if (this.registerShutdownHook) {
        try {
            // 注册关闭钩子函数
            context.registerShutdownHook();
        }
        catch (AccessControlException ex) {
            // Not allowed in some environments.
        }
    }
}
```

```java
// 刷新context的操作
protected void refresh(ApplicationContext applicationContext) {
    Assert.isInstanceOf(AbstractApplicationContext.class, applicationContext);
    ((AbstractApplicationContext) applicationContext).refresh();
}
```

> org.springframework.context.support.AbstractApplicationContext#refresh

spring容器的refresh重要性就不用再说了，容器的IOC，AOP，DI等基础功能，都是在refresh中完成的，在这里进行刷新后，一个context就创建完成了。

继续往后分析：

```java
// 用于子类功能扩展的函数  spring的老套路
afterRefresh(context, applicationArguments);
// 停止计时
stopWatch.stop();
```

其中afterRefresh，是一个扩展函数，spring的经典写法了，各种留后路，用于后来扩展。

>  org.springframework.util.StopWatch#stop

```java
public void stop() throws IllegalStateException {
    if (this.currentTaskName == null) {
        throw new IllegalStateException("Can't stop StopWatch: it's not running");
    }
    // 记录 应用的结束时间
    long lastTime = System.currentTimeMillis() - this.startTimeMillis;
    this.totalTimeMillis += lastTime;
    // 包装一下 taskInfo
    this.lastTaskInfo = new TaskInfo(this.currentTaskName, lastTime);
    if (this.keepTaskList) {
        this.taskList.add(this.lastTaskInfo);
    }
    ++this.taskCount;
    this.currentTaskName = null;
}
```

应用的启动时间，就是在这里进行了计算。

```java
// 8. 发布 ApplicationStartedEvent 事件
listeners.started(context);
// 9. 调用ApplicationRunner  CommandRunner的启动类
callRunners(context, applicationArguments);
```

之后，就是发布了ApplicationStartedEvent时间，以及调用ApplicationRunner  CommandRunner接口的方法。

> org.springframework.boot.SpringApplication#callRunners

```java
private void callRunners(ApplicationContext context, ApplicationArguments args) {
    List<Object> runners = new ArrayList<>();
    // 获取ApplicationRunner 类型的类
    runners.addAll(context.getBeansOfType(ApplicationRunner.class).values());
    // 获取CommandLineRunner 类型的类
    runners.addAll(context.getBeansOfType(CommandLineRunner.class).values());
    // 排序
    AnnotationAwareOrderComparator.sort(runners);
    // 调用其的run方法
    for (Object runner : new LinkedHashSet<>(runners)) {
        if (runner instanceof ApplicationRunner) {
            callRunner((ApplicationRunner) runner, args);
        }
        if (runner instanceof CommandLineRunner) {
            callRunner((CommandLineRunner) runner, args);
        }
    }
}
```

```java
private void callRunner(ApplicationRunner runner, ApplicationArguments args) {
    try {
        // 调用run方法
        (runner).run(args);
    }
    catch (Exception ex) {
        throw new IllegalStateException("Failed to execute ApplicationRunner", ex);
    }
}

private void callRunner(CommandLineRunner runner, ApplicationArguments args) {
    try {
        (runner).run(args.getSourceArgs());
    }
    catch (Exception ex) {
        throw new IllegalStateException("Failed to execute CommandLineRunner", ex);
    }
}
```

最后，再次发布一次事件：

```java
// 发布ApplicationReadyEvent 事件
listeners.running(context);
```

到这里整个应用，就启动完成了。

虽然到这里整个启动流程分析完成了，不过还请小伙伴注意一下，这里咱们只是分析了大体的主流程，对于其中各个监听器，以及其他 initialize 等所做的工作没有展开分析，这样呢看起来很简单，让大家没有什么心理负担。对于那些监听器，以及initialize等工作，后面会针对具体工作，来进行分析。





































