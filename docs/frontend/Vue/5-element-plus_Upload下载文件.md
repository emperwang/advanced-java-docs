---
tags:
  - Vue
  - js
  - element-plus
  - upload
---
这是一个小的转换工具,  前端上传一个数据文件, 后端转换为csv文件, 并返回要压缩后的数据流到前端, 再由前端进行下载.

```
<body>
    <div id="app">
        <el-container class="container">
            <el-header class="header"></el-header>
            <el-main class=" main">
                <el-upload 
                class="upload-demo" 
                :show-file-list="false" 
                v-model:file-list="fileList" 
                drag action=""
                :limit="1" 
                :on-exceed="handleExceed"
                :on-success="handleSuccess"
				>
                    <el-icon class="el-icon--upload"></el-icon>
                    <div class="el-upload__text">
                        Drop file here or <em>click to upload</em>
                    </div>
                </el-upload>
            </el-main>
        </el-container>
    </div>
    <script>
        const app = {
            data() {
                return {
                    message: "Hello world from Vue3",
                    "fileList": []
                }
            },
            methods: {
                handleExceed: (files, uploadFiles) => {
                    ElementPlus.ElMessage({
                        type: "error",
                        message: "upload one file one time"
                    })
                },
                handleSuccess: (response, uploadfile, uploadfiles) => {
	                const blob = new Blob([response], {type:"application/zip; charset=utf8"})
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
        };

        const App = Vue.createApp(app);
        App.use(ElementPlus);
        App.mount("#app");
    </script>

</body>
```

实现如上, 代码没有报错, 但是下载的文件是一个不完整的文件.

[[2-js下载后端压缩的文件流]] 实现所知,  使用blob流下载后端流, 需要使用xhr.response, 使用其他对象会失败.

upload源码实现: [Element-plus_Upload](https://github.com/element-plus/element-plus/blob/dev/packages/components/upload/src/ajax.ts#L55)
```
export const ajaxUpload: UploadRequestHandler = (option) => {
  if (typeof XMLHttpRequest === 'undefined')
    throwError(SCOPE, 'XMLHttpRequest is undefined')

  const xhr = new XMLHttpRequest()
  const action = option.action

  if (xhr.upload) {
    xhr.upload.addEventListener('progress', (evt) => {
      const progressEvt = evt as UploadProgressEvent
      progressEvt.percent = evt.total > 0 ? (evt.loaded / evt.total) * 100 : 0
      option.onProgress(progressEvt)
    })
  }

  const formData = new FormData()
  if (option.data) {
    for (const [key, value] of Object.entries(option.data)) {
      if (isArray(value) && value.length) formData.append(key, ...value)
      else formData.append(key, value)
    }
  }
  formData.append(option.filename, option.file, option.file.name)

  xhr.addEventListener('error', () => {
    option.onError(getError(action, option, xhr))
  })

  xhr.addEventListener('load', () => {
    if (xhr.status < 200 || xhr.status >= 300) {
      return option.onError(getError(action, option, xhr))
    }
    // 在这里回调注册的success函数
    option.onSuccess(getBody(xhr))
  })

  xhr.open(option.method, action, true)

  if (option.withCredentials && 'withCredentials' in xhr) {
    xhr.withCredentials = true
  }

  const headers = option.headers || {}
  if (headers instanceof Headers) {
    headers.forEach((value, key) => xhr.setRequestHeader(key, value))
  } else {
    for (const [key, value] of Object.entries(headers)) {
      if (isNil(value)) continue
      xhr.setRequestHeader(key, String(value))
    }
  }

  xhr.send(formData)
  return xhr
}



// 从此函数看到, 此处使用的 xhr.responseText, 所以导致出现问题 
function getBody(xhr: XMLHttpRequest): XMLHttpRequestResponseType {
  const text = xhr.responseText || xhr.response
  if (!text) {
    return text
  }

  try {
    return JSON.parse(text)
  } catch {
    return text
  }
}
```


修改如下:
```
注册httpRequest函数:
              <el-upload 
               ...
               :http-request="handleRequest"
				>


function handleRequest(options) {
	  if (typeof XMLHttpRequest === 'undefined')
    throwError(SCOPE, 'XMLHttpRequest is undefined')

  const xhr = new XMLHttpRequest()
  const action = option.action
// 设置返回类型
  xhr.responseType = "blob"
  
  xhr.addEventListener('load', () => {
    if (xhr.status < 200 || xhr.status >= 300) {
      return option.onError(getError(action, option, xhr))
    }
    // 在这里回调注册的success函数
    // 这里回调函数时,直接使用xhr
    option.onSuccess(xhr)
  })
.....
  xhr.send(formData)
  return xhr
}


function handleSuccess (response, uploadfile, uploadfiles){
const filename = xhr.getResponseHeader("content-disposition").match(".*;filename=(.*))[1]
// 这里在创建blob时使用 response对象
const blob = new Blob([Vue.xhr.response], {type:"application/zip; charset=utf8"})
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



