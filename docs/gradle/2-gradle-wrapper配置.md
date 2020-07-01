[TOC]

# 配置gradle wrapper

gradle  wrapper指定了此project使用的打包工具的版本，以及指定的jar包二进制下载的地址，可以保证其他人拿到程序后，也能使用正确的打包工具来使用。

gradle wrapper 配置属性：

```java
https://docs.gradle.org/current/dsl/org.gradle.api.tasks.wrapper.Wrapper.html
```



## 1.常用的参数

```shell
--gradle-version: 指定要下载的 gradle 的版本
--distribution-type: gradle发布的类型;有all 和 bin. bin是二进制, all表示二进制以及源码
--gradle-distribution-url: gradle 下载的路径
--gradle-distribution-sha256-sum: SHA256 hash码,用于验证下载的gradle的正确性
```

sha256示例：

```properties
distributionSha256Sum=371cb9fbebbe9880d147f59bab36d61eee122854ef8c9ee1ecf12b82368bcf10
```



## 2. wrapper文件

wrapper文件一般包含下面几个:

* gradle-wapper.jar   下载的gradle的执行jar包
* gradle-wrapper.properties: gradle wrapper 执行时的配置文件
* graldew : unix系统的gradle的执行脚本
* gradlew.bat :  windows 系统上的gradle的执行脚本

## 3.升级wrapper

上级简单说，就是更新一下gradle wrapper配置文件中的版本。

```shell
# 如升级为 6.5.1
gradlew  wrapper --gradle-version 6.5.1
```



## 4. 指定网站的用户名密码

有时在公司内网去下载gradl可能需要用户名密码，那么怎么制定呢？

方式有两个。

方式一：

在家目录中 .gradle/gradle.properties 文件中添加以下内容：

```properties
systemProp.gradle.wrapperUser=username
systemProp.gradle.wrapperPassword=password
```



方式二：

在gradle wrapper配置文件 gradle-wrapper.properties 中的下载路径中添加用户名密码：

```properties
distributionUrl=https://username:password@host/path/to/gradle-distribution.zip
```



实例:

![](../image/gradle/wrapper-0.png)

配置文件内容:

```properties
# cat gradle\wrapper\gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-6.4.0-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

升级wrapper

![](../image/gradle/wrapper-2.png)

配置文件内容

```properties
# cat gradle\wrapper\gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-6.4.1-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

