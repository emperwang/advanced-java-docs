---
tags:
  - devops
  - jenkins
---
最近再做一些关于jenkins的devops工作,  其中一个就是自动化更新Jenkins中的credentials以及调用job的API来出发job的运行.

这里简单说一下其中的两个关键点:
1. 获取API接口的方式方法
2. 访问API时的认证信息

> 获取API

获取对应的API有两种方式, 以下以credentials为例:
1) 访问到对应的页面后, 在URL后面 添加 /api,  就可以看到对应的一些CRUD - API 的使用.  (自己在使用此方法找 credentials的API时不太行)
2) 打开google 浏览器的debug,  查看GUI操作时真正调用的API接口信息 以及 参数. (通过此方法找到credentials的API)


> 认证信息
1) 认证可以通过使用 jenkins-crumb的header 来访问
	i) 获取用户对应的crumb信息
	ii) 使用上面的crumb信息来访问API
2) 使用有权限的账户登录后, 创建一个http token, 使用此token可以方位API

```shell
# crumb的获取
curl -vvv -u "username:password" -X GET https://JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
### 格式为 jenkins-crumb:xxxxx
## crumb的使用

curl -vvv -H "Jenkins-crumb:xxxxx" -u "username:pwd" -X POST https://JENKINS_URL/credentials?jenkins-crumb=xxxxx  -F "json:..."



# token通过GUI创建
## 使用token访问
curl -vvv -u "username:token" -X POST https://JENKINS_URL/credentials?jenkins-crumb=xxxxx  -F "json:..."



```








