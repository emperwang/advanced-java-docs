[TOC]

# springboot AOP的配置

本篇来看一下springbot中对AOP的自动配置，在spring.factories中配置:

```java
// springboot aop的自动配置
@Configuration
// 依赖的条件
@ConditionalOnClass({ EnableAspectJAutoProxy.class, Aspect.class, Advice.class, AnnotatedElement.class })
// 依赖的配置
@ConditionalOnProperty(prefix = "spring.aop", name = "auto", havingValue = "true", matchIfMissing = true)
public class AopAutoConfiguration {
    // 内部配置类
    @Configuration
    // 使用aop,指定使用jdk
    // 此注解在aop的作用,同样是 举足轻重
    @EnableAspectJAutoProxy(proxyTargetClass = false)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "false",
                           matchIfMissing = false)
    public static class JdkDynamicAutoProxyConfiguration {

    }
    // 内部配置类
    @Configuration
    // 打开aop, 并指定使用cglib
    @EnableAspectJAutoProxy(proxyTargetClass = true)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "true",
                           matchIfMissing = true)
    public static class CglibAutoProxyConfiguration {

    }
}
```

在其中使用了两个内部配置类，来根据条件打开了JDK或cglib的AOP代理，当然了通过EnableAspectJAutoProxy注解，注入具体的处理器，之后由处理器进行具体的AOP的创建，此处就不多说了。















































