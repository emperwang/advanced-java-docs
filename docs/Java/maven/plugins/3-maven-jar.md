# Maven JAR Plugin

功能:

```shell
This plugin provides the capability to build jars. 
此插件提供了打jar包的功能
```



## 1. 设置classPath

### 1.1 在Manifest中添加 Class-path

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            ...
            <configuration>
              <archive>
                <manifest>  # 在Mainifest中 添加 Class-path项
                  <addClasspath>true</addClasspath>
                </manifest>
              </archive>
            </configuration>
            ...
          </plugin>
        </plugins>
      </build>
      ...
      <dependencies>
        <dependency>
          <groupId>commons-lang</groupId>
          <artifactId>commons-lang</artifactId>
          <version>2.1</version>
        </dependency>
        <dependency>
          <groupId>org.codehaus.plexus</groupId>
          <artifactId>plexus-utils</artifactId>
          <version>1.1</version>
        </dependency>
      </dependencies>
      ...
    </project>
```

结果:

```shell
    Manifest-Version: 1.0
    Created-By: Apache Maven ${maven.version}
    Build-Jdk: ${java.version}
    Class-Path: plexus-utils-1.1.jar commons-lang-2.1.jar  # 此为添加的
```



### 1.2 打包可执行jar包

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            ...
            <configuration>
              <archive>
                <manifest> 
                  # 添加 Class-path
                  <addClasspath>true</addClasspath>
                  # 指定启动类的 全限定名
                  <mainClass>fully.qualified.MainClass</mainClass>
                </manifest>
              </archive>
            </configuration>
            ...
          </plugin>
        </plugins>
      </build>
      ...
      <dependencies>
        <dependency>
          <groupId>commons-lang</groupId>
          <artifactId>commons-lang</artifactId>
          <version>2.1</version>
        </dependency>
        <dependency>
          <groupId>org.codehaus.plexus</groupId>
          <artifactId>plexus-utils</artifactId>
          <version>1.1</version>
        </dependency>
      </dependencies>
      ...
    </project>
```

```shell
    ## 结构
    Manifest-Version: 1.0
    Created-By: Apache Maven ${maven.version}
    Build-Jdk: ${java.version}
    Main-Class: fully.qualified.MainClass   # 启动类
    Class-Path: plexus-utils-1.1.jar commons-lang-2.1.jar   # 依赖jar包
```



### 1.3 修改classpath:为classpath定义一个前缀

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
             <artifactId>maven-war-plugin</artifactId>
             <configuration>
               <archive>
                 <manifest>
                   <addClasspath>true</addClasspath>
                   # 为 Class-path 中的jar包添加一个前缀
                   <classpathPrefix>lib/</classpathPrefix>
                 </manifest>
               </archive>
             </configuration>
          </plugin>
        </plugins>
      </build>
      ...
      <dependencies>
        <dependency>
          <groupId>commons-lang</groupId>
          <artifactId>commons-lang</artifactId>
          <version>2.1</version>
        </dependency>
        <dependency>
          <groupId>org.codehaus.plexus</groupId>
          <artifactId>plexus-utils</artifactId>
          <version>1.1</version>
        </dependency>
      </dependencies>
      ...
    </project>
```

```shell
# 结果
Class-Path: lib/plexus-utils-1.1.jar lib/commons-lang-2.1.jar
```



### 1.4  修改claspath: 使用maven-reposity 形式的classpath

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <artifactId>maven-jar-plugin</artifactId>
            <version>2.3</version>
            <configuration>
              <archive>
                <manifest>
                  <addClasspath>true</addClasspath>
                  # 添加前缀
                  <classpathPrefix>lib/</classpathPrefix>
                  #　指定格式
                  <classpathLayoutType>repository</classpathLayoutType>
                </manifest>
              </archive>
            </configuration>
          </plugin>
        </plugins>
      </build>
      ...
      <dependencies>
        <dependency>
          <groupId>commons-lang</groupId>
          <artifactId>commons-lang</artifactId>
          <version>2.1</version>
        </dependency>
        <dependency>
          <groupId>org.codehaus.plexus</groupId>
          <artifactId>plexus-utils</artifactId>
          <version>1.1</version>
        </dependency>
      </dependencies>
      ...
    </project>
```

```shell
# 结果
Class-Path: lib/org/codehaus/plexus/plexus-utils/1.1/plexus-utils-1.1.jar lib/commons-lang/commons-lang/2.1/commons-lang-2.1.jar
```



### 1.5 修改classpath: 使用 自定义的 classpath格式

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
             <artifactId>maven-war-plugin</artifactId>
             <configuration>
               <archive>
                 <manifest>
                   <addClasspath>true</addClasspath>
                   # 表示使用自定义class-path
                   <classpathLayoutType>custom</classpathLayoutType>
                   # 自定义class-path
                   <customClasspathLayout>WEB-INF/lib/$${artifact.groupIdPath}/$${artifact.artifactId}-$${artifact.version}$${dashClassifier?}.$${artifact.extension}</customClasspathLayout>
                 </manifest>
               </archive>
             </configuration>
          </plugin>
        </plugins>
      </build>
      ...
      <dependencies>
        <dependency>
          <groupId>commons-lang</groupId>
          <artifactId>commons-lang</artifactId>
          <version>2.1</version>
        </dependency>
        <dependency>
          <groupId>org.codehaus.plexus</groupId>
          <artifactId>plexus-utils</artifactId>
          <version>1.1</version>
        </dependency>
      </dependencies>
      ...
    </project>
```

```shell
# 结果
Class-Path: WEB-INF/lib/org/codehaus/plexus/plexus-utils-1.1.jar WEB-INF/lib/commons-lang/commons-lang-2.1.jar
```

### 1.6 在Manifest中添加 implementation 和 specifiection

```shell
# 默认的manifest实现:
Manifest-Version: 1.0
Created-By: Apache Maven ${maven.version}
Build-Jdk: ${java.version}
```

```shell
<project>
...
    <build>
    <plugins>
    <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <version>2.1</version>
    ...
    <configuration>
        <archive>
        <manifest>
           # 添加implementations
           <addDefaultImplementationEntries>true</addDefaultImplementationEntries>
           # 添加specification
           <addDefaultSpecificationEntries>true</addDefaultSpecificationEntries>
        </manifest>
        </archive>
    </configuration>
    ...
    </plugin>
    </plugins>
    </build>
...
</project>
```

```shell
# 结果
Manifest-Version: 1.0
Created-By: Apache Maven ${maven.version}
Build-Jdk: ${java.version}
Specification-Title: ${project.name}
Specification-Version: ${project.artifact.selectedVersion.majorVersion}.${project.artifact.selectedVersion.minorVersion}
Specification-Vendor: ${project.organization.name}
Implementation-Title: ${project.name}
Implementation-Version: ${project.version}
Implementation-Vendor: ${project.organization.name}
```

### 1.7 在manifest添加自己的entry

```shell
    <project>
      <url>http://some.url.org/</url>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            ...
            <configuration>
              <archive>
                <manifestEntries>
                # 添加的 entry
                  <mode>development</mode>
                  <url>${project.url}</url>
                </manifestEntries>
              </archive>
            </configuration>
            ...
          </plugin>
        </plugins>
      </build>
      ...
    </project>
```

```shell
# 结果
Manifest-Version: 1.0
Created-By: Apache Maven ${maven.version}
Build-Jdk: ${java.version}
mode: development
url: http://some.url.org/
```

### 1.8 使用自己的Manifest

```shell
<project>
...
<build>
    <plugins>
        <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        ...
        <configuration>
            <archive>
            # 指定自定义的manifest文件路径
            <manifestFile>src/main/resources/META-INF/MANIFEST.MF</manifestFile>
            </archive>
        </configuration>
        ...
        </plugin>
    </plugins>
</build>
...
</project>
```



### 1.9 添加manifest Sections

```shelll
The <manifestSections> element provides a way to add custom manifest sections. It contains a list of <manifestSection> elements.
大意:manifestSections元素提供了一个添加manifest sections的功能。它提供了一系列manifestSection.
```

```shell
# 配置
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            ...
            <configuration>
              <archive>
                <manifestSections> # 开始定义manifestSection
                  <manifestSection> # 具体定义每一个section
                    <name>foo</name>
                    <manifestEntries>
                      <id>nice foo</id>
                    </manifestEntries>
                  </manifestSection>
                  <manifestSection>
                    <name>bar</name>
                    <manifestEntries>
                      <id>nice bar</id>
                    </manifestEntries>
                  </manifestSection>
                </manifestSections>
              </archive>
            </configuration>
            ...
          </plugin>
        </plugins>
      </build>
      ...
    </project>
```

```shell
# 结果
Manifest-Version: 1.0
Created-By: Apache Maven ${maven.version}
Build-Jdk: ${java.version}

Name: foo
id: nice foo

Name: bar
id: nice bar
```



## 2. additional attached JAR

```shell
Specify a list of fileset patterns to be included or excluded by adding <includes>/<include> or <excludes>/<exclude> and add a classifier in your pom.xml
大意: 使用<includes>/<include>或<excludes>/<exclude>指定一系列的文件，并且要添加一个 classifier在pom文件中
```

```shell
    <project>
      ...
      <build>
        <plugins>
          ...
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <version>3.1.2</version>
            <executions>
              <execution>
                <phase>package</phase>
                <goals>
                  <goal>jar</goal>
                </goals>
                <configuration>
                # 添加classifier
                  <classifier>client</classifier>
                  <includes> # 要添加的文件
                    <include>**/service/*</include>
                  </includes>
                </configuration>
              </execution>
            </executions>
          </plugin>
          ...
        </plugins>
      </build>
      ...
    </project>
```



## 3. 创建 test jar

创建一个包含test 类和test资源的jar包:

```shell
    <project>
      ...
      <build>
        <plugins>
          ...
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <version>3.1.2</version>
            <executions>
              <execution>
                <goals>
                # 包含 test 类和资源
                  <goal>test-jar</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          ...
        </plugins>
      </build>
      ...
    </project>
```

在其他项目使用此jar时，需使用下面方式添加:

```shell
  <dependencies>
    <dependency>
      <groupId>groupId</groupId>
      <artifactId>artifactId</artifactId>
      <classifier>tests</classifier>
      # 指定类型为 test-jar 
      <type>test-jar</type>
      <version>version</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
```



## 4. include / exclude content

可以使用`<includes>`/`<include>` or `<excludes>`/`<exclude>`来包含或包含一部分文件.

```shell
    <project>
      ...
      <build>
        <plugins>
          ...
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <version>3.1.2</version>
            <configuration>
              <includes>
                <include>**/service/*</include>
              </includes>
            </configuration>
          </plugin>
          ...
        </plugins>
      </build>
      ...
    </project>
```



