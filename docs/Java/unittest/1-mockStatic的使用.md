# mock static 的使用
## 1. mockito 使用

### 1) mockito mock静态方法一

```java
@RunWith(MockitoJUnitRunner.class)
public class MockStatic1Test {

    @Test
    public void test1(){
        MockedStatic<StringUtil> mockedStatic = Mockito.mockStatic(StringUtil.class);
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }


    @Test
    public void test2(){
        MockedStatic<StringUtil> mockedStatic = Mockito.mockStatic(StringUtil.class);
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}
```

运行报错:

```shell
org.mockito.exceptions.base.MockitoException: 
For com.wk.util.StringUtil, static mocking is already registered in the current thread

To create a new mock, the existing static mock registration must be deregistered

at com.wk.mockstatic.MockStaticTest1.test2(MockStaticTest1.java:30)
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
at java.lang.reflect.Method.invoke(Method.java:498)
at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)
at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)
at org.junit.internal.runners.statements.InvokeMethod.evaluate(InvokeMethod.java:17)
at org.mockito.internal.runners.DefaultInternalRunner$1$1.evaluate(DefaultInternalRunner.java:55)
at org.junit.runners.ParentRunner.runLeaf(ParentRunner.java:325)
at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:78)
at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:57)
at org.junit.runners.ParentRunner$3.run(ParentRunner.java:290)
at org.junit.runners.ParentRunner$1.schedule(ParentRunner.java:71)
at org.junit.runners.ParentRunner.runChildren(ParentRunner.java:288)
at org.junit.runners.ParentRunner.access$000(ParentRunner.java:58)
at org.junit.runners.ParentRunner$2.evaluate(ParentRunner.java:268)
at org.junit.runners.ParentRunner.run(ParentRunner.java:363)
at org.mockito.internal.runners.DefaultInternalRunner$1.run(DefaultInternalRunner.java:100)
at org.mockito.internal.runners.DefaultInternalRunner.run(DefaultInternalRunner.java:107)
at org.mockito.internal.runners.StrictRunner.run(StrictRunner.java:41)
at org.mockito.junit.MockitoJUnitRunner.run(MockitoJUnitRunner.java:163)
at org.junit.runner.JUnitCore.run(JUnitCore.java:137)
at com.intellij.junit4.JUnit4IdeaTestRunner.startRunnerWithArgs(JUnit4IdeaTestRunner.java:68)
at com.intellij.rt.junit.IdeaTestRunner$Repeater.startRunnerWithArgs(IdeaTestRunner.java:33)
at com.intellij.rt.junit.JUnitStarter.prepareStreamsAndStart(JUnitStarter.java:230)
at com.intellij.rt.junit.JUnitStarter.main(JUnitStarter.java:58)
```



## 2) mockito mock 静态方法二

```java
@RunWith(MockitoJUnitRunner.class)
public class MockStatic1Test {

    private MockedStatic<StringUtil> mockedStatic;

    @Test
    public void test1(){
        mockedStatic = Mockito.mockStatic(StringUtil.class);
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }


    @Test
    public void test2(){
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}
```

运行报错:

```shell
mockito core result

java.lang.NullPointerException
at com.wk.mockstatic.MockStaticTest1.test2(MockStaticTest1.java:34)
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
at java.lang.reflect.Method.invoke(Method.java:498)
at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)
at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)
at org.junit.internal.runners.statements.InvokeMethod.evaluate(InvokeMethod.java:17)
at org.mockito.internal.runners.DefaultInternalRunner$1$1.evaluate(DefaultInternalRunner.java:55)
at org.junit.runners.ParentRunner.runLeaf(ParentRunner.java:325)
at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:78)
at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:57)
at org.junit.runners.ParentRunner$3.run(ParentRunner.java:290)
at org.junit.runners.ParentRunner$1.schedule(ParentRunner.java:71)
at org.junit.runners.ParentRunner.runChildren(ParentRunner.java:288)
at org.junit.runners.ParentRunner.access$000(ParentRunner.java:58)
at org.junit.runners.ParentRunner$2.evaluate(ParentRunner.java:268)
at org.junit.runners.ParentRunner.run(ParentRunner.java:363)
at org.mockito.internal.runners.DefaultInternalRunner$1.run(DefaultInternalRunner.java:100)
at org.mockito.internal.runners.DefaultInternalRunner.run(DefaultInternalRunner.java:107)
at org.mockito.internal.runners.StrictRunner.run(StrictRunner.java:41)
at org.mockito.junit.MockitoJUnitRunner.run(MockitoJUnitRunner.java:163)
at org.junit.runner.JUnitCore.run(JUnitCore.java:137)
at com.intellij.junit4.JUnit4IdeaTestRunner.startRunnerWithArgs(JUnit4IdeaTestRunner.java:68)
at com.intellij.rt.junit.IdeaTestRunner$Repeater.startRunnerWithArgs(IdeaTestRunner.java:33)
at com.intellij.rt.junit.JUnitStarter.prepareStreamsAndStart(JUnitStarter.java:230)
at com.intellij.rt.junit.JUnitStarter.main(JUnitStarter.java:58)
```

### 3) mockito mock 静态方法三

```java
@RunWith(MockitoJUnitRunner.class)
public class MockStatic1Test {

    private static MockedStatic<StringUtil> mockedStatic;
    @BeforeClass
    public static void setup(){
         mockedStatic = Mockito.mockStatic(StringUtil.class);
    }


    @Test
    public void test1(){
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }


    @Test
    public void test2(){
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}

```

运行单元测试(mvn test 运行)，无报错。
#### 4)  多个单元测试

```java
@RunWith(MockitoJUnitRunner.class)
public class MockStatic1Test {

    private static MockedStatic<StringUtil> mockedStatic;
    @BeforeClass
    public static void setup(){
         mockedStatic = Mockito.mockStatic(StringUtil.class);
    }


    @Test
    public void test1(){
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }


    @Test
    public void test2(){
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}
```



```java
public class MockStatic2Test {
    private static MockedStatic<StringUtil> mockedStatic;
    @BeforeClass
    public static void setup(){
        mockedStatic = Mockito.mockStatic(StringUtil.class);
    }


    @Test
    public void test1(){
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }


    @Test
    public void test2(){
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}

```

运行会报错:

```shell
org.mockito.exceptions.base.MockitoException:
For com.wk.util.StringUtil, static mocking is already registered in the current thread

To create a new mock, the existing static mock registration must be deregistered
at com.wk.mockstatic.MockStatic2Test.setup(MockStatic2Test.java:18)
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
at java.lang.reflect.Method.invoke(Method.java:498)
at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)
at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)
at org.junit.internal.runners.statements.RunBefores.evaluate(RunBefores.java:24)
at org.junit.runners.ParentRunner.run(ParentRunner.java:363)
at org.apache.maven.surefire.junit4.JUnit4Provider.execute(JUnit4Provider.java:252)
at org.apache.maven.surefire.junit4.JUnit4Provider.executeTestSet(JUnit4Provider.java:141)
at org.apache.maven.surefire.junit4.JUnit4Provider.invoke(JUnit4Provider.java:112)
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
at java.lang.reflect.Method.invoke(Method.java:498)
at org.apache.maven.surefire.util.ReflectionUtils.invokeMethodWithArray(ReflectionUtils.java:189)
at org.apache.maven.surefire.booter.ProviderFactory$ProviderProxy.invoke(ProviderFactory.java:165)
at org.apache.maven.surefire.booter.ProviderFactory.invokeProvider(ProviderFactory.java:85)
at org.apache.maven.surefire.booter.ForkedBooter.runSuitesInProcess(ForkedBooter.java:115)
at org.apache.maven.surefire.booter.ForkedBooter.main(ForkedBooter.java:75)

```

官方对mockstatic的描述:

```shell
// https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#mock-java.lang.Class-
    
    mockStatic
    @Incubating
    public static <T> MockedStatic<T> mockStatic(Class<T> classToMock)

    Creates a thread-local mock controller for all static methods of the given class or interface. The returned object's ScopedMock.close() method must be called upon completing the test or the mock will remain active on the current thread.

    Note: We recommend against mocking static methods of classes in the standard library or classes used by custom class loaders used to executed the block with the mocked class. A mock maker might forbid mocking static methods of know classes that are known to cause problems. Also, if a static method is a JVM-intrinsic, it cannot typically be mocked even if not explicitly forbidden.

# 大意是：
对要mock的class中的静态方法会创建一个thread-local的controller来进行模拟。 而且在完成测试后，需要进行关闭。
```

### 5. final 

```java
@RunWith(MockitoJUnitRunner.class)
public class MockStatic1Test {

    private static MockedStatic<StringUtil> mockedStatic;
    @BeforeClass
    public static void setup(){
         mockedStatic = Mockito.mockStatic(StringUtil.class);
    }

    @AfterClass
    public static void tearDown(){
        if (!mockedStatic.isClosed()){
            mockedStatic.close();
        }
    }



    @Test
    public void test1(){
        String key = "123";
        String res = "mockito core result";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }

    @Test
    public void test2(){
        String key = "1234";
        String res = "mockito core result2";
        mockedStatic.when(() -> StringUtil.generateStr(key)).thenReturn(res);
        System.out.println(StringUtil.generateStr(key));
    }
}
```



## 2. power mock 

power mock 针对mockito中的mockStatic进行了增强，使用起来更为方便。

```java
public class StringUtil {

    public static String generateStr(String str){
        return new StringJoiner("---").add(str).add("success").toString();
    }
}
```



```java
@RunWith(PowerMockRunner.class)
@PrepareForTest({StringUtil.class})
public class PowerStatic {


    @Test
    public void test1(){
        PowerMockito.mockStatic(StringUtil.class);
        String res = "power mock string";
        Mockito.when(StringUtil.generateStr("123")).thenReturn(res);
        System.out.println(StringUtil.generateStr("123"));
    }


    @Test
    public void test2(){
        PowerMockito.mockStatic(StringUtil.class);
        String res = "power mock string2";
        Mockito.when(StringUtil.generateStr("123")).thenReturn(res);
        Assert.assertEquals(res, StringUtil.generateStr("123"));
    }
}
```



