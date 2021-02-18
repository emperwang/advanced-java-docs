# logback配置文件中获取自定义属性

## 1.使用PropertyDefinerBase

配置：

```java
package com.wk.config;

import ch.qos.logback.core.PropertyDefinerBase;
import lombok.extern.slf4j.Slf4j;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 *  可以使用此方法在logback中设置想获取的属性
 *  <define name="hostname" class="com.wk.config.logBackConfig" />
 */
@Slf4j
public class logBackConfig extends PropertyDefinerBase {
    @Override
    public String getPropertyValue() {
        try {
            InetAddress localHost = InetAddress.getLocalHost();
            String hostName = localHost.getHostName();
            log.info("get hostname is :{}",hostName);
            return hostName;
        } catch (UnknownHostException e) {
            e.printStackTrace();
        }
        return null;
    }
}
```

logback 配置:

```xml
<!--在logback.xml中添加此配置,就可以在logback中通过 ${hostname}来使用了-->
<!--第一种配置属性的方法: custome hostName property-->
<define name="hostname" class="com.wk.config.logBackConfig" />
```



## 2.使用ClassicConverter

```java
package com.wk.config;

import ch.qos.logback.classic.pattern.ClassicConverter;
import ch.qos.logback.classic.spi.ILoggingEvent;
import lombok.extern.slf4j.Slf4j;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 *  logback第二种获取属性的方法
 */
@Slf4j
public class logIpConfig extends ClassicConverter{

    @Override
    public String convert(ILoggingEvent event) {
        try {
            String hostName = InetAddress.getLocalHost().getHostName();
            return hostName;
        } catch (UnknownHostException e) {
            e.printStackTrace();
        }
        return null;
    }
}
```

```xml
<!--就可以通过 ${hostname}来进行使用-->
<!--logback 配置-->
<conversionRule conversionWord="hostName" converterClass="com.wk.config.logIpConfig"/>
```



## 3.直接获取系统变量中的value

在linux系统中，springboot环境变量中key为host.name的value就是hostname。

```xml
<!--直接获取springboot中环境变量的值-->
<springProperty scope="context" name="hostname" source="host.name" />
```



## 4.把要获取的值放到System环境变量中

在项目真正启动前，先把hostname的值设置到系统变量中。此处使用的是springboot项目，借助于springboot的环境变量获取；设置hostname到system如下：

```java
@SpringBootApplication
public class startApp {
    public static void main(String[] args) {
        // 此处就是使用1中的类，直接获取hostname
        String hostName = new logBackConfig().getPropertyValue();
        System.setProperty("hostname",hostName);
        SpringApplication.run(startApp.class,args);
    }
}
```

logback配置如下：

```xml
<!--直接获取环境变量中的值-->
<springProperty scope="context" name="hostname" source="hostname" />
```

## 5. 借助springboot的context获取

借助于springboot的环境变量进行设置，此处操作和(方法)4是一样的。

