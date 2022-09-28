# openssl - 非对称加密

## RSA

```shell
#include <openssl/rsa.h>

## allocate 一个RSA
RSA *RSA_new(void);
## 释放 一个RSA
void RSA_free(RSA *r);

int RSA_bits(const RSA *rsa);
## RSA module的 size.  用于决定RSA加密后的数据长度
int RSA_size(const RSA *rsa);

## 生成一对秘钥
int RSA_generate_key_ex(RSA *rsa, int bits, BIGNUM *e, BN_GENCB *cb);
	- rsa: RSA_new 生成的一个上下文
	- bits: 秘钥长度, 最少为1024, 可以设置为 1024*n 的值, 即需要时1024的整数倍
	- e: BN_new 生成的一个伪随机数
	- cb: 回调函数
	
## 公钥加密
## flen must be less than RSA_size(rsa) - 11 for the PKCS #1 v1.5 based padding modes
## less than RSA_size(rsa) - 41 for RSA_PKCS1_OAEP_PADDING and 
## exactly RSA_size(rsa) for RSA_NO_PADDING
int RSA_public_encrypt(int flen, const unsigned char *from,
                       unsigned char *to, RSA *rsa, int padding);
    - flen:参数from 数据长度; 0 < flen <= 秘钥长度-11
    - from: 要加密的数据
    - to: 存储加密后的数据, to的长度至少是 RSA_size
    - RSA: 上下文
    - padding: 
    	## PKCS #1 v1.5 padding. This currently is the most widely used mode
    	RSA_PKCS1_PADDING
    	## EME-OAEP as defined in PKCS #1 v2.0 with SHA-1, MGF1 and an empty encoding parameter. This mode is recommended for all new applications
    	RSA_PKCS1_OAEP_PADDING
    	## PKCS #1 v1.5 padding with an SSL-specific modification that denotes that the server is SSL3 capable
    	RSA_SSLV23_PADDING
    	## Raw RSA encryption
    	RSA_NO_PADDING
    return val:
    RSA_private_encrypt() returns the size of the signature (i.e., RSA_size(rsa)). RSA_public_decrypt() returns the size of the recovered message digest.
    On error, -1 is returned; the error codes can be obtained by ERR_get_error(3).
                       
## 私钥解密             
int RSA_private_encrypt(int flen, const unsigned char *from,
                        unsigned char *to, RSA *rsa, int padding);
	- flen: from的长度
	- from: 要解密的数据
	- to: 存储解密后的数据. RSA_size长度
	- RSA: 上下文
	- padding: 补充的方式
	   
	 return val:
    RSA_private_encrypt() returns the size of the signature (i.e., RSA_size(rsa)). RSA_public_decrypt() returns the size of the recovered message digest.
    On error, -1 is returned; the error codes can be obtained by ERR_get_error(3).
## 公钥解密
int RSA_public_decrypt(int flen, const unsigned char *from,
                       unsigned char *to, RSA *rsa, int padding);
                       
## 私钥解密
int RSA_private_decrypt(int flen, const unsigned char *from,
                        unsigned char *to, RSA *rsa, int padding);

## RSA 签名
## sigret must point to RSA_size(rsa) bytes of memory
int RSA_sign(int type, const unsigned char *m, unsigned int m_length,
             unsigned char *sigret, unsigned int *siglen, RSA *rsa);
	- type: 签名算法:
		## type denotes the message digest algorithm that was used to generate m. It usually is one of NID_sha1,NID_ripemd160 and NID_md5
    - m: 要签名的数据
    - m_length: m 的长度
    - sigret: 存储签名
    - siglen: sigret的长度
    - rsa: 上下文
    
    return val：
    	 1 on success, 0 otherwise
## RSA 校验
int RSA_verify(int type, const unsigned char *m, unsigned int m_length,
               const unsigned char *sigbuf, unsigned int siglen, RSA *rsa);
	- type: 签名的算法
	- m: 要签名的数据
	- m_length: m 的长度
	- sigbuf: 要验证的签名
	- siglen: sigbuf的长度
	- rsa:  上下文
	return val：
    	 1 on success, 0 otherwise
## 复制RSA 的公钥
RSA *RSAPublicKey_dup(RSA *rsa);

## 复制RSA 的私钥
RSA *RSAPrivateKey_dup(RSA *rsa);
```



```shell
#include <openssl/bn.h>
# 生成一个 BIGNUM
BIGNUM *BN_new(void);
# 初始化 BIGNUM
void BN_init(BIGNUM *);
# clear BigNum
void BN_clear(BIGNUM *a);
# 释放 BigNUM
void BN_free(BIGNUM *a);

void BN_clear_free(BIGNUM *a);

int BN_zero(BIGNUM *a);
int BN_one(BIGNUM *a);

const BIGNUM *BN_value_one(void);

int BN_set_word(BIGNUM *a, unsigned long w);
unsigned long BN_get_word(BIGNUM *a);

```



```shell
#include <openssl/pem.h>
# 使用BIO 读取RSA 的私钥
RSA *PEM_read_bio_RSAPrivateKey(BIO *bp, RSA **x,
								pem_password_cb *cb, void *u);
	- bp: 要操作的一个BIO entity
	- x: 存储读取的结果
	- cb: 回调函数
	- u: 
# 从fp中读取RSA私钥
RSA *PEM_read_RSAPrivateKey(FILE *fp, RSA **x,
								pem_password_cb *cb, void *u);

int PEM_write_bio_RSAPrivateKey(BIO *bp, RSA *x, const EVP_CIPHER *enc,
							unsigned char *kstr, int klen,pem_password_cb *cb, void *u);
	- bp: 要操作的BIO 对象
	- x: 存储读取的 数据
	- enc: 指私钥被加密的算法(为了安全,私钥存储到文件时被加密了)
	- kstr: For the PEM write routines if the kstr parameter is not NULL then klen bytes at kstr are used as the passphrase
		私钥被写入文件时如果制定了算法，则kstr是加密秘钥
	- klen: 表示kstr的加密秘钥长度
	- cb: 回到函数
	- u: 
	1. If the cb parameters is set to NULL and the u parameter is not NULL then the u parameter is interpreted as a null terminated string to use as the passphrase
	   (如果cb为null,u不为null,那么u被解析为一个字符串, 并被使用为秘钥密码)
	2. If both cb and u are NULL then the default callback routine is used which will typically prompt for the passphrase on the current terminal with echoing turned off.

int PEM_write_RSAPrivateKey(FILE *fp, RSA *x, const EVP_CIPHER *enc,
							unsigned char *kstr, int klen,pem_password_cb *cb, void *u);

RSA *PEM_read_bio_RSAPublicKey(BIO *bp, RSA **x,
							pem_password_cb *cb, void *u);

RSA *PEM_read_RSAPublicKey(FILE *fp, RSA **x,
							pem_password_cb *cb, void *u);

int PEM_write_bio_RSAPublicKey(BIO *bp, RSA *x);

int PEM_write_RSAPublicKey(FILE *fp, RSA *x);

RSA *PEM_read_bio_RSA_PUBKEY(BIO *bp, RSA **x,
							pem_password_cb *cb, void *u);

RSA *PEM_read_RSA_PUBKEY(FILE *fp, RSA **x,
							pem_password_cb *cb, void *u);

int PEM_write_bio_RSA_PUBKEY(BIO *bp, RSA *x);

int PEM_write_RSA_PUBKEY(FILE *fp, RSA *x);


### return val
The read routines return either a pointer to the structure read or NULL if an error occurred.
The write routines return 1 for success or 0 for failure
```



BIO 操作

```shell
#include <openssl/bio.h>

BIO_METHOD *   BIO_s_file(void);
# 使用BIO,并使用mode模式来打开filename文件
BIO *BIO_new_file(const char *filename, const char *mode);
# 使用BIO 包裹 FILE 来进行读写
BIO *BIO_new_fp(FILE *stream, int flags);

# 设置BIO 的FILE 指针
BIO_set_fp(BIO *b,FILE *fp, int flags);
BIO_get_fp(BIO *b,FILE **fpp);

# BIO_read_filename(), BIO_write_filename(), BIO_append_filename() and BIO_rw_filename() set the file BIO b to use file name for reading, writing, append or read write respectively
int BIO_read_filename(BIO *b, char *name)
int BIO_write_filename(BIO *b, char *name)
int BIO_append_filename(BIO *b, char *name)
int BIO_rw_filename(BIO *b, char *name)

# BIO 读写postition 设置
int BIO_reset(BIO *b);
int BIO_seek(BIO *b, int ofs);
int BIO_tell(BIO *b);
int BIO_flush(BIO *b);
int BIO_eof(BIO *b);
int BIO_set_close(BIO *b,long flag);
int BIO_get_close(BIO *b);
int BIO_pending(BIO *b);
int BIO_wpending(BIO *b);
size_t BIO_ctrl_pending(BIO *b);
size_t BIO_ctrl_wpending(BIO *b);

int BIO_get_info_callback(BIO *b,bio_info_cb **cbp);
int BIO_set_info_callback(BIO *b,bio_info_cb *cb);

typedef void bio_info_cb(BIO *b, int oper, const char *ptr, int arg1, long arg2, long arg3);
```









获取错误的函数

```shell
#include <openssl/err.h>
# 获取最早的 错误， 并从队列中删除
unsigned long ERR_get_error(void);
# 获取错误, 但不删除
unsigned long ERR_peek_error(void);
unsigned long ERR_peek_last_error(void);
# 获取错误, 但是带有 文件名 和行号
unsigned long ERR_get_error_line(const char **file, int *line);
unsigned long ERR_peek_error_line(const char **file, int *line);
unsigned long ERR_peek_last_error_line(const char **file, int *line);

# 带有文件名和行号 以及 data 和flags
# ERR_get_error_line_data(), ERR_peek_error_line_data() and ERR_peek_last_error_line_data() store additional data and flags associated with the error code in *data and *flags, unless these are NULL. *data contains a string if *flags&ERR_TXT_STRING is true
## 
unsigned long ERR_get_error_line_data(const char **file, int *line,
const char **data, int *flags);
unsigned long ERR_peek_error_line_data(const char **file, int *line,
const char **data, int *flags);
unsigned long ERR_peek_last_error_line_data(const char **file, int *line,
const char **data, int *flags);
```







































