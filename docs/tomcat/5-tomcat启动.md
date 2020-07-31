[TOC]

# tomcat的启动

## 回顾

```java
tomcat.start();
```

```java
public void start() throws LifecycleException {
    getServer();
    getConnector();
    server.start();
}
```



## server启动

> org.apache.catalina.util.LifecycleBase#start

```java
@Override
public final synchronized void start() throws LifecycleException {
    if (LifecycleState.STARTING_PREP.equals(state) || LifecycleState.STARTING.equals(state) ||
        LifecycleState.STARTED.equals(state)) {
        if (log.isDebugEnabled()) {
            Exception e = new LifecycleException();
            log.debug(sm.getString("lifecycleBase.alreadyStarted", toString()), e);
        } else if (log.isInfoEnabled()) {
            log.info(sm.getString("lifecycleBase.alreadyStarted", toString()));
        }
        return;
    }
    if (state.equals(LifecycleState.NEW)) {
        init();
    } else if (state.equals(LifecycleState.FAILED)) {
        stop();
    } else if (!state.equals(LifecycleState.INITIALIZED) &&
               !state.equals(LifecycleState.STOPPED)) {
        invalidTransition(Lifecycle.BEFORE_START_EVENT);
    }
    try {
        setStateInternal(LifecycleState.STARTING_PREP, null, false);
        startInternal();
        if (state.equals(LifecycleState.FAILED)) {
            // This is a 'controlled' failure. The component put itself into the
            // FAILED state so call stop() to complete the clean-up.
            stop();
        } else if (!state.equals(LifecycleState.STARTING)) {
            // Shouldn't be necessary but acts as a check that sub-classes are
            // doing what they are supposed to.
            invalidTransition(Lifecycle.AFTER_START_EVENT);
        } else {
            setStateInternal(LifecycleState.STARTED, null, false);
        }
    } catch (Throwable t) {
        // This is an 'uncontrolled' failure so put the component into the
        // FAILED state and throw an exception.
        ExceptionUtils.handleThrowable(t);
        setStateInternal(LifecycleState.FAILED, null, false);
        throw new LifecycleException(sm.getString("lifecycleBase.startFail", toString()), t);
    }
}
```

> org.apache.catalina.core.StandardServer#startInternal

```java
// server的启动
@Override
protected void startInternal() throws LifecycleException {
    fireLifecycleEvent(CONFIGURE_START_EVENT, null);
    setState(LifecycleState.STARTING);
    globalNamingResources.start();
    // Start our defined Services
    synchronized (servicesLock) {
        for (int i = 0; i < services.length; i++) {
            services[i].start();
        }
    }
}
```

这里看到server的启动操作，重点主要是启动其子组件  service。

## service启动

> org.apache.catalina.core.StandardService#startInternal

```java
// service的启动
// 1. engine 的启动
// 2. mapperListener 的启动
// 3. connector的启动
@Override
protected void startInternal() throws LifecycleException {
    if(log.isInfoEnabled())
        log.info(sm.getString("standardService.start.name", this.name));
    setState(LifecycleState.STARTING);
    // Start our defined Container first
    if (engine != null) {
        synchronized (engine) {
            // engine的启动
            engine.start();
        }
    }
    // 线程池的启动
    synchronized (executors) {
        for (Executor executor: executors) {
            executor.start();
        }
    }
    // todo 重点 重点
    //此处会记录host  context  servlet这个container的映射关系，并记录到service中的mapper里面
    mapperListener.start();
    // Start our defined Connectors second
    synchronized (connectorsLock) {
        for (Connector connector: connectors) {
            try {
                // If it has already failed, don't try and start it
                if (connector.getState() != LifecycleState.FAILED) {
                    connector.start();
                }
            } catch (Exception e) {
                log.error(sm.getString(
                    "standardService.connector.startFailed",
                    connector), e);
            }
        }
    }
}
```

可见service启动，主要操作是：

1. engine的启动
2. executor的启动
3. mapperListener的启动
4. connector的启动

## engine的启动

> org.apache.catalina.core.StandardEngine#startInternal

```java
@Override
protected synchronized void startInternal() throws LifecycleException {
    // Log our server identification information
    if(log.isInfoEnabled())
        log.info( "Starting Servlet Engine: " + ServerInfo.getServerInfo());
    // Standard container startup
    super.startInternal();
}
```

> org.apache.catalina.core.ContainerBase#startInternal

```java
@Override
protected synchronized void startInternal() throws LifecycleException {

    // Start our subordinate components, if any
    logger = null;
    getLogger();
    // 是否是集群启动
    Cluster cluster = getClusterInternal();
    if (cluster instanceof Lifecycle) {
        ((Lifecycle) cluster).start();
    }
    Realm realm = getRealmInternal();
    if (realm instanceof Lifecycle) {
        ((Lifecycle) realm).start();
    }
    // Start our child containers, if any
    // 启动子类组件
    // 这里启动子类看起来好像是异步,不过调用完之后,立即等待回去返回值
    // 这样就转换为了  同步
    Container children[] = findChildren();
    List<Future<Void>> results = new ArrayList<>();
    for (int i = 0; i < children.length; i++) {
        //results.add(startStopExecutor.submit(new StartChild(children[i])));
        new StartChild(children[i]).call();
    }
    MultiThrowable multiThrowable = null;
    for (Future<Void> result : results) {
        try {
            // 上面看起来是异步操作,不过在此进行结果值的获取
            // 相当于 异步变同步
            result.get();
        } catch (Throwable e) {
            log.error(sm.getString("containerBase.threadedStartFailed"), e);
            if (multiThrowable == null) {
                multiThrowable = new MultiThrowable();
            }
            multiThrowable.add(e);
        }
    }
    if (multiThrowable != null) {
        throw new LifecycleException(sm.getString("containerBase.threadedStartFailed"),
                                     multiThrowable.getThrowable());
    }
    // Start the Valves in our pipeline (including the basic), if any
    // 启动 pipeline
    if (pipeline instanceof Lifecycle) {
        ((Lifecycle) pipeline).start();
    }
    setState(LifecycleState.STARTING);
    // Start our thread
    threadStart();
}
```

这里engine启动:

1. 启动子组件
2. pipeline启动
3. 启动一个后台进程(目前不是很清楚此后台进程作用  *************************************************************************)

子组件启动

> org.apache.catalina.core.ContainerBase.StartChild#StartChild

```java
private static class StartChild implements Callable<Void> {
    private Container child;
    public StartChild(Container child) {
        this.child = child;
    }
    @Override
    public Void call() throws LifecycleException {
        child.start();
        return null;
    }
}

```

engine下的子组件就是host，下面的子组件启动，就是host的启动

### host启动

> org.apache.catalina.core.StandardHost#startInternal

```java
@Override
protected synchronized void startInternal() throws LifecycleException {
    // Set error report valve
    String errorValve = getErrorReportValveClass();
    if ((errorValve != null) && (!errorValve.equals(""))) {
        try {
            boolean found = false;
            Valve[] valves = getPipeline().getValves();
            for (Valve valve : valves) {
                if (errorValve.equals(valve.getClass().getName())) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                Valve valve =
                    (Valve) Class.forName(errorValve).getConstructor().newInstance();
                getPipeline().addValve(valve);
            }
        } catch (Throwable t) {
            ExceptionUtils.handleThrowable(t);
            log.error(sm.getString(
                "standardHost.invalidErrorReportValveClass",
                errorValve), t);
        }
    }
    super.startInternal();
}
```

```java
@Override
protected synchronized void startInternal() throws LifecycleException {

    // Start our subordinate components, if any
    logger = null;
    getLogger();
    Cluster cluster = getClusterInternal();
    if (cluster instanceof Lifecycle) {
        ((Lifecycle) cluster).start();
    }
    Realm realm = getRealmInternal();
    if (realm instanceof Lifecycle) {
        ((Lifecycle) realm).start();
    }

    // Start our child containers, if any
    // 启动子类组件
    Container children[] = findChildren();
    List<Future<Void>> results = new ArrayList<>();
    for (int i = 0; i < children.length; i++) {
        //results.add(startStopExecutor.submit(new StartChild(children[i])));
        new StartChild(children[i]).call();
    }

    MultiThrowable multiThrowable = null;

    for (Future<Void> result : results) {
        try {
            // 上面看起来是异步操作,不过在此进行结果值的获取
            // 相当于 异步变同步
            result.get();
        } catch (Throwable e) {
            log.error(sm.getString("containerBase.threadedStartFailed"), e);
            if (multiThrowable == null) {
                multiThrowable = new MultiThrowable();
            }
            multiThrowable.add(e);
        }

    }
    if (multiThrowable != null) {
        throw new LifecycleException(sm.getString("containerBase.threadedStartFailed"),
                                     multiThrowable.getThrowable());
    }
    // Start the Valves in our pipeline (including the basic), if any
    // 启动 pipeline
    if (pipeline instanceof Lifecycle) {
        ((Lifecycle) pipeline).start();
    }
    setState(LifecycleState.STARTING);
    // Start our thread
    threadStart();
}
```

此步骤和 engine启动一样了，就不多说了，继续看一下context的启动

### context 启动

> org.apache.catalina.core.StandardContext#startInternal

```java
// context的启动操作
@Override
protected synchronized void startInternal() throws LifecycleException {

    if(log.isDebugEnabled())
        log.debug("Starting " + getBaseName());

    // Send j2ee.state.starting notification
    if (this.getObjectName() != null) {
        Notification notification = new Notification("j2ee.state.starting",
                                                     this.getObjectName(), sequenceNumber.getAndIncrement());
        broadcaster.sendNotification(notification);
    }
    setConfigured(false);
    boolean ok = true;
    // Currently this is effectively a NO-OP but needs to be called to
    // ensure the NamingResources follows the correct lifecycle
    if (namingResources != null) {
        namingResources.start();
    }
    // Post work directory
    /**
         * workdir的创建
         */
    postWorkDirectory();
    // Add missing components as necessary
    if (getResources() == null) {   // (1) Required by Loader
        if (log.isDebugEnabled())
            log.debug("Configuring default Resources");

        try {
            // 设置rootResources
            setResources(new StandardRoot(this));
        } catch (IllegalArgumentException e) {
            log.error(sm.getString("standardContext.resourcesInit"), e);
            ok = false;
        }
    }
    if (ok) {
        resourcesStart();
    }
    if (getLoader() == null) {
        WebappLoader webappLoader = new WebappLoader(getParentClassLoader());
        webappLoader.setDelegate(getDelegate());
        setLoader(webappLoader);
    }
    // An explicit cookie processor hasn't been specified; use the default
    if (cookieProcessor == null) {
        cookieProcessor = new Rfc6265CookieProcessor();
    }
    // Initialize character set mapper
    getCharsetMapper();
    // Validate required extensions
    boolean dependencyCheck = true;
    try {
        dependencyCheck = ExtensionValidator.validateApplication
            (getResources(), this);
    } catch (IOException ioe) {
        log.error(sm.getString("standardContext.extensionValidationError"), ioe);
        dependencyCheck = false;
    }
    if (!dependencyCheck) {
        // do not make application available if dependency check fails
        ok = false;
    }

    // Reading the "catalina.useNaming" environment variable
    String useNamingProperty = System.getProperty("catalina.useNaming");
    if ((useNamingProperty != null)
        && (useNamingProperty.equals("false"))) {
        useNaming = false;
    }
    if (ok && isUseNaming()) {
        if (getNamingContextListener() == null) {
            NamingContextListener ncl = new NamingContextListener();
            ncl.setName(getNamingContextName());
            ncl.setExceptionOnFailedWrite(getJndiExceptionOnFailedWrite());
            addLifecycleListener(ncl);
            setNamingContextListener(ncl);
        }
    }
    // Standard container startup
    if (log.isDebugEnabled())
        log.debug("Processing standard container startup");

    // Binding thread
    ClassLoader oldCCL = bindThread();

    try {
        if (ok) {
            // Start our subordinate components, if any
            Loader loader = getLoader();
            if (loader instanceof Lifecycle) {
                ((Lifecycle) loader).start();
            }
            // since the loader just started, the webapp classloader is now
            // created.
            setClassLoaderProperty("clearReferencesRmiTargets",
                                   getClearReferencesRmiTargets());
            setClassLoaderProperty("clearReferencesStopThreads",
                                   getClearReferencesStopThreads());
            setClassLoaderProperty("clearReferencesStopTimerThreads",
                                   getClearReferencesStopTimerThreads());
            setClassLoaderProperty("clearReferencesHttpClientKeepAliveThread",
                                   getClearReferencesHttpClientKeepAliveThread());
            setClassLoaderProperty("clearReferencesObjectStreamClassCaches",
                                   getClearReferencesObjectStreamClassCaches());
            setClassLoaderProperty("clearReferencesThreadLocals",
                                   getClearReferencesThreadLocals());

            // By calling unbindThread and bindThread in a row, we setup the
            // current Thread CCL to be the webapp classloader
            unbindThread(oldCCL);
            oldCCL = bindThread();
            // Initialize logger again. Other components might have used it
            // too early, so it should be reset.
            logger = null;
            getLogger();

            Realm realm = getRealmInternal();
            if(null != realm) {
                if (realm instanceof Lifecycle) {
                    ((Lifecycle) realm).start();
                }
                // Place the CredentialHandler into the ServletContext so
                // applications can have access to it. Wrap it in a "safe"
                // handler so application's can't modify it.
                CredentialHandler safeHandler = new CredentialHandler() {
                    @Override
                    public boolean matches(String inputCredentials, String storedCredentials) {
                        return getRealmInternal().getCredentialHandler().matches(inputCredentials, storedCredentials);
                    }

                    @Override
                    public String mutate(String inputCredentials) {
                        return getRealmInternal().getCredentialHandler().mutate(inputCredentials);
                    }
                };
                context.setAttribute(Globals.CREDENTIAL_HANDLER, safeHandler);
            }
            // Notify our interested LifecycleListeners
            fireLifecycleEvent(Lifecycle.CONFIGURE_START_EVENT, null);

            // Start our child containers, if not already started
            for (Container child : findChildren()) {
                if (!child.getState().isAvailable()) {
                    child.start();
                }
            }
            // Start the Valves in our pipeline (including the basic),
            // if any
            if (pipeline instanceof Lifecycle) {
                ((Lifecycle) pipeline).start();
            }
            // Acquire clustered manager
            Manager contextManager = null;
            Manager manager = getManager();
            if (manager == null) {
                if (log.isDebugEnabled()) {
                    log.debug(sm.getString("standardContext.cluster.noManager",
                                           Boolean.valueOf((getCluster() != null)),
                                           Boolean.valueOf(distributable)));
                }
                if ( (getCluster() != null) && distributable) {
                    try {
                        contextManager = getCluster().createManager(getName());
                    } catch (Exception ex) {
                        log.error("standardContext.clusterFail", ex);
                        ok = false;
                    }
                } else {
                    // 单例部署情况下  会创建 StandardManager
                    contextManager = new StandardManager();
                }
            }
            // Configure default manager if none was specified
            if (contextManager != null) {
                if (log.isDebugEnabled()) {
                    log.debug(sm.getString("standardContext.manager",
                                           contextManager.getClass().getName()));
                }
                // 记录创建的 contextManager
                setManager(contextManager);
            }

            if (manager!=null && (getCluster() != null) && distributable) {
                //let the cluster know that there is a context that is distributable
                //and that it has its own manager
                getCluster().registerManager(manager);
            }
        }
        if (!getConfigured()) {
            log.error(sm.getString("standardContext.configurationFail"));
            ok = false;
        }
        // We put the resources into the servlet context
        if (ok)
            getServletContext().setAttribute
            (Globals.RESOURCES_ATTR, getResources());
        if (ok ) {
            // 如果 instanceManager 为null
            // 那么在这里会创建一个
            if (getInstanceManager() == null) {
                javax.naming.Context context = null;
                if (isUseNaming() && getNamingContextListener() != null) {
                    context = getNamingContextListener().getEnvContext();
                }
                Map<String, Map<String, String>> injectionMap = buildInjectionMap(
                    getIgnoreAnnotations() ? new NamingResourcesImpl(): getNamingResources());
                // 创建一个 DefaultInstanceManager 保存起来
                setInstanceManager(new DefaultInstanceManager(context,
                                                              injectionMap, this, this.getClass().getClassLoader()));
            }
            getServletContext().setAttribute(
                InstanceManager.class.getName(), getInstanceManager());
            InstanceManagerBindings.bind(getLoader().getClassLoader(), getInstanceManager());
        }
        // Create context attributes that will be required
        if (ok) {
            getServletContext().setAttribute(
                JarScanner.class.getName(), getJarScanner());
        }
        // Set up the context init params
        // 1.创建applicationContext
        // 2.合并 contextParameter 和 application parameter
        // 3. 把上面合并的参数设置到 applicationContext中
        mergeParameters();
        // Call ServletContainerInitializers
        // 注意 调用 ServletContainerInitializers
        for (Map.Entry<ServletContainerInitializer, Set<Class<?>>> entry :
             initializers.entrySet()) {
            try {
                entry.getKey().onStartup(entry.getValue(),
                                         getServletContext());
            } catch (ServletException e) {
                log.error(sm.getString("standardContext.sciFail"), e);
                ok = false;
                break;
            }
        }
        // Configure and call application event listeners
        if (ok) {
            if (!listenerStart()) {
                log.error(sm.getString("standardContext.listenerFail"));
                ok = false;
            }
        }
        // Check constraints for uncovered HTTP methods
        // Needs to be after SCIs and listeners as they may programmatically
        // change constraints
        if (ok) {
            checkConstraintsForUncoveredMethods(findConstraints());
        }
        try {
            // Start manager
            Manager manager = getManager();
            if (manager instanceof Lifecycle) {
                ((Lifecycle) manager).start();
            }
        } catch(Exception e) {
            log.error(sm.getString("standardContext.managerFail"), e);
            ok = false;
        }
        // Configure and call application filters
        if (ok) {
            /**
                 *  启动filter
                 *  重点 重点
                 */
            if (!filterStart()) {
                log.error(sm.getString("standardContext.filterFail"));
                ok = false;
            }
        }
        // Load and initialize all "load on startup" servlets
        if (ok) {
            /**
                 * 加载此context中的servlet
                 * 重点
                 */
            if (!loadOnStartup(findChildren())){
                log.error(sm.getString("standardContext.servletFail"));
                ok = false;
            }
        }
        // Start ContainerBackgroundProcessor thread
        super.threadStart();
    } finally {
        // Unbinding thread
        unbindThread(oldCCL);
    }
    // Set available status depending upon startup success
    if (ok) {
        if (log.isDebugEnabled())
            log.debug("Starting completed");
    } else {
        log.error(sm.getString("standardContext.startFailed", getName()));
    }
    startTime=System.currentTimeMillis();
    // Send j2ee.state.running notification
    if (ok && (this.getObjectName() != null)) {
        Notification notification =
            new Notification("j2ee.state.running", this.getObjectName(),
                             sequenceNumber.getAndIncrement());
        broadcaster.sendNotification(notification);
    }
    // The WebResources implementation caches references to JAR files. On
    // some platforms these references may lock the JAR files. Since web
    // application start is likely to have read from lots of JARs, trigger
    // a clean-up now.
    getResources().gc();
    // Reinitializing if something went wrong
    if (!ok) {
        setState(LifecycleState.FAILED);
    } else {
        setState(LifecycleState.STARTING);
    }
}
```

如果函数的重要性都和长度有关系，那么此函数可谓是特别重要了。确实做了很多的工作，小结一下（我知道的）重要点：

1. 创建workdir 工作目录
2.  realm 跟认证相关的启动
3.  context的子组件的启动，也即是standardWrapper的启动
4.  context的pipeline的启动
5.  依据此context创建 applicationContext
6. 创建DefaultInstanceManager
7. 合并contextParameter和applicationParameter，并设置到applicationContext中
8. 调用 ServletContainerInitializer
9. listener 的实例化
10. filter的实例化，并调用其 init初始化方法
11. 加载servlet，并调用其init方法来进行初始化
12. 启动一个后台线程

这里主要看一下filter的实例化及初始化，servlet的加载以及初始化

> org.apache.catalina.core.StandardContext#filterStart

```java
// filter过滤器 开始
// 调用其 init 方法
public boolean filterStart() {

    if (getLogger().isDebugEnabled()) {
        getLogger().debug("Starting filters");
    }
    // Instantiate and record a FilterConfig for each defined filter
    boolean ok = true;
    synchronized (filterConfigs) {
        filterConfigs.clear();
        for (Entry<String,FilterDef> entry : filterDefs.entrySet()) {
            String name = entry.getKey();
            if (getLogger().isDebugEnabled()) {
                getLogger().debug(" Starting filter '" + name + "'");
            }
            try {
                // 使用此ApplicationFilterConfig包装一下  filter
                // 并在其中调用了 filter的init 初始化方法
                ApplicationFilterConfig filterConfig =
                    new ApplicationFilterConfig(this, entry.getValue());
                // 记录一下
                filterConfigs.put(name, filterConfig);
            } catch (Throwable t) {
                t = ExceptionUtils.unwrapInvocationTargetException(t);
                ExceptionUtils.handleThrowable(t);
                getLogger().error(sm.getString(
                    "standardContext.filterStart", name), t);
                ok = false;
            }
        }
    }
    return ok;
}
```

> org.apache.catalina.core.ApplicationFilterConfig#ApplicationFilterConfig

```java
ApplicationFilterConfig(Context context, FilterDef filterDef)
    throws ClassCastException, ClassNotFoundException, IllegalAccessException,
InstantiationException, ServletException, InvocationTargetException, NamingException,
IllegalArgumentException, NoSuchMethodException, SecurityException {

    super();
    // 此filter 对应的context
    this.context = context;
    // 此filter的定义
    this.filterDef = filterDef;
    // Allocate a new filter instance if necessary
    if (filterDef.getFilter() == null) {
        getFilter();
    } else {
        // 获取定义的filter
        this.filter = filterDef.getFilter();
        // 实例化filter
        getInstanceManager().newInstance(filter);
        // 调用 filter的init 方法进行初始化
        initFilter();
    }
}
```

```java
private void initFilter() throws ServletException {
    if (context instanceof StandardContext &&
        context.getSwallowOutput()) {
        try {
            SystemLogHandler.startCapture();
            filter.init(this);
        } finally {
            String capturedlog = SystemLogHandler.stopCapture();
            if (capturedlog != null && capturedlog.length() > 0) {
                getServletContext().log(capturedlog);
            }
        }
    } else {
        // 调用init方法
        filter.init(this);
    }

    // Expose filter via JMX
    registerJMX();
}
```

> org.apache.catalina.core.StandardContext#loadOnStartup

```java
// 记载 servlet
public boolean loadOnStartup(Container children[]) {
    // Collect "load on startup" servlets that need to be initialized
    TreeMap<Integer, ArrayList<Wrapper>> map = new TreeMap<>();
    for (int i = 0; i < children.length; i++) {
        Wrapper wrapper = (Wrapper) children[i];
        int loadOnStartup = wrapper.getLoadOnStartup();
        // 可见 loadOnStartup小于0的,不会在此处进行加载,而是懒加载,放在后面
        if (loadOnStartup < 0)
            continue;
        Integer key = Integer.valueOf(loadOnStartup);
        ArrayList<Wrapper> list = map.get(key);
        if (list == null) {
            list = new ArrayList<>();
            map.put(key, list);
        }
        list.add(wrapper);
    }
    // 开始加载那些 需要  立即加载的 servlet
    // Load the collected "load on startup" servlets
    for (ArrayList<Wrapper> list : map.values()) {
        for (Wrapper wrapper : list) {
            try {
                wrapper.load();
            } catch (ServletException e) {
                getLogger().error(sm.getString("standardContext.loadOnStartup.loadException",  getName(), wrapper.getName()), StandardWrapper.getRootCause(e));
                // NOTE: load errors (including a servlet that throws
                // UnavailableException from the init() method) are NOT
                // fatal to application startup
                // unless failCtxIfServletStartFails="true" is specified
                if(getComputedFailCtxIfServletStartFails()) {
                    return false;
                }
            }
        }
    }
    return true;
}
```

> org.apache.catalina.core.StandardWrapper#load

```java
// 记载servlet
@Override
public synchronized void load() throws ServletException {
    // 加载servlet
    instance = loadServlet();
    // 如果还没有初始化,则调用servlet的init 方法
    if (!instanceInitialized) {
        initServlet(instance);
    }
    if (isJspServlet) {
        StringBuilder oname = new StringBuilder(getDomain());
        oname.append(":type=JspMonitor");
        oname.append(getWebModuleKeyProperties());
        oname.append(",name=");
        oname.append(getName());
        oname.append(getJ2EEKeyProperties());
        try {
            jspMonitorON = new ObjectName(oname.toString());
            Registry.getRegistry(null, null).registerComponent(instance, jspMonitorON, null);
        } catch (Exception ex) {
            log.warn("Error registering JSP monitoring with jmx " + instance);
        }
    }
}
```

> org.apache.catalina.core.StandardWrapper#loadServlet

```java
public synchronized Servlet loadServlet() throws ServletException {

    // Nothing to do if we already have an instance or an instance pool
    if (!singleThreadModel && (instance != null))
        return instance;
    PrintStream out = System.out;
    if (swallowOutput) {
        SystemLogHandler.startCapture();
    }
    Servlet servlet;
    try {
        long t1=System.currentTimeMillis();
        // Complain if no servlet class has been specified
        if (servletClass == null) {
            unavailable(null);
            throw new ServletException
                (sm.getString("standardWrapper.notClass", getName()));
        }
        InstanceManager instanceManager = ((StandardContext)getParent()).getInstanceManager();
        try {
            // 创建  servlet 实例
            servlet = (Servlet) instanceManager.newInstance(servletClass);
        } catch (ClassCastException e) {
            unavailable(null);
            // Restore the context ClassLoader
            throw new ServletException
                (sm.getString("standardWrapper.notServlet", servletClass), e);
        } catch (Throwable e) {
            e = ExceptionUtils.unwrapInvocationTargetException(e);
            ExceptionUtils.handleThrowable(e);
            unavailable(null);
            // Added extra log statement for Bugzilla 36630:
            // https://bz.apache.org/bugzilla/show_bug.cgi?id=36630
            if(log.isDebugEnabled()) {
                log.debug(sm.getString("standardWrapper.instantiate", servletClass), e);
            }
            // Restore the context ClassLoader
            throw new ServletException
                (sm.getString("standardWrapper.instantiate", servletClass), e);
        }
        // 是否有此 MultipartConfig 注解
        if (multipartConfigElement == null) {
            MultipartConfig annotation =
                servlet.getClass().getAnnotation(MultipartConfig.class);
            if (annotation != null) {
                multipartConfigElement =
                    new MultipartConfigElement(annotation);
            }
        }
        // Special handling for ContainerServlet instances
        // Note: The InstanceManager checks if the application is permitted
        //       to load ContainerServlets
        if (servlet instanceof ContainerServlet) {
            ((ContainerServlet) servlet).setWrapper(this);
        }
        // 加载的时间
        classLoadTime=(int) (System.currentTimeMillis() -t1);
        if (servlet instanceof SingleThreadModel) {
            if (instancePool == null) {
                instancePool = new Stack<>();
            }
            singleThreadModel = true;
        }
        // 调用servlet的init方法
        initServlet(servlet);
        // 发布 load加载 事件
        fireContainerEvent("load", this);
        loadTime=System.currentTimeMillis() -t1;
    } finally {
        if (swallowOutput) {
            String log = SystemLogHandler.stopCapture();
            if (log != null && log.length() > 0) {
                if (getServletContext() != null) {
                    getServletContext().log(log);
                } else {
                    out.println(log);
                }
            }
        }
    }
    return servlet;
}
```

```java
    // 调用 servlet的init 方法
    private synchronized void initServlet(Servlet servlet)
            throws ServletException {
        if (instanceInitialized && !singleThreadModel) return;
        // Call the initialization method of this servlet
        try {
            if( Globals.IS_SECURITY_ENABLED) {
                boolean success = false;
                try {
                    Object[] args = new Object[] { facade };
                    SecurityUtil.doAsPrivilege("init", servlet, classType,args);
                    success = true;
                } finally {
                    if (!success) {
                        // destroy() will not be called, thus clear the reference now
                        SecurityUtil.remove(servlet);
                    }
                }
            } else {
                // 调用init方法
                servlet.init(facade);
            }
            instanceInitialized = true;
        } catch (UnavailableException f) {
        	....
        }
    }
```

applicationContext的创建

> org.apache.catalina.core.StandardContext#getServletContext

```java
public ServletContext getServletContext() {
    if (context == null) {
        // 创建applicationContext
        context = new ApplicationContext(this);
        if (altDDName != null)
            context.setAttribute(Globals.ALT_DD_ATTR,altDDName);
    }
    return context.getFacade();
}
```

### context子组件 standard启动

> org.apache.catalina.core.StandardWrapper#startInternal

```java
// standardWrapper的初始化
@Override
protected synchronized void startInternal() throws LifecycleException {

    // Send j2ee.state.starting notification
    if (this.getObjectName() != null) {
        Notification notification = new Notification("j2ee.state.starting",
                                                     this.getObjectName(),
                                                     sequenceNumber++);
        broadcaster.sendNotification(notification);
    }
    // Start up this component
    super.startInternal();
    setAvailable(0L);
    // Send j2ee.state.running notification
    if (this.getObjectName() != null) {
        Notification notification =
            new Notification("j2ee.state.running", this.getObjectName(),
                             sequenceNumber++);
        broadcaster.sendNotification(notification);
    }
}
```



## mapperlistener的启动

> org.apache.catalina.mapper.MapperListener#startInternal

```java
/**
     * 解析host  context  servlet的映射关系,并记录到mapper里面
     */
@Override
public void startInternal() throws LifecycleException {
    setState(LifecycleState.STARTING);
    // 获取此 mapperListener 注册的service 对应的 engine
    Engine engine = service.getContainer();
    if (engine == null) {
        return;
    }
    findDefaultHost();
    // 给engine及其子容器 也添加上此listener
    addListeners(engine);
    // 找到engine的host, 并注册其信息
    Container[] conHosts = engine.findChildren();
    for (Container conHost : conHosts) {
        Host host = (Host) conHost;
        if (!LifecycleState.NEW.equals(host.getState())) {
            // Registering the host will register the context and wrappers
            // 把host的信息注册保存起来, 用于后面请求来时候,比对该请求对应到那个host上
            registerHost(host);
        }
    }
}
```

给engine及其子组件添加listener

```java
    private void addListeners(Container container) {
        container.addContainerListener(this);
        container.addLifecycleListener(this);
        for (Container child : container.findChildren()) {
            addListeners(child);
        }
    }
```

> org.apache.catalina.mapper.MapperListener#registerHost

```java
private void registerHost(Host host) {
    // 获取host的别名
    String[] aliases = host.findAliases();
    // 把host信息记录到 hosts
    // 此中的mapper是由 service中传递进来的
    // 也就是说,此注册完成后,service也可以使用其中的注册信息
    mapper.addHost(host.getName(), aliases, host);
    // 把host对应的子 context容器也进行注册保存
    for (Container container : host.findChildren()) {
        if (container.getState().isAvailable()) {
            // 注册context信息
            registerContext((Context) container);
        }
    }
    if(log.isDebugEnabled()) {
        log.debug(sm.getString("mapperListener.registerHost",
                               host.getName(), domain, service));
    }
}
```

此也就不细说了，后面专门开篇讲一下。



## connector的启动

> org.apache.catalina.connector.Connector#startInternal

```java
protected void startInternal() throws LifecycleException {
    // Validate settings before starting
    if (getPort() < 0) {
        throw new LifecycleException(sm.getString(
            "coyoteConnector.invalidPort", Integer.valueOf(getPort())));
    }
    setState(LifecycleState.STARTING);
    try {
        protocolHandler.start();
    } catch (Exception e) {
        throw new LifecycleException(
            sm.getString("coyoteConnector.protocolHandlerStartFailed"), e);
    }
}
```

> org.apache.coyote.AbstractProtocol#start

```java
@Override
public void start() throws Exception {
    if (getLog().isInfoEnabled()) {
        getLog().info(sm.getString("abstractProtocolHandler.start", getName()));
    }
    endpoint.start();
    // Start async timeout thread
    // 处理异步请求的超时 后台线程
    asyncTimeout = new AsyncTimeout();
    Thread timeoutThread = new Thread(asyncTimeout, getNameInternal() + "-AsyncTimeout");
    int priority = endpoint.getThreadPriority();
    if (priority < Thread.MIN_PRIORITY || priority > Thread.MAX_PRIORITY) {
        priority = Thread.NORM_PRIORITY;
    }
    timeoutThread.setPriority(priority);
    timeoutThread.setDaemon(true);
    timeoutThread.start();
}
```

> org.apache.tomcat.util.net.AbstractEndpoint#start

```java
public final void start() throws Exception {
    if (bindState == BindState.UNBOUND) {
        bind();
        bindState = BindState.BOUND_ON_START;
    }
    // 此处是NioEndpoint
    startInternal();
}
```

> org.apache.tomcat.util.net.NioEndpoint#startInternal

```java
// socket接收的 后台线程
@Override
public void startInternal() throws Exception {
    if (!running) {
        running = true;
        paused = false;
        // 默认长度大小为 128
        // 三个缓存的 列表都是 128
        processorCache = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                                 socketProperties.getProcessorCache());
        eventCache = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                             socketProperties.getEventCache());
        nioChannels = new SynchronizedStack<>(SynchronizedStack.DEFAULT_SIZE,
                                              socketProperties.getBufferPool());

        // Create worker collection
        // 创建  executor
        if ( getExecutor() == null ) {
            createExecutor();
        }
        // 限流使用
        // 变相的限制 连接数
        initializeConnectionLatch();
        // Start poller threads
        // 控制pollers线程数量的是
        // pollerThreadCount = Math.min(2,Runtime.getRuntime().availableProcessors())
        // poller 用于进行 读写处理
        pollers = new Poller[getPollerThreadCount()];
        for (int i=0; i<pollers.length; i++) {
            // 看一下poller的run方法
            pollers[i] = new Poller();
            Thread pollerThread = new Thread(pollers[i], getName() + "-ClientPoller-"+i);
            pollerThread.setPriority(threadPriority);
            //pollerThread.setDaemon(true);
            // 同步
            pollerThread.setDaemon(false);
            pollerThread.start();
        }
        // 接收器 用于接收
        startAcceptorThreads();
    }
}
```

可以看到这里启动了一个socket接收线程，以及多个poller来对接收的socket读写处理。这个模型，说实话，跟netty在模型上实在是太相像了，基本上可以说是一模一样。

这里咱们看一下接收线程，以及处理线程，但是具体的接收逻辑，处理逻辑在后面进行具体讲解。

接收线程:

> org.apache.tomcat.util.net.AbstractEndpoint#startAcceptorThreads

```java
// 开启接收线程
protected final void startAcceptorThreads() {
    // 默认的接收线程数 为1
    int count = getAcceptorThreadCount();
    acceptors = new Acceptor[count];
    // 创建并启动接收器
    for (int i = 0; i < count; i++) {
        acceptors[i] = createAcceptor();
        String threadName = getName() + "-Acceptor-" + i;
        acceptors[i].setThreadName(threadName);
        Thread t = new Thread(acceptors[i], threadName);
        t.setPriority(getAcceptorThreadPriority());
        //t.setDaemon(getDaemon());
        t.setDaemon(false);
        t.start();
    }
}
```

> org.apache.tomcat.util.net.NioEndpoint#createAcceptor

```java
@Override
protected AbstractEndpoint.Acceptor createAcceptor() {
    return new Acceptor();
}
```

接收到run方法：

> org.apache.tomcat.util.net.NioEndpoint.Acceptor#run

```java
@Override
public void run() {
    int errorDelay = 0;
    // Loop until we receive a shutdown command
    while (running) {
        // Loop if endpoint is paused
        while (paused && running) {
            state = AcceptorState.PAUSED;
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                // Ignore
            }
        }
        if (!running) {
            break;
        }
        state = AcceptorState.RUNNING;
        try {
            //if we have reached max connections, wait
            // 限制连接数
            countUpOrAwaitConnection();
            SocketChannel socket = null;
            try {
                // Accept the next incoming connection from the server
                // socket  接收连接
                socket = serverSock.accept();
            } catch (IOException ioe) {
                // We didn't get a socket
                countDownConnection();
                if (running) {
                    // Introduce delay if necessary
                    errorDelay = handleExceptionWithDelay(errorDelay);
                    // re-throw
                    throw ioe;
                } else {
                    break;
                }
            }
            // Successful accept, reset the error delay
            errorDelay = 0;
            // Configure the socket
            if (running && !paused) {
                // setSocketOptions() will hand the socket off to
                // an appropriate processor if successful
                // todo 对socket进行处理
                if (!setSocketOptions(socket)) {
                    closeSocket(socket);
                }
            } else {
                closeSocket(socket);
            }
        } catch (Throwable t) {
            ExceptionUtils.handleThrowable(t);
            log.error(sm.getString("endpoint.accept.fail"), t);
        }
    }
    state = AcceptorState.ENDED;
}
```

下面看一下处理线程poller:

> org.apache.tomcat.util.net.NioEndpoint.Poller#run

```java
@Override
public void run() {
    // Loop until destroy() is called
    while (true) {

        boolean hasEvents = false;

        try {
            if (!close) {
                hasEvents = events();
                // wakeupCounter大于0,表示有pollerEvent事件进入
                // 那么就selectNow,不会有超时等待; 也就是为了及时处理请求
                if (wakeupCounter.getAndSet(-1) > 0) {
                    //if we are here, means we have other stuff to do
                    //do a non blocking select
                    keyCount = selector.selectNow();
                } else {
                    // 如果到此,说明暂时没有注册的socket
                    keyCount = selector.select(selectorTimeout);
                }
                wakeupCounter.set(0);
            }
            if (close) {
                events();
                timeout(0, false);
                try {
                    selector.close();
                } catch (IOException ioe) {
                    log.error(sm.getString("endpoint.nio.selectorCloseFail"), ioe);
                }
                break;
            }
        } catch (Throwable x) {
            ExceptionUtils.handleThrowable(x);
            log.error("",x);
            continue;
        }
        //either we timed out or we woke up, process events first
        // 如果之前检测没有事件,那么此处在检测一次
        // 如果被唤醒,先进行一次事件的处理; 即为了timeout处理,也为了及时对事件响应
        if ( keyCount == 0 ) hasEvents = (hasEvents | events());
        // 获取所有可用的key的迭代器
        // 如果检测没有事件, 则不会对key进行遍历
        Iterator<SelectionKey> iterator =
            keyCount > 0 ? selector.selectedKeys().iterator() : null;
        // Walk through the collection of ready keys and dispatch
        // any active event.
        // todo  遍历所有的可用的事件, 并进行处理
        while (iterator != null && iterator.hasNext()) {
            SelectionKey sk = iterator.next();
            NioSocketWrapper attachment = (NioSocketWrapper)sk.attachment();
            // Attachment may be null if another thread has called
            // cancelledKey()
            if (attachment == null) {
                iterator.remove();
            } else {
                iterator.remove();
                // 对就绪的key对应的socket的channel进行处理
                processKey(sk, attachment);
            }
        }//while

        //process timeouts
        // timeout的处理
        timeout(keyCount,hasEvents);
    }//while
    getStopLatch().countDown();
}
```

这里对socket的读写事件进行处理，后面会开篇专门说，这里就不展开了。















































