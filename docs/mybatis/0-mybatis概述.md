# mybatis概述

使用了mybatis这么久，其实现了java接口和sql语句的对应，并且可让使用者对sql进行编辑，使其灵活性大大增强。使用了这么久mybatis，如何去介绍其是一个什么样的框架呢？

官方介绍：

```shell
MyBatis is a first class persistence framework with support for custom SQL, stored procedures and advanced mappings. MyBatis eliminates almost all of the JDBC code and manual setting of parameters and retrieval of results. MyBatis can use simple XML or Annotations for configuration and map primitives, Map interfaces and Java POJOs (Plain Old Java Objects) to database records. 
```

可以看到官方介绍其是一个持久性框架，支持个性化SQL。消除了几乎所有的JDBC代码以及参数设置和结果遍历。其可以使用简单的xml配置以及注解进行配置。

其实，我个人觉得mybatis就是对JDBC代码的一个封装，其中所有的操作，都是为了更好的封装JDBC，让人更方便的去使用。

简单JDBC：

```java
Class.forName("com.mysql.jdbc.Driver");     // 加载驱动
Connection conn=DriverManager.getConnection(url,"root","hello"); // 建立连接
String sql="select * from new_table where t1=? and t2=?"; // 编写sql
PreparedStatement stm = conn.prepareStatement(sql); // 创建执行语句
stm.setString(1, "1");		// 设置参数
stm.setString(2, "aa");
ResultSet rs =stm.executeQuery();  // 执行
conn.close();	// 关闭连接

```

接下来，怎么就下面几个方面分析一下mybatis源码：

1. [配置文件的加载以及分析](1配置文件解析.md)
2. [mapper接口和xml中的sql对应关系](2-接口和xml文件的对应关系.md)
3. [一个接口的执行流程](3-一个接口函数的执行流程.md)
4. [sql参数的配置](4-sql参数的配置.md)
5. [mybatis自带的连接池](5-连接池.md)
6. [mybatis对事务的管理](6-事务管理.md)
7. [把结果映射到javaBean中](8-查询结果如何映射到java类中.md)