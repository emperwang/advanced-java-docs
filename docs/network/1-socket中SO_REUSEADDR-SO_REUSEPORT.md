# socket中 SO_REUSEADDR和SO_REUSEPORT

## 1. socket的一些简介

基本上其他所有的系统某种程度上都参考了BSD socket实现(或者至少是其接口), 然后开始了他们各自的独立法阵, 简单说BSD实现是所有socket实现的起源.  所以理解BSD socket实现是理解其他socket实现的基石. 

在分析BSD 参数前, 先了解一些socket的基本知识.

TCP/UDP 是由以下五元组唯一的识别的:

`{<protocol>, <src addr>, <src port>, <dest addr>, <dest port>}`



## 2. BSD

### 2.1 SO_REUSEADDR



### 2.2 SO_REUSEPORT







