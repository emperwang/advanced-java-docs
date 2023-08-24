[TOC]

# HandlerExceotionResolvers 的初始化

回顾:

```java
@Override
protected void onRefresh(ApplicationContext context) {
    initStrategies(context);
}

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



![](HandlerExceptionResolver.png)

看一下其初始化的操作：

```java
private void initHandlerExceptionResolvers(ApplicationContext context) {
    this.handlerExceptionResolvers = null;
    // 先去容器中查找类型为  HandlerExceptionResolver的bean
    // 先去容器中查找,这就给了用于一个自定义的机会
    if (this.detectAllHandlerExceptionResolvers) {
        // Find all HandlerExceptionResolvers in the ApplicationContext, including ancestor contexts.
        Map<String, HandlerExceptionResolver> matchingBeans = BeanFactoryUtils
            .beansOfTypeIncludingAncestors(context, HandlerExceptionResolver.class, true, false);
        if (!matchingBeans.isEmpty()) {
            this.handlerExceptionResolvers = new ArrayList<>(matchingBeans.values());
            // We keep HandlerExceptionResolvers in sorted order.
            AnnotationAwareOrderComparator.sort(this.handlerExceptionResolvers);
        }
    }
    else {
        try {
            // 第二步: 去容器中查找指定名字的bean
            HandlerExceptionResolver her =
                context.getBean(HANDLER_EXCEPTION_RESOLVER_BEAN_NAME, HandlerExceptionResolver.class);
            this.handlerExceptionResolvers = Collections.singletonList(her);
        }
        catch (NoSuchBeanDefinitionException ex) {
            // Ignore, no HandlerExceptionResolver is fine too.
        }
    }

    // Ensure we have at least some HandlerExceptionResolvers, by registering
    // default HandlerExceptionResolvers if no other resolvers are found.
    // 第三步,都没有查找到,则使用默认策略中设置的class
    if (this.handlerExceptionResolvers == null) {
        this.handlerExceptionResolvers = getDefaultStrategies(context, HandlerExceptionResolver.class);
        if (logger.isTraceEnabled()) {
            logger.trace("No HandlerExceptionResolvers declared in servlet '" + getServletName() +
                         "': using default strategies from DispatcherServlet.properties");
        }
    }
}

```

此初始化同样是先从容器中查找，这个操作就给了用户去自定义的机会； 之后再容器中查找指定名字的bean；都没有查找到的话，最后使用默认策略中的设置。

默认策略：

```properties
org.springframework.web.servlet.HandlerExceptionResolver=org.springframework.web.servlet.mvc.method.annotation.ExceptionHandlerExceptionResolver,\
	org.springframework.web.servlet.mvc.annotation.ResponseStatusExceptionResolver,\
	org.springframework.web.servlet.mvc.support.DefaultHandlerExceptionResolver
```































