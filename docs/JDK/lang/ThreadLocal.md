# ThreadLocal

## Field

```java
private final int threadLocalHashCode = nextHashCode();
private static AtomicInteger nextHashCode = new AtomicInteger();
private static final int HASH_INCREMENT = 0x61c88647;
```



## 构造函数

```java
public ThreadLocal() {
}
```



## 功能函数

### nextHashCode

```java
private static int nextHashCode() {
    return nextHashCode.getAndAdd(HASH_INCREMENT);
}
```



### initialValue

```java
protected T initialValue() {
    return null;
}
```

### withInitial

```java
    public static <S> ThreadLocal<S> withInitial(Supplier<? extends S> supplier) {
        return new SuppliedThreadLocal<>(supplier);
    }
```



### get
```java
public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
}


ThreadLocalMap getMap(Thread t) {
    return t.threadLocals;
}
```


### setInitialValue
```java
private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
}
```


### set
```java
public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}
```


### remove
```java
public void remove() {
    ThreadLocalMap m = getMap(Thread.currentThread());
    if (m != null)
        m.remove(this);
}
```


### getMap
```java
ThreadLocalMap getMap(Thread t) {
    return t.threadLocals;
}
```


### createMap
```java
void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
}
```


### createInheritedMap
```java
static ThreadLocalMap createInheritedMap(ThreadLocalMap parentMap) {
    return new ThreadLocalMap(parentMap);
}
```


### childValue
```java
T childValue(T parentValue) {
    throw new UnsupportedOperationException();
}
```



## 内部类

### ThreadLocalMap

#### Field

```java
        /**
         * The initial capacity -- MUST be a power of two.
         */
        private static final int INITIAL_CAPACITY = 16;

        /**
         * The table, resized as necessary.
         * table.length MUST always be a power of two.
         */
        private Entry[] table;

        /**
         * The number of entries in the table.
         */
        private int size = 0;

        /**
         * The next size value at which to resize.
         */
        private int threshold; // Default to 0
```

内部类,也是存储结构:

```java
static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;

    Entry(ThreadLocal<?> k, Object v) {
        super(k);
        value = v;
    }
}
```

#### 构造函数

```java
ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    // 存储数组的初始化---也就是会在使用时才会初始化
    table = new Entry[INITIAL_CAPACITY];
    // 要存储的index位置
    int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
    // 构建entry,然后存储进数组中
    table[i] = new Entry(firstKey, firstValue);
    size = 1;
    // 设置阈值
    setThreshold(INITIAL_CAPACITY);
}

private ThreadLocalMap(ThreadLocalMap parentMap) {
    // 获取参数的table数组
    Entry[] parentTable = parentMap.table;
    // 获取长度
    int len = parentTable.length;
    // 设置阈值  
    setThreshold(len);
    // 初始化数组
    table = new Entry[len];

    for (int j = 0; j < len; j++) {
        // 遍历参数数组
        Entry e = parentTable[j];
        if (e != null) {
            @SuppressWarnings("unchecked")
            // 获取e的threadLocal和value值
            ThreadLocal<Object> key = (ThreadLocal<Object>) e.get();
            if (key != null) {
                Object value = key.childValue(e.value);
                // 把获取到的值封装到Entry中
                Entry c = new Entry(key, value);
                // 获取存放的索引位置
                int h = key.threadLocalHashCode & (len - 1);
                // 如果对应的位置有值
                while (table[h] != null)
                    // 重新查到一个位置
                    h = nextIndex(h, len);
                // 放入数组
                table[h] = c;
                size++;
            }
        }
    }
}


private static int nextIndex(int i, int len) {
    return ((i + 1 < len) ? i + 1 : 0);
}
```



#### 功能函数

getEntry

```java
private Entry getEntry(ThreadLocal<?> key) {
    // 获取对应的存储位置
    int i = key.threadLocalHashCode & (table.length - 1);
    // 得到位置上的值
    Entry e = table[i];
    // 相等就返回
    if (e != null && e.get() == key)
        return e;
    else // 不等,就再找一下
        return getEntryAfterMiss(key, i, e);
}
```



getEntryAfterMiss

```java
private Entry getEntryAfterMiss(ThreadLocal<?> key, int i, Entry e) {
    // 获取存储数组及其长度
    Entry[] tab = table;
    int len = tab.length;

    while (e != null) {
        // 获取threadLocal
        ThreadLocal<?> k = e.get();
        // 相等则返回
        if (k == key)
            return e;
        // 为null,则进行一下reHash
        if (k == null)
            expungeStaleEntry(i);
        else // 查找下一个位置
            i = nextIndex(i, len);
        e = tab[i];
    }
    return null;
}


// 清除操作,也就是把staleslot位置上的值清除
private int expungeStaleEntry(int staleSlot) {
    // 获取原数组和长度
    Entry[] tab = table;
    int len = tab.length;

    // expunge entry at staleSlot
    // 清除staleSlot对应的值
    tab[staleSlot].value = null;
    tab[staleSlot] = null;
    size--;

    // Rehash until we encounter null
    Entry e;
    int i;
    // reHash操作
    for (i = nextIndex(staleSlot, len);
         (e = tab[i]) != null;
         i = nextIndex(i, len)) {
        ThreadLocal<?> k = e.get();
        // 如果位置上为null,则清除
        if (k == null) {
            e.value = null;
            tab[i] = null;
            size--;
        } else { // 位置上存在值,则进行添加操作
            int h = k.threadLocalHashCode & (len - 1);
            if (h != i) {
                tab[i] = null;
                // Unlike Knuth 6.4 Algorithm R, we must scan until
                // null because multiple entries could have been stale.
                // 存放操作
                while (tab[h] != null)
                    h = nextIndex(h, len);
                tab[h] = e;
            }
        }
    }
    return i;
}
```

set

```java
private void set(ThreadLocal<?> key, Object value) {
	// 获取数组和长度
    Entry[] tab = table;
    int len = tab.length;
    // 计算要存储的位置
    int i = key.threadLocalHashCode & (len-1);
	// 遍历数组进行存储操作
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();

        if (k == key) { // 赋值操作
            e.value = value;
            return;
        }

        if (k == null) {// 对应位置为空
            replaceStaleEntry(key, value, i);
            return;
        }
    }
	// 对应位置没有元素,则直接添加
    tab[i] = new Entry(key, value);
    int sz = ++size;
    // 没有可清除的.并且长度大于阈值;则进行扩容操作
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
}
```



remove

```java
private void remove(ThreadLocal<?> key) {
    Entry[] tab = table;
    int len = tab.length;
    int i = key.threadLocalHashCode & (len-1);
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        if (e.get() == key) { // 找到了,则进行清除操作
            e.clear();
            expungeStaleEntry(i); // 并从数组中删除
            return;
        }
    }
}
```

replaceStaleEntry

```java
private void replaceStaleEntry(ThreadLocal<?> key, Object value,
                               int staleSlot) {
    // 获取数组
    Entry[] tab = table;
    int len = tab.length;
    Entry e;

    int slotToExpunge = staleSlot;
    for (int i = prevIndex(staleSlot, len);
         (e = tab[i]) != null;
         i = prevIndex(i, len))
        if (e.get() == null)
            slotToExpunge = i;

    for (int i = nextIndex(staleSlot, len);
         (e = tab[i]) != null;
         i = nextIndex(i, len)) {
        ThreadLocal<?> k = e.get();


        if (k == key) { // 如果key已经存在
            e.value = value; // 覆盖值

            tab[i] = tab[staleSlot]; // 更新引用
            tab[staleSlot] = e;

            if (slotToExpunge == staleSlot)
                slotToExpunge = i;
            cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
            return;
        }

        if (k == null && slotToExpunge == staleSlot)
            slotToExpunge = i;
    }

    // If key not found, put new entry in stale slot
    tab[staleSlot].value = null;
    tab[staleSlot] = new Entry(key, value);

    // If there are any other stale entries in run, expunge them
    if (slotToExpunge != staleSlot)
        cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
}


private static int prevIndex(int i, int len) {
    return ((i - 1 >= 0) ? i - 1 : len - 1);
}
```

cleanSomeSlots

```java
private boolean cleanSomeSlots(int i, int n) {
    boolean removed = false;
    Entry[] tab = table;
    int len = tab.length;
    // 循环进行清除操作
    do {
        i = nextIndex(i, len);
        Entry e = tab[i];
        if (e != null && e.get() == null) {
            n = len;
            removed = true;
            i = expungeStaleEntry(i);
        }
    } while ( (n >>>= 1) != 0);
    return removed;
}
```

rehash

```java
private void rehash() {
    // 先进行一下清除操作
    expungeStaleEntries();
    // Use lower threshold for doubling to avoid hysteresis
    // 超过阈值,则进行扩容
    if (size >= threshold - threshold / 4)
        resize();
}

// 扩容操作
private void resize() {
    // 获取原来的数组以及长度
    Entry[] oldTab = table;
    int oldLen = oldTab.length;
    // 设置新长度,也就是原来的2倍
    int newLen = oldLen * 2;
    // 创建新数组
    Entry[] newTab = new Entry[newLen];
    int count = 0;
	// 遍历原来数组,把数组内容拷贝到新数组中
    for (int j = 0; j < oldLen; ++j) {
        Entry e = oldTab[j];
        if (e != null) {
            ThreadLocal<?> k = e.get();
            if (k == null) {
                e.value = null; // Help the GC
            } else {
                int h = k.threadLocalHashCode & (newLen - 1);
                while (newTab[h] != null)
                    h = nextIndex(h, newLen);
                newTab[h] = e;
                count++;
            }
        }
    }
	// 设置新阈值,并更新总数和数组引用
    setThreshold(newLen);
    size = count;
    table = newTab;
}
```



### SuppliedThreadLocal



