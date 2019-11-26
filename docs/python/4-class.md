# class

## 1.class的定义

```python
## 方法中会默认自带一个self参数,此self不是关键字,可以换成其他名字
class className:
    field			## 定义内部属性
    __field			## 私有属性, 内部调用: self.__field
    def ___init__(self):		## 构造函数
        process ...
    
    def method(self):		## 内部操作函数, self为默认带的参数
        process ...
    
    def  __method(self):	## 内部私有操作,只能内部调用: self.__method()
        process ...
```

### 1.1 constructor

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    i = 1213456

    ## constructor,实例化类时调用
    def __init__(self, *data):
        self.das = data

# instance
var = firstDemo("this is init paramer")

# invoke field and method
print("firstDemo's data:", var.das)

###  程序输出:
firstDemo's data: ('this is init paramer',)
```



### 1.2 field

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    i = 1213456

# instance
var = firstDemo()

# invoke field and method
print("firstDemo's field :", var.i)

### 输出:
firstDemo's field : 1213456
```



### 1.3 private field

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    __privateValue = 1213456

# instance
var = firstDemo()

# invoke field and method
print("firstDemo's field :", var.__privateValue)

### 输出:
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 11, in <module>
    print("firstDemo's field :", var.__privateValue)
AttributeError: 'firstDemo' object has no attribute '__privateValue'
```



### 1.4  method

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    i = 1213456

    ## constructor
    def __init__(self, *data):
        self.das = data

    def printMeth(self):
        return "hello world"

# instance
var = firstDemo("this is init paramer")

# invoke field and method
print("firstDemo's method:", var.printMeth())

### 输出:
firstDemo's method: hello world
```

### 1.5 private method

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    i = 1213456

    ## constructor
    def __init__(self, *data):
        self.das = data

    def __printMeth(self):
        return "hello world"


    def invokePrivate(self):
        return self.__printMeth();


# instance
var = firstDemo("this is init paramer")

# invoke field and method
print("firstDemo's method:", var.__printMeth())

## 输出:
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 23, in <module>
    print("firstDemo's method:", var.__printMeth())
AttributeError: 'firstDemo' object has no attribute '__printMeth'
```

正常调用:

```python
#!/usr/bin/python3
# coding=utf-8
class firstDemo:
    """ A simple demo"""
    i = 1213456

    ## constructor
    def __init__(self, *data):
        self.das = data

    def __printMeth(self):
        return "hello world"


    def invokePrivate(self):
        return self.__printMeth();


# instance
var = firstDemo("this is init paramer")

# invoke field and method
print("firstDemo's method:", var.invokePrivate())

## 输出:
firstDemo's method: hello world
```



### 1.6  类的实例化及调用

```python
## 如上，类的实例化，就是直接调用类就可以
var = firstDemo("this is init paramer")
## 有参数，则在 ()中填入参数
## 如果没有参数,则就空着()
```



## 2.继承

### 2.1 单继承

```python
#!/usr/bin/python3
# coding=utf-8
class person:

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def printInfo(self):
        print("name = ", self.name, ",age = ", self.age)
### 单继承，继承persion类
class student(person):

    def __init__(self, name, age, score):
        person.__init__(self,name, age)
        self.score = score

    def printStudent(self):
        print("name=%s, age=%d,score=%d"%(self.name, self.age, self.score))

## instance
var = student("zhangsan",20,100)

## invoke parent
var.printInfo()   ## 调用父类方法
## invoke student
var.printStudent()	## 调用自己的方法


#### 输出
name =  zhangsan ,age =  20
name=zhangsan, age=20,score=100
```



### 2.2 多继承

```python
#!/usr/bin/python3
# coding=utf-8
class person:

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def printInfo(self):
        print("name = ", self.name, ",age = ", self.age)


class speak:

    def __init__(self):
        pass

    def welcome(self):
        print("speaking......")



class student(person, speak):

    def __init__(self, name, age, score):
        person.__init__(self,name, age)
        self.score = score

    def printStudent(self):
        print("name=%s, age=%d,score=%d"%(self.name, self.age, self.score))

## instance
var = student("zhangsan",20,100)

## invoke parent
var.printInfo()		## 调用父类方法
var.welcome()
## invoke student
var.printStudent()	## 调用自己方法

### 输出：
name =  zhangsan ,age =  20
speaking......
name=zhangsan, age=20,score=100
```



### 2.3 方法复写

```python
#!/usr/bin/python3
# coding=utf-8
class person:

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def printInfo(self):
        print("name = ", self.name, ",age = ", self.age)

    def welcome(self):
        print("this is welcome...")


class student(person):

    def __init__(self, name, age, score):
        person.__init__(self,name, age)
        self.score = score

    def printstudent(self):
        print("name=%s, age=%d,score=%d"%(self.name, self.age, self.score))

    def welcome(self):
        print("this is %s speaking...." % self.name)


# instance
var = student("zhangsan",20,100)

# invoke student
var.printstudent()

# invoke parent
var.welcome()           # 调用复写方法
var.printInfo()


### 输出:
name=zhangsan, age=20,score=100
this is zhangsan speaking....
name =  zhangsan ,age =  20
```

### 2.4 使用父类私有field

```python
#!/usr/bin/python3
# coding=utf-8
class person:

    def __init__(self, name, age):
        self.__name = name
        self.age = age

    def printInfo(self):
        print("name = ", self.__name, ",age = ", self.age)


class speak:

    def __init__(self):
        pass

    def welcome(self):
        print("speaking......")


class student(person, speak):

    def __init__(self, name, age, score):
        person.__init__(self,name, age)
        self.score = score

    def printstudent(self):
        print("name=%s, age=%d,score=%d"%(self._person__name, self.age, self.score))

    def welcome(self):	### 调用父类的私有方法
        print("this is %s speaking...." % (self._person__name)) ## 这样调用时可以的
        print("this is %s speaking...."%(self.name)) ## 报错
        print("this is %s speaking"%(self.__name))	## 报错

## instance
var = student("zhangsan",20,100)

## invoke parent
var.printInfo()
var.welcome()
## invoke student
var.printstudent()

### 输出:   由此可见，正常的调用name属性是不可以的
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 41, in <module>
    var.welcome()
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 33, in welcome
    print("this is %s speaking...."%(self.name))
AttributeError: 'student' object has no attribute 'name'
name =  zhangsan ,age =  20
this is zhangsan speaking....
```

### 2.5 调用父类私有method

```python
#!/usr/bin/python3
# coding=utf-8
class person:

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __printInfo(self):
        print("name = ", self.__name, ",age = ", self.age)



class student(person):

    def __init__(self, name, age, score):
        person.__init__(self,name, age)
        self.score = score

    def printstudent(self):
        print("name=%s, age=%d,score=%d"%(self.name, self.age, self.score))

    def welcome(self):
        self.__printInfo
        print("this is %s speaking...." % (self.name))


# instance
var = student("zhangsan",20,100)

# invoke student
var.printstudent()		# 调用自己的方法

# invoke parent
var.welcome()	 # 调用父类的私有方法
var.__printInfo()	## 直接调用父类的私有方法
var.printInfo()

### 输出：    可见直接调用父类的私有方法，会报错
name=zhangsan, age=20,score=100
Traceback (most recent call last):
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 35, in <module>
    var.welcome()
  File "F:/pythonDemo/python_operation/basic/test-for-doc.py", line 24, in welcome
    self.__printInfo
AttributeError: 'student' object has no attribute '_student__printInfo'
```

## 3.类的专有方法

```python
__init__: 构造函数，在生成对象时调用
__del__: 析构函数，释放对戏那个时使用
__repr__: 打印，转换
__setitem__: 按照索引赋值
__getitem__: 按照索引获取值
__len__:  获得长度
__cmp__: 比较运算
__call__: 函数调用
__add__: 加 运算
__sub__: 减 运算
__mul__: 乘 运算
__truediv__: 除 运算
__mod__: 求余 运算
__pow__: 乘方 操作
```

### 3.1 运算符 add 重载

```python
#!/usr/bin/python3
# coding=utf-8
class Ventor:
    def __init__(self, a, b):
        self.a = a
        self.b = b

    def __str__(self):
        return 'Ventor(%d,%d)'%(self.a, self.b)

    def __add__(self, other):
        return Ventor(self.a + other.a, self.b + other.b)


v1 = Ventor(2, 10)
v2 = Ventor(3, 5)

print(v1 + v2)


## 输出结果:
Ventor(5,15)
```

