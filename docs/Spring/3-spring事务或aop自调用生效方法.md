[TOC]

# 事务以及aop内部调用生效方法



## 事务

环境: postgresql-9.5   mybatis-3.5.1  springboot-2.1.6

需求: 批量处理一批bean，处理完之后要把bean的主键作为redis hash结构的field进行插入，而插入数据库的方式使用的是批量插入，所以在处理bean时需要每条数据从数据库中获取主键，大体代码如下;  

问题:  批量处理时, 每次获取的Id都是一样的,  并且设置了不使用缓存, 导致插入时主键冲突.

sql:

```xml
<select id="getSeq" resultType="java.lang.Integer" useCache="false">
    select nextval('user_id_seq'::regclass)
</select>
```



```java
public class resultServiceImpl implements resultService{
    @Override
    @Transactional(isolation = Isolation.DEFAULT)
    public JSONObject batchInsert(String addStr) {
        JSONObject object = new JSONObject();
        if (addStr != null && addStr.length() > 0){
            String delids = JSONUtil.getJsonField(addStr, ParameterConstant.ResponseKey);
            // 把json数据转换为bean
            List<Result> res = JSONUtil.jsonToBeanList(delids,Result.class);
            //  对数据进行批量处理
            processInfo(res);
            if (res != null && res.size() > 0) {
                // 把处理完的数据插入到数据库中
                int counts = ResultMapper.batchInsert(res);
                log.info("batch insert size:{}, values:{}", counts, JSON.toJSONString(res));
            }
        }
        return object;
    }

    // 进行处理的批量处理
    private void processInfo(List<Result> res){
        res.stream().forEach(it -> {
            if (it.getAutoId() == null) {
                // 从数据中获取主键
                Integer seq = getSeq();
                log.info("get seq: {}", seq);
                it.setAutoId(seq);
            }
        });
        res.stream().forEach(it ->{
            // set 数据到 redis中
            jedisUtil.hset(config.getRedisConfigKey(), it.getAutoId().toString(), JSON.toJSONString(it));
        }
       );
    }


    @Transactional(isolation = Isolation.DEFAULT, propagation = Propagation.REQUIRES_NEW)
    public int getSeq(){
        return ResultMapper.getSeq();
    }
}
```

上面的处理看起来都没有问题，不过运行时会发现获取的主键是一样的，此时才考虑到影响因素可能是在一个事务中执行导致的。

**这就涉及到了事务内调用内部方法，不过内部方法的事务并没有生效的问题。**

下面就来说一下解决：

```shell
# 方法一
通过ApplicationContext来从容器中获取resultService bean,之后再使用此bean记性方法的调用.

# 方法二
把resultService对应的bean注入到 resultService实现类中, 通过注入的实现类来进行调用
```

上面代码修改如下:

```java
public class resultServiceImpl implements resultService{
    @Autowired
    private ResultMapper resultMapper;
    @Autowired
    @Lazy // 添加这个, 进行懒加载
    private resultService resultService
    
    @Override
    @Transactional(isolation = Isolation.DEFAULT)
    public JSONObject batchInsert(String addStr) {
        JSONObject object = new JSONObject();
        if (addStr != null && addStr.length() > 0){
            String delids = JSONUtil.getJsonField(addStr, ParameterConstant.ResponseKey);
            // 把json数据转换为bean
            List<Result> res = JSONUtil.jsonToBeanList(delids,Result.class);
            //  对数据进行批量处理
            processInfo(res);
            if (res != null && res.size() > 0) {
                // 把处理完的数据插入到数据库中
                int counts = resultMapper.batchInsert(res);
                log.info("batch insert size:{}, values:{}", counts, JSON.toJSONString(res));
            }
        }
        return object;
    }

    // 进行处理的批量处理
    private void processInfo(List<Result> res){
        res.stream().forEach(it -> {
            if (it.getAutoId() == null) {
                // 从数据中获取主键
                // 修改前
                //Integer seq = getSeq();
                //****************************************** 
 			   //              修改后
                //****************************************** 
                Integer seq = resultService.getSeq();
                log.info("get seq: {}", seq);
                it.setAutoId(seq);
            }
        });
        res.stream().forEach(it ->{
            // set 数据到 redis中
            jedisUtil.hset(config.getRedisConfigKey(), it.getAutoId().toString(), JSON.toJSONString(it));
        }
       );
    }


    @Transactional(isolation = Isolation.DEFAULT, propagation = Propagation.REQUIRES_NEW)
    public int getSeq(){
        return resultMapper.getSeq();
    }
}
```

修改后问题解决。





## aop

当前Aop也可以使用上面的方式来尝试解决。

不过同样由一个注解

```java
@EnableAspectJAutoProxy(exposeProxy = true)
// 此配置会把 代理放入到 AopContext 也就是 ThreadLocal中
// 加上此注解后内部调用使用此方式

```

```java
public class aopProxy{
    // 增强方法1
    public void log(){
		sout();

    }
	// 增强方法2
    public void log2(){
        // 如此在内部调用方法, 就同样会走 aop代理
        ((aopProxy) AopContext.currentProxy()).log();
    }
}
```









































