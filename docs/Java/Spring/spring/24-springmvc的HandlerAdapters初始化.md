[TOC]

# HandlerAdapter 初始化

回顾：

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



![](HandlerAdapter.png)

看一下具体的对HandlerAdapter的初始化操作：

```java
private void initHandlerAdapters(ApplicationContext context) {
    this.handlerAdapters = null;
    // 此和 handlerMapping 的配置类似, 先去容器中自动加载用户自定义的
    // 如果容器中没有用户自定义的,那么就使用默认的配置
    if (this.detectAllHandlerAdapters) {
        // Find all HandlerAdapters in the ApplicationContext, including ancestor contexts.
        Map<String, HandlerAdapter> matchingBeans =
            BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerAdapter.class, true, false);
        if (!matchingBeans.isEmpty()) {
            this.handlerAdapters = new ArrayList<>(matchingBeans.values());
            // We keep HandlerAdapters in sorted order.
            AnnotationAwareOrderComparator.sort(this.handlerAdapters);
        }
    }
    else {
        try {
            // 使用名字,从容器中查找
            HandlerAdapter ha = context.getBean(HANDLER_ADAPTER_BEAN_NAME, HandlerAdapter.class);
            this.handlerAdapters = Collections.singletonList(ha);
        }
        catch (NoSuchBeanDefinitionException ex) {
            // Ignore, we'll add a default HandlerAdapter later.
        }
    }

    // Ensure we have at least some HandlerAdapters, by registering
    // default HandlerAdapters if no other adapters are found.
    // 如果前面都没有查找到,则使用默认策略中设置的class
    if (this.handlerAdapters == null) {
        this.handlerAdapters = getDefaultStrategies(context, HandlerAdapter.class);
        if (logger.isTraceEnabled()) {
            logger.trace("No HandlerAdapters declared for servlet '" + getServletName() +
                         "': using default strategies from DispatcherServlet.properties");
        }
    }
}
```

此初始化同样是先从容器中查找，这个操作就给了用户去自定义的机会； 之后再容器中查找指定名字的bean；都没有查找到的话，最后使用默认策略中的设置。

默认策略：

```properties
org.springframework.web.servlet.HandlerAdapter=org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter,\
	org.springframework.web.servlet.mvc.SimpleControllerHandlerAdapter,\
	org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter
```



















































