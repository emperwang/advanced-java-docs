[TOC]

# 函数字节码分析

## 1. 实例一(数据加载)

```java
package com.wk.jvm_instruction;
public class JVMDemo {
    public static void main(String[] args) {
        boolean flag = false;
        byte  bites = 6;
        char ch = 'a';
        short shNum = 5;
        int age = 8;
        long score = 90L;
        double ave = 55f;
        String abc = "abcdefghijklmn";
    }
}
```

对应的字节码:

```java
public class com.wk.jvm_instruction.JVMDemo
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:   /// 常量池
   #1 = Methodref          #8.#38         // java/lang/Object."<init>":()V
   #2 = Long               90l
   #4 = Double             55.0d
   #6 = String             #39            // abcdefghijklmn
   #7 = Class              #40            // com/wk/jvm_instruction/JVMDemo
   #8 = Class              #41            // java/lang/Object
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               LocalVariableTable
  #14 = Utf8               this
  #15 = Utf8               Lcom/wk/jvm_instruction/JVMDemo;
  #16 = Utf8               main
  #17 = Utf8               ([Ljava/lang/String;)V
  #18 = Utf8               args
  #19 = Utf8               [Ljava/lang/String;
  #20 = Utf8               flag
  #21 = Utf8               Z
  #22 = Utf8               bites
  #23 = Utf8               B
  #24 = Utf8               ch
  #25 = Utf8               C
  #26 = Utf8               shNum
  #27 = Utf8               S
  #28 = Utf8               age
  #29 = Utf8               I
  #30 = Utf8               score
  #31 = Utf8               J
  #32 = Utf8               ave
  #33 = Utf8               D
  #34 = Utf8               abc
  #35 = Utf8               Ljava/lang/String;
  #36 = Utf8               SourceFile
  #37 = Utf8               JVMDemo.java
  #38 = NameAndType        #9:#10         // "<init>":()V
  #39 = Utf8               abcdefghijklmn
  #40 = Utf8               com/wk/jvm_instruction/JVMDemo
  #41 = Utf8               java/lang/Object
{
  public com.wk.jvm_instruction.JVMDemo();  /// 构造函数
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:				/// code属性
      stack=1, locals=1, args_size=1  /// 表示了 操作栈 以及 本地变量的数
         0: aload_0					/// load this,并表用父类初始化方法
         1: invokespecial #1          // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:		/// 本地变量表
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMDemo;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V	/// 描述符
    flags: ACC_PUBLIC, ACC_STATIC
    Code:							/// code属性
      stack=2, locals=11, args_size=1
         0: iconst_0		
         1: istore_1		/// 先把0推送至栈顶,然后把0存储到本地变量1中,也就是flag
         2: bipush        6
         4: istore_2	   /// 先把6推送到栈顶,然后把栈顶值在存储到本地变量2,也就是bites
         5: bipush        97
         7: istore_3	///把97推送至栈顶,再把栈顶元素存储到本地变量3中,也就是变量ch
         8: iconst_5	///把5推送到栈顶
         9: istore        4 /// 把栈顶元素存储到4,也就是变量shNum
        11: bipush        8	/// 把8推送到栈顶
        13: istore        5	/// 把栈顶值存储到变量age
        15: ldc2_w        #2 ///把常量池中第2个常量加载到栈顶
        18: lstore        6	/// 把栈顶元素存储到第6个本地变量,也就是变量score
        20: ldc2_w        #4  // double 55.0d
        23: dstore        8
        25: ldc           #6  // String abcdefghijklmn
        27: astore        10 ///首先加载常量池中的字符串到栈顶,并把栈顶值存储到10
        29: return
      LineNumberTable:
        line 5: 0			/// 表示源文件中的第五行对应bytecode中的第0行
        line 6: 2
        line 7: 5
        line 8: 8
        line 9: 11
        line 10: 15
        line 11: 20
        line 12: 25
        line 13: 29
      LocalVariableTable:	/// 本地变量表
        Start  Length  Slot  Name   Signature	/// 注意此处的Signature是如何表示的
            0      30     0  args   [Ljava/lang/String;
            2      28     1  flag   Z
            5      25     2 bites   B
            8      22     3    ch   C
           11      19     4 shNum   S
           15      15     5   age   I
           20      10     6 score   J
           25       5     8   ave   D
           29       1    10   abc   Ljava/lang/String;
}
SourceFile: "JVMDemo.java"                    
```

## 实例二(静态调用)

```java
package com.wk.jvm_instruction;

public class InstanceForTest {

    public static void printInfo(){
        System.out.println("this is static invoke");
    }

    public void printMsg(String msg){
        System.out.println("print msg is :"+msg);
    }
}
```

```java
package com.wk.jvm_instruction;

public class JVMInvokeStatic {
    public static void main(String[] args) {
        String out="123";
        System.out.println("output is: "+out);
        InstanceForTest.printInfo();
    }
}
```

```java
public class com.wk.jvm_instruction.JVMInvokeStatic
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #12.#28        // java/lang/Object."<init>":()V
   #2 = String             #29            // 123
   #3 = Fieldref           #30.#31        // java/lang/System.out:Ljava/io/PrintStream;
   #4 = Class              #32            // java/lang/StringBuilder
   #5 = Methodref          #4.#28         // java/lang/StringBuilder."<init>":()V
   #6 = String             #33            // output is:
   #7 = Methodref          #4.#34         // java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
   #8 = Methodref          #4.#35         // java/lang/StringBuilder.toString:()Ljava/lang/String;
   #9 = Methodref          #36.#37        // java/io/PrintStream.println:(Ljava/lang/String;)V
  #10 = Methodref          #38.#39        // com/wk/jvm_instruction/InstanceForTest.printInfo:()V
  #11 = Class              #40            // com/wk/jvm_instruction/JVMInvokeStatic
  #12 = Class              #41            // java/lang/Object
  #13 = Utf8               <init>
  #14 = Utf8               ()V
  #15 = Utf8               Code
  #16 = Utf8               LineNumberTable
  #17 = Utf8               LocalVariableTable
  #18 = Utf8               this
  #19 = Utf8               Lcom/wk/jvm_instruction/JVMInvokeStatic;
  #20 = Utf8               main
  #21 = Utf8               ([Ljava/lang/String;)V
  #22 = Utf8               args
  #23 = Utf8               [Ljava/lang/String;
  #24 = Utf8               out
  #25 = Utf8               Ljava/lang/String;
  #26 = Utf8               SourceFile
  #27 = Utf8               JVMInvokeStatic.java
  #28 = NameAndType        #13:#14        // "<init>":()V
  #29 = Utf8               123
  #30 = Class              #42            // java/lang/System
  #31 = NameAndType        #24:#43        // out:Ljava/io/PrintStream;
  #32 = Utf8               java/lang/StringBuilder
  #33 = Utf8               output is:
  #34 = NameAndType        #44:#45        // append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
  #35 = NameAndType        #46:#47        // toString:()Ljava/lang/String;
  #36 = Class              #48            // java/io/PrintStream
  #37 = NameAndType        #49:#50        // println:(Ljava/lang/String;)V
  #38 = Class              #51            // com/wk/jvm_instruction/InstanceForTest
  #39 = NameAndType        #52:#14        // printInfo:()V
  #40 = Utf8               com/wk/jvm_instruction/JVMInvokeStatic
  #41 = Utf8               java/lang/Object
  #42 = Utf8               java/lang/System
  #43 = Utf8               Ljava/io/PrintStream;
  #44 = Utf8               append
  #45 = Utf8               (Ljava/lang/String;)Ljava/lang/StringBuilder;
  #46 = Utf8               toString
  #47 = Utf8               ()Ljava/lang/String;
  #48 = Utf8               java/io/PrintStream
  #49 = Utf8               println
  #50 = Utf8               (Ljava/lang/String;)V
  #51 = Utf8               com/wk/jvm_instruction/InstanceForTest
  #52 = Utf8               printInfo
{
  public com.wk.jvm_instruction.JVMInvokeStatic();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1	/// 调用初始化方法
         0: aload_0
         1: invokespecial #1      // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMInvokeStatic;
 public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=3, locals=2, args_size=1
         0: ldc           #2     // String 123
         2: astore_1
         3: getstatic     #3   // Field java/lang/System.out:Ljava/io/PrintStream;
         6: new           #4   // class java/lang/StringBuilder
         9: dup
        10: invokespecial #5   // Method java/lang/StringBuilder."<init>":()V
        13: ldc           #6   // String output is:
        15: invokevirtual #7   // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
        18: aload_1
        19: invokevirtual #7   // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
        22: invokevirtual #8  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
        25: invokevirtual #9 // Method java/io/PrintStream.println:Ljava/lang/String;)V
        28: invokestatic  #10 // Method com/wk/jvm_instruction/InstanceForTest.printInfo:()V
        31: return
      LineNumberTable:
        line 5: 0
        line 6: 3
        line 7: 28
        line 8: 31
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      32     0  args   [Ljava/lang/String;
            3      29     1   out   Ljava/lang/String;
}
SourceFile: "JVMInvokeStatic.java"
```

## 实例三(调用实例方法)

```java
package com.wk.jvm_instruction;
public class InstanceForTest {
    public static void printInfo(){
        System.out.println("this is static invoke");
    }
    public void printMsg(String msg){
        System.out.println("print msg is :"+msg);
    }
}

```

```java
package com.wk.jvm_instruction;

public class JVMInvokeInstace {
    public static void main(String[] args) {
        InstanceForTest instanceForTest = new InstanceForTest();
        instanceForTest.printMsg("this is instance invoke");   // 实例方法调用
    }
}
```

```java
public class com.wk.jvm_instruction.JVMInvokeInstace
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #7.#23         // java/lang/Object."<init>":()V
   #2 = Class              #24            // com/wk/jvm_instruction/InstanceForTest
   #3 = Methodref          #2.#23         // com/wk/jvm_instruction/InstanceForTest."<init>":()V
   #4 = String             #25            // this is instance invoke
   #5 = Methodref          #2.#26         // com/wk/jvm_instruction/InstanceForTest.printMsg:(Ljava/lang/String;)V
   #6 = Class              #27            // com/wk/jvm_instruction/JVMInvokeInstace
   #7 = Class              #28            // java/lang/Object
   #8 = Utf8               <init>
   #9 = Utf8               ()V
  #10 = Utf8               Code
  #11 = Utf8               LineNumberTable
  #12 = Utf8               LocalVariableTable
  #13 = Utf8               this
  #14 = Utf8               Lcom/wk/jvm_instruction/JVMInvokeInstace;
  #15 = Utf8               main
  #16 = Utf8               ([Ljava/lang/String;)V
  #17 = Utf8               args
  #18 = Utf8               [Ljava/lang/String;
  #19 = Utf8               instanceForTest
  #20 = Utf8               Lcom/wk/jvm_instruction/InstanceForTest;
  #21 = Utf8               SourceFile
  #22 = Utf8               JVMInvokeInstace.java
  #23 = NameAndType        #8:#9          // "<init>":()V
  #24 = Utf8               com/wk/jvm_instruction/InstanceForTest
  #25 = Utf8               this is instance invoke
  #26 = NameAndType        #29:#30        // printMsg:(Ljava/lang/String;)V
  #27 = Utf8               com/wk/jvm_instruction/JVMInvokeInstace
  #28 = Utf8               java/lang/Object
  #29 = Utf8               printMsg
  #30 = Utf8               (Ljava/lang/String;)V
{
  public com.wk.jvm_instruction.JVMInvokeInstace();
   descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1   // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMInvokeInstace;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: new           #2   // class com/wk/jvm_instruction/InstanceForTest
         3: dup
         4: invokespecial #3  // Method com/wk/jvm_instruction/InstanceForTest."<init>":()V
         7: astore_1
         8: aload_1
         9: ldc           #4 // String this is instance invoke
        11: invokevirtual #5 // Method com/wk/jvm_instruction/InstanceForTest.printMsg:(Ljava/lang/String;)V
        14: return
      LineNumberTable:
        line 6: 0
        line 7: 8
        line 8: 14
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      15     0  args   [Ljava/lang/String;
            8       7     1 instanceForTest   Lcom/wk/jvm_instruction/InstanceForTest;
}
SourceFile: "JVMInvokeInstace.java"
```

## 实例四(if)

```java
package com.wk.jvm_instruction;
public class JVMIf {
    public static void main(String[] args) {
        boolean flag = true;
        if (flag){
            System.out.println("this is if");
        }else{
            System.out.println("this is else");
        }
    }
}
```

```java
public class com.wk.jvm_instruction.JVMIf
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #7.#24         // java/lang/Object."<init>":()V
   #2 = Fieldref           #25.#26        // java/lang/System.out:Ljava/io/PrintStream;
   #3 = String             #27            // this is if
   #4 = Methodref          #28.#29        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #5 = String             #30            // this is else
   #6 = Class              #31            // com/wk/jvm_instruction/JVMIf
   #7 = Class              #32            // java/lang/Object
   #8 = Utf8               <init>
   #9 = Utf8               ()V
  #10 = Utf8               Code
  #11 = Utf8               LineNumberTable
  #12 = Utf8               LocalVariableTable
  #13 = Utf8               this
  #14 = Utf8               Lcom/wk/jvm_instruction/JVMIf;
  #15 = Utf8               main
  #16 = Utf8               ([Ljava/lang/String;)V
  #17 = Utf8               args
  #18 = Utf8               [Ljava/lang/String;
  #19 = Utf8               flag
  #20 = Utf8               Z
  #21 = Utf8               StackMapTable
  #22 = Utf8               SourceFile
  #23 = Utf8               JVMIf.java
  #24 = NameAndType        #8:#9          // "<init>":()V
  #25 = Class              #33            // java/lang/System
  #26 = NameAndType        #34:#35        // out:Ljava/io/PrintStream;
  #27 = Utf8               this is if
  #28 = Class              #36            // java/io/PrintStream
  #29 = NameAndType        #37:#38        // println:(Ljava/lang/String;)V
  #30 = Utf8               this is else
  #31 = Utf8               com/wk/jvm_instruction/JVMIf
  #32 = Utf8               java/lang/Object
  #33 = Utf8               java/lang/System
  #34 = Utf8               out
  #35 = Utf8               Ljava/io/PrintStream;
  #36 = Utf8               java/io/PrintStream
  #37 = Utf8               println
  #38 = Utf8               (Ljava/lang/String;)V
{
  public com.wk.jvm_instruction.JVMIf();
   descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMIf;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: iconst_1
         1: istore_1
         2: iload_1
         3: ifeq          17
         6: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
         9: ldc           #3                  // String this is if
        11: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        14: goto          25
        17: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
        20: ldc           #5                  // String this is else
        22: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        25: return
      LineNumberTable:
        line 6: 0
        line 8: 2
        line 9: 6
        line 11: 17
        line 14: 25
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      26     0  args   [Ljava/lang/String;
            2      24     1  flag   Z
      StackMapTable: number_of_entries = 2
        frame_type = 252 /* append */
          offset_delta = 17
          locals = [ int ]
        frame_type = 7 /* same */
}
SourceFile: "JVMIf.java"
```



## 实例五(try-catch)

```java
package com.wk.jvm_instruction;
public class JVMTryCatch {
    public static void main(String[] args) {

        try{
            Thread.sleep(100);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }
}
```

```java
 public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: ldc2_w        #2                  // long 100l
         3: invokestatic  #4                  // Method java/lang/Thread.sleep:(J)V
         6: goto          14
         9: astore_1
        10: aload_1
        11: invokevirtual #6  // Method java/lang/InterruptedException.printStackTrace:()V
        14: return
      Exception table:
         from    to  target type
             0     6     9   Class java/lang/InterruptedException
      LineNumberTable:
        line 7: 0
        line 10: 6
        line 8: 9
        line 9: 10
        line 12: 14
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
           10       4     1     e   Ljava/lang/InterruptedException;
            0      15     0  args   [Ljava/lang/String;
      StackMapTable: number_of_entries = 2
        frame_type = 73 /* same_locals_1_stack_item */
          stack = [ class java/lang/InterruptedException ]
        frame_type = 4 /* same */
}
SourceFile: "JVMTryCatch.java"
```



## 实例六(try-catch-finally)

```java
package com.wk.jvm_instruction;
public class JVMTryCatchFinally {
    public static void main(String[] args) {
        int getvalue = getvalue();	// 此处值为4
        System.out.println("value is :"+getvalue);
    }
    public static int getvalue(){
        int a = 1;
        try{
            a += 1;
            Thread.sleep(100);
            return a;
        } catch (InterruptedException e) {
            e.printStackTrace();
        }finally {
            a += 2;
            return a;			// 真正在这里进行的返回
        }
    }
}
```

```java
public class com.wk.jvm_instruction.JVMTryCatchFinally
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #17.#40        // java/lang/Object."<init>":()V
   #2 = Methodref          #16.#41        // com/wk/jvm_instruction/JVMTryCatchFinally.getvalue:()I
   #3 = Fieldref           #42.#43        // java/lang/System.out:Ljava/io/PrintStream;
   #4 = Class              #44            // java/lang/StringBuilder
   #5 = Methodref          #4.#40         // java/lang/StringBuilder."<init>":()V
   #6 = String             #45            // value is :
   #7 = Methodref          #4.#46         // java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
   #8 = Methodref          #4.#47         // java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
   #9 = Methodref          #4.#48         // java/lang/StringBuilder.toString:()Ljava/lang/String;
  #10 = Methodref          #49.#50        // java/io/PrintStream.println:(Ljava/lang/String;)V
  #11 = Long               100l
  #13 = Methodref          #51.#52        // java/lang/Thread.sleep:(J)V
  #14 = Class              #53            // java/lang/InterruptedException
  #15 = Methodref          #14.#54        // java/lang/InterruptedException.printStackTrace:()V
  #16 = Class              #55            // com/wk/jvm_instruction/JVMTryCatchFinally
  #17 = Class              #56            // java/lang/Object
  #18 = Utf8               <init>
  #19 = Utf8               ()V
  #20 = Utf8               Code
  #21 = Utf8               LineNumberTable
  #22 = Utf8               LocalVariableTable
  #23 = Utf8               this
  #24 = Utf8               Lcom/wk/jvm_instruction/JVMTryCatchFinally;
  #25 = Utf8               main
  #26 = Utf8               ([Ljava/lang/String;)V
  #27 = Utf8               args
  #28 = Utf8               [Ljava/lang/String;
  #29 = Utf8               getvalue
  #30 = Utf8               I
  #31 = Utf8               ()I
  #32 = Utf8               e
  #33 = Utf8               Ljava/lang/InterruptedException;
  #34 = Utf8               a
  #35 = Utf8               StackMapTable
  #36 = Class              #53            // java/lang/InterruptedException
  #37 = Class              #57            // java/lang/Throwable
  #38 = Utf8               SourceFile
  #39 = Utf8               JVMTryCatchFinally.java
  #40 = NameAndType        #18:#19        // "<init>":()V
  #41 = NameAndType        #29:#31        // getvalue:()I
  #42 = Class              #58            // java/lang/System
  #43 = NameAndType        #59:#60        // out:Ljava/io/PrintStream;
  #44 = Utf8               java/lang/StringBuilder
  #45 = Utf8               value is :
  #46 = NameAndType        #61:#62        // append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
  #47 = NameAndType        #61:#63        // append:(I)Ljava/lang/StringBuilder;
  #48 = NameAndType        #64:#65        // toString:()Ljava/lang/String;
  #49 = Class              #66            // java/io/PrintStream
  #50 = NameAndType        #67:#68        // println:(Ljava/lang/String;)V
  #51 = Class              #69            // java/lang/Thread
  #52 = NameAndType        #70:#71        // sleep:(J)V
  #53 = Utf8               java/lang/InterruptedException
  #54 = NameAndType        #72:#19        // printStackTrace:()V
  #55 = Utf8               com/wk/jvm_instruction/JVMTryCatchFinally
  #56 = Utf8               java/lang/Object
  #57 = Utf8               java/lang/Throwable
  #58 = Utf8               java/lang/System
  #59 = Utf8               out
  #60 = Utf8               Ljava/io/PrintStream;
  #61 = Utf8               append
  #62 = Utf8               (Ljava/lang/String;)Ljava/lang/StringBuilder;
  #63 = Utf8               (I)Ljava/lang/StringBuilder;
  #64 = Utf8               toString
  #65 = Utf8               ()Ljava/lang/String;
  #66 = Utf8               java/io/PrintStream
  #67 = Utf8               println
  #68 = Utf8               (Ljava/lang/String;)V
  #69 = Utf8               java/lang/Thread
  #70 = Utf8               sleep
  #71 = Utf8               (J)V
  #72 = Utf8               printStackTrace
{
  public com.wk.jvm_instruction.JVMTryCatchFinally();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMTryCatchFinally;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=3, locals=2, args_size=1
         0: invokestatic  #2                  // Method getvalue:()I
         3: istore_1
         4: getstatic     #3                  // Field java/lang/System.out:Ljava/io/PrintStream;
         7: new           #4                  // class java/lang/StringBuilder
        10: dup
        11: invokespecial #5                  // Method java/lang/StringBuilder."<init>":()V
        14: ldc           #6                  // String value is :
        16: invokevirtual #7                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
        19: iload_1
        20: invokevirtual #8                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
        23: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
        26: invokevirtual #10                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        29: return
      LineNumberTable:
        line 5: 0
        line 6: 4
        line 7: 29
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      30     0  args   [Ljava/lang/String;
            4      26     1 getvalue   I

  public static int getvalue();
    descriptor: ()I
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=3, args_size=0
         0: iconst_1
         1: istore_0
         2: iinc          0, 1	/// 本地变量0 数值增加1
         5: ldc2_w        #11                 // long 100l
         8: invokestatic  #13                 // Method java/lang/Thread.sleep:(J)V
        11: iload_0
        12: istore_1
        13: iinc          0, 2
        16: iload_0
        17: ireturn
        18: astore_1
        19: aload_1
        20: invokevirtual #15                 // Method java/lang/InterruptedException.printStackTrace:()V
        23: iinc          0, 2
        26: iload_0
        27: ireturn
        28: astore_2
        29: iinc          0, 2
        32: iload_0
        33: ireturn
      Exception table:	/// 异常表
         from    to  target type
             2    13    18   Class java/lang/InterruptedException
             2    13    28   any
            18    23    28   any
      LineNumberTable:
        line 10: 0
        line 12: 2
        line 13: 5
        line 14: 11
        line 18: 13
        line 19: 16
        line 15: 18
        line 16: 19
        line 18: 23
        line 19: 26
        line 18: 28
        line 19: 32
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
           19       4     1     e   Ljava/lang/InterruptedException;
            2      32     0     a   I
      StackMapTable: number_of_entries = 2
        frame_type = 255 /* full_frame */
          offset_delta = 18
          locals = [ int ]
          stack = [ class java/lang/InterruptedException ]
        frame_type = 73 /* same_locals_1_stack_item */
          stack = [ class java/lang/Throwable ]
}
SourceFile: "JVMTryCatchFinally.java"
```

另一个情况:

```java
package com.wk.jvm_instruction;

public class JVMTryCatchFinally {
    public static void main(String[] args) {
        int getvalue = getvalue();	 // 此处值为2
        System.out.println("value is :"+getvalue);
    }
    public static int getvalue(){
        int a = 1;
        try{
            a += 1;
            Thread.sleep(100);
            return a;			// 真正是在这里进行的返回
        } catch (InterruptedException e) {
            e.printStackTrace();
        }finally {
            a += 2;
//            return a;   // 此处不进行返回
        }
        return a;
    }
}

```

```java
public class com.wk.jvm_instruction.JVMTryCatchFinally
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #17.#40        // java/lang/Object."<init>":()V
   #2 = Methodref          #16.#41        // com/wk/jvm_instruction/JVMTryCatchFinally.getvalue:()I
   #3 = Fieldref           #42.#43        // java/lang/System.out:Ljava/io/PrintStream;
   #4 = Class              #44            // java/lang/StringBuilder
   #5 = Methodref          #4.#40         // java/lang/StringBuilder."<init>":()V
   #6 = String             #45            // value is :
   #7 = Methodref          #4.#46         // java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
   #8 = Methodref          #4.#47         // java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
   #9 = Methodref          #4.#48         // java/lang/StringBuilder.toString:()Ljava/lang/String;
  #10 = Methodref          #49.#50        // java/io/PrintStream.println:(Ljava/lang/String;)V
  #11 = Long               100l
  #13 = Methodref          #51.#52        // java/lang/Thread.sleep:(J)V
  #14 = Class              #53            // java/lang/InterruptedException
  #15 = Methodref          #14.#54        // java/lang/InterruptedException.printStackTrace:()V
  #16 = Class              #55            // com/wk/jvm_instruction/JVMTryCatchFinally
  #17 = Class              #56            // java/lang/Object
  #18 = Utf8               <init>
  #19 = Utf8               ()V
  #20 = Utf8               Code
  #21 = Utf8               LineNumberTable
  #22 = Utf8               LocalVariableTable
  #23 = Utf8               this
  #24 = Utf8               Lcom/wk/jvm_instruction/JVMTryCatchFinally;
  #25 = Utf8               main
  #26 = Utf8               ([Ljava/lang/String;)V
  #27 = Utf8               args
  #28 = Utf8               [Ljava/lang/String;
  #29 = Utf8               getvalue
  #30 = Utf8               I
  #31 = Utf8               ()I
  #32 = Utf8               e
  #33 = Utf8               Ljava/lang/InterruptedException;
  #34 = Utf8               a
  #35 = Utf8               StackMapTable
  #36 = Class              #53            // java/lang/InterruptedException
  #37 = Class              #57            // java/lang/Throwable
  #38 = Utf8               SourceFile
  #39 = Utf8               JVMTryCatchFinally.java
  #40 = NameAndType        #18:#19        // "<init>":()V
  #41 = NameAndType        #29:#31        // getvalue:()I
  #42 = Class              #58            // java/lang/System
  #43 = NameAndType        #59:#60        // out:Ljava/io/PrintStream;
  #44 = Utf8               java/lang/StringBuilder
  #45 = Utf8               value is :
  #46 = NameAndType        #61:#62        // append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
  #47 = NameAndType        #61:#63        // append:(I)Ljava/lang/StringBuilder;
  #48 = NameAndType        #64:#65        // toString:()Ljava/lang/String;
  #49 = Class              #66            // java/io/PrintStream
  #50 = NameAndType        #67:#68        // println:(Ljava/lang/String;)V
  #51 = Class              #69            // java/lang/Thread
  #52 = NameAndType        #70:#71        // sleep:(J)V
  #53 = Utf8               java/lang/InterruptedException
  #54 = NameAndType        #72:#19        // printStackTrace:()V
  #55 = Utf8               com/wk/jvm_instruction/JVMTryCatchFinally
  #56 = Utf8               java/lang/Object
  #57 = Utf8               java/lang/Throwable
  #58 = Utf8               java/lang/System
  #59 = Utf8               out
  #60 = Utf8               Ljava/io/PrintStream;
  #61 = Utf8               append
  #62 = Utf8               (Ljava/lang/String;)Ljava/lang/StringBuilder;
  #63 = Utf8               (I)Ljava/lang/StringBuilder;
  #64 = Utf8               toString
  #65 = Utf8               ()Ljava/lang/String;
  #66 = Utf8               java/io/PrintStream
  #67 = Utf8               println
  #68 = Utf8               (Ljava/lang/String;)V
  #69 = Utf8               java/lang/Thread
  #70 = Utf8               sleep
  #71 = Utf8               (J)V
  #72 = Utf8               printStackTrace
{
  public com.wk.jvm_instruction.JVMTryCatchFinally();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/wk/jvm_instruction/JVMTryCatchFinally;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=3, locals=2, args_size=1
         0: invokestatic  #2                  // Method getvalue:()I
         3: istore_1
         4: getstatic     #3                  // Field java/lang/System.out:Ljava/io/PrintStream;
         7: new           #4                  // class java/lang/StringBuilder
        10: dup
        11: invokespecial #5                  // Method java/lang/StringBuilder."<init>":()V
        14: ldc           #6                  // String value is :
        16: invokevirtual #7                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
        19: iload_1
        20: invokevirtual #8                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
        23: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
        26: invokevirtual #10                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        29: return
      LineNumberTable:
        line 5: 0
        line 6: 4
        line 7: 29
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      30     0  args   [Ljava/lang/String;
            4      26     1 getvalue   I

  public static int getvalue();
    descriptor: ()I
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=3, args_size=0
         0: iconst_1
         1: istore_0
         2: iinc          0, 1
         5: ldc2_w        #11                 // long 100l
         8: invokestatic  #13                 // Method java/lang/Thread.sleep:(J)V
        11: iload_0			// 注意这里，是把返回值放到的本地变量1
        12: istore_1	
        13: iinc          0, 2 // 这里finally对a进行增加2,可是是对本地变量0, 根本没有影响本地变量1
        16: iload_1		/// 从本地变量1加载真正的返回值进行返回
        17: ireturn
        18: astore_1
        19: aload_1
        20: invokevirtual #15 // Method java/lang/InterruptedException.printStackTrace:()V
        23: iinc          0, 2
        26: goto          35
        29: astore_2
        30: iinc          0, 2
        33: aload_2
        34: athrow
        35: iload_0
        36: ireturn
      Exception table:
         from    to  target type
             2    13    18   Class java/lang/InterruptedException
             2    13    29   any
            18    23    29   any
      LineNumberTable:
        line 10: 0
        line 12: 2
        line 13: 5
        line 14: 11
        line 18: 13
        line 14: 16
        line 15: 18
        line 16: 19
        line 18: 23
        line 20: 26
        line 18: 29
        line 20: 33
        line 21: 35
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
           19       4     1     e   Ljava/lang/InterruptedException;
            2      35     0     a   I
      StackMapTable: number_of_entries = 3
        frame_type = 255 /* full_frame */
          offset_delta = 18
          locals = [ int ]
          stack = [ class java/lang/InterruptedException ]
        frame_type = 74 /* same_locals_1_stack_item */
          stack = [ class java/lang/Throwable ]
        frame_type = 5 /* same */
}
SourceFile: "JVMTryCatchFinally.java"
```



## 实例七(switch)

```java
package com.wk.jvm_instruction;
public class JVMSwitch {
    public static void main(String[] args) {
        int a = 1;
        switch (a){
            case 1:
                break;
            case 2:
                break;
            case 3:
                break;
            case 4:
                break;
             default:
                 break;
        }
    }
}
```

```java
public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=2, args_size=1
         0: iconst_1
         1: istore_1
         2: iload_1
         3: tableswitch   { // 1 to 4	//// 连续的使用tableswitch，不连续的使用lookupswitch
                       1: 32	/// 可以看到是如何进行匹配, 匹配值:行号
                       2: 35
                       3: 38
                       4: 41
                 default: 44
            }
        32: goto          44
        35: goto          44
        38: goto          44
        41: goto          44
        44: return
      LineNumberTable:
        line 5: 0
        line 6: 2
        line 8: 32
        line 10: 35
        line 12: 38
        line 14: 41
        line 18: 44
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      45     0  args   [Ljava/lang/String;
            2      43     1     a   I
      StackMapTable: number_of_entries = 5
        frame_type = 252 /* append */
          offset_delta = 32
          locals = [ int ]
        frame_type = 2 /* same */
        frame_type = 2 /* same */
        frame_type = 2 /* same */
        frame_type = 2 /* same */
}
SourceFile: "JVMSwitch.java"
```



## 实例八(switch2)

```java
package com.wk.jvm_instruction;
public class JVMSwitch2 {
    public static void main(String[] args) {
        String test = "abc";
        switch (test){
            case "123":
                break;
            case "678":
                break;
            case "365":
                break;
            case "234":
                break;
            case "abc":
                break;
            default:break;
        }
    }
}
```

```java
public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=4, args_size=1
         0: ldc           #2                  // String abc
         2: astore_1
         3: aload_1
         4: astore_2
         5: iconst_m1
         6: istore_3
         7: aload_2
         8: invokevirtual #3                  // Method java/lang/String.hashCode:()I
        11: lookupswitch  { // 5			//// 可以看到字符串进行匹配使用到了hashCode码进行匹配
                   48690: 60
                   49683: 102		/// 可以看到不连续的switch,所做的操作是:1.先进行匹配
                   50738: 88			/// 2.根据匹配上的不同,跳转到不同的行继续进行执行
                   53655: 74
                   96354: 116
                 default: 127
            }
        60: aload_2
        61: ldc           #4                  // String 123
        63: invokevirtual #5                  // Method java/lang/String.equals:(Ljava/lang/Object;)Z
        66: ifeq          127	/// 如果相等,则跳转到127(字节码中的行号)继续进行运行
        69: iconst_0
        70: istore_3
        71: goto          127
        74: aload_2
        75: ldc           #6                  // String 678
        77: invokevirtual #5                  // Method java/lang/String.equals:(Ljava/lang/Object;)Z
        80: ifeq          127
        83: iconst_1
        84: istore_3
        85: goto          127
        88: aload_2
        89: ldc           #7                  // String 365
        91: invokevirtual #5                  // Method java/lang/String.equals:(Ljava/lang/Object;)Z
        94: ifeq          127
        97: iconst_2
        98: istore_3
        99: goto          127
       102: aload_2
       103: ldc           #8                  // String 234
       105: invokevirtual #5                  // Method java/lang/String.equals:(Ljava/lang/Object;)Z
       108: ifeq          127
       111: iconst_3
       112: istore_3
       113: goto          127
       116: aload_2
       117: ldc           #2                  // String abc
       119: invokevirtual #5                  // Method java/lang/String.equals:(Ljava/lang/Object;)Z
       122: ifeq          127
       125: iconst_4
       126: istore_3
       127: iload_3
       128: tableswitch   { // 0 to 4
                       0: 164
                       1: 167
                       2: 170
                       3: 173
                       4: 176
                 default: 179
            }
       164: goto          179
       167: goto          179
       170: goto          179
       173: goto          179
       176: goto          179
       179: return
      LineNumberTable:
        line 5: 0
        line 6: 3
        line 8: 164
        line 10: 167
        line 12: 170
        line 14: 173
        line 16: 176
        line 19: 179
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0     180     0  args   [Ljava/lang/String;
            3     177     1  test   Ljava/lang/String;
      StackMapTable: number_of_entries = 12
        frame_type = 254 /* append */
          offset_delta = 60
          locals = [ class java/lang/String, class java/lang/String, int ]
        frame_type = 13 /* same */
        frame_type = 13 /* same */
        frame_type = 13 /* same */
        frame_type = 13 /* same */
        frame_type = 10 /* same */
        frame_type = 36 /* same */
        frame_type = 2 /* same */
        frame_type = 2 /* same */
        frame_type = 2 /* same */
        frame_type = 2 /* same */
        frame_type = 249 /* chop */
          offset_delta = 2
}
SourceFile: "JVMSwitch2.java"
```

