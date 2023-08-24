# Schedule task 原理

## 1. demo

配置类:

```java
@EnableScheduling
@Configuration
public class ScheduleConfig {
}
```

任务类:

```java
@Component
public class FixRateTask {

    private SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    @Scheduled(fixedRate = 5000)
    public void FixRateTask(){
        System.out.println("begin time： " + format.format(new Date()));
        System.out.println("fix rate task begin...");
        System.out.println();
    }

    @Schedules(value = {
            @Scheduled(cron = "*/5 * * * * *")
    })
    public void cronTask(){
        System.out.println();
        System.out.println("cron task start: " + format.format(new Date()));
        System.out.println("cron task: 5 * * * * *");
        System.out.println();
    }

}
```

按照上面配置好之后, 启动项目任务就会按照配置进行执行.  下面就来看一下这个schedule task的实现.



## 2. 实现原理

这里就看一下spring对schedule task是如何实现的.  按照平常看spring源码的惯用方法,  从这个enable注解开始.

> org.springframework.scheduling.annotation.EnableScheduling

```java
/*
  使能调度的操作
  即 注入一个配置类到 容器中
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Import(SchedulingConfiguration.class)
@Documented
public @interface EnableScheduling {

}
```

> org.springframework.scheduling.annotation.SchedulingConfiguration

```java
/*
针对scheduling 调度注解的配置类
可以看到角色是 指令
并注入一个后置处理器到容器中
 */
@Configuration
@Role(BeanDefinition.ROLE_INFRASTRUCTURE)
public class SchedulingConfiguration {

    @Bean(name = TaskManagementConfigUtils.SCHEDULED_ANNOTATION_PROCESSOR_BEAN_NAME)
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    public ScheduledAnnotationBeanPostProcessor scheduledAnnotationProcessor() {
        // 注入针对scheduling处理的后置处理器
        return new ScheduledAnnotationBeanPostProcessor();
    }
}
```

看一下注入到容器中的此后置处理器:

![](spring-schedule.png)

![](spring-ScheduleAnnotationBeanPostProcessor.png)

可以看到此后置处理器的类图还是比较复杂的, 实现了众多的aware接口, 以及 beanPostProcessor后置处理器.  对于aware接口就不细看了, 主要看一下BeanPostProcessor后置处理器的处理方法, 来了解下此处理器在schedule实现中承担了什么作用.

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#ScheduledAnnotationBeanPostProcessor()

```java
public ScheduledAnnotationBeanPostProcessor() {
    // 创建任务的调度器
    this.registrar = new ScheduledTaskRegistrar();
}
```

`ScheduledTaskRegistrar`此保存了项目中配置的schedule task信息。

> org.springframework.scheduling.config.ScheduledTaskRegistrar

```java
// 任务的执行器, 默认使用 使用单线程线程池
/**
	 * 简单来说 即如果没有在容器中设置线程池的话, 或默认使用newSingleThreadScheduledExecutor 线程池来执行任务
	 * 即默认情况下会使用coresize=1, 最大线程数为Integer.MAX 的线程池; 个人感觉这样效率也不会低到哪里
	 */
@Nullable
private TaskScheduler taskScheduler;
// 默认使用单线程线程池
@Nullable
private ScheduledExecutorService localExecutor;
// 当还没有配置 执行器,即设置线程池时, 会先把任务 暂时存储到这里
@Nullable
private List<TriggerTask> triggerTasks;
// 当还没有配置线程池时 crontab任务先保存到这里
@Nullable
private List<CronTask> cronTasks;
// 作用类似上面的容器, 只是存储的任务是 fixRate任务
@Nullable
private List<IntervalTask> fixedRateTasks;
@Nullable
private List<IntervalTask> fixedDelayTasks;
// 当还没有配置线程池时, 对于提交的任务 会保存到这里
private final Map<Task, ScheduledTask> unresolvedTasks = new HashMap<>(16);
// 此容器会记录 调度执行的任务
private final Set<ScheduledTask> scheduledTasks = new LinkedHashSet<>(16);
```

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#postProcessAfterInitialization

```java
@Override
public Object postProcessAfterInitialization(Object bean, String beanName) {
    // 针对 Aop TaskScheduler 和 ExecutorService 类型的bean 跳过 不进行处理
    if (bean instanceof AopInfrastructureBean || bean instanceof TaskScheduler ||
        bean instanceof ScheduledExecutorService) {
        // Ignore AOP infrastructure such as scoped proxies.
        return bean;
    }

    Class<?> targetClass = AopProxyUtils.ultimateTargetClass(bean);
    if (!this.nonAnnotatedClasses.contains(targetClass)) {
        // 查找带有 Scheduled注解 和  Schedules 注解的方法
        Map<Method, Set<Scheduled>> annotatedMethods = MethodIntrospector.selectMethods(targetClass,                                                 (MethodIntrospector.MetadataLookup<Set<Scheduled>>) method -> {Set<Scheduled> scheduledMethods = AnnotatedElementUtils.getMergedRepeatableAnnotations(method, Scheduled.class, Schedules.class);
return (!scheduledMethods.isEmpty() ? scheduledMethods : null);});
        if (annotatedMethods.isEmpty()) {
            // 记录下 没有 schedule 方法的类
            this.nonAnnotatedClasses.add(targetClass);
            if (logger.isTraceEnabled()) {
                logger.trace("No @Scheduled annotations found on bean class: " + targetClass);
            }
        }
        else {
            // Non-empty set of methods
            // 针对带有 scheduled 注解的方法进行处理
            annotatedMethods.forEach((method, scheduledMethods) ->
            // 对方法的处理
            /**
			* processScheduled  具体的处理方法 重点-------------
			*/
scheduledMethods.forEach(scheduled -> processScheduled(scheduled, method, bean)));
            if (logger.isTraceEnabled()) {
                logger.trace(annotatedMethods.size() + " @Scheduled methods processed on bean '" + beanName +"': " + annotatedMethods);
            }
        }
    }
    return bean;
}
```

通过这个方法可以看到, 此会查找容器中各个bean中所有带有`Scheduled`和`Schedules`注解的方法, 并把获取到的方法进行处理, 并保存下来, 以备后续的调用.

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#processScheduled
>
> 此主要是对带有schedule注解的方法

```java
// 对调度方法的处理
protected void processScheduled(Scheduled scheduled, Method method, Object bean) {
    try {
        // 把 要运行的方法和 target 封装为 Runanble,即一个运行接口
        Runnable runnable = createRunnable(bean, method);
        boolean processedSchedule = false;
        String errorMessage =
            "Exactly one of the 'cron', 'fixedDelay(String)', or 'fixedRate(String)' attributes is required";
        // 记录解析到的各个method
        Set<ScheduledTask> tasks = new LinkedHashSet<>(4);

        // Determine initial delay
        // 获得方法被调用前的初始 延迟时间
        long initialDelay = scheduled.initialDelay();
        String initialDelayString = scheduled.initialDelayString();
        if (StringUtils.hasText(initialDelayString)) {
            Assert.isTrue(initialDelay < 0, "Specify 'initialDelay' or 'initialDelayString', not both");
            // SPEL 表达式解析
            if (this.embeddedValueResolver != null) {
                initialDelayString = this.embeddedValueResolver.resolveStringValue(initialDelayString);
            }
            if (StringUtils.hasLength(initialDelayString)) {
                try {
                    initialDelay = parseDelayAsLong(initialDelayString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException("Invalid initialDelayString value \"" + initialDelayString + "\" - cannot parse into long");
                }
            }
        }

        // Check cron expression
        // 获得method的crontab表达式
        String cron = scheduled.cron();
        if (StringUtils.hasText(cron)) {
            String zone = scheduled.zone();
            if (this.embeddedValueResolver != null) {
                // SPEL 表达式解析,
                cron = this.embeddedValueResolver.resolveStringValue(cron);
                zone = this.embeddedValueResolver.resolveStringValue(zone);
            }
            if (StringUtils.hasLength(cron)) {
 Assert.isTrue(initialDelay == -1, "'initialDelay' not supported for cron triggers");
                processedSchedule = true;
                // 设置了crontab 表达式
                if (!Scheduled.CRON_DISABLED.equals(cron)) {
                    TimeZone timeZone;
                    // 解析 时区
                    if (StringUtils.hasText(zone)) {
                        timeZone = StringUtils.parseTimeZoneString(zone);
                    }
                    else {
                        timeZone = TimeZone.getDefault();
                    }
                    // 记录解析到的 method
                    // CronTrigger封装 crontab任务的触发时间
                    // CronTask 封装trigger表达式和 要运行的 方法
                    // scheduleCronTask 注册crontab任务
                    tasks.add(this.registrar.scheduleCronTask(new CronTask(runnable, new CronTrigger(cron, timeZone))));
                }
            }
        }

// At this point we don't need to differentiate between initial delay set or not anymore
        if (initialDelay < 0) {
            initialDelay = 0;
        }

        // Check fixed delay
        long fixedDelay = scheduled.fixedDelay();
        if (fixedDelay >= 0) {
            Assert.isTrue(!processedSchedule, errorMessage);
            processedSchedule = true;
            // 提交fixed delay任务
            tasks.add(this.registrar.scheduleFixedDelayTask(new FixedDelayTask(runnable, fixedDelay, initialDelay)));
        }
        String fixedDelayString = scheduled.fixedDelayString();
        if (StringUtils.hasText(fixedDelayString)) {
            if (this.embeddedValueResolver != null) {
                fixedDelayString = this.embeddedValueResolver.resolveStringValue(fixedDelayString);
            }
            if (StringUtils.hasLength(fixedDelayString)) {
                Assert.isTrue(!processedSchedule, errorMessage);
                processedSchedule = true;
                try {
                    fixedDelay = parseDelayAsLong(fixedDelayString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException(
                        "Invalid fixedDelayString value \"" + fixedDelayString + "\" - cannot parse into long");
                }
                // 再次 提交任务
                tasks.add(this.registrar.scheduleFixedDelayTask(new FixedDelayTask(runnable, fixedDelay, initialDelay)));
            }
        }

        // Check fixed rate
        long fixedRate = scheduled.fixedRate();
        if (fixedRate >= 0) {
            Assert.isTrue(!processedSchedule, errorMessage);
            processedSchedule = true;
            tasks.add(this.registrar.scheduleFixedRateTask(new FixedRateTask(runnable, fixedRate, initialDelay)));
        }
        String fixedRateString = scheduled.fixedRateString();
        if (StringUtils.hasText(fixedRateString)) {
            if (this.embeddedValueResolver != null) {
                fixedRateString = this.embeddedValueResolver.resolveStringValue(fixedRateString);
            }
            if (StringUtils.hasLength(fixedRateString)) {
                Assert.isTrue(!processedSchedule, errorMessage);
                processedSchedule = true;
                try {
                    fixedRate = parseDelayAsLong(fixedRateString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException(
"Invalid fixedRateString value \"" + fixedRateString + "\" - cannot parse into long");
                }
                tasks.add(this.registrar.scheduleFixedRateTask(new FixedRateTask(runnable, fixedRate, initialDelay)));
            }
        }

        // Check whether we had any attribute set
        Assert.isTrue(processedSchedule, errorMessage);

        // Finally register the scheduled tasks
        synchronized (this.scheduledTasks) {
            Set<ScheduledTask> regTasks = this.scheduledTasks.computeIfAbsent(bean, key -> new LinkedHashSet<>(4));
            regTasks.addAll(tasks);
        }
    }
    catch (IllegalArgumentException ex) {
        throw new IllegalStateException(
            "Encountered invalid @Scheduled method '" + method.getName() + "': " + ex.getMessage());
    }
}
```

此方法首先通过`createRunnable`把方法封装成一个Runnable接口实现类,  简单说就是在Runnable接口中的run方法中调用method方法. 之后开始对scheduled注解中 crontab表达式/ fixrate 等信息进行解析, 并把最后解析到的方法保存起来, 即注册到`ScheduledTaskRegistrar`中.

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#createRunnable

```java
// 这里把要被调用的方法和 target进行封装, 等待被调用
protected Runnable createRunnable(Object target, Method method) {
    Assert.isTrue(method.getParameterCount() == 0, "Only no-arg methods may be annotated with @Scheduled");
    Method invocableMethod = AopUtils.selectInvocableMethod(method, target.getClass());
    // 把要被调用的方法 和 target 进行封装
    return new ScheduledMethodRunnable(target, invocableMethod);
}
```

> org.springframework.scheduling.support.ScheduledMethodRunnable#ScheduledMethodRunnable(java.lang.Object, java.lang.reflect.Method)

```java
	public ScheduledMethodRunnable(Object target, Method method) {
		this.target = target;
		this.method = method;
	}
```

> org.springframework.scheduling.support.ScheduledMethodRunnable#run

```java
@Override
public void run() {
    try {
        // 使方法可访问
        ReflectionUtils.makeAccessible(this.method);
        // 方法调用
        this.method.invoke(this.target);
    }
    catch (InvocationTargetException ex) {
        ReflectionUtils.rethrowRuntimeException(ex.getTargetException());
    }
    catch (IllegalAccessException ex) {
        throw new UndeclaredThrowableException(ex);
    }
}
```

可以看到`createRunnable`就是把带有注解的方法封装为ScheduledMethodRunnable,即 `Runnable`实现类, 并在run方法中实现了对method方法的调用. 

`想一下为啥要这么做呢?`

> 其实简单说,  后续的方法调用都是在线程池中调用的,  把要执行的方法封装到Runnable中, 可以方便提交到线程池中去执行.



其实通过上面一个postProcessAfterInitialization的处理, 就已经把容器中所有的调用scheduled注解的方法进行了处理, 那么什么时候进行任务的提交呢?

那咱们带着问题, 继续向下分析.

![](ScheduleAnnotationBeanPostProcessor.png)

可以看到此类还是一个事件的监听器实现. 看一下此监听器对事件的处理:

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#onApplicationEvent

```java
@Override
public void onApplicationEvent(ContextRefreshedEvent event) {
    if (event.getApplicationContext() == this.applicationContext) {
        // Running in an ApplicationContext -> register tasks this late...
        // giving other ContextRefreshedEvent listeners a chance to perform
        // their work at the same time (e.g. Spring Batch's job registration).
        finishRegistration();
    }
}
```

> org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor#finishRegistration

```java
// 上面分析完了method的处理
// 此处就开始了对 分析完成的 method进行 任务的提交
private void finishRegistration() {
    if (this.scheduler != null) {
        this.registrar.setScheduler(this.scheduler);
    }

    if (this.beanFactory instanceof ListableBeanFactory) {
        // 从容器中获取到 SchedulingConfigurer 这种类型的 bean
        Map<String, SchedulingConfigurer> beans =
            ((ListableBeanFactory) this.beanFactory).getBeansOfType(SchedulingConfigurer.class);
        List<SchedulingConfigurer> configurers = new ArrayList<>(beans.values());
        AnnotationAwareOrderComparator.sort(configurers);
        // 调用这些配置类 对register中的任务 进行配置
        for (SchedulingConfigurer configurer : configurers) {
            configurer.configureTasks(this.registrar);
        }
    }

    if (this.registrar.hasTasks() && this.registrar.getScheduler() == null) {
        Assert.state(this.beanFactory != null, "BeanFactory must be set to find scheduler by type");
        try {
            // Search for TaskScheduler bean...
            // 从容器中去获取 TaskScheduler 类型的bean, 此处查找是按照类型去查找
            this.registrar.setTaskScheduler(resolveSchedulerBean(this.beanFactory, TaskScheduler.class, false));
        }
        catch (NoUniqueBeanDefinitionException ex) {
            logger.trace("Could not find unique TaskScheduler bean", ex);
            try {
                // 按照名字去容器中查找对应的 TaskScheduler 类型的bean
                this.registrar.setTaskScheduler(resolveSchedulerBean(this.beanFactory, TaskScheduler.class, true));
            }
            catch (NoSuchBeanDefinitionException ex2) {
                if (logger.isInfoEnabled()) {
                    logger.info("More than one TaskScheduler bean exists within the context, and " +"none is named 'taskScheduler'. Mark one of them as primary or name it 'taskScheduler' " +"(possibly as an alias); or implement the SchedulingConfigurer interface and call " +"ScheduledTaskRegistrar#setScheduler explicitly within the configureTasks() callback: " +ex.getBeanNamesFound());
                }
            }
        }
        catch (NoSuchBeanDefinitionException ex) {
            logger.trace("Could not find default TaskScheduler bean", ex);
            // Search for ScheduledExecutorService bean next...
            try {
                // 去容器中按照类型查找 ScheduledExecutorService 类型的bean
                this.registrar.setScheduler(resolveSchedulerBean(this.beanFactory, ScheduledExecutorService.class, false));
            }
            catch (NoUniqueBeanDefinitionException ex2) {
                logger.trace("Could not find unique ScheduledExecutorService bean", ex2);
                try {
                    // 去容器中按照名字查找 ScheduledExecutorService 类型的bean
                    this.registrar.setScheduler(resolveSchedulerBean(this.beanFactory, ScheduledExecutorService.class, true));
                }
                catch (NoSuchBeanDefinitionException ex3) {
                    if (logger.isInfoEnabled()) {
                        logger.info("More than one ScheduledExecutorService bean exists within the context, and " +"none is named 'taskScheduler'. Mark one of them as primary or name it 'taskScheduler' " +"(possibly as an alias); or implement the SchedulingConfigurer interface and call " +"ScheduledTaskRegistrar#setScheduler explicitly within the configureTasks() callback: " + ex2.getBeanNamesFound());
                    }
                }
            }
            catch (NoSuchBeanDefinitionException ex2) {
                logger.trace("Could not find default ScheduledExecutorService bean", ex2);
                // Giving up -> falling back to default scheduler within the registrar...
                logger.info("No TaskScheduler/ScheduledExecutorService bean found for scheduled processing");
            }
        }
    }
    // 开始调度任务
    // 即任务从这里开始 提交到线程池中 准备进行执行
    this.registrar.afterPropertiesSet();
}
```

上面的处理中spring还留有一个扩展接口`SchedulingConfigurer`,  此接口可以用来再次对要处理的任务进行处理. 之后就开始从容器中查找线程池, 看看容器中有没有进行配置, 如果配置了则使用用户配置的线程池. 如果没有配置的话, 最终使用的线程池是`Executors.newSingleThreadScheduledExecutor`.

从容器中查找线程池顺序:

1. 查找TaskScheduler类型的bean
2. 查找 taskScheduler 名字的bean
3. 查找ScheduledExecutorService类型的bean
4. 查找scheduledExecutorService 名字的bean
5. 如果没有查找到相应的线程池的画, 就使用`Executors.newSingleThreadScheduledExecutor`

> org.springframework.scheduling.config.ScheduledTaskRegistrar#afterPropertiesSet

```java
@Override
public void afterPropertiesSet() {
    // 调度任务
    scheduleTasks();
}
```

```java
protected void scheduleTasks() {
    // 这里是对 执行器即 线程池的一个创建
    if (this.taskScheduler == null) {
        // 默认是单线程的线程池
        this.localExecutor = Executors.newSingleThreadScheduledExecutor();
        // 使用的是 单线程的线程池
        this.taskScheduler = new ConcurrentTaskScheduler(this.localExecutor);
    }
    if (this.triggerTasks != null) {
        for (TriggerTask task : this.triggerTasks) {
            // 记录任务
            addScheduledTask(scheduleTriggerTask(task));
        }
    }
    if (this.cronTasks != null) {
        for (CronTask task : this.cronTasks) {
            // 调度任务 并记录
            addScheduledTask(scheduleCronTask(task));
        }
    }
    if (this.fixedRateTasks != null) {
        for (IntervalTask task : this.fixedRateTasks) {
            // 调度任务并执行
            addScheduledTask(scheduleFixedRateTask(task));
        }
    }
    if (this.fixedDelayTasks != null) {
        for (IntervalTask task : this.fixedDelayTasks) {
            addScheduledTask(scheduleFixedDelayTask(task));
        }
    }
}
```

这里对解析到的cronTask,  fixRateTask,  fixedDelayTask 进行提交.

> org.springframework.scheduling.config.ScheduledTaskRegistrar#scheduleFixedRateTask(org.springframework.scheduling.config.IntervalTask)

这里看一下scheduleFixedRateTask任务的提交:

```java
@Nullable
public ScheduledTask scheduleFixedRateTask(IntervalTask task) {
    // 把任务 封装为一个 FixedRateTask
    FixedRateTask taskToUse = (task instanceof FixedRateTask ? (FixedRateTask) task :
                               new FixedRateTask(task.getRunnable(), task.getInterval(), task.getInitialDelay()));
    // 调度任务
    return scheduleFixedRateTask(taskToUse);
}
```

```java
// fixedRate 任务执行
@Nullable
public ScheduledTask scheduleFixedRateTask(FixedRateTask task) {
    ScheduledTask scheduledTask = this.unresolvedTasks.remove(task);
    boolean newTask = false;
    if (scheduledTask == null) {
        scheduledTask = new ScheduledTask(task);
        newTask = true;
    }
    if (this.taskScheduler != null) {
        if (task.getInitialDelay() > 0) {
            Date startTime = new Date(System.currentTimeMillis() + task.getInitialDelay());
            // 提交任务
            scheduledTask.future =
                this.taskScheduler.scheduleAtFixedRate(task.getRunnable(), startTime, task.getInterval());
        }
        else {
            scheduledTask.future =
                this.taskScheduler.scheduleAtFixedRate(task.getRunnable(), task.getInterval());
        }
    }
    else {
        // 记录任务
        addFixedRateTask(task);
        this.unresolvedTasks.put(task, scheduledTask);
    }
    return (newTask ? scheduledTask : null);
}
```

crontask任务的提交

```java
// 注册crontab任务
@Nullable
public ScheduledTask scheduleCronTask(CronTask task) {
    ScheduledTask scheduledTask = this.unresolvedTasks.remove(task);
    boolean newTask = false;
    if (scheduledTask == null) {
        scheduledTask = new ScheduledTask(task);
        newTask = true;
    }
    if (this.taskScheduler != null) {
        // 调度执行 crontab任务
        scheduledTask.future = this.taskScheduler.schedule(task.getRunnable(), task.getTrigger());
    }
    else {
        // 记录任务
        addCronTask(task);
        this.unresolvedTasks.put(task, scheduledTask);
    }
    return (newTask ? scheduledTask : null);
}
```

今天就先分析到这里了, 可以看到对scheduled类型的任务, 相当于是spring进行了一些封装, 最终仍然是提交到线程池中进行任务的执行.















































































