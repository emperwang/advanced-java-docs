---
tags:
  - jenkins
  - summary
---
今天在编写Jenkins时, 思考了比较久来如何快速编写,  虽然编写过很多次了, 但是再次编写一个类似的,  仍然会出现这种需要思考比较久的时间.

编写jenkinsfile时,  可以选择遵从下面一些方法, 来快速达到最终的CICD的效果.
1) 确认好最终效果后, 切分各个步骤
2) 按照切分好的步骤, 写好程序轮廓
3) 依次编写各个步骤,  并调试通过
4) 总的功能走通后,  再细致添加其他的要求, 如: sonarQube, sonarIQ等



以一个例子来说明步骤:
> 把编写好的java后端程序, 从repo中拉取下来, 编译打包, 并upload到nexus.

这在工作中属于常见的一个devOps项目. 首先我们把次功能拆分:
1) 创建下载目录
2) 下载代码
3) 读取pom中的artificate, groupID, version信息
4) 使用maven编译代码, 并打包
5) 上传到nexus

接下来, 把项目的轮廓编写出来
``` jenkinsfile
## 这是 script 形式的
properties (parameters)

timestampes {
	node ('builder') {
		stage('Preparation') {
			// 创建下载的目录
		}

		stage('Checkout App'){
			// 下载源码
			// 读取artificate  groupId  version信息
		}

		stage('Build Package'){
			// 使用mvn编译package
		}

		stage('Upload Package'){
			// 上传到 nexus
		}
	}
}
```

当把上面的各个步骤,  编写完,  并测试通过后,  可以继续添加其他CI功能. 如:
1) 整合snoarQube 扫描代码  testcase覆盖率
2) 整合sonarIQ 测试依赖jar有没有漏洞
3) ....


```jenkinsfile
## 这是 script 形式的
properties (parameters)

timestampes {
	node ('builder') {
		stage('Preparation') {
			// 创建下载的目录
		}

		stage('Checkout App'){
			// 下载源码
			// 读取artificate  groupId  version信息
		}

		stage('Build Package'){
			// 使用mvn编译package
		}

		stage('Upload Package'){
			// 上传到 nexus
		}

		stage('sonarQube') {
		
		}

		stage('sonarIQ'){
		}
	}
}
```

如此, 则能快速搭建起来一个devOps的框架, 并按照步骤去快速实现.




