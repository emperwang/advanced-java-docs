[TOC]

# springboot中的servlet的使用

大家有在springboot中使用自定义的servlet吗? 本篇准备介绍一下在springboot中是如何使用自定义servlet，以及如何把servlet注册到tomcat容器中的。

先看一下在springboot中如何使用自定义的servlet，方式有两种，咱们都说一下。

方式一:

首先定义一个servlet， 并使用WebServlet注解：

```java
@WebServlet(urlPatterns = "/demo1")
public class ServletDemo1 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().write("this is servlet demo 1");
        resp.getWriter().close();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
```

之后进行配置：

```java
@Configuration
@ServletComponentScan("com.bt")  // 注册此处路径，一定要包含上面定义的servlet
public class ServletConfig {

}
```

方式二:

首先定义一个servlet：

```java
public class ServletDemo2 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        PrintWriter writer = resp.getWriter();
        writer.write("this is  servlet demo2 ");
        writer.flush();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
```

使用配置类，添加到springboot中:

```java
@Configuration
public class ServletConfig {
    // 通过bean来创建一个servlet
    @Bean
    public ServletRegistrationBean servletRegistrationBean(){
        return new ServletRegistrationBean<ServletDemo2>(new ServletDemo2(), "/demo2");
    }
}
```

使用者两个方式都可以把servlet添加到tomcat中，并正常使用。当前了对于filter，以及listener使用方法都类似。

可以看到此两种方法的不同，后面会主要分析一下注解ServletComponentScan的作用，以及ServletRegistrationBean的作用，了解一下其是如何把servlet扫描到，并注册到tomcat中。



















































































