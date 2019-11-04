[TOC]

# Jenkinsfile

此列举一个使用jenkinsfile部署程序的example，此处使用的声明式pipeline脚本：

```groovy
pipeline{
    agent any
    options{			# 输出日志带时间戳
        timestamps()
    }
    stages{
        stage('Pull code'){	# 从git从库拉取代码
            steps{
                echo 'pull code'
                git credentialsId: 'a0967f37-79d9-4547-ad97-d239c64b2d09', url: 'https://github.com/emperwang/springbootDemo.git'
            }
        }
        stage('Build with mvn'){		# 编译代码
            steps{
                echo 'build with mvn'
                sh "mvn --version"
                sh "cd springbootAssemble && mvn clean package -Dmaven.test.skip=true"
            }
        }
        stage('Deploy'){	# 把编译后的jar包拷贝到服务器, 并执行服务器上的启动脚本
            steps{
                echo "deploy"
                sh "scp springbootAssemble/target/spring-boot-assembly.jar root@192.168.72.35:/opt/spring-boot-assembly/boot"
                sh "ssh root@192.168.72.35 '/opt/spring-boot-assembly/bin/start.sh start'"
            }
        }
    }
}
```

