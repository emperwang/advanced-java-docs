# Object

## 功能函数

静态初始化代码:

```java
private static native void registerNatives();
static {
    registerNatives();
}
```



### getClass

```java
public final native Class<?> getClass();
```



### hashCode

```java
public native int hashCode();
```



### equals

```java
public boolean equals(Object obj) {
        return (this == obj);
    }
```

### clone

```java
protected native Object clone() throws CloneNotSupportedException;
```



### toString

```java
    public String toString() {
        return getClass().getName() + "@" + Integer.toHexString(hashCode());
    }
```



### notify

```java
public final native void notify();
```



### notifyAll

```java
public final native void notifyAll();
```



### wait

```java
public final native void wait(long timeout) throws InterruptedException;

public final void wait(long timeout, int nanos) throws InterruptedException {
    if (timeout < 0) {
        throw new IllegalArgumentException("timeout value is negative");
    }
    if (nanos < 0 || nanos > 999999) {
        throw new IllegalArgumentException(
            "nanosecond timeout value out of range");
    }
    if (nanos > 0) {
        timeout++;
    }
    wait(timeout);
}


public final void wait() throws InterruptedException {
    wait(0);
}

```



### finalize

```java
protected void finalize() throws Throwable { }
```

