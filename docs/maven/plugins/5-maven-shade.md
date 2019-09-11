# Maven Shade

```shell
This plugin provides the capability to package the artifact in an uber-jar, including its dependencies and to shade - i.e. rename - the packages of some of the dependencies.

大意:此插件提供了把工程打包成一个超级jar包，包括其依赖 及其shade，即重命名一些依赖项的包.
```

## 1. 选择打包的内容

```shell
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <artifactSet>
                <excludes> # 打包时去除的依赖包
                  # 这里可以使用 ant 风格的 正则表达式
                  <exclude>classworlds:classworlds</exclude>
                  <exclude>junit:junit</exclude>
                  <exclude>jmock:*</exclude>
                  <exclude>*:xml-apis</exclude>
                  <exclude>org.apache.maven:lib:tests</exclude>
                  <exclude>log4j:log4j:jar:</exclude>
                </excludes>
              </artifactSet>
            </configuration>
          </execution>
        </executions>
      </plugin>
```

```shell
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
            # 此配置表示,打包时没有使用到的jar包,就不会打进去, 保持jar包的最小化
              <minimizeJar>true</minimizeJar>
            </configuration>
          </execution>
        </executions>
      </plugin>
```

## 2. 可执行jar包

```shell
<plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
              # 指定转换类
              <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
              	# 指定主类
                  <mainClass>org.sonatype.haven.HavenCli</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
```

```shell
# 添加其他entries
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <manifestEntries>
                    # 添加entry到 manifest中
                    <Main-Class>org.sonatype.haven.ExodusCli</Main-Class>
                    <Build-Number>123</Build-Number>
                  </manifestEntries>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
```

## 3. 重命名jar包package(Relocating Classes)

```shell
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <relocations> # 重命名package
                <relocation>
                  <pattern>org.codehaus.plexus.util</pattern>
                  <shadedPattern>org.shaded.plexus.util</shadedPattern>
                  <excludes>
                    <exclude>org.codehaus.plexus.util.xml.Xpp3Dom</exclude>
                    <exclude>org.codehaus.plexus.util.xml.pull.*</exclude>
                  </excludes>
                </relocation>
              </relocations>
            </configuration>
          </execution>
        </executions>
      </plugin>
     
# 此配置会把org.codehaus.plexus.util及其子包的移动到org.shaded.plexus.util,但是Xpp3Dom和org.codehaus.plexus.util.xml.pull包下的文件不会进行修改
```

```shell
# 官方解释
This instructs the plugin to move classes from the package org.codehaus.plexus.util and its subpackages into the package org.shaded.plexus.util by moving the corresponding JAR file entries and rewritting the affected bytecode. The class Xpp3Dom and some others will remain in their original package.
```



```shell
<relocation>
    <pattern>org.codehaus.plexus.util</pattern>
    <shadedPattern>org.shaded.plexus.util</shadedPattern>
    #  只修改指定的类
    <includes>
    	<include>org.codehaud.plexus.util.io.*</include>
    </includes>
</relocation>
```

