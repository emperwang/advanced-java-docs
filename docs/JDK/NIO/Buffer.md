# Buffer

## Field

```java
static final int SPLITERATOR_CHARACTERISTICS =
    Spliterator.SIZED | Spliterator.SUBSIZED | Spliterator.ORDERED;

// Invariants: mark <= position <= limit <= capacity
private int mark = -1;  // 标记的位置
private int position = 0; // 元素的位置
private int limit;  //  元素的个数
private int capacity; // 容量

// Used only by direct buffers
// NOTE: hoisted here for speed in JNI GetDirectBufferAddress
long address;
```



## 构造器

```java
Buffer(int mark, int pos, int lim, int cap) {       // package-private
    if (cap < 0)
        throw new IllegalArgumentException("Negative capacity: " + cap);
    this.capacity = cap;
    limit(lim);
    position(pos);
    if (mark >= 0) {
        if (mark > pos)
            throw new IllegalArgumentException("mark > position: ("
                                               + mark + " > " + pos + ")");
        this.mark = mark;
    }
}
```

## 功能函数

### position

```java
// 设置position位置
public final Buffer position(int newPosition) {
    if ((newPosition > limit) || (newPosition < 0))
        throw new IllegalArgumentException();
    position = newPosition;
    if (mark > position) mark = -1;
    return this;
}
```

### limit

```java
// 设置limit参数
public final Buffer limit(int newLimit) {
    if ((newLimit > capacity) || (newLimit < 0))
        throw new IllegalArgumentException();
    limit = newLimit;
    if (position > limit) position = limit;
    if (mark > limit) mark = -1;
    return this;
}
```

### mark

```java
// 标记
public final Buffer mark() {
    mark = position;
    return this;
}

// 恢复到mark的位置
public final Buffer reset() {
    int m = mark;
    if (m < 0)
        throw new InvalidMarkException();
    position = m;
    return this;
}
// 清空
public final Buffer clear() {
    position = 0;
    limit = capacity;
    mark = -1;
    return this;
}
// 也就是把limit设置到有效数据位置
public final Buffer flip() {
    limit = position;
    position = 0;
    mark = -1;
    return this;
}

// 复位position位置,以及丢弃标记的值
public final Buffer rewind() {
    position = 0;
    mark = -1;
    return this;
}

// 下一个索引的位置
final int nextGetIndex() {                          // package-private
    if (position >= limit)
        throw new BufferUnderflowException();
    return position++;
}

final int nextGetIndex(int nb) {                    // package-private
    if (limit - position < nb)
        throw new BufferUnderflowException();
    int p = position;
    position += nb;
    return p;
}

// 截断
final void truncate() {                             // package-private
    mark = -1;
    position = 0;
    limit = 0;
    capacity = 0;
}

// 丢弃mark的值
final void discardMark() {                          // package-private
    mark = -1;
}
```

