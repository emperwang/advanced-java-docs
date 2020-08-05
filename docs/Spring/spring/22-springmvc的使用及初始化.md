[TOC]

# spring整合springMVC使用的一些配置及初始化

本篇回顾一下在使用spring和springmvc时，需要做的配置都有哪些？

首先是web.xml的配置:

```xml
<!-- spring 容器的配置文件,其中一般写入了service dao的bean,事务 aop -->
<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>classpath:spring.xml</param-value>
</context-param>
<!-- 配置一个监听器, 会主要分析此类的作用 -->
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>
<!-- 注册servlet -->
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <!-- springmvc的配置xml,其中一般配置controller以及和springmvc有关的其他bean -->
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:spring-mvc.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
<!-- dispatcherServlet的映射路径 -->
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>/</url-pattern>
</servlet-mapping>
```

看到此配置是否很熟悉呢？ 当然我是使用了很久这样的配置，不知大家是否和我有一样的疑惑，注册的那个监听器是干啥的，为什么有设置了一个context-param后，还要给servlet设置一个参数，并且两个参数都是一些spring配置的xml文件？

如果大家没有此疑惑，或者清楚这些原理，那么就可以不用浪费使用看本篇了，本篇的就是要说一些上面的那些配置都是做什么了。

那首先来看一下这个监听器的作用，老规矩，看一下类图：

![](../../image/spring/ContextLoaderListener.png)

看到此类是一个tomcat中ServletContextListener的子类，而此类的调用呢，就在tomcat中standardContext的start阶段调用，调用的具体函数回顾一下：

> org.apache.catalina.core.StandardContext#listenerStart

```java
// 省略函数的部分主体  只看关键部分 
public boolean listenerStart() {
		........
        for (int i = 0; i < instances.length; i++) {
            if (!(instances[i] instanceof ServletContextListener))
                continue;
            ServletContextListener listener =
                (ServletContextListener) instances[i];
            try {
                fireContainerEvent("beforeContextInitialized", listener);
                if (noPluggabilityListeners.contains(listener)) {
                    // 在此处会调用监听器中的contextInitialized方法,
                 // 在springMVC和spring的整合中 web.xml中配置的监听器ContextLoaderListener 就在这里调用的
                    // 此监听器 ContextLoaderListener 创建了 XMLWebApplicationContext
                    listener.contextInitialized(tldEvent);
                } else {
                    listener.contextInitialized(event);
                }
                fireContainerEvent("afterContextInitialized", listener);
            } catch (Throwable t) {
			.......
            }
        }
        return ok;
    }
```

接下来，看一下此监听器的处理：

> org.springframework.web.context.ContextLoaderListener#contextInitialized

```java
/**
  * Initialize the root web application context.
*/
@Override
public void contextInitialized(ServletContextEvent event) {
    // 在监听器中创建root容器，也就是其他的业务bean存放
    // 正常情况下,没有controller相关的bean
    initWebApplicationContext(event.getServletContext());
}
```





























