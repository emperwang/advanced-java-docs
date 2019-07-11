# Class

## Field

```java
private static final int ANNOTATION = 8192;
private static final int ENUM = 16384;
private static final int SYNTHETIC = 4096;
private transient volatile Constructor<T> cachedConstructor;
private transient volatile Class<?> newInstanceCallerCache;
private transient String name;
private final ClassLoader classLoader;
private static ProtectionDomain allPermDomain;
private static boolean useCaches;
private transient volatile SoftReference<Class.ReflectionData<T>> reflectionData;
private transient volatile int classRedefinedCount = 0;
private transient volatile ClassRepository genericInfo;
private static final long serialVersionUID = 3206093459760846163L;
private static final ObjectStreamField[] serialPersistentFields;
private static ReflectionFactory reflectionFactory;
private static boolean initted;
private transient volatile T[] enumConstants = null;
private transient volatile Map<String, T> enumConstantDirectory = null;
private transient volatile Class.AnnotationData annotationData;
private transient volatile AnnotationType annotationType;
transient ClassValueMap classValueMap;
```

静态初始化代码:

```java
    static {
        registerNatives();
        useCaches = true;
        serialPersistentFields = new ObjectStreamField[0];
        initted = false;
    }

// 注册本地方法
private static native void registerNatives();
```

## 构造器

```java
    private Class(ClassLoader var1) {
        this.classLoader = var1;
    }
```

## 功能函数

### forName

```java
public static Class<?> forName(String var0) throws ClassNotFoundException {
    Class var1 = Reflection.getCallerClass();
    return forName0(var0, true, ClassLoader.getClassLoader(var1), var1);
}

// 调用类
public static native Class<?> getCallerClass();
// 加载类
private static native Class<?> forName0(String var0, boolean var1, ClassLoader var2, Class<?> var3) throws ClassNotFoundException;
```

```java
public static Class<?> forName(String var0, boolean var1, ClassLoader var2) throws ClassNotFoundException {
    Class var3 = null;
    SecurityManager var4 = System.getSecurityManager();
    if (var4 != null) {
        var3 = Reflection.getCallerClass();
        // 进行了一些检查
        if (VM.isSystemDomainLoader(var2)) {
            ClassLoader var5 = ClassLoader.getClassLoader(var3);
            if (!VM.isSystemDomainLoader(var5)) {
                var4.checkPermission(SecurityConstants.GET_CLASSLOADER_PERMISSION);
            }
        }
    }
    return forName0(var0, var1, var2, var3);
}
```

### newInstance

```java
// 创建一个实例
public T newInstance() throws InstantiationException, IllegalAccessException {
    if (System.getSecurityManager() != null) {
        this.checkMemberAccess(0, Reflection.getCallerClass(), false);
    }
    if (this.cachedConstructor == null) {
        if (this == Class.class) {
            throw new IllegalAccessException("Can not call newInstance() on the Class for java.lang.Class");
        }
        try {
            Class[] var1 = new Class[0];
            // 获取构造方法
            final Constructor var2 = this.getConstructor0(var1, 1);
            // 设置权限
            AccessController.doPrivileged(new PrivilegedAction<Void>() {
                public Void run() {
                    var2.setAccessible(true);
                    return null;
                }
            });
            // 缓存构造器
            this.cachedConstructor = var2;
        } catch (NoSuchMethodException var5) {
            throw (InstantiationException)(new InstantiationException(this.getName())).initCause(var5);
        }
    }
    // 得到缓存的构造器
    Constructor var6 = this.cachedConstructor;
    // 修饰符
    int var7 = var6.getModifiers();
    if (!Reflection.quickCheckMemberAccess(this, var7)) {
        Class var3 = Reflection.getCallerClass();
        if (this.newInstanceCallerCache != var3) {
            Reflection.ensureMemberAccess(var3, this, (Object)null, var7);
            this.newInstanceCallerCache = var3;
        }
    }
    try {
        // 调用构造方法中的newInstance
        // 构造方法调用native方法进行实例创建
        return var6.newInstance((Object[])null);
    } catch (InvocationTargetException var4) {
        Unsafe.getUnsafe().throwException(var4.getTargetException());
        return null;
    }
}


// 获取构造器
private Constructor<T> getConstructor0(Class<?>[] var1, int var2) throws NoSuchMethodException {
    // 获取构造器
    // 有可能是多个
    Constructor[] var3 = this.privateGetDeclaredConstructors(var2 == 0);
    Constructor[] var4 = var3;
    int var5 = var3.length;
    for(int var6 = 0; var6 < var5; ++var6) {
        Constructor var7 = var4[var6];
        if (arrayContentsEq(var1, var7.getParameterTypes())) {
            // 根据信息创建一个新的构造器
            return getReflectionFactory().copyConstructor(var7);
        }
    }
    throw new NoSuchMethodException(this.getName() + ".<init>" + argumentTypesToString(var1));
}

// 私有构造器获取
private Constructor<T>[] privateGetDeclaredConstructors(boolean var1) {
    checkInitted();
    // 反射信息
    Class.ReflectionData var3 = this.reflectionData();
    Constructor[] var2;
    if (var3 != null) {
        // 是私有的还是public的构造方法
        var2 = var1 ? var3.publicConstructors : var3.declaredConstructors;
        if (var2 != null) {
            return var2;
        }
    }
    if (this.isInterface()) {
        // 是接口,则数组为0,接口没有构造函数
        Constructor[] var4 = (Constructor[])(new Constructor[0]);
        var2 = var4;
    } else {
        // 获取构造器
        var2 = this.getDeclaredConstructors0(var1);
    }
    if (var3 != null) {
        // 记录一下获取到的构造方法
        if (var1) {
            var3.publicConstructors = var2;
        } else {
            var3.declaredConstructors = var2;
        }
    }
    return var2;
}

// native 获取构造器
private native Constructor<T>[] getDeclaredConstructors0(boolean var1);
```

### nativeMethod

```java
public native boolean isInstance(Object var1);

public native boolean isAssignableFrom(Class<?> var1);

public native boolean isInterface();

public native boolean isArray();

public native boolean isPrimitive();

private native String getName0();

public native Class<? super T> getSuperclass();

native byte[] getRawAnnotations();

native byte[] getRawTypeAnnotations();
// 常量池
native ConstantPool getConstantPool();

private native String getGenericSignature0();

public native Class<?> getComponentType();
// 修饰符
public native int getModifiers();

public native Object[] getSigners();

native void setSigners(Object[] var1);
```

### 标识符判断

```java
public boolean isAnnotation() {
    return (this.getModifiers() & 8192) != 0;
}

public boolean isSynthetic() {
    return (this.getModifiers() & 4096) != 0;
}
```

### getClassLoader

```java
public ClassLoader getClassLoader() {
    ClassLoader var1 = this.getClassLoader0();
    if (var1 == null) {
        return null;
    } else {
        SecurityManager var2 = System.getSecurityManager();
        if (var2 != null) {
            ClassLoader.checkClassLoaderPermission(var1, Reflection.getCallerClass());
        }
        return var1;
    }
}

ClassLoader getClassLoader0() {
    return this.classLoader;
}
```

### getTypeParameters

```java
public TypeVariable<Class<T>>[] getTypeParameters() {
    ClassRepository var1 = this.getGenericInfo();
    return var1 != null ? (TypeVariable[])var1.getTypeParameters() : (TypeVariable[])(new TypeVariable[0]);
}


private ClassRepository getGenericInfo() {
    ClassRepository var1 = this.genericInfo;
    if (var1 == null) {
        // 本地方法获取签名信息
        String var2 = this.getGenericSignature0();
        if (var2 == null) {// 没有获取到,则返回null
            var1 = ClassRepository.NONE;
        } else {// 获取到了,则封装到ClassRepository
            var1 = ClassRepository.make(var2, this.getFactory());
        }
        this.genericInfo = var1;
    }
    return var1 != ClassRepository.NONE ? var1 : null;
}
// 本地方法获取一般信息
private native String getGenericSignature0();
```

### getSuperClass

```java
    public Type getGenericSuperclass() {
        ClassRepository var1 = this.getGenericInfo();
        if (var1 == null) {
            // 获取父类--本地方法
            return this.getSuperclass();
        } else {
            return this.isInterface() ? null : var1.getSuperclass();
        }
    }
```

### getInterfaces

```java
// 获取接口信息
public Class<?>[] getInterfaces() {
    Class.ReflectionData var1 = this.reflectionData();
    if (var1 == null) { // 反射信息没有,就通过本地方法获取
        return this.getInterfaces0();
    } else {// 反射信息有
        Class[] var2 = var1.interfaces;
        if (var2 == null) {
            var2 = this.getInterfaces0();
            var1.interfaces = var2;
        }
        // 拷贝一份
        return (Class[])var2.clone();
    }
}

private native Class<?>[] getInterfaces0();
```

### getEnclosingMethod

```java
public Method getEnclosingMethod() throws SecurityException {
    // 本地方法获取EnclosingMethod信息
    Class.EnclosingMethodInfo var1 = this.getEnclosingMethodInfo();
    if (var1 == null) {
        return null;
    } else if (!var1.isMethod()) {
        return null;
    } else {
        MethodRepository var2 = MethodRepository.make(var1.getDescriptor(), this.getFactory());
        // 返回值转换为class
        Class var3 = toClass(var2.getReturnType());
        // 参数类型
        Type[] var4 = var2.getParameterTypes();
        // 装载参数class的数组
        Class[] var5 = new Class[var4.length];
		//装载具体参数类型的class
        for(int var6 = 0; var6 < var5.length; ++var6) {
            var5[var6] = toClass(var4[var6]);
        }

        Class var14 = var1.getEnclosingClass();
        var14.checkMemberAccess(1, Reflection.getCallerClass(), true);
        // 方法
        Method[] var7 = var14.getDeclaredMethods();
        // 方法个数
        int var8 = var7.length;
		// 遍历method
        for(int var9 = 0; var9 < var8; ++var9) {
            Method var10 = var7[var9];
            if (var10.getName().equals(var1.getName())) {
                Class[] var11 = var10.getParameterTypes();
                if (var11.length == var5.length) {
                    boolean var12 = true;
					// 比较方法的参数类型一样
                    for(int var13 = 0; var13 < var11.length; ++var13) {
                        if (!var11[var13].equals(var5[var13])) {
                            var12 = false;
                            break;
                        }
                    }
				// 返回值一样,则返回返回值类型
                    if (var12 && var10.getReturnType().equals(var3)) {
                        return var10;
                    }
                }
            }
        }
        throw new InternalError("Enclosing method not found");
    }
}

private native Object[] getEnclosingMethod0();
```

### getSimpleName

```java
public String getSimpleName() {
    if (this.isArray()) {
        return this.getComponentType().getSimpleName() + "[]";
    } else {
        String var1 = this.getSimpleBinaryName();
        if (var1 == null) {
            var1 = this.getName();
            return var1.substring(var1.lastIndexOf(".") + 1);
        } else {
            int var2 = var1.length();
            if (var2 >= 1 && var1.charAt(0) == '$') {
                int var3;
         for(var3 = 1; var3 < var2 && isAsciiDigit(var1.charAt(var3)); ++var3) {
                    ;
                }
                return var1.substring(var3);
            } else {
                throw new InternalError("Malformed class name");
            }
        }
    }
}


private String getSimpleBinaryName() {
    Class var1 = this.getEnclosingClass();
    if (var1 == null) {
        return null;
    } else {
        try {
            return this.getName().substring(var1.getName().length());
        } catch (IndexOutOfBoundsException var3) {
            throw new InternalError("Malformed class name", var3);
        }
    }
}
```

### getTypeName

```java
public String getTypeName() {
    if (this.isArray()) {
        try {
            Class var1 = this;
            int var2;
            // 数组类型
            for(var2 = 0; var1.isArray(); var1 = var1.getComponentType()) {
                ++var2;
            }
			// 存储名字的容器
            StringBuilder var3 = new StringBuilder();
            // 追加名字
            var3.append(var1.getName());
			
            for(int var4 = 0; var4 < var2; ++var4) {
                var3.append("[]");
            }
            return var3.toString();
        } catch (Throwable var5) {
            ;
        }
    }
    return this.getName();
}
```

### getClasses

```java
@CallerSensitive
// 获取声明的类信息
public Class<?>[] getClasses() {
    this.checkMemberAccess(0, Reflection.getCallerClass(), false);
 return (Class[])AccessController.doPrivileged(new PrivilegedAction<Class<?>[]>() {
        public Class<?>[] run() {
            ArrayList var1 = new ArrayList();
       for(Class var2 = Class.this; var2 != null; var2 = var2.getSuperclass()) {
           		// 获取声明的类
                Class[] var3 = var2.getDeclaredClasses();
           		// 遍历所有的类,并记录类的修饰符为public的类
                for(int var4 = 0; var4 < var3.length; ++var4) {
                    if (Modifier.isPublic(var3[var4].getModifiers())) {
                        var1.add(var3[var4]);
                    }
                }
            }
            return (Class[])var1.toArray(new Class[0]);
        }
    });
}
```

### getDeclaredClasses

```java
@CallerSensitive
// 通过本地方法获取声明的类
public Class<?>[] getDeclaredClasses() throws SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), false);
    return this.getDeclaredClasses0();
}

private native Class<?>[] getDeclaredClasses0();
```



### getFields

```java
public Field[] getFields() throws SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    return copyFields(this.privateGetPublicFields((Set)null));
}


// 获取public-field
private Field[] privateGetPublicFields(Set<Class<?>> var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Field[] var2;
    // 从缓存中直接获取public-fields
    if (var3 != null) {
        var2 = var3.publicFields;
        if (var2 != null) {
            return var2;
        }
    }

    ArrayList var4 = new ArrayList();
    if (var1 == null) {
        var1 = new HashSet();
    }
	// 获取声明的fields
    Field[] var5 = this.privateGetDeclaredFields(true);
    // 把所有的field添加到var4中
    addAll(var4, var5);
    // 获取所有的接口
    Class[] var6 = this.getInterfaces();
    int var7 = var6.length;
	// 遍历所有的接口
    for(int var8 = 0; var8 < var7; ++var8) {
        Class var9 = var6[var8];
        // var1中不包含此接口,则添加
        if (!((Set)var1).contains(var9)) {
            ((Set)var1).add(var9);
            // 再把接口中的所有field添加到var4中,以及接口的内部接口信息放到var1中
            addAll(var4, var9.privateGetPublicFields((Set)var1));
        }
    }
    if (!this.isInterface()) {
        // 获取父类
        Class var10 = this.getSuperclass();
        if (var10 != null) {
            // 再添加父类的field 以及 接口信息
            addAll(var4, var10.privateGetPublicFields((Set)var1));
        }
    }
    // 创建数组var2并把var4中的field存储到var2中
    var2 = new Field[var4.size()];
    var4.toArray(var2);
    if (var3 != null) {
        var3.publicFields = var2;
    }
    // 返回所有的field信息
    return var2;
}

// 检查初始化
private static void checkInitted() {
    if (!initted) {
        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {
                if (System.out == null) {
                    return null;
                } else {
                    // 根据系统属性,设置是否使用cache
                    String var1 = System.getProperty("sun.reflect.noCaches");
                    if (var1 != null && var1.equals("true")) {
                        Class.useCaches = false;
                    }
                    Class.initted = true;
                    return null;
                }
            }
        });
    }
}

private static Field[] copyFields(Field[] var0) {
    Field[] var1 = new Field[var0.length];
    ReflectionFactory var2 = getReflectionFactory();
	// 遍历所有field,创建一个新的field放到var1中
    for(int var3 = 0; var3 < var0.length; ++var3) {
        var1[var3] = var2.copyField(var0[var3]);
    }
    return var1;
}
```

### getField

```java
@CallerSensitive
public Field getField(String var1) throws NoSuchFieldException, SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    // 获取field
    Field var2 = this.getField0(var1);
    if (var2 == null) {
        throw new NoSuchFieldException(var1);
    } else {
        return var2;
    }
}


private Field getField0(String var1) throws NoSuchFieldException {
    Field var2;
    // 从声明的field中获取
    // 找到直接返回
    if ((var2 = searchFields(this.privateGetDeclaredFields(true), var1)) != null) {
        return var2;
    } else { // 没有找到
        // 获取接口信息
        Class[] var3 = this.getInterfaces();
		// 再从接口中查找,找到直接返回
        for(int var4 = 0; var4 < var3.length; ++var4) {
            Class var5 = var3[var4];
            if ((var2 = var5.getField0(var1)) != null) {
                return var2;
            }
        }
        // 从父类中查找,找到则返回
        if (!this.isInterface()) {
            Class var6 = this.getSuperclass();
            if (var6 != null && (var2 = var6.getField0(var1)) != null) {
                return var2;
            }
        }
        return null;
    }
}
// 获取声明的fields
private Field[] privateGetDeclaredFields(boolean var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Field[] var2;
    if (var3 != null) {
        // var1为true,获取public-field
        // 否则获取declared-field
        var2 = var1 ? var3.declaredPublicFields : var3.declaredFields;
        if (var2 != null) {
            return var2;
        }
    }
    // 底层方法获取field
    var2 = Reflection.filterFields(this, this.getDeclaredFields0(var1));
    if (var3 != null) {
        // 记录找到的信息
        if (var1) {
            var3.declaredPublicFields = var2;
        } else {
            var3.declaredFields = var2;
        }
    }
    return var2;
}

private native Field[] getDeclaredFields0(boolean var1);

// 搜寻field
private static Field searchFields(Field[] var0, String var1) {
    String var2 = var1.intern();
    // 遍历var0,从中查找var1,找到了则创建一个新的返回
    for(int var3 = 0; var3 < var0.length; ++var3) {
        if (var0[var3].getName() == var2) {
            return getReflectionFactory().copyField(var0[var3]);
        }
    }
    return null;
}
```

### getDeclaredFields

```java
@CallerSensitive
public Field[] getDeclaredFields() throws SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 通过native方法找到声明的field,并创建一份新的返回
    return copyFields(this.privateGetDeclaredFields(false));
}
```



### getDeclaredField

```java
@CallerSensitive
public Field getDeclaredField(String var1) throws NoSuchFieldException, SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 找到所有声明的field,然后遍历查找var1
    // 找到则创建一个新的赋值给var2
    Field var2 = searchFields(this.privateGetDeclaredFields(false), var1);
    if (var2 == null) {
        throw new NoSuchFieldException(var1);
    } else {
        return var2;
    }
}
```



### getMethods

```java
@CallerSensitive
public Method[] getMethods() throws SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    return copyMethods(this.privateGetPublicMethods());
}

// 仔细看了,套路跟上面是一样的
private Method[] privateGetDeclaredMethods(boolean var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Method[] var2;
    if (var3 != null) {
        // 根据参数获取,true获取public-method 或 
        // false 获取 declared-method
        var2 = var1 ? var3.declaredPublicMethods : var3.declaredMethods;
        if (var2 != null) {
            return var2;
        }
    }
    // native方法获取
    var2 = Reflection.filterMethods(this, this.getDeclaredMethods0(var1));
    if (var3 != null) {
        // 记录获取到的方法
        if (var1) {
            var3.declaredPublicMethods = var2;
        } else {
            var3.declaredMethods = var2;
        }
    }
    return var2;
}

private native Method[] getDeclaredMethods0(boolean var1);

// 遍历拷贝一份新的返回
private static Method[] copyMethods(Method[] var0) {
    Method[] var1 = new Method[var0.length];
    ReflectionFactory var2 = getReflectionFactory();
    for(int var3 = 0; var3 < var0.length; ++var3) {
        var1[var3] = var2.copyMethod(var0[var3]);
    }
    return var1;
}
```

### getMethod

```java
public Method getMethod(String var1, Class... var2) throws NoSuchMethodException, SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    Method var3 = this.getMethod0(var1, var2, true);
    if (var3 == null) {
        throw new NoSuchMethodException(this.getName() + "." + var1 + argumentTypesToString(var2));
    } else {
        return var3;
    }
}


private Method getMethod0(String var1, Class<?>[] var2, boolean var3) {
    Class.MethodArray var4 = new Class.MethodArray(2);
    Method var5 = this.privateGetMethodRecursive(var1, var2, var3, var4);
    if (var5 != null) {
        return var5;
    } else {
        var4.removeLessSpecifics();
        return var4.getFirst();
    }
}



private Method privateGetMethodRecursive(String var1, Class<?>[] var2, boolean var3, Class.MethodArray var4) {
    Method var5;
    // 从所有方法中进行查找
    if ((var5 = searchMethods(this.privateGetDeclaredMethods(true), var1, var2)) == null || !var3 && Modifier.isStatic(var5.getModifiers())) {
        if (!this.isInterface()) { // 从父类中查找
            Class var6 = this.getSuperclass();
           if (var6 != null && (var5 = var6.getMethod0(var1, var2, true)) != null) {
                return var5;
            }
        }
        Class[] var11 = this.getInterfaces();
        Class[] var7 = var11;
        int var8 = var11.length;
        // 从所有接口方法中查找
        for(int var9 = 0; var9 < var8; ++var9) {
            Class var10 = var7[var9];
            if ((var5 = var10.getMethod0(var1, var2, false)) != null) {
                var4.add(var5);
            }
        }
        return null;
    } else {
        return var5;
    }
}

// 最后还是到这里,进行方法的获取
private Method[] privateGetDeclaredMethods(boolean var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Method[] var2;
    if (var3 != null) {
        var2 = var1 ? var3.declaredPublicMethods : var3.declaredMethods;
        if (var2 != null) {
            return var2;
        }
    }
    var2 = Reflection.filterMethods(this, this.getDeclaredMethods0(var1));
    if (var3 != null) {
        if (var1) {
            var3.declaredPublicMethods = var2;
        } else {
            var3.declaredMethods = var2;
        }
    }
    return var2;
}

private native Method[] getDeclaredMethods0(boolean var1);

// 方法查找
private static Method searchMethods(Method[] var0, String var1, Class<?>[] var2) {
    Method var3 = null;
    String var4 = var1.intern();
	// 遍历所有方法进行查找
    for(int var5 = 0; var5 < var0.length; ++var5) {
        Method var6 = var0[var5];
        if (var6.getName() == var4 && arrayContentsEq(var2, var6.getParameterTypes()) && (var3 == null || var3.getReturnType().isAssignableFrom(var6.getReturnType()))) {
            var3 = var6;
        }
    }
	// 找到了,则创建一个新的返回
    return var3 == null ? var3 : getReflectionFactory().copyMethod(var3);
}
```

### getDeclaredMethods

```java
@CallerSensitive
public Method[] getDeclaredMethods() throws SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 找到所有方法,复制一份返回
    return copyMethods(this.privateGetDeclaredMethods(false));
}
```



### getDeclaredMethod

```java
@CallerSensitive
public Method getDeclaredMethod(String var1, Class... var2) throws NoSuchMethodException, SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 从所有方法中进行查找
    Method var3 = searchMethods(this.privateGetDeclaredMethods(false), var1, var2);
    if (var3 == null) {
        throw new NoSuchMethodException(this.getName() + "." + var1 + argumentTypesToString(var2));
    } else {
        return var3;
    }
}
```



### getConstructors

```java
@CallerSensitive
public Constructor<?>[] getConstructors() throws SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    return copyConstructors(this.privateGetDeclaredConstructors(true));
}

// 查找constructor
private Constructor<T>[] privateGetDeclaredConstructors(boolean var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Constructor[] var2;
    if (var3 != null) {
        // 从缓存中获取
        // 参数为true,则获取public-constructor
        // 参数为flase,则获取declared-constructor
        var2 = var1 ? var3.publicConstructors : var3.declaredConstructors;
        if (var2 != null) {
            return var2;
        }
    }
    if (this.isInterface()) {
        // 接口没有构造函数
        Constructor[] var4 = (Constructor[])(new Constructor[0]);
        var2 = var4;
    } else {
        // 查询操作
        // 本地方法查找
        var2 = this.getDeclaredConstructors0(var1);
    }
    if (var3 != null) {
        // 记录查询到的constructor
        if (var1) {
            var3.publicConstructors = var2;
        } else {
            var3.declaredConstructors = var2;
        }
    }

    return var2;
}

private native Constructor<T>[] getDeclaredConstructors0(boolean var1);
```

### getConstructor

```java
public Constructor<T> getConstructor(Class... var1) throws NoSuchMethodException, SecurityException {
    this.checkMemberAccess(0, Reflection.getCallerClass(), true);
    return this.getConstructor0(var1, 0);
}

private Constructor<T> getConstructor0(Class<?>[] var1, int var2) throws NoSuchMethodException {
    // 根据参数获取constructor
    Constructor[] var3 = this.privateGetDeclaredConstructors(var2 == 0);
    Constructor[] var4 = var3;
    int var5 = var3.length;
    // 遍历所有constructor,找到符合的constructor
    for(int var6 = 0; var6 < var5; ++var6) {
        Constructor var7 = var4[var6];
        if (arrayContentsEq(var1, var7.getParameterTypes())) {
            return getReflectionFactory().copyConstructor(var7);
        }
    }
  throw new NoSuchMethodException(this.getName() + ".<init>" + argumentTypesToString(var1));
}


private Constructor<T>[] privateGetDeclaredConstructors(boolean var1) {
    checkInitted();
    Class.ReflectionData var3 = this.reflectionData();
    Constructor[] var2;
    if (var3 != null) {
        // 从缓存中获取
        var2 = var1 ? var3.publicConstructors : var3.declaredConstructors;
        if (var2 != null) {
            return var2;
        }
    }
    if (this.isInterface()) {
        // 接口不需要constructor
        Constructor[] var4 = (Constructor[])(new Constructor[0]);
        var2 = var4;
    } else {
        // native方法查找
        var2 = this.getDeclaredConstructors0(var1);
    }
    if (var3 != null) {
        // 记录查找到的contructor
        if (var1) {
            var3.publicConstructors = var2;
        } else {
            var3.declaredConstructors = var2;
        }
    }
    return var2;
}

private native Constructor<T>[] getDeclaredConstructors0(boolean var1);
```

### getDeclaredContructors

```java
@CallerSensitive
public Constructor<?>[] getDeclaredConstructors() throws SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 查找所有的,复制一份返回
    return copyConstructors(this.privateGetDeclaredConstructors(false));
}
```

### getDeclaredContructor

```java
@CallerSensitive
public Constructor<T> getDeclaredConstructor(Class... var1) throws NoSuchMethodException, SecurityException {
    this.checkMemberAccess(1, Reflection.getCallerClass(), true);
    // 查找出所有的,遍历查找对应的
    return this.getConstructor0(var1, 1);
}
```

### getResourceAsStream

```java
public InputStream getResourceAsStream(String var1) {
    var1 = this.resolveName(var1);
    ClassLoader var2 = this.getClassLoader0();
    // 获得资源的输入流
    return var2 == null ? ClassLoader.getSystemResourceAsStream(var1) : var2.getResourceAsStream(var1);
}
// 解析名字 转换为 路径
private String resolveName(String var1) {
    if (var1 == null) {
        return var1;
    } else {
        if (!var1.startsWith("/")) {
            Class var2;
            for(var2 = this; var2.isArray(); var2 = var2.getComponentType()) {
                ;
            }
            String var3 = var2.getName();
            int var4 = var3.lastIndexOf(46);
            if (var4 != -1) {
                var1 = var3.substring(0, var4).replace('.', '/') + "/" + var1;
            }
        } else {
            var1 = var1.substring(1);
        }
        return var1;
    }
}
```

### getResource

```java
public URL getResource(String var1) {
    var1 = this.resolveName(var1);
    ClassLoader var2 = this.getClassLoader0();
    return var2 == null ? ClassLoader.getSystemResource(var1) : var2.getResource(var1);
}
```

### getProtectionDomain

```java
public ProtectionDomain getProtectionDomain() {
    SecurityManager var1 = System.getSecurityManager();
    if (var1 != null) {
        var1.checkPermission(SecurityConstants.GET_PD_PERMISSION);
    }
	// 本地方法获取保护域
    ProtectionDomain var2 = this.getProtectionDomain0();
    if (var2 == null) {
        if (allPermDomain == null) {
            Permissions var3 = new Permissions();
            var3.add(SecurityConstants.ALL_PERMISSION);
            allPermDomain = new ProtectionDomain((CodeSource)null, var3);
        }
        var2 = allPermDomain;
    }
    return var2;
}

private native ProtectionDomain getProtectionDomain0();

```

### getPrimitiveClass

```java
static native Class<?> getPrimitiveClass(String var0);
```

### checkMemberAccess

权限检查，不是很清楚。

```java
private void checkMemberAccess(int var1, Class<?> var2, boolean var3) {
    SecurityManager var4 = System.getSecurityManager();
    if (var4 != null) {
        ClassLoader var5 = ClassLoader.getClassLoader(var2);
        ClassLoader var6 = this.getClassLoader0();
        if (var1 != 0 && var5 != var6) {
            var4.checkPermission(SecurityConstants.CHECK_MEMBER_ACCESS_PERMISSION);
        }
        this.checkPackageAccess(var5, var3);
    }
}
```



### checkPackageAccess

```java
private void checkPackageAccess(ClassLoader var1, boolean var2) {
    SecurityManager var3 = System.getSecurityManager();
    if (var3 != null) {
        ClassLoader var4 = this.getClassLoader0();
        if (ReflectUtil.needsPackageAccessCheck(var1, var4)) {
            String var5 = this.getName();
            int var6 = var5.lastIndexOf(46);
            if (var6 != -1) {
                String var7 = var5.substring(0, var6);
                if (!Proxy.isProxyClass(this) || ReflectUtil.isNonPublicProxyClass(this)) {
                    var3.checkPackageAccess(var7);
                }
            }
        }
        if (var2 && Proxy.isProxyClass(this)) {
            ReflectUtil.checkProxyPackageAccess(var1, this.getInterfaces());
        }
    }
}
```



### reflectionData

```java
private Class.ReflectionData<T> reflectionData() {
    SoftReference var1 = this.reflectionData;
    int var2 = this.classRedefinedCount;
    Class.ReflectionData var3;
    return useCaches && var1 != null && (var3 = (Class.ReflectionData)var1.get()) != null && var3.redefinedCount == var2 ? var3 : this.newReflectionData(var1, var2);
}
```



### newReflectionData

```java
private Class.ReflectionData<T> newReflectionData(SoftReference<Class.ReflectionData<T>> var1, int var2) {
    if (!useCaches) {
        return null;
    } else {
        Class.ReflectionData var3;
        do {
            var3 = new Class.ReflectionData(var2);
            // 原子更新ReflectionData
          if (Class.Atomic.casReflectionData(this, var1, new SoftReference(var3))) {
                return var3;
            }
            var1 = this.reflectionData;
            var2 = this.classRedefinedCount;
        } while(var1 == null || (var3 = (Class.ReflectionData)var1.get()) == null || var3.redefinedCount != var2);
        return var3;
    }
}
```

### createAnnotationData

```java
private Class.AnnotationData createAnnotationData(int var1) {
    // 通过getRawAnnotations方法获取 annotation
    // getConstantPool 获取常量池
    Map var2 = AnnotationParser.parseAnnotations(this.getRawAnnotations(), this.getConstantPool(), this);
    // 获取父类
    Class var3 = this.getSuperclass();
    Object var4 = null;
    if (var3 != null) {
        // 获取父类的annotation
        Map var5 = var3.annotationData().annotations;
        Iterator var6 = var5.entrySet().iterator();
		// 遍历父类的annotatioan
        // 如果是可继承的则记录下来
        while(var6.hasNext()) {
            Entry var7 = (Entry)var6.next();
            Class var8 = (Class)var7.getKey();
            if (AnnotationType.getInstance(var8).isInherited()) {
                if (var4 == null) {
                    var4 = new LinkedHashMap((Math.max(var2.size(), Math.min(12, var2.size() + var5.size())) * 4 + 2) / 3);
                }
                ((Map)var4).put(var8, var7.getValue());
            }
        }
    }

    if (var4 == null) {
        var4 = var2;
    } else {
        ((Map)var4).putAll(var2);
    }
	// 创建AnnotationData
    return new Class.AnnotationData((Map)var4, var2, var1);
}
```



### getAnnotaion

```java
public <A extends Annotation> A getAnnotation(Class<A> var1) {
    Objects.requireNonNull(var1);
    // 返回此class对应的annotation
    return (Annotation)this.annotationData().annotations.get(var1);
}
```

下面几个方法主要就是对这个创建好的map的操作.

### getAnnotations

```java
public Annotation[] getAnnotations() {
    // 返回所有annotation
    return AnnotationParser.toArray(this.annotationData().annotations);
}
```



### getDeclaredAnnotation

```java
public <A extends Annotation> A getDeclaredAnnotation(Class<A> var1) {
    Objects.requireNonNull(var1);
    // 从declaredAnnotation中获取annotation
    return (Annotation)this.annotationData().declaredAnnotations.get(var1);
}
```



### getDeclaredAnnotations

```java
public Annotation[] getDeclaredAnnotations() {
    return AnnotationParser.toArray(this.annotationData().declaredAnnotations);
}
```



### getAnnotationByType

```java
    public <A extends Annotation> A[] getAnnotationsByType(Class<A> var1) {
        Objects.requireNonNull(var1);
        Class.AnnotationData var2 = this.annotationData();
        return AnnotationSupport.getAssociatedAnnotations(var2.declaredAnnotations, this, var1);
    }
```





##  内部类

### AnnotationData

field

```java
final Map<Class<? extends Annotation>, Annotation> annotations;
final Map<Class<? extends Annotation>, Annotation> declaredAnnotations;
final int redefinedCount;
```



构造器

```java
AnnotationData(Map<Class<? extends Annotation>, Annotation> var1, Map<Class<? extends Annotation>, Annotation> var2, int var3) {
    this.annotations = var1;
    this.declaredAnnotations = var2;
    this.redefinedCount = var3;
}
```



### Atomic

field

```java
private static final Unsafe unsafe = Unsafe.getUnsafe();
private static final long reflectionDataOffset;
private static final long annotationTypeOffset;
private static final long annotationDataOffset;
```



静态初始化代码:

```java
static {
    Field[] var0 = Class.class.getDeclaredFields0(false);
    reflectionDataOffset = objectFieldOffset(var0, "reflectionData");
    annotationTypeOffset = objectFieldOffset(var0, "annotationType");
    annotationDataOffset = objectFieldOffset(var0, "annotationData");
}
```

构造器:

```java
private Atomic() {
}
```



功能方法:

原子修改object变量值:

objcetFieldOffet:

```java
private static long objectFieldOffset(Field[] var0, String var1) {
    Field var2 = Class.searchFields(var0, var1);
    if (var2 == null) {
        throw new Error("No " + var1 + " field found in java.lang.Class");
    } else {
        return unsafe.objectFieldOffset(var2);
    }
}
```



casReflectionData:

```java
static <T> boolean casReflectionData(Class<?> var0, SoftReference<Class.ReflectionData<T>> var1, SoftReference<Class.ReflectionData<T>> var2) {
    return unsafe.compareAndSwapObject(var0, reflectionDataOffset, var1, var2);
}
```



casAnnotationType:

```java
static <T> boolean casAnnotationType(Class<?> var0, AnnotationType var1, AnnotationType var2) {
    return unsafe.compareAndSwapObject(var0, annotationTypeOffset, var1, var2);
}
```

casAnnotationData:

```java
static <T> boolean casAnnotationData(Class<?> var0, Class.AnnotationData var1, Class.AnnotationData var2) {
    return unsafe.compareAndSwapObject(var0, annotationDataOffset, var1, var2);
}
```



### EnclosingMethodInfo

field

```java
private Class<?> enclosingClass;
private String name;
private String descriptor;
```



构造器:

```java
private EnclosingMethodInfo(Object[] var1) {
    if (var1.length != 3) {
        throw new InternalError("Malformed enclosing method information");
    } else {
        try {
            // class信息
            this.enclosingClass = (Class)var1[0];
            assert this.enclosingClass != null;
           // 名字信息
            this.name = (String)var1[1];
            // 介绍信息
            this.descriptor = (String)var1[2];
            assert this.name != null && this.descriptor != null || this.name == this.descriptor;
        } catch (ClassCastException var3) {
   throw new InternalError("Invalid type in enclosing method information", var3);
        }
    }
}
```

ispartial:

```java
boolean isPartial() {
    return this.enclosingClass == null || this.name == null || this.descriptor == null;
}
```

isContructor:

```java
boolean isConstructor() {
    return !this.isPartial() && "<init>".equals(this.name);
}
```

isMethod:

```java
boolean isMethod() {
    return !this.isPartial() && !this.isConstructor() && !"<clinit>".equals(this.name);
}
```

getEnclosingClass:

```java
Class<?> getEnclosingClass() {
    return this.enclosingClass;
}
```

getName:

```java
String getName() {
    return this.name;
}
```

getDescriptor:

```java
String getDescriptor() {
    return this.descriptor;
}
```

### MethodArray

field

```java
private Method[] methods;
private int length; // 数组有效数据数
private int defaults;
```

构造器

```java
MethodArray() {
    this(20);
}

MethodArray(int var1) {
    if (var1 < 2) {
        throw new IllegalArgumentException("Size should be 2 or more");
    } else {
        // 初始化信息
        this.methods = new Method[var1];
        this.length = 0;
        this.defaults = 0;
    }
}
```

add:

```java
void add(Method var1) {
    if (this.length == this.methods.length) {// 满了,则进行扩容
        this.methods = (Method[])Arrays.copyOf(this.methods, 2 * this.methods.length);
    }
	// 存储到数组
    this.methods[this.length++] = var1;
    if (var1 != null && var1.isDefault()) {
        ++this.defaults;
    }

}
```





### ReflectionData

field

```java
        volatile Field[] declaredFields;
        volatile Field[] publicFields;
        volatile Method[] declaredMethods;
        volatile Method[] publicMethods;
        volatile Constructor<T>[] declaredConstructors;
        volatile Constructor<T>[] publicConstructors;
        volatile Field[] declaredPublicFields;
        volatile Method[] declaredPublicMethods;
        volatile Class<?>[] interfaces;
        final int redefinedCount;
```

构造函数

```java
        ReflectionData(int var1) {
            this.redefinedCount = var1;
        }
```

