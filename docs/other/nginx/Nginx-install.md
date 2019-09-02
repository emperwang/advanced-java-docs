# nginx-install

1.安装依赖

```shell
yum -y install gcc zlib zlib-devel pcre-devel openssl openssl-devel
```



2.下载安装包

下载路径

```shell
http://nginx.org/download/
```

![](../../image/nginx/nginx1.png)

3.进入目录进行安装

```shell
./configure
```

![](../../image/nginx/configura-start.png)

![](../../image/nginx/configura-end.png)

```shell
make
```

![](../../image/nginx/make-start.png)

![](../../image/nginx/make-end.png)

```shell
make install
```

![](../../image/nginx/make-install.png)

4.进行一个简单的配置

```shell
vim /usr/local/nginx/conf/nginx.conf
```

![](../../image/nginx/conf.png)

5.启动

```shell
/usr/local/nginx/sbin/nginx 
```



6.测试

![](../../image/nginx/test.png)