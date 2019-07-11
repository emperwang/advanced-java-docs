# Parameter

## Field

```java
private final String name;
private final int modifiers;
private final Executable executable;
private final int index;
private transient volatile Type parameterTypeCache = null;
private transient volatile Class<?> parameterClassCache = null;
private transient Map<Class<? extends Annotation>, Annotation> declaredAnnotations;
```



## 构造器

```java
Parameter(String name,
          int modifiers,
          Executable executable,
          int index) {
    this.name = name;
    this.modifiers = modifiers;
    this.executable = executable;
    this.index = index;
}
```

## 功能方法

```java
public boolean equals(Object obj) {
    if(obj instanceof Parameter) {
        Parameter other = (Parameter)obj;
        return (other.executable.equals(executable) &&
                other.index == index);
    }
    return false;
}
```

```java
public boolean isNamePresent() {
    return executable.hasRealParameterData() && name != null;
}
```

```java
    public Executable getDeclaringExecutable() {
        return executable;
    }

    public int getModifiers() {
        return modifiers;
    }

    public String getName() {
        // Note: empty strings as paramete names are now outlawed.
        // The .equals("") is for compatibility with current JVM
        // behavior.  It may be removed at some point.
        if(name == null || name.equals(""))
            return "arg" + index;
        else
            return name;
    }

    // Package-private accessor to the real name field.
    String getRealName() {
        return name;
    }


    public Type getParameterizedType() {
        Type tmp = parameterTypeCache;
        if (null == tmp) {
            tmp = executable.getAllGenericParameterTypes()[index];
            parameterTypeCache = tmp;
        }

        return tmp;
    }

    public Class<?> getType() {
        Class<?> tmp = parameterClassCache;
        if (null == tmp) {
            tmp = executable.getParameterTypes()[index];
            parameterClassCache = tmp;
        }
        return tmp;
    }
```

```java
public Annotation[] getDeclaredAnnotations() {
    // 获取参数的annotation
    return executable.getParameterAnnotations()[index];
}

private synchronized Map<Class<? extends Annotation>, Annotation> declaredAnnotations() {
    if(null == declaredAnnotations) {
        declaredAnnotations =
            new HashMap<Class<? extends Annotation>, Annotation>();
        Annotation[] ann = getDeclaredAnnotations();
        // 保存获取到的annotations
        for(int i = 0; i < ann.length; i++)
            declaredAnnotations.put(ann[i].annotationType(), ann[i]);
    }
    return declaredAnnotations;
}
```