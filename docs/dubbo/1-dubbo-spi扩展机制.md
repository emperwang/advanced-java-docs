[TOC]

# dubbo中spi扩展机制

了解本篇前，最好看一下jdk中自带的SPI机制的实现，两个对比更容易看出不同点。

jdk-spi路径: docs/JDK/spi/1-SPI实现原理.md.

这里同于以一个dubbo-spi的demo作为入口来进行分析：

```java
package demo2;
import com.alibaba.dubbo.common.URL;
import com.alibaba.dubbo.common.extension.Adaptive;
import com.alibaba.dubbo.common.extension.SPI;

@SPI("dog")
public interface HelloService {
    void sayHello();
    @Adaptive
    void sayHello(URL url);
}

```

具体的实现类:

```java
package demo2;

import com.alibaba.dubbo.common.URL;
public class DogHelloServiceImpl implements HelloService {
    @Override
    public void sayHello() {
        System.out.println("hello dog.");
    }
    @Override
    public void sayHello(URL url) {
        System.out.println("dog hello  " + url);
    }
}

package demo2;
import com.alibaba.dubbo.common.URL;
public class HumanHelloServiceImpl implements HelloService {
    @Override
    public void sayHello() {
        System.out.println("human say hello.");
    }
    @Override
    public void sayHello(URL url) {
        System.out.println("hello human  " + url);
    }
}
```

dubbo约定的服务配置路径有三个分别为:

1. META-INF/dubbo/interval
2. META-INF/dubbo
3. META-INF/services  此路径和jdk spi一样

配置文件名字为要加载类的全限定类名。配置如下：

在META-INF/dubbo/demo2.HelloService 中写入一下内容：

```properties
dog=demo2.DogHelloServiceImpl
human=demo2.HumanHelloServiceImpl
```

启动类:

```java
public class DSPI2Starter {
    public static void main(String[] args) {
        /**
         * 这里注意? 后面:
         * hello.service=HelloService= 后面就是在配置文件中的key
         */
        final URL url = URL.valueOf("test://localhost/hello?hello.service=human");
        //final URL url = URL.valueOf("test://localhost/hello");
        final ExtensionLoader<HelloService> extensionLoader = ExtensionLoader.getExtensionLoader(HelloService.class);
        // 前提是使用test://localhost/hello这个没有参数的URL: 因为在 HelloService 中 SPI指定了默认值为dog,
        // 所以这里会加载dog对应的实现类
        // 如果使用了test://localhost/hello?hello.service=human, 那这里就会使用 human对应的实现类
        // 此是获取自适应的 类
        System.out.println("=====================adaptive================================");
        HelloService adaptive = extensionLoader.getAdaptiveExtension();
        adaptive.sayHello(url);
        System.out.println("======================default===============================");
        // 获取默认的实现
        HelloService defaultExtension = extensionLoader.getDefaultExtension();
        defaultExtension.sayHello(url);
        System.out.println("=======================all impl==============================");
        // 获取所有的实现
        Set<String> supportedExtensions = extensionLoader.getSupportedExtensions();
        supportedExtensions.forEach( s-> {
            System.out.println(s);
            extensionLoader.getExtension(s).sayHello(url);
        });
    }
}
```

通过测试类，看到可以获取三种类型的实现类：

1. 自适应实现类
2. 默认实现类
3. 所有实现类

自适应实现类有两种：

1. 类上有 Adaptive注解的类
2. 在类的方法上标记了Adaptive注解的类，此方式的实现类会从两个地方寻找
   1. 从url中查找，如test://localhost/hello?hello.service=human  ，在url的parameter中设置了的，也就是会查找humane对应的实现类
   2. 如果url parameter中没有的话，会使用spi 注解中指定的

下面就来看一下dubbo中spi的实现：

> com.alibaba.dubbo.common.extension.ExtensionLoader#getExtensionLoader

```java
// 扩展加载
@SuppressWarnings("unchecked")
public static <T> ExtensionLoader<T> getExtensionLoader(Class<T> type) {
    // 参数为 null,抛出异常
    if (type == null)
        throw new IllegalArgumentException("Extension type == null");
    // 不是接口, 抛出异常
    if (!type.isInterface()) {
        throw new IllegalArgumentException("Extension type(" + type + ") is not interface!");
    }
    // 没有SPI 注解,抛出异常
    if (!withExtensionAnnotation(type)) {
        throw new IllegalArgumentException("Extension type(" + type +
        ") is not extension, because WITHOUT @" + SPI.class.getSimpleName() + " Annotation!");
    }
    // 先去缓存中获取此 type 类型有没有 loader实例
    // 如果缓存中没有,则创建一个
    ExtensionLoader<T> loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
    if (loader == null) {
        // 创建一个放入到  缓存中
        EXTENSION_LOADERS.putIfAbsent(type, new ExtensionLoader<T>(type));
        loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
    }
    return loader;
}
```

获取ExtensionLoader的操作，ExtensionLoader类的构造器为私有，故此方法类似于工厂方法。方法先做些校验，之后从缓存中获取，缓存中没有，则创建 一个ExtensionLoader，并把创建的放入缓存。

```java
        private ExtensionLoader(Class<?> type) {
            // 对应的要加载的类型
            this.type = type;
            objectFactory = (type == ExtensionFactory.class ? null : ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension());
        }
```

下面看一下自适应类的获取：

> com.alibaba.dubbo.common.extension.ExtensionLoader#getAdaptiveExtension

```java
// 获取自适应 的 extension
@SuppressWarnings("unchecked")
public T getAdaptiveExtension() {
    // 查看缓存中是否有实例
    Object instance = cachedAdaptiveInstance.get();
    if (instance == null) {
        // 双重判定锁
        if (createAdaptiveInstanceError == null) {
            synchronized (cachedAdaptiveInstance) {
                instance = cachedAdaptiveInstance.get();
                if (instance == null) {
                    try {
                        // 创建一个
                        // 并放入到 缓存中
                        instance = createAdaptiveExtension();
                        cachedAdaptiveInstance.set(instance);
                    } catch (Throwable t) {
                        createAdaptiveInstanceError = t;
                        throw new IllegalStateException("fail to create adaptive instance: " + t.toString(), t);
                    }
                }
            }
        } else {
            throw new IllegalStateException("fail to create adaptive instance: " + createAdaptiveInstanceError.toString(), createAdaptiveInstanceError);
        }
    }
```

这里使用了双重判定锁，其实在spi的实现中有多处都是双重判定锁，因为这里使用了很多的缓存操作。这里先从缓存中获取自适应类的实例，缓存中没有则去创建一个，创建完成后放入到缓存中。

> com.alibaba.dubbo.common.extension.ExtensionLoader#createAdaptiveExtension

```java
    @SuppressWarnings("unchecked")
    private T createAdaptiveExtension() {
        try {
            // 先获取自适应类, 并创建实例
            // 之后调用injectExtension 通过set方法来进行注入
            return injectExtension((T) getAdaptiveExtensionClass().newInstance());
        } catch (Exception e) {
            throw new IllegalStateException("Can not create adaptive extension " + type + ", cause: " + e.getMessage(), e);
        }
    }
```

看到这里先获取到Adaptive扩展类的实例，之后调用injectExtension调用set来进行注入操作。

> com.alibaba.dubbo.common.extension.ExtensionLoader#getAdaptiveExtensionClass

```java
// 获取extensionClass
private Class<?> getAdaptiveExtensionClass() {
    // 开始加载实现类
    getExtensionClasses();
    // 如果 类上 有注释  Adaptive 那么会先使用 此类
    // 如: ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension()
    // 获取ExtensionFactory 类时,会获取 AdaptiveExtensionFactory,因为此类上有注解 @Adaptive
    if (cachedAdaptiveClass != null) {
        return cachedAdaptiveClass;
    }
    // 没有缓存,则创建缓存
    return cachedAdaptiveClass = createAdaptiveExtensionClass();
}
```

这里就开始去约定的目录加载实现类，之后cachedAdaptiveClass如果有值，则使用此值，否则创建子适应类。

> com.alibaba.dubbo.common.extension.ExtensionLoader#getExtensionClasses

```java
// 获取 extensionClass
private Map<String, Class<?>> getExtensionClasses() {
    Map<String, Class<?>> classes = cachedClasses.get();
    // 双重判定锁
    if (classes == null) {
        synchronized (cachedClasses) {
            classes = cachedClasses.get();
            if (classes == null) {
                // 缓存中没有,则尝试加载
                classes = loadExtensionClasses();
                cachedClasses.set(classes);
            }
        }
    }
    return classes;
}
```

又是双重判定锁哦。

> com.alibaba.dubbo.common.extension.ExtensionLoader#loadExtensionClasses

```java
// synchronized in getExtensionClasses
private Map<String, Class<?>> loadExtensionClasses() {
    // 获取要加载接口的SPI注解信息
    final SPI defaultAnnotation = type.getAnnotation(SPI.class);
    if (defaultAnnotation != null) {
        // spi 注解的 defaultValue值
        String value = defaultAnnotation.value();
        if ((value = value.trim()).length() > 0) {
            String[] names = NAME_SEPARATOR.split(value);
            if (names.length > 1) {
                throw new IllegalStateException("more than 1 default extension name on extension " + type.getName()
                                                + ": " + Arrays.toString(names));
            }
            // 获取 spi 注解中的 defaultValue值
            // 并缓存 起来
            if (names.length == 1) cachedDefaultName = names[0];
        }
    }
    // 容器记录 要加载的类
    Map<String, Class<?>> extensionClasses = new HashMap<String, Class<?>>();
    // 约定路径 META-INF/dubbo/internal/
    loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY);
    // 约定路径 META-INF/dubbo/
    loadDirectory(extensionClasses, DUBBO_DIRECTORY);
    // 约定路径 同样 也是java spi路径:  META-INF/services
    loadDirectory(extensionClasses, SERVICES_DIRECTORY);
    return extensionClasses;
}
```

看到这里就记录下了SPI注解中设置的默认实现类的name(此name不是类名,对应配置文件中的key)，之后就去约定的目录中进行加载操作。

> com.alibaba.dubbo.common.extension.ExtensionLoader#loadDirectory

```java
// 去目录中加载实现类
private void loadDirectory(Map<String, Class<?>> extensionClasses, String dir) {
    // 根据约定的目录 以及 要加载的接口类名, 确定文件
    String fileName = dir + type.getName();
    try {
        Enumeration<java.net.URL> urls;
        // 查找类加载器
        ClassLoader classLoader = findClassLoader();
        // 使用类加载器 去获取 文件 url路径
        if (classLoader != null) {
            urls = classLoader.getResources(fileName);
        } else {
            urls = ClassLoader.getSystemResources(fileName);
        }
        if (urls != null) {
            // 遍历所有的 配置文件,并进行加载
            while (urls.hasMoreElements()) {
                java.net.URL resourceURL = urls.nextElement();
                // 加载文件
                loadResource(extensionClasses, classLoader, resourceURL);
            }
        }
    } catch (Throwable t) {
        logger.error("Exception when load extension class(interface: " +
                     type + ", description file: " + fileName + ").", t);
    }
}
```

> com.alibaba.dubbo.common.extension.ExtensionLoader#loadResource

```java
// 加载实例
private void loadResource(Map<String, Class<?>> extensionClasses, ClassLoader classLoader, java.net.URL resourceURL) {
    try {
        // BufferedReader  文件读取流
        BufferedReader reader = new BufferedReader(new InputStreamReader(resourceURL.openStream(), "utf-8"));
        try {
            String line;
            // 遍历文件中的 行
            while ((line = reader.readLine()) != null) {
                // # 是注释符
                final int ci = line.indexOf('#');
                // 去除注释的符号
                if (ci >= 0) line = line.substring(0, ci);
                line = line.trim();
                if (line.length() > 0) {
                    try {
                        String name = null;
                        int i = line.indexOf('=');
                        if (i > 0) {
                            // 这里就跟 dubbo spi配置文件有关了
                            // 此配置类似 properties文件
                            name = line.substring(0, i).trim();
                            line = line.substring(i + 1).trim();
                        }
                        // 如果指定了类,那么就开始加载类
                        if (line.length() > 0) {
                            // Class.forName 加载类
                            // -----重点-----  这里就进行了加载
                            loadClass(extensionClasses, resourceURL, Class.forName(line, true, classLoader), name);
                        }
                    } catch (Throwable t) {
                        IllegalStateException e = new IllegalStateException("Failed to load extension class(interface: " + type + ", class line: " + line + ") in " + resourceURL + ", cause: " + t.getMessage(), t);
                        exceptions.put(line, e);
                    }
                }
            }
        } finally {
            reader.close();
        }
    } catch (Throwable t) {
        logger.error("Exception when load extension class(interface: " +
                     type + ", class file: " + resourceURL + ") in " + resourceURL, t);
    }
}
```

> com.alibaba.dubbo.common.extension.ExtensionLoader#loadClass

```java
// 开始加载类
private void loadClass(Map<String, Class<?>> extensionClasses, java.net.URL resourceURL, Class<?> clazz, String name) throws NoSuchMethodException {
    // 类型不符,则抛出异常
    if (!type.isAssignableFrom(clazz)) {
        throw new IllegalStateException("Error when load extension class(interface: " +
                                        type + ", class line: " + clazz.getName() + "), class "
                                        + clazz.getName() + "is not subtype of interface.");
    }
    // 如果上声明了 Adaptive,则缓存下载
    // cachedAdaptiveInstance
    if (clazz.isAnnotationPresent(Adaptive.class)) {
        if (cachedAdaptiveClass == null) {
            cachedAdaptiveClass = clazz;
        } else if (!cachedAdaptiveClass.equals(clazz)) {
            throw new IllegalStateException("More than 1 adaptive class found: "
                                            + cachedAdaptiveClass.getClass().getName()
                                            + ", " + clazz.getClass().getName());
        }
        // 如果类没有默然构造器,则不是 wrapper类
    } else if (isWrapperClass(clazz)) {
        Set<Class<?>> wrappers = cachedWrapperClasses;
        if (wrappers == null) {
            // 创建容器
            cachedWrapperClasses = new ConcurrentHashSet<Class<?>>();
            wrappers = cachedWrapperClasses;
        }
        // 缓存器此 有默认构造器的 类
        wrappers.add(clazz);
    } else {
        clazz.getConstructor();
        if (name == null || name.length() == 0) {
            name = findAnnotationName(clazz);
            if (name.length() == 0) {
                throw new IllegalStateException("No such extension name for the class " + clazz.getName() + " in the config " + resourceURL);
            }
        }
        String[] names = NAME_SEPARATOR.split(name);
        if (names != null && names.length > 0) {
            Activate activate = clazz.getAnnotation(Activate.class);
            if (activate != null) {
                cachedActivates.put(names[0], activate);
            }
            for (String n : names) {
                if (!cachedNames.containsKey(clazz)) {
                    cachedNames.put(clazz, n);
                }
                // 如果 extension中 不包括此 name,则把此name以及其对应的class 放入到 extension中
                Class<?> c = extensionClasses.get(n);
                if (c == null) {
                    extensionClasses.put(n, clazz);
                } else if (c != clazz) {
                    throw new IllegalStateException("Duplicate extension " + type.getName() + " name " + n + " on " + c.getName() + " and " + clazz.getName());
                }
            }
        }
    }
}
```

这里看到和jdk spi的区别了吗? 这里只是进行了加载，没有进行实例化，jdk spi会进行实例化，并缓存起来。在这里解析文件时，和jdk spi的处理很像。

这一溜解析下来，cachedAdaptiveClass只有在类上有Adaptive注解的才会设置，说明刚才一溜都没有设置，也就是会继续向下，创建自适应类，此处会生成动态代码，不用怕，会把生成的代码贴出来，大家一看其实就明白了。

> com.alibaba.dubbo.common.extension.ExtensionLoader#createAdaptiveExtensionClass

```java
// 创建自适应 extension
private Class<?> createAdaptiveExtensionClass() {
    // -----重点----
    // 生成自适应类代码
    String code = createAdaptiveExtensionClassCode();
    // 查找 类加载器
    ClassLoader classLoader = findClassLoader();
    // 加载编译器, 默认是使用 javassist
    com.alibaba.dubbo.common.compiler.Compiler compiler = ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.common.compiler.Compiler.class).getAdaptiveExtension();
    // 编译代码
    return compiler.compile(code, classLoader);
}
```

这里首先生成了自适应的代码字符串，之后使用javassist去吧生成的代码字符串记性编译，此生成的class就是自适应的类实例了。

看一下代码生成操作：

> com.alibaba.dubbo.common.extension.ExtensionLoader#createAdaptiveExtensionClassCode

```java
    // 生成自适应代码
    private String createAdaptiveExtensionClassCode() {
        StringBuilder codeBuilder = new StringBuilder();
        Method[] methods = type.getMethods();
        boolean hasAdaptiveAnnotation = false;
        // 遍历接口中所有方法, 查看方法上是否有 Adaptive 注解
        for (Method m : methods) {
            if (m.isAnnotationPresent(Adaptive.class)) {
                // 有方法存在注解,则 设置标志位 true
                hasAdaptiveAnnotation = true;
                break;
            }
        }
        // no need to generate adaptive class since there's no adaptive method found.
        // 所有 type接口方法中 都没有此 Adaptive注解,抛出异常
        if (!hasAdaptiveAnnotation)
            throw new IllegalStateException("No adaptive method on extension " + type.getName() + ", refuse to create the adaptive class!");
        // 包名 和 导入包
        // 以及类名
        codeBuilder.append("package ").append(type.getPackage().getName()).append(";");
        codeBuilder.append("\nimport ").append(ExtensionLoader.class.getName()).append(";");
        codeBuilder.append("\npublic class ").append(type.getSimpleName()).append("$Adaptive").append(" implements ").append(type.getCanonicalName()).append(" {");
        // 遍历所有方法
        for (Method method : methods) {
            // 方法返回类型
            Class<?> rt = method.getReturnType();
            // 方法参数类型
            Class<?>[] pts = method.getParameterTypes();
            // 方法异常类型
            Class<?>[] ets = method.getExceptionTypes();
            // 获取方法上的 Adaptive 注解信息
            Adaptive adaptiveAnnotation = method.getAnnotation(Adaptive.class);
            StringBuilder code = new StringBuilder(512);
            // 如果此方法上没有 Adaptive注解,则追加项目的代码
            if (adaptiveAnnotation == null) {
                code.append("throw new UnsupportedOperationException(\"method ")
                        .append(method.toString()).append(" of interface ")
                        .append(type.getName()).append(" is not adaptive method!\");");
            } else {    // 有Adaptive注解的方法处理
                // 查找 参数类型为 URL的 index
                int urlTypeIndex = -1;
                for (int i = 0; i < pts.length; ++i) {
                    if (pts[i].equals(URL.class)) {
                        urlTypeIndex = i;
                        break;
                    }
                }
                // found parameter in URL type
                // 找到 URL 参数的 处理
                if (urlTypeIndex != -1) {
                    // Null Point check
                    String s = String.format("\nif (arg%d == null) throw new IllegalArgumentException(\"url == null\");",
                            urlTypeIndex);
                    code.append(s);

                    s = String.format("\n%s url = arg%d;", URL.class.getName(), urlTypeIndex);
                    code.append(s);
                }
                // did not find parameter in URL type
                // 没有找到URL 类型的处理
                else {
                    String attribMethod = null;

                    // find URL getter method
                    LBL_PTS:
                    for (int i = 0; i < pts.length; ++i) {
                        Method[] ms = pts[i].getMethods();
                        for (Method m : ms) {
                            String name = m.getName();
                            if ((name.startsWith("get") || name.length() > 3)
                                    && Modifier.isPublic(m.getModifiers())
                                    && !Modifier.isStatic(m.getModifiers())
                                    && m.getParameterTypes().length == 0
                                    && m.getReturnType() == URL.class) {
                                urlTypeIndex = i;
                                attribMethod = name;
                                break LBL_PTS;
                            }
                        }
                    }
                    if (attribMethod == null) {
                        throw new IllegalStateException("fail to create adaptive class for interface " + type.getName()
                                + ": not found url parameter or url attribute in parameters of method " + method.getName());
                    }

                    // Null point check
                    String s = String.format("\nif (arg%d == null) throw new IllegalArgumentException(\"%s argument == null\");",
                            urlTypeIndex, pts[urlTypeIndex].getName());
                    code.append(s);
                    s = String.format("\nif (arg%d.%s() == null) throw new IllegalArgumentException(\"%s argument %s() == null\");",
                            urlTypeIndex, attribMethod, pts[urlTypeIndex].getName(), attribMethod);
                    code.append(s);

                    s = String.format("%s url = arg%d.%s();", URL.class.getName(), urlTypeIndex, attribMethod);
                    code.append(s);
                }
                // 获取 Adaptive 配置的 value 数组
                String[] value = adaptiveAnnotation.value();
                // value is not set, use the value generated from class name as the key
                if (value.length == 0) {
                    char[] charArray = type.getSimpleName().toCharArray();
                    StringBuilder sb = new StringBuilder(128);
                    // 这里会生成服务的名字,如:类型为 HelloService --> hello.service
                    for (int i = 0; i < charArray.length; i++) {
                        if (Character.isUpperCase(charArray[i])) {
                            if (i != 0) {
                                sb.append(".");
                            }
                            sb.append(Character.toLowerCase(charArray[i]));
                        } else {
                            sb.append(charArray[i]);
                        }
                    }
                    value = new String[]{sb.toString()};
                }

                boolean hasInvocation = false;
                for (int i = 0; i < pts.length; ++i) {
                    if (pts[i].getName().equals("com.alibaba.dubbo.rpc.Invocation")) {
                        // Null Point check
                        String s = String.format("\nif (arg%d == null) throw new IllegalArgumentException(\"invocation == null\");", i);
                        code.append(s);
                        s = String.format("\nString methodName = arg%d.getMethodName();", i);
                        code.append(s);
                        hasInvocation = true;
                        break;
                    }
                }

                String defaultExtName = cachedDefaultName;
                String getNameCode = null;
                // 此处的value 就是服务的名字, 会去url 的 parameter中获取此 value对应的值
                // 如果url parameter有值,那么此值就是实现类的 key
                // 没有的否,会使用 cachedDefaultName 作为实现类的key
                for (int i = value.length - 1; i >= 0; --i) {
                    if (i == value.length - 1) {
                        if (null != defaultExtName) {
                            if (!"protocol".equals(value[i]))
                                if (hasInvocation)
                                    getNameCode = String.format("url.getMethodParameter(methodName, \"%s\", \"%s\")", value[i], defaultExtName);
                                else    // 可以看到这里的默认值使用的是 defaultExtName,即 cachedDefaultName
                                    getNameCode = String.format("url.getParameter(\"%s\", \"%s\")", value[i], defaultExtName);
                            else
                                getNameCode = String.format("( url.getProtocol() == null ? \"%s\" : url.getProtocol() )", defaultExtName);
                        } else {
                            if (!"protocol".equals(value[i]))
                                if (hasInvocation)
                                    getNameCode = String.format("url.getMethodParameter(methodName, \"%s\", \"%s\")", value[i], defaultExtName);
                                else
                                    getNameCode = String.format("url.getParameter(\"%s\")", value[i]);
                            else
                                getNameCode = "url.getProtocol()";
                        }
                    } else {
                        if (!"protocol".equals(value[i]))
                            if (hasInvocation)
                                getNameCode = String.format("url.getMethodParameter(methodName, \"%s\", \"%s\")", value[i], defaultExtName);
                            else
                                getNameCode = String.format("url.getParameter(\"%s\", %s)", value[i], getNameCode);
                        else
                            getNameCode = String.format("url.getProtocol() == null ? (%s) : url.getProtocol()", getNameCode);
                    }
                }
                code.append("\nString extName = ").append(getNameCode).append(";");
                // extName 其实就是实现类的key
                // 如果 extName为null, 则报错
                String s = String.format("\nif(extName == null) " +
                                "throw new IllegalStateException(\"Fail to get extension(%s) name from url(\" + url.toString() + \") use keys(%s)\");",
                        type.getName(), Arrays.toString(value));
                code.append(s);

                s = String.format("\n%s extension = (%<s)%s.getExtensionLoader(%s.class).getExtension(extName);",
                        type.getName(), ExtensionLoader.class.getSimpleName(), type.getName());
                code.append(s);

                // return statement
                if (!rt.equals(void.class)) {
                    code.append("\nreturn ");
                }

                s = String.format("extension.%s(", method.getName());
                code.append(s);
                for (int i = 0; i < pts.length; i++) {
                    if (i != 0)
                        code.append(", ");
                    code.append("arg").append(i);
                }
                code.append(");");
            }

            codeBuilder.append("\npublic ").append(rt.getCanonicalName()).append(" ").append(method.getName()).append("(");
            for (int i = 0; i < pts.length; i++) {
                if (i > 0) {
                    codeBuilder.append(", ");
                }
                codeBuilder.append(pts[i].getCanonicalName());
                codeBuilder.append(" ");
                codeBuilder.append("arg").append(i);
            }
            codeBuilder.append(")");
            if (ets.length > 0) {
                codeBuilder.append(" throws ");
                for (int i = 0; i < ets.length; i++) {
                    if (i > 0) {
                        codeBuilder.append(", ");
                    }
                    codeBuilder.append(ets[i].getCanonicalName());
                }
            }
            codeBuilder.append(" {");
            codeBuilder.append(code.toString());
            codeBuilder.append("\n}");
        }
        codeBuilder.append("\n}");
        if (logger.isDebugEnabled()) {
            logger.debug(codeBuilder.toString());
        }
        return codeBuilder.toString();
    }
```

这里比较长，不过自己debug一下，就清楚了，看一下在这里生成的自适应类：

```java
package demo2;
import com.alibaba.dubbo.common.extension.ExtensionLoader;
public class HelloService$Adaptive implements demo2.HelloService {
    public void sayHello() {
        throw new UnsupportedOperationException("method public abstract void demo2.HelloService.sayHello() of " +
                                                "interface demo2.HelloService is not adaptive method!");
    }
    // 这里生产的自适应方法
    // 何为自适应?
    // 对于在方法上标记了 Adaptive 注解的方法,会根据其参数去调用具体的实现类,此称为自适应
    // 确定具体实现类方式:
    // 1. 在url中 Parameter 中指定了此服务的实现类对应的key,则调用key对应的实现类
    // 2. 在 url parameter中没有指定的话,会使用@SPI注解中指定的默认的实现类key
    public void sayHello(com.alibaba.dubbo.common.URL arg0) {
        if (arg0 == null) throw new IllegalArgumentException("url == null");
        com.alibaba.dubbo.common.URL url = arg0;
        String extName = url.getParameter("hello.service", "dog");
        if(extName == null)
            throw new IllegalStateException("Fail to get extension(demo2.HelloService) name from url(" + url.toString() + ") use keys([hello.service])");
        demo2.HelloService extension = (demo2.HelloService)ExtensionLoader.getExtensionLoader(demo2.HelloService.class).getExtension(extName);
        extension.sayHello(arg0);
    }
}
```

这里自适应类中的注释是自己添加的，方便理解。

总体就先分析到这里，基本上对dubbo spi就有了一些总的理解了。















