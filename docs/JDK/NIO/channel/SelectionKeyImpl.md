# SelectionKeyImpl

## Field

```java
final SelChImpl channel;
public final SelectorImpl selector;
private int index;
private volatile int interestOps;
private int readyOps;
```



## 构造方法

```java
SelectionKeyImpl(SelChImpl var1, SelectorImpl var2) {
    this.channel = var1;
    this.selector = var2;
}
```



## 功能函数

### channel

```java
public SelectableChannel channel() {
    return (SelectableChannel)this.channel;
}
```


### selector

```java
public Selector selector() {
    return this.selector;
}
```


### getIndex

```java
int getIndex() {
    return this.index;
}
```


### setIndex

```java
void setIndex(int var1) {
    this.index = var1;
}
```


### interestOps

```java
public int interestOps() {
    this.ensureValid();
    return this.interestOps;
}

public SelectionKey interestOps(int var1) {
    this.ensureValid();
    return this.nioInterestOps(var1);
}

public SelectionKey nioInterestOps(int var1) {
    if ((var1 & ~this.channel().validOps()) != 0) {
        throw new IllegalArgumentException();
    } else {
        this.channel.translateAndSetInterestOps(var1, this);
        this.interestOps = var1;
        return this;
    }
}
```


### readyOps

```java
public int readyOps() {
    this.ensureValid();
    return this.readyOps;
}

public void nioReadyOps(int var1) {
    this.readyOps = var1;
}

public int nioReadyOps() {
    return this.readyOps;
}

public SelectionKey nioInterestOps(int var1) {
    if ((var1 & ~this.channel().validOps()) != 0) {
        throw new IllegalArgumentException();
    } else {
        this.channel.translateAndSetInterestOps(var1, this);
        this.interestOps = var1;
        return this;
    }
}
```

