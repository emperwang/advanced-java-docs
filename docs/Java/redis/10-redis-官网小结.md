[TOC]

# redis

## 集群恢复

```shell
In the majority side of the partition assuming that there are at least the majority of masters and a slave for every unreachable master, the cluster becomes available again after NODE_TIMEOUT time plus a few more seconds required for a slave to get elected and failover its master (failovers are usually executed in a matter of 1 or 2 seconds).

# 集群中大部分的master存活，且每一个不可达的master都有对应的slave，那么在NODE_TIMEOUT + (a few more seconds required for a slave to get elected and failover its master) 集群就会恢复。 （failove通常在1到2s内执行）
```



## hash tag的使用

hash tag出现的原因：

```shell
Hash tags are a way to ensure that multiple keys are allocated in the same hash slot. This is used in order to implement multi-key operations in Redis Cluster.

# hash tag可以保证多个key能分配到同一个slot.这种做法实现了在redis集群中多个key的操作.
```

hash tag的具体实现

```shell
If the key contains a "{...}" pattern only the substring between { and } is hashed in order to obtain the hash slot. However since it is possible that there are multiple occurrences of { or } the algorithm is well specified by the following rules:

1.IF the key contains a { character.
2.AND IF there is a } character to the right of {
3.AND IF there are one or more characters between the first occurrence of { and the first occurrence of }.

examples:

1.The two keys {user1000}.following and {user1000}.followers will hash to the same hash slot since only the substring user1000 will be hashed in order to compute the hash slot.
2.For the key foo{}{bar} the whole key will be hashed as usually since the first occurrence of { is followed by } on the right without characters in the middle.
3.For the key foo{{bar}}zap the substring {bar will be hashed, because it is the substring between the first occurrence of { and the first occurrence of } on its right.
4.For the key foo{bar}{zap} the substring bar will be hashed, since the algorithm stops at the first valid or invalid (without bytes inside) match of { and }.
5.What follows from the algorithm is that if the key starts with {}, it is guaranteed to be hashed as a whole. This is useful when using binary data as key names.

```

hash tag的具体算法实例:

```ruby
def HASH_SLOT(key)
    s = key.index "{"
    if s
        e = key.index "}",s+1
        if e && e != s+1
            key = key[s+1..e-1]
        end
    end
    crc16(key) % 16384
end
```

```c
unsigned int HASH_SLOT(char *key, int keylen) {
    int s, e; /* start-end indexes of { and } */

    /* Search the first occurrence of '{'. */
    for (s = 0; s < keylen; s++)
        if (key[s] == '{') break;

    /* No '{' ? Hash the whole key. This is the base case. */
    if (s == keylen) return crc16(key,keylen) & 16383;

    /* '{' found? Check if we have the corresponding '}'. */
    for (e = s+1; e < keylen; e++)
        if (key[e] == '}') break;

    /* No '}' or nothing between {} ? Hash the whole key. */
    if (e == keylen || e == s+1) return crc16(key,keylen) & 16383;

    /* If we are here there is both a { and a } on its right. Hash
     * what is in the middle between { and }. */
    return crc16(key+s+1,e-s-1) & 16383;
}
```



## cluster node 属性

```shell
$ redis-cli cluster nodes
d1861060fe6a534d42d8a19aeb36600e18785e04 127.0.0.1:6379 myself - 0 1318428930 1 connected 0-1364
3886e65cc906bfd9b1f7e7bde468726a052d1dae 127.0.0.1:6380 master - 1318428930 1318428931 2 connected 1365-2729
d289c575dcbc4bdd2931585fd4339089e461a27d 127.0.0.1:6381 master - 1318428931 1318428931 3 connected 2730-4095

## 字段解析
fields are in order: node id, address:port, flags, last ping sent, last pong received, configuration epoch, link state, slots
```



## Nodes handshake(节点握手信息)

```shell
Nodes always accept connections on the cluster bus port, and even reply to pings when received, even if the pinging node is not trusted. However, all other packets will be discarded by the receiving node if the sending node is not considered part of the cluster.
# 节点总结在 cluster bus port上接受连接,并对接收到的ping进行回复,尽管pinging node不是可信的.但是呢,所有其他的package会被丢弃,如果发送package的node不是集群中的节点.
```



```shell
# 一个node接收其他node作为集群节点有两种方式
A node will accept another node as part of the cluster only in two ways:

1.If a node presents itself with a MEET message. A meet message is exactly like a PING message, but forces the receiver to accept the node as part of the cluster. Nodes will send MEET messages to other nodes only if the system administrator requests this via the following command:
CLUSTER MEET ip port

# 一个node使用MEET消息发送自己.meet消息和PING消息很相似,却强制接受者接收node作为集群中的一部分. 只有当管理员使用CLUSTER MEET ip port 命令时,node才会发送MEET消息

2.A node will also register another node as part of the cluster if a node that is already trusted will gossip about this other node. So if A knows B, and B knows C, eventually B will send gossip messages to A about C. When this happens, A will register C as part of the network, and will try to connect with C.

# node(A)同样会吧另一个node(B)注册为集群中的一个节点,当这个node(B)已经被集群中其他节点信任.所以: 当A 探测到B,B探测到C,最终B会把C通过发送gooip消息给A. 当这个操作发生后,A就会把C注册为集群中的一部分,且会尝试连接C.
```



## MOVED和ASK 消息处理

MOVED消息:

```shell
GET x
-MOVED 3999 127.0.0.1:6381
```

MOVED的处理:

```shell
An alternative is to just refresh the whole client-side cluster layout using the CLUSTER NODES or CLUSTER SLOTS commands when a MOVED redirection is received. When a redirection is encountered, it is likely multiple slots were reconfigured rather than just one, so updating the client configuration as soon as possible is often the best strategy.

# 大意: 当接收到MOVED命令时,很多情况下都是集群中有许多的slot记性了更改,所以要更新一些客户端本地的 table map.
```



ASK的处理:

```shell
# ASK的处理语义
The full semantics of ASK redirection from the point of view of the client is as follows:
1. If ASK redirection is received, send only the query that was redirected to the specified node but continue sending subsequent queries to the old node.
# 如果接收到了ASK重定向,只发送此query到特定的node,但是后续的查询仍然发送到此old node
2.Start the redirected query with the ASKING command.
# 使用ASKING命令开始重定向查询
3.Don't yet update local client tables to map hash slot 8 to B.
# 不更新客户端本地的 table map
```



## 客户端更新本地table map的两个时间点

```shell
Clients usually need to fetch a complete list of slots and mapped node addresses in two different situations:
1.At startup in order to populate the initial slots configuration.
# 刚启动时,初始化配置
2.When a MOVED redirection is received.
# 接收到  MOVED重定向指令时
```



## MIGRATING和IMPORTING使用

```shell
When a slot is set as MIGRATING, the node will accept all queries that are about this hash slot, but only if the key in question exists, otherwise the query is forwarded using a -ASK redirection to the node that is target of the migration.
# 当一个slot设置为MIGRATING,这个node仍然会接收所有对此slot的查询,但仅当此key存在时,否则回复 ASK 重定向此查询到 migration的目标node上.

When a slot is set as IMPORTING, the node will accept all queries that are about this hash slot, but only if the request is preceded by an ASKING command. If the ASKING command was not given by the client, the query is redirected to the real hash slot owner via a -MOVED redirection error, as would happen normally.
# 当一个slot设置为IMPORTING时,只有当对此slot使用ASKING命令时,这个node才会接收此查询. 如果客户端没有发送ASKING请求,那么对此slot的查询会被MOVED重定向到此slot的真正属主.
```

举一个栗子:

```shell
We want to move hash slot 8 from A to B, so we issue commands like this
# 我们想把 slot8 从A 移动到B, 命令如下:
1.We send B: CLUSTER SETSLOT 8 IMPORTING A
# 发送给B的命令:
2.We send A: CLUSTER SETSLOT 8 MIGRATING B
# 发送给A的命令:

command:
MIGRATE target_host target_port key target_database id timeout
```



## 丢失消息的场景

场景一:

```shell
A write may reach a master, but while the master may be able to reply to the client, the write may not be propagated to slaves via the asynchronous replication used between master and slave nodes. If the master dies without the write reaching the slaves, the write is lost forever if the master is unreachable for a long enough period that one of its slaves is promoted. This is usually hard to observe in the case of a total, sudden failure of a master node since masters try to reply to clients (with the acknowledge of the write) and slaves (propagating the write) at about the same time. However it is a real world failure mode.

# 大意如下：当客户端向master写入一次数据后，并收到了master的回复，此写操作会异步同步到slave中。如果master在异步同步进行前挂掉了，一段时间后此master的slave晋升成master，那么此次的写操作就永远丢失了。
```

场景二：

```shell
Another theoretically possible failure mode where writes are lost is the following:
1.A master is unreachable because of a partition.
	#  master不可达
2.It gets failed over by one of its slaves.
	#  此master的slave晋升为 master
3.After some time it may be reachable again.
	#  一段时间后,此master又可达了
4.A client with an out-of-date routing table may write to the old master before it is converted into a slave (of the new master) by the cluster.
	#  客户端的路由关系还使用旧的

The second failure mode is unlikely to happen because master nodes unable to communicate with the majority of the other masters for enough time to be failed over will no longer accept writes, and when the partition is fixed writes are still refused for a small amount of time to allow other nodes to inform about configuration changes. This failure mode also requires that the client's routing table has not yet been updated.
```

```shell
Specifically, for a master to be failed over it must be unreachable by the majority of masters for at least NODE_TIMEOUT, so if the partition is fixed before that time, no writes are lost. When the partition lasts for more than NODE_TIMEOUT, all the writes performed in the minority side up to that point may be lost. However the minority side of a Redis Cluster will start refusing writes as soon as NODE_TIMEOUT time has elapsed without contact with the majority, so there is a maximum window after which the minority becomes no longer available. Hence, no writes are accepted or lost after that time.

# 特别注意的是,当一个master等待failover时,其一定得是和大多数master失联超过NODE_TIMEOUT,如果在这个时间之前恢复,则不会丢失数据. 当partition失联超过NODE_TIMEOUT,所有在超时后对 minority的写入可能会丢失.但是minority在超过NODE_TIMEOUT时间没有和 majority联系时,就会开始拒绝写入,所以当minority不可用时会有一个很大的时间区间会丢失数据. 所以在那之后,没有写入被处理或者丢失.
```



## 心跳的发送

redis中什么称为心跳包? 

```shell
Redis Cluster nodes continuously exchange ping and pong packets. Those two kind of packets have the same structure, and both carry important configuration information. The only actual difference is the message type field. We'll refer to the sum of ping and pong packets as heartbeat packets.
# 简单说 redis中的 ping pong称为心跳包
```

redis节点中每次发送心跳包都要有回应吗?什么情况下发送的心跳包不需要回复?

```shell
Usually nodes send ping packets that will trigger the receivers to reply with pong packets. However this is not necessarily true. It is possible for nodes to just send pong packets to send information to other nodes about their configuration, without triggering a reply. This is useful, for example, in order to broadcast a new configuration as soon as possible.
```

redis节点发送心跳包是给所有的节点发送吗? 或者 redis节点发送心跳包的对象如何确定?

```shell
Usually a node will ping a few random nodes every second so that the total number of ping packets sent (and pong packets received) by each node is a constant amount regardless of the number of nodes in the cluster.

# 简答说: 通常情况下每次发送只是选择随机几个发送不是全部发送. 发送的对象是随机选择.
```

redis 多久发送一次心跳包? 或者 发送心跳间隔是什么?

```shell
However every node makes sure to ping every other node that hasn't sent a ping or received a pong for longer than half the NODE_TIMEOUT time. Before NODE_TIMEOUT has elapsed, nodes also try to reconnect the TCP link with another node to make sure nodes are not believed to be unreachable only because there is a problem in the current TCP connection.

# 简单说: 每 NODE_TIMEOUT/2 时间发送一次. 并且不成功还会进行重新了解,以防止是网路链路导致的问题.
```

redis心跳包的大小计算:

```shell
For example in a 100 node cluster with a node timeout set to 60 seconds, every node will try to send 99 pings every 30 seconds, with a total amount of pings of 3.3 per second. Multiplied by 100 nodes, this is 330 pings per second in the total cluster.

There are ways to lower the number of messages, however there have been no reported issues with the bandwidth currently used by Redis Cluster failure detection, so for now the obvious and direct design is used. Note that even in the above example, the 330 packets per second exchanged are evenly divided among 100 different nodes, so the traffic each node receives is acceptable.
# 100个节点,timeout=60s, 那么每个节点 30s发送99个包, 也就是 3.3/s,100个节点也就是 330/s.
```

心跳包的内容:

```shell
The common header has the following information:

1.Node ID, a 160 bit pseudorandom string that is assigned the first time a node is created and remains the same for all the life of a Redis Cluster node.
# node ID
2.The currentEpoch and configEpoch fields of the sending node that are used to mount the distributed algorithms used by Redis Cluster (this is explained in detail in the next sections). If the node is a slave the configEpoch is the last known configEpoch of its master.
# currentEpoch and configEpoch 
3.The node flags, indicating if the node is a slave, a master, and other single-bit node information.
# node的角色
4.A bitmap of the hash slots served by the sending node, or if the node is a slave, a bitmap of the slots served by its master.
# 服务的 slot
5.The sender TCP base port (that is, the port used by Redis to accept client commands; add 10000 to this to obtain the cluster bus port).
#  发送者的 port
6.The state of the cluster from the point of view of the sender (down or ok).
# 发送者 认为的集群状态  down/ok
7.The master node ID of the sending node, if it is a slave.
# 如果是slave,则加上其master的 nodeId
```

PING和 PONG 包同样包含了 goosip section.

```shell
Ping and pong packets also contain a gossip section. This section offers to the receiver a view of what the sender node thinks about other nodes in the cluster. The gossip section only contains information about a few random nodes among the set of nodes known to the sender. The number of nodes mentioned in a gossip section is proportional to the cluster size.
# ping pong包中同样包含了gossip section. 这个 section提供了接收者一个在sender节点眼中如何看待集群中其他节点. gossip section只包含发送者了解的节点的随机的几个. gossip section中的节点数量和集群大小成比例.
```

gossip内容:

```shell
Node ID.
IP and port of the node.
Node flags.
```



## 错误探测(Failure detection)

```shell
Redis Cluster failure detection is used to recognize when a master or slave node is no longer reachable by the majority of nodes and then respond by promoting a slave to the role of master. When slave promotion is not possible the cluster is put in an error state to stop receiving queries from clients.

# redis集群的错误探测用于识别一个master或slave节点不能和大多数节点连接,然后响应一个slave节点的晋升. 当slave晋升不成功或不能晋升, 集群会设置一个error 状态来停止接收客户端的查询
```

PFAIL flag:

```shell
A node flags another node with the PFAIL flag when the node is not reachable for more than NODE_TIMEOUT time. Both master and slave nodes can flag another node as PFAIL, regardless of its type.

# 一个节点能标记其他节点PFAIl标志,当那个node超过NODE_TIMEOUT不可达时. master和slave都能标记其他节点PFAIL, 无论其他节点的类型是什么.

The concept of non-reachability for a Redis Cluster node is that we have an active ping (a ping that we sent for which we have yet to get a reply) pending for longer than NODE_TIMEOUT. For this mechanism to work the NODE_TIMEOUT must be large compared to the network round trip time. In order to add reliability during normal operations, nodes will try to reconnect with other nodes in the cluster as soon as half of the NODE_TIMEOUT has elapsed without a reply to a ping. This mechanism ensures that connections are kept alive so broken connections usually won't result in false failure reports between nodes.
# non-reachability 表示: redis节点会发送ping,等待期reply的时间超过了NODE_TIMEOUT. 对于这种机制NODE_TIMEOUT必须大于网络的往返时间. 为了增加可靠性,正常操作下,超过NODE_TIMEOUT/2 时间没有响应ping时,node会尝试重新连接另一个node. 这种机制保证了broken connection通常不会导致错误的failure报告.
```

FAIL falg:

```shell
The PFAIL flag alone is just local information every node has about other nodes, but it is not sufficient to trigger a slave promotion
# PFAIL 标志只是每个节点对于其他节点的本地信息, 这不足以触发一次 slave的晋升.
For a node to be considered down the PFAIL condition needs to be escalated to a FAIL condition.
# 对于一个考虑要被关闭的node,必须从PFAIL升级为FAIL.
```

PFAIL升级为FAIL的条件:

```shell
1.Some node, that we'll call A, has another node B flagged as PFAIL.
# 假设 node A标记了 node B为PFAIL
2.Node A collected, via gossip sections, information about the state of B from the point of view of the majority of masters in the cluster.
# node A通过gossip协议开始收集集群中大多数master对 node B的看法
3.The majority of masters signaled the PFAIL or FAIL condition within NODE_TIMEOUT * FAIL_REPORT_VALIDITY_MULT time. (The validity factor is set to 2 in the current implementation, so this is just two times the NODE_TIMEOUT time).
# 大多数的master会在NODE_TIMEOUT * FAIL_REPORT_VALIDITY_MULT 时间内发送出 PFAIL到FAIL的消息.  FAIL_REPORT_VALIDITY_MULT 默认是2.
```

当条件满足后,node A操作:

```shell
1.Mark the node as FAIL.
# 标记node为 FAIL
2.Send a FAIL message to all the reachable nodes.
# 发送FAIL信息到集群中其他节点
The FAIL message will force every receiving node to mark the node in FAIL state, 
whether or not it already flagged the node in PFAIL state.
# FAIL消息会强制接收到消息的节点把node标记为FAIL,无论其是否已经把node标记为PFAIL.
```

FAIL标记可以被清除的情况:

```shell
1.The node is already reachable and is a slave. In this case the FAIL flag can be cleared as slaves are not failed over.
# 此node是slave,且已经可达了. 这种情况情况下 FAIL标记可以被清除,且没有发生failover
2.The node is already reachable and is a master not serving any slot. In this case the FAIL flag can be cleared as masters without slots do not really participate in the cluster and are waiting to be configured in order to join the cluster.
# 此节点是一个没有slot的master,且现在可达. 这种情况下FAIL标记可以被清除,因为一个没有slot的master并不算真正加入到集群中其正在等待被配置 然后加入集群中
3.The node is already reachable and is a master, but a long time (N times the NODE_TIMEOUT) has elapsed without any detectable slave promotion. It's better for it to rejoin the cluster and continue in this case.
# 此node是一个master,现在可达, 但是已经 N*NODE_TIMEOUT 时间过去了,并且没有探测任何的slave 晋升操作, 这种情况下最好就是让此master重新加入到集群中.
```

PFAIL ->FAIL的转换弱一致性协议:

```shell
1.Nodes collect views of other nodes over some time period, so even if the majority of master nodes need to "agree", actually this is just state that we collected from different nodes at different times and we are not sure, nor we require, that at a given moment the majority of masters agreed. However we discard failure reports which are old, so the failure was signaled by the majority of masters within a window of time.
# nodes在一段时间内收集其他节点的看法信息,即使需要大多数节点 "agree 同意", 实际上我们只是在不同的时间收集不同节点的信心,我们也不确定,也没有要求,在那个时间点(收集信息的时间点)要求master同意. 而且我们会丢弃那些已经过期的failure信息,所以failure信息最终会由大多数master在一定得时间窗口发送出来.
2.While every node detecting the FAIL condition will force that condition on other nodes in the cluster using the FAIL message, there is no way to ensure the message will reach all the nodes. For instance a node may detect the FAIL condition and because of a partition will not be able to reach any other node.
# 当一个node探测到FAIL信息,并发送FAIL消息到集群中的其他节点,这个也不能保证此消息能发送给所有节点. 对于一个探测大FAIL条件的节点,可能因为分区而不能喝其他节点联系.
```

## slave的晋升步骤

谁开始的晋升动作?

```shell
Slave election and promotion is handled by slave nodes, with the help of master nodes that vote for the slave to promote. A slave election happens when a master is in FAIL state from the point of view of at least one of its slaves that has the prerequisites in order to become a master.
# Slave的选举和晋升由slave节点自己处理,其他的master节点投票帮助其晋升.
```



slave开始晋升的条件:

```shell
A slave starts an election when the following conditions are met:
# slave开始选举的条件
1.The slave's master is in FAIL state.
# slave的master状态为 FAIL
2.The master was serving a non-zero number of slots.
# master拥有 slots
3.The slave replication link was disconnected from the master for no longer than a given amount of time, in order to ensure the promoted slave's data is reasonably fresh. This time is user configurable.
# slave和master的副本连接被断开不超过一定时间,为了保证slave的数据是比较新的, 这个时间是可配置的.
```

slave晋升的动作:

```shell
0.As soon as a master is in FAIL state, a slave waits a short period of time before trying to get elected. The delay is :
DELAY = 500 milliseconds + random delay between 0 and 500 milliseconds +
        SLAVE_RANK * 1000 milliseconds.
# 只要master进入FAIL状态, slave在开始选举前,会等待一端时间,时间计算如上所示.
1. In order to be elected, the first step for a slave is to increment its currentEpoch counter, and request votes from master instances.
# 为了开始选举,slave的第一步就是增加其currentEpoch, 并且请求其他master的选票
2.Votes are requested by the slave by broadcasting a FAILOVER_AUTH_REQUEST packet to every master node of the cluster.
# slave通过发送FAILOVER_AUTH_REQUEST包给集群中的其他master,来请求选票
3.Then it waits for a maximum time of two times the NODE_TIMEOUT for replies to arrive (but always for at least 2 seconds).
# 发送请求后,slave开始等待回复, 最大的等待时间为 2*NODE_TIMEOUT.(至少是2s)
4.Once a master has voted for a given slave, replying positively with a FAILOVER_AUTH_ACK
# 一旦master准备投票给slave,其发送FAILOVER_AUTH_ACK 消息
5.A slave discards any AUTH_ACK replies with an epoch that is less than the currentEpoch at the time the vote request was sent. This ensures it doesn't count votes intended for a previous election.
# slave丢弃那些epoch小于发送请求时currentEpoch的选票. 这是为了保证不会计算以前选举的选票
6.Once the slave receives ACKs from the majority of masters, it wins the election.
# 一旦slave接收到了大多数master的响应,就获胜了
7. Otherwise if the majority is not reached within the period of two times NODE_TIMEOUT (but always at least 2 seconds), the election is aborted and a new one will be tried again after NODE_TIMEOUT * 4 (and always at least 4 seconds).
# 如果2*NODE_TIMEOUT都没有接收到大多数master的回复, 此选举就终止了,并且一个新选举会在NODE_TIMEOUT * 4 之后再次记性.
```

slave选举前先等待一段时间，是为了避免多个slave同时选举.

SLAVE_RANK:

```shell
The SLAVE_RANK is the rank of this slave regarding the amount of replication data it has processed from the master. Slaves exchange messages when the master is failing in order to establish a (best effort) rank: the slave with the most updated replication offset is at rank 0, the second most updated at rank 1, and so forth. In this way the most updated slaves try to get elected before others.
# SLAVE_RANK 表示slave从master同步的数据. 当master在failing状态时,slave和其开始交换信息: 最好的同步RANK为0, 此好的为1,以此类推. 这种方式是为了同步最好的slave赢取选举.
```

master接收到FAILOVER_AUTH_REQUEST的处理:

```shell
For a vote to be granted the following conditions need to be met:
# master要产生选票必选满足一下条件:
1.A master only votes a single time for a given epoch, and refuses to vote for older epochs: every master has a lastVoteEpoch field and will refuse to vote again as long as the currentEpoch in the auth request packet is not greater than the lastVoteEpoch.
When a master replies positively to a vote request, the lastVoteEpoch is updated accordingly, and safely stored on disk.
# master只会对某一个epoch投票一次，并且拒绝对老的epoch投票: 每一个master都有一个lastVoteEpoch,并且拒绝对那些auth-request中currentEpoch小于lastVoteEpoch的请求投票.当master响应一个投票请求时,lastVoteEpoch会对应更新,并安全的存储到disk
2.A master votes for a slave only if the slave's master is flagged as FAIL.
# master只会对那些slave的master 标记为FAIL的投票
3.Auth requests with a currentEpoch that is less than the master currentEpoch are ignored. Because of this the master reply will always have the same currentEpoch as the auth request. If the same slave asks again to be voted, incrementing the currentEpoch, it is guaranteed that an old delayed reply from the master can not be accepted for the new vote.
# Auth request中currentEpoch小于master的currentEpoch会被忽略. 导致了master的currentEpoch总是和auth request中相同. 如果slave再次请求投票,其会增加currentEpoch的值, 这保证了那些比较延后的master响应不会被接受.
```

mater投票后的其他操作:

```shell
1.Masters don't vote for a slave of the same master before NODE_TIMEOUT * 2 has elapsed if a slave of that master was already voted for. This is not strictly required as it is not possible for two slaves to win the election in the same epoch. However, in practical terms it ensures that when a slave is elected it has plenty of time to inform the other slaves and avoid the possibility that another slave will win a new election, performing an unnecessary second failover.
# master在NODE_TIMEOUT * 2时间内不会对同一个slave投票. 这个不是强求的因为不可能两个slave使用相同的epoch来赢得选举. 但是,在实践中他保证了一个slave赢得选举后拥有足够的时间通知其他slaves并且避免其他slave进行一次新的选举,进行一次不必要的failover.
2.Masters make no effort to select the best slave in any way. If the slave's master is in FAIL state and the master did not vote in the current term, a positive vote is granted. The best slave is the most likely to start an election and win it before the other slaves, since it will usually be able to start the voting process earlier because of its higher rank as explained in the previous section.
# master对选择出最好的slave没有影响. 如果slave的master是FAIL状态,并且master在当前任期没有投票,则给予正面投票. 最好的slave应该是最先开始选举的slave,因为rank的关系,它比其他的slave要先投票
3.When a master refuses to vote for a given slave there is no negative response, the request is simply ignored.
# 当一个master拒绝对一个slave投票时,其没有负面响应, 只是简单的忽略.
4.Masters don't vote for slaves sending a configEpoch that is less than any configEpoch in the master table for the slots claimed by the slave. Remember that the slave sends the configEpoch of its master, and the bitmap of the slots served by its master. This means that the slave requesting the vote must have a configuration for the slots it wants to failover that is newer or equal the one of the master granting the vote.
# master不会对configEpoch 小的slave投票.
```

## node reset的操作

命令:

```shell
CLUSTER RESET SOFT
CLUSTER RESET HARD
```

产应的影响:

```shell
#Soft and hard reset: means  sofe 和 hard 都有的影响
# SOft 表示只有soft才有的影响
# Hard 表示之后 Hard才有的影响
1.Soft and hard reset: If the node is a slave, it is turned into a master, and its dataset is discarded. If the node is a master and contains keys the reset operation is aborted.
#  如果node是slave,此命令会把此node升级为 master,并且其dataset 被丢弃. 
#  如果此节点是master 并且包含key, 那么此 reset操作会终止
2.Soft and hard reset: All the slots are released, and the manual failover state is reset.
#  所有的slot 释放, 并且 手动的 failover状态被复位
3.Soft and hard reset: All the other nodes in the nodes table are removed, so the node no longer knows any other node.
# node table中的所有其他节点被移除,所以此node不再知道其他节点
4.Hard reset only: currentEpoch, configEpoch, and lastVoteEpoch are set to 0.
#currentEpoch, configEpoch, and lastVoteEpoch 设置为0
5.Hard reset only: the Node ID is changed to a new random ID.
# Node ID 修改为一个新的随机ID
```

## 副本迁移(replicas migration)

迁移算法的开始:

```shell
The execution of the algorithm is triggered in every slave that detects that there is at least a single master without good slaves. 
# 每一个slave探测到集群中至少有一个master没有 good slave 就会触发此算法.
# a good slave is a slave not in FAIL state from the point of view of a given node.
```

真正执行算法的save:

```shell
The acting slave is the slave among the masters with the maximum number of attached slaves, that is not in FAIL state and has the smallest node ID.
# 执行算法的slave是在 那个拥有最多不是FAIL状态slave, 且 NodeId最小的slave开始执行.
# 简单说: 1.挑选slave数量最多的master 2. 在其slave中选举 node id最小的执行算法
```

副本迁移算法:

```shell
从slave数量最多的master中,选举node id最小的slave作为孤儿master的slave.
```

有关的一个配置:

cluster-migration-barrier:

```shell
The algorithm is controlled by a user-configurable parameter called cluster-migration-barrier: the number of good slaves a master must be left with before a slave can migrate away. For example, if this parameter is set to 2, a slave can try to migrate only if its master remains with two working slaves.
#控制算法的一个用户配置参数: master至少拥有的slave数量.
#example: 如果设置为2,那么一个至于在master的goog slave数量为3的情况下才能迁移.
```

## remove node操作

命令:

```shell
 CLUSTER FORGET <node-id>
```

影响:

```shell
1.It removes the node with the specified node ID from the nodes table.
# 此命令把 node-id从 node-table中移除
2.It sets a 60 second ban which prevents a node with the same node ID from being re-added.
# 此设置了60s内,相同的node id 不能重新被加入大集群中
```





















