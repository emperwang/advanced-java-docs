# fucntion

## 1.简单函数

```python
def functioName(parameter):
    functionBody
```



```python
#!/usr/bin/python3
# coding=utf-8
def hello():
    print("this is hello function")


hello()
```



## 2.带参函数

```python
#!/usr/bin/python3
# coding=utf-8
def area(width, height):
    return width * height
## 调用调用
res = area(2, 3)
print("result is :", res)
```

### 2.1 必需参数

必需参数须以正确的顺序传入参数。 调用时的数量必须和声明时的一样。

```python
#!/usr/bin/python3
# coding=utf-8
def hello(name):
    print("hello", name)

hello()

## 输出
运行报错：
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 6, in <module>
    hello()
TypeError: hello() missing 1 required positional argument: 'name'
```

```python
#!/usr/bin/python3
# coding=utf-8
def hello(name):
    print("hello", name)

hello("zhangsan")

## 结果:
hello zhangsan
```



### 2.2 关键字参数

关键字参数和函数调用关系密切，函数调用使用关键字参数来确定传入的参数值。

```python
#!/usr/bin/python3
# coding=utf-8
def printInfo(name, age):
    "打印任何传入的字符串"
    print("name is: ",name)
    print("age is :",age)

printInfo(age=20, name="wangwu")

# 结果如下：
name is:  wangwu
age is : 20

# 对于关键字参数,调用时不需要按照参数顺序,但需要执行关键字的名字,来进行传参
```



### 2.3 默认参数

调用函数时，如果没有传递参数，则会使用默认参数。

```python
#!/usr/bin/python3
# coding=utf-8
def printInfo(name, age=35):
    "打印任何传入的字符串"
    print("name is: ",name)
    print("age is :",age)

printInfo(name="wangwu")

## 输出：
name is:  wangwu
age is : 35

## 由此可见,当没有传递age的参数时,则使用age的默认值 35
```



### 2.4 不定长参数

可以接收比声明时更多的参数。加了 *（星号）的参数会以元组的形式导入。

```python
#!/usr/bin/python3
# coding=utf-8
def printInfo(name, *var):
    "打印任何传入的字符串"
    print("name is: ",name)
    print("age is :",var)

printInfo("wangwu",70,60,50,40,30)

##输出：
name is:  wangwu
age is : (70, 60, 50, 40, 30)
```

### 2.5 强制位置参数

python3.8新增了一个函数形参语法  / 用来指明函数形参必须使用执行位置参数，不讷讷个使用关键字参数的形式。

```python
## 形参a 和b必须使用指定位置参数，c或d可以是位置形参或关键字形参，而e或f要求为关键字形参
def f(a, b, /, c, d, *, e, f):
    print(a, b ,c, d, e, f)
    
## 正确使用
f(10,20,30,d=40, e=50, f=60)

## 错误使用
f(10,b=20,c=30,d=40,e=50,f=60)  ## b不能使用关键字参数形式
f(10,20,30,40,50,f=60)	# e必须使用关键字参数
```

```python
#!/usr/bin/python3
# coding=utf-8
def f(a,b, /,c, d, *, e, f):
    print(a,b,c,d,e,f)

f(10,b=20,c=30,d=40,e=40,f=60)
## 输出
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 6, in <module>
    f(10,b=20,c=30,d=40,e=40,f=60)
TypeError: f() got some positional-only arguments passed as keyword arguments: 'b'
       
    
f(10,20,c=30,d=40,40,f=60)
## 输出
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 6
    f(10,20,c=30,d=40,40,f=60)
                      ^
SyntaxError: positional argument follows keyword argument
```





## 3.匿名函数

python使用lambda来创建匿名函数。

所谓匿名，意即不再使用def语句这样标准的形式定义一个函数：

* lambda 只是一个表达式，函数体比def简单的多
* lambda的主题时一个表达式，而不是一个代码块，仅仅能在lambda表达式中封装有限的逻辑进入
* lambda函数拥有自己的命名空间，且不能访问自己参数列表之外或全局命名空间里的参数
* 虽然lambda函数看起来只能写一行，却不等于c或c++的内联函数，后者的目的是调用时不占用栈内存从而增加执行效率

lambda 函数的语法值包含一个语句：

```python
lambda [arg1 [,arg2,....argn]]: expression
```

example:

```python
#!/usr/bin/python3
# coding=utf-8
sum = lambda arg1,arg2: arg1 + arg2

print("相加后:", sum(10,20))
print("相加后:", sum(50,10))

输出:
相加后: 30
相加后: 60
```





























