[TOC]

# jedisCluster为什么不支持pipeline

在使用jedcluster时，一般是如下用法:

```java
Pipeline pline = jedis.pipeline();
pline  action
```

一个jedis其实就是连接的一个redis节点，也就是说上面的场景就是把一个批次的key插入到一个redis节点中。而jedisCluster是对应一个redis集群，也就是会有很多redis节点，那是如何插入数据的呢？

```java
jedisCluser.getSlotjedis(crc64 % slots); // 使用key的crc值和slots数量进行取余数,余数就是数据要插入的slot
```

可从上面的伪代码知道jedisCluster插入数据时，是如何得到key对应的slot。而不同的slot是分布在不同的节点的，换句话就是不同的节点负责一段slot的读写。

从上面了解了jedisCluster是如何插入数据的，那么不同的key有很大的可能是分布在不同的节点上，也就是不同的jedis客户端(一个jedis连接一个节点)。所以，使用jedCluster插入一批数据时，如何可以确定数据就是在一个节点上，那么是可以私用pipeline，而一般是不能确定key是在哪个节点的，故不能使用pipeline。