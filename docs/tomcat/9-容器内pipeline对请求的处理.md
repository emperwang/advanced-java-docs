[TOC]

# 容器内部对请求的处理

上篇分析到，请求最后交由engine的 pipeline来进行处理了，本篇就就接着从这里进行下去。

```java
// 此处就是 engine的pipeline 进行处理了
connector.getService().getContainer().getPipeline().getFirst().invoke(request, response);
```

Engine的pipeline

> org.apache.catalina.core.StandardEngineValve#invoke

```java
// standardEngine 对请求的处理
@Override
public final void invoke(Request request, Response response)
    throws IOException, ServletException {
    // Select the Host to be used for this Request
    // 获取此处请求的host
    Host host = request.getHost();
    if (host == null) {
        response.sendError
            (HttpServletResponse.SC_BAD_REQUEST,
             sm.getString("standardEngine.noHost",
                          request.getServerName()));
        return;
    }
    // 是否支持异步处理
    if (request.isAsyncSupported()) {
        request.setAsyncSupported(host.getPipeline().isAsyncSupported());
    }

    // Ask this Host to process this request
    // 调用host的pipeline中第一个处理器进行处理
    host.getPipeline().getFirst().invoke(request, response);
}
```

host pipeline的处理：

> org.apache.catalina.core.StandardHostValve#invoke

```java
// standardHost pipeline中的 默认第一个处理器的入口
@Override
public final void invoke(Request request, Response response)
    throws IOException, ServletException {
    // Select the Context to be used for this Request
    // 获取请求中的context
    Context context = request.getContext();
    if (context == null) {
        return;
    }
    // 是否支持异步请求
    if (request.isAsyncSupported()) {
        request.setAsyncSupported(context.getPipeline().isAsyncSupported());
    }
    boolean asyncAtStart = request.isAsync();
    try {
        context.bind(Globals.IS_SECURITY_ENABLED, MY_CLASSLOADER);
        if (!asyncAtStart && !context.fireRequestInitEvent(request.getRequest())) {
            // Don't fire listeners during async processing (the listener
            // fired for the request that called startAsync()).
            // If a request init listener throws an exception, the request
            // is aborted.
            return;
        }
        // Ask this Context to process this request. Requests that are
        // already in error must have been routed here to check for
        // application defined error pages so DO NOT forward them to the the
        // application for processing.
        try {
            if (!response.isErrorReportRequired()) {
                // 调用context的pipeline 的第一个处理器进行处理
                // 进入下一级 容器继续进行处理
                context.getPipeline().getFirst().invoke(request, response);
            }
        } catch (Throwable t) {
            ExceptionUtils.handleThrowable(t);
            container.getLogger().error("Exception Processing " + request.getRequestURI(), t);
            // If a new error occurred while trying to report a previous
            // error allow the original error to be reported.
            if (!response.isErrorReportRequired()) {
                request.setAttribute(RequestDispatcher.ERROR_EXCEPTION, t);
                throwable(request, response, t);
            }
        }
        // Now that the request/response pair is back under container
        // control lift the suspension so that the error handling can
        // complete and/or the container can flush any remaining data
        response.setSuspended(false);
        Throwable t = (Throwable) request.getAttribute(RequestDispatcher.ERROR_EXCEPTION);
        // Protect against NPEs if the context was destroyed during a
        // long running request.
        if (!context.getState().isAvailable()) {
            return;
        }
        // Look for (and render if found) an application level error page
        if (response.isErrorReportRequired()) {
            if (t != null) {
                throwable(request, response, t);
            } else {
                status(request, response);
            }
        }
        if (!request.isAsync() && !asyncAtStart) {
            context.fireRequestDestroyEvent(request.getRequest());
        }
    } finally {
        // Access a session (if present) to update last accessed time, based
        // on a strict interpretation of the specification
        if (ACCESS_SESSION) {
            request.getSession(false);
        }
        context.unbind(Globals.IS_SECURITY_ENABLED, MY_CLASSLOADER);
    }
}
```

context的处理：

> org.apache.catalina.core.StandardContextValve#invoke

```java
// standardContext pipeline中的默认第一个处理器
@Override
public final void invoke(Request request, Response response)
    throws IOException, ServletException {
    // Disallow any direct access to resources under WEB-INF or META-INF
    // 获取请求的路径
    MessageBytes requestPathMB = request.getRequestPathMB();
    // 如果访问的路径不存在,设置返回状态码为404
    if ((requestPathMB.startsWithIgnoreCase("/META-INF/", 0))
        || (requestPathMB.equalsIgnoreCase("/META-INF"))
        || (requestPathMB.startsWithIgnoreCase("/WEB-INF/", 0))
        || (requestPathMB.equalsIgnoreCase("/WEB-INF"))) {
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
        return;
    }
    // Select the Wrapper to be used for this Request
    // 选择request对应的wrapper
    // 如果wrapper不存在,则返回404
    Wrapper wrapper = request.getWrapper();
    if (wrapper == null || wrapper.isUnavailable()) {
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
        return;
    }
    // Acknowledge the request
    try {
        response.sendAcknowledgement();
    } catch (IOException ioe) {
        container.getLogger().error(sm.getString(
            "standardContextValve.acknowledgeException"), ioe);
        request.setAttribute(RequestDispatcher.ERROR_EXCEPTION, ioe);
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        return;
    }
    if (request.isAsyncSupported()) {
        request.setAsyncSupported(wrapper.getPipeline().isAsyncSupported());
    }
    // 调用wrapper的pipeline
    wrapper.getPipeline().getFirst().invoke(request, response);
}
```

下面就开始调用wrapper的处理了，wrapper一般就对应servlet哦：

> org.apache.catalina.core.StandardWrapperValve#invoke

```java
// standardWrapper pipeline中第一个处理器
@Override
public final void invoke(Request request, Response response)
    throws IOException, ServletException {
    // Initialize local variables we may need
    boolean unavailable = false;
    Throwable throwable = null;
    // This should be a Request attribute...
    long t1=System.currentTimeMillis();
    // 请求次数增加,统计信息
    requestCount.incrementAndGet();
    // 获取此standardWrapperValue对应的standardWrapper
    StandardWrapper wrapper = (StandardWrapper) getContainer();
    Servlet servlet = null;
    Context context = (Context) wrapper.getParent();

    // Check for the application being marked unavailable
    if (!context.getState().isAvailable()) {
        response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                           sm.getString("standardContext.isUnavailable"));
        unavailable = true;
    }

    // Check for the servlet being marked unavailable
    if (!unavailable && wrapper.isUnavailable()) {
        container.getLogger().info(sm.getString("standardWrapper.isUnavailable",
                                                wrapper.getName()));
        long available = wrapper.getAvailable();
        if ((available > 0L) && (available < Long.MAX_VALUE)) {
            response.setDateHeader("Retry-After", available);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                               sm.getString("standardWrapper.isUnavailable",
                                            wrapper.getName()));
        } else if (available == Long.MAX_VALUE) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,sm.getString("standardWrapper.notFound",wrapper.getName()));
        }
        unavailable = true;
    }
    // Allocate a servlet instance to process this request
    try {
        if (!unavailable) {
            // servlet的加载
            servlet = wrapper.allocate();
        }
    } catch (UnavailableException e) {
        container.getLogger().error(sm.getString("standardWrapper.allocateException",wrapper.getName()), e);
        long available = wrapper.getAvailable();
        if ((available > 0L) && (available < Long.MAX_VALUE)) {
            response.setDateHeader("Retry-After", available);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, sm.getString("standardWrapper.isUnavailable",wrapper.getName()));
        } else if (available == Long.MAX_VALUE) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, sm.getString("standardWrapper.notFound",wrapper.getName()));
        }
    } catch (ServletException e) {
        container.getLogger().error(sm.getString("standardWrapper.allocateException", wrapper.getName()), StandardWrapper.getRootCause(e));
        throwable = e;
        exception(request, response, e);
    } catch (Throwable e) {
        ExceptionUtils.handleThrowable(e);
        container.getLogger().error(sm.getString("standardWrapper.allocateException",
                                                 wrapper.getName()), e);
        throwable = e;
        exception(request, response, e);
        servlet = null;
    }
    // 获取请求的路径
    MessageBytes requestPathMB = request.getRequestPathMB();
    DispatcherType dispatcherType = DispatcherType.REQUEST;
    if (request.getDispatcherType()==DispatcherType.ASYNC) dispatcherType = DispatcherType.ASYNC;
    request.setAttribute(Globals.DISPATCHER_TYPE_ATTR,dispatcherType);
    request.setAttribute(Globals.DISPATCHER_REQUEST_PATH_ATTR,
                         requestPathMB);
    // Create the filter chain for this request
    // 创建执行链,其中有过滤器 也有servlet, 之后执行servlet
    ApplicationFilterChain filterChain =
        ApplicationFilterFactory.createFilterChain(request, wrapper, servlet);
    // Call the filter chain for this request
    // NOTE: This also calls the servlet's service() method
    try {
        if ((servlet != null) && (filterChain != null)) {
            // Swallow output if needed
            if (context.getSwallowOutput()) {
                try {
                    SystemLogHandler.startCapture();
                    if (request.isAsyncDispatching()) {
                        request.getAsyncContextInternal().doInternalDispatch();
                    } else {
                        // 开始执行方法,最后执行到servlet
                        // 从过滤器开始执行,最后执行到 servlet
                        // 重点 重点
                        filterChain.doFilter(request.getRequest(), response.getResponse());
                    }
                } finally {
                    String log = SystemLogHandler.stopCapture();
                    if (log != null && log.length() > 0) {
                        context.getLogger().info(log);
                    }
                }
            } else {
                if (request.isAsyncDispatching()) {
                    request.getAsyncContextInternal().doInternalDispatch();
                } else {
                    filterChain.doFilter
                        (request.getRequest(), response.getResponse());
                }
            }

        }
    } catch (ClientAbortException | CloseNowException e) {
        if (container.getLogger().isDebugEnabled()) {
            container.getLogger().debug(sm.getString(
                "standardWrapper.serviceException", wrapper.getName(),
                context.getName()), e);
        }
        throwable = e;
        exception(request, response, e);
    } catch (IOException e) {
        container.getLogger().error(sm.getString(
            "standardWrapper.serviceException", wrapper.getName(),
            context.getName()), e);
        throwable = e;
        exception(request, response, e);
    } catch (UnavailableException e) {
        container.getLogger().error(sm.getString(
            "standardWrapper.serviceException", wrapper.getName(),
            context.getName()), e);
        //            throwable = e;
        //            exception(request, response, e);
        wrapper.unavailable(e);
        long available = wrapper.getAvailable();
        if ((available > 0L) && (available < Long.MAX_VALUE)) {
            response.setDateHeader("Retry-After", available);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                               sm.getString("standardWrapper.isUnavailable",
                                            wrapper.getName()));
        } else if (available == Long.MAX_VALUE) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                               sm.getString("standardWrapper.notFound",
                                            wrapper.getName()));
        }
        // Do not save exception in 'throwable', because we
        // do not want to do exception(request, response, e) processing
    } catch (ServletException e) {
        Throwable rootCause = StandardWrapper.getRootCause(e);
        if (!(rootCause instanceof ClientAbortException)) {
            container.getLogger().error(sm.getString(
                "standardWrapper.serviceExceptionRoot",
                wrapper.getName(), context.getName(), e.getMessage()), rootCause);
        }
        throwable = e;
        exception(request, response, e);
    } catch (Throwable e) {
        ExceptionUtils.handleThrowable(e);
        container.getLogger().error(sm.getString(
            "standardWrapper.serviceException", wrapper.getName(),
            context.getName()), e);
        throwable = e;
        exception(request, response, e);
    }
    // Release the filter chain (if any) for this request
    if (filterChain != null) {
        // 过滤器链的释放
        filterChain.release();
    }
    // Deallocate the allocated servlet instance
    try {
        if (servlet != null) {
            // 如果servlet没有实现SingleThreadModel  则把servlet添加到 instancePool,后续继续使用
            wrapper.deallocate(servlet);
        }
    } catch (Throwable e) {
        ExceptionUtils.handleThrowable(e);
        container.getLogger().error(sm.getString("standardWrapper.deallocateException",
                                                 wrapper.getName()), e);
        if (throwable == null) {
            throwable = e;
            exception(request, response, e);
        }
    }
    // If this servlet has been marked permanently unavailable,
    // unload it and release this instance
    try {
        if ((servlet != null) &&
            (wrapper.getAvailable() == Long.MAX_VALUE)) {
            // 销毁servlet
            // 调用其 destory 
            wrapper.unload();
        }
    } catch (Throwable e) {
        ExceptionUtils.handleThrowable(e);
        container.getLogger().error(sm.getString("standardWrapper.unloadException",
                                                 wrapper.getName()), e);
        if (throwable == null) {
            throwable = e;
            exception(request, response, e);
        }
    }
    long t2=System.currentTimeMillis();
    long time=t2-t1;
    processingTime += time;
    if( time > maxTime) maxTime=time;
    if( time < minTime) minTime=time;
}
```

这个函数比较长，但是处理流程还是比较清楚的：

1. 获取此value对应的wrapper，并进行servlet的加载
2. 记录此request的dispatcher类型(Async，request)以及请求路径到 request的属性中
3. 根据servlet，request创建执行链，此执行链中有过滤器和servlet
4. 执行执行链，从过滤器开始执行，最终执行到servlet
5. 释放执行链
6. 正常的servlet执行完，会销毁

看一下执行链的创建：

> org.apache.catalina.core.ApplicationFilterFactory#createFilterChain

```java
public static ApplicationFilterChain createFilterChain(ServletRequest request,
                                                       Wrapper wrapper, Servlet servlet) {

    // If there is no servlet to execute, return null
    // 如果不存在 servlet,则直接返回
    if (servlet == null)
        return null;
    // Create and initialize a filter chain object
    // 创建执行链
    ApplicationFilterChain filterChain = null;
    if (request instanceof Request) {
        Request req = (Request) request;
        if (Globals.IS_SECURITY_ENABLED) {
            // Security: Do not recycle
            filterChain = new ApplicationFilterChain();
        } else {
            filterChain = (ApplicationFilterChain) req.getFilterChain();
            if (filterChain == null) {
                filterChain = new ApplicationFilterChain();
                req.setFilterChain(filterChain);
            }
        }
    } else {
        // Request dispatcher in use
        filterChain = new ApplicationFilterChain();
    }
    // 记录servlet 到此执行链
    filterChain.setServlet(servlet);
    filterChain.setServletSupportsAsync(wrapper.isAsyncSupported());
    // Acquire the filter mappings for this Context
    StandardContext context = (StandardContext) wrapper.getParent();
    /**
         * 获取standardContext中注册的filterMap
         */
    FilterMap filterMaps[] = context.findFilterMaps();

    // If there are no filter mappings, we are done
    if ((filterMaps == null) || (filterMaps.length == 0))
        return filterChain;
    // Acquire the information we will need to match filter mappings
    // 获取 dispatcher 类型
    DispatcherType dispatcher =
        (DispatcherType) request.getAttribute(Globals.DISPATCHER_TYPE_ATTR);
    // 获取 请求的路径
    String requestPath = null;
    Object attribute = request.getAttribute(Globals.DISPATCHER_REQUEST_PATH_ATTR);
    if (attribute != null){
        // 请求路径
        requestPath = attribute.toString();
    }
    String servletName = wrapper.getName();
    // 下面两步,主要是添加过滤器到  执行链中

    // Add the relevant path-mapped filters to this filter chain
    // 遍历此context中所有的filterMap,来找到匹配当前requet的fileter
    for (int i = 0; i < filterMaps.length; i++) {
        // 根据DISPATCHER_TYPE_ATTR来判断是否匹配
        if (!matchDispatcher(filterMaps[i] ,dispatcher)) {
            continue;
        }
        // 根据url类匹配
        if (!matchFiltersURL(filterMaps[i], requestPath))
            continue;
        ApplicationFilterConfig filterConfig = (ApplicationFilterConfig)
            context.findFilterConfig(filterMaps[i].getFilterName());
        if (filterConfig == null) {
            // FIXME - log configuration problem
            continue;
        }
        // 有匹配的则,记录此 filter到执行链中
        filterChain.addFilter(filterConfig);
    }
    // Add filters that match on servlet name second
    // 把匹配 servlet name的过滤器 也添加进来
    for (int i = 0; i < filterMaps.length; i++) {
        if (!matchDispatcher(filterMaps[i] ,dispatcher)) {
            continue;
        }
        if (!matchFiltersServlet(filterMaps[i], servletName))
            continue;
        ApplicationFilterConfig filterConfig = (ApplicationFilterConfig)
            context.findFilterConfig(filterMaps[i].getFilterName());
        if (filterConfig == null) {
            // FIXME - log configuration problem
            continue;
        }
        filterChain.addFilter(filterConfig);
    }
    // Return the completed filter chain
    return filterChain;
}
```

执行链的执行：

> org.apache.catalina.core.ApplicationFilterChain#doFilter

```java
// 执行链的执行
@Override
public void doFilter(ServletRequest request, ServletResponse response)
    throws IOException, ServletException {

    if( Globals.IS_SECURITY_ENABLED ) {
        final ServletRequest req = request;
        final ServletResponse res = response;
        try {
            java.security.AccessController.doPrivileged(
                new java.security.PrivilegedExceptionAction<Void>() {
                    @Override
                    public Void run()
                        throws ServletException, IOException {
                        internalDoFilter(req,res);
                        return null;
                    }
                }
            );
        } catch( PrivilegedActionException pe) {
            Exception e = pe.getException();
            if (e instanceof ServletException)
                throw (ServletException) e;
            else if (e instanceof IOException)
                throw (IOException) e;
            else if (e instanceof RuntimeException)
                throw (RuntimeException) e;
            else
                throw new ServletException(e.getMessage(), e);
        }
    } else {
        // 指定filter
        internalDoFilter(request,response);
    }
}
```

> org.apache.catalina.core.ApplicationFilterChain#internalDoFilter

```java
private void internalDoFilter(ServletRequest request,
                              ServletResponse response)
    throws IOException, ServletException {

    // Call the next filter if there is one
    // 此处开始调用 filter对请求进行处理
    if (pos < n) {
        ApplicationFilterConfig filterConfig = filters[pos++];
        try {
            Filter filter = filterConfig.getFilter();
            if (request.isAsyncSupported() && "false".equalsIgnoreCase(
                filterConfig.getFilterDef().getAsyncSupported())) {
                request.setAttribute(Globals.ASYNC_SUPPORTED_ATTR, Boolean.FALSE);
            }
            if( Globals.IS_SECURITY_ENABLED ) {
                final ServletRequest req = request;
                final ServletResponse res = response;
                Principal principal =
                    ((HttpServletRequest) req).getUserPrincipal();
                Object[] args = new Object[]{req, res, this};
                SecurityUtil.doAsPrivilege ("doFilter", filter, classType, args, principal);
            } else {
                // 调用下一个filter
                // 具体的过滤 处理
                filter.doFilter(request, response, this);
            }
        } catch (IOException | ServletException | RuntimeException e) {
            throw e;
        } catch (Throwable e) {
            e = ExceptionUtils.unwrapInvocationTargetException(e);
            ExceptionUtils.handleThrowable(e);
            throw new ServletException(sm.getString("filterChain.filter"), e);
        }
        return;
    }
    // We fell off the end of the chain -- call the servlet instance
    try {
        if (ApplicationDispatcher.WRAP_SAME_OBJECT) {
            lastServicedRequest.set(request);
            lastServicedResponse.set(response);
        }
        if (request.isAsyncSupported() && !servletSupportsAsync) {
            request.setAttribute(Globals.ASYNC_SUPPORTED_ATTR,
                                 Boolean.FALSE);
        }
        // Use potentially wrapped request from this point
        if ((request instanceof HttpServletRequest) &&
            (response instanceof HttpServletResponse) &&
            Globals.IS_SECURITY_ENABLED ) {
            final ServletRequest req = request;
            final ServletResponse res = response;
            Principal principal =
                ((HttpServletRequest) req).getUserPrincipal();
            Object[] args = new Object[]{req, res};
            SecurityUtil.doAsPrivilege("service",
                                       servlet,
                                       classTypeUsedInService,
                                       args,
                                       principal);
        } else {
            // 最后调用servlet中的service方法
            // todo final final 调用service方法
            servlet.service(request, response);
        }
    } catch (IOException | ServletException | RuntimeException e) {
        throw e;
    } catch (Throwable e) {
        e = ExceptionUtils.unwrapInvocationTargetException(e);
        ExceptionUtils.handleThrowable(e);
        throw new ServletException(sm.getString("filterChain.servlet"), e);
    } finally {
        if (ApplicationDispatcher.WRAP_SAME_OBJECT) {
            lastServicedRequest.set(null);
            lastServicedResponse.set(null);
        }
    }
}
```

这里就很清楚了，调用过滤器的doFilter方法，以及最后调用servlet的serivce方法。

到此一个请求的处理完成了。

看一图，可能对上述处理就恍然大悟了：

![](../image/tomcat/PipelineValue.png)











































































































































