# Constructor

## Field

```java
private Class<T>            clazz;
private int                 slot;
private Class<?>[]          parameterTypes;
private Class<?>[]          exceptionTypes;
private int                 modifiers;
// Generics and annotations support
private transient String    signature;
// generic info repository; lazily initialized
private transient ConstructorRepository genericInfo;
private byte[]              annotations;
private byte[]              parameterAnnotations;
private volatile ConstructorAccessor constructorAccessor;
// For sharing of ConstructorAccessors. This branching structure
// is currently only two levels deep (i.e., one root Constructor
// and potentially many Constructor objects pointing to it.)
// If this branching structure would ever contain cycles, deadlocks can
// occur in annotation code.
private Constructor<T>      root;
```



## 构造函数

```java
   /** Package-private constructor used by ReflectAccess to enable
     * instantiation of these objects in Java code from the java.lang
     * package via sun.reflect.LangReflectAccess. */
    Constructor(Class<T> declaringClass,
                Class<?>[] parameterTypes,
                Class<?>[] checkedExceptions,
                int modifiers,
                int slot,
                String signature,
                byte[] annotations,
                byte[] parameterAnnotations) {
        this.clazz = declaringClass;
        this.parameterTypes = parameterTypes;
        this.exceptionTypes = checkedExceptions;
        this.modifiers = modifiers;
        this.slot = slot;
        this.signature = signature;
        this.annotations = annotations;
        this.parameterAnnotations = parameterAnnotations;
    }
```

## 功能方法

### getFactory

```java
// Generics infrastructure
// Accessor for factory
private GenericsFactory getFactory() {
    // create scope and factory
    return CoreReflectionFactory.make(this, ConstructorScope.make(this));
}
```



### copy

```java
Constructor<T> copy() {
    // This routine enables sharing of ConstructorAccessor objects
    // among Constructor objects which refer to the same underlying
    // method in the VM. (All of this contortion is only necessary
    // because of the "accessibility" bit in AccessibleObject,
    // which implicitly requires that new java.lang.reflect
    // objects be fabricated for each reflective call on Class
    // objects.)
    if (this.root != null)
        throw new IllegalArgumentException("Can not copy a non-root Constructor");
	// 就是创建了一个新类
    Constructor<T> res = new Constructor<>(clazz,
                                           parameterTypes,
                                           exceptionTypes, modifiers, slot,
                                           signature,
                                           annotations,
                                           parameterAnnotations);
    res.root = this;
    // Might as well eagerly propagate this if already present
    res.constructorAccessor = constructorAccessor;
    return res;
}
```



### newInstance

```java
public T newInstance(Object ... initargs)
    throws InstantiationException, IllegalAccessException,
IllegalArgumentException, InvocationTargetException {
        if (!override) {
            if (!Reflection.quickCheckMemberAccess(clazz, modifiers)) {
                Class<?> caller = Reflection.getCallerClass();
                checkAccess(caller, clazz, null, modifiers);
            }
        }
        if ((clazz.getModifiers() & Modifier.ENUM) != 0)
            throw new IllegalArgumentException("Cannot reflectively create enum objects");
        ConstructorAccessor ca = constructorAccessor;   // read volatile
        if (ca == null) {
            ca = acquireConstructorAccessor();
        }
        @SuppressWarnings("unchecked")
    // 创建实例
        T inst = (T) ca.newInstance(initargs);
        return inst;
    }

// 创建实例的实现方法
public Object newInstance(Object[] var1) throws InstantiationException, IllegalArgumentException, InvocationTargetException {
    if (++this.numInvocations > ReflectionFactory.inflationThreshold() && !ReflectUtil.isVMAnonymousClass(this.c.getDeclaringClass())) {
        ConstructorAccessorImpl var2 = (ConstructorAccessorImpl)(new MethodAccessorGenerator()).generateConstructor(this.c.getDeclaringClass(), this.c.getParameterTypes(), this.c.getExceptionTypes(), this.c.getModifiers());
        this.parent.setDelegate(var2);
    }

    return newInstance0(this.c, var1);
}


// 本地方法创建实例
private static native Object newInstance0(Constructor<?> var0, Object[] var1) throws InstantiationException, IllegalArgumentException, InvocationTargetException;
```

### 查看信息method

```java
@Override
boolean hasGenericInformation() {
    return (getSignature() != null);
}

@Override
byte[] getAnnotationBytes() {
    return annotations;
}

/**
     * {@inheritDoc}
     */
@Override
public Class<T> getDeclaringClass() {
    return clazz;
}

@Override
public String getName() {
    return getDeclaringClass().getName();
}

/**
     * {@inheritDoc}
     */
@Override
public int getModifiers() {
    return modifiers;
}

@Override
@SuppressWarnings({"rawtypes", "unchecked"})
public TypeVariable<Constructor<T>>[] getTypeParameters() {
    if (getSignature() != null) {
        return (TypeVariable<Constructor<T>>[])getGenericInfo().getTypeParameters();
    } else
        return (TypeVariable<Constructor<T>>[])new TypeVariable[0];
}


@Override
public Class<?>[] getParameterTypes() {
    return parameterTypes.clone();
}

/**
     * {@inheritDoc}
     * @since 1.8
     */
public int getParameterCount() { return parameterTypes.length; }


@Override
public Type[] getGenericParameterTypes() {
    return super.getGenericParameterTypes();
}

/**
     * {@inheritDoc}
     */
@Override
public Class<?>[] getExceptionTypes() {
    return exceptionTypes.clone();
}

@Override
public Type[] getGenericExceptionTypes() {
    return super.getGenericExceptionTypes();
}

@Override
void specificToStringHeader(StringBuilder sb) {
    sb.append(getDeclaringClass().getTypeName());
}


@Override
public String toGenericString() {
    return sharedToGenericString(Modifier.constructorModifiers(), false);
}

@Override
void specificToGenericStringHeader(StringBuilder sb) {
    specificToStringHeader(sb);
}

int getSlot() {
    return slot;
}

String getSignature() {
    return signature;
}

byte[] getRawAnnotations() {
    return annotations;
}

byte[] getRawParameterAnnotations() {
    return parameterAnnotations;
}

public <T extends Annotation> T getAnnotation(Class<T> annotationClass) {
    return super.getAnnotation(annotationClass);
}

/**
     * {@inheritDoc}
     * @since 1.5
     */
public Annotation[] getDeclaredAnnotations()  {
    return super.getDeclaredAnnotations();
}

/**
     * {@inheritDoc}
     * @since 1.5
     */
@Override
public Annotation[][] getParameterAnnotations() {
    return sharedGetParameterAnnotations(parameterTypes, parameterAnnotations);
}
```

