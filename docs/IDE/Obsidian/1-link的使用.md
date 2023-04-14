---
tags: obsidian,link
---
[TOC]


## 1.  internal link

```
# 直接连接到一个文件
[[name of file]]

#link to head in a note
[[File#head]]
[[File#head 1#Head 2]]

# link to block in a note
[[File#^block]]

# create a block
add ^human-block at the end of a block.

# change the link display text
Wikilink frmat:
Use the vertical bar (|) to change the text used to display a link.
[[internal link|display text]]

Markdown format:
Enter the display text between the square brackets ([])
[display text](url)

```
[[0-Obsidian index]]

## 2. external link

```
[content](url)

# 对于一下有特殊符号的url可以编码,如: 空格替换为 %20
# 也可以把有特殊符号的url写在 <> 中如:
[note](<url>)
```
example:

[百度](https://www.baidu.com/index.php?tn=monline_3_dg)


## 3.  Callouts (标注)

```
> [!note]
```
example:

> [!info]
> here is example of callouts.
> It supports **Markdown**,  [[1-link的使用 | Internal link]], and [[0-Obsidian index | embeds]] !
> ![[obsidian.png]]

## 4. comment

```
%%content%%
```

example:

this is an %%inline%% comment.

%%
this is block comment
Block comment can span multiple line
%%


## 5. embeds
```
# 可以嵌入图片, 视频,pdf(不会显示pdf内容,相当于是附件)
![[file]]
```
