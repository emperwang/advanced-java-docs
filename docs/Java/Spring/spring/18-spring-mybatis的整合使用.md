[TOC]

# spring - mybatis 整合使用

接下来准备看一下spring和mybatis的整合源码，这里开篇先看一下spring整合mybatis时的一些配置。

首先添加pom依赖：

```xml
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>1.3.2</version>
</dependency>
```

在看一下具体的配置：

```java
@Configuration
// 扫描mapper的接口,并注册到容器中
@MapperScan(basePackages = {"com.wk.springdemo.mapper"})
@ComponentScan(value = {"com.wk.springdemo.service"})
@EnableTransactionManagement
public class MybatisConfig {
    //private String MapperLocation = "classpath: /*Mapper.xml";
    private String MapperLocation = "classpath:/mapper/*.xml";

    // 数据源
    @Bean
    public DataSource dataSource(){
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("com.mysql.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql://localhost:3306/ssm?useSSL=false&allowMultiQueries=true");
        dataSource.setUsername("root");
        dataSource.setPassword("admin");
        return dataSource;
    }

    // sqlsessionfactory
    @Bean("sqlSessionFactory")
    public SqlSessionFactory sqlSessionFactory() throws Exception {
        PathMatchingResourcePatternResolver patternResolver = new PathMatchingResourcePatternResolver();
        SqlSessionFactoryBean sessionFactoryBean = new SqlSessionFactoryBean();
        sessionFactoryBean.setDataSource(dataSource());
        sessionFactoryBean.setMapperLocations(patternResolver.getResources(MapperLocation));
        return sessionFactoryBean.getObject();
    }

    // 事务管理器
    @Bean
    public PlatformTransactionManager transactionManager(){
        DataSourceTransactionManager transactionManager = new DataSourceTransactionManager();
        transactionManager.setDataSource(dataSource());
        return transactionManager;
    }
}
```

mapper接口以及sql文件：

```java
import com.wk.entity.User;
import org.apache.ibatis.annotations.Param;
import java.util.List;
import java.util.Map;
/**
 * descripiton:
 *
 * @author: wk
 * @time: 19:10 2019/12/31
 * @modifier:
 */
public interface UserMapper {
    List<User> selectAll();
    /**
     * 使用 注解 指定参数名字
     * @param id
     * @return
     */
    User selectById(@Param("id") Integer id);
    /**
     * 使用 map 其中的key为参数的名字
     * @param
     * @return
     */
    User selectByMap(Map<String, String> map);
    /**
     * 根据条件选择性进行查询操作
     * @param user
     * @return
     */
    List<User> chooseSelect(User user);
    int updateAgeList(List<User> users);

    /**
     *  选择性的更新操作
     * @param user
     * @return
     */
    int updateSelectFieldTrim(User user);

    int updateSelectField(User user);

    int batchInsert(List<User> list);

    int insertOne(User user);

    // todo  此函数测试不通过
    int batchDeletes(List<User> list);

    int batchDelArray(Integer[] id);
}
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.wk.springdemo.mapper.UserMapper">
    <resultMap id="baseResult" type="com.wk.entity.User">
        <id property="id" column="id" jdbcType="INTEGER"></id>
        <result property="name" column="name" jdbcType="VARCHAR"></result>
        <result property="age" column="age" jdbcType="INTEGER"></result>
        <result property="address" column="address" jdbcType="VARCHAR"></result>
    </resultMap>

    <sql id="baseSql">
        id,name,age,address
    </sql>

    <select id="selectById" parameterType="java.lang.Integer" resultMap="baseResult">
        select <include refid="baseSql"/> from USER WHERE id=#{id}
    </select>

    <select id="selectByMap" parameterType="java.util.Map" resultType="com.wk.entity.User">
        select <include refid="baseSql"/> from USER WHERE id=#{id}
    </select>

    <select id="selectAll" resultMap="baseResult">
        SELECT <include refid="baseSql"/> FROM user;
    </select>

    <!--choose select-->
    <select id="chooseSelect" parameterType="com.wk.entity.User" resultMap="baseResult">
        SELECT <include refid="baseSql"/> FROM USER
        <where>
            <choose>
                <when test="id != null and id != ''">
                    AND id = #{id}
                </when>
                <when test="name != null and name != ''">
                    AND  name = #{name}
                </when>
                <when test="age != null and age != ''">
                    AND age = #{age}
                </when>
                <when test="address != null and address != ''">
                    AND address = #{address}
                </when>
                <otherwise>
                    id = 6
                </otherwise>
            </choose>
        </where>
    </select>


    <!-- 批量更新-->
    <update id="updateAgeList" parameterType="com.wk.entity.User">
        <foreach collection="list" separator=";" item="idx" close=";">
            UPDATE user SET age=#{idx.age} where id=#{idx.id}
        </foreach>
    </update>

    <!--更新一个记录中的某些字段-->
    <update id="updateSelectField" parameterType="com.wk.entity.User">
        UPDATE USER
        <set>
            <if test="name!= null and name != ''">
                name=#{name},
            </if>
            <if test="age != null and age != ''">
                age=#{age},
            </if>
            <if test="address != null and address != ''">
                address=#{address}
            </if>
        </set>
        WHERE id=#{id}
    </update>
    <!--选择性的更新操作-->
    <update id="updateSelectFieldTrim" parameterType="com.wk.entity.User">
        UPDATE USER
        <trim prefix="set" suffixOverrides=",">
            <if test="name!=null &amp;&amp; name != ''">
                name=#{name},
            </if>
            <if test="age !=null &amp;&amp; age != ''">
                age=#{},
            </if>
            <if test="address!=null &amp;&amp; address != ''">
                address=#{address}
            </if>
        </trim>
        WHERE id=#{id}
    </update>

    <!--批量添加-->
    <insert id="batchInsert" parameterType="java.util.List">
        INSERT into USER(name,age,address) VALUES
        <foreach collection="list" item="itm" separator=",">
            (#{itm.name}, #{itm.age}, #{itm.address})
        </foreach>
    </insert>

    <insert id="insertOne" parameterType="com.wk.entity.User">
        INSERT into USER(name,age,address) VALUES(#{name}, #{age}, #{address});
    </insert>

    <!--目前有问题-->
    <delete id="batchDeletes" parameterType="java.util.List">
        DELETE FROM USER WHERE id IN
        <foreach collection="list" item="itm" open="(" separator="," close=");">
            #{itm.id, jdbcType='INTEGER'}
        </foreach>
    </delete>

    <delete id="batchDelArray" parameterType="int">
        DELETE FROM user WHERE  id IN
        <foreach collection="array"  item="id" open="(" separator="," close=");">
            #{id}
        </foreach>
    </delete>
</mapper>
```

service的引用:

```java
import com.wk.entity.User;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
public interface UserService {
    // 加上此注解,会生效;验证:
    // 1. 添加此注解, 实现类引发异常,事务回滚,插入不会成功
    // 2. 去除此注解, 实现类引发异常,事务不会回滚,插入成功
    @Transactional(isolation = Isolation.DEFAULT)
    int insertOne(User user);
    List<User> selectAll();
}
```

```java
import com.wk.entity.User;
import com.wk.springdemo.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private UserMapper userMapper;

    // 由此可见 把注解放到接口上,同样是生效的
    @Override
    //@Transactional(isolation = Isolation.DEFAULT)
    public int insertOne(User user) {
        int count = 0;
        count += userMapper.insertOne(user);
        int i = 1/0;
        return count;
    }
    @Override
    @Transactional(isolation = Isolation.DEFAULT, readOnly = true)
    public List<User> selectAll() {
        List<User> users = userMapper.selectAll();
        System.out.println(users.toString());
        return users;
    }
}
```

调用:

```java
import com.wk.entity.User;
import com.wk.springdemo.config.MybatisConfig;
import com.wk.springdemo.mapper.UserMapper;
import com.wk.springdemo.service.UserService;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

public class SpringStarter {
    public static void main(String[] args) {
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MybatisConfig.class);
        insertAndGet(context);
    }
    public static void insertAndGet(ApplicationContext context){
        User user = new User();
        user.setAge(1);
        user.setAddress("bj");
        user.setName("zhangsan");
        UserService userService = context.getBean(UserService.class);
        userService.insertOne(user);
        userService.selectAll();
    }
    public static void getById(ApplicationContext context, int id){
        UserMapper bean = context.getBean(UserMapper.class);
        User user = bean.selectById(1);
        System.out.println(user.toString());
    }
}
```

这里就可以正常使用。











































