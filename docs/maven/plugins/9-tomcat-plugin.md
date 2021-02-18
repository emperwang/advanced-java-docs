# tomcat plugin

## 1.添加依赖

目前tomcat依赖只支持tomcat6和tomcat7，更新较慢。

```java
	<plugins>
        <plugin>
          <groupId>org.apache.tomcat.maven</groupId>
          <artifactId>tomcat6-maven-plugin</artifactId>
          <version>2.2</version>
        </plugin>
        <plugin>
          <groupId>org.apache.tomcat.maven</groupId>
          <artifactId>tomcat7-maven-plugin</artifactId>
          <version>2.2</version>
        </plugin>
      </plugins>
```



## 2.启动

在pom.xml文件所在目录使用如下命令进行启动:

```shell
## 启动
mvn tomcat7:run
## 停止
mvn tomcat7:stop
## 重新部署
mvn package tomcat6/7:redeploy
mvn war:exploded tomcat6/7:redeploy
mvn tomcat6/7:redeploy
mvn war:inplace tomcat6/7:redeploy

## tomcat7 可用的goals：
exec-war-only, deploy-only, redeploy-only, help, shutdown, run-war-only, standalone-war-only, run, deploy, standalone-war, undeploy, run-war, redeploy, exec-war

### tomcat6 特有
## 列出当前的session
mvn tomcat6:sessions
## 列出当前服务的JNDI资源
mvn tomcat6:resources
## 列出当前tomcat的信息 以及JVM peoperties
mvn tomcat6:info
## 列出当前已经部署的application
mvn tomcat6:list
```

