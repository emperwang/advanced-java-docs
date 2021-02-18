# hostConfig何时初始化

hostConfig解析 webapps中部署的程序，创建对应的standardContext，并进行启动，不可谓不重要，那么这个类又是何时创建的呢？

## 1. 创建

tomcat启动的时候，会使用digester解析server.xml，就是在解析的过程中创建的HostConfig并保存到StandardHost中。

### 1.1 digester的创建

> org.apache.catalina.startup.Catalina#createStartDigester

```java
 protected Digester createStartDigester() {
        long t1=System.currentTimeMillis();
        // Initialize the digester
        Digester digester = new Digester();
        digester.setValidating(false);
        digester.setRulesValidation(true);
        Map<Class<?>, List<String>> fakeAttributes = new HashMap<>();
        List<String> objectAttrs = new ArrayList<>();
        objectAttrs.add("className");
        fakeAttributes.put(Object.class, objectAttrs);
        // Ignore attribute added by Eclipse for its internal tracking
        List<String> contextAttrs = new ArrayList<>();
        contextAttrs.add("source");
        fakeAttributes.put(StandardContext.class, contextAttrs);
        digester.setFakeAttributes(fakeAttributes);
        digester.setUseContextClassLoader(true);

        // Configure the actions we will be using
        digester.addObjectCreate("Server",
                                 "org.apache.catalina.core.StandardServer",
                                 "className");
        digester.addSetProperties("Server");
        digester.addSetNext("Server",
                            "setServer",
                            "org.apache.catalina.Server");
		..........
        // Add RuleSets for nested elements
        digester.addRuleSet(new NamingRuleSet("Server/GlobalNamingResources/"));
        digester.addRuleSet(new EngineRuleSet("Server/Service/"));
        digester.addRuleSet(new HostRuleSet("Server/Service/Engine/"));
        digester.addRuleSet(new ContextRuleSet("Server/Service/Engine/Host/"));
        addClusterRuleSet(digester, "Server/Service/Engine/Host/Cluster/");
        digester.addRuleSet(new NamingRuleSet("Server/Service/Engine/Host/Context/"));

        // When the 'engine' is found, set the parentClassLoader.
        digester.addRule("Server/Service/Engine",
                         new SetParentClassLoaderRule(parentClassLoader));
        addClusterRuleSet(digester, "Server/Service/Engine/Cluster/");

        long t2=System.currentTimeMillis();
        if (log.isDebugEnabled()) {
            log.debug("Digester for server.xml created " + ( t2-t1 ));
        }
        return digester;
    }
```

> org.apache.catalina.startup.HostRuleSet#addRuleInstances

```java
@Override
public void addRuleInstances(Digester digester) {

    digester.addObjectCreate(prefix + "Host",
                             "org.apache.catalina.core.StandardHost",
                             "className");
    digester.addSetProperties(prefix + "Host");
    digester.addRule(prefix + "Host",
                     new CopyParentClassLoaderRule());
    // 在这里添加了 解析web.xml文件时, 会自动添加 HostConfig
    digester.addRule(prefix + "Host",
                     new LifecycleListenerRule
                     ("org.apache.catalina.startup.HostConfig",
                      "hostConfigClass"));
    digester.addSetNext(prefix + "Host",
                        "addChild",
                        "org.apache.catalina.Container");

    digester.addCallMethod(prefix + "Host/Alias",
                           "addAlias", 0);

	 ............ // 省略非关键代码
    digester.addSetProperties(prefix + "Host/Valve");
    digester.addSetNext(prefix + "Host/Valve",
                        "addValve",
                        "org.apache.catalina.Valve");

}
```

> org.apache.catalina.startup.LifecycleListenerRule#LifecycleListenerRule

```java
    public LifecycleListenerRule(String listenerClass, String attributeName) {
        // 举例说明:
        // listenerClass = org.apache.catalina.startup.HostConfig
        this.listenerClass = listenerClass;
        //attributeName = hostConfigClass
        this.attributeName = attributeName;

    }
```

> org.apache.catalina.startup.LifecycleListenerRule#begin

```java
// 对lifecycle的监听器的一下处理
// 如: 会把 HostConfig添加到 StandardHost中
@Override
public void begin(String namespace, String name, Attributes attributes)
    throws Exception {

    Container c = (Container) digester.peek();
    Container p = null;
    Object obj = digester.peek(1);
    if (obj instanceof Container) {
        p = (Container) obj;
    }

    String className = null;

    // Check the container for the specified attribute
    if (attributeName != null) {
        String value = attributes.getValue(attributeName);
        if (value != null)
            className = value;
    }

    // Check the container's parent for the specified attribute
    if (p != null && className == null) {
        String configClass =
            (String) IntrospectionUtils.getProperty(p, attributeName);
        if (configClass != null && configClass.length() > 0) {
            className = configClass;
        }
    }

    // Use the default
    if (className == null) {
        className = listenerClass;
    }

    // Instantiate a new LifecycleListener implementation object
    // 加载 listener
    Class<?> clazz = Class.forName(className);
    // 实例化 listener
    LifecycleListener listener = (LifecycleListener) clazz.getConstructor().newInstance();

    // Add this LifecycleListener to our associated component
    // 把lifecycleListener 添加到 container中
    // 如: 把HostConfig添加到 standardHost中
    c.addLifecycleListener(listener);
}
```

如果有配置lifecycleListener那么就使用配置的，如果没有配置，那么就是用org.apache.catalina.startup.HostConfig这个默认的。

> org.apache.catalina.util.LifecycleBase#addLifecycleListener

```java
// 存储对应的事件监听器
private final List<LifecycleListener> lifecycleListeners = new CopyOnWriteArrayList<>();

public void addLifecycleListener(LifecycleListener listener) {
    lifecycleListeners.add(listener);
}
```

此处就是把HostConfig注册到 StandardHost中。tomcat中容器都是LifecycleBase的子类。

## 2. 事件监听

> org.apache.catalina.startup.HostConfig#lifecycleEvent

```java
public void lifecycleEvent(LifecycleEvent event) {

    // Identify the host we are associated with
    try {
        host = (Host) event.getLifecycle();
        if (host instanceof StandardHost) {
            setCopyXML(((StandardHost) host).isCopyXML());
            setDeployXML(((StandardHost) host).isDeployXML());
            setUnpackWARs(((StandardHost) host).isUnpackWARs());
            setContextClass(((StandardHost) host).getContextClass());
        }
    } catch (ClassCastException e) {
        log.error(sm.getString("hostConfig.cce", event.getLifecycle()), e);
        return;
    }

    // Process the event that has occurred
    if (event.getType().equals(Lifecycle.PERIODIC_EVENT)) {
        check();
    } else if (event.getType().equals(Lifecycle.BEFORE_START_EVENT)) {
        beforeStart();
    } else if (event.getType().equals(Lifecycle.START_EVENT)) {
        start();
    } else if (event.getType().equals(Lifecycle.STOP_EVENT)) {
        stop();
    }
}
```

针对不同的生命周期事件，进行处理，其中就包括了解析webapps中的程序，并启动。

这里的HostConfig的事件，类似于standContext和contextConfig的事件传递。StandardHost会启动后台线程进行处理，并发送Lifecycle.PERIODIC_EVENT事件，在这个事件中进行 webapps程序的解析启动。  

tomcat的热加载大体原理也是后台线程触发PERIODIC_EVENT，然后在这里进行处理，如果standContext中内容有更改，那么会stop此context然后重新启动此context，来达到对应的热加载，具体会放在后面的篇章中再次解析。



