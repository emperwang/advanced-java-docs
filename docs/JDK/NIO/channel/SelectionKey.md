# SelectionKey

javaDoc介绍:

```java
/* A token representing the registration of a SelectableChannel with a
 * A selection key is created each time a channel is registered with a
 * selector.  A key remains valid until it is <i>cancelled</i> by invoking its
 * cancel cancel method, by closing its channel, or by closing its
 * selector.  Cancelling a key does not immediately remove it from its
 * selector; it is instead added to the selector's <a
 * href="Selector.html#ks"><i>cancelled-key set</i></a> for removal during the
 * next selection operation.  The validity of a key may be tested by invoking
 * its {@link #isValid isValid} method. */
```

## Field

```java
/** Operation-set bit for read operations.  */
public static final int OP_READ = 1 << 0;

/** Operation-set bit for write operations. */
public static final int OP_WRITE = 1 << 2;

/** Operation-set bit for socket-connect operations. */
public static final int OP_CONNECT = 1 << 3;

/**Operation-set bit for socket-accept operations.  */
public static final int OP_ACCEPT = 1 << 4;

private volatile Object attachment = null;
// 原子更新
private static final AtomicReferenceFieldUpdater<SelectionKey,Object>
        attachmentUpdater = AtomicReferenceFieldUpdater.newUpdater(
    SelectionKey.class, Object.class, "attachment"
);
```



## 构造器

```java
protected SelectionKey() { }
```



## 功能函数

```java

    /**
     * Returns the channel for which this key was created.  This method will
     * continue to return the channel even after the key is cancelled. */		    
	public abstract SelectableChannel channel();

    /**
     * Returns the selector for which this key was created.  This method will
     * continue to return the selector even after the key is cancelled. */
    public abstract Selector selector();

    /**
     * Tells whether or not this key is valid.*/
    public abstract boolean isValid();

    public abstract void cancel();

    /**
     * Retrieves this key's interest set.*/
    public abstract int interestOps();

    /**
     * Sets this key's interest set to the given value. */
    public abstract SelectionKey interestOps(int ops);

    /**
     * Retrieves this key's ready-operation set.*/
    public abstract int readyOps();

    public final Object attach(Object ob) {
        return attachmentUpdater.getAndSet(this, ob);
    }
```

