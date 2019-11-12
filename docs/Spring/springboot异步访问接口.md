[TOC]

# springboot接口的异步访问

当访问springboot的接口时，可能会有一些比较耗时的动作，或者会访问其他接口，而其他接口的返回时间就不好确定。故一个优化的方式就是，可以把比较耗时的动作，或者访问其他接口的动作使用异步来进行，最后根据最终的返回结果，来进行下一步的操作。

下面咱们介绍四种springboot的异步接口操作:

## 1.返回Callable

当springboot的controller函数返回值是Callable的时候，springmvc就会启动一个线程将Callable交给TaskExecutor去处理然后DispatcherServlet还有所有的spring拦截器都退出主线程，然后把response保持打开状态。当Callable执行结束之后，springMVC就会重新启动分配一个request请求，然后DispatcherServlet就重新调用和处理Callable异步执行的返回结果，然后返回视图.

```java
// 配置
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ConcurrentTaskExecutor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.web.servlet.config.annotation.AsyncSupportConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;

@Configuration
@EnableAsync
public class ThreadPoolConfigForCallable {

    public ThreadPoolTaskExecutor taskExecutor(){
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        taskExecutor.setCorePoolSize(50);
        taskExecutor.setAllowCoreThreadTimeOut(true);
        taskExecutor.setMaxPoolSize(80);
        taskExecutor.setQueueCapacity(200);
        taskExecutor.setThreadNamePrefix("Async-service");
        taskExecutor.setKeepAliveSeconds(60);
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());;
        taskExecutor.initialize();
        return taskExecutor;
    }

    /**
     *  此配置用于设置一个springmvc异步执行请求时的线程池
     *  当controller Callable 和 WebAsyncTask，而没有配置线程池时，会报下面的警告:
           !!!
         An Executor is required to handle java.util.concurrent.Callable return values.
         Please, configure a TaskExecutor in the MVC config under "async support".
         The SimpleAsyncTaskExecutor currently in use is not suitable under load.
         -------------------------------
         Request URI: '/webasyn.do'
         !!!

     添加后，警告就消失了
     * @return
     */
    @Bean
    public WebMvcConfigurer webMvcConfigurer(){
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
                configurer.setTaskExecutor(taskExecutor());
            }
        };
    }

    /**
     *  第二种配置 springmvc的线程池
     * @return
     */
    public WebMvcConfigurer anotherConfig(){
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
                configurer.setTaskExecutor(new ConcurrentTaskExecutor(Executors.newFixedThreadPool(50)));
            }
        };
    }
}
```



```java
// 使用
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.concurrent.Callable;
@Slf4j
@RestController
public class CallableController {

    @Autowired
    private RestTemplate restTemplate;

    /** 异步调用restful接口
     * 此是实现异步调用的方式一种
     * 当controller返回值是Callable的时候,springmvc就会启动一个线程将Callable交给TaskExecutor去处理
     * 然后DispatcherServelt还有所有的spring拦截器都退出主线程. 然后把response保持打开的状态
     * 当Callable执行结束之后,springmvc就会重新启动分配一个request请求,然后DispatcherServlet就重新
     * 调用和处理Callable异步执行的返回结果. 然后返回视图
     * @return
     */
    @GetMapping(value = "callable.do")
    public Callable<String> callable(){
        String url = "http://192.168.72.1:8888/getUser";
        log.info("current thread : {}",Thread.currentThread().getId());
        Callable<String> callable = new Callable<String>() {
            @Override
            public String call() throws Exception {
                log.info("call thread. current thread is :{}, into  call",Thread.currentThread().getId());
                ResponseEntity<String> entity = restTemplate.getForEntity(url, String.class);
                int statusCodeValue = entity.getStatusCodeValue();
                String body = entity.getBody();
                log.info("statusCodeValue= {},body={}",statusCodeValue,body);
                return body;
            }
        };
        log.info("main Thread:{}, return from controller..",Thread.currentThread().getId());
        return callable;
    }

}
```



## 2.WebAsyncTask

webAsyncTask增加了超时等回调方法，不过也是对Callable的封装。

```java
// 配置
// 因为同样是要执行Callable函数,故也要配置线程池
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ConcurrentTaskExecutor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.web.servlet.config.annotation.AsyncSupportConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;

@Configuration
@EnableAsync
public class ThreadPoolConfigForCallable {

    public ThreadPoolTaskExecutor taskExecutor(){
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        taskExecutor.setCorePoolSize(50);
        taskExecutor.setAllowCoreThreadTimeOut(true);
        taskExecutor.setMaxPoolSize(80);
        taskExecutor.setQueueCapacity(200);
        taskExecutor.setThreadNamePrefix("Async-service");
        taskExecutor.setKeepAliveSeconds(60);
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());;
        taskExecutor.initialize();
        return taskExecutor;
    }

    /**
     *  此配置用于设置一个springmvc异步执行请求时的线程池
     *  当controller Callable 和 WebAsyncTask，而没有配置线程池时，会报下面的警告:
           !!!
         An Executor is required to handle java.util.concurrent.Callable return values.
         Please, configure a TaskExecutor in the MVC config under "async support".
         The SimpleAsyncTaskExecutor currently in use is not suitable under load.
         -------------------------------
         Request URI: '/webasyn.do'
         !!!

     添加后，警告就消失了
     * @return
     */
    @Bean
    public WebMvcConfigurer webMvcConfigurer(){
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
                configurer.setTaskExecutor(taskExecutor());
            }
        };
    }

    /**
     *  第二种配置 springmvc的线程池
     * @return
     */
    public WebMvcConfigurer anotherConfig(){
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
                configurer.setTaskExecutor(new ConcurrentTaskExecutor(Executors.newFixedThreadPool(50)));
            }
        };
    }
}
```

```java
// 使用
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.context.request.async.WebAsyncTask;

import java.util.concurrent.Callable;

@Slf4j
@RestController
public class WebAsyncTaskController {
    @Autowired
    private RestTemplate restTemplate;

    @GetMapping(value = "webasyn.do")
    public WebAsyncTask<String> webAsyncTask(){
        String url = "http://192.168.72.1:8888/getUser";
        log.info("current thread : {},into webAsync controller .",Thread.currentThread().getId());
        WebAsyncTask<String> asyncTask = new WebAsyncTask<>(3000, new Callable<String>() {
            @Override
            public String call() throws Exception {
                log.info("into webAsyncTask ,current thread is {}",Thread.currentThread().getId());
                ResponseEntity<String> entity = restTemplate.getForEntity(url, String.class);
                int statusCodeValue = entity.getStatusCodeValue();
                String body = entity.getBody();
                log.info("statusCodeValue= {},body={}",statusCodeValue,body);
                return body;
            }
        });

        log.info("into controller ...........,thread ={}",Thread.currentThread().getId());
        // 完成的回调方法
        asyncTask.onCompletion(new Runnable() {
            @Override
            public void run() {
            log.info("completion thread, current thread is :{}",Thread.currentThread().getId());
            }
        });
        // 超时的回调方法
        asyncTask.onTimeout(new Callable<String>() {
            @Override
            public String call() throws Exception {
                log.info("Timeout thread is :{}",Thread.currentThread().getId());
                return null;
            }
        });
        // 错误的回调方法
        asyncTask.onError(new Callable<String>() {
            @Override
            public String call() throws Exception {
                log.error("error callBack...............");
                return null;
            }
        });
        log.info("return from  controller .........");
        return asyncTask;
    }
}
```





##3.DeferredResult 

此是直接把耗时代码放到了线程池中进行异步处理:

直接看代码吧:

```java
// 配置
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ConcurrentTaskExecutor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.web.servlet.config.annotation.AsyncSupportConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;

@Configuration
@EnableAsync
public class ThreadPoolConfigForCallable {

    @Bean("taskExecutor")
    public ThreadPoolTaskExecutor taskExecutor(){
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        taskExecutor.setCorePoolSize(50);
        taskExecutor.setAllowCoreThreadTimeOut(true);
        taskExecutor.setMaxPoolSize(80);
        taskExecutor.setQueueCapacity(200);
        taskExecutor.setThreadNamePrefix("Async-service");
        taskExecutor.setKeepAliveSeconds(60);
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());;
        taskExecutor.initialize();
        return taskExecutor;
    }
}
```

```java
// 执行器
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.context.request.async.DeferredResult;

@Slf4j
@Component
public class DeferredResultConfig {

    @Autowired
    private RestTemplate restTemplate;

    @Async
    public void execute(DeferredResult<String> deferredResult){
        log.info("DeferredResultConfig execute, thread = {}",Thread.currentThread().getId());
        String url = "http://192.168.72.1:8888/getUser";

        ResponseEntity<String> entity = restTemplate.getForEntity(url, String.class);
        int statusCodeValue = entity.getStatusCodeValue();
        String body = entity.getBody();
        log.info("get result is :statusCodeValue={},body={} ",statusCodeValue,body);
        deferredResult.setResult(body);
    }

}
```

```java
// 使用
import com.wk.config.DeferredResultConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.async.DeferredResult;

@Slf4j
@RestController
public class DeferredController {

    @Autowired
    private DeferredResultConfig resultConfig;

    @GetMapping(value = "deferred.do")
    public DeferredResult<String> executeSlowTask(){
        log.info("into DeferredResult executeSlowTask ,thread = {}",Thread.currentThread().getId());

        DeferredResult<String> deferredResult = new DeferredResult<>();
        // 异步执行
        resultConfig.execute(deferredResult);
        // 绑定回调方法
        deferredResult.onTimeout(new Runnable() {
            @Override
            public void run() {
                log.error("deferredResult Timeout ...................");
            }
        });

        deferredResult.onCompletion(new Runnable() {
            @Override
            public void run() {
                log.info("deferredResult onCompletion...........");
            }
        });
        log.info("current thread is :{}, result is :{}",Thread.currentThread().getId());
        return deferredResult;
    }
}
```



## 4.AsyncRestTemplate

异步进行http的访问：

```java
// 配置
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.AsyncRestTemplate;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AsyncRestTemplateConfig {
	// 异步访问
    @Bean
    public AsyncRestTemplate asyncRestTemplate(){
        AsyncRestTemplate asyncRestTemplate = new AsyncRestTemplate();
        /*asyncRestTemplate.setDefaultUriVariables();
        asyncRestTemplate.setErrorHandler();
        asyncRestTemplate.setMessageConverters();
        asyncRestTemplate.setUriTemplateHandler();
        asyncRestTemplate.setAsyncRequestFactory();*/
        return asyncRestTemplate;
    }
	// 同步访问
    @Bean
    public RestTemplate getRestTemplate(){
        RestTemplate restTemplate = new RestTemplate();
        return restTemplate;
    }
}
```

```java
// 使用
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.concurrent.FailureCallback;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.util.concurrent.SuccessCallback;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.AsyncRestTemplate;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class AsynTemplateController {

    @Autowired
    private AsyncRestTemplate asyncRestTemplate;

    @Autowired
    private RestTemplate restTemplate;

    @GetMapping(value = "synget.do")
    public String synGet(){
        String url = "http://192.168.72.1:8888/getUser";
        // 设置请求头
        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.setContentType(MediaType.APPLICATION_JSON);
        String json = "{\"name\":\"wang\"}";
        // 设置请求体
        HttpEntity<String> httpEntity = new HttpEntity<String>(json,httpHeaders);

        ResponseEntity<String> entity = restTemplate.getForEntity(url, String.class);
        int statusCodeValue = entity.getStatusCodeValue();
        String body = entity.getBody();
        log.info("statusCodeValue ={}, body={}",statusCodeValue,body);
        return "success";
    }

    @GetMapping(value = "asynget.do")
    public String AsyncGet(){
        String url = "http://192.168.72.1:8888/getUser";
        // 设置请求头
        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.setContentType(MediaType.APPLICATION_JSON);
        String json = "{\"name\":\"wang\"}";
        HttpEntity<String> httpEntity = new HttpEntity<String>(json,httpHeaders);
        //asyncRestTemplate.execute(url, HttpMethod.GET,);
        ListenableFuture<ResponseEntity<String>> entity = asyncRestTemplate.getForEntity(url, String.class);
        // 添加回调函数, 在回调函数中根据返回值进行下一步的操作
        entity.addCallback(new SuccessCallback<ResponseEntity<String>>() {
            @Override
            public void onSuccess(ResponseEntity<String> result) {
                log.info("success thread is :{}",Thread.currentThread().getId());
                int statusCodeValue = result.getStatusCodeValue();
                String body = result.getBody();
                log.info("statusCode :{}, body is:{}",statusCodeValue,body);
            }
        }, new FailureCallback() {
            @Override
            public void onFailure(Throwable ex) {
                log.info("success thread is :{}",Thread.currentThread().getId());
                log.info("failed , msg is :{}",ex.getMessage());
            }
        });

        // 第二种方法回调
        /*entity.addCallback(new ListenableFutureCallback<ResponseEntity<String>>() {
            @Override
            public void onFailure(Throwable ex) {
                log.info("onFailure thread is :{}",Thread.currentThread().getId());
                log.info("ListenableFutureCallback failed , msg is :{}",ex.getMessage());
            }

            @Override
            public void onSuccess(ResponseEntity<String> result) {
                log.info("onSuccess thread is :{}",Thread.currentThread().getId());
                int statusCodeValue = result.getStatusCodeValue();
                String body = result.getBody();
                log.info("ListenableFutureCallback statusCode :{}, body is:{}",statusCodeValue,body);
            }
        });*/

log.info("-------------------------------main thread ---------------:{}",Thread.currentThread().getId());
        return "success";
    }
}

```



