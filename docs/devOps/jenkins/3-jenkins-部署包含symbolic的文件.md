---
tags:
  - jenkins
---

问题:
在部署项目到server时,  发现repository中的symbolic 文件都变成了实体文件. 

部署流程:
![](./deploy-flow)

排查点:
1. 源码中的文件的确时 symbolic类型的文件,  没有问题
2. ansible playbook 部署时,  把文件属性修改了.    仔细检查部署脚本后,  应该是没有这么操作的
3. 在部署过程中,  查看下载到 server 上的 项目package,  发现下载下来的文件就已经是 `实体文件`了.  **这应该就是问题所在了**



原因:

在Jenkins中是 使用 `zip` step把文件打包后 上传到nexus, zip应该添加 `-y` 属性来保存symbolic 文件, 参考[[2-linux中压缩symbolic-link文件]].  不过jenkins中 zip 没有添加参数的方法.
那就替换为使用 `tar` 命令来压缩文件,   替换后发现可以完美部署 symbolic文件.






