---
tags:
  - Home
---
足迹
```ActivityHistory
/
```


今天是 `=date(today).year`年`=date(today).month`月`=date(today).day`日, 今年已经过去了`=(date(today)-date(date(today).year+"-01-01")).days` 天。


最近10天修改
```dataview
LIST WHERE file.mtime >= date(today) - dur(10 day) sort file.mtime desc limit (20)
```



最近3天修改
```dataview
LIST WHERE file.mtime >= date(today) - dur(3 day) sort file.mtime desc limit (10)
```
