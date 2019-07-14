# SelectorImpl

## Field

```java
protected Set<SelectionKey> selectedKeys = new HashSet();
protected HashSet<SelectionKey> keys = new HashSet();
private Set<SelectionKey> publicKeys;
private Set<SelectionKey> publicSelectedKeys;
```

## 构造函数

```java
protected SelectorImpl(SelectorProvider var1) {
    super(var1);
    if (Util.atBugLevel("1.4")) {
        this.publicKeys = this.keys;
        this.publicSelectedKeys = this.selectedKeys;
    } else {
        this.publicKeys = Collections.unmodifiableSet(this.keys);
        this.publicSelectedKeys = Util.ungrowableSet(this.selectedKeys);
    }
}
```

## 功能函数

### keys

```java
public Set<SelectionKey> keys() {
    if (!this.isOpen() && !Util.atBugLevel("1.4")) {
        throw new ClosedSelectorException();
    } else {
        return this.publicKeys;
    }
}
```



### selectedKeys

```java
public Set<SelectionKey> selectedKeys() {
    if (!this.isOpen() && !Util.atBugLevel("1.4")) {
        throw new ClosedSelectorException();
    } else {
        return this.publicSelectedKeys;
    }
}
```

### select

```java
public int select() throws IOException {
    return this.select(0L);
}

public int select(long var1) throws IOException {
    if (var1 < 0L) {
        throw new IllegalArgumentException("Negative timeout");
    } else {
        return this.lockAndDoSelect(var1 == 0L ? -1L : var1);
    }
}

private int lockAndDoSelect(long var1) throws IOException {
    synchronized(this) {
        if (!this.isOpen()) {
            throw new ClosedSelectorException();
        } else {
            Set var4 = this.publicKeys;
            int var10000;
            synchronized(this.publicKeys) {
                Set var5 = this.publicSelectedKeys;
                synchronized(this.publicSelectedKeys) {
                    // 轮训
                    var10000 = this.doSelect(var1);
                }
            }
            return var10000;
        }
    }
}

protected abstract int doSelect(long var1) throws IOException;


public int selectNow() throws IOException {
    return this.lockAndDoSelect(0L);
}
```

### close

```java
public void implCloseSelector() throws IOException {
    this.wakeup();
    synchronized(this) {
        Set var2 = this.publicKeys;
        synchronized(this.publicKeys) {
            Set var3 = this.publicSelectedKeys;
            synchronized(this.publicSelectedKeys) {
                this.implClose();
            }
        }

    }
}

protected abstract void implClose() throws IOException;
```

### putEventOps

```java
public void putEventOps(SelectionKeyImpl var1, int var2) {
}
```

### register

```java
protected final SelectionKey register(AbstractSelectableChannel var1, int var2, Object var3) {
    if (!(var1 instanceof SelChImpl)) {
        throw new IllegalSelectorException();
    } else {
        SelectionKeyImpl var4 = new SelectionKeyImpl((SelChImpl)var1, this);
        var4.attach(var3);
        Set var5 = this.publicKeys;
        synchronized(this.publicKeys) {
            this.implRegister(var4);
        }
        var4.interestOps(var2);
        return var4;
    }
}

protected abstract void implRegister(SelectionKeyImpl var1);

```

### processDeregisterQueue

```java
void processDeregisterQueue() throws IOException {
    Set var1 = this.cancelledKeys();
    synchronized(var1) {
        if (!var1.isEmpty()) {
            Iterator var3 = var1.iterator();
            // 遍历所有要取消的key，进行取消
            while(var3.hasNext()) {
                SelectionKeyImpl var4 = (SelectionKeyImpl)var3.next();
                try {
                    this.implDereg(var4);
                } catch (SocketException var11) {
                    throw new IOException("Error deregistering key", var11);
                } finally {
                    var3.remove();
                }
            }
        }

    }
}

protected abstract void implDereg(SelectionKeyImpl var1) throws IOException;
```

