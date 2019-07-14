# Docker-compose

## 常用命令

```shell
# 1. 构建镜像
docker-compose build 
--pull  : 可以在构建过程中，总是从远程仓库拉取依赖的基础镜像
--force-rm：在构建镜像前，移除所有基于此文件生成的镜像
--nocache：可以让构建镜像的过程不适用构建缓存
```

```shell
# 2.创建项目内存
#可以让docker-compose根据项目配置文件创建响应的容器。在创建容器的过程中，docker compose会自动结局容器之间的依赖，完成对数据卷，网络等模块的配置，并且可以继续宁容器连接和端口映射等操作
docker-compose create
--force-create：重新创建已存在于docker中的容器

```

```shell
# 3.运行项目
# 启动docker-compose定义的容器
docker-compose start 
docker compose start nginx php mysql
```

```shell
# 4.组合运行
# 可以说,组名命令运行能够通过一条命令完成整个项目的运行,
docker-compose up
-d: 可以让docker compose项目以后台方式运行.默认情况下,会在前台运行
--force-create: 可以让docker compose重新创建已经存在于docker中的容器
--build: 可以让docker compose构建容器所需的镜像,即使这些镜像存在
```

```shell
# 5.项目停止
docker-compose stop
--timeout: 可以设置需要停止容器在停止过程中的等待超时时间
```

```shell
# 6.删除项目
# 可以删除docker compose创建的容器
docker-compose rm
--force 强制删除
-v 可以同时判断容器使用的数据卷是否还存在引用,没有其他容器引用时,数据卷会一并删除
-all 可以通过让docker composer run命令启动的容器也会被删除
```

```shell
# 7.组合结束
# 可以让docker compose项目所有通过docker-compose up启动的容器停止
docker-compose down
--remove-orphans 可以删除未被docker compose配置文件定义的容器
```

```shell
# 8.获取服务日志
# 接收docker compose配置中的服务名称,如果一个服务生成了多个容器,则所有容器输出会合并显示.同时也能够给出多个服务名称,而且这写服务的输出也会合并显示
docker-compose logs <service>
```



## 配置文件

```yaml
version: '2'
service:
	db:
		image:mysql:5.7
		volumes:
			-"./.data/db:/var/lib/mysql"
		enviroment:
			MYSQL_ROOT_PASSWORD:
			MYSQL_DATABASE:
			MYSQL_USER:
			MYSQL_PASSWORD:
	wordpress:
		build:./wordpress
		links:
			-db
		ports:
			-"8000:80"
		enviroments:
			WORDPRESS_DB: db:3306
			WORDPRESS:DB_PASSWORD: wordpress
```

