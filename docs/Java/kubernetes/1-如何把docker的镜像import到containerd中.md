---
tags:
  - k8s
  - docker
  - image
  - containerd
---
环境: 
使用Vmware自建的k8s集群.

在部署镜像到k8s集群时, 常常使用docker创建好对应的镜像,  然后再进行部署操作. 不过在部署时, 发现镜像明明存在于服务器, 但是PullImage时, 还是会失败.

因为k8s底层使用的是 containerd,   故使用 `crictl`来查看镜像,  发现docker build的镜像, 使用`crictl` 并看不到.  于是尝试使用 `ctr`  把docker的镜像进行导入操作,  导入后, 仍是看不见.

这里有一个小知识: 
>  containerd是有namespace的, 并通过namespace来进行镜像的隔离.  而 k8s 使用的是  `k8s.io`此namespace下的.

故通过`ctr`导入镜像时, 要指定导入到 `k8s.io` namespace中.

```
ctr -n k8s.io  images import image:tag

# 导出的操作
docker save -o nginx.tar.gz nginx:v1.2
```










