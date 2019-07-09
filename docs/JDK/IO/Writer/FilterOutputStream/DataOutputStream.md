# DataOuputStream

## Field
```java
    // 已经写完的数据数
	protected int written;
	// bytearr 是writeUTF使用
    private byte[] bytearr = null;
	// 在writeLong时使用
    private byte writeBuffer[] = new byte[8];
```


## 构造函数
```java
    public DataOutputStream(OutputStream out) {
        super(out);
    }
```


## 功能函数

### incCount
```java
    // 就是更新written的值
	private void incCount(int value) {
        int temp = written + value;
        if (temp < 0) {
            temp = Integer.MAX_VALUE;
        }
        written = temp;
    }
```


### write

#### write char
```java
    public synchronized void write(int b) throws IOException {
        out.write(b);  // 通过输出流写入一个byte
        incCount(1);
    }
```
#### wite byte array
```java
    public synchronized void write(byte b[], int off, int len)
        throws IOException
    {
        out.write(b, off, len);  // 写入数组
        incCount(len);
    }
```
### writeByte
```java
    public final void writeByte(int v) throws IOException {
        out.write(v);
        incCount(1);
    }
```
### writeShort
```java
    public final void writeShort(int v) throws IOException {
        out.write((v >>> 8) & 0xFF);
        out.write((v >>> 0) & 0xFF);
        incCount(2);
    }
```
### writeChar
```java
    public final void writeChar(int v) throws IOException {
        out.write((v >>> 8) & 0xFF);
        out.write((v >>> 0) & 0xFF);
        incCount(2);
    }
```


### writeInt
```java
    public final void writeInt(int v) throws IOException {
        out.write((v >>> 24) & 0xFF);
        out.write((v >>> 16) & 0xFF);
        out.write((v >>>  8) & 0xFF);
        out.write((v >>>  0) & 0xFF);
        incCount(4);
    }
```


### writeLong
```java
    public final void writeLong(long v) throws IOException {
        writeBuffer[0] = (byte)(v >>> 56);
        writeBuffer[1] = (byte)(v >>> 48);
        writeBuffer[2] = (byte)(v >>> 40);
        writeBuffer[3] = (byte)(v >>> 32);
        writeBuffer[4] = (byte)(v >>> 24);
        writeBuffer[5] = (byte)(v >>> 16);
        writeBuffer[6] = (byte)(v >>>  8);
        writeBuffer[7] = (byte)(v >>>  0);
        out.write(writeBuffer, 0, 8);
        incCount(8);
    }
```


### witeBytes
```java
    public final void writeBytes(String s) throws IOException {
        int len = s.length();
        // 循环把字符串写入
        for (int i = 0 ; i < len ; i++) {
            out.write((byte)s.charAt(i));
        }
        incCount(len);
    }
```


### writeUTF

```java
    static int writeUTF(String str, DataOutput out) throws IOException {
        int strlen = str.length();
        int utflen = 0;
        int c, count = 0;

        /* use charAt instead of copying String to char array */
        // 循环字符串得到其对ing的utflen的值
        for (int i = 0; i < strlen; i++) {
            c = str.charAt(i);
            if ((c >= 0x0001) && (c <= 0x007F)) {
                utflen++;
            } else if (c > 0x07FF) {
                utflen += 3;
            } else {
                utflen += 2;
            }
        }

        if (utflen > 65535)
            throw new UTFDataFormatException(
                "encoded string too long: " + utflen + " bytes");

        byte[] bytearr = null;
        if (out instanceof DataOutputStream) {
            DataOutputStream dos = (DataOutputStream)out;
            if(dos.bytearr == null || (dos.bytearr.length < (utflen+2)))
                // 新建一个数组,存储字符串转换为UTF后的值
                dos.bytearr = new byte[(utflen*2) + 2];
            bytearr = dos.bytearr;
        } else {
            bytearr = new byte[utflen+2];
        }
		// bytearr中最后两位表示str转换为utf后的长度值
        bytearr[count++] = (byte) ((utflen >>> 8) & 0xFF);
        bytearr[count++] = (byte) ((utflen >>> 0) & 0xFF);

        int i=0;
        // 循环str,把其中的值写入到bytearr中
        for (i=0; i<strlen; i++) {
           c = str.charAt(i);
           if (!((c >= 0x0001) && (c <= 0x007F))) break;
           bytearr[count++] = (byte) c;
        }
		// 再次修改其中的值; ----- 这块不清楚为什么要修改
        for (;i < strlen; i++){
            c = str.charAt(i);
            if ((c >= 0x0001) && (c <= 0x007F)) {
                bytearr[count++] = (byte) c;

            } else if (c > 0x07FF) {
                bytearr[count++] = (byte) (0xE0 | ((c >> 12) & 0x0F));
                bytearr[count++] = (byte) (0x80 | ((c >>  6) & 0x3F));
                bytearr[count++] = (byte) (0x80 | ((c >>  0) & 0x3F));
            } else {
                bytearr[count++] = (byte) (0xC0 | ((c >>  6) & 0x1F));
                bytearr[count++] = (byte) (0x80 | ((c >>  0) & 0x3F));
            }
        }
        // 把bytearr中的数据写入到输出流
        out.write(bytearr, 0, utflen+2);
        return utflen + 2;
    }
```

