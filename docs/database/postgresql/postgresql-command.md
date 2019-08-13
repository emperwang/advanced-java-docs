# Postgresql 命令行

## 1. 交互模式下的psql命令

```shell
# 这里列出了psql交互模式下的命令行,查看方式:命令行登录后输入: \?

# 通用命令
\copyright			显示postgesql使用和分发条款
\g	[file] or ;		执行查询(并将结果发送给文件或管道)
\gset	[prefix]	执行查询并将结果存储到psql变量中
\h	[名称]		  关于sql命令语法帮助,* 代表所有命令
\q				   退出psql
\watch	[SEC]		每隔SEC秒执行一次查询
# 查询缓冲区相关命令
\e	[file]  [line]	使用外部编辑器编辑查询缓冲区(或文件)
\ef [funcName [line]]  使用外部编辑器编辑函数定义
\p					显示查询缓冲区内容
\r					重置(清除)查询缓冲区
\w					将查询缓冲区写入到文件
# 输入输出相关命令
\copy	...			执行sql copy,将数据流发送到客户端主机
\echo	[字符串]	  将字符串写到标准输出
\i		文件		   从文件执行命令
\ir		file		与\i类似,但是在脚本执行时,认为目标文件的位置时当前脚本所在目录
\o		[文件]	   将所有查询结果发送到文件或管道
\qecho	[字符串]	  将字符串写入到查询输出流,该命令等效于\echo,区别是所有输出将写入由\o设置的输出通道
# 信息查询命令
(选项:S = 显示系统对象, + = 附加的详细信息)
\d[S+]				输出表,视图和序列列表
\d[S+]	名称		   描述表,视图,序列或索引
\da[S+]	[模式]	   输出聚合函数列表
\db[+]	[模式]	   输出表空间列表
\dc[S]	[模式]	   输出编码准换(conversion)列表
\dC		[模式]	   输出类型强制转换(cast)列表
\dd[S]	[模式]	   显示对象上的注释
\ddp	[模式]	   输出默认权限列表
\dD[S]	[模式]	   输出域列表
\det[+]	[模式]	   输出外部表列表
\des[+]	[模式]	   输出外部服务器列表
\deu[+]	[模式]	   输出用户映射列表
\dew[+]	[模式]	   输出外部数据封装器列表
\df[antw][S+]	[模式] 输出特定类型函数(a-聚合函数,n-常规函数,t-触发器函数,w-窗口函数)列表
\dF[+]	[模式]	   输出文本搜索配置列表
\dFd[+]	[模式]	   输出文本所有字典列表
\dFp[+]	[模式]	   输出文本搜索解析器列表
\dFt[+]	[模式]	   输出文本搜索模板列表
\dg[+]	[模式]	   输出角色列表
\di[S+]	[模式]	   输出索引列表
\dl(小写字母l,不是i)	输出大对象列表
\dL[S+]	[模式]	   输出过程语言列表
\dm[S+]	[模式]	   输出物化视图列表
\dn[S+]	[模式]	   输出schema列表
\do[S]	[模式]	   输出运算符列表
\dO[S+]	[模式]	   输出排序规则列表
\dp		[模式]	   输出表,视图和序列访问权限列表
\drds	[模式1]  [模式2]	输出每个database的角色设置列表
\ds[S+]	[模式]		输出序列列表
\dt[S+]	[模式]		输出表列表
\dT[S+]	[模式]		输出数据类型列表
\du[S+]	[模式]		输出角色列表
\dv[S+]	[模式]		输出视图列表
\dE[S+]	[模式]		输出外部扩展列表
\dx[+]	[模式]		输出扩展列表
\dy		[模式]	    输出时间触发器列表
\l[+]				 输出数据库列表
\sf[+]	FUNCName	  显示函数定义
\z		[模式]	    和\dp功能相同

# 格式化相关命令
\a					在非对齐输出模式和对齐输出模式之间切换
\C	[字符串]		  设置表标题,或如果没有,则不设置
\f	[字符串]		  显示或设置非对齐查询输出的字段分隔符
\H					切换HTML输出格式(当前关闭) 
\pset	Name	[value] 
					设置表输出选项(name的可选项有format,border,expanded
					fieldsep,fieldsep_zero,footer,null,numericlocale,
					recordse,tuples_only,title,tableattr,pager)
\t	[on | off]		仅显示行(当前关闭)
\T	[字符串]		设置html
\x	[on | off]		切换扩展输出(当前关闭)
# 连接相关命令
\c	[BDNAME | user | host | port]   连接到新的database
\connect	[BDNAME | user | host | port]   连接到新的database
\encoding	[编码名称]	显示或设置客户端编码
\password	[username]	安全的为用户更改密码
\conninfo				显示当前连接的相关信息

# 操作系统相关命令
\cd	[目录]			  更改当前工作目录
\setenv	NAME	[VALUE]	设置或取消设置环境变量
\timing	[on | off]		切换命令计时开关(当前关闭)
\!	[command]			在shell中执行命令或打开一个交互shell

# variables --变量
\prompt	[text]	name	提醒用户设置内部变量
\set	[name [value]]	设置内部变量,或列出没有参数的变量
\unset 	name			unset(delete) 内部变量
# 大对象
\lo_export	LOBOID	FILE		
\lo_inport	FILE	[COMMENT]
\lo_list	
\lo_unlink	LOBOID			
```



## 2. 非交互模式下的psql命令

```shell
useage:
psql [选项]...	[databse名称 [用户名]]

# 通用选项
-c,--command=命令			仅运行单个命令(sql或内部命令),然后退出
-d,--dbane=数据库名称	  要连接到的数据库的名称
-f,--file=文件名		   从文件执行命令,然后退出
-l,--list				 列出可用的数据库,然后退出
-v,--set=,--variable=名称=值	 将psql变量name设置为value
-X,--no-psqlrc			 不读取启动文件(~/.psqlrc)
-1("one"),--single-transaction	将此命令文件作为单一事务执行
--help					显示帮助信息
--version				显示版本信息
# 输入和输出选项
-a,--echo-all			回显所有来自脚本的输入
-e,--echo-queries		回显发送给服务器的命令
-E,--echo-hidden		显示内部命令生成的查询
-L,--log-file=文件名	  将会话日志发送给文件
-n,--no-readline		禁用增强命令行编辑功能
-o,--output=fileName	将查询结果发送给文件(或管道)
-q,--quiet				以静默模式执行(不显示消息,仅显示查询输出)
-s,--single-step		单步模式(每个查询均需确认)
-S,--single-line		单行模式(SQL命令不允许跨行)

# 输出格式选项
-A,--no-align				非对齐表输出模式
-F,--field-separator=字符串   设置字段分隔符(默认为 "|")
-H,--html					html表输出
-P,--pset=var[=arg]			  将打印选项var设置为arg
-R,--record-separator=字符串	设置记录分隔符(默认是换行符)
-t,--tuples-only			  仅打印行
-T,--table-attr=文本			 设置html表标记属性
-x,--expanded				   打开扩展表输出
-z,--field-separator-zero		将字段分隔符设置为零字节
-0('零'),--record-separator-zero	将记录分隔符设置为零字节

# 连接选项
-h,--host=主机名		数据库服务器主机或套接字目录
-p,--port=端口		数据库服务器杜那口
-U,--username=用户名	用户名
-w,--no-password		永远不提示输入密码
-W,--password			强制要求输入密码
```



## 3.pg_restore

```shell
此命令可以从pg_dump创建的存档中恢复一个postgresql数据库
useage:
	pg_restore	[选项]...  [文件名]

# 通用选项
-d,--dbname=name	连接的数据库名称
-f,--file=文件名	  读取的文件
-F,--format=c|d|t	 备份文档格式
-l,--list			打印存档的汇总目录
-v,--verbose		详细信息模式
-V,--version		版本
-?,--help			帮助信息

# 恢复控制选项
-a,--data-only			仅恢复数据,不回复schema
-c,--clean				在重新创建数据库对象之前清除数据库
-C,--create				创建目录数据库
-e,--exit-on-error		恢复期间发送错误时推出,若不设定则默认继续恢复
-I,-index=name			恢复命令索引
-j,--jobs=num			使用多个并行作业进行恢复
-L,--user-list=fileName	将此文件的目录用于选择输出或对输出进行排序
-n,--schema=name		仅恢复此schema中的对象
-O,--no-owner			跳过对象所有权的恢复
-P,--function=name(args)	恢复命名函数
-s,--schema-only		仅恢复schema,不恢复数据
-S,--superuser=name		用于禁用触发器的超级用户用户名
-t,--table=name			恢复命名表
-T,--trigger=name		恢复命名触发器
-x,--no-privileges		跳过访问特权(grant/revoke)的恢复
-1,--single-transaction	作为单个事务恢复
--disable-triggers		在仅恢复数据期间禁用触发器
--no-data-for-failed-tables	如果表创建失败,则不对其进行数据恢复
--no-security-labels	不恢复安全标签
--no-tablespaces		不恢复表空间分配
--section=section       恢复命令部分(包括三个部分:pre-data,data和post-data.data部分包含记录数据,
					大对象以及序列的值;post-data部分包含索引,触发器,规则和约束;
					pre-data包含此外其他所有对象的定义)
```



## 4. pg_dumpall

```shell
此命令可以将postgresql数据库集群中的所有数据都提取到一个sql脚本中
usage:
	pg_dumpall [选项]..
# 通用选项
-f,--file=fileName		输出文件名
--lock-wait-timeout=timeout	等待表锁超时后操作失败
--help					显示此帮助信息并退出
--version				输出版本号并退出

# 控制输出额你容选项
-a,--data-only			仅转储数据,不转储schema
-c,--clean				重新创建数据库之前清除(删除)数据库
-g,--global-only		仅转储全局对象,而不转储数据库
-o,--oids				在转储中包含oids
-O,--no-owner			以纯文本格式跳过对象所有权的恢复
-r,--roles-only			仅仅\转储角色,不转储数据库和表空间	
-s,--schema-only		仅转储schema,而不转储数据
-S,--superuser=name		要在转储中使用的超级用户用户名
-t,--tablespaces-only	仅转储表空间,而不转储数据库和角色
-x,--no-privileges		不转储特权(grant/revoke)
--binary-upgrade		仅供升级工具使用
--column-inserts		以带有列名的insert命令的形式转储数据
--disable-dollar-quoting	禁用美元引用,而是使用sql标准引号
--disable-triggers		在仅恢复数据期间禁用触发器
--inserts				以insert命令(而非copy命令)的形式转储数据
--no-security-labels	不转储安全标签分配
--no-tablespaces		不转储表空间分配
--no-unloadded-table-data	不转储不记录wal日志的表的数据
--quote-all-identifiers		所有标识符加引号,即使不是关键字也加
-use-set-session-authorization 使用set session authorization命令代替
					alter owner命令设置所有权

# 连接选项
-d,--dbname=CONNSTR	使用连接连接串连接
-h,--host=主机名		主机名
-l,--databse=dbname	替代默认数据库
-p,--port=端口		端口
-U,--username=用户名
-w,--no-password	不提示输出密码
-W,--password		强制要求输入密码
--role=roleName		在转储之前执行set role命令
```



## 5. pg_dump

```shell
此命名把一个数据库导出为一个文件后其他格式.
usage:
pg_dump	[option]...	[dbname]
# 通用选项
-f,--file=fileName			输出的文件名
-F,--format=c|d|t|p			文件格式(custom,directory,tar,plain-text(default))
-j,--jobs=num				多线程并行执行
-v,--verbose				
-V,--version
-Z,--compress=0-9			压缩
--lock-wait-timeout=TIMEOUT
-?,--help

# 控制输出选项
-a,--data-only
-b,--blobs					大对象也进行导出
-c,--clean
-C,--create
-E,--encoding=encoding
-n,--schema=schema			仅导出设置的schema
-N,--exclude-schema=schema	不导出执行的schema
-o,--oids					导出时包含oids
-O,--no-owner				
-s,--schema-only			仅导出schema,不导出数据
-S,--superuser=name			在plain-text格式导出时使用的超级用户
-t,--table=table			仅导出指定的table
-T,--exclude-table=table	不导出指定的table
-x,--no-privileges			不导出权限(grant/revoke)
--binary-upgrade			升级
--diable-doller-quoting
--disable-triggers
--exclude-table-data=table	不导出指定的table的数据
--if-exists				   执行droptable时使用if-exists
--inserts				  导出的数据使用insert命令格式
--no-security-labels
--no-synchronized-snapshots	并行任性不使用synchronized snapshots
--no-tablespaces			不导出分配的tablespace
--no-unlogged-table-data	不导出unlogged表数据
--quote-all-identifiers		不是关键字的都使用引号括起来
--section=section			导出指定的section
--serializable-deferrable	wait until the dump can run without anomalies
--use-set-session-authorization 使用 set session authorization命令代替 alter owner

# 连接选项
-d,--dbname=dbname
-h,--host=hostName
-p,--port=port
-U,--userName=name
-w,--no-password
-W,--password
--role=roleName
```



## 6.pg_basebackup

```shell
对运行的postgresql-server执行一个基本的备份
usage:
pg_basebackup [option]
# 控制输出选项
-D,--pgdata=directory				备份目录指定
-F,--format=p|t					导出格式(plain(default),tar)
-r,--max-rate=rate				最大导出速率(k,m)
-R,--write-recovery-conf		写 recovery.conf 进行复制
-T,--tablespace-maping=OLDDIR=NEWDIR 把OLDDIR的tablespace重新在NEWDIR分配
-x,--xlog						fetch模式备份wal文件
-X,--xlog-method=fetch|stream	  备份wal使用的方法
	--xlogdir=xlgdir			transaction log 目录
-z,--gzip
-Z,--compress=0-9

# 通用选项
-C,--checkpoint=fast|spread		设置 fast 或 spread 恢复点
-l,--label=label				设置backup 标签
-P,--progress					显示处理信息
-v,--verbose					输出详细信息
-V,--version
-?,--help

# 连接选项
-d,--dbname=connstr
-h,--host=hostName
-p,--port=port
-s,--status-interval=interval
-U,--username=name
```



