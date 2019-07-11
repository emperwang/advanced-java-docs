# Modifier

## FIeld

```java
// 关键字对应的编码
public static final int PUBLIC = 1;
public static final int PRIVATE = 2;
public static final int PROTECTED = 4;
public static final int STATIC = 8;
public static final int FINAL = 16;
public static final int SYNCHRONIZED = 32;
public static final int VOLATILE = 64;
public static final int TRANSIENT = 128;
public static final int NATIVE = 256;
public static final int INTERFACE = 512;
public static final int ABSTRACT = 1024;
public static final int STRICT = 2048;
static final int BRIDGE = 64;
static final int VARARGS = 128;
static final int SYNTHETIC = 4096;
static final int ANNOTATION = 8192;
static final int ENUM = 16384;
static final int MANDATED = 32768;
private static final int CLASS_MODIFIERS = 3103;
private static final int INTERFACE_MODIFIERS = 3087;
private static final int CONSTRUCTOR_MODIFIERS = 7;
private static final int METHOD_MODIFIERS = 3391;
private static final int FIELD_MODIFIERS = 223;
private static final int PARAMETER_MODIFIERS = 16;
static final int ACCESS_MODIFIERS = 7;
```

```java
public static final int PUBLIC           = 0x00000001;

public static final int PRIVATE          = 0x00000002;

public static final int PROTECTED        = 0x00000004;

public static final int STATIC           = 0x00000008;

public static final int FINAL            = 0x00000010;

public static final int SYNCHRONIZED     = 0x00000020;

public static final int VOLATILE         = 0x00000040;

public static final int TRANSIENT        = 0x00000080;

public static final int NATIVE           = 0x00000100;

public static final int INTERFACE        = 0x00000200;

public static final int ABSTRACT         = 0x00000400;

public static final int STRICT           = 0x00000800;

static final int BRIDGE    = 0x00000040;
static final int VARARGS   = 0x00000080;
static final int SYNTHETIC = 0x00001000;
static final int ANNOTATION  = 0x00002000;
static final int ENUM      = 0x00004000;
static final int MANDATED  = 0x00008000;
private static final int CLASS_MODIFIERS =
    Modifier.PUBLIC         | Modifier.PROTECTED    | Modifier.PRIVATE |
    Modifier.ABSTRACT       | Modifier.STATIC       | Modifier.FINAL   |
    Modifier.STRICT;

private static final int INTERFACE_MODIFIERS =
    Modifier.PUBLIC         | Modifier.PROTECTED    | Modifier.PRIVATE |
    Modifier.ABSTRACT       | Modifier.STATIC       | Modifier.STRICT;

private static final int CONSTRUCTOR_MODIFIERS =
    Modifier.PUBLIC         | Modifier.PROTECTED    | Modifier.PRIVATE;

private static final int METHOD_MODIFIERS =
    Modifier.PUBLIC         | Modifier.PROTECTED    | Modifier.PRIVATE |
    Modifier.ABSTRACT       | Modifier.STATIC       | Modifier.FINAL   |
    Modifier.SYNCHRONIZED   | Modifier.NATIVE       | Modifier.STRICT;

private static final int FIELD_MODIFIERS =
    Modifier.PUBLIC         | Modifier.PROTECTED    | Modifier.PRIVATE |
    Modifier.STATIC         | Modifier.FINAL        | Modifier.TRANSIENT |
    Modifier.VOLATILE;

private static final int PARAMETER_MODIFIERS =
    Modifier.FINAL;

static final int ACCESS_MODIFIERS =
    Modifier.PUBLIC | Modifier.PROTECTED | Modifier.PRIVATE;
```



静态初始化函数:

```java
    static {
        ReflectionFactory var0 = (ReflectionFactory)AccessController.doPrivileged(new GetReflectionFactoryAction());
        var0.setLangReflectAccess(new ReflectAccess());
    }
```



## 构造器

```java
    public Modifier() {
    }
```



## 功能函数

