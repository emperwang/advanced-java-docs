---
tags:
  - electron
  - Vue
---
```
# electron + vue3项目的插件
vue create helloword
vue add electron-builder
npm run electron:serve
npm run electron:build 
```



### 1. build package的异常
build package 异常:
```
PS E:\code-workSpace\project-portal\electron-vue3> cnpm.cmd run electron:build

> electron-vue3@0.0.0 electron:build
> vite build && electron-builder

The CJS build of Vite's Node API is deprecated. See https://vitejs.dev/guide/troubleshooting.html#vite-cjs-node-api-deprecated for more details.
vite v5.1.4 building for production...
✓ 42 modules transformed.
dist/index.html                      0.43 kB │ gzip:  0.28 kB
dist/assets/AboutView-C6Dx7pxG.css   0.09 kB │ gzip:  0.10 kB
dist/assets/index-DHqK1tyo.css       4.21 kB │ gzip:  1.30 kB
dist/assets/AboutView-qmNf1BOh.js    0.23 kB │ gzip:  0.20 kB
dist/assets/index-Dp4XFkdS.js       88.59 kB │ gzip: 34.98 kB
✓ built in 1.20s
  • electron-builder  version=24.12.0 os=10.0.19045
  • loaded configuration  file=package.json ("build" field)
  • description is missed in the package.json  appPackageFile=E:\code-workSpace\project-portal\electron-vue3\package.json
  • author is missed in the package.json  appPackageFile=E:\code-workSpace\project-portal\electron-vue3\package.json
  • writing effective config  file=dist_electron\builder-effective-config.yaml
  • packaging       platform=win32 arch=x64 electron=29.0.1 appOutDir=dist_electron\win-unpacked
  • default Electron icon is used  reason=application icon is not set
  • downloading     url=https://github.com/electron-userland/electron-builder-binaries/releases/download/winCodeSign-2.6.0/winCodeSign-2.6.0.7z size=5.6 MB parts=1
  • downloaded      url=https://github.com/electron-userland/electron-builder-binaries/releases/download/winCodeSign-2.6.0/winCodeSign-2.6.0.7z duration=37.934s
  ⨯ cannot execute  cause=exit status 2
                    out=
    7-Zip (a) 21.07 (x64) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26

    Scanning the drive for archives:
    1 file, 5635384 bytes (5504 KiB)

    Extracting archive: C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551.7z
    --
    Path = C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551.7z
    Type = 7z
    Physical Size = 5635384
    Headers Size = 1492
    Method = LZMA2:24m LZMA:20 BCJ2
    Solid = +
    Blocks = 2
    Sub items Errors: 2
    Archives with Errors: 1
    Sub items Errors: 2
                    errorOut=ERROR: Cannot create symbolic link : �ͻ���û����������Ȩ�� : C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551\darwin\10.12\lib\libcrypto.dylib
    ERROR: Cannot create symbolic link : �ͻ���û����������Ȩ�� : C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551\darwin\10.12\lib\libssl.dylib
                    command='E:\code-workSpace\project-portal\electron-vue3\node_modules\.store\7zip-bin@5.2.0\node_modules\7zip-bin\win\x64\7za.exe' x -bd 'C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551.7z' '-oC:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign\196416551'
                    workingDir=C:\Users\Sparks\AppData\Local\electron-builder\Cache\winCodeSign
```

运行此build package命令时, 使用的是vs-code 嵌入的powershell,  报错是因为权限不对, 使用管理员模式的 powershell 重新build, 即可成功。


### 2. 安装electron的异常
```
# 安装electron时, 失败
npm ERR! command C:\WINDOWS\system32\cmd.exe /d /s /c node install.js
npm ERR! RequestError: connect ETIMEDOUT 13.250.177.223:443
npm ERR!     at ClientRequest.<anonymous> (E:\code-workSpace\project-portal\electron-vue3\node_modules\got\dist\source\core\index.js:970:111)
npm ERR!     at Object.onceWrapper (node:events:632:26)

```

没有找到更好的方法, 最后尝试 cnpm with 淘宝 registry 安装成功.
对于这种情况，就是去尝试多种registry 去进行安装。包括不限于cnpm，npm，yarn等





