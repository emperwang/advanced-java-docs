[TOC]

# springboot中的servlet的使用

大家有在springboot中使用自定义的servlet吗? 本篇准备介绍一下在springboot中是如何使用自定义servlet，以及如何把servlet注册到tomcat容器中的。

先看一下在springboot中如何使用自定义的servlet，方式有两种，咱们都说一下。

方式一:

首先定义一个servlet， 并使用WebServlet注解：

```java
@WebServlet(urlPatterns = "/demo1")
public class ServletDemo1 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().write("this is servlet demo 1");
        resp.getWriter().close();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
```

之后进行配置：

```java
@Configuration
@ServletComponentScan("com.bt")  // 注册此处路径，一定要包含上面定义的servlet
public class ServletConfig {

}
```

方式二:

首先定义一个servlet：

```java
public class ServletDemo2 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        PrintWriter writer = resp.getWriter();
        writer.write("this is  servlet demo2 ");
        writer.flush();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
```

使用配置类，添加到springboot中:

```java
@Configuration
public class ServletConfig {
    // 通过bean来创建一个servlet
    @Bean
    public ServletRegistrationBean servletRegistrationBean(){
        return new ServletRegistrationBean<ServletDemo2>(new ServletDemo2(), "/demo2");
    }
}
```

使用者两个方式都可以把servlet添加到tomcat中，并正常使用。当前了对于filter，以及listener使用方法都类似。

可以看到此两种方法的不同，后面会主要分析一下注解ServletComponentScan的作用，以及ServletRegistrationBean的作用，了解一下其是如何把servlet扫描到，并注册到tomcat中。

接下来，咱们先看一下注解的使用： ServletComponentScan

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
// 熟悉不,springboot的经典手段
// 注入一个bean到容器中中
// 一般此注入到容器中的bean, 会进一步注入一些后置处理器到容器(当前也有配置类),此注入的处理器会
// 处理对应的这些要实现的功能
@Import(ServletComponentScanRegistrar.class)
public @interface ServletComponentScan {
    @AliasFor("basePackages")
    String[] value() default {};
    @AliasFor("value")
    String[] basePackages() default {};
    Class<?>[] basePackageClasses() default {};
}
```

可以看到，进一步注入一个ServletComponentScanRegistrar到容器中，看一下此ServletComponentScanRegistrar的类图：

![](ServletComponentScanRegistrar.png)

可见此bean也是注册其他bean到容器中，看一下ServletComponentScanRegistrar此bean 具体的注册动作：

```java
// 注入一个bean到容器中
@Override
public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
    // 先获取注解中要扫描的路径
    Set<String> packagesToScan = getPackagesToScan(importingClassMetadata);
    // 先查看容器中是否存在了 servletComponentRegisteringPostProcessor  bean
    if (registry.containsBeanDefinition(BEAN_NAME)) {
        // 存在了,则进行更新
        updatePostProcessor(registry, packagesToScan);
    }
    else {
        // 没有存在则添加此bean 到容器中
        addPostProcessor(registry, packagesToScan);
    }
}
```

```java
// 更新servletComponentRegisteringPostProcessor beanDefinition的信息
private void updatePostProcessor(BeanDefinitionRegistry registry, Set<String> packagesToScan) {
    // 获取servletComponentRegisteringPostProcessor的beanDefinition
    BeanDefinition definition = registry.getBeanDefinition(BEAN_NAME);
    // 构造一个构造器参数
    ValueHolder constructorArguments = definition.getConstructorArgumentValues().getGenericArgumentValue(Set.class);
    @SuppressWarnings("unchecked")
    Set<String> mergedPackages = (Set<String>) constructorArguments.getValue();
    mergedPackages.addAll(packagesToScan);
    // 记录构造器参数
    constructorArguments.setValue(mergedPackages);
}
// 添加servletComponentRegisteringPostProcessor  的beanDefinition到容器中
private void addPostProcessor(BeanDefinitionRegistry registry, Set<String> packagesToScan) {
    // 创建一个beanDefinition
    GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
    // 设置此 bean的beanClass
    beanDefinition.setBeanClass(ServletComponentRegisteringPostProcessor.class);
    // 设置 构造器参数
    beanDefinition.getConstructorArgumentValues().addGenericArgumentValue(packagesToScan);
    // 记录bean的角色
    beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
    // 注册beanDefinition
    registry.registerBeanDefinition(BEAN_NAME, beanDefinition);
}
// 从注解的属性信息中 获取要扫描的路径
private Set<String> getPackagesToScan(AnnotationMetadata metadata) {
    // 先获取此注解的 属性信息
    AnnotationAttributes attributes = AnnotationAttributes
        .fromMap(metadata.getAnnotationAttributes(ServletComponentScan.class.getName()));
    // 获取要扫描的路径
    String[] basePackages = attributes.getStringArray("basePackages");
    // 获取保存扫描路径的class
    Class<?>[] basePackageClasses = attributes.getClassArray("basePackageClasses");
    // 保存要扫描的路径
    Set<String> packagesToScan = new LinkedHashSet<>();
    // 先把设置的路径记录
    packagesToScan.addAll(Arrays.asList(basePackages));
    // 获取设置的类的 package 路径, 以此作为要扫描的 路径
    for (Class<?> basePackageClass : basePackageClasses) {
        packagesToScan.add(ClassUtils.getPackageName(basePackageClass));
    }
    // 如果没有设置要扫描的路径信息,则使用 此注解所在类的package 路径作为扫描
    // 此是一个特殊的点哦
    if (packagesToScan.isEmpty()) {
        packagesToScan.add(ClassUtils.getPackageName(metadata.getClassName()));
    }
    return packagesToScan;
}
```

可以看地最终是注册一个ServletComponentRegisteringPostProcessor的容器中，从名字看是一个后置处理器，看一下ServletComponentRegisteringPostProcessor的类图，确定下其具体是否是后置处理器：

![](ServletComponentRegisteringPostProcessor.png)

可以看到此bean确实是一个后置处理器，那大概率上此bean就是对容器中的servlet的操作了。

看一下此bean的具体的处理，先看一下其初始化：

```java
// 记录一些处理器
private static final List<ServletComponentHandler> HANDLERS;
static {
    // 在静态代码块中添加一些 handler
    List<ServletComponentHandler> servletComponentHandlers = new ArrayList<>();
    servletComponentHandlers.add(new WebServletHandler());
    servletComponentHandlers.add(new WebFilterHandler());
    servletComponentHandlers.add(new WebListenerHandler());
    // 并记录到  HANDLERS
    HANDLERS = Collections.unmodifiableList(servletComponentHandlers);
}
// 记录要扫描的路径
private final Set<String> packagesToScan;
// 记录容器
private ApplicationContext applicationContext;
// 通过构造器 来注入 要扫描的路径
ServletComponentRegisteringPostProcessor(Set<String> packagesToScan) {
    this.packagesToScan = packagesToScan;
}
```

注解还可以，代码也比较清晰，进一步看一下其具体的处理动作：

> org.springframework.boot.web.servlet.ServletComponentRegisteringPostProcessor#postProcessBeanFactory

```java
// 此操作就是把具体的servlet注册到容器中,看一下其是如何进行处理的
@Override
public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
    // 此操作是,必须是web的情况下才进行; 很缜密
    if (isRunningInEmbeddedWebServer()) {
        // 创建一个 候选组件提供者CandidateComponentProvider
        ClassPathScanningCandidateComponentProvider componentProvider = createComponentProvider();
        // 对要扫描的各个路径,进行扫描动作,并把其注册到容器中
        for (String packageToScan : this.packagesToScan) {
            scanPackage(componentProvider, packageToScan);
        }
    }
}
```

> org.springframework.boot.web.servlet.ServletComponentRegisteringPostProcessor#createComponentProvider

```java
// 创建ClassPathScanningCandidateComponentProvider, 并把 初始化的处理器 记录到其中
private ClassPathScanningCandidateComponentProvider createComponentProvider() {
    // 创建动作
    ClassPathScanningCandidateComponentProvider componentProvider = new ClassPathScanningCandidateComponentProvider(
        false);
    // 记录 environment
    componentProvider.setEnvironment(this.applicationContext.getEnvironment());
    // 记录 resourceLoader
    componentProvider.setResourceLoader(this.applicationContext);
    // 添加 过滤类型
    for (ServletComponentHandler handler : HANDLERS) {
        // 其实这里的类型,在handler创建时就指定了
        // 如WebServletHandler 的typeFilter为 WebServlet 注解
        // 这里添加这些 filter, 那么在classpath中查找  潜在的候选者时,就会使用这些filter进行过滤
        // 符合的,才是候选组件
        componentProvider.addIncludeFilter(handler.getTypeFilter());
    }
    return componentProvider;
}

```

> org.springframework.boot.web.servlet.ServletComponentRegisteringPostProcessor#scanPackage

```java
// 对路径进行扫描动作
private void scanPackage(ClassPathScanningCandidateComponentProvider componentProvider, String packageToScan) {
    // 查找路径中潜在的  component
    // findCandidateComponents此处查找候选者,主要是根据上面添加的那些 TypeFilter来进行过滤的
    // 也就是扫描那些 带有 WebServlet  WebFilter WebListener注解的bean
    for (BeanDefinition candidate : componentProvider.findCandidateComponents(packageToScan)) {
        if (candidate instanceof AnnotatedBeanDefinition) {
            // 然后所有的候选者，进行处理
            for (ServletComponentHandler handler : HANDLERS) {
                // 处理候选者
                handler.handle(((AnnotatedBeanDefinition) candidate),
                               (BeanDefinitionRegistry) this.applicationContext);
            }
        }
    }
}
```

此就开始对扫描到的 servlet  beanDefinition进行处理了。后面会专门说一下ClassPathScanningCandidateComponentProvider是如何对classpath中的component进行扫描的，这里不多说，继续向下看看如何对beanDefinition的进一步处理：

> org.springframework.boot.web.servlet.ServletComponentHandler#handle

```java
// 对那些 带有 WebServlet  WebFilter  WebListener的bean的处理
void handle(AnnotatedBeanDefinition beanDefinition, BeanDefinitionRegistry registry) {
    // 当然了,这里就会根据具体的注解信息,最终匹配到合适的 处理器
    Map<String, Object> attributes = beanDefinition.getMetadata()
        .getAnnotationAttributes(this.annotationType.getName());
    // 运行到此,说明当前的处理器和此bean是符合的
    // 如 WebServletHandler 处理 WebServlet注解bean
    if (attributes != null) {
        // 模板方法,由具体处理器 子类来实现
        doHandle(attributes, beanDefinition, registry);
    }
}
```

这里提一下一个知识点，ServletComponentHandler的doHandle是属于模板方法，由具体的处理子类来进行实现，这里看一下三个子类，分别对应对 WebServlet，WebFilter，WebListener的处理：

看一下类图：

![](ServletComponentHandler.png)

> org.springframework.boot.web.servlet.WebServletHandler#doHandle

```java
// 对 WebServlet 注解bean的处理
@Override
public void doHandle(Map<String, Object> attributes, AnnotatedBeanDefinition beanDefinition,
                     BeanDefinitionRegistry registry) {
    // 创建一个 ServletRegistrationBean 的beanDefinitionBuilder
    BeanDefinitionBuilder builder = BeanDefinitionBuilder.rootBeanDefinition(ServletRegistrationBean.class);
    // 添加了各种 property value
    builder.addPropertyValue("asyncSupported", attributes.get("asyncSupported"));
    builder.addPropertyValue("initParameters", extractInitParameters(attributes));
    builder.addPropertyValue("loadOnStartup", attributes.get("loadOnStartup"));
    String name = determineName(attributes, beanDefinition);
    builder.addPropertyValue("name", name);
    // 此servlet 属性记录了 具体的servlet对应的 beanDefinition
    builder.addPropertyValue("servlet", beanDefinition);
    builder.addPropertyValue("urlMappings", extractUrlPatterns(attributes));
    builder.addPropertyValue("multipartConfig", determineMultipartConfig(beanDefinition));
    // 注册此beanDefinition到容器
    // 也就是说最终的 一个webServlet注解的bean,就会包装为一个 ServletRegistrationBean beanDefinition
    registry.registerBeanDefinition(name, builder.getBeanDefinition());
}
```

> org.springframework.boot.web.servlet.WebFilterHandler#doHandle

```java
// 对webFilter注解的bean的处理
@Override
public void doHandle(Map<String, Object> attributes, AnnotatedBeanDefinition beanDefinition,
                     BeanDefinitionRegistry registry) {
    // 创建一个FilterRegistrationBean 的beanDefinition的builder
    BeanDefinitionBuilder builder = BeanDefinitionBuilder.rootBeanDefinition(FilterRegistrationBean.class);
    // 记录此 filter是否支持异步处理
    builder.addPropertyValue("asyncSupported", attributes.get("asyncSupported"));
    builder.addPropertyValue("dispatcherTypes", extractDispatcherTypes(attributes));
    // 记录 filter对应的beanDefinition
    builder.addPropertyValue("filter", beanDefinition);
    // 此filter对应的初始化参数
    builder.addPropertyValue("initParameters", extractInitParameters(attributes));
    String name = determineName(attributes, beanDefinition);
    builder.addPropertyValue("name", name);
    builder.addPropertyValue("servletNames", attributes.get("servletNames"));
    // 此filter对应的 urlpattern
    builder.addPropertyValue("urlPatterns", extractUrlPatterns(attributes));
    // 记录此 FilterRegistrationBean的beanDefinition到容器中
    registry.registerBeanDefinition(name, builder.getBeanDefinition());
}
```

> org.springframework.boot.web.servlet.WebListenerHandler#doHandle

```java
@Override
protected void doHandle(Map<String, Object> attributes, AnnotatedBeanDefinition beanDefinition,
                        BeanDefinitionRegistry registry) {
    // 创建一个ServletListenerRegistrationBean beanDefinition的builder
    BeanDefinitionBuilder builder = BeanDefinitionBuilder.rootBeanDefinition(ServletListenerRegistrationBean.class);
    // 记录 具体的listener的 beanDefinition
    builder.addPropertyValue("listener", beanDefinition);
    // 记录此ServletListenerRegistrationBean 的beanDefinition到容器中
    registry.registerBeanDefinition(beanDefinition.getBeanClassName(), builder.getBeanDefinition());
}
```

这里就三个类型的bean处理完了，可以看到处理的最终结果: 

1. webServlet-->   ServletRegistrationBean
2. webFilter-->  FilterRegistrationBean
3. webListener-> ServletListenerRegistrationBean

到这里后置处理器就完事了，也没有注册到tomcat容器中啊，那么什么时候做的呢？  

既然无头绪，就看一下为什么把这些类都包装为这样，咱们先看一下此类的类图：

![](ServletRegistrationBean.png)

可以看到，这三个类都是ServletContextInitializer的子类，有没有感觉一些特殊呢？看起来是有些不一样，那就拿这个ServletRegistrationBean来分析一下：

> org.springframework.boot.web.servlet.RegistrationBean#onStartup

```java
	// 重载ServletContextInitializer的函数
	// 此操作会在 tomcat启动,也就是 standardContext 进行启动的时候,进行调用
	// servletContext 就是tomcat中的应用上下文, 也是在standardContext中创建的
	@Override
	public final void onStartup(ServletContext servletContext) throws ServletException {
		String description = getDescription();
		if (!isEnabled()) {
			logger.info(StringUtils.capitalize(description) + " was not registered (disabled)");
			return;
		}
		// 注册动作
		register(description, servletContext);
	}
```

> org.springframework.boot.web.servlet.DynamicRegistrationBean#register

```java
@Override
protected final void register(String description, ServletContext servletContext) {
    // 真实的注册操作
    // 返回动态注册的servlet的包装类 ServletRegistration.Dynamic
    D registration = addRegistration(description, servletContext);
    if (registration == null) {
        logger.info(
            StringUtils.capitalize(description) + " was not registered " + "(possibly already registered?)");
        return;
    }
    // 对动态注册的servlet 进行配置
    configure(registration);
}
```

> org.springframework.boot.web.servlet.ServletRegistrationBean#addRegistration

```java
@Override
protected ServletRegistration.Dynamic addRegistration(String description, ServletContext servletContext) {
    // 获取此servlet的name
    String name = getServletName();
    // 把servelt添加到tomcat的 standardContext中
    // 返回动态注册的servlet的包装类 ServletRegistration.Dynamic
    return servletContext.addServlet(name, this.servlet);
}
// tomcat中的实现
// 真正的注册
org.apache.catalina.core.ApplicationContext#addServlet(java.lang.String, javax.servlet.Servlet)
```

```java
// 如果设置了名字,则使用设置的名字
// 否则使用serlvet 全限定类的最后
// com.myapp.UKProduct becomes  "UKProduct"
public String getServletName() {
    return getOrDeduceName(this.servlet);
}

protected final String getOrDeduceName(Object value) {
    return (this.name != null) ? this.name : Conventions.getVariableName(value);
}
```

到此一个servlet就注册到tomcat容器中了。

那么这个动作具体什么时候操作的呢？ 回顾一下上篇tomcat的启动，其在启动前向Tomcat中设置了容器中的ServletContextInitializer类型的bean都注册到了tomcat中，那么tomcat中standardContext 启动时，就会调用此ServletContextInitializer的onStartup方法来进行注册操作。

回顾一下：

>  org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext#createWebServer

```java
// 创建webServer
private void createWebServer() {
    .....
        // 调用其getWebServer进行创建
// getSelfInitializer() 获取容器中的ServletContextInitializer并调用其onStartUp方法,此操作会把servelt
        // filter listener 注册到context中
        // todo * * * * 重要
        // getSelfInitializer() 此函数在此处只是返回一个函数
        // getWebServer 函数比较特殊,此处参数接收到了一个 函数
        this.webServer = factory.getWebServer(getSelfInitializer());
    .....   
}
```

这里getSelfInitializer() 主要就是向tomcat中注册了一个ServletContextInitializer，其在standardContext启动时，就会调用此selfInitialize方法，看一下此方法实现:

```java
// 这只是向tomcat中添加一个 ServletContextInitializer, 在context的start中执行
// 后面会看到,此操作是向 context注册 servlet的操作
private void selfInitialize(ServletContext servletContext) throws ServletException {
    // 1. 先尝试从servletContext中获取rootContext(即根容器),如果存在则报错
    // 2. 把当前的 applicationContext注册到  ServletContext
    // 3. 记录当前的servletContext
    prepareWebApplicationContext(servletContext);
    // 1. 注册 servlerScope 到容器中
    // 2  添加此scope到servletContext中
    registerApplicationScope(servletContext);
    WebApplicationContextUtils.registerEnvironmentBeans(getBeanFactory(), servletContext);
    // 获取容器中ServletContextInitializer
    // servletContextInitializer的onstartup方法调用其子类ServletRegistrationBean FilterRegistrationBean等的方法
    // 把servelt filter listener注册到了 tomcat中的context上
    for (ServletContextInitializer beans : getServletContextInitializerBeans()) {
        // 1. 此步骤会把servlet filter listener 注册到context上
        // 2.
        beans.onStartup(servletContext);
    }
}
```

重点就在最后，其调用了容器中所有的ServletContextInitializer的onStartup方法，这样也就是把servlet，filter，listener等注册到了tomcat容器中。

最后上面使用servlet的方法二，也就不用多解释了。











































































