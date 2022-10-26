# openssl 对称加密

## AES 对称加密

```shell
#include <openssl/aes.h>
# define AES_ENCRYPT     1
# define AES_DECRYPT     0

# define AES_MAXNR 14
# define AES_BLOCK_SIZE 16

const char *AES_options(void);

## 设置加密的秘钥
int AES_set_encrypt_key(const unsigned char *userKey, const int bits,
                        AES_KEY *key);
		- userKey： 加密秘钥, 秘钥可选长度: 16 byte, 24byte, 32byte
		- bits: userkey的长度 bit = byts/8
		- key: 存储秘钥.  AES_KEY
## 设置解密的秘钥
int AES_set_decrypt_key(const unsigned char *userKey, const int bits,
                        AES_KEY *key);

## 加密
void AES_encrypt(const unsigned char *in, unsigned char *out,
                 const AES_KEY *key);
	- in:  输入的要加密的数据
	- out: 加密后的数据
	- key: 加密秘钥
## 解密
void AES_decrypt(const unsigned char *in, unsigned char *out,
                 const AES_KEY *key);

## AES_encrypt AES_decrypt默认使用的加解密方式是 ECB, 电子密码本,容易被破解.

# 加密
void AES_ecb_encrypt(const unsigned char *in, unsigned char *out,
                     const AES_KEY *key, const int enc);
                     
## 加密
void AES_cbc_encrypt(const unsigned char *in, unsigned char *out,
                     size_t length, const AES_KEY *key,
                     unsigned char *ivec, const int enc);
     - in: 要加密的数据
     - out: 存储加密后的数据, 密文和明文的长度是相同的,所以out的长度等于 length
     - length: 表示in的长度.
     	要求: 1.必须包含结尾\0的长度. length = in.length+\0
     		 2. (字符串长度+\0) % 16 == 0;  必须是16的整数倍
     		  - 实际长度计算: length = ((in.len /16) + 1) * 16
     - key: 初始化后的加密key;  秘钥可选长度: 16 byte, 24byte, 32byte
     - ivec: 初始化向量. 长度和分组长度相同
     - enc: 指明是加密还是解密,此值为两个宏中选择一个
     	 # define AES_ENCRYPT     1
		 # define AES_DECRYPT     0
     
void AES_cfb128_encrypt(const unsigned char *in, unsigned char *out,
                        size_t length, const AES_KEY *key,
                        unsigned char *ivec, int *num, const int enc);
void AES_cfb1_encrypt(const unsigned char *in, unsigned char *out,
                      size_t length, const AES_KEY *key,
                      unsigned char *ivec, int *num, const int enc);
void AES_cfb8_encrypt(const unsigned char *in, unsigned char *out,
                      size_t length, const AES_KEY *key,
                      unsigned char *ivec, int *num, const int enc);
void AES_ofb128_encrypt(const unsigned char *in, unsigned char *out,
                        size_t length, const AES_KEY *key,
                        unsigned char *ivec, int *num);
/* NB: the IV is _two_ blocks long */
void AES_ige_encrypt(const unsigned char *in, unsigned char *out,
                     size_t length, const AES_KEY *key,
                     unsigned char *ivec, const int enc);
/* NB: the IV is _four_ blocks long */
void AES_bi_ige_encrypt(const unsigned char *in, unsigned char *out,
                        size_t length, const AES_KEY *key,
                        const AES_KEY *key2, const unsigned char *ivec,
                        const int enc);

int AES_wrap_key(AES_KEY *key, const unsigned char *iv,
                 unsigned char *out,const unsigned char *in, unsigned int inlen);
int AES_unwrap_key(AES_KEY *key, const unsigned char *iv,
                   unsigned char *out,const unsigned char *in, unsigned int inlen);


```

