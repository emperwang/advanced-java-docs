[TOC]

# MyBatis的SqlSession分析

本篇咱们看一下mybatis自身的sqlSession为什么不是线程安全的，那为什么和spring整合后，就变成了线程安全的？

先以一个示例看一下mybatis自身的使用：

```java
public class SqlSessionNoThreadSafe {
	private static SqlSessionFactory sessionFactory;
	private static SqlSession sqlSession;
	static {
		try {
			Reader reader = Resources.getResourceAsReader("MyBatis-config.xml");
			sessionFactory = new SqlSessionFactoryBuilder().build(reader);
			sqlSession = sessionFactory.openSession();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}


	public void multiThreadExec(){
		UserMapper mapper = sqlSession.getMapper(UserMapper.class);
		int count = 10;
		CountDownLatch latch = new CountDownLatch(10);
		for (int i=0; i < count; i++){
			new Thread(() -> {
				try {
					latch.await();
					List<User> users = mapper.selectAll();
					System.out.println("current-thread: "+ Thread.currentThread().getName()+", " +
							"res="+users.toString());
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}).start();
			latch.countDown();
		}
	}
}
```

```java
public class Starter {
	public static void main(String[] args) {
		SqlSessionNoThreadSafe noThreadSafe = new SqlSessionNoThreadSafe();
		noThreadSafe.multiThreadExec();
	}
}
```

报错：

```java
Exception in thread "Thread-8" Exception in thread "Thread-5" org.apache.ibatis.exceptions.PersistenceException: 
### Error querying database.  Cause: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
### The error may exist in UserMapper.xml
### The error may involve com.wk.basedemo.UserMapper.selectAll
### The error occurred while executing a query
### Cause: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
	at org.apache.ibatis.exceptions.ExceptionFactory.wrapException(ExceptionFactory.java:30)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:152)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:141)
	at org.apache.ibatis.binding.MapperMethod.executeForMany(MapperMethod.java:170)
	at org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:95)
	at org.apache.ibatis.binding.MapperProxy$PlainMethodInvoker.invoke(MapperProxy.java:157)
	at org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:94)
	at com.sun.proxy.$Proxy0.selectAll(Unknown Source)
	at com.wk.basedemo.SqlSessionMuliExec.SqlSessionNoThreadSafe.lambda$multiThreadExec$0(SqlSessionNoThreadSafe.java:37)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
	at org.apache.ibatis.executor.BaseExecutor.query(BaseExecutor.java:153)
	at org.apache.ibatis.executor.CachingExecutor.query(CachingExecutor.java:119)
	at org.apache.ibatis.executor.CachingExecutor.query(CachingExecutor.java:91)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:150)
	... 8 more
org.apache.ibatis.exceptions.PersistenceException: 
### Error querying database.  Cause: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
### The error may exist in UserMapper.xml
### The error may involve com.wk.basedemo.UserMapper.selectAll
### The error occurred while executing a query
### Cause: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
	at org.apache.ibatis.exceptions.ExceptionFactory.wrapException(ExceptionFactory.java:30)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:152)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:141)
	at org.apache.ibatis.binding.MapperMethod.executeForMany(MapperMethod.java:170)
	at org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:95)
	at org.apache.ibatis.binding.MapperProxy$PlainMethodInvoker.invoke(MapperProxy.java:157)
	at org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:94)
	at com.sun.proxy.$Proxy0.selectAll(Unknown Source)
	at com.wk.basedemo.SqlSessionMuliExec.SqlSessionNoThreadSafe.lambda$multiThreadExec$0(SqlSessionNoThreadSafe.java:37)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.ClassCastException: org.apache.ibatis.executor.ExecutionPlaceholder cannot be cast to java.util.List
	at org.apache.ibatis.executor.BaseExecutor.query(BaseExecutor.java:153)
	at org.apache.ibatis.executor.CachingExecutor.query(CachingExecutor.java:119)
	at org.apache.ibatis.executor.CachingExecutor.query(CachingExecutor.java:91)
	at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:150)
	... 8 more
```

多个线程使用同一个SqlSession执行时，就报错了。这里就以出错的点入手，看一下其为什么不是线程安全的：

> org.apache.ibatis.session.defaults.DefaultSqlSession#selectList(java.lang.String)

```java
@Override
public <E> List<E> selectList(String statement) {
    return this.selectList(statement, null);
}

@Override
public <E> List<E> selectList(String statement, Object parameter) {
    return this.selectList(statement, parameter, RowBounds.DEFAULT);
}

@Override
public <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds) {
    try {
        // 获取方法对应的statement
        MappedStatement ms = configuration.getMappedStatement(statement);
        // 使用执行器进行具体的sql的执行
        return executor.query(ms, wrapCollection(parameter), rowBounds, Executor.NO_RESULT_HANDLER);
    } catch (Exception e) {
        throw ExceptionFactory.wrapException("Error querying database.  Cause: " + e, e);
    } finally {
        ErrorContext.instance().reset();
    }
}
```

> org.apache.ibatis.executor.BaseExecutor#query

```java
	// 查询操作
  @Override
  public <E> List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler) throws SQLException {
    BoundSql boundSql = ms.getBoundSql(parameter);
    // 创建缓存的key
    CacheKey key = createCacheKey(ms, parameter, rowBounds, boundSql);
    // 查询操作
    return query(ms, parameter, rowBounds, resultHandler, key, boundSql);
  }


  @SuppressWarnings("unchecked")
  @Override
  public <E> List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey key, BoundSql boundSql) throws SQLException {
    ErrorContext.instance().resource(ms.getResource()).activity("executing a query").object(ms.getId());
    if (closed) {
      throw new ExecutorException("Executor was closed.");
    }
    if (queryStack == 0 && ms.isFlushCacheRequired()) {
    	// 清空缓存的操作
      clearLocalCache();
    }
    List<E> list;
    try {
      queryStack++;
      // 从一级缓存中查询
      list = resultHandler == null ? (List<E>) localCache.getObject(key) : null;
      // 如果一级缓存存在,则处理
        //从错误日志看,出错的应该就是这里了.
      if (list != null) {
        handleLocallyCachedOutputParameters(ms, key, parameter, boundSql);
      } else {
      	// 一级缓存中不存在,则从数据库中查找
        list = queryFromDatabase(ms, parameter, rowBounds, resultHandler, key, boundSql);
      }
    } finally {
      queryStack--;
    }
    if (queryStack == 0) {
      for (DeferredLoad deferredLoad : deferredLoads) {
        deferredLoad.load();
      }
      // issue #601
      deferredLoads.clear();
      if (configuration.getLocalCacheScope() == LocalCacheScope.STATEMENT) {
        // issue #482
        clearLocalCache();
      }
    }
    return list;
  }
```

> org.apache.ibatis.executor.BaseExecutor#queryFromDatabase

```java
// 可以看到 EXECUTION_PLACEHOLDER 是一个枚举类型
public enum ExecutionPlaceholder {
  EXECUTION_PLACEHOLDER
}
	

// 数据库的查询动作
  private <E> List<E> queryFromDatabase(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey key, BoundSql boundSql) throws SQLException {
    List<E> list;
    // 现在一级缓存占据一个位置
    localCache.putObject(key, EXECUTION_PLACEHOLDER);
    try {
      list = doQuery(ms, parameter, rowBounds, resultHandler, boundSql);
    } finally {
    	//
      localCache.removeObject(key);
    }
    // 结果放入一级缓存
    localCache.putObject(key, list);
    if (ms.getStatementType() == StatementType.CALLABLE) {
    	// 缓存参数
      localOutputParameterCache.putObject(key, parameter);
    }
    return list;
  }
```



```java
      // 从一级缓存中查询
      list = resultHandler == null ? (List<E>) localCache.getObject(key) : null;
      // 如果一级缓存存在,则处理
        //从错误日志看,出错的应该就是这里了.
      if (list != null) {
        handleLocallyCachedOutputParameters(ms, key, parameter, boundSql);
      } else {
      	// 一级缓存中不存在,则从数据库中查找
        list = queryFromDatabase(ms, parameter, rowBounds, resultHandler, key, boundSql);
      }
```

这里首先是一个三目表达式，第一次时resultHandler应该为null，那么就会进入queryFromDatabase来进行具体的查询操作，在queryFromDatabase中查询时，会在localCache.putObject(key, EXECUTION_PLACEHOLDER); 中存放了一个占位符，而EXECUTION_PLACEHOLDER 是一个枚举； 当下一个线程过来时，执行到

```java
list = resultHandler == null ? (List<E>) localCache.getObject(key) : null;
```

时，**就发现了localCache中存储的是EXECUTION_PLACEHOLDER ，但是不为空，那这时就(List<E>) localCache.getObject(key) 强制转换为 List**，但是真实存放的是EXECUTION_PLACEHOLDER ，是一个枚举，并不能转换成功，就出错了。



那下面看一下为什么和spring中整合后，就变为了线程安全的，回顾一下和spring整合后的执行：

> org.mybatis.spring.SqlSessionTemplate.SqlSessionInterceptor#invoke

```java
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		/**
* todo  获取sqlsession, 为啥mybatis和spring整合后线程安全了呢?就在这里,sqlSession使用threadLocal来进行保存
		 */
		SqlSession sqlSession = getSqlSession(SqlSessionTemplate.this.sqlSessionFactory,
          SqlSessionTemplate.this.executorType, SqlSessionTemplate.this.exceptionTranslator);
      try {
      	// 此处就执行到DefaultSqlSession
		  // 反射调用,此处的sqlSession为DefaultSqlSession,也就是说method的targer是DefaultSqlSession
		  // 所以此处的调用,就直接调用到 DefaultSqlSession中的 crud了
        Object result = method.invoke(sqlSession, args);
        // 如果spring中没有事务,那么就执行进行提交操作了
        if (!isSqlSessionTransactional(sqlSession, SqlSessionTemplate.this.sqlSessionFactory)) {
          // force commit even on non-dirty sessions because some databases require
          // a commit/rollback before calling close()
          sqlSession.commit(true);
        }
        // 返回执行的结果
        return result;
      } catch (Throwable t) {
        Throwable unwrapped = unwrapThrowable(t);
        if (SqlSessionTemplate.this.exceptionTranslator != null && unwrapped instanceof PersistenceException) {
          // release the connection to avoid a deadlock if the translator is no loaded. See issue #22
          closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
          sqlSession = null;
          Throwable translated = SqlSessionTemplate.this.exceptionTranslator
              .translateExceptionIfPossible((PersistenceException) unwrapped);
          if (translated != null) {
            unwrapped = translated;
          }
        }
        throw unwrapped;
      } finally {
          // 关闭sqlSession
        if (sqlSession != null) {
          closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
        }
      }
    }
  }
```

这里看到执行流程：

1.  getSqlSession 先去spring的threadLocal中获取sqlSession，没有则创建一个
2.  method.invoke 执行查询操作
3.  commit 事务的提交
4.  closeSqlSession 关闭sqlSession
5. 返回结果

这里为什么是线程安全就比较清楚了，其对每一个thread创建了不同的sqlSession实例，彼此不共用，也就没有所谓的线程安全问题了。



















































































