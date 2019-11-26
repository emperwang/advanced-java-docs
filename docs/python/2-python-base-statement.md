# 基础语句

## 0. 注释

```shell
# 单行注释 以 井号开头,#
# 多行注释两种方式:
## 方式一: 单引号
'''

'''

## 方式二: 双引号
"""
  
"""

```



## 1.if语句

```python
// 多条件
if condition:
	process ....
elif condition2:
	process ...
elif confition3:
	process ...
else:
	process ...

// 一般使用
if condition:
    process ...
else: 
	process ...
```

example:

```python
score = 80
if score >= 90:
    print("very good")
elif score >= 80:
    print("good")
else:
    print("just so so")
```



## 2.while

```python
// 在条件符合是,循环一直执行
while condition:
    process ....
    
// 带有else语句，当condition为false时执行else
while condition:
    process ...
else: // false
    process ...
```

example:

````python
#!/usr/bin/python3
# coding=utf-8
score = 1
while score <= 10:
    print(score)
    score = score + 2
else:
    print("existing...")
````



## 3. for

```python
for <var> in <sequence>:
    statement ...
else:
    <statement> ...
```

```python
#!/usr/bin/python3
# coding=utf-8
sites = ["baidu", "Google", "Running"]
for var in sites:
    print(var)
else:
    print("no elements anymore .....")
```

```python
#!/usr/bin/python3
# coding=utf-8
sites = ["baidu", "Google", "Running"]
for var in sites:
    print(var, end=" ")		# 把最后的换行符去除
else:
    print("no elements anymore .....")
```



## 4. break

example:

```python
#!/usr/bin/python3
# coding=utf-8
var = 1
while var <= 20:
    print(var)
    if var == 2:
        break		## 当输出到2时  结束
    var += 1

结果:
1
2
```



## 5.continue

```python
#!/usr/bin/python3
# coding=utf-8
var = 0
while var <= 10:
    if var == 2:
        var += 1
        continue		## 跳过2
    print("current value is:", var)
    var += 1
print("while end....")
```

