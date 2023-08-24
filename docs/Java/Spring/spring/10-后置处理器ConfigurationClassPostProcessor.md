[TOC]

# ConfigurationClassPostProcessor 解析

本篇分析一个后置处理器ConfigurationClassPostProcessor 的作用.

先看一些其类图:

![](ConfigurationClassPostProcesso.png)

可以看到其是BeanFactoryPostProcessor的子类，以及是BeanDefinitionRegistryPostProcessor的子类。

BeanDefinitionRegistryPostProcessor子类的调用时机：



BeanFactoryPostProcessor子类的调用时机：

refresh --> invokeBeanFactoryPostProcessors

> org.springframework.context.support.AbstractApplicationContext#invokeBeanFactoryPostProcessors

```java
// 实例化并调用所有注册的 BeanFactoryPostProcessor 后置处理器
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    // 获取所有的BeanFactoryPostProcessor后置处理器
    // 并调用
    PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());

    // Detect a LoadTimeWeaver and prepare for weaving, if found in the meantime
    // (e.g. through an @Bean method registered by ConfigurationClassPostProcessor)
    if (beanFactory.getTempClassLoader() == null && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
}
```

```java
// 调用 beanFactoryPostProcessors
public static void invokeBeanFactoryPostProcessors(
    ConfigurableListableBeanFactory beanFactory, List<BeanFactoryPostProcessor> beanFactoryPostProcessors) {

    // Invoke BeanDefinitionRegistryPostProcessors first, if any.
    Set<String> processedBeans = new HashSet<>();

    if (beanFactory instanceof BeanDefinitionRegistry) {
        BeanDefinitionRegistry registry = (BeanDefinitionRegistry) beanFactory;
        List<BeanFactoryPostProcessor> regularPostProcessors = new ArrayList<>();
        List<BeanDefinitionRegistryPostProcessor> registryProcessors = new ArrayList<>();
        // 遍历所有的后置处理器,如果是BeanDefinitionRegistryPostProcessor后置处理器则调用
        // 并添加到registryProcessors
        for (BeanFactoryPostProcessor postProcessor : beanFactoryPostProcessors) {
            if (postProcessor instanceof BeanDefinitionRegistryPostProcessor) {
                BeanDefinitionRegistryPostProcessor registryProcessor =
                    (BeanDefinitionRegistryPostProcessor) postProcessor;
                // 此操作可以注册更多的beanDefinition到容器中
                // 具体的解析操作
                registryProcessor.postProcessBeanDefinitionRegistry(registry);
                registryProcessors.add(registryProcessor);
            }
            else {
                // regularPostProcessors 存储BeanFactoryPostProcessor
                regularPostProcessors.add(postProcessor);
            }
        }
        List<BeanDefinitionRegistryPostProcessor> currentRegistryProcessors = new ArrayList<>();

        // First, invoke the BeanDefinitionRegistryPostProcessors that implement PriorityOrdered.
        // 获取所有的BeanDefinitionRegistryPostProcessor的bean定义
        String[] postProcessorNames =
            beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        // 遍历获取到的后置处理器BeanDefinitionRegistryPostProcessor,如果实现了PriorityOrdered,则添加到currentRegistryProcessors
        for (String ppName : postProcessorNames) {
            if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        // 把获取到的实现了PriorityOrdered的BeanDefinitionRegistryPostProcessor进行排序操作
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        // 按顺序调用currentRegistryProcessors中的后置处理器
        // 调用 BeanDefinitionRegistryPostProcessor 后置处理器
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        // 调用完之后，清空
        currentRegistryProcessors.clear();

        // Next, invoke the BeanDefinitionRegistryPostProcessors that implement Ordered.
        // 再次获取所有的BeanDefinitionRegistryPostProcessor
        postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        // 遍历得到实现了Ordered接口的BeanDefinitionRegistryPostProcessors
        for (String ppName : postProcessorNames) {
            if (!processedBeans.contains(ppName) && beanFactory.isTypeMatch(ppName, Ordered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        // 对后置处理进行排序
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        // 调用排好序的后置处理器,调用完成后情况容器
        // 调用BeanDefinitionRegistryPostProcessor 后置处理器
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        currentRegistryProcessors.clear();

        // Finally, invoke all other BeanDefinitionRegistryPostProcessors until no further ones appear.
        boolean reiterate = true;
        while (reiterate) {
            // 获取上面两次都没有获取到的BeanDefinitionRegistryPostProcessor处理器
            reiterate = false;
            postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
            for (String ppName : postProcessorNames) {
                if (!processedBeans.contains(ppName)) {
                    currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                    processedBeans.add(ppName);
                    reiterate = true;
                }
            }
            // 同样是对处理器进行排序,添加到registryProcessors, 调用, 然后清空容器
            sortPostProcessors(currentRegistryProcessors, beanFactory);
            registryProcessors.addAll(currentRegistryProcessors);
            invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
            currentRegistryProcessors.clear();
        }

        // Now, invoke the postProcessBeanFactory callback of all processors handled so far.
        // 现在调用所有的BeanDefinitionRegistryPostProcessor.postProcessBeanFactory 方法,对ioc容器中的beanDefinition进行修改
        invokeBeanFactoryPostProcessors(registryProcessors, beanFactory);
        // regularPostProcessors 存储BeanFactoryPostProcessor
        // 这里调用BeanFactoryPostProcessor.postProcessBeanFactory
        invokeBeanFactoryPostProcessors(regularPostProcessors, beanFactory);
    }
    else {
        // Invoke factory processors registered with the context instance.
        invokeBeanFactoryPostProcessors(beanFactoryPostProcessors, beanFactory);
    }
```

这里所做的操作：

1. 调用BeanDefinitionRegistryPostProcessor.postProcessBeanDefinitionRegistry
2. 调用BeanDefinitionRegistryPostProcessor.postProcessBeanFactory
3. 调用BeanFactoryPostProcessor.postProcessBeanFactory

时间点：

```java
// ImportSelector.selectImports() 解析的点
org.springframework.context.annotation.ConfigurationClassParser#processImports
// // ImportSelector.selectImports() 调用的点,也就是把此 处理器返回的beanDefinition注入到 容器的点
org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#registerBeanDefinitionForImportedConfigurationClass
    
// ImportBeanDefinitionRegistrar  DeferredImportSelector 解析点:
org.springframework.context.annotation.ConfigurationClassParser#processImports

// ImportBeanDefinitionRegistrar 调用其注入操作的点
org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsFromRegistrars

// DeferredImportSelector处理点
org.springframework.context.annotation.ConfigurationClassParser#parse(java.util.Set<org.springframework.beans.factory.config.BeanDefinitionHolder>)
    
// @Bean注入到容器中的时间点
org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsForBeanMethod

//ImportResource 注入到容器中
org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsFromImportedResources
```



这里看一下此ConfigurationClassPostProcessor 处理器，在这里阶段所做的工作。

先看一下BeanDefinitionRegistryPostProcessor接口实现函数的工作:

> org.springframework.context.annotation.ConfigurationClassPostProcessor#postProcessBeanDefinitionRegistry

```java
// BeanDefinitionRegistry 其实就是bean容器
@Override
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
    // 生成一个唯一性 id, 防止重复解析
    int registryId = System.identityHashCode(registry);
    if (this.registriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
            "postProcessBeanDefinitionRegistry already called on this post-processor against " + registry);
    }
    // 记录一个新的 bean容器
    if (this.factoriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
            "postProcessBeanFactory already called on this post-processor against " + registry);
    }
    this.registriesPostProcessed.add(registryId);
    // 具体的解析操作
    // 重点
    processConfigBeanDefinitions(registry);
}
```

> org.springframework.context.annotation.ConfigurationClassPostProcessor#processConfigBeanDefinitions

```java
// 具体的对 Configuration 类的解析,并加载其 生成的beanDefinition 到容器中
public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
    List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
    // 获取所有的beanDefinition的name
    String[] candidateNames = registry.getBeanDefinitionNames();
    // 通过名字来获取其对应的beanDefinition, 通过对应的beanDefinition来判断是否是配置类
    for (String beanName : candidateNames) {
        // 获取beanDefinition
        BeanDefinition beanDef = registry.getBeanDefinition(beanName);
        //
        if (ConfigurationClassUtils.isFullConfigurationClass(beanDef) ||
            ConfigurationClassUtils.isLiteConfigurationClass(beanDef)) {
            if (logger.isDebugEnabled()) {
                logger.debug("Bean definition has already been processed as a configuration class: " + beanDef);
            }
        }
        // 判断是否是 配置类
        else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
            // 是配置类,则添加到 configCandidates中
            configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
        }
    }
    // Return immediately if no @Configuration classes were found
    // 没有配置类,那就不同继续分析了
    if (configCandidates.isEmpty()) {
        return;
    }
    // Sort by previously determined @Order value, if applicable
    // 排序
    configCandidates.sort((bd1, bd2) -> {
        int i1 = ConfigurationClassUtils.getOrder(bd1.getBeanDefinition());
        int i2 = ConfigurationClassUtils.getOrder(bd2.getBeanDefinition());
        return Integer.compare(i1, i2);
    });
    // Detect any custom bean name generation strategy supplied through the enclosing application context
    // 名字生成器
    SingletonBeanRegistry sbr = null;
    if (registry instanceof SingletonBeanRegistry) {
        sbr = (SingletonBeanRegistry) registry;
        if (!this.localBeanNameGeneratorSet) {
            BeanNameGenerator generator = (BeanNameGenerator) sbr.getSingleton(CONFIGURATION_BEAN_NAME_GENERATOR);
            if (generator != null) {
                this.componentScanBeanNameGenerator = generator;
                this.importBeanNameGenerator = generator;
            }
        }
    }
    // 是否有环境变量,如果没有则创建一个
    if (this.environment == null) {
        this.environment = new StandardEnvironment();
    }

    // Parse each @Configuration class
    // configuration 注解的解析类
    ConfigurationClassParser parser = new ConfigurationClassParser(
        this.metadataReaderFactory, this.problemReporter, this.environment,
        this.resourceLoader, this.componentScanBeanNameGenerator, registry);
    // 对等待分析的配置类去重
    Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
    Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
    do {
        // 解析
        // 重点
        parser.parse(candidates);
        // 校验
        parser.validate();
        // 获取刚解析到的配置类
        Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
        // 去除已经解析的
        configClasses.removeAll(alreadyParsed);

        // Read the model and create bean definitions based on its content
        if (this.reader == null) {
            this.reader = new ConfigurationClassBeanDefinitionReader(
                registry, this.sourceExtractor, this.resourceLoader, this.environment,
                this.importBeanNameGenerator, parser.getImportRegistry());
        }
        // 把配置类注册到容器
        // todo 注册动作
        // 1. 注入@Bean 到容器
        // 2. 注入Import 的beanDefinition 到容器
        // 3. 注入ImportSource 的beanDefinition 到容器
        // 4. 调用ImportBeanDefinitionRegistrar 的注入操作,来注入beanDefinition到容器中
        this.reader.loadBeanDefinitions(configClasses);
        // 记录注册类
        alreadyParsed.addAll(configClasses);
        // 注册完成后, 就清空候选类
        candidates.clear();
        if (registry.getBeanDefinitionCount() > candidateNames.length) {
            String[] newCandidateNames = registry.getBeanDefinitionNames();
            Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
            Set<String> alreadyParsedClasses = new HashSet<>();
            for (ConfigurationClass configurationClass : alreadyParsed) {
                alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
            }
            for (String candidateName : newCandidateNames) {
                if (!oldCandidateNames.contains(candidateName)) {
                    BeanDefinition bd = registry.getBeanDefinition(candidateName);
                    if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
                        !alreadyParsedClasses.contains(bd.getBeanClassName())) {
                        candidates.add(new BeanDefinitionHolder(bd, candidateName));
                    }
                }
            }
            candidateNames = newCandidateNames;
        }
    }
    while (!candidates.isEmpty());

    // Register the ImportRegistry as a bean in order to support ImportAware @Configuration classes
    if (sbr != null && !sbr.containsSingleton(IMPORT_REGISTRY_BEAN_NAME)) {
        sbr.registerSingleton(IMPORT_REGISTRY_BEAN_NAME, parser.getImportRegistry());
    }
    // 清空缓存
    if (this.metadataReaderFactory instanceof CachingMetadataReaderFactory) {
        // Clear cache in externally provided MetadataReaderFactory; this is a no-op
        // for a shared cache since it'll be cleared by the ApplicationContext.
        ((CachingMetadataReaderFactory) this.metadataReaderFactory).clearCache();
    }
}
```

代码比较长，小结一下此函数的工作：

1. 获取容器中所有的beanDefinition，记录其中的Configuration类
2. 对Configuration类排序
3. 记录名字生成器
4.  记录环境变量  environment
5. 创建ConfigurationClassParser 具体的解析类
6. 对类进行具体的解析操作
7. 把解析出的内容，转换为beanDefinition注入到容器中的操作

前面5步都是准备操作，这里咱们主要看一下解析操作，和注入操作。

## 解析操作

> org.springframework.context.annotation.ConfigurationClassParser#parse

```java
// 配置类 configuration注解 import  importResource component  componentScan的配置类
public void parse(Set<BeanDefinitionHolder> configCandidates) {
    for (BeanDefinitionHolder holder : configCandidates) {
        BeanDefinition bd = holder.getBeanDefinition();
        try {
            // 下面的三个 解析 都对都 import  importResource component  componentScan  Configuration
            // 以及 ImportBeanDefinitionRegistrar  DeferredImportSelector  ImportSelector.selectImports() 的解析
            if (bd instanceof AnnotatedBeanDefinition) {
                parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
            }
            else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
                parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
            }
            else {
                parse(bd.getBeanClassName(), holder.getBeanName());
            }
        }
        catch (BeanDefinitionStoreException ex) {
            throw ex;
        }
        catch (Throwable ex) {
            throw new BeanDefinitionStoreException(
                "Failed to parse configuration class [" + bd.getBeanClassName() + "]", ex);
        }
    }
    this.deferredImportSelectorHandler.process();
}
```

> org.springframework.context.annotation.ConfigurationClassParser#parse

```java
// 解析配置类,也就是configuration 注解的类
protected final void parse(AnnotationMetadata metadata, String beanName) throws IOException {
    processConfigurationClass(new ConfigurationClass(metadata, beanName));
}
```

> org.springframework.context.annotation.ConfigurationClassParser#processConfigurationClass

```java
// 解析配置类
protected void processConfigurationClass(ConfigurationClass configClass) throws IOException {
    // 根据Conditional 注解 判断是否需要跳过
    // 根据上面的 conditionOn 条件进行判断是否需要跳过
    if (this.conditionEvaluator.shouldSkip(configClass.getMetadata(), ConfigurationPhase.PARSE_CONFIGURATION)) {
        return;
    }
    // 查看是否已经处理过此配置类
    ConfigurationClass existingClass = this.configurationClasses.get(configClass);
    // 如果处理过
    if (existingClass != null) {
        // 新的配置类为 import的
        // isImported 表示是由 import 注解来注入的
        if (configClass.isImported()) {
            // 存在的也是 import
            if (existingClass.isImported()) {
                // 则进行合并
                existingClass.mergeImportedBy(configClass);
            }
            // Otherwise ignore new imported config class; existing non-imported class overrides it.
            return;
        }
        else {
            // Explicit bean definition found, probably replacing an import.
            // Let's remove the old one and go with the new one.
            this.configurationClasses.remove(configClass);
            this.knownSuperclasses.values().removeIf(configClass::equals);
        }
    }
    // Recursively process the configuration class and its superclass hierarchy.
    //  感觉这里是吧类的各个内容进行了解析
    // *****待 深入
    SourceClass sourceClass = asSourceClass(configClass);
    // 递归处理 配置类
    do {
        // 解析处理
        sourceClass = doProcessConfigurationClass(configClass, sourceClass);
    }
    while (sourceClass != null);
    //
    this.configurationClasses.put(configClass, configClass);
}
```

> org.springframework.context.annotation.ConfigurationClassParser#doProcessConfigurationClass

```java
// 对配置类的具体解析
@Nullable
protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
    throws IOException {
    // 如果是 component
    if (configClass.getMetadata().isAnnotated(Component.class.getName())) {
        // Recursively process any member (nested) classes first
        // 会递归处理器其内部的配置类
        processMemberClasses(configClass, sourceClass);
    }

    // Process any @PropertySource annotations
    // 处理propertySource注解
    for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
        sourceClass.getMetadata(), PropertySources.class,
        org.springframework.context.annotation.PropertySource.class)) {
        if (this.environment instanceof ConfigurableEnvironment) {
            // 解析source 并保存起来
            // 保存到 environment中
            processPropertySource(propertySource);
        }
        else {
            logger.info("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
                        "]. Reason: Environment must implement ConfigurableEnvironment");
        }
    }

    // Process any @ComponentScan annotations
    // 解析componentScans  componentScan
    Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
        sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
    if (!componentScans.isEmpty() &&
        !this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
        for (AnnotationAttributes componentScan : componentScans) {
            // The config class is annotated with @ComponentScan -> perform the scan immediately
            // 根据componentScan, 立即进行一些扫描, 并把beanDefinition注册到容器中
            // 也就是在此对 ComponentScans ComponentScan 表明的地址进行扫描
            // 并把对应地址上的bean解析为 beanDefinition
            Set<BeanDefinitionHolder> scannedBeanDefinitions =
                this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
            // Check the set of scanned definitions for any further config classes and parse recursively if needed
            for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
                BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
                if (bdCand == null) {
                    bdCand = holder.getBeanDefinition();
                }
                // 检测刚扫描的类,是否是 配置类; 如果也是配置类的话,也进行一次解析
                if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
                    // 解析操作
                    parse(bdCand.getBeanClassName(), holder.getBeanName());
                }
            }
        }
    }

    // Process any @Import annotations
    // 解析import注解
    // getImports  获取 import注解的 注入bean
    processImports(configClass, sourceClass, getImports(sourceClass), true);

    // Process any @ImportResource annotations
    AnnotationAttributes importResource =
        AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
    if (importResource != null) {
        String[] resources = importResource.getStringArray("locations");
        Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
        for (String resource : resources) {
            String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
            configClass.addImportedResource(resolvedResource, readerClass);
        }
    }

    // Process individual @Bean methods
    // 解析 @Bean
    Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
    for (MethodMetadata methodMetadata : beanMethods) {
        configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
    }

    // Process default methods on interfaces
    // 由此可见, 在Configuration 配置类中, @Bean 的注解也可以方法 实现的接口方法上 也可以
    // 重点  重点 特殊点
    // ***************** @Bean 放在接口函数上 也可以解析到 ****************
    processInterfaces(configClass, sourceClass);

    // Process superclass, if any
    // 处理 父类
    if (sourceClass.getMetadata().hasSuperClass()) {
        String superclass = sourceClass.getMetadata().getSuperClassName();
        if (superclass != null && !superclass.startsWith("java") &&
            !this.knownSuperclasses.containsKey(superclass)) {
            this.knownSuperclasses.put(superclass, configClass);
            // Superclass found, return its annotation metadata and recurse
            return sourceClass.getSuperClass();
        }
    }

    // No superclass -> processing is complete
    return null;
}
```

此函数对多种注解进行了分析，下面咱们按照不同注解的分析来进行。

### Component 解析

```java
// 如果是 component
if (configClass.getMetadata().isAnnotated(Component.class.getName())) {
    // Recursively process any member (nested) classes first
    // 会递归处理器其内部的配置类
    processMemberClasses(configClass, sourceClass);
}
```

> org.springframework.context.annotation.ConfigurationClassParser#processMemberClasses

```java
private void processMemberClasses(ConfigurationClass configClass, SourceClass sourceClass) throws IOException {
    // 获取内部类
    Collection<SourceClass> memberClasses = sourceClass.getMemberClasses();
    // 内部类存在
    if (!memberClasses.isEmpty()) {
        List<SourceClass> candidates = new ArrayList<>(memberClasses.size());
        // 遍历其内部类,并判断内部类是否是配置类,如果也是配置类,则保存起来,并进行处理
        for (SourceClass memberClass : memberClasses) {
            if (ConfigurationClassUtils.isConfigurationCandidate(memberClass.getMetadata()) &&
                !memberClass.getMetadata().getClassName().equals(configClass.getMetadata().getClassName())) {
                candidates.add(memberClass);
            }
        }
        OrderComparator.sort(candidates);
        // 递归遍历其内部类,并进行处理
        for (SourceClass candidate : candidates) {
            // 防止循环 处理
            if (this.importStack.contains(configClass)) {
                this.problemReporter.error(new CircularImportProblem(configClass, this.importStack));
            }
            else {
                this.importStack.push(configClass);
                try {
                    // 处理内部类
                    processConfigurationClass(candidate.asConfigClass(configClass));
                }
                finally {
                    this.importStack.pop();
                }
            }
        }
    }
}
```





### PropertySources解析

```java
// Process any @PropertySource annotations
// 处理propertySource注解
for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
    sourceClass.getMetadata(), PropertySources.class,
    org.springframework.context.annotation.PropertySource.class)) {
    if (this.environment instanceof ConfigurableEnvironment) {
        // 解析source 并保存起来
        // 保存到 environment中
        processPropertySource(propertySource);
    }
    else {
        logger.info("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
                    "]. Reason: Environment must implement ConfigurableEnvironment");
    }
}
```

> org.springframework.context.annotation.ConfigurationClassParser#processPropertySource

```java
// 最终是吧解析到的propertySource 放入到 环境environment中
private void processPropertySource(AnnotationAttributes propertySource) throws IOException {
    // 获取name 属性的值
    String name = propertySource.getString("name");
    if (!StringUtils.hasLength(name)) {
        name = null;
    }
    // 解析编码
    String encoding = propertySource.getString("encoding");
    if (!StringUtils.hasLength(encoding)) {
        encoding = null;
    }
    // 获取 source 的位置
    String[] locations = propertySource.getStringArray("value");
    Assert.isTrue(locations.length > 0, "At least one @PropertySource(value) location is required");
    boolean ignoreResourceNotFound = propertySource.getBoolean("ignoreResourceNotFound");
    // 属性 factory class
    Class<? extends PropertySourceFactory> factoryClass = propertySource.getClass("factory");
    //
    PropertySourceFactory factory = (factoryClass == PropertySourceFactory.class ?
                                     DEFAULT_PROPERTY_SOURCE_FACTORY : BeanUtils.instantiateClass(factoryClass));
    // 循环source的位置, 遍历资源
    for (String location : locations) {
        try {
            // 解析 占位符
            String resolvedLocation = this.environment.resolveRequiredPlaceholders(location);
            // 获取资源
            Resource resource = this.resourceLoader.getResource(resolvedLocation);
            addPropertySource(factory.createPropertySource(name, new EncodedResource(resource, encoding)));
        }
        catch (IllegalArgumentException | FileNotFoundException | UnknownHostException ex) {
            // Placeholders not resolvable or resource not found when trying to open it
            if (ignoreResourceNotFound) {
                if (logger.isInfoEnabled()) {
                    logger.info("Properties location [" + location + "] not resolvable: " + ex.getMessage());
                }
            }
            else {
                throw ex;
            }
        }
    }
}
```

> org.springframework.context.annotation.ConfigurationClassParser#addPropertySource

```java
// 添加 propertySource 注解添加的资源
private void addPropertySource(PropertySource<?> propertySource) {
    // 获取propertySource的name
    String name = propertySource.getName();
    // 从环境遍历中获取全部的 propertySource
    MutablePropertySources propertySources = ((ConfigurableEnvironment) this.environment).getPropertySources();
    // 查看已经处理的propertySource 是否包含此要添加的propertySource
    if (this.propertySourceNames.contains(name)) {
        // We've already added a version, we need to extend it
        PropertySource<?> existing = propertySources.get(name);
        if (existing != null) {
            PropertySource<?> newSource = (propertySource instanceof ResourcePropertySource ?
((ResourcePropertySource) propertySource).withResourceName() : propertySource);
            if (existing instanceof CompositePropertySource) {
                ((CompositePropertySource) existing).addFirstPropertySource(newSource);
            }
            else {
                if (existing instanceof ResourcePropertySource) {
                    existing = ((ResourcePropertySource) existing).withResourceName();
                }
                CompositePropertySource composite = new CompositePropertySource(name);
                // 已经存在的话 则组合一下
                composite.addPropertySource(newSource);
                composite.addPropertySource(existing);
                // 替换所有 propertySources中此name的value
                propertySources.replace(name, composite);
            }
            return;
        }
    }
    if (this.propertySourceNames.isEmpty()) {
        propertySources.addLast(propertySource);
    }
    else {
        String firstProcessed = this.propertySourceNames.get(this.propertySourceNames.size() - 1);
        propertySources.addBefore(firstProcessed, propertySource);
    }
    // 把加载的资源添加到 propertySourceNames
    this.propertySourceNames.add(name);
}
```



### ComponentScan 解析

```java
// Process any @ComponentScan annotations
// 解析componentScans  componentScan
Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
    sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
if (!componentScans.isEmpty() &&
    !this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
    for (AnnotationAttributes componentScan : componentScans) {
        // The config class is annotated with @ComponentScan -> perform the scan immediately
        // 根据componentScan, 立即进行一些扫描, 并把beanDefinition注册到容器中
        // 也就是在此对 ComponentScans ComponentScan 表明的地址进行扫描
        // 并把对应地址上的bean解析为 beanDefinition
        Set<BeanDefinitionHolder> scannedBeanDefinitions =
            this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName()); 
        for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
            BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
            if (bdCand == null) {
                bdCand = holder.getBeanDefinition();
            }
            // 检测刚扫描的类,是否是 配置类; 如果也是配置类的话,也进行一次解析
            if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
                // 解析操作
                parse(bdCand.getBeanClassName(), holder.getBeanName());
            }
        }
    }
}

```

> org.springframework.context.annotation.ComponentScanAnnotationParser#parse

```java
// 解析componentScan 路径上的组件
public Set<BeanDefinitionHolder> parse(AnnotationAttributes componentScan, final String declaringClass) {
    // ClassPathBeanDefinitionScanner 是具体的扫描实现
    // componentScan.getBoolean("useDefaultFilters") 获取注解的属性值,是否使用默认的过滤
    ClassPathBeanDefinitionScanner scanner = new ClassPathBeanDefinitionScanner(this.registry,
                                                                                componentScan.getBoolean("useDefaultFilters"), this.environment, this.resourceLoader);
    // 名字生成器
    // componentScan.getClass("nameGenerator") 获取注解中指定的名字生成器
    Class<? extends BeanNameGenerator> generatorClass = componentScan.getClass("nameGenerator");
    // 如果没有设置则使用默认的名字生成器
    boolean useInheritedGenerator = (BeanNameGenerator.class == generatorClass);
    scanner.setBeanNameGenerator(useInheritedGenerator ? this.beanNameGenerator :
                                 BeanUtils.instantiateClass(generatorClass));
    // scope mode
    // componentScan.getEnum("scopedProxy") 获取注解中 属性值
    ScopedProxyMode scopedProxyMode = componentScan.getEnum("scopedProxy");
    if (scopedProxyMode != ScopedProxyMode.DEFAULT) {
        scanner.setScopedProxyMode(scopedProxyMode);
    }
    else {
        // componentScan.getClass("scopeResolver") 获取属性值 解析scope
        Class<? extends ScopeMetadataResolver> resolverClass = componentScan.getClass("scopeResolver");
        scanner.setScopeMetadataResolver(BeanUtils.instantiateClass(resolverClass));
    }
    //componentScan.getString("resourcePattern") 获取属性值 得到资源的正则
    scanner.setResourcePattern(componentScan.getString("resourcePattern"));
    // 添加 includeFilter 过滤器
    // 获取属性中 componentScan.getAnnotationArray("includeFilters") 包含的过滤器
    for (AnnotationAttributes filter : componentScan.getAnnotationArray("includeFilters")) {
        for (TypeFilter typeFilter : typeFiltersFor(filter)) {
            scanner.addIncludeFilter(typeFilter);
        }
    }
    // 添加 excludeFilters 过滤器
    for (AnnotationAttributes filter : componentScan.getAnnotationArray("excludeFilters")) {
        for (TypeFilter typeFilter : typeFiltersFor(filter)) {
            scanner.addExcludeFilter(typeFilter);
        }
    }
    // 是否是  懒加载
    boolean lazyInit = componentScan.getBoolean("lazyInit");
    if (lazyInit) {
        scanner.getBeanDefinitionDefaults().setLazyInit(true);
    }
    // 获取要扫描的包
    Set<String> basePackages = new LinkedHashSet<>();
    String[] basePackagesArray = componentScan.getStringArray("basePackages");
    for (String pkg : basePackagesArray) {
        String[] tokenized = StringUtils.tokenizeToStringArray(this.environment.resolvePlaceholders(pkg),
                                                               ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS);
        Collections.addAll(basePackages, tokenized);
    }
    for (Class<?> clazz : componentScan.getClassArray("basePackageClasses")) {
        basePackages.add(ClassUtils.getPackageName(clazz));
    }
    if (basePackages.isEmpty()) {
        basePackages.add(ClassUtils.getPackageName(declaringClass));
    }
    scanner.addExcludeFilter(new AbstractTypeHierarchyTraversingFilter(false, false) {
        @Override
        protected boolean matchClassName(String className) {
            return declaringClass.equals(className);
        }
    });
    // 万事俱备, 开始扫描
    // 重点  重点  重点
    // 前面配置了过滤器 资源正则 等属性,现在开始扫描
    return scanner.doScan(StringUtils.toStringArray(basePackages));
}
```

> org.springframework.context.annotation.ClassPathBeanDefinitionScanner#doScan

```java
// 对指定路径上的bean进行解析,并把其解析为beanDefinition
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
    Assert.notEmpty(basePackages, "At least one base package must be specified");
    Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
    // 遍历这些 package路径 进行扫描
    for (String basePackage : basePackages) {
        // 从指定的路径下查找 候选的组件
        Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
        for (BeanDefinition candidate : candidates) {
            // 解析scope 数据
            ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
            // 设置此bean的scope
            candidate.setScope(scopeMetadata.getScopeName());
            // 生成名字
            String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
            if (candidate instanceof AbstractBeanDefinition) {
                // 设置beanDefinition的默认属性
                postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
            }
            if (candidate instanceof AnnotatedBeanDefinition) {
                // 对Lazy  Primary DependsOn Role  Description 属性的解析,并设置到beanDefinition中
                AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
            }
            // checkCandidate 检测是否已经注册
            if (checkCandidate(beanName, candidate)) {
                BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
                definitionHolder =
                    AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
                beanDefinitions.add(definitionHolder);
                // 注册beanDefinition到容器中
                // 重点 要点 
                registerBeanDefinition(definitionHolder, this.registry);
            }
        }
    }
    return beanDefinitions;
}

```

由此可见对于componentScan组件的扫描，其在扫描到之后，就会封装为BeanDefinition 注入到容器中。此不会延后处理。



### import解析

```java
// Process any @Import annotations
// 解析import注解
// getImports  获取 import注解的 注入bean
processImports(configClass, sourceClass, getImports(sourceClass), true);
```

> org.springframework.context.annotation.ConfigurationClassParser#getImports

```java
// 获取类上的 import注解 注入到容器中的 类
private Set<SourceClass> getImports(SourceClass sourceClass) throws IOException {
    Set<SourceClass> imports = new LinkedHashSet<>();
    Set<SourceClass> visited = new LinkedHashSet<>();
    // 收集 import 注解要注入到容器中的 类
    collectImports(sourceClass, imports, visited);
    // 返回 收集到 要注入的类
    return imports;
}
```

> org.springframework.context.annotation.ConfigurationClassParser#collectImports

```java
// 收集 import 注解要注入到容器中的 类
private void collectImports(SourceClass sourceClass, Set<SourceClass> imports, Set<SourceClass> visited)throws IOException {
    if (visited.add(sourceClass)) {
        for (SourceClass annotation : sourceClass.getAnnotations()) {
            String annName = annotation.getMetadata().getClassName();
            if (!annName.startsWith("java") && !annName.equals(Import.class.getName())) {
                collectImports(annotation, imports, visited);
            }
        }
        // 获取import 注解 要注入的类
        imports.addAll(sourceClass.getAnnotationAttributes(Import.class.getName(), "value"));
    }
}
```

> org.springframework.context.annotation.ConfigurationClassParser#processImports

```java
// 处理 import 注解,其要注入到容器中的bean
private void processImports(ConfigurationClass configClass, SourceClass currentSourceClass,
                            Collection<SourceClass> importCandidates, boolean checkForCircularImports) {
    // 如果没有要注入的类  则直接返回
    if (importCandidates.isEmpty()) {
        return;
    }
    // 检测  CircularImports
    if (checkForCircularImports && isChainedImportOnStack(configClass)) {
        this.problemReporter.error(new CircularImportProblem(configClass, this.importStack));
    }
    else {
        // 记录配置类
        this.importStack.push(configClass);
        try {
            for (SourceClass candidate : importCandidates) {
                if (candidate.isAssignable(ImportSelector.class)) {
                    // Candidate class is an ImportSelector -> delegate to it to determine imports
                    // 加载此配置类
                    Class<?> candidateClass = candidate.loadClass();
                    // 实例化
                    ImportSelector selector = BeanUtils.instantiateClass(candidateClass, ImportSelector.class);
                    // 调用aware方法;也就是注入需要的field
                    ParserStrategyUtils.invokeAwareMethods(
                        selector, this.environment, this.resourceLoader, this.registry);
                    if (selector instanceof DeferredImportSelector) {
                        this.deferredImportSelectorHandler.handle(
                            configClass, (DeferredImportSelector) selector);
                    }
                    else {
                        // 调用 ImportSelector.selectImports 获取到要注册的bean的 全类名
                        String[] importClassNames = selector.selectImports(currentSourceClass.getMetadata());
                        Collection<SourceClass> importSourceClasses = asSourceClasses(importClassNames);
                        // 递归处理,看要注入的类是否仍然是配置类
                        processImports(configClass, currentSourceClass, importSourceClasses, false);
                    }
                }
                else if (candidate.isAssignable(ImportBeanDefinitionRegistrar.class)) {
                    // Candidate class is an ImportBeanDefinitionRegistrar ->
                    // delegate to it to register additional bean definitions
                    Class<?> candidateClass = candidate.loadClass();
                    ImportBeanDefinitionRegistrar registrar =
                        BeanUtils.instantiateClass(candidateClass, ImportBeanDefinitionRegistrar.class);
                    ParserStrategyUtils.invokeAwareMethods(
                        registrar, this.environment, this.resourceLoader, this.registry);
                    // 把此 ImportBeanDefinitionRegistrar 保存起来
                    configClass.addImportBeanDefinitionRegistrar(registrar, currentSourceClass.getMetadata());
                }
                else {
                    // Candidate class not an ImportSelector or ImportBeanDefinitionRegistrar ->
                    // process it as an @Configuration class
                    this.importStack.registerImport(
                        currentSourceClass.getMetadata(), candidate.getMetadata().getClassName());
                    processConfigurationClass(candidate.asConfigClass(configClass));
                }
            }
        }
        catch (BeanDefinitionStoreException ex) {
            throw ex;
        }
        catch (Throwable ex) {
            throw new BeanDefinitionStoreException(
                "Failed to process import candidates for configuration class [" +
                configClass.getMetadata().getClassName() + "]", ex);
        }
        finally {
            this.importStack.pop();
        }
    }
}
```

由此可见对于Import处理分为几种情况:

1. 导入的是ImportSelector类型的，则获取其要注入的类； 
   1. 如果类是DeferredImportSelector，则记录到 deferredImportSelectors中
   2. 如果不是，则继续进行processImports处理，看起是否让然有import操作
2. 导入的类是ImportBeanDefinitionRegistrar类型的，那么就保存起来
3. 否则作为Configuration类，继续进行处理

### ImportResource解析

```java
// Process any @ImportResource annotations
AnnotationAttributes importResource =
    AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
if (importResource != null) {
    String[] resources = importResource.getStringArray("locations");
    Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
    for (String resource : resources) {
        // 解析占位符
        String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
        // 记录 ImportResource的资源
        configClass.addImportedResource(resolvedResource, readerClass);
    }
}
```

此处就是记录下来，没有做进一步的处理。



### Bean 解析

```java
// Process individual @Bean methods
// 解析 @Bean
Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
for (MethodMetadata methodMetadata : beanMethods) {
    // 记录下来所有的 带有 @Bean注解的 method
    configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
}

// Process default methods on interfaces
// 由此可见, 在Configuration 配置类中, @Bean 的注解也可以方法 实现的接口方法上 也可以
// 重点  重点 特殊点
// ***************** @Bean 放在接口函数上 也可以解析到 ****************
processInterfaces(configClass, sourceClass);
```

> org.springframework.context.annotation.ConfigurationClassParser#retrieveBeanMethodMetadata

```java
// 获取一个类中带有 @Bean注解的 method
private Set<MethodMetadata> retrieveBeanMethodMetadata(SourceClass sourceClass) {
    // 获取 类的 源信息,其中包括了注解
    AnnotationMetadata original = sourceClass.getMetadata();
    // 获取带有 @Bean 注解的方法
    Set<MethodMetadata> beanMethods = original.getAnnotatedMethods(Bean.class.getName());
    if (beanMethods.size() > 1 && original instanceof StandardAnnotationMetadata) {
        // Try reading the class file via ASM for deterministic declaration order...
        // Unfortunately, the JVM's standard reflection returns methods in arbitrary
        // order, even between different runs of the same application on the same JVM.
        try {
            AnnotationMetadata asm =                this.metadataReaderFactory.getMetadataReader(original.getClassName()).getAnnotationMetadata();
            // 通过asm 获取 带有@Bean注解的method
            Set<MethodMetadata> asmMethods = asm.getAnnotatedMethods(Bean.class.getName());
            // 这里的操作,就是保留下 class 原有的 带有@Bean注解的method
            if (asmMethods.size() >= beanMethods.size()) {
                Set<MethodMetadata> selectedMethods = new LinkedHashSet<>(asmMethods.size());
                for (MethodMetadata asmMethod : asmMethods) {
                    for (MethodMetadata beanMethod : beanMethods) {
                        if (beanMethod.getMethodName().equals(asmMethod.getMethodName())) {
                            selectedMethods.add(beanMethod);
                            break;
                        }
                    }
                }
                // 记录下带有@Bean 的method
                if (selectedMethods.size() == beanMethods.size()) {
                    // All reflection-detected methods found in ASM method set -> proceed
                    beanMethods = selectedMethods;
                }
            }
        }
        catch (IOException ex) {
            logger.debug("Failed to read class file via ASM for determining @Bean method order", ex);
            // No worries, let's continue with the reflection metadata we started with...
        }
    }
    return beanMethods;
}
```

可以看到此处同样是记录下来@Bean method.

> org.springframework.context.annotation.ConfigurationClassParser#processInterfaces

```java
// 由此可见, 在Configuration 配置类中, @Bean 的注解也可以方法 实现的接口方法上 也可以
private void processInterfaces(ConfigurationClass configClass, SourceClass sourceClass) throws IOException {
    // 遍历配置类上的所有接口
    for (SourceClass ifc : sourceClass.getInterfaces()) {
        // 获取接口上 所有的 带有@Bean 注解的方法
        Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(ifc);
        // 遍历所有的 带@Bean 方法
        for (MethodMetadata methodMetadata : beanMethods) {
            if (!methodMetadata.isAbstract()) {
                // A default method or other concrete method on a Java 8+ interface...
                // 记录带有@Bean注解的 方法
                configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
            }
        }
        // 再处理接口的接口 上的注解信息
        // 递归 一直处理
        processInterfaces(configClass, ifc);
    }
}
```



## 注入操作

```java
// 把配置类注册到容器
// todo 注册动作
// 1. 注入@Bean 到容器
// 2. 注入Import 的beanDefinition 到容器
// 3. 注入ImportSource 的beanDefinition 到容器
// 4. 调用ImportBeanDefinitionRegistrar 的注入操作,来注入beanDefinition到容器中
this.reader.loadBeanDefinitions(configClasses);
```

> org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitions

```java
// 开始把 Configuration中解析出来 的 @Bean注解的bean 加载到容器中
// 在此操作中会把  Import  ImportResource @Bean 会注入到容器中
// ImportBeanDefinitionRegistrar 调用其注入操作, 调用其实现类 来注入具体的其他的beanDefinition
public void loadBeanDefinitions(Set<ConfigurationClass> configurationModel) {
    TrackedConditionEvaluator trackedConditionEvaluator = new TrackedConditionEvaluator();
    for (ConfigurationClass configClass : configurationModel) {
        loadBeanDefinitionsForConfigurationClass(configClass, trackedConditionEvaluator);
    }
}

```



```java
// 从解析出来的Configuration中加载beanDefinition到容器中
private void loadBeanDefinitionsForConfigurationClass(
    ConfigurationClass configClass, TrackedConditionEvaluator trackedConditionEvaluator) {

    if (trackedConditionEvaluator.shouldSkip(configClass)) {
        String beanName = configClass.getBeanName();
        if (StringUtils.hasLength(beanName) && this.registry.containsBeanDefinition(beanName)) {
            this.registry.removeBeanDefinition(beanName);
        }
        this.importRegistry.removeImportingClass(configClass.getMetadata().getClassName());
        return;
    }
    // 注册import 的类
    if (configClass.isImported()) {
        registerBeanDefinitionForImportedConfigurationClass(configClass);
    }
    // 注册 @bean
    for (BeanMethod beanMethod : configClass.getBeanMethods()) {
        loadBeanDefinitionsForBeanMethod(beanMethod);
    }
    // 注册 ImportResource
    loadBeanDefinitionsFromImportedResources(configClass.getImportedResources());
    // 通过 import注册的bean
    // 通过遍历调用其registerBeanDefinitions 方法来实现具体的注册动作
    // ImportBeanDefinitionRegistrar的注入操作
    loadBeanDefinitionsFromRegistrars(configClass.getImportBeanDefinitionRegistrars());
}
```

此函数也是针对不同的注解，来进行注入，下面咱们也按照不同的注入类型，来进行分析。

#### import注入

```java
// 注册import 的类
if (configClass.isImported()) {
    registerBeanDefinitionForImportedConfigurationClass(configClass);
}
```

> org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#registerBeanDefinitionForImportedConfigurationClass

```java
// 把 import 注解注入的bean 加载到 容器中
private void registerBeanDefinitionForImportedConfigurationClass(ConfigurationClass configClass) {
    AnnotationMetadata metadata = configClass.getMetadata();
    AnnotatedGenericBeanDefinition configBeanDef = new AnnotatedGenericBeanDefinition(metadata);

    ScopeMetadata scopeMetadata = scopeMetadataResolver.resolveScopeMetadata(configBeanDef);
    configBeanDef.setScope(scopeMetadata.getScopeName());
    String configBeanName = this.importBeanNameGenerator.generateBeanName(configBeanDef, this.registry);
    // Lazy  primary dependOn description 注解
    AnnotationConfigUtils.processCommonDefinitionAnnotations(configBeanDef, metadata);

    BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(configBeanDef, configBeanName);
    definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
    // 注册
    // 加载到容器中
    this.registry.registerBeanDefinition(definitionHolder.getBeanName(), definitionHolder.getBeanDefinition());
    configClass.setBeanName(configBeanName);

    if (logger.isTraceEnabled()) {
        logger.trace("Registered bean definition for imported class '" + configBeanName + "'");
    }
}
```





#### Bean注入

```java
// 注册 @bean
for (BeanMethod beanMethod : configClass.getBeanMethods()) {
    loadBeanDefinitionsForBeanMethod(beanMethod);
}
```

> org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsForBeanMethod

```java
// 把@Bean 注解类型的beanDefinition 加载到容器中
@SuppressWarnings("deprecation")  // for RequiredAnnotationBeanPostProcessor.SKIP_REQUIRED_CHECK_ATTRIBUTE
private void loadBeanDefinitionsForBeanMethod(BeanMethod beanMethod) {
    ConfigurationClass configClass = beanMethod.getConfigurationClass();
    MethodMetadata metadata = beanMethod.getMetadata();
    String methodName = metadata.getMethodName();

    // Do we need to mark the bean as skipped by its condition?
    // 是否需要跳过
    if (this.conditionEvaluator.shouldSkip(metadata, ConfigurationPhase.REGISTER_BEAN)) {
        configClass.skippedBeanMethods.add(methodName);
        return;
    }
    if (configClass.skippedBeanMethods.contains(methodName)) {
        return;
    }
    // 获取 @Bean注解的属性值
    AnnotationAttributes bean = AnnotationConfigUtils.attributesFor(metadata, Bean.class);
    Assert.state(bean != null, "No @Bean annotation attributes");

    // Consider name and any aliases
    // 获取beanName
    List<String> names = new ArrayList<>(Arrays.asList(bean.getStringArray("name")));
    String beanName = (!names.isEmpty() ? names.remove(0) : methodName);

    // Register aliases even when overridden
    // 为此bean注册别名
    for (String alias : names) {
        this.registry.registerAlias(beanName, alias);
    }

    // Has this effectively been overridden before (e.g. via XML)?
    if (isOverriddenByExistingDefinition(beanMethod, beanName)) {
        if (beanName.equals(beanMethod.getConfigurationClass().getBeanName())) {
            throw new BeanDefinitionStoreException(beanMethod.getConfigurationClass().getResource().getDescription(),
                                                   beanName, "Bean name derived from @Bean method '" + beanMethod.getMetadata().getMethodName() +
                                                   "' clashes with bean name for containing configuration class; please make those names unique!");
        }
        return;
    }
    // 创建 beanDefinition
    ConfigurationClassBeanDefinition beanDef = new ConfigurationClassBeanDefinition(configClass, metadata);
    beanDef.setResource(configClass.getResource());
    beanDef.setSource(this.sourceExtractor.extractSource(metadata, configClass.getResource()));
    // 根据此方法是否是静态的来标注一些标志
    if (metadata.isStatic()) {
        // static @Bean method
        beanDef.setBeanClassName(configClass.getMetadata().getClassName());
        beanDef.setFactoryMethodName(methodName);
    }
    else {
        // instance @Bean method
        beanDef.setFactoryBeanName(configClass.getBeanName());
        beanDef.setUniqueFactoryMethodName(methodName);
    }
    // 自动注入模式 按照 构造器注入
    beanDef.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_CONSTRUCTOR);
    // 设置属性
    beanDef.setAttribute(org.springframework.beans.factory.annotation.RequiredAnnotationBeanPostProcessor.
                         SKIP_REQUIRED_CHECK_ATTRIBUTE, Boolean.TRUE);
    // 一般注解的处理
    // lazy  primary  dependOn  role  Description 注解
    AnnotationConfigUtils.processCommonDefinitionAnnotations(beanDef, metadata);
    // 也可以指定自动注入的模式
    Autowire autowire = bean.getEnum("autowire");
    if (autowire.isAutowire()) {
        beanDef.setAutowireMode(autowire.value());
    }

    boolean autowireCandidate = bean.getBoolean("autowireCandidate");
    if (!autowireCandidate) {
        beanDef.setAutowireCandidate(false);
    }
    // 获取 initMethod 也就是初始化方法
    String initMethodName = bean.getString("initMethod");
    if (StringUtils.hasText(initMethodName)) {
        beanDef.setInitMethodName(initMethodName);
    }
    // 获取销毁方法
    String destroyMethodName = bean.getString("destroyMethod");
    beanDef.setDestroyMethodName(destroyMethodName);

    // Consider scoping
    // 设置此bean的scope
    ScopedProxyMode proxyMode = ScopedProxyMode.NO;
    AnnotationAttributes attributes = AnnotationConfigUtils.attributesFor(metadata, Scope.class);
    if (attributes != null) {
        beanDef.setScope(attributes.getString("value"));
        proxyMode = attributes.getEnum("proxyMode");
        if (proxyMode == ScopedProxyMode.DEFAULT) {
            proxyMode = ScopedProxyMode.NO;
        }
    }

    // Replace the original bean definition with the target one, if necessary
    BeanDefinition beanDefToRegister = beanDef;
    if (proxyMode != ScopedProxyMode.NO) {
        BeanDefinitionHolder proxyDef = ScopedProxyCreator.createScopedProxy(
            new BeanDefinitionHolder(beanDef, beanName), this.registry,
            proxyMode == ScopedProxyMode.TARGET_CLASS);
        beanDefToRegister = new ConfigurationClassBeanDefinition(
            (RootBeanDefinition) proxyDef.getBeanDefinition(), configClass, metadata);
    }

    if (logger.isTraceEnabled()) {
        logger.trace(String.format("Registering bean definition for @Bean method %s.%s()",
                                   configClass.getMetadata().getClassName(), beanName));
    }
    // 加载到容器中
    // 创建好
    this.registry.registerBeanDefinition(beanName, beanDefToRegister);
}
```



#### ImportSource注入

```java
// 注册 ImportResource
loadBeanDefinitionsFromImportedResources(configClass.getImportedResources());
```

> org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsFromImportedResources

```java
private void loadBeanDefinitionsFromImportedResources(
    Map<String, Class<? extends BeanDefinitionReader>> importedResources) {

    Map<Class<?>, BeanDefinitionReader> readerInstanceCache = new HashMap<>();

    importedResources.forEach((resource, readerClass) -> {
        // Default reader selection necessary?
        if (BeanDefinitionReader.class == readerClass) {
            if (StringUtils.endsWithIgnoreCase(resource, ".groovy")) {
                // When clearly asking for Groovy, that's what they'll get...
                readerClass = GroovyBeanDefinitionReader.class;
            }
            else {
                // Primarily ".xml" files but for any other extension as well
                readerClass = XmlBeanDefinitionReader.class;
            }
        }

        BeanDefinitionReader reader = readerInstanceCache.get(readerClass);
        if (reader == null) {
            try {
                // Instantiate the specified BeanDefinitionReader
                reader = readerClass.getConstructor(BeanDefinitionRegistry.class).newInstance(this.registry);
                // Delegate the current ResourceLoader to it if possible
                if (reader instanceof AbstractBeanDefinitionReader) {
                    AbstractBeanDefinitionReader abdr = ((AbstractBeanDefinitionReader) reader);
                    abdr.setResourceLoader(this.resourceLoader);
                    abdr.setEnvironment(this.environment);
                }
                readerInstanceCache.put(readerClass, reader);
            }
            catch (Throwable ex) {
                throw new IllegalStateException(
                    "Could not instantiate BeanDefinitionReader class [" + readerClass.getName() + "]");
            }
        }

        // TODO SPR-6310: qualify relative path locations as done in AbstractContextLoader.modifyLocations
        reader.loadBeanDefinitions(resource);
    });
}
```





#### ImportBeanDefinitionRegistrar注入

```java
// 通过 import注册的bean
// 通过遍历调用其registerBeanDefinitions 方法来实现具体的注册动作
// ImportBeanDefinitionRegistrar的注入操作
loadBeanDefinitionsFromRegistrars(configClass.getImportBeanDefinitionRegistrars());
```

> org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsFromRegistrars

```java
// ImportBeanDefinitionRegistrar 注入的操作
private void loadBeanDefinitionsFromRegistrars(Map<ImportBeanDefinitionRegistrar, AnnotationMetadata> registrars) {
    registrars.forEach((registrar, metadata) ->
                       registrar.registerBeanDefinitions(metadata, this.registry));
}

```

到此，此后置处理器就分析完了。可见真的是功能强大。







































































