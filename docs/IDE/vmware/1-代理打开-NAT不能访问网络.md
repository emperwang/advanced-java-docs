---
tags:
  - vmware
  - proxy
  - NAT
---
在windows中打开了proxy代理后,  使用NAT 配置的虚拟机就不能访问网络.


解决:
在proxy中配置虚拟机网段的IP不经过代理, 直连网络.
![](./images/proxy.png)



