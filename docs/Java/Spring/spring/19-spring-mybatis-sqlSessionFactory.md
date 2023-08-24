[TOC]

# SqlSessionFactory

根据spring和mybatis整合的配置，可以看到有一个特殊的注解：@MapperScan，还有一个javaBean的配置：

```java
private String MapperLocation = "classpath:/mapper/*.xml";
// 数据源
@Bean
public DataSource dataSource(){
    DriverManagerDataSource dataSource = new DriverManagerDataSource();
    dataSource.setDriverClassName("com.mysql.jdbc.Driver");
    dataSource.setUrl("jdbc:mysql://localhost:3306/ssm?useSSL=false&allowMultiQueries=true");
    dataSource.setUsername("root");
    dataSource.setPassword("admin");
    return dataSource;
}
// sqlsessionfactory
@Bean("sqlSessionFactory")
public SqlSessionFactory sqlSessionFactory() throws Exception {
    PathMatchingResourcePatternResolver patternResolver = new PathMatchingResourcePatternResolver();
    SqlSessionFactoryBean sessionFactoryBean = new SqlSessionFactoryBean();
    sessionFactoryBean.setDataSource(dataSource());
    sessionFactoryBean.setMapperLocations(patternResolver.getResources(MapperLocation));
    return sessionFactoryBean.getObject();
}
// 事务管理器
@Bean
public PlatformTransactionManager transactionManager(){
    DataSourceTransactionManager transactionManager = new DataSourceTransactionManager();
    transactionManager.setDataSource(dataSource());
    return transactionManager;
}
```

事务管理器和数据源是和事务相关的操作，那和mybatis相关的就是SqlSessionFactory这个配置了。下面咱们就可以从这个bean配置和注解MapperScan来入手分析一下。

本篇主要来分析这个SqlSessionFactory。老规矩先看一下这个类图：

![](SqlSessionFactoryBean.png)

可以看到其是几个特殊接口的子类: InitializingBean，FactoryBean；也就是说首先此类是一个工厂类，而且在bean进行完自动注入后，会执行此 InitializingBean的回调。

直接看此InitializingBean接口的实现：

> org.mybatis.spring.SqlSessionFactoryBean#afterPropertiesSet

```java
@Override
public void afterPropertiesSet() throws Exception {
    notNull(dataSource, "Property 'dataSource' is required");
    notNull(sqlSessionFactoryBuilder, "Property 'sqlSessionFactoryBuilder' is required");
    state((configuration == null && configLocation == null) || !(configuration != null && configLocation != null), "Property 'configuration' and 'configLocation' can not specified with together");
    /**
	   * 进行初始化时,就创建SqlSessionFactory
	   */
    this.sqlSessionFactory = buildSqlSessionFactory();
}
```

> org.mybatis.spring.SqlSessionFactoryBean#buildSqlSessionFactory

```java
/**
	 * buildSqlSessionFactory 创建SqlSessionFactory
	 */
protected SqlSessionFactory buildSqlSessionFactory() throws Exception {
    final Configuration targetConfiguration;
    XMLConfigBuilder xmlConfigBuilder = null;
    // 如果已经存在了configuration, 当然此时第一次进入,肯定是为null的
    if (this.configuration != null) {
        targetConfiguration = this.configuration;
        if (targetConfiguration.getVariables() == null) {
            targetConfiguration.setVariables(this.configurationProperties);
        } else if (this.configurationProperties != null) {
            targetConfiguration.getVariables().putAll(this.configurationProperties);
        }
        // 如果指定了mybatis-config.xml配置文件的位置
        // 就创建一个xmlConfigBuilder类用来对config文件的解析
        // 和spring整合时一般不需要制定 mybatis的配置
    } else if (this.configLocation != null) {
        xmlConfigBuilder = new XMLConfigBuilder(this.configLocation.getInputStream(), null, this.configurationProperties);
        targetConfiguration = xmlConfigBuilder.getConfiguration();
    } else {
        LOGGER.debug(
            () -> "Property 'configuration' or 'configLocation' not specified, using default MyBatis Configuration");
        // 如果不存在configuration也没有指定配置文件位置,那么就创建一个
        // 此处创建了一个 Configuration
        // 看过mybatis源码的童鞋,对于此类我就不多说了
        targetConfiguration = new Configuration();
      Optional.ofNullable(this.configurationProperties).ifPresent(targetConfiguration::setVariables);
    }
    // 下面的Optional都是对configuration类中的属性进行设置
    Optional.ofNullable(this.objectFactory).ifPresent(targetConfiguration::setObjectFactory);
 Optional.ofNullable(this.objectWrapperFactory).ifPresent(targetConfiguration::setObjectWrapperFactory);
    Optional.ofNullable(this.vfs).ifPresent(targetConfiguration::setVfsImpl);
    if (hasLength(this.typeAliasesPackage)) {
        scanClasses(this.typeAliasesPackage, this.typeAliasesSuperType).stream()
            .filter(clazz -> !clazz.isAnonymousClass()).filter(clazz -> !clazz.isInterface())
            .filter(clazz -> !clazz.isMemberClass()).forEach(targetConfiguration.getTypeAliasRegistry()::registerAlias);
    }
    if (!isEmpty(this.typeAliases)) {
        Stream.of(this.typeAliases).forEach(typeAlias -> {
            targetConfiguration.getTypeAliasRegistry().registerAlias(typeAlias);
            LOGGER.debug(() -> "Registered type alias: '" + typeAlias + "'");
        });
    }
    if (!isEmpty(this.plugins)) {
        Stream.of(this.plugins).forEach(plugin -> {
            targetConfiguration.addInterceptor(plugin);
            LOGGER.debug(() -> "Registered plugin: '" + plugin + "'");
        });
    }
    if (hasLength(this.typeHandlersPackage)) {
        scanClasses(this.typeHandlersPackage, TypeHandler.class).stream().filter(clazz -> !clazz.isAnonymousClass())
            .filter(clazz -> !clazz.isInterface()).filter(clazz -> !Modifier.isAbstract(clazz.getModifiers()))
            .forEach(targetConfiguration.getTypeHandlerRegistry()::register);
    }

    if (!isEmpty(this.typeHandlers)) {
        Stream.of(this.typeHandlers).forEach(typeHandler -> {
            targetConfiguration.getTypeHandlerRegistry().register(typeHandler);
            LOGGER.debug(() -> "Registered type handler: '" + typeHandler + "'");
        });
    }
    targetConfiguration.setDefaultEnumTypeHandler(defaultEnumTypeHandler);

    if (!isEmpty(this.scriptingLanguageDrivers)) {
        Stream.of(this.scriptingLanguageDrivers).forEach(languageDriver -> {
            targetConfiguration.getLanguageRegistry().register(languageDriver);
            LOGGER.debug(() -> "Registered scripting language driver: '" + languageDriver + "'");
        });
    }
    Optional.ofNullable(this.defaultScriptingLanguageDriver)
        .ifPresent(targetConfiguration::setDefaultScriptingLanguage);

    if (this.databaseIdProvider != null) {// fix #64 set databaseId before parse mapper xmls
        try {
           targetConfiguration.setDatabaseId(this.databaseIdProvider.getDatabaseId(this.dataSource));
        } catch (SQLException e) {
            throw new NestedIOException("Failed getting a databaseId", e);
        }
    }
    Optional.ofNullable(this.cache).ifPresent(targetConfiguration::addCache);
    // 如果指定了mybatis-config.xml配置文件的话,那么在此处会进行分析
    if (xmlConfigBuilder != null) {
        try {
            // 如果指定了mybatis的配置文件,那么就会在此进行解析
            // 当然一般在spring整合时,并不会使用到  mybatis的配置文件
            xmlConfigBuilder.parse();
            LOGGER.debug(() -> "Parsed configuration file: '" + this.configLocation + "'");
        } catch (Exception ex) {
         throw new NestedIOException("Failed to parse config resource: " + this.configLocation, ex);
        } finally {
            ErrorContext.instance().reset();
        }
    }
    // 创建数据库环境, 此处使用的应该是SpringManagedTransactionFactory
    targetConfiguration.setEnvironment(new Environment(this.environment, this.transactionFactory == null ? new SpringManagedTransactionFactory() : this.transactionFactory, this.dataSource));
    // 如果指定了mapper.xml配置,在此处就要进行解析了
    if (this.mapperLocations != null) {
        if (this.mapperLocations.length == 0) {
            LOGGER.warn(() -> "Property 'mapperLocations' was specified but matching resources are not found.");
        } else {
            for (Resource mapperLocation : this.mapperLocations) {
                if (mapperLocation == null) {
                    continue;
                }
                try {
                    // 创建XMLMapperBuilder对象,来对mapper文件进行解析
                    XMLMapperBuilder xmlMapperBuilder = new XMLMapperBuilder(mapperLocation.getInputStream(), targetConfiguration, mapperLocation.toString(), targetConfiguration.getSqlFragments());
                    // todo 重要 具体mapper.xml解析的动作
                    xmlMapperBuilder.parse();
                } catch (Exception e) {
                    throw new NestedIOException("Failed to parse mapping resource: '" + mapperLocation + "'", e);
                } finally {
                    ErrorContext.instance().reset();
                }
                LOGGER.debug(() -> "Parsed mapper file: '" + mapperLocation + "'");
            }
        }
    } else {
        LOGGER.debug(() -> "Property 'mapperLocations' was not specified.");
    }
    return this.sqlSessionFactoryBuilder.build(targetConfiguration);
}
```

此类也是一个重头类，主要做了几件事：

1. 如果指定了 mybatis配置文件，那么就解析mybatis配置文件
2. 如果没有指定，则创建一个空的 Configuration类
3. 解析mapper.xml 文件
4. 创建DefaultSqlSessionFactory

看一下对mapper.xml文件的解析:

> org.apache.ibatis.builder.xml.XMLMapperBuilder#parse

```java
// 解析mapper.xml文件
public void parse() {
    // 查看此mapper文件是否已经解析,如果没有解析的话,那么就进行解析
    if (!configuration.isResourceLoaded(resource)) {
        // 具体解析mapper文件
        configurationElement(parser.evalNode("/mapper"));
        // 解析完后,把此mapper添加到已解析的容器中,以防多次解析
        configuration.addLoadedResource(resource);
        //1. 记录加载的namespace
        //2. 记录创建此mapper及其代理的工厂类
        bindMapperForNamespace();
    }

    parsePendingResultMaps();
    parsePendingCacheRefs();
    parsePendingStatements();
}
```

> org.apache.ibatis.builder.xml.XMLMapperBuilder#configurationElement

```java
// 解析 mapper.xml 文件
private void configurationElement(XNode context) {
    try {
        // 获取namespace节点内容,此内容就是对应接口类的全限定类名
        String namespace = context.getStringAttribute("namespace");
        if (namespace == null || namespace.isEmpty()) {
            throw new BuilderException("Mapper's namespace cannot be empty");
        }
        // 记录全限定类名
        builderAssistant.setCurrentNamespace(namespace);
        // 解析cache-ref
        cacheRefElement(context.evalNode("cache-ref"));
        // 解析cache
        cacheElement(context.evalNode("cache"));
        parameterMapElement(context.evalNodes("/mapper/parameterMap"));
        // 解析resultMap节点
        resultMapElements(context.evalNodes("/mapper/resultMap"));
        // 解析sql语句
        sqlElement(context.evalNodes("/mapper/sql"));
        // 创建sql statement语句
        buildStatementFromContext(context.evalNodes("select|insert|update|delete"));
    } catch (Exception e) {
        throw new BuilderException("Error parsing Mapper XML. The XML location is '" + resource + "'. Cause: " + e, e);
    }
}
```

> org.apache.ibatis.builder.xml.XMLMapperBuilder#bindMapperForNamespace

```java
// 绑定mapper到 configuration中
private void bindMapperForNamespace() {
    String namespace = builderAssistant.getCurrentNamespace();
    if (namespace != null) {
        Class<?> boundType = null;
        try {
            // 加载namespace对应的class
            boundType = Resources.classForName(namespace);
        } catch (ClassNotFoundException e) {
            // ignore, bound type is not required
        }
        if (boundType != null && !configuration.hasMapper(boundType)) {
            // Spring may not know the real resource name so we set a flag
            // to prevent loading again this resource from the mapper interface
            // look at MapperAnnotationBuilder#loadXmlResource
            // 记录加载的namespace
            configuration.addLoadedResource("namespace:" + namespace);
            // mapperRegistry在其中记录此class，及其对应的MapperProxyFactory
            // knownMappers.put(type, new MapperProxyFactory<>(type)) 在mapper
            // 简单说就是 记录创建此mapper对应实例的代理类工厂
            configuration.addMapper(boundType);
        }
    }
}
```

最后创建一个factory：

> org.apache.ibatis.session.SqlSessionFactoryBuilder#build(org.apache.ibatis.session.Configuration)

```java
// 创建SqlSesionFactory
public SqlSessionFactory build(Configuration config) {
    // 由此可见创建的是DefaultSqlSessionFactory
    return new DefaultSqlSessionFactory(config);
}
```

















































































