# Field

## field

```java
    private Class<?> clazz;
    private int slot;
    private String name;
    private Class<?> type;
    private int modifiers;
    private transient String signature;
    private transient FieldRepository genericInfo;
    private byte[] annotations;
    private FieldAccessor fieldAccessor;
    private FieldAccessor overrideFieldAccessor;
    private Field root;
    private transient Map<Class<? extends Annotation>, Annotation> declaredAnnotations;
```



## 构造器

```java
Field(Class<?> var1, String var2, Class<?> var3, int var4, int var5, String var6, byte[] var7) {
    this.clazz = var1;
    this.name = var2;
    this.type = var3;
    this.modifiers = var4;
    this.slot = var5;
    this.signature = var6;
    this.annotations = var7;
}
```



## 功能函数

### getFactory

```java
private GenericsFactory getFactory() {
    Class var1 = this.getDeclaringClass();
    return CoreReflectionFactory.make(var1, ClassScope.make(var1));
}
```

### getGenericInfo

```java
private FieldRepository getGenericInfo() {
    if (this.genericInfo == null) {
        this.genericInfo = FieldRepository.make(this.getGenericSignature(), this.getFactory());
    }

    return this.genericInfo;
}
```

### copy

```java
Field copy() {
    if (this.root != null) {
        throw new IllegalArgumentException("Can not copy a non-root Field");
    } else {
        // 复制就是新建一个和原来一样的
        Field var1 = new Field(this.clazz, this.name, this.type, this.modifiers, this.slot, this.signature, this.annotations);
        var1.root = this;
        var1.fieldAccessor = this.fieldAccessor;
        var1.overrideFieldAccessor = this.overrideFieldAccessor;
        return var1;
    }
}
```

### acquireFieldAccessor

```java
// 创建一个具体的操作field的类
private FieldAccessor acquireFieldAccessor(boolean var1) {
    FieldAccessor var2 = null;
    if (this.root != null) { // 从root中获取
        var2 = this.root.getFieldAccessor(var1);
    }
    if (var2 != null) { // 获取成功，则记录
        if (var1) {
            this.overrideFieldAccessor = var2;
        } else {
            this.fieldAccessor = var2;
        }
    } else { // 不然就创建一个
        // 创建对应的类型访问方法
        var2 = reflectionFactory.newFieldAccessor(this, var1);
        // 记录field访问类
        this.setFieldAccessor(var2, var1);
    }
    return var2;
}

// 创建访问方法
public FieldAccessor newFieldAccessor(Field var1, boolean var2) {
    checkInitted();
    return UnsafeFieldAccessorFactory.newFieldAccessor(var1, var2);
}

// 此方法创建对应不同field的操作方法
static FieldAccessor newFieldAccessor(Field var0, boolean var1) {
    // 获取类型
    Class var2 = var0.getType();
    // 是否是static
    boolean var3 = Modifier.isStatic(var0.getModifiers());
    // 是否是final
    boolean var4 = Modifier.isFinal(var0.getModifiers());
    // 是否是volatile
    boolean var5 = Modifier.isVolatile(var0.getModifiers());
    boolean var6 = var4 || var5;
    boolean var7 = var4 && (var3 || !var1);
    if (var3) { // 如果是static修饰
 UnsafeFieldAccessorImpl.unsafe.ensureClassInitialized(var0.getDeclaringClass());
        if (!var6) { // 不是final 和 volatile
            if (var2 == Boolean.TYPE) { // boolean的操作类 ； 下面是一样的
                return new UnsafeStaticBooleanFieldAccessorImpl(var0);
            } else if (var2 == Byte.TYPE) {
                return new UnsafeStaticByteFieldAccessorImpl(var0);
            } else if (var2 == Short.TYPE) {
                return new UnsafeStaticShortFieldAccessorImpl(var0);
            } else if (var2 == Character.TYPE) {
                return new UnsafeStaticCharacterFieldAccessorImpl(var0);
            } else if (var2 == Integer.TYPE) {
                return new UnsafeStaticIntegerFieldAccessorImpl(var0);
            } else if (var2 == Long.TYPE) {
                return new UnsafeStaticLongFieldAccessorImpl(var0);
            } else if (var2 == Float.TYPE) {
                return new UnsafeStaticFloatFieldAccessorImpl(var0);
            } else {
                return (FieldAccessor)(var2 == Double.TYPE ? new UnsafeStaticDoubleFieldAccessorImpl(var0) : new UnsafeStaticObjectFieldAccessorImpl(var0));
            }
         // 是final 或 volatile 修饰的一种或两种
        } else if (var2 == Boolean.TYPE) {
            return new UnsafeQualifiedStaticBooleanFieldAccessorImpl(var0, var7);
        } else if (var2 == Byte.TYPE) {
            return new UnsafeQualifiedStaticByteFieldAccessorImpl(var0, var7);
        } else if (var2 == Short.TYPE) {
            return new UnsafeQualifiedStaticShortFieldAccessorImpl(var0, var7);
        } else if (var2 == Character.TYPE) {
            return new UnsafeQualifiedStaticCharacterFieldAccessorImpl(var0, var7);
        } else if (var2 == Integer.TYPE) {
            return new UnsafeQualifiedStaticIntegerFieldAccessorImpl(var0, var7);
        } else if (var2 == Long.TYPE) {
            return new UnsafeQualifiedStaticLongFieldAccessorImpl(var0, var7);
        } else if (var2 == Float.TYPE) {
            return new UnsafeQualifiedStaticFloatFieldAccessorImpl(var0, var7);
        } else {
            return (FieldAccessor)(var2 == Double.TYPE ? new UnsafeQualifiedStaticDoubleFieldAccessorImpl(var0, var7) : new UnsafeQualifiedStaticObjectFieldAccessorImpl(var0, var7));
        }
        // 不是static修饰，也不是final 和 volatile修饰
    } else if (!var6) {
        if (var2 == Boolean.TYPE) {
            return new UnsafeBooleanFieldAccessorImpl(var0);
        } else if (var2 == Byte.TYPE) {
            return new UnsafeByteFieldAccessorImpl(var0);
        } else if (var2 == Short.TYPE) {
            return new UnsafeShortFieldAccessorImpl(var0);
        } else if (var2 == Character.TYPE) {
            return new UnsafeCharacterFieldAccessorImpl(var0);
        } else if (var2 == Integer.TYPE) {
            return new UnsafeIntegerFieldAccessorImpl(var0);
        } else if (var2 == Long.TYPE) {
            return new UnsafeLongFieldAccessorImpl(var0);
        } else if (var2 == Float.TYPE) {
            return new UnsafeFloatFieldAccessorImpl(var0);
        } else {
            return (FieldAccessor)(var2 == Double.TYPE ? new UnsafeDoubleFieldAccessorImpl(var0) : new UnsafeObjectFieldAccessorImpl(var0));
        }
       // static 和 final  volatile修饰 
    } else if (var2 == Boolean.TYPE) {
        return new UnsafeQualifiedBooleanFieldAccessorImpl(var0, var7);
    } else if (var2 == Byte.TYPE) {
        return new UnsafeQualifiedByteFieldAccessorImpl(var0, var7);
    } else if (var2 == Short.TYPE) {
        return new UnsafeQualifiedShortFieldAccessorImpl(var0, var7);
    } else if (var2 == Character.TYPE) {
        return new UnsafeQualifiedCharacterFieldAccessorImpl(var0, var7);
    } else if (var2 == Integer.TYPE) {
        return new UnsafeQualifiedIntegerFieldAccessorImpl(var0, var7);
    } else if (var2 == Long.TYPE) {
        return new UnsafeQualifiedLongFieldAccessorImpl(var0, var7);
    } else if (var2 == Float.TYPE) {
        return new UnsafeQualifiedFloatFieldAccessorImpl(var0, var7);
    } else {
        return (FieldAccessor)(var2 == Double.TYPE ? new UnsafeQualifiedDoubleFieldAccessorImpl(var0, var7) : new UnsafeQualifiedObjectFieldAccessorImpl(var0, var7));
    }
}
```



### get获取信息

```java
public Class<?> getDeclaringClass() {
    return this.clazz;
}

public String getName() {
    return this.name;
}

public int getModifiers() {
    return this.modifiers;
}

public boolean isEnumConstant() {
    return (this.getModifiers() & 16384) != 0;
}

public boolean isSynthetic() {
    return Modifier.isSynthetic(this.getModifiers());
}

public Class<?> getType() {
    return this.type;
}

public Type getGenericType() {
    return (Type)(this.getGenericSignature() != null ? this.getGenericInfo().getGenericType() : this.getType());
}
```

### declaredAnnotations

```java
private synchronized Map<Class<? extends Annotation>, Annotation> declaredAnnotations() {
    if (this.declaredAnnotations == null) {
        Field var1 = this.root;
        if (var1 != null) { // 获取注解
            this.declaredAnnotations = var1.declaredAnnotations();
        } else {
            // 获取声明的注解
            this.declaredAnnotations = AnnotationParser.parseAnnotations(this.annotations, SharedSecrets.getJavaLangAccess().getConstantPool(this.getDeclaringClass()), this.getDeclaringClass());
        }
    }
    return this.declaredAnnotations;
}
```

至于其他的getBoolean，getChar，getShort，getInt等操作，就是具体的具体修饰符修饰的field的操作函数执行的。可以选一个看一下: static修饰的字符:UnsafeStaticCharacterFieldAccessorImpl:

```java
    // 仍旧是对应的底层函数
	public Object get(Object var1) throws IllegalArgumentException {
        return new Character(this.getChar(var1));
    }

    public char getChar(Object var1) throws IllegalArgumentException {
        return unsafe.getChar(this.base, this.fieldOffset);
    }

	public native char getChar(Object var1, long var2);
```

这个操作可以单独拿出来分析一下，在这里就先了解到这里就好。