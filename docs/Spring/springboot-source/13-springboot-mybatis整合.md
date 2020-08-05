[TOC]

# springboot 和 mybatis的整合

本篇咱们来看一下springboot和mybatis是如何进行整合的，

springboot和mybatis使用时的一些配置:

```java
@Configuration
@MapperScan("com.wk.mapper")
public class MyBatisConfig {
    // 配置多个数据源时，让其扫描的mapper是不一样的
    private static final String MAPPER_LOCATION="classpath:mapper/*.xml";
    @Value("${spring.datasource.url}")
    private String url;
    @Value("${spring.datasource.driver-class-name}")
    private String className;
    @Value("${spring.datasource.username}")
    private String userName;
    @Value("${spring.datasource.password}")
    private String password;

    @Bean("druidDataSource")
    public DataSource masterDataSource() {
        DruidDataSource dataSource = new DruidDataSource();
        dataSource.setUrl(url);
        dataSource.setUsername(userName);
        dataSource.setPassword(password);
        dataSource.setDriverClassName(className);
        return dataSource;
    }
    @Bean
    public DataSourceTransactionManager transactionManager() {
        return new DataSourceTransactionManager(masterDataSource());
    }

    @Bean
    public SqlSessionFactory sqlSessionFactory(@Qualifier("druidDataSource") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean sqlSessionFactory = new SqlSessionFactoryBean();
        sqlSessionFactory.setDataSource(dataSource);
        sqlSessionFactory.setMapperLocations(new PathMatchingResourcePatternResolver()
                                             .getResources(MyBatisConfig.MAPPER_LOCATION));
        return sqlSessionFactory.getObject();
    }
}
```

可见springboot和mybatis整合特别简单，主要工作是在MapperScan注解，其注入了后置处理器，来做一些偷梁换柱的操作。

在mybatis-spring-boot-starter中也有一个spring.factories文件，其中有一个自动配置类：

```properties
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration
```

看一下此mybatis自动配置类:

```java
@org.springframework.context.annotation.Configuration
@ConditionalOnClass({ SqlSessionFactory.class, SqlSessionFactoryBean.class })
@ConditionalOnBean(DataSource.class)
// 导入了 MybatisProperties 配置
@EnableConfigurationProperties(MybatisProperties.class)
// 此配置主要在 数据源自动配置后 进行
@AutoConfigureAfter(DataSourceAutoConfiguration.class)
public class MybatisAutoConfiguration {

  private static final Logger logger = LoggerFactory.getLogger(MybatisAutoConfiguration.class);
  private final MybatisProperties properties;
  private final Interceptor[] interceptors;
  private final ResourceLoader resourceLoader;
  private final DatabaseIdProvider databaseIdProvider;
  private final List<ConfigurationCustomizer> configurationCustomizers;
    
  public MybatisAutoConfiguration(MybatisProperties properties,
                                  ObjectProvider<Interceptor[]> interceptorsProvider,
                                  ResourceLoader resourceLoader,
                                  ObjectProvider<DatabaseIdProvider> databaseIdProvider,
                                  ObjectProvider<List<ConfigurationCustomizer>> configurationCustomizersProvider) {
    this.properties = properties;
    this.interceptors = interceptorsProvider.getIfAvailable();
    this.resourceLoader = resourceLoader;
    this.databaseIdProvider = databaseIdProvider.getIfAvailable();
    this.configurationCustomizers = configurationCustomizersProvider.getIfAvailable();
  }
	// 初始化函数
  @PostConstruct
  public void checkConfigFileExists() {
    if (this.properties.isCheckConfigLocation() && StringUtils.hasText(this.properties.getConfigLocation())) {
      Resource resource = this.resourceLoader.getResource(this.properties.getConfigLocation());
      Assert.state(resource.exists(), "Cannot find config location: " + resource
          + " (please add config file or check your Mybatis configuration)");
    }
  }
// 如果没有创建 SqlSessionFactory呢,在这里就创建了一个
  @Bean
  @ConditionalOnMissingBean
  public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
    SqlSessionFactoryBean factory = new SqlSessionFactoryBean();
    factory.setDataSource(dataSource);
    factory.setVfs(SpringBootVFS.class);
      // mybatis 配置文件的路径
    if (StringUtils.hasText(this.properties.getConfigLocation())) {
     factory.setConfigLocation(this.resourceLoader.getResource(this.properties.getConfigLocation()));
    }
    Configuration configuration = this.properties.getConfiguration();
    if (configuration == null && !StringUtils.hasText(this.properties.getConfigLocation())) {
      configuration = new Configuration();
    }
      // 使用 configurationCustomizers 对configuration 进行定制化操作
    if (configuration != null && !CollectionUtils.isEmpty(this.configurationCustomizers)) {
      for (ConfigurationCustomizer customizer : this.configurationCustomizers) {
        customizer.customize(configuration);
      }
    }
    factory.setConfiguration(configuration);
    if (this.properties.getConfigurationProperties() != null) {
      factory.setConfigurationProperties(this.properties.getConfigurationProperties());
    }
    if (!ObjectUtils.isEmpty(this.interceptors)) {
      factory.setPlugins(this.interceptors);
    }
      // dataSource
    if (this.databaseIdProvider != null) {
      factory.setDatabaseIdProvider(this.databaseIdProvider);
    }
      // package 别名记录
    if (StringUtils.hasLength(this.properties.getTypeAliasesPackage())) {
      factory.setTypeAliasesPackage(this.properties.getTypeAliasesPackage());
    }
      // 如果指定了 typeHandler 也进行记录
    if (StringUtils.hasLength(this.properties.getTypeHandlersPackage())) {
      factory.setTypeHandlersPackage(this.properties.getTypeHandlersPackage());
    }
      // mapper.xml 文件的位置解析
    if (!ObjectUtils.isEmpty(this.properties.resolveMapperLocations())) {
      factory.setMapperLocations(this.properties.resolveMapperLocations());
    }
	// 创建 SqlSessionFactory
    return factory.getObject();
  }
	// 如果没有创建SqlSessionTemplate, 此会就会创建一个SqlSessionTemplate
  @Bean
  @ConditionalOnMissingBean
  public SqlSessionTemplate sqlSessionTemplate(SqlSessionFactory sqlSessionFactory) {
    ExecutorType executorType = this.properties.getExecutorType();
    if (executorType != null) {
      return new SqlSessionTemplate(sqlSessionFactory, executorType);
    } else {
      return new SqlSessionTemplate(sqlSessionFactory);
    }
  }
```

当前其内部还有一个配置类，看一下：

```java
@org.springframework.context.annotation.Configuration
    // 此配置呢,向容器中注入一个类 AutoConfiguredMapperScannerRegistrar
    @Import({ AutoConfiguredMapperScannerRegistrar.class })
    // 容器中没有 MapperFactoryBean 类,则添加此配置类
    // 这说明什么呢? 没有MapperFactoryBean类, 说明没有使用 mapperScan注解
    @ConditionalOnMissingBean(MapperFactoryBean.class)
    public static class MapperScannerRegistrarNotFoundConfiguration {
		// 初始化 函数
        @PostConstruct
        public void afterPropertiesSet() {
            logger.debug("No {} found.", MapperFactoryBean.class.getName());
        }
    }
```

看一下此类AutoConfiguredMapperScannerRegistrar:

```java
public static class AutoConfiguredMapperScannerRegistrar
    implements BeanFactoryAware, ImportBeanDefinitionRegistrar, ResourceLoaderAware {

    private BeanFactory beanFactory;

    private ResourceLoader resourceLoader;
	// 自动注入类到容器中
    // 简单说,此向容器注入的类主要是对  @Mapper 注解的处理
    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
		// 定义具体的 扫描类
        ClassPathMapperScanner scanner = new ClassPathMapperScanner(registry);

        try {
            if (this.resourceLoader != null) {
                scanner.setResourceLoader(this.resourceLoader);
            }
			// 获取自动配置类的路径
            // 此获取 SpringBootApplication 注解 配置的扫描路径
            List<String> packages = AutoConfigurationPackages.get(this.beanFactory);
            if (logger.isDebugEnabled()) {
                for (String pkg : packages) {
                    logger.debug("Using auto-configuration base package '{}'", pkg);
                }
            }
			 // 设置注解的类 为 Mapper
            scanner.setAnnotationClass(Mapper.class);
            // 注册过滤器
            scanner.registerFilters();
            // 开始进行扫描
            // 1. 此处就开始 扫描 Mapper 注解的beanDefinition
            // 2. 更改其beanDefinition中的class为 MapperFactoryBean
            // 3. 把此更改后的beanDefinition注册到容器中
            scanner.doScan(StringUtils.toStringArray(packages));
        } catch (IllegalStateException ex) {
            logger.debug("Could not determine auto-configuration package, automatic mapper scanning disabled.", ex);
        }
    }
	// BeanFactoryAware 回调方法
    @Override
    public void setBeanFactory(BeanFactory beanFactory) throws BeansException {
        this.beanFactory = beanFactory;
    }
	// ResourceLoaderAware 回调
    @Override
    public void setResourceLoader(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }
}
```

可以看到，看过前面后，此处springboot和mybatis的整合，也是比较简答。此自动配置主要有一下动作：

1. 容器中没有SqlSessionFactory，则创建一个
2. 容器中没有SqlSessionTemplate，则创建一个
3. 如果容器中没有MapperFactoryBean，也就是没有使用MapperScan注解，那么就向容器中注入：AutoConfiguredMapperScannerRegistrar。
4.  AutoConfiguredMapperScannerRegistrar 主要是处理 Mapper注解的bean，扫描路径同 SpringbootApplication注解的路径，更改bean的beanDefinition的class为MapperFactoryBean，之后再把更改后的beanDefinition，注入到容器中。

































































