# postgresql异步集群搭建

## 1. 环境介绍

| 主机          | 版本          |      |
| ------------- | ------------- | ---- |
| centos        | 7.6.181       |      |
| name2(master) | 192.168.30.15 |      |
| name3(slave1) | 192.168.30.16 |      |
| name4(slave2) | 192.168.30.17 |      |

## 2. 安装

```shell
# 安装rpm包
yum -y install https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm
# 客户端安装
yum -y install postgresql95
# server安装
yum -y install postgresql95-server
```



## 3. 初始化master

安装完成后，pg的安装目录如下：

```shell
/usr/pgsql-9.5/
```

### 1) 初始化数据库目录

```shell
./initdb -D /var/lib/pgsql/9.5/data -W
# 创建archive目录
mkdir pg_archive
chown -R  postgres:postgres pg_archive/                                                         
chmod 700 pg_archive/
```

### 2) 设置环境变量

```shell
# .bashrc
export PGDATA=/var/lib/pgsql/9.5/data/
```

### 3) 启停命令

```shell
# 检测db目录
/usr/pgsql-9.5/bin/postgresql95-check-db-dir ${PGDATA}
# 启动db
/usr/pgsql-9.5/bin/pg_ctl start -D ${PGDATA} -s -w -t 300
# 停止db
/usr/pgsql-9.5/bin/pg_ctl stop -D ${PGDATA} -s -m fast
# 重新加载
/usr/pgsql-9.5/bin/pg_ctl reload -D ${PGDATA} -s
```

### 4) 创建复制用户

```sql
create ROLE replica login replication encrypted password 'replica';
```

### 5) 修改配置文件 pg_hba.conf

```shell
host    replication     replica        192.168.30.15/34          md5
host    replication     replica        192.168.30.16/34          md5
host    replication     replica        192.168.30.17/34          md5
```



### 6) 修改配置文件postgresql.conf

```shell
listen_addresses = '*'
max_wal_senders = 6
wal_level = hot_standby
wal_keep_segments = 30
# Archive
archive_mode = on
archive_mode = 'test ! -f /opt/pg_archive/%f && cp %p /opt/pg_archive/%f'

```

修改完后 重启db

```shell
su postgres -c '/usr/pgsql-9.5/bin/pg_ctl stop -D $PGDATA'
su postgres -c '/usr/pgsql-9.5/bin/pg_ctl start -D $PGDATA'
```





## 4. 初始化slave

### 1) 从master备份数据

```shell
[root@name3 bin]# ./pg_basebackup -h name2 -U replica -W -Fp -Pv -X stream -R -D $PGDATA                                                           
Password: 
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
transaction log start point: 0/2000028 on timeline 1
pg_basebackup: starting background WAL receiver
39261/39261 kB (100%), 1/1 tablespace                                         
transaction log end point: 0/20000F8
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: base backup completed
```

### 2)  修改data目录属主

```shell
chown postgres:postgres -R data/
```



### 3) 修改配置

```properties
hot_standby = on
```



### 4) 查看生成的recovery.conf文件

```properties
standby_mode = 'on'
primary_conninfo = 'user=replica password=replica host=name2 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres'
```



### 5) 创建备份目录

```shell
mkdir -p /opt/pg_archive/
chown postgres:postgres /opt/pg_archive/
chown postgres:postgres -R /opt/pg_archive/
```



### 6)启动数据库

```shell
systemctl start postgresql-9.5
```

启动日志:

```shell
2021-07-19 10:24:51.507 CST >LOG:  entering standby mode
< 2021-07-19 10:24:51.510 CST >LOG:  redo starts at 0/3000060
< 2021-07-19 10:24:51.510 CST >LOG:  consistent recovery state reached at 0/3000108
< 2021-07-19 10:24:51.510 CST >LOG:  invalid record length at 0/3000140
< 2021-07-19 10:24:51.511 CST >LOG:  database system is ready to accept read only connections
< 2021-07-19 10:24:51.521 CST >LOG:  started streaming WAL from primary at 0/3000000 on timeline 1
```



##  5. 第二台slave配置

此操作步骤， 同第一台



## 6. 状态查看

### 1) 在master上查看slave的状态

```sql
postgres=# select * from pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 13240
usesysid         | 33517
usename          | replica
application_name | walreceiver
client_addr      | 192.168.30.16
client_hostname  | 
client_port      | 57166
backend_start    | 2021-07-19 10:24:51.517768+08
backend_xmin     | 
state            | streaming
sent_location    | 0/5015CA0
write_location   | 0/5015CA0
flush_location   | 0/5015CA0
replay_location  | 0/5015BF8
sync_priority    | 0
sync_state       | async
-[ RECORD 2 ]----+------------------------------
pid              | 13728
usesysid         | 33517
usename          | replica
application_name | walreceiver
client_addr      | 192.168.30.17
client_hostname  | 
client_port      | 59948
backend_start    | 2021-07-19 10:33:31.283859+08
backend_xmin     | 
state            | streaming
sent_location    | 0/5015CA0
write_location   | 0/5015CA0
flush_location   | 0/5015CA0
replay_location  | 0/5015BF8
sync_priority    | 0
sync_state       | async

/*
state:
	streaming  同步
	startup	   连接中
	catchup	   同步中
sync_priority: 同步优先级
	0:   表示异步
	1 ~ ? : 表示同步,数字越小优先级越高
sync_state:
	async:	异步
	sync:	同步
	potential: 当前是异步, 但是可以升级为同步
*/
```

可以看到是异步的操作

### 2) 查看是否是master

```sql
postgres=# select pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

-- 为true 表示为slave
```



## 7. 主备切换

### 1) 主机停止

```shell
# cmd
systemctl stop postgresql-9.5
su - postgres -c "/usr/pgsql-9.5/bin/pg_ctl stop -D $PGDATA"
```

### 2) 提升从库为主库(name3上执行)

```shell
su - postgres -c "/usr/pgsql-9.5/bin/pg_ctl promote -D $PGDATA"
```

提升操作完成后，会发现recovery.conf文件会变成 recovery.done.

### 3) name4 从库修改

修改name4从库的recovery.conf 文件，更新主机信息为 name3，重新启动。

```properties
standby_mode = 'on'
primary_conninfo = 'user=replica password=replica host=name3 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres'
recovery_target_timeline = 'latest'
```

### 4) name2修改recovery.conf 文件

重命名recovery.done文件为recovery.conf，并更新其中的主机信息，然后启动db，此时启动后的db就会变为新的备库添加到集群中.

```properties
recovery_target_timeline = 'latest'
standby_mode = on
primary_conninfo = 'user=replica password=replica host=name3 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres'
```

修改master的postgresql.conf 配置

```pro
hot_standby = on
```











