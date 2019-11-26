# JSON

python3中可以使用json模块来对JSON数据进行编解码，它包含了两个函数：

* json.dumps(): 对数据进行编码
* json.loads(): 对数据进行解码

python 编码为JSON类型转换对应表：

| python        | json   |
| ------------- | ------ |
| dict          | object |
| list, tupe    | array  |
| str           | string |
| int, float 等 | number |
| True          | true   |
| False         | false  |
| None          | null   |

JSON解码为python类型转换对应表：

| json         | python |
| ------------ | ------ |
| object       | dict   |
| array        | list   |
| string       | str    |
| number(int)  | int    |
| number(real) | float  |
| true         | True   |
| false        | False  |
| null         | None   |

Example:

```python
#!/use/bin/python3
# coding=utf-8
import json
# dict
data = {
    'no': 1,
    'name': 'Runoob',
    'url': 'http://www.runoob.com'
}

json_str = json.dumps(data)
print("origin str:", repr(data))
print("json:", json_str)

## 输出
origin str: {'no': 1, 'name': 'Runoob', 'url': 'http://www.runoob.com'}
json: {"no": 1, "name": "Runoob", "url": "http://www.runoob.com"}
```

Example:

```python
#!/use/bin/python3
# coding=utf-8
import json
# dict
data = {
    'no': 1,
    'name': 'Runoob',
    'url': 'http://www.runoob.com'
}

json_str = json.dumps(data)
print("origin str:", repr(data))
print("json:", json_str)
# json to python dict
data2 = json.loads(json_str)
print("data2['name']:", data2['name'])
print("data2['url']:", data2['url'])

### 输出
origin str: {'no': 1, 'name': 'Runoob', 'url': 'http://www.runoob.com'}
json: {"no": 1, "name": "Runoob", "url": "http://www.runoob.com"}
data2['name']: Runoob
data2['url']: http://www.runoob.com
```



