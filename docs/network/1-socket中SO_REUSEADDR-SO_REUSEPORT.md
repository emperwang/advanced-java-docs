# socket中 SO_REUSEADDR和SO_REUSEPORT

## 1. socket的一些简介

基本上其他所有的系统某种程度上都参考了BSD socket实现(或者至少是其接口), 然后开始了他们各自的独立法阵, 简单说BSD实现是所有socket实现的起源.  所以理解BSD socket实现是理解其他socket实现的基石. 

在分析BSD 参数前, 先了解一些socket的基本知识.

TCP/UDP 是由以下五元组唯一的识别的:

`{<protocol>, <src addr>, <src port>, <dest addr>, <dest port>}`

这些数值组成的任何独特组合可以唯一的确定一个链接. 那么, 对于任何任意连接, 这五个值都不能完全相同, 否则的话操作系统就无法区别这些连接了.

一个socket的`协议`是在调用socket()初始化时设置的;   源地址`source address` 和源端口`source port` 在调用bind() 时设置的;  目的地址`destination address`和源端口`destination port`在调用connect()时设置的. 

UDP是无连接的, UDP socket可以在未与目的端口连接的情况下使用,  但是UDP也可以先与目的源地址和端口建立连接后使用.  在使用无连接 UDP 发送数据情况下, 如果没有显式调用bind(), 操作系统会在第一次发送数据时将UDP socket和本机的地址和某个端口绑定;  同样的,  一个没有绑定地址的TCP socket也会在建立连接时被自动绑定到一个本机地址和端口.

### 1.1 地址绑定

> 端口绑定0

如果手动将端口绑定至`0`,  即表示`让操作系统自己决定使用哪个端口`, 也就是任何端口的意思.  

同样可以使用一个通配符来让系统决定绑定到哪个源地址(`IPV4 通配符:0.0.0.0; IPV6 通配符 ::`), 与端口不同的是, 一个socket可以被绑定到主机所有网卡接口所对应的地址中的任意一个,  基于连接在本socket的目的地址和路由表中对应的信息, 操作系统将会选择合适的地址来绑定这个socket, 并用这个地址来取代之前额通配符IP地址.

默认情况下, 任意两个socket不能被绑定在同一个源地址和源端口组合上.  比如: socketA 绑定在 A:X地址,  将socketB绑定在B:Y 地址,  其中 A和B是IP地址, X和Y是端口, 那么在A==B情况下, X!=Y,  在X==Y的情况下,  A!=B.  

如果一个socket被绑定在通配符IP地址下, 那么事实上本机上所有的IP都会被系统认为与其绑定了,  例如一个socket绑定了0.0.0.0:21,  这种情况下, 任何其他socket不论选择哪一个具体的IP地址, 其都不能再绑定在21端口下,  因为通配符0.0.0.0与所有本地IP都冲突.

## 2. BSD

### 2.1 SO_REUSEADDR

> 作用一: 改变了系统对待通配符IP地址冲突的方式

如果在一个socket绑定到某一个地址和端口之前设置了`SO_REUSEADDR`属性, 那么除非本socket产生了与另一个socket绑定到`完全`相同的源地址和源端口组合的冲突,  否则的话这个socket就可以成功绑定到这个地址端口对.

如: 如果不用SO_REUSEADDR属性,  我们将socketA绑定到 0.0.0.0:21, 那么任何将本机其他socket绑定到端口21的举动(如绑定到192.168.1.1:21) 都会导致`EADDRUNUSE`错误.   因为0.0.0.0 是一个通配符IP地址, 意味着任意一个IP地址,  所以任何其他本机上的IP地址21端口都被系统认为已被占用;   如果设置了SO_REUSEADDR属性, 因为0.0.0.0:21 和 182.168.1.1:21 并不是完全相同的地址端口对, 所以这样的绑定是可以的. 

需要`注意`的是:  无论socketA和socketB初始化顺序如何, 只要设置了SO_REUSEADDR, 绑定都会成功, 否则绑定不会成功.

一些可能结果:

| SO_REUSEADDR | socketA        | socketB        | result     |
| ------------ | -------------- | -------------- | ---------- |
| ON/OFF       | 192.168.1.1:21 | 192.168.1.1:21 | EADDRINUSE |
| ON/OFF       | 192.168.1.1:21 | 10.0.1.1:21    | OK         |
| ON/OFF       | 10.0.1.1:21    | 192.168.1.1:21 | OK         |
| OFF          | 192.168.1.1:21 | 0.0.0.0:21     | EADDRINUSE |
| OFF          | 0.0.0.0:21     | 192.168.1.1:21 | EADDRINUSE |
| ON           | 192.168.1.1:21 | 0.0.0.0:21     | OK         |
| ON           | 0.0.0.0:21     | 192.168.1.1:21 | OK         |
| ON/OFF       | 0.0.0.0:21     | 0.0.0.0:21     | EADDRINUSE |



> 改变了系统对TIME_WAIT 连接的处理

每一个socket都有其相应的发送缓冲区, 当调用send()时,  实际上数据是被添加到了发送缓冲区中.  故当我们调用了其`close()`方法时, 会进入一个 `TIME_WAIT`状态.  在这个状态下, socket将会持续尝试发送缓冲区中的数据直到`1.数据都被成功发送,2超时`, 超时被触发的情况下, socket将会被强制关闭.

操作系统的kernel在强制关闭一个socket之前的最长等待时间被称为`延迟时间(Linger Time)`, 在大部分系统中延迟时间都已经被全局是设置好了,  并且相对较长 (大部分系统将其设置为2min).

在理的问题是: 操作系统如何对待处于TIME_WAIT阶段的socket,  如果SO_REUSEADDR属性没有被设置, 处于TIME_WAIT阶段的socket仍然被认为是绑定在原来哪个地址和端口上的, 知道该socket被`完全关闭(结束TIME_WAIT阶段)`, 再次阶段任何其他企图将一个新socket绑定到该地址端口对的操作都将无法成功;    如果在新的socket上设置了`SO_REUSEADDR`属性,  并此时有另外一个socket绑定在当前的地址端口且处于TIME_WAIT阶段, 那么这个已存在的绑定关系将被忽略, 这样新的socket就可以成功绑定在此地址端口对上.

事实上处于`TIME_WAIT`阶段的额socket已经是半关闭状态了,  将一个新的socket绑定在这个地址端口对上不会有什么问题.  原来绑定在这个端口上的socket一般也不会对新的socket产生影响.  

`需要注意的时:` 在某些时候, 将一个新的socket绑定在一个处于TIME_WAIT阶段但仍在工作的socket时 产生一些我们并不想要的, 无法预料的影响.

`另外注意:`以上内容只要对新的socket设置了SO_REUSEADDR属性就成立,  至于原有的已经绑定在当前地址端口对上的socket是否设置SO_REUSEADDR属性并无影响.  决定`bind`操作是否成功的代码仅仅会检查新的被传递到bind方法的socket  SO_REUSEADDR属性.

### 2.2 SO_REUSEPORT

`作用:`SO_REUSEPORT允许允许我我们将任意数目的socket绑定到完全相同的源地址端口对上, 只要之前绑定的socket都设置了SO_REUSEPORT属性. 如果第一个绑定在该地址端口对上的socket没有设置SO_REUSEPORT, 无论之后的socket是否设置SO_REUSEPORT, 其都无法绑定在这个地址端口对上.  除非第一个绑定在这个地址端口对上的socket释放了这个绑定关系.   

`不同:`与SO_REUSEADDR不同的是, 处理SO_REUSEPORT的代码不仅会检查当前尝试绑定的socket的SO_REUSEPORT属性, 而且会检查之前已经绑定了当前尝试绑定地址端口对的socket的SO_REUSEPORT属性.

SO_REUSEPORT并不等于SO_REUSEADDR.  原因是:  如果一个已经绑定了地址的socket没有设置SO_REUSEPORT, 而另一个新的socket设置了SO_REUSEPORT且尝试绑定到与当前socket完全相同地址端口对, 将会失败.  同时如果当前socket已经处于TIME_WAIT阶段, 而这个设置了SO_REUSEPORT的新socket尝试绑定到该地址, 这个绑定也会失败.  为了能够将新的socket绑定到一个当前处于TIME_WAIT阶段的socket对应的地址端口对, 我们要么需要在绑定前设置其`SO_REUSEADDR`属性.  要么需要在绑定之前给两个socket都设置SO_REUSEPORT属性.  当前同时设置这个两个属性也是可以的.

### 2.3 connect() 返回 EADDRINUSE

于是bind()操作会返回`EADDRINUSE`错误. 但奇怪的是,  在我们调用connect() 操作时, 也有可能得到EADDRINUSE错误, 为什么呢?  为什么尝试连接的远程地址会被占用?  将多个socket连接到同一个远程地址的操作有什么问题吗?

如本文之前所有, 一个连接关系是由一个五元组确定的.  对于任意的连接而言, 这个五元组必须是唯一的,  否则的话, 系统将无法分辨两个连接.  现在当采用了 地址复用之后, 可以将两个采用相同协议的socket绑定到同一个地址端口上,  这意味这对两个socket而言, 五元组里的 `{<protocol> <src addr> <src port>}` 是相同的.  在这种情况下, 如果我们尝试将他们都连接到同一个远程地址端口上,  这两个连接的`五元组`将完全相同, 也就是说, 产生了两个完全相同的连接.   这在TCP协议中是不被允许的.

所以当两个采用相同协议的socket绑定到同一个地址端口对上后, 如果换尝试让他们和同一个目的地址端口对连接连接,  第二个调用connect() 方法的socket将报`EADDRINUSE`的错误.



## 其他os

FreeBSD/OpenBSD/NetBSD 和上面所属相同.

MacOS X 和上面相同.



### linux

在linux3.9 之前, 只有SO_REUSEADDR存在, 这个属性基本上同BSD系统下相同, 但其仍有两个重要的区别.

`区别一: ` 如果一个处于监听(服务器)状态下的TCP socket已经被绑定到一个通配符IP地址和一个特定端口下, 那么不论这两个socket有没有设置`SO_REUSEADDR`属性, 任何其他TCP socket都无法再被绑定到相同端口下. 即使另一个socket使用了一个具体的IP地址(像BSD系统中允许的那样)也不行.  而非监听(客户端)socket 无此限制

`区别二: `对于UDP来说, SO_REUSEADDR的作用和BSD中SO_REUSEPORT完全相同. 所以两个UDP socket 如果都设置了SO_REUSEADDR, 它们就可以被绑定在一组完全相同的地址端口对.

linux3.9 加入了`SO_REUSEPORT`属性. 只要所有socket(包括第一个)在绑定地址前设置了这个选项,  两个或多个, TCP 或 UDP, 监听(服务器) 或非监听(客户端) socket就可以绑定在完全相同的地址端口组合下.  同时为了`防止端口劫持`, 还有一个特别的限制: `所有试图绑定在相同地址端口组合的socket必须属于拥有相同用户ID的进程, 所以一个用户无法从另外一个用户那里偷窃端口`.

除此之外, 对于设置了SO_REUSEPORT属性的socket, linux socket还会执行一些别的系统所没有的特别操作: `对于绑定在同一地址端口组合上的UDP socket  kernel尝试在它们之间平均分配收到的数据包;  对于绑定在同一地址端口组合上的TCP监听socket,kernel尝试在它们之间平均分配收到的连接请求(调用accept()放大得到的请求). 这意味着相比其他允许地址复用但随即将受到的数据包或者连接请求分配给连接在同一地址端口组合上的socket系统而言, linux尝试了进行流量分配上的优化.`

比如: 一个简单的服务器进程的几个不同实例可以方便的使用SO_REUSEPORT来实现一个简单的负载均衡, 而且这个负载均衡由 kernel负责.

#### windows

windows仅有SO_REUSEADDR属性. 在windows中对一个socket设置SO_REUSEADDR的效果和在BSD下同时设置SO_REUSEADDR和SO_REUSEPORT相同. `区别在于:` 即使另一个已绑定地址的socket并没有设置SO_REUSEADDR, 一个设置了SO_REUSEADDR的socket总是可以绑定到另一个已绑定的socket完全相同的地址端口组合上, `这是危险的,因为它允许了一个应用从另一个已连接的端口上偷取数据`. 微软意识到这个问题, 因此添加了另一个socket选项: `SO_EXCLUSIVEADDRUSE`.  对一个socket设置`SO_EXCLUSIVEADDRUSE`可以确保一旦该socket绑定了一个地址端口组合,  任何其他socket, 不论是否设置SO_REUSEADDR与否, 都无法再绑定当前的地址端口组合.

#### solaris

solaris只提供SO_REUSEADDR, 且表现和BSD系统基本相同.  solaris中没有实现SO_REUSEPORT, 这意味着在solaris中无法将两个socket绑定到完全相同的地址端口组合下.

与windows类似, solaris为socket提供了独占属性: `SO_EXCLBIND`. 如果一个socket在绑定地址前设置了此选项, 即使其他socket设置了SO_REUSEADDR也将无法绑定至相同地址. 























