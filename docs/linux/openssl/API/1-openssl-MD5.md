# openssl 之 MD5



## MD5

记录一下使用到的MD5接口函数

```shell
#include <openssl/md5.h>

# define MD5_DIGEST_LENGTH 16		#指纹结果长度

# 记录md5上下文的 结构体
typedef struct MD5state_st {
    MD5_LONG A, B, C, D;
    MD5_LONG Nl, Nh;
    MD5_LONG data[MD5_LBLOCK];
    unsigned int num;
} MD5_CTX;

# MD5 上下文结构体初始化
int MD5_Init(MD5_CTX *c);
	- c: md5的上下文
	
	return val:
	- 1: success
	- 0: fail
# 更新要进行 md5的数据
int MD5_Update(MD5_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 要编码的数据
	- len: data的长度
	
	return val:
	- 1; success
	- 0: fail
# 生成MD5 值
int MD5_Final(unsigned char *md, MD5_CTX *c);
	- md: 最后生成的md5值
	- c: 上下文
	
	return val:
	- 1: success
	- 0: fail
# 生成MD5 值
unsigned char *MD5(const unsigned char *d, size_t n, unsigned char *md);
	- d: 要编码的数据
	- n: 数据的长度
	- md: 最后的md5结果
	
	return val:
	- return pointers to the hase value.(md)
	
# 没看到具体的使用， 先mark保留 ？？？
void MD5_Transform(MD5_CTX *c, const unsigned char *b);

```



## SHA1

```shell
#include <openssl/sha.h>

# 最后生成指纹的长度
# define SHA_DIGEST_LENGTH 20

typedef struct SHAstate_st {
    SHA_LONG h0, h1, h2, h3, h4;
    SHA_LONG Nl, Nh;
    SHA_LONG data[SHA_LBLOCK];
    unsigned int num;
} SHA_CTX;

# 初始化上下文
int SHA1_Init(SHA_CTX *c);
	- c; 上下文
	return val:
	- 1 : success
	- 0: fail
# 添加要计算指纹的数据
int SHA1_Update(SHA_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 输入参数, 要计算指纹的数据
	- len: data的长度
	
	return val:
	- 1 : success
	- 0: fail
# 计算指纹
int SHA1_Final(unsigned char *md, SHA_CTX *c);
	- md; 生成的指纹数据
	- c: 上下文

	return val:
	- 1 : success
	- 0: fail
// # 计算指针
unsigned char *SHA1(const unsigned char *d, size_t n, unsigned char *md);
	- d: 要计算的数据
	- n: 参数d的长度
	- md: 最后生成的指纹
	
	return val:
	- 1 : success
	- 0: fail
```









## SHA{224,256,384,512}

```shell
#include <openssl/sha.h>

# define SHA224_DIGEST_LENGTH    28
# define SHA256_DIGEST_LENGTH    32
# define SHA384_DIGEST_LENGTH    48
# define SHA512_DIGEST_LENGTH    64


# 上下文初始化
int SHA224_Init(SHA256_CTX *c);
	- c: 上下文结构体
	
	return val: 
	- 1: success
	- 0: fail
# 添加要计算指纹的数据
int SHA224_Update(SHA256_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 要计算的数据
	- len: 数据(data)的长度
	
	return val:
	- 1: success
	- 0:fail
# 计算指纹
int SHA224_Final(unsigned char *md, SHA256_CTX *c);
	- md: 最后指纹的结果
	- c: 上下文
	return val:
	- 1: success
	- 0: fail

# 计算指针
unsigned char *SHA224(const unsigned char *d, size_t n, unsigned char *md);
	-d: 要计算的数据
	-n: 要计算数据的长度 
	-md: 最后的 指纹结果
	return val:
	- 1: success
	- 0: fail


# 上下文初始化
int SHA256_Init(SHA256_CTX *c);
	- c: 上下文结构体
	
	return val: 
	- 1: success
	- 0: fail
# 添加要计算指纹的数据
int SHA256_Update(SHA256_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 要计算的数据
	- len: 数据(data)的长度
	
	return val:
	- 1: success
	- 0:fail
# 计算指纹
int SHA256_Final(unsigned char *md, SHA256_CTX *c);
	- md: 最后指纹的结果
	- c: 上下文
	return val:
	- 1: success
	- 0: fail
# 计算指针
unsigned char *SHA256(const unsigned char *d, size_t n, unsigned char *md);
	-d: 要计算的数据
	-n: 要计算数据的长度 
	-md: 最后的 指纹结果
	return val:
	- 1: success
	- 0: fail

# 上下文初始化
int SHA384_Init(SHA512_CTX *c);
	- c: 上下文结构体
	
	return val: 
	- 1: success
	- 0: fail
# 添加要计算指纹的数据
int SHA384_Update(SHA512_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 要计算的数据
	- len: 数据(data)的长度
	
	return val:
	- 1: success
	- 0:fail
# 计算指纹
int SHA384_Final(unsigned char *md, SHA512_CTX *c);
	- md: 最后指纹的结果
	- c: 上下文
	return val:
	- 1: success
	- 0: fail
# 计算指针
unsigned char *SHA384(const unsigned char *d, size_t n, unsigned char *md);
	-d: 要计算的数据
	-n: 要计算数据的长度 
	-md: 最后的 指纹结果
	return val:
	- 1: success
	- 0: fail

# 上下文初始化
int SHA512_Init(SHA512_CTX *c);
	- c: 上下文结构体
	
	return val: 
	- 1: success
	- 0: fail
# 添加要计算指纹的数据
int SHA512_Update(SHA512_CTX *c, const void *data, size_t len);
	- c: 上下文
	- data: 要计算的数据
	- len: 数据(data)的长度
	
	return val:
	- 1: success
	- 0:fail
# 计算指纹
int SHA512_Final(unsigned char *md, SHA512_CTX *c);
	- md: 最后指纹的结果
	- c: 上下文
	return val:
	- 1: success
	- 0: fail
# 计算指针
unsigned char *SHA512(const unsigned char *d, size_t n, unsigned char *md);
	-d: 要计算的数据
	-n: 要计算数据的长度 
	-md: 最后的 指纹结果
	return val:
	- 1: success
	- 0: fail

```







