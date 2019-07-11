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

