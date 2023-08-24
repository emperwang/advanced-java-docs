# redis 分布式锁

## 1.redis分布式锁使用

针对redis的分布式锁，获取锁时应该为该lock设置一个随机值，这样当删除时判断一下lock对应的value是否是刚才设置的随机值，则进行删除。

这样当业务执行完成，删除lock时，不会因为lock过期而删除其他进程设置lock。

```shell
# shell加锁
redis-cli -h ip -p port set lockname lockValue NX PX TIME
## lockname  锁名字
## lockValue 锁值
## NX	set if not exists
## PX	表示要加一个超时时间
## TIME	超时时间
# java加锁
jedis.set(String key, String value, String nxxx, String expx, int time)
jedis.set(lockKey, requestId, SET_IF_NOT_EXIST, SET_WITH_EXPIRE_TIME, expireTime)

# 解锁
## 具体解锁使用lua,来删除锁
脚本 /opt/del.lua,内容如下
if redis.call("GET",KEYS[1]) ==ARGV[1] then
	return redis.call("DEL", KEYS[1])
	else
	return 0
end

redis-cli -h ip -p port  --eval /opt/del.lua  lockName, lockValue

# java解锁
String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";

Object result = jedis.eval(script, Collections.singletonList(LockKey), Collections.singletonList(lockValue));
## 这里使用lua脚本原子性删除
```





## 2. 服务运行超过redis锁的有效时间

异常场景一:

```sh
如果客户端1对某个reids master实例设置锁成功, 此时会异步复制给slave实例.
但是这个过程中一旦发生master宕机, 主备切换, slave变为master, 而且呢master的锁信息没有同步到此slave上.
那么就会导致客户端2尝试加锁的时候, 在新的master上完成了加锁,而客户端1也认为成功加了锁.
```

异常场景二:

```shell
客户端1 业务代码执行的时间比较长, 导致锁超时了.
此时客户端2获取成功, 并开始执行.  之后客户端1执行完成, 删除锁,发现不是自己的锁,抛出异常.
```

此种场景下，可以使用一个后台线程，间隔一段时间判断客户端是否还在使用锁，如果使用呢，就尝试更新锁的超时时间，这样就不会导致锁在客户端执行期间就被释放了。了解一下``redisson``的实现





























