[TOC]

# Async的使用

本篇咱们回顾一下springboot中Async的使用，在说明使用前，先看一下javadoc中的说明，其说明的还是很清楚了，各种配置方法和使用：

```java
/**
 * Enables Spring's asynchronous method execution capability, similar to functionality
 * found in Spring's {@code <task:*>} XML namespace.
 *
 * <p>To be used together with @{@link Configuration Configuration} classes as follows,
 * enabling annotation-driven async processing for an entire Spring application context:
 *
 * <pre class="code">
 * &#064;Configuration
 * &#064;EnableAsync
 * public class AppConfig {
 * }</pre>
 *
 * {@code MyAsyncBean} is a user-defined type with one or more methods annotated with
 * either Spring's {@code @Async} annotation, the EJB 3.1 {@code @javax.ejb.Asynchronous}
 * annotation, or any custom annotation specified via the {@link #annotation} attribute.
 * The aspect is added transparently for any registered bean, for instance via this
 * configuration:
 * <pre class="code">
 * &#064;Configuration
 * public class AnotherAppConfig {
 *
 *     &#064;Bean
 *     public MyAsyncBean asyncBean() {
 *         return new MyAsyncBean();
 *     }
 * }</pre>
 *
 * <p>By default, Spring will be searching for an associated thread pool definition:
 * either a unique {@link org.springframework.core.task.TaskExecutor} bean in the context,
 * or an {@link java.util.concurrent.Executor} bean named "taskExecutor" otherwise. If
 * neither of the two is resolvable, a {@link org.springframework.core.task.SimpleAsyncTaskExecutor}
 * will be used to process async method invocations. Besides, annotated methods having a
 * {@code void} return type cannot transmit any exception back to the caller. By default,
 * such uncaught exceptions are only logged.
 *
 * <p>To customize all this, implement {@link AsyncConfigurer} and provide:
 * <ul>
 * <li>your own {@link java.util.concurrent.Executor Executor} through the
 * {@link AsyncConfigurer#getAsyncExecutor getAsyncExecutor()} method, and</li>
 * <li>your own {@link org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler
 * AsyncUncaughtExceptionHandler} through the {@link AsyncConfigurer#getAsyncUncaughtExceptionHandler
 * getAsyncUncaughtExceptionHandler()}
 * method.</li>
 * </ul>
 *
 * <p><b>NOTE: {@link AsyncConfigurer} configuration classes get initialized early
 * in the application context bootstrap. If you need any dependencies on other beans
 * there, make sure to declare them 'lazy' as far as possible in order to let them
 * go through other post-processors as well.</b>
 *
 * <pre class="code">
 * &#064;Configuration
 * &#064;EnableAsync
 * public class AppConfig implements AsyncConfigurer {
 *     &#064;Override
 *     public Executor getAsyncExecutor() {
 *         ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
 *         executor.setCorePoolSize(7);
 *         executor.setMaxPoolSize(42);
 *         executor.setQueueCapacity(11);
 *         executor.setThreadNamePrefix("MyExecutor-");
 *         executor.initialize();
 *         return executor;
 *     }
 *     &#064;Override
 *     public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
 *         return MyAsyncUncaughtExceptionHandler();
 *     }
 * }</pre>
 *
 * <p>If only one item needs to be customized, {@code null} can be returned to
 * keep the default settings. Consider also extending from {@link AsyncConfigurerSupport}
 * when possible.
 *
 * <p>Note: In the above example the {@code ThreadPoolTaskExecutor} is not a fully managed
 * Spring bean. Add the {@code @Bean} annotation to the {@code getAsyncExecutor()} method
 * if you want a fully managed bean. In such circumstances it is no longer necessary to
 * manually call the {@code executor.initialize()} method as this will be invoked
 * automatically when the bean is initialized.
 *
 * <p>For reference, the example above can be compared to the following Spring XML
 * configuration:
 *
 * <pre class="code">
 * {@code
 * <beans>
 *
 *     <task:annotation-driven executor="myExecutor" exception-handler="exceptionHandler"/>
 *
 *     <task:executor id="myExecutor" pool-size="7-42" queue-capacity="11"/>
 *
 *     <bean id="asyncBean" class="com.foo.MyAsyncBean"/>
 *
 *     <bean id="exceptionHandler" class="com.foo.MyAsyncUncaughtExceptionHandler"/>
 *
 * </beans>
 * }</pre>
 *
 * The above XML-based and JavaConfig-based examples are equivalent except for the
 * setting of the <em>thread name prefix</em> of the {@code Executor}; this is because
 * the {@code <task:executor>} element does not expose such an attribute. This
 * demonstrates how the JavaConfig-based approach allows for maximum configurability
 * through direct access to actual componentry.
 *
 * <p>The {@link #mode} attribute controls how advice is applied: If the mode is
 * {@link AdviceMode#PROXY} (the default), then the other attributes control the behavior
 * of the proxying. Please note that proxy mode allows for interception of calls through
 * the proxy only; local calls within the same class cannot get intercepted that way.
 *
 * <p>Note that if the {@linkplain #mode} is set to {@link AdviceMode#ASPECTJ}, then the
 * value of the {@link #proxyTargetClass} attribute will be ignored. Note also that in
 * this case the {@code spring-aspects} module JAR must be present on the classpath, with
 * compile-time weaving or load-time weaving applying the aspect to the affected classes.
 * There is no proxy involved in such a scenario; local calls will be intercepted as well.
 */
```

上面说到，对async的配置主要通过EnableAsync注解来打开，对其运行的线程池的配置由四种：

1. 自定义一个TaskExecutor 类型的线程池
2. 自定义一个线程池，指定此线程池bean的名字为taskExecutor
3. 通过实现AsyncConfigurer来进行配置
4. 通过继承AsyncConfigurerSupport 来配置

如果都没有配置，则使用SimpleAsyncTaskExecutor 作为默认的线程池来运行任务。

看一下具体的使用以及商贸的三种配置：

```java
@SpringBootApplication
public class ExecutorStarter {
    public static void main(String[] args) {
        SpringApplication context = new SpringApplication(ExecutorStarter.class);
        context.setBannerMode(Banner.Mode.OFF);
        context.run(args);
    }
}
```

使用指定线程池的配置：

```java
@Configuration
@EnableAsync
public class ExecutorConfig {

    @Bean("executor")
    public Executor executor(){
        ThreadFactory factory = new ThreadFactoryBuilder().setNameFormat("custome-fcatory-name-%d").setDaemon(true).build();
        int process = Runtime.getRuntime().availableProcessors();
        ThreadPoolExecutor executor = new ThreadPoolExecutor(process, Integer.MAX_VALUE, 50, TimeUnit.SECONDS, new LinkedBlockingQueue<>(100), factory);
        return executor;
    }
}
```

方法的配置：

```java
@Service
public class AsyncServiceImpl {
	// 此方法会使用SimpleAsyncTaskExecutor  默认的线程池
    @Async
    public void doTaskA() throws InterruptedException {
        System.out.println("doTaskA thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(2);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
    // 1. 在这里指定 要使用的线程池 bean name
    @Async("executor")
    public void doTaskB() throws InterruptedException {
        System.out.println("doTaskB thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(4);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
}
```



第二种，定义一个 taskExecutor的线程池：

```java
@Configuration
@EnableAsync
public class ExecutorConfig {

    @Bean("taskExecutor")
    public Executor executor(){
        ThreadFactory factory = new ThreadFactoryBuilder().setNameFormat("custome-fcatory-name-%d").setDaemon(true).build();
        int process = Runtime.getRuntime().availableProcessors();
        ThreadPoolExecutor executor = new ThreadPoolExecutor(process, Integer.MAX_VALUE, 50, TimeUnit.SECONDS,new LinkedBlockingQueue<>(100), factory);
        return executor;
    }
}
```

如果定义，则具体方法使用：

```java
@Service
public class AsyncServiceImpl {
	// 使用此taskExecutor 线程池
    @Async
    public void doTaskA() throws InterruptedException {
        System.out.println("doTaskA thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(2);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
  	// 使用此taskExecutor 线程池
    @Async
    public void doTaskB() throws InterruptedException {
        System.out.println("doTaskB thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(4);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
}
```

第三种配置：

```java
/**
 *  通过实现 AsyncConfigurer 也能实现对 Async的 配置
 */
@Configuration
@EnableAsync
public class MyAsyncConfig implements AsyncConfigurer {

    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(7);
        executor.setMaxPoolSize(42);
        executor.setQueueCapacity(11);
        executor.setThreadNamePrefix("MyAsyncConfigurer-");
        executor.initialize();
        return executor;
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return null;
    }
}
```

方法使用：

```java
@Service
public class AsyncServiceImpl {
	// 使用此 MyAsyncConfig中配置的 线程池
    @Async
    public void doTaskA() throws InterruptedException {
        System.out.println("doTaskA thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(2);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
  	// 使用此 MyAsyncConfig中配置的 线程池
    @Async
    public void doTaskB() throws InterruptedException {
        System.out.println("doTaskB thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(4);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
}
```

第四种：

```java
/**
 *  通过继承 AsyncConfigurerSupport,并复写其方法,也能实现对 async的配置
 */
@Configuration
@EnableAsync
public class MyAsyncConfigSupprt extends AsyncConfigurerSupport {
    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(7);
        executor.setMaxPoolSize(42);
        executor.setQueueCapacity(11);
        executor.setThreadNamePrefix("MyExecutorSupport-");
        executor.initialize();
        return executor;
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return super.getAsyncUncaughtExceptionHandler();
    }
}
```

方法使用：

```java
@Service
public class AsyncServiceImpl {
	// 使用此 MyAsyncConfigSupprt 中配置的 线程池
    @Async
    public void doTaskA() throws InterruptedException {
        System.out.println("doTaskA thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(2);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
  	// 使用此 MyAsyncConfigSupprt 中配置的 线程池
    @Async
    public void doTaskB() throws InterruptedException {
        System.out.println("doTaskB thread name --> " + Thread.currentThread().getName());
        long start = System.currentTimeMillis();
        TimeUnit.SECONDS.sleep(4);
        long end = System.currentTimeMillis();
        System.out.println(" doTask A 耗时: " + (end-start));
    }
}
```

到这里，几种使用方法就说明完了。





































































