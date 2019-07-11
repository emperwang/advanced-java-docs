# Method

## Fied

```java
    private Class<?> clazz;
    private int slot;
    private String name;
    private Class<?> returnType;
    private Class<?>[] parameterTypes;
    private Class<?>[] exceptionTypes;
    private int modifiers;
    private transient String signature;
    private transient MethodRepository genericInfo;
    private byte[] annotations;
    private byte[] parameterAnnotations;
    private byte[] annotationDefault;
    private volatile MethodAccessor methodAccessor;
    private Method root;
```

## 构造器

```java
Method(Class<?> var1, String var2, Class<?>[] var3, Class<?> var4, Class<?>[] var5, int var6, int var7, String var8, byte[] var9, byte[] var10, byte[] var11) {
    this.clazz = var1;
    this.name = var2;
    this.parameterTypes = var3;
    this.returnType = var4;
    this.exceptionTypes = var5;
    this.modifiers = var6;
    this.slot = var7;
    this.signature = var8;
    this.annotations = var9;
    this.parameterAnnotations = var10;
    this.annotationDefault = var11;
}
```

## 功能函数

### getFactory

```java
private GenericsFactory getFactory() {
    return CoreReflectionFactory.make(this, MethodScope.make(this));
}

MethodRepository getGenericInfo() {
    if (this.genericInfo == null) {
        this.genericInfo = MethodRepository.make(this.getGenericSignature(), this.getFactory());
    }

    return this.genericInfo;
}
```

### copy

```java
Method copy() {
    if (this.root != null) {
        throw new IllegalArgumentException("Can not copy a non-root Method");
    } else {
        // 复制也是使用原参数创建一个
        Method var1 = new Method(this.clazz, this.name, this.parameterTypes, this.returnType, this.exceptionTypes, this.modifiers, this.slot, this.signature, this.annotations, this.parameterAnnotations, this.annotationDefault);
        var1.root = this;
        var1.methodAccessor = this.methodAccessor;
        return var1;
    }
}
```

### acquireMethodAccessor

```java
// 创建不同method的操作方法
private MethodAccessor acquireMethodAccessor() {
    MethodAccessor var1 = null;
    if (this.root != null) { // 如果有了，直接使用
        var1 = this.root.getMethodAccessor();
    }
    if (var1 != null) {
        this.methodAccessor = var1;
    } else {
        // 不然就需要创建
        var1 = reflectionFactory.newMethodAccessor(this);
        // 记录
        this.setMethodAccessor(var1);
    }
    return var1;
}

// 创建的函数
public MethodAccessor newMethodAccessor(Method var1) {
    checkInitted();
    if (noInflation && !ReflectUtil.isVMAnonymousClass(var1.getDeclaringClass())) {
        // 这是一种
  return (new MethodAccessorGenerator()).generateMethod(var1.getDeclaringClass(), var1.getName(), var1.getParameterTypes(), var1.getReturnType(), var1.getExceptionTypes(), var1.getModifiers());
    } else {
        // 这也是一种method访问；此方法最后调用的函数是native函数
        // 具体的函数调用，就不展开了，回头开一篇具体讲
        NativeMethodAccessorImpl var2 = new NativeMethodAccessorImpl(var1);
        DelegatingMethodAccessorImpl var3 = new DelegatingMethodAccessorImpl(var2);
        var2.setParent(var3);
        return var3;
    }
}
```

### invoke

```java
public Object invoke(Object var1, Object... var2) throws IllegalAccessException, IllegalArgumentException, InvocationTargetException {
    if (!this.override && !Reflection.quickCheckMemberAccess(this.clazz, this.modifiers)) {
        Class var3 = Reflection.getCallerClass();
        this.checkAccess(var3, this.clazz, var1, this.modifiers);
    }
	// 这里可以看到，函数调用，是通过这个methodAccessor实现的
    MethodAccessor var4 = this.methodAccessor;
    if (var4 == null) {
        var4 = this.acquireMethodAccessor();
    }
    return var4.invoke(var1, var2);
}
```

