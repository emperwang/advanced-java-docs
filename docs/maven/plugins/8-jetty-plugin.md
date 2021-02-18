[TOC]

# plugin 

## 1.导入依赖

```java
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.22.v20191022</version>
</plugin>
```



##2. support goals

```shell
$ mvn jetty:deploy-war
This goal is used to run jetty with a pre-assembled war.

$ mvn jetty:effective-web-xml
This goal runs the jetty quickstart feature on an unassembled webapp in order to generate a comprehensive web.xml that combines all information from annotations, webdefault.xml and all web-fragment.xml files.
简单说：就是此goal会把指定的xml文件进行整合

$ mvn jetty:help
查看帮助

$ mvn jetty:run
启动项目。此会并行的进行编译，并且启动后，会定时扫描修改的文件，并更新。

$ mvn jetty:run-distro
This goal is used to deploy the unassembled webapp into a jetty distribution.

$ mvn jetty:run-exploded
This goal is used to assemble your webapp into an exploded war and automatically deploy it to Jetty.
人话：会打包项目成war包，并加载到jetty进行运行。

$ mvn jetty:run-forked
This goal is used to deploy your unassembled webapp into a forked JVM.
运行在一个新的JVM。

$ mvn jetty:run-war
This goal is used to assemble your webapp into a war and automatically deploy it to Jetty.

$ mvn jetty:start
类似于run，区别：
 EXCEPT that it is designed to be bound to an execution inside your pom, rather than being run from the command line.
 还有就是命令行运行时，需要确定包已经存在jetty中。

$ mvn jetty:stop
停止jetty实例。
```

## 3. 常用的配置

```shell
## configuration节点 的配置
<configureation>
jettyXml: 可选的.	设置Jetty xml文件的位置
scanIntervalSeconds:默认是10.设置扫面文件的间隔
reload: 默认自动加载,默认值:automatic。 是否重新加载.
dumpOnStart:可选的,默认是false. 如果设置为true,jetty会在启动时dump出来server的结构 
loginServices:可选的. 设置用户登录
requestLog:可选的. 请求log
server:可选的.
stopPort:可选的. 监听停止命令的端口
stopkey:可选的. 停止的命令,收到此命令则停止
systemProperties:可选的. 设置系统变量
systemPropertiesFile:可选的. 从文件中加载变量
skip: 默认是false。  ????
useProvidedScope:默认是false. If true, the dependencies with <scope>provided</scope> are placed onto the container classpath.
excludedGoals:可选的. 在此项目下排除一些goals.
</configureation>
## webapp 节点的配置
<webApp>
contextPath: 设置contextpath,默认是/
descriptor: web.xml文件的位置
defaultsDescriptor: webdefault.xml文件位置
overrideDescriptor: web.xml文件位置,可以使用此配置进行replace会add configuration
tempDirectory: jetty用来expand或拷贝jars,jsp编译的地方.默认是${project.build.outputDirectory}/tmp.
baseResource:指定jetty server的静态资源位置. 默认是 src/main/webapp
resourceBases: 指定静态资源的位置的baseResouecs directory,可以指定多个目录
baseAppFirst: 默认是true.
containerIncludeJarPattern: 设置jar包的正则. 默认:表达式: .*/javax.servlet-[^/]*\.jar$|.*/servlet-api-[^/]*\.jar$|.*javax.servlet.jsp.jstl-[^/]*\.jar|.*taglibs-standard-impl-.*\.jar
webInfIncludeJarPattern:默认是匹配所有在WEB-INF/lib目录下的jar包.也可以使用此配置进行配置正则
</webApp>
```

命令行参数:

```shell
-Djetty.skip : 使用skip
-Djetty.http.port=9999 :指定端口
mvn jetty:help -Ddetail=true  -Dgoal=<goal name>  # 查看某个goal的帮助
```



example:

```java
<plugin>
                <groupId>org.eclipse.jetty</groupId>
                <artifactId>jetty-maven-plugin</artifactId>
                <version>9.4.22.v20191022</version>
                <configuration>
                    <scanIntervalSeconds>10</scanIntervalSeconds>
                    <!--<scanClassesPattern></scanClassesPattern>
                    <scanTargetPatterns></scanTargetPatterns>
                    <scanTargets></scanTargets>
                    <scanTestClassesPattern></scanTestClassesPattern>
                    <contextXml></contextXml>-->
                    <reload>automatic</reload>
                    <!--<stopKey></stopKey>
                    <stopPort></stopPort>-->
                    <systemProperties>
                        <systemProperties>
                            <name>test</name>
                            <value>testVale</value>
                            <name>test1</name>
                            <value>test1value</value>
                        </systemProperties>
                    </systemProperties>
                    <!--fileExample: test=testValue -->
                    <!--<systemPropertiesFile>/filepath</systemPropertiesFile>-->
                </configuration>
            </plugin>
```



```java
    <plugin>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>jetty-maven-plugin</artifactId>
      <version>9.4.22.v20191022</version>
      <configuration>
 ## 源码目录    <webAppSourceDirectory>${project.basedir}/src/staticfiles</webAppSourceDirectory>
        <webApp>
        ## web配置
          <contextPath>/</contextPath>
          <descriptor>${project.basedir}/src/over/here/web.xml</descriptor>
          <jettyEnvXml>${project.basedir}/src/over/here/jetty-env.xml</jettyEnvXml>
        </webApp>
        <classesDirectory>${project.basedir}/somewhere/else</classesDirectory>
        <scanClassesPattern>
          <excludes>  ## 不包含的文件
             <exclude>**/Foo.class</exclude>
          </excludes>
        </scanClassesPattern>
        <scanTargets>  ## 目标目录
          <scanTarget>src/mydir</scanTarget>
          <scanTarget>src/myfile.txt</scanTarget>
        </scanTargets>
        <scanTargetPatterns>
          <scanTargetPattern> ## targer的正则
            <directory>src/other-resources</directory>
            <includes>
              <include>**/*.xml</include>
              <include>**/*.properties</include>
            </includes>
            <excludes>
              <exclude>**/myspecial.xml</exclude>
              <exclude>**/myspecial.properties</exclude>
            </excludes>
          </scanTargetPattern>
        </scanTargetPatterns>
      </configuration>
    </plugin>
```



```java
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.22.v20191022</version>
  <configuration>
    <stopPort>9966</stopPort>  # 监听停止的端口
    <stopKey>foo</stopKey>  # 停止的命令,也就是server接收到foo,则停止
    <stopWait>10</stopWait> 
 // The maximum time in seconds that the plugin will wait for confirmation that Jetty has stopped. 
  </configuration>
</plugin>
```



