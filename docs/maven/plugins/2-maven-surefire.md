# Mavne-Surefire

官方功能解释:

```shell
The Surefire Plugin is used during the test phase of the build lifecycle to execute the unit tests of an application.

大意:surefire插件在生命周期中的test阶段使用，执行应用的单元测试。
```

## 1. 跳过测试

```shell
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.0.0-M3</version>
        <configuration>  # 跳过测试
          <skipTests>true</skipTests>
        </configuration>
      </plugin>
```

```shell
    <project>
      <properties> # 属性指定是否跳过
        <skipTests>true</skipTests>
      </properties>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.0.0-M3</version>
            <configuration>
              <skipTests>${skipTests}</skipTests>
            </configuration>
          </plugin>
        </plugins>
      </build>
    </project>
```





```shell
# 命令设置
mvn install -DskipTests
mvn install -Dmavne.test.skip=true
```



