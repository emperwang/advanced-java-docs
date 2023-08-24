[TOC]

# spring整合springMVC使用的一些配置及初始化

本篇回顾一下在使用spring和springmvc时，需要做的配置都有哪些？

首先是web.xml的配置:

```xml
<!-- spring 容器的配置文件,其中一般写入了service dao的bean,事务 aop -->
<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>classpath:spring.xml</param-value>
</context-param>
<!-- 配置一个监听器, 会主要分析此类的作用 -->
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>
<!-- 注册servlet -->
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <!-- springmvc的配置xml,其中一般配置controller以及和springmvc有关的其他bean -->
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:spring-mvc.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
<!-- dispatcherServlet的映射路径 -->
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>/</url-pattern>
</servlet-mapping>
```

看到此配置是否很熟悉呢？ 当然我是使用了很久这样的配置，不知大家是否和我有一样的疑惑，注册的那个监听器是干啥的，为什么有设置了一个context-param后，还要给servlet设置一个参数，并且两个参数都是一些spring配置的xml文件？

如果大家没有此疑惑，或者清楚这些原理，那么就可以不用浪费使用看本篇了，本篇的就是要说一些上面的那些配置都是做什么了。

那首先来看一下这个监听器的作用，老规矩，看一下类图：

![](ContextLoaderListener.png)

看到此类是一个tomcat中ServletContextListener的子类，而此类的调用呢，就在tomcat中standardContext的start阶段调用，调用的具体函数回顾一下：

> org.apache.catalina.core.StandardContext#listenerStart

```java
// 省略函数的部分主体  只看关键部分 
public boolean listenerStart() {
		........
        for (int i = 0; i < instances.length; i++) {
            if (!(instances[i] instanceof ServletContextListener))
                continue;
            ServletContextListener listener =
                (ServletContextListener) instances[i];
            try {
                fireContainerEvent("beforeContextInitialized", listener);
                if (noPluggabilityListeners.contains(listener)) {
                    // 在此处会调用监听器中的contextInitialized方法,
                 // 在springMVC和spring的整合中 web.xml中配置的监听器ContextLoaderListener 就在这里调用的
                    // 此监听器 ContextLoaderListener 创建了 XMLWebApplicationContext
                    listener.contextInitialized(tldEvent);
                } else {
                    listener.contextInitialized(event);
                }
                fireContainerEvent("afterContextInitialized", listener);
            } catch (Throwable t) {
			.......
            }
        }
        return ok;
    }
```

接下来，看一下此监听器的处理：

> org.springframework.web.context.ContextLoaderListener#contextInitialized

```java
/**
  * Initialize the root web application context.
*/
@Override
public void contextInitialized(ServletContextEvent event) {
    // 在监听器中创建root容器，也就是其他的业务bean存放
    // 正常情况下,没有controller相关的bean
    initWebApplicationContext(event.getServletContext());
}
```

具体的创建由ContextLoader来进行一些创建，看一下contextLoad的初始化代码

```java
// 默认策略存储在此文件中
private static final String DEFAULT_STRATEGIES_PATH = "ContextLoader.properties";

// 存储默认策略
private static final Properties defaultStrategies;

static {
    try {
        // 加载默认文档  ContextLoader.properties
        ClassPathResource resource = new ClassPathResource(DEFAULT_STRATEGIES_PATH, ContextLoader.class);
        // 把默认文档中的内容加载到  defaultStrategies
        defaultStrategies = PropertiesLoaderUtils.loadProperties(resource);
    }
    catch (IOException ex) {
        throw new IllegalStateException("Could not load 'ContextLoader.properties': " + ex.getMessage());
    }
}
```

ContextLoader.properties，记录了默认要创建的 applicationContext的类型：

```properties
org.springframework.web.context.WebApplicationContext=org.springframework.web.context.support.XmlWebApplicationContext
```

继续看一些此初始化context的操作：

```java
/**
	 * 1. 创建WebApplicationContext
	 * 2. 对容器进行刷新,也就是根据contextConfigLocation进行容器中bean的初始化
	 * 3. 把此容器记录到servletContext
	 */
public WebApplicationContext initWebApplicationContext(ServletContext servletContext) {
    // 先从servletContext获取一个root applicationContext,如果已经存在,则报错
    if (servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
        throw new IllegalStateException(
            "Cannot initialize context because there is already a root application context present - " +"check whether you have multiple ContextLoader* definitions in your web.xml!");
    }

    servletContext.log("Initializing Spring root WebApplicationContext");
    Log logger = LogFactory.getLog(ContextLoader.class);
    if (logger.isInfoEnabled()) {
        logger.info("Root WebApplicationContext: initialization started");
    }
    // 记录开始时间
    long startTime = System.currentTimeMillis();

    try {
        // Store context in local instance variable, to guarantee that
        // it is available on ServletContext shutdown.
        if (this.context == null) {
            //  创建root context
            // 默认创建XmlWebApplicationContext
            this.context = createWebApplicationContext(servletContext);
        }
        if (this.context instanceof ConfigurableWebApplicationContext) {
            ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) this.context;
            if (!cwac.isActive()) {
                // The context has not yet been refreshed -> provide services such as
                // setting the parent context, setting the application context id, etc
                if (cwac.getParent() == null) {
                    // The context instance was injected without an explicit parent ->
                    // determine parent for root web application context, if any.
                    // 设置父容器
                    // 第一次创建时,父容器为null
                    ApplicationContext parent = loadParentContext(servletContext);
                    cwac.setParent(parent);
                }
                // 对ApplicationContext进行配置
                // 1. wac.setServletContext(sc) 记录此容器对应的servletContext
                // 2. 设置contextConfigLocation
                // 3. wac.refresh()
                configureAndRefreshWebApplicationContext(cwac, servletContext);
            }
        }
        // 把容器记录到servletContext
        servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);

        ClassLoader ccl = Thread.currentThread().getContextClassLoader();
        if (ccl == ContextLoader.class.getClassLoader()) {
            currentContext = this.context;
        }
        else if (ccl != null) {
            currentContextPerThread.put(ccl, this.context);
        }

        if (logger.isInfoEnabled()) {
            long elapsedTime = System.currentTimeMillis() - startTime;
            logger.info("Root WebApplicationContext initialized in " + elapsedTime + " ms");
        }
        return this.context;
    }
    catch (RuntimeException | Error ex) {
        logger.error("Context initialization failed", ex);
      servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, ex);
        throw ex;
    }
}
```

> org.springframework.web.context.ContextLoader#createWebApplicationContext

```java
// 创建 webApplicationContext
protected WebApplicationContext createWebApplicationContext(ServletContext sc) {
    // 根据是否进行过配置,配置过则使用配置的
    // 没有配置的话,则使用ContextLoader.properties来进行配置,默认使用XmlWebApplicationContext
    Class<?> contextClass = determineContextClass(sc);
    if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
        throw new ApplicationContextException("Custom context class [" + contextClass.getName() +
        "] is not of type [" + ConfigurableWebApplicationContext.class.getName() + "]");
    }
    // 反射进行bean的创建
    return (ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);
}
```

决定来创建哪一个webApplicationContext：

> org.springframework.web.context.ContextLoader#determineContextClass

```java
// 根据是否在web.xml中对contextClass进行了配置
// 如果没有开发过的话,就默认使用XmlWebApplicationContext此类
protected Class<?> determineContextClass(ServletContext servletContext) {
    // 查看servletContext中是否制定的context的类型
    // 如果contextClass指定了类,则使用指定的class
    String contextClassName = servletContext.getInitParameter(CONTEXT_CLASS_PARAM);
    if (contextClassName != null) {
        try {
            return ClassUtils.forName(contextClassName, ClassUtils.getDefaultClassLoader());
        }
        catch (ClassNotFoundException ex) {
            throw new ApplicationContextException(
                "Failed to load custom context class [" + contextClassName + "]", ex);
        }
    }
    else {
        // 如果没有指定,则使用ContextLoader.properties中指定的context,为XmlWebApplicationContext
        contextClassName = defaultStrategies.getProperty(WebApplicationContext.class.getName());
        try {
            return ClassUtils.forName(contextClassName, ContextLoader.class.getClassLoader());
        }
        catch (ClassNotFoundException ex) {
            throw new ApplicationContextException(
                "Failed to load default context class [" + contextClassName + "]", ex);
        }
    }
}
```

如果contextClass指定了类,则使用指定的class，否则就加载默认策略的class，默认策略由上面可知是XmlWebApplicationContext。当此创建完了applicationContext后，后面开始指定其父容器，此时的父容器应该是null，下面继续对此applicationContext进行配置：

> org.springframework.web.context.ContextLoader#configureAndRefreshWebApplicationContext

```java
// 对创建的applicationContext进行配置, 并刷新
protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac, ServletContext sc) {
    if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
        // The application context id is still set to its original default value
        // -> assign a more useful id based on available information
        String idParam = sc.getInitParameter(CONTEXT_ID_PARAM);
        if (idParam != null) {
            wac.setId(idParam);
        }
        else {
            // Generate default id...
            wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
                      ObjectUtils.getDisplayString(sc.getContextPath()));
        }
    }
    // 把servletContext 记录到 applicationContext中
    wac.setServletContext(sc);
    // 获取父容器的配置文件路径,contextConfigLocation 属性的值
    String configLocationParam = sc.getInitParameter(CONFIG_LOCATION_PARAM);
    if (configLocationParam != null) {
        // 记录配置文件路径
        wac.setConfigLocation(configLocationParam);
    }

    // The wac environment's #initPropertySources will be called in any case when the context
    // is refreshed; do it eagerly here to ensure servlet property sources are in place for
    // use in any post-processing or initialization that occurs below prior to #refresh
    // 配置  servletContextInitParams  servletConfigInitParams  的值到环境变量中
    ConfigurableEnvironment env = wac.getEnvironment();
    if (env instanceof ConfigurableWebEnvironment) {
        ((ConfigurableWebEnvironment) env).initPropertySources(sc, null);
    }
    // 执行ApplicationContextInitializer,进行一些初始化动作
    // 是由这些 globalInitializerClasses contextInitializerClasses 配置项中指定的初始化类
    customizeContext(sc, wac);
    // 刷新容器
    wac.refresh();
}
```

到此一个xmlWebApplicationContext就创建完成了。

接下来看一下关于DispatcherServlet的相关初始化操作，先看一下其类图：

![](DispatcherServlet.png)

可以看到DispatcherServlet其实就是HttpServlet，其在使用前，需先调用其init方法进行初始化，然后才能正常使用。这里咱们先看一下其构造函数，然后看一下其init方法。

```java
public DispatcherServlet() {
    super();
    setDispatchOptionsRequest(true);
}
```

再看一下dispatcherServlet的静态代码块：

```java
// 存储默认策略的文件
	private static final String DEFAULT_STRATEGIES_PATH = "DispatcherServlet.properties";
// 存储默认的构造策略, 默认构造策略存储在DispatcherServlet.properties 文件中
	private static final Properties defaultStrategies;

	static {
		try {
			ClassPathResource resource = new ClassPathResource(DEFAULT_STRATEGIES_PATH, DispatcherServlet.class);
			defaultStrategies = PropertiesLoaderUtils.loadProperties(resource);
		}
		catch (IOException ex) {
			throw new IllegalStateException("Could not load '" + DEFAULT_STRATEGIES_PATH + "': " + ex.getMessage());
		}
	}
```

再看一下默认策略文件中存储的内容

```properties
org.springframework.web.servlet.LocaleResolver=org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver
org.springframework.web.servlet.ThemeResolver=org.springframework.web.servlet.theme.FixedThemeResolver
org.springframework.web.servlet.HandlerMapping=org.springframework.web.servlet.handler.BeanNameUrlHandlerMapping,\
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping

org.springframework.web.servlet.HandlerAdapter=org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter,\
org.springframework.web.servlet.mvc.SimpleControllerHandlerAdapter,\
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter

org.springframework.web.servlet.HandlerExceptionResolver=org.springframework.web.servlet.mvc.method.annotation.ExceptionHandlerExceptionResolver,\
org.springframework.web.servlet.mvc.annotation.ResponseStatusExceptionResolver,\
org.springframework.web.servlet.mvc.support.DefaultHandlerExceptionResolver

org.springframework.web.servlet.RequestToViewNameTranslator=org.springframework.web.servlet.view.DefaultRequestToViewNameTranslator

org.springframework.web.servlet.ViewResolver=org.springframework.web.servlet.view.InternalResourceViewResolver

org.springframework.web.servlet.FlashMapManager=org.springframework.web.servlet.support.SessionFlashMapManager
```

dispatcherServlet的构造函数就到此，下面继续看一下其init初始化方法:

> org.springframework.web.servlet.HttpServletBean#init

```java
// dispatcherServlet 会先调用其初始化方法,之后才能正常使用
@Override
public final void init() throws ServletException {

    // Set bean properties from init parameters.
    // todo 这里会把此servlet的init-param进行设置
    PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
    if (!pvs.isEmpty()) {
        try {
            // 把当前的 dispatcherServlet封装为 BeanWrapper
            BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
            ResourceLoader resourceLoader = new ServletContextResourceLoader(getServletContext());
            bw.registerCustomEditor(Resource.class, new ResourceEditor(resourceLoader, getEnvironment()));
            initBeanWrapper(bw);
            // 把 servelt的init paramer 通过反射设置到bean中
            bw.setPropertyValues(pvs, true);
        }
        catch (BeansException ex) {
            if (logger.isErrorEnabled()) {
            logger.error("Failed to set bean properties on servlet '" + getServletName() + "'", ex);
            }
            throw ex;
        }
    }

    // Let subclasses do whatever initialization they like.
    // 子类进行扩展
    // 在子类中常见 web 的子容器
    initServletBean();
}
```

此函数小结一下：

1. 获取此servlet的初始化函数，也就是前面配置的springmvc.xml配置文件路径
2. 之后吧此servlet封装为 beanWrapper
3. 把上面的初始化函数设置到此 beanWrapper
4. 在子类的initServletBean中创建子容器，可以称为 servlet容器

上面设置init-parameter的操作就不细说了，下面看一下创建子容器的操作：

> org.springframework.web.servlet.FrameworkServlet#initServletBean

```java
@Override
protected final void initServletBean() throws ServletException {
    getServletContext().log("Initializing Spring " + getClass().getSimpleName() + " '" + getServletName() + "'");
    // 记录开始时间
    long startTime = System.currentTimeMillis();

    try {
        // 初始化webApplicationContext
        // 如果没有呢,就进行创建
        this.webApplicationContext = initWebApplicationContext();
        // 用于扩展
        initFrameworkServlet();
    }
    catch (ServletException | RuntimeException ex) {
        logger.error("Context initialization failed", ex);
        throw ex;
    }

    if (logger.isDebugEnabled()) {
        String value = this.enableLoggingRequestDetails ?
            "shown which may lead to unsafe logging of potentially sensitive data" :
        "masked to prevent unsafe logging of potentially sensitive data";
        logger.debug("enableLoggingRequestDetails='" + this.enableLoggingRequestDetails +
                     "': request parameters and headers will be " + value);
    }

    if (logger.isInfoEnabled()) {
        logger.info("Completed initialization in " + (System.currentTimeMillis() - startTime) + " ms");
    }
}
```

> org.springframework.web.servlet.FrameworkServlet#initWebApplicationContext

```java
// 初始化 webApplicationContext,如果没有,就进行创建
protected WebApplicationContext initWebApplicationContext() {
    // 从servletContext中取获取root容器
    WebApplicationContext rootContext =
        WebApplicationContextUtils.getWebApplicationContext(getServletContext());
    WebApplicationContext wac = null;
    // 如果当亲servlet对应的  webApplicationContext 存在,即不为null
    if (this.webApplicationContext != null) {
        // A context instance was injected at construction time -> use it
        // 记录此 webApplicationContext
        wac = this.webApplicationContext;
        if (wac instanceof ConfigurableWebApplicationContext) {
            // 类型转换
            ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) wac;
            // 没有激活
            if (!cwac.isActive()) {
                // The context has not yet been refreshed -> provide services such as
                // setting the parent context, setting the application context id, etc
                if (cwac.getParent() == null) {
                    // The context instance was injected without an explicit parent -> set
                    // the root application context (if any; may be null) as the parent
                    // 设置其 父容器为 rootContext
                    cwac.setParent(rootContext);
                }
                // 进行配置,及进行 refresh
                configureAndRefreshWebApplicationContext(cwac);
            }
        }
    }
    // 如果当前servlet没有webApplicationContext
    if (wac == null) {
        // No context instance was injected at construction time -> see if one
        // has been registered in the servlet context. If one exists, it is assumed
        // that the parent context (if any) has already been set and that the
        // user has performed any initialization such as setting the context id
        // 从 servletContext中去查找 applicationContext
        wac = findWebApplicationContext();
    }
    // 如果还没有找到 applicationContext,则创建一个
    if (wac == null) {
        // No context instance is defined for this servlet -> create a local one
        // 创建webApplication
        wac = createWebApplicationContext(rootContext);
    }
    // 是否接收到 刷新的事件
    if (!this.refreshEventReceived) {
        // Either the context is not a ConfigurableApplicationContext with refresh
        // support or the context injected at construction time had already been
        // refreshed -> trigger initial onRefresh manually here.
        synchronized (this.onRefreshMonitor) {
            // 进行dispatcherServlet其他组件的注册以及初始化
            onRefresh(wac);
        }
    }
    // 发布创建的 子applicationContext,即子容器
    if (this.publishContext) {
        // Publish the context as a servlet context attribute.
        // 把刚创建的子容器 放到 servletContext
        // 获取一个名字,名字格式为: SERVLET_CONTEXT_PREFIX + getServletName()
        //  SERVLET_CONTEXT_PREFIX = FrameworkServlet.class.getName() + ".CONTEXT."
        String attrName = getServletContextAttributeName();
        // 把创建的 applicationContext设置到 servletContext中
        getServletContext().setAttribute(attrName, wac);
    }
    return wac;
}
```

最终创建applicationContext后，同样会注册到servletContext中，属性名字为： FrameworkServlet.class.getName() + ".CONTEXT." + getServletName()， 由此可见可以同时注册多个dispatcherServlet。

这里看一下这个onRefresh方法：

> org.springframework.web.servlet.DispatcherServlet#onRefresh

```java
	/**
	 * This implementation calls {@link #initStrategies}.
	 * servlet.init 方法进行对此方法的调用,那就是说在dispatcher进行服务时,关于handlerMapping  
	 * handlerAdapter还有一些其他组件就初始化好了
	 */
	@Override
	protected void onRefresh(ApplicationContext context) {
		initStrategies(context);
	}

	/**
	 * Initialize the strategy objects that this servlet uses.
	 * <p>May be overridden in subclasses in order to initialize further strategy objects.
	 */
	// 初始化提供服务的组件
	protected void initStrategies(ApplicationContext context) {
		initMultipartResolver(context);
		initLocaleResolver(context);
		initThemeResolver(context);
		// 初始化handlerMapping
		initHandlerMappings(context);
		// 初始化HandlerAdapter
		initHandlerAdapters(context);
		// 初始化异常处理器
		// 此处会在此类ExceptionHandlerExceptionResolver中进行如下:
		// 1. controllerAdvice注解的bean的解析
		// 2. requestBodyAdvice  responseBodyAdvice切面
		initHandlerExceptionResolvers(context);
		initRequestToViewNameTranslator(context);
		initViewResolvers(context);
		initFlashMapManager(context);
	}
```

此步骤还是很重要的，此onRefresh操作初始化了dispatcherServlet的各个重要的组件。

那此onRefresh什么时候初始化呢？

看一下FrameworkServlet中的一个监听器：

```java
private class ContextRefreshListener implements ApplicationListener<ContextRefreshedEvent> {

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        FrameworkServlet.this.onApplicationEvent(event);
    }
}
```

```java
public void onApplicationEvent(ContextRefreshedEvent event) {
    this.refreshEventReceived = true;
    synchronized (this.onRefreshMonitor) {
        onRefresh(event.getApplicationContext());
    }
}
```

在看一下事件的发出时机点:

> org.springframework.context.support.AbstractApplicationContext#finishRefresh

```java
protected void finishRefresh() {
	......

    // Publish the final event.
    // 发布一个事件
    publishEvent(new ContextRefreshedEvent(this));
    .....
}
```

再看一下具体注册ContextRefreshListener此监听器到容器的操作：

> org.springframework.web.servlet.FrameworkServlet#createWebApplicationContext
>
> org.springframework.web.servlet.FrameworkServlet#configureAndRefreshWebApplicationContext

```java
protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac) {
    if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
        // The application context id is still set to its original default value
        // -> assign a more useful id based on available information
        if (this.contextId != null) {
            wac.setId(this.contextId);
        }
        else {
            // Generate default id...
            wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
ObjectUtils.getDisplayString(getServletContext().getContextPath()) + '/' + getServletName());
        }
    }

    wac.setServletContext(getServletContext());
    wac.setServletConfig(getServletConfig());
    wac.setNamespace(getNamespace());
    // 添加一个监听器,此监听器用于监听ContextRefreshedEvent事件
    // 此ContextRefreshListener 主要会用于调用dispatcherServlet的onRefresh方法,
    // 来进行具体的dispatcherServlet的组件初始化
    wac.addApplicationListener(new SourceFilteringListener(wac, new ContextRefreshListener()));
    ConfigurableEnvironment env = wac.getEnvironment();
    if (env instanceof ConfigurableWebEnvironment) {
        ((ConfigurableWebEnvironment) env).initPropertySources(getServletContext(), getServletConfig());
    }

    postProcessWebApplicationContext(wac);
    applyInitializers(wac);
    wac.refresh();
}
```

到此dispatcherServlet的初始化就完成了。

























