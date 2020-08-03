[TOC]

# mapperListener

mapperListener此监听器的作用还是很重要的，其主要的工作是把service下engine中的host，context信息注册到service中的mapper中；所以当请求过来时，就可以在service中知道具体请求的是哪一个context以及servlet。

从其启动开始分析：

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

此中主要是获取  -> engine下的host并进行注册。

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
        log.debug(sm.getString("mapperListener.registerHost",host.getName(), domain, service));
    }
}
```

此中注册host的操作呢，第一步注册Host，第二部呢，注册host下的context。

看一下host的注册

> org.apache.catalina.mapper.Mapper#addHost

```java
// 记录 注册的host的信息
volatile MappedHost[] hosts = new MappedHost[0];
// 注册host信息到  mapper中
// 此mapper是 service的一个 属性
public synchronized void addHost(String name, String[] aliases,
                                 Host host) {
    name = renameWildcardHost(name);
    // 存储host的 数组
    MappedHost[] newHosts = new MappedHost[hosts.length + 1];
    // 封装要 注入的 host
    MappedHost newHost = new MappedHost(name, host);
    // 把 newHost 插入到 newHosts, 并把原来的hosts中的内容拷贝到 newHosts
    if (insertMap(hosts, newHosts, newHost)) {
        // 更新容器
        hosts = newHosts;
        if (newHost.name.equals(defaultHostName)) {
            defaultHost = newHost;
        }
        if (log.isDebugEnabled()) {
            log.debug(sm.getString("mapper.addHost.success", name));
        }
    } else {
        MappedHost duplicate = hosts[find(hosts, name)];
        if (duplicate.object == host) {
            // The host is already registered in the mapper.
            // E.g. it might have been added by addContextVersion()
            if (log.isDebugEnabled()) {
                log.debug(sm.getString("mapper.addHost.sameHost", name));
            }
            newHost = duplicate;
        } else {
            log.error(sm.getString("mapper.duplicateHost", name,
                                   duplicate.getRealHostName()));
            // Do not add aliases, as removeHost(hostName) won't be able to
            // remove them
            return;
        }
    }
    // 注册 host的别名
    List<MappedHost> newAliases = new ArrayList<>(aliases.length);
    for (String alias : aliases) {
        alias = renameWildcardHost(alias);
        MappedHost newAlias = new MappedHost(alias, newHost);
        if (addHostAliasImpl(newAlias)) {
            newAliases.add(newAlias);
        }
    }
    newHost.addAliases(newAliases);
}
```

可见主要操作是，使用MappedHost封装一下host信息，并把此封装后的信息保存在hosts数组中。

MapperHost 的构造

```java
public MappedHost(String name, Host host) {
    super(name, host);
    // 真正的host
    realHost = this;
    // 创建一个list,此主要记录此host 对应的context
    contextList = new ContextList();
    // 存储别名
    aliases = new CopyOnWriteArrayList<>();
}
```



看一下context的注册:

> org.apache.catalina.mapper.MapperListener#registerContext

```java
// 注册context到 service中的mapper field中
private void registerContext(Context context) {
    // 获取 contextPath
    String contextPath = context.getPath();
    if ("/".equals(contextPath)) {
        contextPath = "";
    }
    // 获取此context的host
    Host host = (Host)context.getParent();
    // 获取资源
    WebResourceRoot resources = context.getResources();
    // 查找 welcome的servlet
    String[] welcomeFiles = context.findWelcomeFiles();
    // 此主要存储 context下的 wrapper
    List<WrapperMappingInfo> wrappers = new ArrayList<>();
    /**
         * 注册context对应的servlet信息
         */
    for (Container container : context.findChildren()) {
        // 把 context下的wrapper存储到 wrappers中
        prepareWrapperMappingInfo(context, (Wrapper) container, wrappers);

        if(log.isDebugEnabled()) {
            log.debug(sm.getString("mapperListener.registerWrapper",
                                   container.getName(), contextPath, service));
        }
    }
    // 注册context到mapper中
    mapper.addContextVersion(host.getName(), host, contextPath,context.getWebappVersion(), context, welcomeFiles, resources,wrappers);

    if(log.isDebugEnabled()) {
        log.debug(sm.getString("mapperListener.registerContext",contextPath, service));
    }
}
```

此函数呢主要操作:

1. 获取context对应的host，以及welcome file
2. 把context中的wrapper存储到 一个list容器中
3. 注册context到mapper中

保存wrapper到 list容器中

> org.apache.catalina.mapper.MapperListener#prepareWrapperMappingInfo

```java
// 记录 context中的 servlet的映射信息
private void prepareWrapperMappingInfo(Context context, Wrapper wrapper,
                                       List<WrapperMappingInfo> wrappers) {
    // servlet的 名字
    String wrapperName = wrapper.getName();
    boolean resourceOnly = context.isResourceOnlyServlet(wrapperName);
    // 找到此wrapper对应哪些mapping
    String[] mappings = wrapper.findMappings();
    /**
         * 遍历其mapping, 把其信息添加到wrappers中
         */
    for (String mapping : mappings) {
        boolean jspWildCard = (wrapperName.equals("jsp")
                               && mapping.endsWith("/*"));
        // 进一步把wrapper的信息封装到 WrapperMappingInfo
        wrappers.add(new WrapperMappingInfo(mapping, wrapper, jspWildCard,
                                            resourceOnly));
    }
}
```

> org.apache.catalina.mapper.Mapper#addContextVersion

```java
// 记录此context 对应的 ContextVersion
// ContextVersion 中记录了 servlet的映射关系
private final Map<Context, ContextVersion> contextObjectToContextVersionMap =
    new ConcurrentHashMap<>();

// 注册context到 mapper中
public void addContextVersion(String hostName, Host host, String path,
                              String version, Context context, String[] welcomeResources,
                              WebResourceRoot resources, Collection<WrapperMappingInfo> wrappers) {

    hostName = renameWildcardHost(hostName);
    // 精确查找host
    MappedHost mappedHost  = exactFind(hosts, hostName);
    // 没有找到,则记录起来
    if (mappedHost == null) {
        addHost(hostName, new String[0], host);
        mappedHost = exactFind(hosts, hostName);
        if (mappedHost == null) {
            log.error("No host found: " + hostName);
            return;
        }
    }
    if (mappedHost.isAlias()) {
        log.error("No host found: " + hostName);
        return;
    }
    // 获取 path中/ 的个数
    int slashCount = slashCount(path);
    synchronized (mappedHost) {
        ContextVersion newContextVersion = new ContextVersion(version,path, slashCount, context, resources, welcomeResources);
        if (wrappers != null) {
            // todo 添加mapper到此对应的context
            addWrappers(newContextVersion, wrappers);
        }
        // 获取此 host下面的  context
        ContextList contextList = mappedHost.contextList;
        // 精确查找 context
        MappedContext mappedContext = exactFind(contextList.contexts, path);
        // 没有找到 context
        // 则把此context添加到host中
        if (mappedContext == null) {
            //todo 封装context信息, 然后添加到mappedHost.contextList
            mappedContext = new MappedContext(path, newContextVersion);
            ContextList newContextList = contextList.addContext(
                mappedContext, slashCount);
            if (newContextList != null) {
                updateContextList(mappedHost, newContextList);
                //  保存context及其对应的wrapper信息
                contextObjectToContextVersionMap.put(context, newContextVersion);
            }
        } else {
            ContextVersion[] contextVersions = mappedContext.versions;
            ContextVersion[] newContextVersions = new ContextVersion[contextVersions.length + 1];
            if (insertMap(contextVersions, newContextVersions,
                          newContextVersion)) {
                mappedContext.versions = newContextVersions;
                contextObjectToContextVersionMap.put(context, newContextVersion);
            } else {
                // Re-registration after Context.reload()
                // Replace ContextVersion with the new one
                int pos = find(contextVersions, version);
                if (pos >= 0 && contextVersions[pos].name.equals(version)) {
                    contextVersions[pos] = newContextVersion;
                    contextObjectToContextVersionMap.put(context, newContextVersion);
                }
            }
        }
    }
}
```

操作步骤：

1. 创建一个ContextVersion
2. 添加wrapper到此ContextVersion中
3. 把context的path以及ContextVersion 封装一个MappedContext
4. 最后把MappedContext 记录到contextObjectToContextVersionMap

添加wrapper到contextVersion中：

> org.apache.catalina.mapper.Mapper#addWrappers(org.apache.catalina.mapper.Mapper.ContextVersion, java.util.Collection<org.apache.catalina.mapper.WrapperMappingInfo>)

```java
// 添加  wrapper到context中
private void addWrappers(ContextVersion contextVersion,
                         Collection<WrapperMappingInfo> wrappers) {
    // 遍历wrapper 注册到从context
    for (WrapperMappingInfo wrapper : wrappers) {
            // 注册 servlet的映射到  context中
            // wrapper.getMapping()  获取wrapper的映射路径
            // wrapper.getWrapper()  具体的servlet
            // wrapper.isJspWildCard()  是否是jsp的正则
            // wrapper.isResourceOnly()  是否只是 资源
        addWrapper(contextVersion, wrapper.getMapping(),
                   wrapper.getWrapper(), wrapper.isJspWildCard(),
                   wrapper.isResourceOnly());
    }
}
```

> org.apache.catalina.mapper.Mapper#addWrapper(org.apache.catalina.mapper.Mapper.ContextVersion, java.lang.String, org.apache.catalina.Wrapper, boolean, boolean)

```java
protected void addWrapper(ContextVersion context, String path,
                          Wrapper wrapper, boolean jspWildCard, boolean resourceOnly) {

    synchronized (context) {
        // 如果匹配路径是以  /*  结束,则 表示是 正则匹配,添加到 wildcardWrappers
        if (path.endsWith("/*")) {
            // Wildcard wrapper
            String name = path.substring(0, path.length() - 2);
            MappedWrapper newWrapper = new MappedWrapper(name, wrapper,
                                                         jspWildCard, resourceOnly);
            MappedWrapper[] oldWrappers = context.wildcardWrappers;
            MappedWrapper[] newWrappers = new MappedWrapper[oldWrappers.length + 1];
            if (insertMap(oldWrappers, newWrappers, newWrapper)) {
                context.wildcardWrappers = newWrappers;
                int slashCount = slashCount(newWrapper.name);
                if (slashCount > context.nesting) {
                    context.nesting = slashCount;
                }
            }
            // 如果是以 *. 开始,那么是扩展匹配, 记录到  extensionWrappers
        } else if (path.startsWith("*.")) {
            // Extension wrapper
            String name = path.substring(2);
            MappedWrapper newWrapper = new MappedWrapper(name, wrapper,
                                                         jspWildCard, resourceOnly);
            MappedWrapper[] oldWrappers = context.extensionWrappers;
            MappedWrapper[] newWrappers =
                new MappedWrapper[oldWrappers.length + 1];
            if (insertMap(oldWrappers, newWrappers, newWrapper)) {
                context.extensionWrappers = newWrappers;
            }
            // 如果path和 / 相等, 那么设置为默认的 wrapper
        } else if (path.equals("/")) {
            // Default wrapper
            MappedWrapper newWrapper = new MappedWrapper("", wrapper,
                                                         jspWildCard, resourceOnly);
            context.defaultWrapper = newWrapper;
        } else {
            // Exact wrapper
            // 否则就属于 完全匹配
            // 完全匹配的话 则把此wrapper添加到 exactWrappers中
            final String name;
            if (path.length() == 0) {
                // Special case for the Context Root mapping which is
                // treated as an exact match
                name = "/";
            } else {
                name = path;
            }
            MappedWrapper newWrapper = new MappedWrapper(name, wrapper,
                                                         jspWildCard, resourceOnly);
            MappedWrapper[] oldWrappers = context.exactWrappers;
            MappedWrapper[] newWrappers = new MappedWrapper[oldWrappers.length + 1];
            if (insertMap(oldWrappers, newWrappers, newWrapper)) {
                context.exactWrappers = newWrappers;
            }
        }
    }
}
```

到此，server子容器engine中的host以及context以及servlet就注册到了 mapper中。



















































































































