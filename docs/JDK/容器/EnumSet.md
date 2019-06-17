# EnumSet

使用示例:

```java
enum Season {
    SPRING, SUMMER, FALL, WINTER
}

public class EnumSetTest {
    public static void main(String[] args) {
        //创建一个EnumSet集合，集合元素就是Season枚举类的全部枚举值
        EnumSet es1 = EnumSet.allOf(Season.class);
        //输出[SPRING, SUMMER, FALL, WINTER]
        System.out.println(es1);
        //创建一个EnumSet空集合，指定其集合元素是Season类的枚举值
        EnumSet es2 = EnumSet.noneOf(Season.class);
        //输出[]
        System.out.println(es2);
        //手动添加两个元素
        es2.add(Season.WINTER);
        es2.add(Season.SPRING);
        //输出[Spring, WINTER]
        System.out.println(es2);
        //以指定枚举值创建EnumSet集合
        EnumSet es3 = EnumSet.of(Season.SUMMER, Season.WINTER);
        //输出[SUMMER, WINTER]
        System.out.println(es3);
　　　　　//创建一个包含两个枚举值范围内所有枚举值的EnumSet集合
        EnumSet es4 = EnumSet.range(Season.SUMMER, Season.WINTER);
        //输出[SUMMER, FALL, WINTER]s
        System.out.println(es4);
        //新创建的EnumSet集合元素和es4集合元素有相同的类型
        //es5集合元素 + es4集合元素=Season枚举类的全部枚举值
        EnumSet es5 = EnumSet.complementOf(es4);
        System.out.println(es5);
        //创建一个集合
        Collection c = new HashSet();
        c.clear();
        c.add(Season.SPRING);
        c.add(Season.WINTER);
        //复制Collection集合中的所有元素来创建EnumSet集合
        EnumSet es = EnumSet.copyOf(c);
        //输出es
        System.out.println(es);
        c.add("111");
        c.add("222");
        //下面代码出现异常，因为c集合里的元素不是全部都为枚举值
        es = EnumSet.copyOf(c);
    }
}
```

可以看到EnumSet是一个抽象类，故平时使用的应该是其的子类。

有两个子类：

```java
// 元素多于64个时的实现类
class JumboEnumSet<E extends Enum<E>> extends EnumSet<E> {
}
// 元素小于等于64时的实现类
class RegularEnumSet<E extends Enum<E>> extends EnumSet<E> {
}
```



## Field

```java
	// 存储的数据的类型
    final Class<E> elementType;
	// key值
    final Enum<?>[] universe;

    private static Enum<?>[] ZERO_LENGTH_ENUM_ARRAY = new Enum<?>[0];
```



## 创建方法

这里就按照示例程序中的使用来查看把。

```java
    public static <E extends Enum<E>> EnumSet<E> allOf(Class<E> elementType) {
        // 根据类型创建一个实例对象
        EnumSet<E> result = noneOf(elementType);
        // 并把枚举中的所有实例添加进来
        result.addAll();
        return result;
    }

    public static <E extends Enum<E>> EnumSet<E> of(E first, E... rest) {
        // 同样是先创建实例，然后添加参数中的枚举实例
        EnumSet<E> result = noneOf(first.getDeclaringClass());
        result.add(first);
        for (E e : rest)
            result.add(e);
        return result;
    }
    public static <E extends Enum<E>> EnumSet<E> range(E from, E to) {
        if (from.compareTo(to) > 0)
            throw new IllegalArgumentException(from + " > " + to);
        // 创建实例，添加参数中的枚举实例
        EnumSet<E> result = noneOf(from.getDeclaringClass());
        result.addRange(from, to);
        return result;
    }
```

看来都是调用这个noneOf函数来创建一个实例对象，那来看一下这个函数:

```java
   // 创建实例对象
	public static <E extends Enum<E>> EnumSet<E> noneOf(Class<E> elementType) {
        // 获取枚举类的实例的个数
        Enum<?>[] universe = getUniverse(elementType);  // 获取到枚举实例类型的数组(包含了枚举类型的所有实例)
        if (universe == null)
            throw new ClassCastException(elementType + " not an enum");

        if (universe.length <= 64)
            // 小于64，则使用此子类
            return new RegularEnumSet<>(elementType, universe);
        else
            // 否则使用此子类
            return new JumboEnumSet<>(elementType, universe);
    }
```

### 子类实现

看一下两个子类的实现把:

#### EnumSet

```java
    // EnumSet的构造函数，保存key类型和 key的数组
	EnumSet(Class<E>elementType, Enum<?>[] universe) {
        this.elementType = elementType;
        this.universe    = universe;
    }
```



#### RegularEnumSet

```java
    // 类型 和 key的数组环视保存在父类field中
	RegularEnumSet(Class<E>elementType, Enum<?>[] universe) {
        super(elementType, universe);
    }
```

#### JumboEnumSet

```java
    // 类型和枚举实例数组保存在父类中， 并且创建一个实例化elements数组
	JumboEnumSet(Class<E>elementType, Enum<?>[] universe) {
        super(elementType, universe);
        elements = new long[(universe.length + 63) >>> 6];
    }

    /**
     * Bit vector representation of this set.  The ith bit of the jth
     * element of this array represents the  presence of universe[64*j +i]
     * in this set.
     */
    private long elements[];
```

可以看到，都会调用父类EnumSet的构造函数，并把枚举类型和key数组赋值给父类EnumSet的Field。



## 添加元素

### 添加所有
#### RegularEnumSet

```java
    /** elements和universe的对应关系
     * Bit vector representation of this set.  The 2^k bit indicates the
     * presence of universe[k] in this set.
     */
    private long elements = 0L;
	void addAll() { // elements中相关的置1
        if (universe.length != 0)
            elements = -1L >>> -universe.length;
    }
```



#### JumboEnumSet

```java
    /**
     * Bit vector representation of this set.  The ith bit of the jth
     * element of this array represents the  presence of universe[64*j +i]
     * in this set.
     */
    private long elements[];
	void addAll() {  // 相应的也是对应的位置置为1
        for (int i = 0; i < elements.length; i++)
            elements[i] = -1;
        elements[elements.length - 1] >>>= -universe.length;
        size = universe.length;
    }
```



### 添加一个范围的元素
#### RegularEnumSet

```java
    void addRange(E from, E to) {
        elements = (-1L >>>  (from.ordinal() - to.ordinal() - 1)) << from.ordinal();
    }
```



#### JumboEnumSet

```java
    void addRange(E from, E to) {
        int fromIndex = from.ordinal() >>> 6;
        int toIndex = to.ordinal() >>> 6;

        if (fromIndex == toIndex) {
            elements[fromIndex] = (-1L >>>  (from.ordinal() - to.ordinal() - 1))
                            << from.ordinal();
        } else {
            elements[fromIndex] = (-1L << from.ordinal());
            for (int i = fromIndex + 1; i < toIndex; i++)
                elements[i] = -1;
            elements[toIndex] = -1L >>> (63 - to.ordinal());
        }
        size = to.ordinal() - from.ordinal() + 1;
    }
```



### 创建一个相同类型的EnumSet，并包含此类型的所有元素

```java
   public static <E extends Enum<E>> EnumSet<E> complementOf(EnumSet<E> s) {
        EnumSet<E> result = copyOf(s);
        result.complement();
        return result;
    }
	// 直接进行复制
    public static <E extends Enum<E>> EnumSet<E> copyOf(EnumSet<E> s) {
        return s.clone();
    }
	// 添加一个其他容器的值到此EnumSet中
    public static <E extends Enum<E>> EnumSet<E> copyOf(Collection<E> c) {
        if (c instanceof EnumSet) {
            // 直接复制
            return ((EnumSet<E>)c).clone();
        } else {
            if (c.isEmpty())
                throw new IllegalArgumentException("Collection is empty");
            Iterator<E> i = c.iterator();
            E first = i.next();
            // 创建容器
            EnumSet<E> result = EnumSet.of(first);
            // 遍历参数集合，添加到新创建的EnumSet中
            while (i.hasNext())
                result.add(i.next());
            return result;
        }
    }
```



#### RegularEnumSet

```java
    void complement() { // 所有元素的对应的bit位，置位
        if (universe.length != 0) {
            elements = ~elements;
            elements &= -1L >>> -universe.length;  // Mask unused bits
        }
    }
```



#### JumboEnumSet

```java
    void complement() {
        for (int i = 0; i < elements.length; i++)
            elements[i] = ~elements[i];
        elements[elements.length - 1] &= (-1L >>> -universe.length);
        size = universe.length - size;
    }
```

可以看到上面的操作都是位运算，为什么呢？

简单点说：universe存储了枚举中的所有实例，elements表示当前的EnumSet存储了哪些实例(相当于elements就是有效数据的索引).

## 容器遍历
### JumboEnumSet

```java
    public Iterator<E> iterator() {
        return new EnumSetIterator<>();
    }
	// 实现遍历的内部类
    private class EnumSetIterator<E extends Enum<E>> implements Iterator<E> {
        /**
         * A bit vector representing the elements in the current "word"
         * of the set not yet returned by this iterator.
         */
        long unseen;

        /**
         * The index corresponding to unseen in the elements array.
         */
        int unseenIndex = 0;

        /**
         * The bit representing the last element returned by this iterator
         * but not removed, or zero if no such element exists.
         */
        long lastReturned = 0;

        /**
         * The index corresponding to lastReturned in the elements array.
         */
        int lastReturnedIndex = 0;

        EnumSetIterator() {
            unseen = elements[0];
        }

        @Override
        public boolean hasNext() {
            while (unseen == 0 && unseenIndex < elements.length - 1)
                unseen = elements[++unseenIndex];
            return unseen != 0;
        }

        @Override
        @SuppressWarnings("unchecked")
        public E next() {
            if (!hasNext())
                throw new NoSuchElementException();
            lastReturned = unseen & -unseen;
            lastReturnedIndex = unseenIndex;
            unseen -= lastReturned;
            return (E) universe[(lastReturnedIndex << 6)
                                + Long.numberOfTrailingZeros(lastReturned)];
        }

        @Override
        public void remove() {
            if (lastReturned == 0)
                throw new IllegalStateException();
            final long oldElements = elements[lastReturnedIndex];
            elements[lastReturnedIndex] &= ~lastReturned;
            if (oldElements != elements[lastReturnedIndex]) {
                size--;
            }
            lastReturned = 0;
        }
    }
```



### RegularEnumSet

```java
    public Iterator<E> iterator() {
        return new EnumSetIterator<>();
    }
	// 实现遍历功能的内部类
    private class EnumSetIterator<E extends Enum<E>> implements Iterator<E> {
		// 标识有效元素的位置
        long unseen;
		// 上次返回的元素的位置
        long lastReturned = 0;

        EnumSetIterator() {
            unseen = elements; // 记录此集合中的有效元素的位置
        }
		// 判断是否有下一个元素
        public boolean hasNext() {
            return unseen != 0;
        }

        @SuppressWarnings("unchecked")
        // 下一个元素
        public E next() {
            if (unseen == 0)
                throw new NoSuchElementException();
            lastReturned = unseen & -unseen;
            unseen -= lastReturned;
            return (E) universe[Long.numberOfTrailingZeros(lastReturned)];
        }
		// 删除元素
        public void remove() {
            if (lastReturned == 0)
                throw new IllegalStateException();
            elements &= ~lastReturned;
            lastReturned = 0;
        }
    }
```



