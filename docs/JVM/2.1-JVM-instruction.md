[TOC]

# JVM Instruction

## 0. 未归类

```shell
指令码			助记符				说明
0x00			nop				什么也不做
0x01			aconst_null		 将null推送至栈顶
```



## 1.const(常量)系列

该系列参数主要负责把简单的数值推送至栈顶。该系列命令不带参数。注意只把简单的数值类型推送至栈顶时，才使用此命令。

```shell
指令码			助记符				说明
0x02			iconst_m1		将int型-1推动至栈顶
0x03		 	iconst_0		将int型0推动至栈顶
0x04			iconst_1		将int型1推动至栈顶
0x05			iconst_2		将int型2推动至栈顶
0x06			iconst_3		将int型3推动至栈顶
0x07			iconst_4		将int型4动至栈顶
0x08			iconst_5		将int型5推动至栈顶
0x09			lconst_0		将long型0推动至栈顶
0x0a			lconst_1		将long型1推动至栈顶
0x0b			fconst_0		将float型0推动至栈顶
0x0c			fconst_1		将float型1推动至栈顶
0x0d			fconst_2		将float型2推动至栈顶
0x0e			dconst_0		将double型0推动至栈顶
0x0d			dconst_1		将double型1推动至栈顶
```



## 2.push(入栈)

该系列命令负责把一个整型数字(长度比较小)送到栈顶。该系列命令有一个参数，用于指定要送到栈顶的数字。

```shell
指令码			助记符				说明
0x10			bipush			将单字节常量值(-128~127)推送到栈顶
0x11			sipush			将一个短整型常量值(-32768~32767)推送至栈顶
```

## 3.ldc

该系列命令负责把数值或String常量值从常量池中推送至栈顶。该命令需要一个表示常量在常量池中位置(编号)的参数。对于const系列命令和push系列命令操作范围外的数值类型常量，都放常量池中.

```shell
指令码			助记符			说明
0x12			ldc			将int float String型常量值从常量池中推送至栈顶
0x13			ldc_w		将int float String型常量值从常量池中推送至栈顶(宽索引)
0x14			ldc2_w		将long或double型常量值从常量池中推送至栈顶(宽索引)
```

## 4.load(加载)

### 4.1 常量系列

该系列命令负责把本地变量推送到栈顶.此处的本地变量不仅可以是数值类型，还可以是引用类型。对本地变量所进行的编号，是对所有类型的本地变量进行的(并不按照类型分类)。对于非静态函数，第一变量时this，即对应的的操作时aload_0。还有函数传入参数也算是本地变量，在进行编号时，它时先与函数的本地变量。

```shell
指令码			助记符			说明
0x15			iload		将指定的int型本地变量推送至栈顶
0x16			lload		将指定的long型本地变量推送至栈顶
0x17			fload		将指定的float型本地变量推送至栈顶
0x18			dload		将指定的double型本地变量推送至栈顶
0x19			aload		将指定的引用型本地变量推送至栈顶
0x1a			iload_0		将第1个int型本地变量推送至栈顶
0x1b			iload_1		将第2个int型本地变量推送至栈顶
0x1c			iload_2		将第3个int型本地变量推送至栈顶
0x1d			iload_3		将第4个int型本地变量推送至栈顶
0x1e			lload_0		将第1个long型本地变量推送至栈顶
0x1f			lload_1		将第2个long型本地变量推送至栈顶
0x20			lload_2		将第3个long型本地变量推送至栈顶
0x21			lload_3		将第4个long型本地变量推送至栈顶
0x22			fload_0		将第1个float型本地变量推送至栈顶
0x23			fload_1		将第2个float型本地变量推送至栈顶
0x24			fload_2		将第3个float型本地变量推送至栈顶
0x25			fload_3		将第4个float型本地变量推送至栈顶
0x26			dload_0		将第1个double型本地变量推送至栈顶
0x27			dload_1		将第2个double型本地变量推送至栈顶
0x28			dload_2		将第3个double型本地变量推送至栈顶
0x29			dload_3		将第4个double型本地变量推送至栈顶
0x2a			aload_0		将第1个reference型本地变量推送至栈顶
0x2b			aload_1		将第2个reference型本地变量推送至栈顶
0x2c			aload_2		将第3个reference型本地变量推送至栈顶
0x2d			aload_3		将第4个reference型本地变量推送至栈顶
```



### 4.2 数组系列

该系列命令负责把数组的某项送到栈顶。该命令分局栈里的内容来确定对哪个数组的哪项进行操作。

```shell
指令码			助记符			说明
0x2e			iaload		将int型数组指定索引的值推送至栈顶
0x2f			laload		将long型数组指定索引的值推送至栈顶
0x30			faload		将float型数组指定索引的值推送至栈顶
0x31			daload		将double型数组指定索引的值推送至栈顶
0x32			aaload		将引用型数组指定索引的值推送至栈顶
0x33			baload		将boolean或byte型数组指定索引值推送栈顶
0x34			caload		将char型数组指定索引值突嵩栈顶
0x35			saload		将short型数组指定索引值推送至栈顶
```

## 5.store(存储系列)

### 5.1 常量系列

该系列命令负责把栈顶值存入本地变量。这里的本地变量不仅可以数值类型，还可以是引用类型。

```shell
指令码				助记符			说明
0x36				istore		将栈顶int型数值存入本地变量
0x37				lstore		将栈顶long型数值存入本地变量
0x38				fstore		将栈顶float型数值存储本地变量
0x39				dstore		将栈顶double型数值存储指定本地变量
0x3a				astore		将栈顶引用型数值存储本变量
0x3b				istore_0	将栈顶int型数值存储第一个本地变量
0x3c				istore_1	将栈顶int型数值存储第二个本地变量
0x3d				istore_2	将栈顶int型数值存储第3个本地变量
0x3e				istore_3	将栈顶int型数值存储第4个本地变量
0x3f				lstore_0	将栈顶long型数值存储第1个本地变量
0x40				lstore_1	将栈顶long型数值存储第2个本地变量
0x41				lstore_2	将栈顶long型数值存储第3个本地变量
0x42				lstore_3	将栈顶long型数值存储第4个本地变量
0x43				fstore_0	将栈顶float型数值存储第1个本地变量
0x44				fstore_1	将栈顶float型数值存储第2个本地变量
0x45				fstore_2	将栈顶float型数值存储第3个本地变量
0x46				fstore_3	将栈顶float型数值存储第4个本地变量
0x47				dstore_0	将栈顶double型数值存储第1个本地变量
0x48				dstore_1	将栈顶double型数值存储第5个本地变量
0x49				dstore_2	将栈顶double型数值存储第6个本地变量
0x4a				dstore_3	将栈顶double型数值存储第7个本地变量
0x4b				astore_0	将栈顶引用型数值存储第1个本地变量
0x4c				astore_1	将栈顶引用型数值存储第2个本地变量
0x4d				astore_2	将栈顶引用型数值存储第3个本地变量
0x4e				astore_3	将栈顶引用型数值存储第4个本地变量
```

### 5.2  数组系列

该系命令负责把栈顶的值存到数组中。该命令根据栈里内容来确定对哪个数组的哪个项进行操作。

```shell
指令码			助记符			说明
0x4f			iastore		将栈顶int型数值存入指定数组的指定位置
0x50			lastore		将栈顶long型数值存入指定数组的指定位置
0x51			fastore		将栈顶float型数值存入指定数组的指定位置
0x52			dastore		将栈顶double型数值存入指定数组的指定位置
0x53			aastore		将栈顶引用型数值存入指定数组的指定位置
0x54			bastore		将栈顶boolean型数值存入指定数组的指定位置
0x55			castore		将栈顶char型数值存入指定数组的指定位置
0x56			sastore		将栈顶short型数值存入指定数组的指定位置
```



## 6.pop系列

该系列命令对栈顶进行操作。

```shell
指令码			助记符			说明
0x57			pop			将栈顶元素弹出(数值不能是long或double)
0x58			pop2		将指定的一个(long或double)或两个数值弹出
0x59			dup			复制栈顶数值(数值不能是long或double)并将复制值压入栈顶
0x5a			dup_x1		复制栈顶数值(数值不能是long或double)并将两个复制值压入栈顶
0x5b			dup_x2		赋值栈顶值(数值不能是long或double)并将三个或连个复制值压入栈顶
0x5c			dup2 		复制栈顶值一个(long或double类型)或两个其他数值并将复制值压入栈顶
0x5d			dup2_x1		复制栈顶值(long或double型)并将两个复制值压入栈顶
0x5e			dup2_x2		赋值栈顶(long或double)并将两个或三个复制值压缩栈顶

```



## 7.数学操作 和 移位操作

该系列命令用于对栈顶元素进行数学运算，和对数值进行移位操作。移位操作的操作数和要移位的数都是从栈中获取的。

```shell
指令码				助记符			说明
0x5f				swap	将栈顶最顶端的两个数值互换(数值不能是long或double)
0x60				iadd	将栈顶两int型数值相加并将结果压入栈顶
0x61				ladd	将栈顶两long型数值相加并将结果压入栈顶
0x62				fadd	将栈顶两float型数值相加并将结果压入栈顶
0x63				dadd	将栈顶两double型数值相加并将结果压入栈顶
0x64				isub	将栈顶两int型数值相减并将结果压入栈顶
0x65				lsub	将栈顶两long型数值相减并将结果压入栈顶
0x66				fsub	将栈顶两float型数值相减并将结果压入栈顶
0x67				dsub	将栈顶两double型数值相减并将结果压入栈顶
0x68				imul	将栈顶两int型数值相乘并将结果压入栈顶
0x69				lmul	将栈顶两long型数值相乘并将结果压入栈顶
0x6a				fmul	将栈顶两float型数值相乘并将结果压入栈顶
0x6b				dmul	将栈顶两double型数值相乘并将结果压入栈顶
0x6c				idiv	将栈顶两int型数值相除并将结果压入栈顶
0x6d				ldiv	将栈顶两long型数值相除并将结果压入栈顶
0x6e				fdiv	将栈顶两float型数值相除并将结果压入栈顶
0x6f				ddiv	将栈顶两double型数值相除并将结果压入栈顶
0x70				irem	将栈顶两int型数值做取模运算并将结果压入栈顶
0x71				lrem	将栈顶两long型数值做取模运算并将结果压入栈顶
0x72				frem	将栈顶两float型数值做取模运算并将结果压入栈顶
0x73				drem	将栈顶两double型数值做取模运算并将结果压入栈顶
0x74				ineg	将栈顶两int型数值取负并将结果压入栈顶
0x75				lneg	将栈顶两long型数值取负并将结果压入栈顶
0x76				fneg	将栈顶两float型数值取负并将结果压入栈顶
0x77				dneg	将栈顶两double型数值取负并将结果压入栈顶
0x78				ishl	将栈顶int型数值左移位指定位数并将结果压入栈顶
0x79				lshl	将栈顶long型数值左移位指定位数并将结果压入栈顶
0x7a				ishr	将栈顶int型数值右移位指定位数并将结果压入栈顶
0x7b				lshr	将栈顶long型数值右移位指定位数并将结果压入栈顶
0x7c				iushr	将栈顶int型数值右无符号移位指定位数并将结果压入栈顶
0x7d				lushr	将栈顶int型数值右无符号移位指定位数并将结果压入栈顶
0x7e				iand	将栈顶两int型数值 按位与 并将结果压入栈顶
0x7f				land	将栈顶两long型数值 按位与 并将结果压入栈顶
0x80				ior		将栈顶两int型数值 按位或 并将结果压入栈顶
0x81				lor		将栈顶两long型数值 按位或 并将结果压入栈顶
0x82				ixor	将栈顶两int型数值 按位异或 并将结果压入栈顶
0x83				lxor	将栈顶两long型数值 按位异或 并将结果压入栈顶
```



## 8. 自增减

```shell
指令码			助记符			说明
0x84			iinc		将指定int型变量增加指定值(i++, i-- ,i += 2)
```

## 9. 类型转换

该系类负责对栈顶数值进行类型转换，并将结果压入栈顶

```shell
指令码			助记符			说明
0x85			i2l		将int型数值强转为long型数值并将结果压入栈顶
0x86			i2f		将int型数值强转为float型数值并将结果压入栈顶
0x87			i2d		将int型数值强转为double型数值并将结果压入栈顶
0x88			l2i		将long型数值强转为int型数值并将结果压入栈顶
0x89			l2f		将long型数值强转为float型数值并将结果压入栈顶
0x8a			l2d		将long型数值强转为double型数值并将结果压入栈顶
0x8b			f2i		将float型数值强转为int型数值并将结果压入栈顶
0x8c			f2l		将float型数值强转为long型数值并将结果压入栈顶
0x8d			f2d		将float型数值强转为double型数值并将结果压入栈顶
0x8e			d2i		将double型数值强转为int型数值并将结果压入栈顶
0x8f			d2l		将double型数值强转为long型数值并将结果压入栈顶
0x90			d2f		将double型数值强转为float型数值并将结果压入栈顶
0x91			i2b		将int型数值强转为boolean型数值并将结果压入栈顶
0x92			i2c		将int型数值强转为char型数值并将结果压入栈顶
0x93			i2s		将int型数值强转为short型数值并将结果压入栈顶
```



## 10.比较指令

该系类指令用于对栈顶非int型元素进行比较，并把结果压入栈顶

```shell
指令码			助记符			说明
0x94			lcmp	比较栈顶两long型数值,并将结果(1,0,-1)压入栈顶
0x95			fcmpl	比较栈顶两float型数值,并将结果(1,0,-1)压入栈顶;当其中一个数值为NaN时,将-1压入栈顶
0x96			fcmpg	比较栈顶两float型数值,并将结果(1,0,-1)压入栈顶;当其中一个数值为NaN时,将1压入栈顶
0x97			dcmpl	比较栈顶两double型数值,并将结果(1,0,-1)压入栈顶;当其中一个数值为NaN时,将-1压入栈顶
0x98			dcmpg	比较栈顶两double型数值,并将结果(1,0,-1)压入栈顶;当其中一个数值为NaN时,将1压入栈顶
```



## 11. 有条件跳转指令

该系列指令用于对栈顶int型元素进行比较，根据结果进行跳转。第一个参数为要跳转到的代码的地址(这里的地址是指其指令在函数内是第几个指令。)

```shell
指令码			助记符				说明
0x99			ifeq			当栈顶int型数值等于0时跳转
0x9a			ifne			当栈顶int型数值不等于0时跳转
0x9b			iflt			当栈顶int型数值小于0时跳转
0x9c			ifge			当栈顶int型数值大于等于0时跳转
0x9d			ifgt			当栈顶int型数值大于0时跳转
0x9e			ifle			当栈顶int型数值小于等于0时跳转
0x9f			if_icmpeq		比较栈顶两int型值大小,当结果等于0时跳转
0xa0			if_icmpne		比较栈顶两int型值大小,当结果不等于0时跳转
0xa1			if_icmplt		比较栈顶两int型值大小,当结果小于0时跳转
0xa2			if_icmpge		比较栈顶两int型值大小,当结果大于等于0时跳转
0xa3			if_icmpgt		比较栈顶两int型值大小,当结果大于0时跳转
0xa4			if_icmple		比较栈顶两int型值大小,当结果小于等于0时跳转
0xa5			ifacmpeq		比较栈顶两引用型值大小,当结果相等时跳转
0xa6			if_acmpne		比较栈顶两引用型值大小,当结果不相等时跳转
```



## 12.无条件跳转指令

```shell
指令码			助记符				说明
0xa7			goto			无条件跳转
0xa8			jsr			跳转至指定16位offset位置，并将jsr下一条指令地址压入栈顶
0xa9			ret			返回至本地变量指定的index的指令位置(一般与jsr,jsr_w联合使用)
0xaa			tableswitch 用于switch调换跳转,case连续(可变长度指令)
0xab			lookupswitch 用于switch条件跳转,case值不连续(可变长度指令)
```



## 13.返回指令

该系列指令用于从函数中返回；如果有返回值的话，都把函数的返回值放在栈道中，以便它的调用方法取得它。

```shell
指令码			助记符				说明
0xac			ireturn			从当前方法返回int
0xad			lreturn			从当前方法返回long
0xae			freturn			从当前方法返回float
0xaf			dreturn			从当前方法返回double
0xb0			areturn			从当前方法返回对象引用
0xb1			return			从当前方法返回void
```



## 14.域操作指令

该系列指令用于对静态和非静态域进行读写。该系列命令需要跟一个表明域 编号的 参数。

```shell
指令码			助记符				说明
0xb2			getstatic		获取指令类的静态域,并将其值压入栈顶
0xb3			putstatic		用栈顶的值为指定的类的静态域 赋值
0xb4			getfield		获取指定类的实例域, 并将其压入栈顶
0xb5			putfield		用栈顶的值为指定的类的实例域  赋值
```



## 15. 方法操作指令

该系列指令用于对静态方法和非静态方法进行调用。该系列命令需要跟一个表明 方法编号的参数。

```shell
指令码			助记符				说明
0xb6			invokevirtual		调用实例方法
0xb7			invokespecial		调用超类构造方法,实例初始化方法,私有方法
0xb8			invokestatic		调用静态方法
0xb9			invokeinterface		调用接口方法
0xba			invokedynamic		调用动态方法
```



## 16.未归类

```shell
指令码			助记符				说明
```



## 17.new以及数组创建

该系列用于创建一个对象和数组。

```shel
指令码			助记符				说明
0xbb			new				创建一个对象,并将其引用值压入栈顶
0xbc			newarray		创建一个指定原始类型(如int,float,char..)数组,并将其引用值压入栈顶
0xbd			anewarray	创建一个引用型(如类,接口,数组)的数组,并将其引用值压入栈顶
0xbe			arraylength  获得数组的长度值并压入栈顶
```



## 18.异常抛出指令

用于抛出异常

```shell
指令码			助记符				说明
0xbf		 athrow				将栈顶的异常抛出
```

## 19.对象操作

该系列指令用于操作对象。

```shell
指令码			助记符			说明
0xc0		checkcast		检验类型转换,检验未通过将抛出异常ClassCastException
0xc1		instanceof	检验对戏那个是否是指定的类的实例,如果是将1压入栈顶,否则将0压入
0xc2		monitorenter	获得对象的锁,用于同步方法或同步块
0xc3		monitorexit		释放对象的锁,用于同步方法或同步块
```

## 20. 未归类

```shell
指令码			助记符				说明
0xc4			wide			扩展本地变量的宽度
```



## 21.new多维数组

```shell
指令码			助记符			说明
0xc5		multianewarray	创建指定类型和指定维度的多维数组(指定该指令时,操作栈中必须包含各维度的长度值),并将其引用值压入栈顶
```



## 22.有条件跳转指令

该系列用于根据引用是否为空，来进行相应的指令跳转。

```shell
指令码			助记符			说明
0xc6		ifnull		为null时跳转
0xc7		ifnotnull	不为null时跳转
```



## 23.无条件跳转指令

该系列指令用于进行无条件指令跳转。

```shell
指令码			助记符			说明
0xc8		goto_w		无条件跳转
0xc9		jsr_w		跳转至指定32位offset位置,并将jsr_w下一条指令地址压入栈顶
```





## 

## 

