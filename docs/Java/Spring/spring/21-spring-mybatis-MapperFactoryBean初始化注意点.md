[TOC]

# MapperFactoryBean初始化的点

通过上面的分析了解到每一个mapper接口其实都是初始化的MapperFactoryBean类，经过解析可以知道其指定了需要注入的参数为addToConfig。

这里就由一个问题，sqlSessionTemplate是什么时候创建的，大家都可能SqlSessionDaoSupport#setSqlSessionFactory中创建的，那么这个setSqlSessionFactory是什么调用的呢？

大家可能会说自动注入的时候，没有错，确实是在自动注入的时候做的，本篇就来分析一下此自动注入的时间点。

> org.mybatis.spring.support.SqlSessionDaoSupport#setSqlSessionFactory

```java
public void setSqlSessionFactory(SqlSessionFactory sqlSessionFactory) {
    if (this.sqlSessionTemplate == null || sqlSessionFactory != this.sqlSessionTemplate.getSqlSessionFactory()) {
        // 创建sqlSessionTemplate
        this.sqlSessionTemplate = createSqlSessionTemplate(sqlSessionFactory);
    }
}
```

可以看到，确实是在注入sqlSessionFactory属性时创建的。

> org.mybatis.spring.mapper.ClassPathMapperScanner#processBeanDefinitions

```java
// 如果没有具体制定  sqlSessionFactory,那么设置自动注入模式为 按照类型注入
      if (!explicitFactoryUsed) {
        LOGGER.debug(() -> "Enabling autowire by type for MapperFactoryBean with name '" + holder.getBeanName() + "'.");
        definition.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
      }
```

在前面初始化时，如果没有指定SqlSessionFactory，那么就指定注入的模式为按照类型注入。

咱们看一下自动注入bean属性时的操作

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#populateBean

```java
// 这里只是截取函数的部分
// 通过名字  或者 类型进行属性注入
if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_NAME || mbd.getResolvedAutowireMode() == AUTOWIRE_BY_TYPE) {
    // 存储要注入的属性 及其 value
    MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
    // Add property values based on autowire by name if applicable.
    // 根据 名字来进行注入的操作
    // 在这里也就是  根据名字取获取要注入的值
    if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_NAME) {
        autowireByName(beanName, mbd, bw, newPvs);
    }
    // Add property values based on autowire by type if applicable.
    // 根据类型来进行注入
    // 也就是根据类型来获取要注入的 value
    // 此处的点在这里, 按照类型注入
    if (mbd.getResolvedAutowireMode() == AUTOWIRE_BY_TYPE) {
        // 注入模式是 按照类型注入时, 获取要注入的属性
        autowireByType(beanName, mbd, bw, newPvs);
    }
    pvs = newPvs;
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#autowireByType

```java
// 根据类型进行属性的注入
protected void autowireByType(
    String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {
    // 获取类型转换器
    TypeConverter converter = getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }
    // 待注入的beanName
    Set<String> autowiredBeanNames = new LinkedHashSet<>(4);
    // 获取所有需要注入的属性
    // 重点在这里 unsatisfiedNonSimpleProperties, 获取要进行注入操作的属性
    String[] propertyNames = unsatisfiedNonSimpleProperties(mbd, bw);
    // 遍历所有需要注入的 property, 去容器中获取值
    for (String propertyName : propertyNames) {
        try {
            PropertyDescriptor pd = bw.getPropertyDescriptor(propertyName);
            // Don't try autowiring by type for type Object: never makes sense,
            // even if it technically is a unsatisfied, non-simple property.
            if (Object.class != pd.getPropertyType()) {
                MethodParameter methodParam = BeanUtils.getWriteMethodParameter(pd);
                // Do not allow eager init for type matching in case of a prioritized post-processor.
                boolean eager = !PriorityOrdered.class.isInstance(bw.getWrappedInstance());
                DependencyDescriptor desc = new AutowireByTypeDependencyDescriptor(methodParam, eager);
                // 解析依赖
                Object autowiredArgument = resolveDependency(desc, beanName, autowiredBeanNames, converter);
                if (autowiredArgument != null) {
                    // 记录property 及其 value
                    pvs.add(propertyName, autowiredArgument);
                }
                for (String autowiredBeanName : autowiredBeanNames) {
                    // 注册此bean依赖的其他bean
                    registerDependentBean(autowiredBeanName, beanName);
                    if (logger.isTraceEnabled()) {
                        logger.trace("Autowiring by type from bean name '" + beanName + "' via property '" + propertyName + "' to bean named '" + autowiredBeanName + "'");
                    }
                }
                autowiredBeanNames.clear();
            }
        }
        catch (BeansException ex) {
            throw new UnsatisfiedDependencyException(mbd.getResourceDescription(), beanName, propertyName, ex);
        }
    }
}
```

> org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#unsatisfiedNonSimpleProperties

```java
// 获取需要注入的属性，把基本类型的属性排除在外
protected String[] unsatisfiedNonSimpleProperties(AbstractBeanDefinition mbd, BeanWrapper bw) {
    Set<String> result = new TreeSet<>();
    PropertyValues pvs = mbd.getPropertyValues();
    // 此会获取所有的 bw代表的bean的所有 propertyDescriptors
    PropertyDescriptor[] pds = bw.getPropertyDescriptors();
    // 遍历所有 property,获取需要注入的property
    // 根据条件判断,什么情况下一个peoperty需要进行注入
    for (PropertyDescriptor pd : pds) {
        // 1. 首先由 set方法
        // 2. 没有 依赖的排除名单中
        // 3. pvs设置的要注入的属性中 不包含
        // 4. 不是基本类型
        if (pd.getWriteMethod() != null && !isExcludedFromDependencyCheck(pd) && !pvs.contains(pd.getName()) &&
            !BeanUtils.isSimpleProperty(pd.getPropertyType())) {
            result.add(pd.getName());
        }
    }
    return StringUtils.toStringArray(result);
}
```

看一下debug图:

![](autowiredSqlSeessionFactory.png)

通过此操作后，就知道了SqlSessionFactory属性需要注入，具体的value呢，会从容器中获取；还记得mybaits那个javaBean的配置把，其中就创建了SqlSessionFactory，之后就会进行具体的注入操作，顺便就创建了 sqlSessionTemplate。

javaBean配置

```java
// sqlsessionfactory
@Bean("sqlSessionFactory")
public SqlSessionFactory sqlSessionFactory() throws Exception {
    PathMatchingResourcePatternResolver patternResolver = new PathMatchingResourcePatternResolver();
    SqlSessionFactoryBean sessionFactoryBean = new SqlSessionFactoryBean();
    sessionFactoryBean.setDataSource(dataSource());
    sessionFactoryBean.setMapperLocations(patternResolver.getResources(MapperLocation));
    return sessionFactoryBean.getObject();
}
```



















































