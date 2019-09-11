# Spring-boot:repackage

功能介绍:

```shell
Repackages existing JAR and WAR archives so that they can be executed from the command line using java -jar. With layout=NONE can also be used simply to package a JAR with nested dependencies (and no main class, so not executable).
大意: 把 JAR 和 WAR 结构重新打包(repackage),使重新打包的jar包可以通过命令行直接运行。
```

```shell
# 5个Goals
spring-boot:repackage，默认goal。在mvn package之后，再次打包可执行的jar/war，同时保留mvn package生成的jar/war为.origin
spring-boot:run，运行Spring Boot应用
spring-boot:start，在mvn integration-test阶段，进行Spring Boot应用生命周期的管理
spring-boot:stop，在mvn integration-test阶段，进行Spring Boot应用生命周期的管理
spring-boot:build-info，生成Actuator使用的构建信息文件build-info.properties
```



## 1. 自定义classifier

```shell
<project>
  ...
  <build>
    ...
    <plugins>
      ...
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <executions>
          <execution>
            <id>repackage</id>
            <goals> # action
              <goal>repackage</goal>
            </goals>
            <configuration> #  添加 classifier
              <classifier>exec</classifier>
            </configuration>
          </execution>
        </executions>
        ...
      </plugin>
      ...
    </plugins>
    ...
  </build>
  ...
</project>
```



## 2. 自定义 repackage name

```shell
<build>
	#  定义的名字
    <finalName>my-app</finalName>
    <plugins>
      ...
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <executions>
          <execution>
            <id>repackage</id>
            <goals>
              <goal>repackage</goal>
            </goals>
          </execution>
        </executions>
        ...
      </plugin>
      ...
    </plugins>
    ...
  </build>
```

## 3.   exclude - dependency

```shell
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <configuration>
          <excludes>
            <exclude> # 去除某个依赖
              <groupId>com.foo</groupId>
              <artifactId>bar</artifactId>
            </exclude>
          </excludes>
        </configuration>
        ...
      </plugin>
```

```shell
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <configuration> # 去除groupId 为com.foo的所有jar包
          <excludeGroupIds>com.foo</excludeGroupIds>
        </configuration>
        ...
      </plugin>
```

## 4. 传递JVM参数

```shell
	<plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <configuration>
          <jvmArguments> # 指定jar包的启动虚拟机参数
            -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005
          </jvmArguments>
        </configuration>
        ...
      </plugin>
```

```shell
# 相当于命令指定如下参数
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005"
```

## 5. 设置环境变量

```shell
<plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <configuration> # ENV1=5000,ENV2=Some Text,ENV3=null,ENV4="",这些变量会设置
        			# 到系统变量(system properties)中
            <environmentVariables>
                <ENV1>5000</ENV1>
                <ENV2>Some Text</ENV2>
                <ENV3/>
                <ENV4></ENV4>
            </environmentVariables>
        </configuration>
        ...
      </plugin>
```

## 6. 跳过Test

```shell
 <properties>
    <skip.it>false</skip.it>
  </properties>
      <plugin>
       <groupId>org.apache.maven.plugins</groupId>
       <artifactId>maven-failsafe-plugin</artifactId>
       <configuration>
        <skip>${it.skip}</skip>
       </configuration>
      </plugin>
	 <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <executions>
          <execution>
            <id>pre-integration-test</id>
            <goals>
              <goal>start</goal>
            </goals>
            <configuration> # 跳过测试
              <skip>${skip.it}</skip>
            </configuration>
          </execution>
          <execution>
            <id>post-integration-test</id>
            <goals>
              <goal>stop</goal>
            </goals>
            <configuration>
              <skip>${skip.it}</skip>
            </configuration>
          </execution>
        </executions>
 </plugin>
```

## 7. 指定 active profiles

```shell
<plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <configuration>
          <profiles> # 指定激活的profile
            <profile>foo</profile>
            <profile>bar</profile>
          </profiles>
        </configuration>
        ...
      </plugin>
```

```shell
# 对应的命令
mvn spring-boot:run -Dspring-boot.run.profiles=foo,bar
```



## 8. Generate build information

```shell
<plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.1.8.RELEASE</version>
        <executions>
          <execution>
            <goals> # 生成 build-info.properties
              <goal>build-info</goal>
            </goals>
            <configuration>
              <additionalProperties>
                <encoding.source>UTF-8</encoding.source>
                <encoding.reporting>UTF-8</encoding.reporting>
                <java.source>${maven.compiler.source}</java.source>
                <java.target>${maven.compiler.target}</java.target>
              </additionalProperties>
            </configuration>
          </execution>
        </executions>
        ...
      </plugin>

# 此配置最终会生成一个文件build-info.properties文件,位置在META-INF/build-info.properties
```



## 9. layout(目前使用不是很清楚)

使用如下配置打包后，manifest内容如下:

```shell
# 配置
<build>
	<plugins>
		<plugin>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-maven-plugin</artifactId>
             <version>2.1.8.RELEASE</version>
		</plugin>
	</plugins>
</build>

```

```shell
# manifest文件内容
Manifest-Version: 1.0
Implementation-Title: gs-consuming-rest
Implementation-Version: 0.1.0
Archiver-Version: Plexus Archiver
Built-By: exihaxi
Implementation-Vendor-Id: org.springframework
Spring-Boot-Version: 2.1.8.RELEASE
Implementation-Vendor: Pivotal Software, Inc.
Main-Class: org.springframework.boot.loader.JarLauncher # springboot修改的entry
Start-Class: com.ericsson.ramltest.MyApplication  # 程序中主类 
Spring-Boot-Classes: BOOT-INF/classes/
Spring-Boot-Lib: BOOT-INF/lib/
Created-By: Apache Maven 3.5.0
Build-Jdk: 1.8.0_131
```

具体的Start-Class和layout有一定的关系:

```shell
    <plugin>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-maven-plugin</artifactId>
      <version>2.1.8.RELEASE</version>
      <configuration>
        <mainClass>${start-class}</mainClass>
        # 指定layout的值
        <layout>ZIP</layout>
      </configuration>
      <executions>
        <execution>
          <goals>
            <goal>repackage</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
```

```shell
# 不同layout的值,对应不同的Main-Class值
JAR : 即通常的可执行jar
Main-Class: org.springframework.boot.loader.JarLauncher

WAR :即通常执行war,需要的servlet容器依赖位于WEB-INF/lib-provied
Main-Class: org.springframework.boot.loader.warLauncher

ZIP :即DIR,类似于JAR
Main-Class: org.springframework.boot.loader.PropertiesLauncher

MODULE: 将所有的依赖库打包(scope为provide除外),但是不打包spring boot的任何launcher

NONE: 将所有的依赖库打包,但是不打包spring boot的任何launcher
```

后续需要深入了解下此layout具体的作用。

