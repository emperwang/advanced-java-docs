---
tags:
  - devops
  - jenkins
---

如何获取存储在jenkins中的credentials呢? 

第一步:
	在第一个stage中保存下来对应的 credtial信息
第二步:
	 在第二个stage中打印保存的信息.

```groovy
timestamp {
	def username = ""
	def pwd = ""

	node('linux') {
	stage('save_variable'){
	withCredentials([usernamePassword(credentialsId: 'my-credential',usernameVariable: 'USERNAME',       passwordVariable: 'PASSWORD')]) {
			username = "$USERNAME"
			pwd = "$PASSWORD"
		}
	}
	stage('print_variable') {
		echo "$username"
		echo "$pwd"
	}
}
```




