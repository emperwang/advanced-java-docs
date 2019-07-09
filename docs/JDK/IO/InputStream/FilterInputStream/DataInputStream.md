# DataInputStream

## Field

```java
    private byte bytearr[] = new byte[80];
    private char chararr[] = new char[80];
	// 读取long类型数据时使用,缓存8个byte数据
    private byte readBuffer[] = new byte[8];
    private char lineBuffer[];
```


## 构造函数

```java
    public DataInputStream(InputStream in) {
        super(in); // 指定输入流
    }
```


## 功能函数

### read

#### read byte array

```java
    // 此实现都是依赖输入流
	public final int read(byte b[]) throws IOException {
        return in.read(b, 0, b.length);
    }

    public final int read(byte b[], int off, int len) throws IOException {
        return in.read(b, off, len);
    }
```


#### readFully

```java
    public final void readFully(byte b[]) throws IOException {
        readFully(b, 0, b.length);
    }

    public final void readFully(byte b[], int off, int len) throws IOException {
        if (len < 0)
            throw new IndexOutOfBoundsException();
        int n = 0;
        while (n < len) { // 循环从输入流中读取数据到b中
            int count = in.read(b, off + n, len - n);
            if (count < 0)
                throw new EOFException();
            n += count;
        }
    }
```
#### readByte

```java
    public final byte readByte() throws IOException {
        // 从输入流中读取一个数据
        int ch = in.read();
        if (ch < 0)
            throw new EOFException();
        // 强转为byte类型
        return (byte)(ch);
    }
```
#### readBoolean

```java
    public final boolean readBoolean() throws IOException {
        int ch = in.read();
        if (ch < 0)
            throw new EOFException();
        // 大于0为true，小于0为false
        return (ch != 0);
    }
```


#### readChar

```java
    public final char readChar() throws IOException {
        int ch1 = in.read();
        int ch2 = in.read();
        if ((ch1 | ch2) < 0)
            throw new EOFException();
        // char是两个byte
        return (char)((ch1 << 8) + (ch2 << 0));
    }
```
#### readInt

```java
    public final int readInt() throws IOException {
        int ch1 = in.read();
        int ch2 = in.read();
        int ch3 = in.read();
        int ch4 = in.read();
        if ((ch1 | ch2 | ch3 | ch4) < 0)
            throw new EOFException();
        // int是4个byte
        return ((ch1 << 24) + (ch2 << 16) + (ch3 << 8) + (ch4 << 0));
    }
```
#### readLong
```java
    public final long readLong() throws IOException {
        // long是8个byte
        readFully(readBuffer, 0, 8);
        return (((long)readBuffer[0] << 56) +
                ((long)(readBuffer[1] & 255) << 48) +
                ((long)(readBuffer[2] & 255) << 40) +
                ((long)(readBuffer[3] & 255) << 32) +
                ((long)(readBuffer[4] & 255) << 24) +
                ((readBuffer[5] & 255) << 16) +
                ((readBuffer[6] & 255) <<  8) +
                ((readBuffer[7] & 255) <<  0));
    }
```
#### readUTF

```java
    public final String readUTF() throws IOException {
        return readUTF(this);
    }


    public final static String readUTF(DataInput in) throws IOException {
        // utflen是一个无符号short的长度
        int utflen = in.readUnsignedShort();
        byte[] bytearr = null;
        char[] chararr = null;
        if (in instanceof DataInputStream) {
            DataInputStream dis = (DataInputStream)in;
            if (dis.bytearr.length < utflen){
                dis.bytearr = new byte[utflen*2];
                dis.chararr = new char[utflen*2];
            }
            chararr = dis.chararr;
            bytearr = dis.bytearr;
        } else {
            bytearr = new byte[utflen];
            chararr = new char[utflen];
        }

        int c, char2, char3;
        int count = 0;
        int chararr_count=0;
		// 读取utflen个数据到bytearr中
        in.readFully(bytearr, 0, utflen);
		// 把bytearr中的数据转换为char存储到chararr中
        while (count < utflen) {
            c = (int) bytearr[count] & 0xff;
            if (c > 127) break;
            count++;
            chararr[chararr_count++]=(char)c;
        }
		// 根据bytearr中存储的数据类型,进行转换存放到chararr中
        while (count < utflen) {
            c = (int) bytearr[count] & 0xff;
            switch (c >> 4) {
                case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
                    /* 0xxxxxxx*/
                    count++;
                    chararr[chararr_count++]=(char)c;
                    break;
                case 12: case 13:
                    /* 110x xxxx   10xx xxxx*/
                    count += 2;
                    if (count > utflen)
                        throw new UTFDataFormatException(
                            "malformed input: partial character at end");
                    char2 = (int) bytearr[count-1];
                    if ((char2 & 0xC0) != 0x80)
                        throw new UTFDataFormatException(
                            "malformed input around byte " + count);
                    chararr[chararr_count++]=(char)(((c & 0x1F) << 6) |
                                                    (char2 & 0x3F));
                    break;
                case 14:
                    /* 1110 xxxx  10xx xxxx  10xx xxxx */
                    count += 3;
                    if (count > utflen)
                        throw new UTFDataFormatException(
                            "malformed input: partial character at end");
                    char2 = (int) bytearr[count-2];
                    char3 = (int) bytearr[count-1];
                    if (((char2 & 0xC0) != 0x80) || ((char3 & 0xC0) != 0x80))
                        throw new UTFDataFormatException(
                            "malformed input around byte " + (count-1));
                    chararr[chararr_count++]=(char)(((c     & 0x0F) << 12) |
                                                    ((char2 & 0x3F) << 6)  |
                                                    ((char3 & 0x3F) << 0));
                    break;
                default:
                    /* 10xx xxxx,  1111 xxxx */
                    throw new UTFDataFormatException(
                        "malformed input around byte " + count);
            }
        }
        // The number of chars produced may be less than utflen
        // 把chararr中的数据转换为string类型
        return new String(chararr, 0, chararr_count);
    }
```


### skipBytes

```java
    public final int skipBytes(int n) throws IOException {
        int total = 0;
        int cur = 0;
		// 让输入流跳过n个元素
        while ((total<n) && ((cur = (int) in.skip(n-total)) > 0)) {
            total += cur;
        }

        return total;
    }
```

