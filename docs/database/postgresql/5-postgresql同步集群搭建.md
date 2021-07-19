# postgresql 同步集群搭建

## 1.  测试环境

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

### 6) 配置文件

修改配置文件 postgresql.conf

```properties
listen_addresses = '*' 
port = 5432
max_connections = 100
synchronous_commit = on
# 其中master为appname2,slave1 为 appname3, slave2 为 appname4
synchronous_standby_names = 'appname3,appname4'
wal_level = hot_standby
max_wal_senders = 6 
wal_keep_segments = 30
archive_mode = on
archive_command = 'test ! -f /opt/pg_archive/%f && cp %p /opt/pg_archive/%f'

# for slave
hot_standby = on
```



## 4. slave配置

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

因为是从master复制过来的，所以配置和master是一样的，只需要修改几个即可：

slave1 配置

```properties
hot_standby = on
synchronous_standby_names = 'appname2,appname4'
```

slave2 配置

```properties
hot_standby = on
synchronous_standby_names = 'appname3,appname4'
```



### 4) 查看生成的recovery.conf文件

slave1 配置

```properties
standby_mode = 'on'
primary_conninfo = 'user=replica password=replica host=name2 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres application_name=appname3'
recovery_target_timeline = 'latest'
```

slave2 配置

```properties
standby_mode = 'on'
primary_conninfo = 'user=replica password=replica host=name2 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres application_name=appname4'
recovery_target_timeline = 'latest'
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



## 5. 检测状态

### 1) 查看集群状态

```shell
-[ RECORD 1 ]----+------------------------------
pid              | 29121
usesysid         | 33517
usename          | replica
application_name | appname3
client_addr      | 192.168.30.16
client_hostname  | 
client_port      | 57198
backend_start    | 2021-07-19 15:22:17.611416+08
backend_xmin     | 
state            | streaming
sent_location    | 0/A000250
write_location   | 0/A000250
flush_location   | 0/A000250
replay_location  | 0/A000250
sync_priority    | 1
sync_state       | sync
-[ RECORD 2 ]----+------------------------------
pid              | 29130
usesysid         | 33517
usename          | replica
application_name | appname4
client_addr      | 192.168.30.17
client_hostname  | 
client_port      | 60136
backend_start    | 2021-07-19 15:22:25.503399+08
backend_xmin     | 
state            | streaming
sent_location    | 0/A000250
write_location   | 0/A000250
flush_location   | 0/A000250
replay_location  | 0/A000250
sync_priority    | 2
sync_state       | potential
```

此时只有master是可读写的，其中slave为只读状态。



## 6. 主备切换

### 1) 主机停止

```shell
systemctl stop postgresql-9.5
```



### 2) recovery.conf文件配置

name2配置：

```properties
recovery_target_timeline = 'latest'
standby_mode = on
primary_conninfo = 'user=replica password=replica host=name3 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres application_name=appname2'
```

name3配置：

name3即将要升级为master，不需要修改

name4配置：

```properties
standby_mode = 'on'
primary_conninfo = 'user=replica password=replica host=name3 port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres application_name=appname4'
recovery_target_timeline = 'latest'
```



### 3) name2配置修改

```shell
# 添加配置
hot_standby=on
```



### 4) name3 升级

```shell
su - postgres -c "/usr/pgsql-9.5/bin/pg_ctl promote -D $PGDATA"
```



### 5) 启动

```shell
systemctl start postgresql-9.5
```



### 6) 检测状态

```shell
-[ RECORD 1 ]----+------------------------------
pid              | 11623
usesysid         | 33517
usename          | replica
application_name | appname4
client_addr      | 192.168.30.17
client_hostname  | 
client_port      | 58996
backend_start    | 2021-07-19 15:40:36.621843+08
backend_xmin     | 
state            | streaming
sent_location    | 0/B000140
write_location   | 0/B000140
flush_location   | 0/B000140
replay_location  | 0/B000140
sync_priority    | 2
sync_state       | potential
-[ RECORD 2 ]----+------------------------------
pid              | 11624
usesysid         | 33517
usename          | replica
application_name | appname2
client_addr      | 192.168.30.15
client_hostname  | 
client_port      | 60476
backend_start    | 2021-07-19 15:40:46.565347+08
backend_xmin     | 
state            | streaming
sent_location    | 0/B000140
write_location   | 0/B000140
flush_location   | 0/B000140
replay_location  | 0/B000140
sync_priority    | 1
sync_state       | sync
```

可以看到appname2和appname4已经变为从机.







