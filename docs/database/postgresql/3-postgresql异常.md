## 1. 执行超时

异常栈:

```shell
### Cause: org.postgresql.util.PSQLException: ERROR: canceling statement due to user request
  Where: while updating tuple (4,14) in relation "am_collector_host_info"
; ]; ERROR: canceling statement due to user request
  Where: while updating tuple (4,14) in relation "am_collector_host_info"; nested exception is org.postgresql.util.PSQLException: ERROR: canceling stateme
nt due to user request
  Where: while updating tuple (4,14) in relation "am_collector_host_info"
org.springframework.jdbc.support.SQLStateSQLExceptionTranslator.doTranslate(SQLStateSQLExceptionTranslator.java:107)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:72)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.mybatis.spring.MyBatisExceptionTranslator.translateExceptionIfPossible(MyBatisExceptionTranslator.java:73)
org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:446)
com.sun.proxy.$Proxy67.update(Unknown Source)
org.mybatis.spring.SqlSessionTemplate.update(SqlSessionTemplate.java:294)
org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:63)
org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:59)
com.sun.proxy.$Proxy68.updateByPrimaryKeySelective(Unknown Source)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl.updateHeartbeatTime(AmCollectorHostInfoServiceImpl.java:483)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl$$FastClassBySpringCGLIB$$b1b5971e.invoke(<generated>)
org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204)
org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:746)
org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)
org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:294)
org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:98)
org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:185)
org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:688)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl$$EnhancerBySpringCGLIB$$f9d14ea1.updateHeartbeatTime(<generated>)
com.ericsson.web.controller.CollectorHeartbeatController.heartBeat(CollectorHeartbeatController.java:48)
sun.reflect.GeneratedMethodAccessor290.invoke(Unknown Source)
sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
java.lang.reflect.Method.invoke(Method.java:498)
org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:209)
org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:136)
org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:102)
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:877)
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:783)
org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)
org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:991)
org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:925)
org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:974)
org.springframework.web.servlet.FrameworkServlet.doPut(FrameworkServlet.java:888)
javax.servlet.http.HttpServlet.service(HttpServlet.java:664)
org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:851)
javax.servlet.http.HttpServlet.service(HttpServlet.java:742)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:231)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:52)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:99)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.HttpPutFormContentFilter.doFilterInternal(HttpPutFormContentFilter.java:109)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.HiddenHttpMethodFilter.doFilterInternal(HiddenHttpMethodFilter.java:93)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:200)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:198)
org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:96)
org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:493)
org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:140)
org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:81)
org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:87)
org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:342)
org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:800)
org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:66)
org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:800)
org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1471)
org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:49)
java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
java.lang.Thread.run(Thread.java:748)
```

可以看到是用户取消了执行，这个问题比较奇怪，再看配置文件中此语句的执行设置了超时时间为10s，故就对应上了。



## 2. 执行更新失败

```shell
Cause: org.postgresql.util.PSQLException: ERROR: cannot execute UPDATE in a read-only transaction
; uncategorized SQLException; SQL state [25006]; error code [0]; ERROR: cannot execute UPDATE in a read-only transaction; nested exception is org.postgresql.util.PSQLException: ERROR: cannot execute UPDATE in a read-only transaction
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:89)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.mybatis.spring.MyBatisExceptionTranslator.translateExceptionIfPossible(MyBatisExceptionTranslator.java:73)
org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:446)
com.sun.proxy.$Proxy67.update(Unknown Source)
org.mybatis.spring.SqlSessionTemplate.update(SqlSessionTemplate.java:294)
org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:63)
org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:59)
com.sun.proxy.$Proxy68.updateByPrimaryKeySelective(Unknown Source)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl.updateHeartbeatTime(AmCollectorHostInfoServiceImpl.java:483)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl$$FastClassBySpringCGLIB$$b1b5971e.invoke(<generated>)
org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204)

```

主备数据库切换，导致数据库只可读。



## 3. IO异常

```SHELL
Error querying database.  Cause: org.postgresql.util.PSQLException: An I/O error occurred while sending to the backend.
### The error may exist in class path resource [mapper/AmCollectorHostInfoMapper.xml]
### The error may involve com.ericsson.web.mapper.AmCollectorHostInfoMapper.getHostByPrimaryKey-Inline
### The error occurred while setting parameters
### SQL: select     collector_id, state, lost_heartbeat_num     from am_collector_host_info     where collector_id = ?
### Cause: org.postgresql.util.PSQLException: An I/O error occurred while sending to the backend.
; ]; An I/O error occurred while sending to the backend.; nested exception is org.postgresql.util.PSQLException: An I/O error occurred while sending to th
e backend.:
### Error querying database.  Cause: org.postgresql.util.PSQLException: An I/O error occurred while sending to the backend.
### The error may exist in class path resource [mapper/AmCollectorHostInfoMapper.xml]
### The error may involve com.ericsson.web.mapper.AmCollectorHostInfoMapper.getHostByPrimaryKey-Inline
### The error occurred while setting parameters
### SQL: select     collector_id, state, lost_heartbeat_num     from am_collector_host_info     where collector_id = ?
### Cause: org.postgresql.util.PSQLException: An I/O error occurred while sending to the backend.
; ]; An I/O error occurred while sending to the backend.; nested exception is org.postgresql.util.PSQLException: An I/O error occurred while sending to th
e backend.
org.springframework.jdbc.support.SQLStateSQLExceptionTranslator.doTranslate(SQLStateSQLExceptionTranslator.java:107)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:72)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.springframework.jdbc.support.AbstractFallbackSQLExceptionTranslator.translate(AbstractFallbackSQLExceptionTranslator.java:81)
org.mybatis.spring.MyBatisExceptionTranslator.translateExceptionIfPossible(MyBatisExceptionTranslator.java:73)
org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:446)
com.sun.proxy.$Proxy67.selectOne(Unknown Source)
org.mybatis.spring.SqlSessionTemplate.selectOne(SqlSessionTemplate.java:166)
org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:83)
org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:59)
com.sun.proxy.$Proxy68.getHostByPrimaryKey(Unknown Source)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl.updateHeartbeatTime(AmCollectorHostInfoServiceImpl.java:465)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl$$FastClassBySpringCGLIB$$b1b5971e.invoke(<generated>)
org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204)
org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:746)
org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)
org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:294)
org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:98)
org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:185)
org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:688)
com.ericsson.web.service.impl.AmCollectorHostInfoServiceImpl$$EnhancerBySpringCGLIB$$f9d14ea1.updateHeartbeatTime(<generated>)
com.ericsson.web.controller.CollectorHeartbeatController.heartBeat(CollectorHeartbeatController.java:48)
sun.reflect.GeneratedMethodAccessor290.invoke(Unknown Source)
sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
java.lang.reflect.Method.invoke(Method.java:498)
org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:209)
org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:136)
org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:102)
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:877)
org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:783)
org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)
org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:991)
org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:925)
org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:974)
org.springframework.web.servlet.FrameworkServlet.doPut(FrameworkServlet.java:888)
javax.servlet.http.HttpServlet.service(HttpServlet.java:664)
org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:851)
javax.servlet.http.HttpServlet.service(HttpServlet.java:742)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:231)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:52)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:99)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.HttpPutFormContentFilter.doFilterInternal(HttpPutFormContentFilter.java:109)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.HiddenHttpMethodFilter.doFilterInternal(HiddenHttpMethodFilter.java:93)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:200)
org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107)
org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)
org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166)
org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:198)
org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:96)
org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:493)
org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:140)
org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:81)
org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:87)
org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:342)
org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:800)
org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:66)
org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:800)
org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1471)
org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:49)
java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
java.lang.Thread.run(Thread.java:748)
```

