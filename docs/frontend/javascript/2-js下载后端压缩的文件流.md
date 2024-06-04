---
tags:
  - javascript
  - download
  - compress
---
针对一般的查询(GET 请求)结果下载成文件, 一般可以通过
* window.URL.createObjectUrl()
* window.open
* FileReader.readAdDataUrl() 

三种方法来对GET 请求进行下载操作.


现在的需求是:
后端返回压缩后的数据流, header as below:
```
content-type: application/octet-stream
content-disposition: attachemnt; filename=search.csv.zip
```

具体下载如下:
```
const xhr = new XMLHttpRequest()
xhr.setRequestHeader("content-type","application/json")
// 如果设置了 responseType为blob, 那么创建blob时需要使用xhr.response.  使用其他会失败, 如xhr.responseText
xhr.responseType = 'blob'
xhr.onreadystatechange = function() {
	if(xhr.status===200){
		const response = xhr.response;
		// get filename from response header
		const filename = xhr.getResponseHeader("content-disposition").match(".*;filename=(.*))[1]
		const blob = new Blob([res], {type: "application/zip; charset=utf-8"})
		const blobUrl = window.URL.createObjectURL(blob)
		const link = document.createElement("a")
		link.href = blobUrl
		link.download = filename
		link.click()
		setTimeout(() => {
		window.URL.revokeObjectURL(blobUrl)
		}, 2000)
	}
}

```

> 注意:
> 当设置了 responseType=blob时, 创建 Blob对象时,需要使用 response对象.


responseType类型

| value       | 对应的数据类型                                                       |
| ----------- | ------------------------------------------------------------- |
| ‘’          | DOMString(默认类型)                                               |
| arraybuffer | ArrayBuffer object                                            |
| blob        | Blob object                                                   |
| document    | Document object                                               |
| json        | javascript object, parsed from a json string return by server |
| text        | DOMString                                                     |
|             |                                                               |
如何设置：
```
1. 原生js使用XMLHttpRequest时, 通过 xhr.responseType='blob' 设置
2. axios , 可以直接在参数对象中写入:  responseType: blob
3. jquery不能直接设置, 需借助xhrFields,  设置 xheFields:{responseType:"blob"}
$ajax({
	url: "",
	xhrFields: {
	responseType: "blob"
	}
})
```

