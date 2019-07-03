# AtomicIntegerFieldUpdater

此类是个抽象类，有两个方法实现，AtomicIntegerFieldUpdaterImpl和UnsafeAtomicIntegerFieldUpdater。

在这里咱们分析一下AtomicIntegerFieldUpdaterImpl此子类的实现.

使用示例：

```java
public class AtomicIntegerFieldUpdaterTest {
     private static Class<Person> cls;
     /**
      * AtomicIntegerFieldUpdater说明
      * 基于反射的实用工具，可以对指定类的指定 volatile int 字段进行原子更新。此类用于原子数据结构，
      * 该结构中同一节点的几个字段都独立受原子更新控制。
      * 注意，此类中 compareAndSet 方法的保证弱于其他原子类中该方法的保证。
      * 因为此类不能确保所有使用的字段都适合于原子访问目的，所以对于相同更新器上的 compareAndSet 和 set 的		 * 其他调用,它仅可以保证原子性和可变语义。
      */
     public static void main(String[] args) {
        // 新建AtomicLongFieldUpdater对象，传递参数是“class对象”和“long类型在类中对应的名称”
        AtomicIntegerFieldUpdater<Person> mAtoLong = 		AtomicIntegerFieldUpdater.newUpdater(Person.class, "id");  // 原子更新id字段
        Person person = new Person(12345);
        mAtoLong.compareAndSet(person, 12345, 1000);
        System.out.println("id="+person.getId());
     }
}

class Person {
    volatile int id;
    public Person(int id) {
        this.id = id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getId() {
        return id;
    }
}
```



## Field

```java
	   // CAS操作
	   private static final sun.misc.Unsafe U = sun.misc.Unsafe.getUnsafe();
        private final long offset;
		// 如果要操作的field是受保护的,则此是caller的类
        private final Class<?> cclass;
        // 要操作的类
        private final Class<T> tclass;
```



## 构造函数

```java
    public static <U> AtomicIntegerFieldUpdater<U> newUpdater(Class<U> tclass,
                                                              String fieldName) {
        // 创建子类实现
        // tclass记录要操作的类
        // fieldName 要操作的字段
        return new AtomicIntegerFieldUpdaterImpl<U>
            (tclass, fieldName, Reflection.getCallerClass());
    }


    AtomicIntegerFieldUpdaterImpl(final Class<T> tclass,
                                  final String fieldName,
                                  final Class<?> caller) {
        final Field field;
        final int modifiers;
        try {
            // 获取字段
            field = AccessController.doPrivileged(
                new PrivilegedExceptionAction<Field>() {
                    public Field run() throws NoSuchFieldException {
                        return tclass.getDeclaredField(fieldName);
                    }
                });
            // 获取描述符
            modifiers = field.getModifiers();
            sun.reflect.misc.ReflectUtil.ensureMemberAccess(
                caller, tclass, null, modifiers);
            // 操作类的加载器
            ClassLoader cl = tclass.getClassLoader();
            // caller加载器
            ClassLoader ccl = caller.getClassLoader();
            if ((ccl != null) && (ccl != cl) &&
                ((cl == null) || !isAncestor(cl, ccl))) {
                sun.reflect.misc.ReflectUtil.checkPackageAccess(tclass);
            }
        } catch (PrivilegedActionException pae) {
            throw new RuntimeException(pae.getException());
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }

        if (field.getType() != int.class)
            throw new IllegalArgumentException("Must be integer type");

        if (!Modifier.isVolatile(modifiers))
            throw new IllegalArgumentException("Must be volatile type");
		// 根据是否是要保护的类,赋值cclass
        this.cclass = (Modifier.isProtected(modifiers) &&
                       tclass.isAssignableFrom(caller) &&
                       !isSamePackage(tclass, caller))
            ? caller : tclass;
        // 要操作的类
        this.tclass = tclass;
        // 获取字段的内存偏移
        this.offset = U.objectFieldOffset(field);
    }
```

## 功能方法

### 判断是否是父子关系

```java
        private static boolean isAncestor(ClassLoader first, ClassLoader second) {
            ClassLoader acl = first;
            do {
                acl = acl.getParent();
                if (second == acl) {
                    return true;
                }
            } while (acl != null);
            return false;
        }
```



### 是否是同一个包

```java
        private static boolean isSamePackage(Class<?> class1, Class<?> class2) {
            return class1.getClassLoader() == class2.getClassLoader()
                   && Objects.equals(getPackageName(class1), getPackageName(class2));
        }

        private static String getPackageName(Class<?> cls) {
            String cn = cls.getName();
            int dot = cn.lastIndexOf('.');
            return (dot != -1) ? cn.substring(0, dot) : "";
        }
```

### access检查

```java
       private final void accessCheck(T obj) {
           // 如果obj不是cclass的实例,则报错
            if (!cclass.isInstance(obj))
                throwAccessCheckException(obj);
        }
		// 报错
        private final void throwAccessCheckException(T obj) {
            if (cclass == tclass)
                throw new ClassCastException();
            else
                throw new RuntimeException(
                    new IllegalAccessException(
                        "Class " +
                        cclass.getName() +
                        " can not access a protected member of class " +
                        tclass.getName() +
                        " using an instance of " +
                        obj.getClass().getName()));
        }
```



### 自旋设置field值

```java
        public final boolean compareAndSet(T obj, int expect, int update) {
            accessCheck(obj);
            // 自旋设置值
            return U.compareAndSwapInt(obj, offset, expect, update);
        }
```



### 获取并设置值
```java
       public final int getAndSet(T obj, int newValue) {
            accessCheck(obj);
            return U.getAndSetInt(obj, offset, newValue);
        }

    public final int getAndSetInt(Object var1, long var2, int var4) {
        int var5;
        do {
            // 获取值
            var5 = this.getIntVolatile(var1, var2);
            // 把值设置为newValue
        } while(!this.compareAndSwapInt(var1, var2, var5, var4));
		// 返回原来的值
        return var5;
    }
```


### 获取并增加指定值
```java
        public final int getAndAdd(T obj, int delta) {
            accessCheck(obj);
            return U.getAndAddInt(obj, offset, delta);
        }
		// 获取并增加值
    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            // 获取值
            var5 = this.getIntVolatile(var1, var2);
            // 更新为var5+delta的值
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```


### 获取并自增

```java
        public final int getAndIncrement(T obj) {
            // 增加1
            return getAndAdd(obj, 1);
        }
```

## UnsafeAtomicIntegerFieldUpdater子类实现

## Field

```java
    private final long offset;  // 偏移值
    private final Unsafe unsafe; // CAS操作
```



## 构造函数

```java
    UnsafeAtomicIntegerFieldUpdater(Unsafe unsafe, Class<?> tClass, String fieldName) throws NoSuchFieldException {
        Field field = tClass.getDeclaredField(fieldName);
        // 如果修饰符不是Volatile,则报错
        if (!Modifier.isVolatile(field.getModifiers())) {
            throw new IllegalArgumentException("Must be volatile");
        } else {
            this.unsafe = unsafe;
            this.offset = unsafe.objectFieldOffset(field);
        }
    }
```





## 功能方法

```java
final class UnsafeAtomicIntegerFieldUpdater<T> extends AtomicIntegerFieldUpdater<T> {
	// CAS 操作field的值
    public boolean compareAndSet(T obj, int expect, int update) {
        return this.unsafe.compareAndSwapInt(obj, this.offset, expect, update);
    }

    public boolean weakCompareAndSet(T obj, int expect, int update) {
        return this.unsafe.compareAndSwapInt(obj, this.offset, expect, update);
    }

    public void set(T obj, int newValue) {
        this.unsafe.putIntVolatile(obj, this.offset, newValue);
    }

    public void lazySet(T obj, int newValue) {
        this.unsafe.putOrderedInt(obj, this.offset, newValue);
    }

    public int get(T obj) {
        return this.unsafe.getIntVolatile(obj, this.offset);
    }
}
```

