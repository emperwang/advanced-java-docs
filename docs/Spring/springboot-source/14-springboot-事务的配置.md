[TOC]

# springboot 事务的配置

事务的配置跟AOP的配置很相似，看一下其自动配置类：

```java
// 事务的自动化配置; 主要是EnableTransactionManagement注解
@Configuration
@ConditionalOnClass(PlatformTransactionManager.class)
// 初始化的顺序指定一下
@AutoConfigureAfter({ JtaAutoConfiguration.class, HibernateJpaAutoConfiguration.class,
		DataSourceTransactionManagerAutoConfiguration.class, Neo4jDataAutoConfiguration.class })
// 配置文件
@EnableConfigurationProperties(TransactionProperties.class)
public class TransactionAutoConfiguration {
 	...... 省略。。   
}
```

此是事务的自动配置类，其内部还有一个配置类，如下：

```java
// 内部配置类
@Configuration
// 依赖bean
@ConditionalOnBean(PlatformTransactionManager.class)
@ConditionalOnMissingBean(AbstractTransactionManagementConfiguration.class)
public static class EnableTransactionManagementConfiguration {
    // jdk动态代理,来创建事务的aop
    @Configuration
    // 打开事务,此EnableTransactionManagement会注入事务相关的bean, 在事务管理中举足轻重
    @EnableTransactionManagement(proxyTargetClass = false)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "false",
                           matchIfMissing = false)
    public static class JdkDynamicAutoProxyConfiguration {

    }

    @Configuration
    // 打开使用; 设置使用cglib代理
    @EnableTransactionManagement(proxyTargetClass = true)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "true",
                           matchIfMissing = true)
    public static class CglibAutoProxyConfiguration {

    }

}
```

内部配置类，通过注解EnableTransactionManagement类打开事务的配置，通过此注解注入后置处理器，之后在处理器中创建事务，此处就不多做叙述了。