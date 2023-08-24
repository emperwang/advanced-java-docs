[TOC]

# springboot Lifecycle处理

在分析springboot 和kakfa的整合源码时，发现真正提交kakfa的消费任务到线程池的地方是在 SmartLifeCycle类型bean的start方法（没有配置kakfa消费的自动启动）。所以就比较好奇这个LifeCycle的处理是在哪里进行的，以及具体的动作是啥。好了，明确了需求（了解原理），就来看看其实现把。

这里以refresh方法入手吧。

```java
public void refresh() throws BeansException, IllegalStateException {
		synchronized (this.startupShutdownMonitor) {
			// Prepare this context for refreshing.
			// 第一步  ioc容器开始启动前的准备工作,如  记录启动时间,修改容器是否启动的标志
			prepareRefresh();

			// Tell the subclass to refresh the internal bean factory.
			// 第二步 获取BeanFactory
			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

			// Prepare the bean factory for use in this context.
			// 对bean工厂进行一些配置
			/**
			 * 第三步
			 * 1. 设置类加载器
			 * 2. 设置El表达式解析器
			 * 3. 设置PropertyEditorRegistrar
			 * 4. 配置两个后置处理器
			 * 5. 配置一些不需要自动装配的bean
			 * 6. 配置一些自动装配时固定类型的bean
			 * 7. 添加环境相关的bean到容器
			 */
			prepareBeanFactory(beanFactory);

			try {
				// Allows post-processing of the bean factory in context subclasses.
				// 用于子类进行扩展
				// 对于web工程是有做扩展操作的,等看到web源码时,在细看
				// 第四步
				postProcessBeanFactory(beanFactory);

				// Invoke factory processors registered as beans in the context.
				/**
				 * 第五步
				 * 1. 调用 所有的BeanDefinitionRegistryPostProcessor 后置处理器
				 * 2. 调用所有的BeanFactoryPostProcessor 后置处理器
				 */
				invokeBeanFactoryPostProcessors(beanFactory);

				// Register bean processors that intercept bean creation.
				// 注册BeanPostProcessor 后置处理器
				// 第六步
				registerBeanPostProcessors(beanFactory);

				// Initialize message source for this context.
				// 初始化国际消息组件 -- 后看
				// 第七步
				initMessageSource();

				// Initialize event multicaster for this context.
				// 第八步  为此上下文初始化 事件多播器
				initApplicationEventMulticaster();

				// Initialize other special beans in specific context subclasses.
				// 第九步  此主要用于子类进行扩展
				onRefresh();

				// Check for listener beans and register them.
				// 第十步  注册监听器
				registerListeners();

				// Instantiate all remaining (non-lazy-init) singletons.
				// 第十一步 重点  重点  重点
				// 此方法会实例化所有的非懒加载的bean
				finishBeanFactoryInitialization(beanFactory);

				// Last step: publish corresponding event.
				// 完成refresh
				// 第十二步
				// LifeCycle 的调用在这里; 注意哦,具体的处理这里.
				finishRefresh();
			}
			catch (BeansException ex) {
				if (logger.isWarnEnabled()) {
					logger.warn("Exception encountered during context initialization - " +
							"cancelling refresh attempt: " + ex);
				}
				// 第十三步 Destroy already created singletons to avoid dangling resources.
				destroyBeans();
				// 第十四步  Reset 'active' flag.
				cancelRefresh(ex);
				// Propagate exception to caller.
				throw ex;
			}
			finally {
				// Reset common introspection caches in Spring's core, since we
				// 第十五步  might not ever need metadata for singleton beans anymore...
				resetCommonCaches();
			}
		}
	}
```

从上面源码看，具体的处理入口应该在finishRefresh这个方法中，接着走下：

```java
	protected void finishRefresh() {
		// 清除资源缓存
		// Clear context-level resource caches (such as ASM metadata from scanning).
		clearResourceCaches();

		// Initialize lifecycle processor for this context.
		// 此处主要是获取 LifeCycle的处理器
		// 1. 先去容器中获取,也就是说用户可以自定义,如果用户自定义了,则使用用户自己的
		// 2. 如果用户没有自定义处理器,则创建一个默认的DefaultLifecycleProcessor
		initLifecycleProcessor();

		// Propagate refresh to lifecycle processor first.
		// 重新调用一次Lifecycle类型bean的start方法
		getLifecycleProcessor().onRefresh();

		// Publish the final event.
		// 发布一个事件
		publishEvent(new ContextRefreshedEvent(this));

		// Participate in LiveBeansView MBean, if active.
		// MBean 操作
		LiveBeansView.registerApplicationContext(this);
	}
```

注释写的还是比较清楚的，继续走：

```java
protected void initLifecycleProcessor() {
		ConfigurableListableBeanFactory beanFactory = getBeanFactory();
		// 先看容器中是否有 LifeCycle processor(LifeCycle 处理器)
		// 如果容器中已经存在,则使用已经存在的
		if (beanFactory.containsLocalBean(LIFECYCLE_PROCESSOR_BEAN_NAME)) {
			this.lifecycleProcessor =
					beanFactory.getBean(LIFECYCLE_PROCESSOR_BEAN_NAME, LifecycleProcessor.class);
			if (logger.isTraceEnabled()) {
				logger.trace("Using LifecycleProcessor [" + this.lifecycleProcessor + "]");
			}
		}
		else {
			// 如果容器中目前没有 LifeCycle 的处理器,则创建一个默认的: DefaultLifecycleProcessor
			DefaultLifecycleProcessor defaultProcessor = new DefaultLifecycleProcessor();
			// 记录bean工厂到 处理器中
			defaultProcessor.setBeanFactory(beanFactory);
			// 记录处理器
			this.lifecycleProcessor = defaultProcessor;
			// 把处理器注册到容器中
			beanFactory.registerSingleton(LIFECYCLE_PROCESSOR_BEAN_NAME, this.lifecycleProcessor);
			if (logger.isTraceEnabled()) {
				logger.trace("No '" + LIFECYCLE_PROCESSOR_BEAN_NAME + "' bean, using " +
						"[" + this.lifecycleProcessor.getClass().getSimpleName() + "]");
			}
		}
	}
```

这个方法也很清晰了，主要就是获取LifeCycle的处理器，如果没有就去创建。

```java
// 这个方法就是调用 LifeCycle的onRefresh方法. 这里咱们看默认的处理器是如何处理的DefaultLifecycleProcessor
getLifecycleProcessor().onRefresh();
```

```java
	public void onRefresh() {
        // 启动bean
		startBeans(true);
		this.running = true;
	}
```

这里虽然是刷新，实际的动作是执行bean的start方法。

```java
private void startBeans(boolean autoStartupOnly) {
		// 获取所有的Lifecyel类型的bean
		Map<String, Lifecycle> lifecycleBeans = getLifecycleBeans();
		Map<Integer, LifecycleGroup> phases = new HashMap<>();
		// 遍历所有的bean,把bean根据不同的阶段进行分组
		// 对SmartLifeCycle类型的bean的处理
		lifecycleBeans.forEach((beanName, bean) -> {
			if (!autoStartupOnly || (bean instanceof SmartLifecycle && ((SmartLifecycle) bean).isAutoStartup())) {
				// 调用Phased类型bean的 getPhase方法,获取此bean的 phase
				int phase = getPhase(bean);
                // LifecycleGroup此时内部类,主要是记录同一个phase的bean
				LifecycleGroup group = phases.get(phase);
				if (group == null) {
					/*
					this.phase = phase;
					this.timeout = timeoutPerShutdownPhase;
					this.lifecycleBeans = lifecycleBeans;
					this.autoStartupOnly = autoStartupOnly;
					 */
                    // 第一次进入,当然需要创建一个group了
					group = new LifecycleGroup(phase, this.timeoutPerShutdownPhase, lifecycleBeans, autoStartupOnly);
                    // 记录创建好的group, key为 phase
					phases.put(phase, group);
				}
				// 把相同的 phase 的bean 放到同一个 group中
				group.add(beanName, bean);
			}
		});
		// 把不同阶段的bean进行排序,并按照顺序进行启动
		if (!phases.isEmpty()) {
			List<Integer> keys = new ArrayList<>(phases.keySet());
			// 对key进行排序,也就是从小到大
            Collections.sort(keys);
			// 调用LifeCycle的start 方法
            // 根据phase,从小到大进行 调用
			for (Integer key : keys) {
				phases.get(key).start();
			}
		}
	}
```



下面看一下这个方法: getLifecycleBeans

```java
protected Map<String, Lifecycle> getLifecycleBeans() {
		// 获取容器
		ConfigurableListableBeanFactory beanFactory = getBeanFactory();
		// 存储Lifecycle的容器
		Map<String, Lifecycle> beans = new LinkedHashMap<>();
		// 获取Lifecycle类型的bean
		String[] beanNames = beanFactory.getBeanNamesForType(Lifecycle.class, false, false);
		for (String beanName : beanNames) { // 遍历所有的bean
			// 获取bean的真实名字
			String beanNameToRegister = BeanFactoryUtils.transformedBeanName(beanName);
			// 是否是factorybean
			boolean isFactoryBean = beanFactory.isFactoryBean(beanNameToRegister);
			String beanNameToCheck = (isFactoryBean ? BeanFactory.FACTORY_BEAN_PREFIX + beanName : beanName);
			if ((beanFactory.containsSingleton(beanNameToRegister) &&
					(!isFactoryBean || matchesBeanType(Lifecycle.class, beanNameToCheck, beanFactory))) ||
					matchesBeanType(SmartLifecycle.class, beanNameToCheck, beanFactory)) {
				// 从容器中获取bean
				Object bean = beanFactory.getBean(beanNameToCheck);
				if (bean != this && bean instanceof Lifecycle) {
					beans.put(beanNameToRegister, (Lifecycle) bean);
				}
			}
		}
		return beans;
	}
```

这个方法也是比较清晰了，主要是从容器中获取 LifeCycle类型的bean。

下面就看一下这个具体的调用方法把， 此方法是LifecycleGroup中的start方法。

```java
private final List<LifecycleGroupMember> members = new ArrayList<>();
public void start() {
    // 此members是个啥呢?
    // 还记得这个操作吧group.add(beanName, bean),此操作就是把相同phase的bean记录到members中
    // 所以了,如果这个member为空,也就是这个 phase没有bean可被执行
    if (this.members.isEmpty()) {
        return;
    }
    if (logger.isDebugEnabled()) {
        logger.debug("Starting beans in phase " + this.phase);
    }
    // 排序
    Collections.sort(this.members);
    // 进行调用
    // 在对 lifeCycle进行调用时,先调用其依赖的bean的 start
    // 之后在调用本bean的start方法
    for (LifecycleGroupMember member : this.members) {
        doStart(this.lifecycleBeans, member.name, this.autoStartupOnly);
    }
}
```



```java
// 调用bean的start方法
private void doStart(Map<String, ? extends Lifecycle> lifecycleBeans, String beanName, boolean autoStartupOnly) {
    Lifecycle bean = lifecycleBeans.remove(beanName);
    if (bean != null && bean != this) {
        // 先获取此bean的依赖的bean
        String[] dependenciesForBean = getBeanFactory().getDependenciesForBean(beanName);
        // 先启动依赖的bean
        for (String dependency : dependenciesForBean) {
            doStart(lifecycleBeans, dependency, autoStartupOnly);
        }
        // !bean.isRunning() 表示 bean还没有被执行
        // !autoStartupOnly 这是传递的参数startBeans(true), 所以这里就是false
        // !(bean instanceof SmartLifecycle) 不是SmartLifeCycle类型
        // ((SmartLifecycle) bean).isAutoStartup()) 如果是SmartLifeCycle类型,那是否设置了自动启动
        if (!bean.isRunning() &&
            (!autoStartupOnly || !(bean instanceof SmartLifecycle) || ((SmartLifecycle) bean).isAutoStartup())) {
            if (logger.isTraceEnabled()) {
                logger.trace("Starting bean '" + beanName + "' of type [" + bean.getClass().getName() + "]");
            }
            try {
                // 调用bean的start方法
                bean.start();
            }
            catch (Throwable ex) {
                throw new ApplicationContextException("Failed to start bean '" + beanName + "'", ex);
            }
            if (logger.isDebugEnabled()) {
                logger.debug("Successfully started bean '" + beanName + "'");
            }
        }
    }
}
```

调用stop方法也是类似，只不过在SmartLifeCycle类型中有一个 Stop（Runnable runnable）类型的stop方法，而且使用了CountDownLatch来同步所有线程执行完成后，才真正退出。

看一下stop方法的调用：

```java
public void onClose() {
		stopBeans();
		this.running = false;
	}
```



```java
private void stopBeans() {
		// 获取所有Lifecycle类型的bean
		Map<String, Lifecycle> lifecycleBeans = getLifecycleBeans();
		Map<Integer, LifecycleGroup> phases = new HashMap<>();
		// 遍历所有的bean,并根据阶段的不同,进行分组; 把阶段相当的bean放到同一个组中
		lifecycleBeans.forEach((beanName, bean) -> {
			int shutdownPhase = getPhase(bean);
			LifecycleGroup group = phases.get(shutdownPhase);
			if (group == null) {
				group = new LifecycleGroup(shutdownPhase, this.timeoutPerShutdownPhase, lifecycleBeans, false);
				phases.put(shutdownPhase, group);
			}
            // 保存相同phase的bean
			group.add(beanName, bean);
		});
		// 调用bean的stop方法
		if (!phases.isEmpty()) {
			List<Integer> keys = new ArrayList<>(phases.keySet());
			keys.sort(Collections.reverseOrder());
			for (Integer key : keys) {
				phases.get(key).stop();
			}
		}
	}
```

```java
public void stop() {
    if (this.members.isEmpty()) {
        return;
    }
    if (logger.isDebugEnabled()) {
        logger.debug("Stopping beans in phase " + this.phase);
    }
    this.members.sort(Collections.reverseOrder());
    CountDownLatch latch = new CountDownLatch(this.smartMemberCount);
    Set<String> countDownBeanNames = Collections.synchronizedSet(new LinkedHashSet<>());
    Set<String> lifecycleBeanNames = new HashSet<>(this.lifecycleBeans.keySet());
    for (LifecycleGroupMember member : this.members) {
        if (lifecycleBeanNames.contains(member.name)) {
            // 1. 开始执行
            // 2. 先执行依赖的bean,之后再执行本bean
            doStop(this.lifecycleBeans, member.name, latch, countDownBeanNames);
        }
        else if (member.bean instanceof SmartLifecycle) {
            // Already removed: must have been a dependent bean from another phase
            // 直接countDown
            latch.countDown();
        }
    }
    try {
        // 等待所有的 SmartLifeCycle中public void stop(Runnable runnable)线程执行完成。
        // 这里的 等待超时  timeou,是DefaultLifecycleProcessor类的timeoutPerShutdownPhase 属性,默认是30s
        // 也就是说,是可以进行配置了;创建一个bean,设置其field,并注册到容器,嗯你懂得.
        latch.await(this.timeout, TimeUnit.MILLISECONDS);
        if (latch.getCount() > 0 && !countDownBeanNames.isEmpty() && logger.isInfoEnabled()) {
            logger.info("Failed to shut down " + countDownBeanNames.size() + " bean" +
                        (countDownBeanNames.size() > 1 ? "s" : "") + " with phase value " +
                        this.phase + " within timeout of " + this.timeout + ": " + countDownBeanNames);
        }
    }
    catch (InterruptedException ex) {
        Thread.currentThread().interrupt();
    }
}
}
```



```java
private void doStop(Map<String, ? extends Lifecycle> lifecycleBeans, final String beanName,
			final CountDownLatch latch, final Set<String> countDownBeanNames) {
    Lifecycle bean = lifecycleBeans.remove(beanName);
    if (bean != null) {
        // 获取此bean的依赖的bean
        String[] dependentBeans = getBeanFactory().getDependentBeans(beanName);
        // 先停止其依赖的bean
        for (String dependentBean : dependentBeans) {
            // 执行依赖的bean方法
            doStop(lifecycleBeans, dependentBean, latch, countDownBeanNames);
        }
        try {
            // 如果bean正在是正在运行,则执行
            if (bean.isRunning()) {
                // 如果bean是SmartLifecycle
                if (bean instanceof SmartLifecycle) {
                    if (logger.isTraceEnabled()) {
                        logger.trace("Asking bean '" + beanName + "' of type [" +
                                     bean.getClass().getName() + "] to stop");
                    }
                    // 记录已经运行的停止bean
                    countDownBeanNames.add(beanName);
                    // 运行停止的线程
                    ((SmartLifecycle) bean).stop(() -> {
                        latch.countDown();
                        countDownBeanNames.remove(beanName);
                        if (logger.isDebugEnabled()) {
                            logger.debug("Bean '" + beanName + "' completed its stop procedure");
                        }
                    });
                }
                else {
                    if (logger.isTraceEnabled()) {
                        logger.trace("Stopping bean '" + beanName + "' of type [" +
                                     bean.getClass().getName() + "]");
                    }
                    // 如果不是SmartLifecycle,则直接运行 stop方法
                    bean.stop();
                    if (logger.isDebugEnabled()) {
                        logger.debug("Successfully stopped bean '" + beanName + "'");
                    }
                }
            }
            else if (bean instanceof SmartLifecycle) {
                // Don't wait for beans that aren't running...
                // 如果bean已经不再运行了,直接countDown
                latch.countDown();
            }
        }
        catch (Throwable ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Failed to stop bean '" + beanName + "'", ex);
            }
        }
    }
}
```

注解感觉还是比较详细的，总体思路也很清晰。