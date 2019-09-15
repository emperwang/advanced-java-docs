# Maven Assembly Example

下面列举一些示例，作为功能参考。

## 1. filter的作用

```shell
File filtering is used to substitute variable fields from inside a file to their represented values. For the Assembly Plugin, and most Maven filtering procedures, these variables are enclosed between ${ and }. For example, before a file is filtered, it contains ${project.artifactId}. But after filtering is complete, a new file is created with the project's artifactId substituting ${project.artifactId} and that this new file is used instead of the original one.

大意:过滤文件是把文件中变量替换为其真正代表的值. 对于assembly插件来说,大部分的过滤产品,他们的变量都是用 ${} 把变量括起来. 例如:在一个文件被过滤前,它包含 ${project.artifatId}. 当替换完成后,一个使用 项目的artifactId 把变量${project.artifactId}替换的新文件被创建,并替换原来的文件.
```

```shell
# 存储变量的文件
src/assembly/filter.properties
# 文件内容
variable1=value1
variable2=value2
```

```shell
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>distribution</id>
      <formats>
        <format>jar</format>
      </formats>
      <files>
        <file>
          <source>README.txt</source>  # 要包含的文件
          <outputDirectory>/</outputDirectory>
          <filtered>true</filtered>  # 对其进行过滤
        </file>
        <file>
          <source>LICENSE.txt</source>
          <outputDirectory>/</outputDirectory>
        </file>
        <file>
          <source>NOTICE.txt</source>
          <outputDirectory>/</outputDirectory>
          <filtered>true</filtered>
        </file>
      </files>
    </assembly>
```

另一种方式:

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>distribution</id>
      <formats>
        <format>jar</format>
      </formats>
      <fileSets>  # 使用fileSets包含除了 README.txt NOTICE.txt 的所有.txt 文件
        <fileSet>
          <directory>${basedir}</directory>
          <includes>
            <include>*.txt</include>
          </includes>
          <excludes>
            <exclude>README.txt</exclude>
            <exclude>NOTICE.txt</exclude>
          </excludes>
        </fileSet>
      </fileSets>
      <files>
        <file>  # 单独包含此两个文件,并对其继续过滤操作
          <source>README.txt</source>
          <outputDirectory>/</outputDirectory>
          <filtered>true</filtered>
        </file>
        <file>
          <source>NOTICE.txt</source>
          <outputDirectory>/</outputDirectory>
          <filtered>true</filtered>
        </file>
      </files>
    </assembly>
```

POM.xml文件配置:

```xml
      <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>3.1.1</version>
        <configuration>
          <filters> # 指明包含配置属性的文件
            <filter>src/assembly/filter.properties</filter>
          </filters>
          <descriptors> # assembly.xml 描述文件
            <descriptor>src/assembly/distribution.xml</descriptor>
          </descriptors>
        </configuration>
      </plugin>
```



## 2. include and Excluding artifacts

功能:  注意其中的格式

```shell
Currently the include/exclude format is based upon the dependency conflict id which has a form of: groupId:artifactId:type:classifier. A shortened form of the dependency conflict id may also be used groupId:artifactId.
```



pom文件配置:

```xml
        <dependency>
            <groupId>YOUR GROUP</groupId>
            <artifactId>YOUR ARTIFACT</artifactId>
            <version>YOUR VERSION</version>
            <classifier>bin</classifier>
            <type>zip</type>
        </dependency>
```

assembly.xml文件

```shell
  <dependencySets>
    <dependencySet>
      ....
      <excludes>  # 指定不包含的依赖文件
        <exclude>commons-lang:commons-lang</exclude>
        <exclude>log4j:log4j</exclude>
      </excludes>
    </dependencySet>
    ....
  </dependencySets>
```



## 3. Component Descriptor的使用

 使用场景举例:

```shell
Suppose you have a project which will be distributed in two forms: one for use with appserver A and another for appserver B. And as customization for these two servers, you need to exclude some dependencies which are not used by the appserver you will be distributing
```

AppServer A--assembly.xml

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>appserverA</id>   # 针对server A 编写的 assembly
      <formats>
        <format>zip</format>
      </formats>
      <dependencySets>
        <dependencySet>  # server A需要包含的依赖
          <outputDirectory>/lib</outputDirectory>
          <includes>
            <include>application:logging</include>
            <include>application:core</include>
            <include>application:utils</include>
            <include>application:appserverA</include>
          </includes>
        </dependencySet>
      </dependencySets>
    </assembly>
```

Appserver B--assembly.xml

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>appserverB</id>  # 针对server B 编写的asembly
      <formats>
        <format>zip</format>
      </formats>
      <dependencySets>
        <dependencySet>  # server B 需要包含的依赖
          <outputDirectory>/lib</outputDirectory>
          <includes>
            <include>application:logging</include>
            <include>application:core</include>
            <include>application:utils</include>
            <include>application:appserverB</include>
          </includes>
        </dependencySet>
      </dependencySets>
    </assembly>
```

可以看到server A 和server B其实是包含一些相同的依赖的，可以把相同的依赖提取出来到一个component.xml中。

修改后:

component.xml:

```xml
    <component>
      <dependencySets>
        <dependencySet>
          <outputDirectory>/lib</outputDirectory>
          <includes>
            <include>application:logging</include>
            <include>application:core</include>
            <include>application:utils</include>
          </includes>
        </dependencySet>
      </dependencySets>
    </component>
```

AppServer A--assembly.xml

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>appserverA</id>
      <formats>
        <format>zip</format>
      </formats>
      <componentDescriptors>  # 指定组件共同的组件描述文件
        <componentDescriptor>src/assembly/component.xml</componentDescriptor>
      </componentDescriptors>
      <dependencySets> # 指定特定的需要包含的依赖
        <dependencySet>
          <outputDirectory>/lib</outputDirectory>
          <includes>
            <include>application:appserverA</include>
          </includes>
        </dependencySet>
      </dependencySets>
    </assembly>
```

Appserver B--assembly.xml

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>appserverB</id>
      <formats>
        <format>zip</format>
      </formats>
      <componentDescriptors>
        <componentDescriptor>src/assembly/component.xml</componentDescriptor>
      </componentDescriptors>
      <dependencySets>
        <dependencySet>
          <outputDirectory>/lib</outputDirectory>
          <includes>
            <include>application:appserverB</include>
          </includes>
        </dependencySet>
      </dependencySets>
    </assembly>
```

pom配置:

```xml
      <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>3.1.1</version>
        <configuration>
          <descriptors>
            <descriptor>src/assembly/appserverA-assembly.xml</descriptor>
            <descriptor>src/assembly/appserverB-assembly.xml</descriptor>
          </descriptors>
        </configuration>
      </plugin>
```



## 4. Repositories的使用

功能描述:

```shell
The Assembly Plugin allows the inclusion of needed artifacts from your local repository to the generated archive. They are copied into the assembly in a directory similar to what is in your remote repository, complete with metadata and the checksums.
大意: assembly 插件允许把需要的artifact从本地仓库拷贝到创建的归档文件中。他们被拷贝到一个文件夹中和它们在远程仓库很相似，拥有完成的metadata 和 checksums。
```

assembly:

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>repository</id>
      <formats>
        <format>jar</format>
      </formats>
      <repositories>
        <repository>
          <includeMetadata>true</includeMetadata>
          <outputDirectory>maven2</outputDirectory>
        </repository>
      </repositories>
    </assembly>
```

pom:

```xml
      <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>3.1.1</version>
        <configuration>
          <descriptors>
            <descriptor>src/assembly/repository.xml</descriptor>
          </descriptors>
        </configuration>
      </plugin>
```

输出:

```shell
    target/artifactId-version-repository.jar
    `-- maven2
        |-- groupId
        |   |-- maven-metadata.xml
        |   |-- maven-metadata.xml.md5
        |   |-- maven-metadata.xml.sha1
        |   `-- artifactId
        |       |-- maven-metadata.xml
        |       |-- maven-metadata.xml.md5
        |       |-- maven-metadata.xml.sha1
        |       `-- version
        |           |-- artifactId-version.jar
        |           |-- artifactId-version.jar.md5
        |           |-- artifactId-version.jar.sha1
        |           |-- artifactId-version.pom
        |           |-- artifactId-version.pom.md5
        |           |-- artifactId-version.pom.sha1
        |           |-- maven-metadata.xml
        |           |-- maven-metadata.xml.md5
        |           `-- maven-metadata.xml.sha1
        `-- groupId2
            `-- [...]
```



## 5. container Descriptor 的使用

功能描述:

```shell
Container descriptor handlers can be used to filter dynamically the content of files configured in a descriptor, for example by aggregating multiple files into a single file, or customizing the content of specific files.

大意:container descriptor handlers 可以用来过滤动态的配置文件内容，例如可以多个文件整合到一个文件中，也可以自定义特定的文件的内容。
```

container descriptor目前自带了几个handler，下面介绍一些具体的用法:

file-aggregator:

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      ....
      <containerDescriptorHandlers>
        <containerDescriptorHandler>
          <handlerName>file-aggregator</handlerName>
          <configuration>
            <filePattern>.*/file.txt</filePattern> # 正则匹配文件
            <outputPath>file.txt</outputPath>  # 把匹配到的文件内容整合到file.txt 文件
          </configuration>
        </containerDescriptorHandler>
      </containerDescriptorHandlers>
    </assembly>
```

metaInf-services:

This handler matches every `META-INF/services` file and aggregates them into a single `META-INF/services`. The content of the files are appended together.

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      ....
      <containerDescriptorHandlers>
        <containerDescriptorHandler>
          <handlerName>metaInf-services</handlerName>
        </containerDescriptorHandler>
      </containerDescriptorHandlers>
    </assembly>
```

metaInf-spring:

This handler is similar to `metaInf-services`. It matches every file with a name starting with `META-INF/spring.

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      ....
      <containerDescriptorHandlers>
        <containerDescriptorHandler>
          <handlerName>metaInf-spring</handlerName>
        </containerDescriptorHandler>
      </containerDescriptorHandlers>
    </assembly>
```



## 6.  Module Binaries

使用场景及功能：

```shell
It is common practice to create an assembly using the parent POM of a multimodule build. At times, you may want to ensure that this assembly also includes one or more of the module binaries.

大意: 一般使用在多模块的项目中。同时想包含多个或一个模块的二进制
```

assembly:

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>bin</id>
      <formats>
        <format>dir</format>  # 打包到一个目录中
      </formats>
      <includeBaseDirectory>false</includeBaseDirectory> # 不包含基本目录
      <moduleSets> # 要包含的模块
        <moduleSet>
          <!-- Enable access to all projects in the current multimodule build! -->
          <useAllReactorProjects>true</useAllReactorProjects>
          <!-- Now, select which projects to include in this module-set. -->
          <includes>  # 包含模块
            <include>org.test:child1</include>
          </includes>
          <binaries>  # 模块二进制的输出位置
            <outputDirectory>modules/maven-assembly-plugin</outputDirectory>
            <unpack>false</unpack> # 不进行解压
          </binaries>
        </moduleSet>
      </moduleSets>
    </assembly>
```

pom:

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.test</groupId>
      <artifactId>parent</artifactId>
      <version>1.0</version>
     
      <packaging>pom</packaging>
     
      <name>Parent</name>
     
      <modules>
        <module>child1</module>
        <module>child2</module>
        <module>child3</module>
        <module>distribution</module>  # 此示例的项目
      </modules>
    </project>
```

distribution - pom 配置:

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>
      
      <parent>
        <groupId>org.test</groupId>
        <artifactId>parent</artifactId>
        <version>1.0</version>
      </parent>
      
      <artifactId>distribution</artifactId>
     
      <packaging>pom</packaging>
     
      <name>Distribution</name>
      
      <dependencies>
        <dependency>
          <groupId>org.test</groupId>
          <artifactId>child1</artifactId>
          <version>1.0</version>
        </dependency>
      </dependencies>
     
      <build>
        <plugins>
          <plugin>
            <artifactId>maven-assembly-plugin</artifactId>
            <executions>
              <execution>
                <id>distro-assembly</id>
                <phase>package</phase>
                <goals>
                  <goal>single</goal>
                </goals>
                <configuration>
                  <descriptors>
                    <descriptor>src/assembly/bin.xml</descriptor>
                  </descriptors>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </project>
```

输出:

```shell
    target/distribution/distribution-1.0-bin
    `-- modules
        `-- child1
            |-- child1-1.0.jar
            `-- junit-3.8.1.jar
```



## 7. Module Sources

使用场景及功能:

```shell
It is common practice to create an assembly using the parent POM of a multimodule build. At times, you may want to ensure that this assembly also includes the source code from one or more of the modules in this build.
大意: 一般使用在多模块项目中，同时希望包含项目中一个或多个模块的源码。
```

pom配置:

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.test</groupId>
      <artifactId>parent</artifactId>
      <version>1.0</version>
     
      <packaging>pom</packaging>
     
      <name>Parent</name>
     
      <modules>
        <module>child1</module>
        <module>child2</module>
        <module>child3</module>
      </modules>
     
      <build>
        <plugins>
          <plugin>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>3.1.1</version>
            <configuration>
              <descriptors>
                <descriptor>src/assembly/src.xml</descriptor>
              </descriptors>
            </configuration>
          </plugin>
        </plugins>
      </build>
    </project>
```

assembly：

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id>src</id>
      <formats>
        <format>dir</format>
      </formats>
      <includeBaseDirectory>false</includeBaseDirectory>
      <moduleSets>
        <moduleSet>
          <useAllReactorProjects>true</useAllReactorProjects>
          <includes> # 包含的模块
            <include>org.test:child1</include>
          </includes>
          <sources>  # 包含的源码设置
            <includeModuleDirectory>false</includeModuleDirectory>
            <fileSets>
              <fileSet> # 文件输出位置
                <outputDirectory>sources/${module.artifactId}</outputDirectory>
                <excludes> # 不包含的文件目录
                  <exclude>/home/eolivelli/dev/maven-assembly-plugin/target/checkout/target/**</exclude>
                </excludes>
              </fileSet>
            </fileSets>
          </sources>
        </moduleSet>
      </moduleSets>
    </assembly>
```

输出:

```shell
    target/parent-1.0-src/
    `-- sources
        `-- child1
            |-- pom.xml
            `-- src
                |-- main
                |   `-- java
                |       `-- org
                |           `-- test
                |               `-- App.java
                `-- test
                    `-- java
                        `-- org
                            `-- test
                                `-- AppTest.java
```

