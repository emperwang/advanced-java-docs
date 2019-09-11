# Maven dependency

```shell
The dependency plugin provides the capability to manipulate artifacts. It can copy and/or unpack artifacts from local or remote repositories to a specified location.
大意:dependency 插件提供了操作artifiact的能力。它能够拷贝/unpack 本地的或远程的 artifact 到指定的位置。
```

简单点说dependency插件提供了拷贝或解压jar的能力；其能够把指定的jar包拷贝到 或 解压到指定目录下。

## 1. 拷贝

### 1.1  拷贝特定的artifacts

```shell
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-dependency-plugin</artifactId>
    <version>3.1.1</version>
    <executions>
        <execution>
            <id>copy</id>
            <phase>package</phase>
            <goals>
            	<goal>copy</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
    <artifactItems>
    	<artifactItem> # 指定要拷贝的atifiact
    	<groupId>junit</groupId>
    	<artifactId>junit</artifactId>
    	<version>3.8.1</version>
    	<type>jar</type>
    	# 是否覆盖
    	<overWrite>false</overWrite>
    	# 拷贝到哪里
    <outputDirectory>${project.build.directory}/alternateLocation</outputDirectory>
    	# 给jar包修改个名字
    	<destFileName>optional-new-name.jar</destFileName>
    </artifactItem>
    </artifactItems>
    # 其他拷贝到此地址
    <outputDirectory>${project.build.directory}/wars</outputDirectory>
    # 是否覆盖
    <overWriteReleases>false</overWriteReleases>
    # 是否覆盖
    <overWriteSnapshots>true</overWriteSnapshots>
    </configuration>
</plugin>
```

```shell
    <project>
      [...]
      <dependencies>
        <dependency>
          <groupId>junit</groupId>
          <artifactId>junit</artifactId>
          <version>3.8.1</version>
          <scope>test</scope>
        </dependency>
      </dependencies>
      [...]
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>copy</id>
                <phase>package</phase>
                <goals>
                  <goal>copy</goal>
                </goals>
                <configuration>
                  <artifactItems>
                  # 当要拷贝的jar包在dependency中,那么就是用上面指定的版本
                    <artifactItem>
                      <groupId>junit</groupId>
                      <artifactId>junit</artifactId>
                      <overWrite>false</overWrite>                   <outputDirectory>${project.build.directory}/alternateLocation</outputDirectory>
                      <destFileName>optional-new-name.jar</destFileName>
                    </artifactItem>
                  </artifactItems>
                  <outputDirectory>${project.build.directory}/wars</outputDirectory>
                  <overWriteReleases>false</overWriteReleases>
                  <overWriteSnapshots>true</overWriteSnapshots>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
      [...]
    </project>
```

### 1.2 把此次编译好的jar包拷贝到指定的地方

**注意:**此操作一定要绑定在package阶段之后的生命周期.

```shell
    <project>
      [...]
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>copy-installed</id>
                <phase>install</phase>
                <goals>
                  <goal>copy</goal>
                </goals>
                <configuration>
                  <artifactItems> # 把此处编译好的jar包拷贝到其他地方
                    <artifactItem>
                      <groupId>${project.groupId}</groupId>
                      <artifactId>${project.artifactId}</artifactId>
                      <version>${project.version}</version>
                      <type>${project.packaging}</type>
                    </artifactItem>
                  </artifactItems>
                  <outputDirectory>some-other-place</outputDirectory>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
      [...]
    </project>
```

### 1.3  把jar包拷贝到指定的repository

maven在拷贝一个包时，也是先从远程仓库先拷贝到本地仓库，然后再拷贝到desired location。那么可以让下载的包先下载到指定的仓库中，然后再拷贝到 desired location.

```shell
    <project>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>copy-with-alternalte-repo</id>
                <phase>install</phase>
                <goals>
                  <goal>copy</goal>
                </goals>
                <configuration>
                  <artifactItems>
                    <artifactItem>
                      [...]
                    </artifactItem>
                    [...]
                  </artifactItems> 
# 把jar包先下载到此目录中                  <localRepositoryDirectory>${project.build.directory}/localrepo</localRepositoryDirectory>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </project>
```

### 1.4 拷贝项目依赖的jar包

```shell
    <project>
      [...]
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>copy-dependencies</id>
                <phase>package</phase>
                <goals> # 使用此mojo来拷贝项目依赖jar包
                  <goal>copy-dependencies</goal>
                </goals>
                <configuration> # 配置依赖包拷贝到哪里
   <outputDirectory>${project.build.directory}/alternateLocation</outputDirectory>
                  <overWriteReleases>false</overWriteReleases>
                  <overWriteSnapshots>false</overWriteSnapshots>
                  # 替换旧包
                  <overWriteIfNewer>true</overWriteIfNewer>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
      [...]
    </project>
```

### 1.5 拷贝工程依赖的jar包的源码，而不是jar包

```shell
<project>
[...]
<build>
    <plugins>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.1.1</version>
        <executions>
        <execution>
        <id>src-dependencies</id>
        <phase>package</phase>
        <goals>
    	<!-- # use copy-dependencies instead if 
    		# you don't want to explode the sources -->
    		<goal>unpack-dependencies</goal>
    	</goals>
    	<configuration>
    	   <classifier>sources</classifier>
    	   # 找不到artifcat时  是否退出
    	   <failOnMissingClassifierArtifact>false</failOnMissingClassifierArtifact>
    	   # 输出目录
           <outputDirectory>${project.build.directory}/sources</outputDirectory>
        </configuration>
        </execution>
        </executions>
    </plugin>
    </plugins>
</build>
[...]
</project>
```



## 2. 解压

### 2.1 解压指定的jar包

```shell
    <project>
       [...]
       <build>
         <plugins>
           <plugin>
             <groupId>org.apache.maven.plugins</groupId>
             <artifactId>maven-dependency-plugin</artifactId>
             <version>3.1.1</version>
             <executions>
               <execution>
                 <id>unpack</id>
                 <phase>package</phase>
                 <goals> # action动作是解压
                   <goal>unpack</goal>
                 </goals>
                 <configuration>
                   <artifactItems>
                     <artifactItem> 
                     # 指定要解压的特定的 jar 包
                       <groupId>junit</groupId>
                       <artifactId>junit</artifactId>
                       <version>3.8.1</version>
                       <type>jar</type>
                       <overWrite>false</overWrite>
# 解压的目录                       <outputDirectory>${project.build.directory}/alternateLocation</outputDirectory>
                       <destFileName>optional-new-name.jar</destFileName>
                       <includes>**/*.class,**/*.xml</includes>
                       <excludes>**/*test.class</excludes>
                     </artifactItem>
                   </artifactItems>
                   <includes>**/*.java</includes>
                   <excludes>**/*.properties</excludes>
<outputDirectory>${project.build.directory}/wars</outputDirectory>
                   <overWriteReleases>false</overWriteReleases>
                   <overWriteSnapshots>true</overWriteSnapshots>
                 </configuration>
               </execution>
             </executions>
           </plugin>
         </plugins>
       </build>
       [...]
     </project>
```



### 2.2 解压项目依赖包

```shell
    <project>
      [...]
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>unpack-dependencies</id>
                <phase>package</phase>
                <goals>  # 解压的action
                  <goal>unpack-dependencies</goal>
                </goals>
                <configuration> 
                  <includes>**/*.class</includes>
                  <excludes>**/*.properties</excludes>
# 解压的目录
<outputDirectory>${project.build.directory}/alternateLocation</outputDirectory>
                  <overWriteReleases>false</overWriteReleases>
                  <overWriteSnapshots>true</overWriteSnapshots>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
      [...]
    </project>
```

## 3. 依赖分析有警告就退出

```shell
    <project>
      ...
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
              <execution>
                <id>analyze</id>
                <goals> # 分析项目依赖
                  <goal>analyze-only</goal>
                </goals>
                <configuration>
                # 有警告时 就失败
                  <failOnWarning>true</failOnWarning>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
      ...
    </project>
```



## 4. 解决jar包依赖冲突

通过分析依赖tree，查看为什么这些jar添加进来。

```shell
# 命令
# 查看为什么添加 commons-collections jar包
mvn dependency:tree -Dverbose -Dincludes=commons-collections
```

```shell
# 输出结果
[INFO] [dependency:tree]
[INFO] org.apache.maven.plugins:maven-dependency-plugin:maven-plugin:2.0-alpha-5-SNAPSHOT
[INFO] +- org.apache.maven.reporting:maven-reporting-impl:jar:2.0.4:compile
[INFO] |  \- commons-validator:commons-validator:jar:1.2.0:compile
[INFO] |     \- commons-digester:commons-digester:jar:1.6:compile
[INFO] |        \- (commons-collections:commons-collections:jar:2.1:compile - omitted for conflict with 2.0)
[INFO] \- org.apache.maven.doxia:doxia-site-renderer:jar:1.0-alpha-8:compile
[INFO]    \- org.codehaus.plexus:plexus-velocity:jar:1.1.3:compile
[INFO]       \- commons-collections:commons-collections:jar:2.0:compile
```



