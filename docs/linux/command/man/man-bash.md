---
tags:
  - linux
  - bash
  - man
  - shell
---
虽然经常写shell script,  但是时不时仍然会有 bash中的一些语法记得不清楚,  需要去google或者查看笔记.

举几个栗子:
1) shell中的字符串处理.(默认值, 替换, 长度)
2) bash  Process Substitution 使用 
3) `[[]]` 中的 =~ 和 == 有什么区别?
4) > /dev/null 2>&1  和 &>/dev/null 区别大吗?

如果都清楚的了解, 实在是大神.  

那在编写脚本时, 上面的语法或其他需要的语法想不起来, 怎么办呢?
大家都说google就好了.  好吧, 确实, google也可以,  当然问chatgpt也可以.

那如果是内网环境, 放问不了google, 怎么办?

这个时候就可以通过Linux中的man.  平时的小命令大家肯定也经常使用man来查询.  那么对于bash 或 csh的语法, 通过man也可以的.

当然, bash | csh 的 man文档肯定特别长,  相信我,  多看几次就不会有刚开始的担心了.

例如:

```shell
>/dev/null 2>&1  和 &>/dev/null 区别大吗?

man: 
  The format for appending standard output and standard error is:

              &>>word

       This is semantically equivalent to

              >>word 2>&1
```



```shell
bash  Process Substitution 使用 

man: 
   Process Substitution
       Process substitution allows a process's input or output to be referred to using a filename.  It takes the form of <(list) or >(list).  The process list is run asynchronously, and its input or out‐
       put appears as a filename.  This filename is passed as an argument to the current command as the result of the expansion.  If the >(list) form is used, writing to the file will provide  input  for
       list.   If  the  <(list) form is used, the file passed as an argument should be read to obtain the output of list.  Process substitution is supported on systems that support named pipes (FIFOs) or
       the /dev/fd method of naming open files.

       When available, process substitution is performed simultaneously with parameter and variable expansion, command substitution, and arithmetic expansion.
```


如果经常写脚本, 经常忘语法(我有这样的健忘症),  那就经常找man.








