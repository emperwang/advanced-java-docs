[TOC]

# springboot整合jedisCluster 分析

今天咱们直入主题吧，对于springboot和redis集群的整合，本篇咱们分析一下jedisCluster的的配置以及使用。

本篇咱们分析从配置开始入手：

```java
@Configuration
public class JedisClusterConfig {

    @Autowired
    private RedisConfig redisConfig;

    @Bean
    public JedisCluster clusterFactory(){
        String[] split = redisConfig.getNodes().split(",");
        Set<HostAndPort> nodes = new HashSet<>();
        for (String host : split) {
            String[] hostIP = host.split(":");
            nodes.add(new HostAndPort(hostIP[0],Integer.parseInt(hostIP[1])));
        }
        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxIdle(redisConfig.getMaxIdle());
        poolConfig.setMinIdle(redisConfig.getMinIdle());
        poolConfig.setMaxTotal(redisConfig.getMaxActive());
        poolConfig.setMinIdle(redisConfig.getMinIdle());
        poolConfig.setNumTestsPerEvictionRun(10);
        poolConfig.setTimeBetweenEvictionRunsMillis(redisConfig.getTimeBetweenEviction());
        poolConfig.setTestWhileIdle(true);
        poolConfig.setMaxWaitMillis(10000);
        JedisCluster cluster = new JedisCluster(nodes, redisConfig.getConnectionTimeOut(), poolConfig);
        return cluster;
    }
}
```

总体来说是比较简单的，使用一个上面的配置类，就可以直接使用了。使用方法：

```java
    @Autowired
    private JedisCluster jedisCluster;
```

咱们此处就从JedisCluster的创建开始入手：

```java
public JedisCluster(Set<HostAndPort> nodes, int timeout, final GenericObjectPoolConfig poolConfig) {
    this(nodes, timeout, DEFAULT_MAX_REDIRECTIONS, poolConfig);
}

public JedisCluster(Set<HostAndPort> jedisClusterNode, int timeout, int maxAttempts,
                    final GenericObjectPoolConfig poolConfig) {
    super(jedisClusterNode, timeout, maxAttempts, poolConfig);
}

public BinaryJedisCluster(Set<HostAndPort> jedisClusterNode, int timeout, int maxAttempts,
                          final GenericObjectPoolConfig poolConfig) {
    this.connectionHandler = new JedisSlotBasedConnectionHandler(jedisClusterNode, poolConfig,
                                                                 timeout);
    this.maxAttempts = maxAttempts;
}
```

咱们接下来看一下JedisSlotBasedConnectionHandler的创建：

```java
public JedisSlotBasedConnectionHandler(Set<HostAndPort> nodes,
                                       final GenericObjectPoolConfig poolConfig, int timeout) {
    this(nodes, poolConfig, timeout, timeout);
}

public JedisSlotBasedConnectionHandler(Set<HostAndPort> nodes,final GenericObjectPoolConfig poolConfig, int connectionTimeout, int soTimeout) {
    super(nodes, poolConfig, connectionTimeout, soTimeout, null);
}

public JedisClusterConnectionHandler(Set<HostAndPort> nodes,
final GenericObjectPoolConfig poolConfig, int connectionTimeout, int soTimeout, String password) {
    this.cache = new JedisClusterInfoCache(poolConfig, connectionTimeout, soTimeout, password);
    initializeSlotsCache(nodes, poolConfig, password);
}
```

到这里还都只是类的创建，接下来咱们看看JedisClusterInfoCache 以及 initializeSlotsCache这两个方法的作用，从名字上看是创建了 slots 的缓存的信息，从redis的使用可以了解到此应该是和集群交互。那直接看一下：

```java
  public JedisClusterInfoCache(final GenericObjectPoolConfig poolConfig,
      final int connectionTimeout, final int soTimeout, final String password) {
    this.poolConfig = poolConfig;
    this.connectionTimeout = connectionTimeout;
    this.soTimeout = soTimeout;
    this.password = password;
  }
```

```java
  private void initializeSlotsCache(Set<HostAndPort> startNodes, GenericObjectPoolConfig poolConfig, String password) {
    for (HostAndPort hostAndPort : startNodes) {
        // 先连接一个jedis，用于获取信息
      Jedis jedis = new Jedis(hostAndPort.getHost(), hostAndPort.getPort());
      if (password != null) {
        jedis.auth(password);  // 密码认证
      }
      try {
          // 发现master节点以及slot槽的分配
        cache.discoverClusterNodesAndSlots(jedis);
        break;
      } catch (JedisConnectionException e) {
        // try next nodes
      } finally {
        if (jedis != null) {
          jedis.close();  // 使用完了,可以关闭了
        }
      }
    }
  }

```

```java
// 发现集群节点信息和slots槽  
public void discoverClusterNodesAndSlots(Jedis jedis) {
    w.lock();
    try {
      reset();
        // 从创建的jedis连接里面获取 集群 以及 节点信息
      List<Object> slots = jedis.clusterSlots();
      for (Object slotInfoObj : slots) {
        List<Object> slotInfo = (List<Object>) slotInfoObj;
        if (slotInfo.size() <= MASTER_NODE_INDEX) {
          continue;
        }
          // 获取分配的slot
        List<Integer> slotNums = getAssignedSlotArray(slotInfo);
        // hostInfos
        int size = slotInfo.size();
        for (int i = MASTER_NODE_INDEX; i < size; i++) {
          List<Object> hostInfos = (List<Object>) slotInfo.get(i);
          if (hostInfos.size() <= 0) {
            continue;
          }
            // 得到主机信息
          HostAndPort targetNode = generateHostAndPort(hostInfos);
            // 设置master 节点信息
            // 咱们主要看这里
          setupNodeIfNotExist(targetNode);
          if (i == MASTER_NODE_INDEX) {
            assignSlotsToNode(slotNums, targetNode);
          }
        }
      }
    } finally {
      w.unlock();
    }
  }
```

```java
// 具体的存储容器
private final Map<String, JedisPool> nodes = new HashMap<String, JedisPool>();  
// 这里主要是设置主机信息
public JedisPool setupNodeIfNotExist(HostAndPort node) {
    w.lock();
    try {
        // 这里的nodekey就是主机IP+端口
      String nodeKey = getNodeKey(node);
      JedisPool existingPool = nodes.get(nodeKey);
      if (existingPool != null) return existingPool;
      // 创建一个jedis的连接池(底层使用 commonsPool2, 感兴趣可以自己看看,当然了我就很感兴趣,回头会小结一下)
      JedisPool nodePool = new JedisPool(poolConfig, node.getHost(), node.getPort(),
          connectionTimeout, soTimeout, password, 0, null, false, null, null, null);
  	// 可以看到 每一个master 节点对应一个连接池
      nodes.put(nodeKey, nodePool);
      return nodePool;
    } finally {
      w.unlock();
    }
  }
```

```java
// 缓存 每一个节点对应的连接池
private final Map<Integer, JedisPool> slots = new HashMap<Integer, JedisPool>();
// 这里是缓存 slot信息  
public void assignSlotsToNode(List<Integer> targetSlots, HostAndPort targetNode) {
    w.lock();
    try {
        // 获取节点对应的连接池
      JedisPool targetPool = setupNodeIfNotExist(targetNode);
      for (Integer slot : targetSlots) {
          // 把此节点的对应的所有slot缓存起来,并设置其连接池就是此节点的连接池
        slots.put(slot, targetPool);
      }
    } finally {
      w.unlock();
    }
  }
```

到这里jedisCluster就创建好了，从此创建的过程可以看到每一个节点以及该节点对应的slot都保存起来，并且每个节点以及其对应的slots都对应同一个jedis连接池。而且底层的jedis连接池使用commonsPool2池化实现。

关于commonsPool会另开另一篇进行分析。那本篇就结束了。