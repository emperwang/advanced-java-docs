[TOC]

# MySql的一些优化策略

## 1.根据状态查看当前数据库是那种操作多

```shell
# 使用命名查看当前数据库中哪种操作多，好去定位做些什么优化
--> show [sessoin | global ] status
--> show status like 'Com_%';    # 进行一些过滤
# 也可以使用此命令进行查看
mysqladmin extended-status -h host -p password
```

显示如图：

![](../../image/Mysql/mysql-show-status.png)

![](../../image/Mysql/mysqladmin-show-status.png)



从上图结果中可以看到有很多都是很多的统计数据。不过这里主要看Com_select，Com_delete，Com_insert，

Com_update这些统计值，以此来评估此数据库查询操作多，还事插入删除更新操作多。

一些其他统计值：

```shell
Innodb_rows_read：执行select查询的行数
Innodb_rows_inserted: 执行inserted插入的行数
Innodb_rows_updated: 执行update更新的行数
Innodb_rows_deleted:执行delete操作删除的行数
Connections: 试图连接mysql服务器的次数
Uptime:服务器工作时间
Slow_queries:慢查询次数
```

## 2.定位效率较低的SQL

方式一：通过慢查询日志定位那些执行效率较低的SQL语句。

```shell
# 在启动mysql时，使用如下参数启动，mysql会写一个包含所有执行时间大于long_query_time秒的sql语句的日志文件.
--log-slow-queries[=file_name]
```

慢查询日志在查询结束以后才记录，所以在应用反应执行效率出现问题的时候查询慢日志并不能定位问题。

方式二：使用命令行定位问题。

```shell
# 使用此命令查看当前mysql在进行的线程，包括线程的状态，是否锁表，可以实时查看sql的执行情况，同时对一些锁表操作进行优化.
--> show processlist
```



## 3. EXPLAIN分析

通过Explain 或desc 查看sql语句执行计划，先看一个示例：

![](../../image/Mysql/explain-example1.png)

对每个列的内容简单说一下：

```shell
select_type:表示SELECT的类型，常见的取值有SIMPLE(简单表，即不适用表连接或子查询)，PRIMARY(主查询，即外层的查询)，UNION(UNION中的第二个或者后面的查询)，SUBQUERY(子查询中的第一个SELECT)
table:输出结果集的表
type:表示MYSQL在表中查找到所需行的方式，或者叫访问类型（有七种类型，下面进行介绍）
passible_keys:表示查询时可能使用的索引
key:表示实际使用的索引
key_len:使用的索引字段的长度
rows:扫描行的数量
Extra:执行情况的说明和描述，包含不适合在其他列中显示但是对执行计划非常重要的额外信息
```

type类型：

1, type=ALL，全表扫描。如上表所示。

2, type=index，索引全扫描，MySql遍历整个索引来查询匹配的行。

![](../../image/Mysql/select-type-index.png)

3, type=range，索引范围扫描，常见于<，<=，>，>= ，between等操作符号.

![](../../image/Mysql/select-type-range.png)

4, type=ref，使用非唯一索引扫描或唯一索引的前缀扫面，返回匹配某个单独值的记录行。

```shell
# 对表创建一个索引
mysql> create index idx_sname_1 on student (sname);
Query OK, 6 rows affected (0.11 sec)
Records: 6  Duplicates: 0  Warnings: 0
```

![](../../image/Mysql/select-type-ref.png)

5, type=eq_ref，类似ref，区别就在使用的索引唯一索引，对于每个索引键值，表中只有一条记录匹配；简单来说就是多表连接中使用primary key 和 unique index 作为关联条件

6，type=const/system，单表中最多有一个匹配行，查询起来非常迅速，所以这个匹配行中的其他列的值可以被优化器在当前查询中当作常量来处理，例如根据主键primary key 或者唯一索引 unqiue index进行查询。

![](../../image/Mysql/select-type-const.png)

第一个sname时unique index，第二个sid为主键。

7，type=null，mysql不用访问表或者索引，直接就能得到结果

![](../../image/Mysql/select-type-null.png)

### 3.1 explain extended

通过explain extended 加 show warnings可以查看sql在执行前优化器对其作了那些优化。

![](../../image/Mysql/explain-extended.png)

可以看到查询时的语句和开始有很大的不一样，像1=1直接变为了1。

## 4.show profile分析

通过profile，能够更清楚的了解SQL的执行过程。mysql从5.0.37开始增加了多show profiles 和show profile语句的支持。此功能默认时关闭的:

```shell
# 查看状态
mysql> select @@profiling;
+-------------+
| @@profiling |
+-------------+
|           0 |
+-------------+
1 row in set (0.00 sec)
# 打开状态
mysql> set @@profiling=1;
Query OK, 0 rows affected (0.00 sec)

# 再次查看
mysql> select @@profiling;
+-------------+
| @@profiling |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)
```

查看一个使用示例，查询一个Innodb表的数量:

![](../../image/Mysql/show-profile.png)

通过最后的show profile的输出，可以看出来查询中在各个阶段花费的时间。也可以从information表中查询.

```shell

mysql> select state,sum(duration) as total_r,round(100*sum(duration)/(select sum(duration) from information_schema.profiling where query_id=1),2) as pct_r,count(*) as calls,sum(duration)/count(*) as 'r/call' from information_schema.profiling where query_
id=1 group by state order by total_r desc;
+--------------------+----------+-------+-------+--------------+
| state              | total_r  | pct_r | calls | r/call       |
+--------------------+----------+-------+-------+--------------+
| freeing items      | 0.000038 | 28.57 |     1 | 0.0000380000 |
| starting           | 0.000030 | 22.56 |     1 | 0.0000300000 |
| Sending data       | 0.000026 | 19.55 |     1 | 0.0000260000 |
| Opening tables     | 0.000008 |  6.02 |     1 | 0.0000080000 |
| init               | 0.000006 |  4.51 |     1 | 0.0000060000 |
| statistics         | 0.000005 |  3.76 |     1 | 0.0000050000 |
| preparing          | 0.000004 |  3.01 |     1 | 0.0000040000 |
| Table lock         | 0.000003 |  2.26 |     1 | 0.0000030000 |
| cleaning up        | 0.000002 |  1.50 |     1 | 0.0000020000 |
| executing          | 0.000002 |  1.50 |     1 | 0.0000020000 |
| optimizing         | 0.000002 |  1.50 |     1 | 0.0000020000 |
| logging slow query | 0.000002 |  1.50 |     1 | 0.0000020000 |
| System lock        | 0.000002 |  1.50 |     1 | 0.0000020000 |
| end                | 0.000002 |  1.50 |     1 | 0.0000020000 |
| query end          | 0.000001 |  0.75 |     1 | 0.0000010000 |
+--------------------+----------+-------+-------+--------------+
15 rows in set (0.00 sec)
```

**注意:**sending data状态标识mysql线程开始访问数据行并把结果返回给客户端，而不仅仅时返回结果给客户端。由于在sending data状态下，mysql线程往往需要做大量的磁盘读取操作，所以经常是整个查询中耗时最长的状态。

在获取到最消耗时间的线程状态后，mysql支持进一步选择 all，cpu，block io，context switch，page faults等明细类型来查看mysql在使用什么资源上耗费了过高的时间，如：

![](../../image/Mysql/show-profile-all.png)

![](../../image/Mysql/show-profile-cpu.png)

如果喜欢查看源码，可以进一步查看对应的具体源码：

![](../../image/Mysql/show-profile-source.png)

## 5.打开trace

MySQL5.6之后提供了对SQL的跟踪trace，通过trace文件能够进一步了解为什么优化器选择A计划而不是选择B计划，帮助我们更好的理解优化器的行为。

使用方式：首先打开trace，设置格式为json，设置trace最大能够使用的内存大小，避免解析过程中因为默认内存过小而不能完整显示。

```shell
	# 打开配置  以及 设置内存大小
	mysql-> SET OPTIMIZER_TRACE='enable=on',END_MARKERS_IN_JSON=on;
	mysql-> SET OPTIMIZER_TRACE_MAX_MEM_SIZE=1000000;
	
	# 随便执行一条sql语句，以便后面查看
	mysql-> select * from user1,user2 where user1.id=user2.id and user1.id=1;
	
	# 最后检查INFORMATION_SCHEMA.OPTIMIZER_TRACE 就可以知道MySql是如何执行sql的。
	mysql->SELECT * from INFORMATION_SCHEMA.OPTIMIZER_TRACE;
```



## 6.索引优化

### 6.1 索引存储类型

MySQL目前提供了以下4中索引：

1.B-Tree索引：最常见的索引类型，大部分都是支持B树索引

2.HASH索引：只有Memory引擎支持，使用场景简单。

3.R-Tree索引(空间索引)：空间索引时MyISM的一个特殊索引类型，主要用于第地理空间数据类型，通常使用较少。

4.Full-text(全文索引)：全文检索也是MyISM的一个特殊索引类型，主要用于全文检索，InnoDB从mysql 5.6开始提供对全文索引的支持。

各种引擎对索引的支持情况:

![](../../image/Mysql/index-support.jpg)

Hash索引相对简单，只有Memory/Heap引擎支持Hash索引。Hash索引适用于Key-Value查询，通过Hash索引要比通过B-Tree索引查询更迅速；Hash索引不适用于范围查询，如：<,>,<=,>=等此类操作。如果使用memory/Heap引擎且where条件中不使用"=" 进行索引列，那么不会使用到索引。

Btree索引结构：

![](../../image/Mysql/BTressStruct.jpg)

### 6.2 使用索引的情况

1) 匹配全值(Match the full value)，对索引中所有列都指定具体的值，即使对索引中的所有列都有等值匹配的条件。

2) 匹配值的范围查询(match a range of values)，对索引的值能够进行范围查找。

3) 匹配最左前缀(Match a leftmost prefix)，仅仅使用索引中的最左边列进行查找。

如：在col1 + col2 + col3字段上添加联合索引，查询时能够被包含col1，col1+col2，col1+col3，col1+col2+col3等值的查询利用到，可是不能够被col2，col2+col3等查询利用到。

**最左匹配原则**可以算是B-Tree索引中使用的首要原则。

4) 

5)

6)

7)

8)

9)

10)

### 6.3 索引失效情况