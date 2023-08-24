# Maven Resources Plugins

此插件的功能是什么呢？直接看一下官方的解释吧:

```shell
The Resources Plugin handles the copying of project resources to the output directory. There are two different kinds of resources: main resources and test resources. 
大意: Resources Plugin 是把项目中资源文件拷贝到输出文件的。一般项目中有两种资源文件:main resources(对应src/main/resources) 和 test resources(对应 test/resources).
```

其他就先不解释了，咱们这里主要说其用法。

一般资源在pom中的配置位置如下:

```shell
<build>
        <finalName>fcaps-controller</finalName>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <includes>
                    <include>mapper/**/*.xml</include>
                    <include>logback-spring.xml</include>
                    <include>banner.txt</include>
                    <include>static/**</include>
                    <include>templates/**</include>
                </includes>
            </resource>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
                <targetPath>config</targetPath>
                <includes>
                    <include>application.yml</include>
                    <include>application-${profileActive}.yml</include>
                    <include>**/*.properties</include>
                </includes>
            </resource>

            <resource>
                <directory>src/main/bin</directory>
                <filtering>true</filtering>
                <targetPath>bin</targetPath>
                <includes>
                    <include>*.sh</include>
                </includes>
            </resource>

            <resource>
                <directory>src/main/logs</directory>
                <targetPath>logs</targetPath>
                <includes>
                    <include>*.log</include>
                </includes>
            </resource>
        </resources>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-resources-plugin</artifactId>
                <version>3.1.0</version>
            </plugin>
        </plugins>
    </build>
```



## 1.把指定的资源拷贝到jar中

```shell
<resource>
    <directory>src/main/resources</directory>
    <includes> # 此处没有指定输出目录，就会出处到jar中
        <include>mapper/**/*.xml</include>
        <include>logback-spring.xml</include>
        <include>banner.txt</include>
        <include>static/**</include>
        <include>templates/**</include>
    </includes>
</resource>
```



## 2.把指定的资源拷贝到指定目录中

**注意：**当拷贝https证书等文件时，一定要把 filtering 设置为 false，否则会破坏证书文件

```shell
<resource>
    <directory>src/main/resources</directory>  # 指定操作那里的配置文件
    <filtering>true</filtering> # 过滤,此操作会把配置文件中的变量进行替换
    <targetPath>config</targetPath> # 把下面includes中的文件拷贝到config目录下
    							# 默认config目录是在  target/classes/config
    <includes>
        <include>application.yml</include>
        <include>application-${profileActive}.yml</include>
        <include>**/*.properties</include>
    </includes>
</resource>
```

```shell
<resource>
    <directory>src/main/bin</directory> # 指定要操作的配置文件位置
    <filtering>true</filtering> # 是否替换配置文件中的变量
    <targetPath>bin</targetPath># 输出目录,target/classes/bin
    <includes>
    	<include>*.sh</include>
    </includes>
</resource>

<resource>
    <directory>src/main/logs</directory>
    <targetPath>logs</targetPath>
    <includes>
    	<include>*.log</include>
    </includes>
</resource>
```

## 3. 指定配置文件编码

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-resources-plugin</artifactId>
            <version>3.1.0</version>
            <configuration>
              <encoding>UTF-8</encoding> # 指定编码
            </configuration>
          </plugin>
        </plugins>
        ...
      </build>
      ...
    </project>
```



## 4.拷贝资源

```shell
      <plugin>
        <artifactId>maven-resources-plugin</artifactId>
        <version>3.1.0</version>
        <executions>
          <execution>
            <id>copy-resources</id>
            <!-- here the phase you need -->
            <phase>validate</phase>
            <goals>
              <goal>copy-resources</goal>
            </goals>
            <configuration># 输出的目录
              <outputDirectory>${basedir}/target/extra-resources</outputDirectory>
              <resources>          
                <resource> # 要拷贝的资源
                  <directory>src/non-packaged-resources</directory>
                  <filtering>true</filtering>
                </resource>
              </resources>              
            </configuration>            
          </execution>
        </executions>
      </plugin>
```



## 5. 二进制过滤

对指定的尾缀文件不进行过滤。下面所示是对尾缀是 .pdf  .gif 文件不进行过滤

```shell
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-resources-plugin</artifactId>
        <version>3.1.0</version>
        <configuration>
          <nonFilteredFileExtensions>
            <nonFilteredFileExtension>pdf</nonFilteredFileExtension>
            <nonFilteredFileExtension>gif</nonFilteredFileExtension>
          </nonFilteredFileExtensions>
        </configuration>
      </plugin>
```


## 6. 定制资源过滤器
```shell

```

## 7. 转义过滤器(Escape)

```shell
This means expression { } and @ @ preceded will replace by the expression : \${java.home} -> ${java.home}.
简单点说，就是配置文件中原来需要替换的变量，不会进行替换，如上所示:
${java.home}变量就会输出  ${java.home}
```

```shell
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-resources-plugin</artifactId>
    <version>3.1.0</version>
    <configuration>
        <escapeString>\</escapeString>
    </configuration>
</plugin>
```



## 8. excludes

```shell
<resource>
    <directory>src/my-resources</directory>
    <excludes> # 指定不会包含的配置文件
        <exclude>**/*.bmp</exclude>
        <exclude>**/*.jpg</exclude>
        <exclude>**/*.jpeg</exclude>
        <exclude>**/*.gif</exclude>
    </excludes>
</resource>
```




























































