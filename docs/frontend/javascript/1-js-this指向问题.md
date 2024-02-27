# this指向问题

简单理解: **this的指向在函数定义的时候是确定不了的，只有函数执行的时候才能确定this到底指向谁，实际上this最终指向的是那个调用它的对象。** 这么理解虽然也可以，不过有些偏差。

下面通过例子来解析一下this的指向问题.。

## 1. example-1

```javascript
function a(){
    var user="dreamer";
    console.log(this.user); // 输出: undefined
    console.log(this);   // 输出: window 对象
}
a();
```

这里的函数a实例上时Window对象调用的，故这里this的最终指向是Window对象，可以用下面代码查看

```javascript
function a(){
    var user="dreamer";
    console.log(this.user);	// 输出: undefined
    console.log(this);	// 输出: Window
}
window.a();
```

此示例和上面的示例是一样的，其实alert也是window的一个属性，也是window调用的。

## 2. exmaple-2

```javascript
var o = {
    user: "dreamer",
    fu: function(){
        console.log(this.user);	// 输出: dreamer
    }
}
o.fn();
```

这里的this指向的是对象o，因为是通过o.fn()来调用执行的，那自然指向的就是对象o。

**在强调一下：this的指向在函数创建的时候是决定不了的，在调用的时候才能确定，谁调用就指向谁。**



## 3.  example-3

```javascript
var o ={
    user:"dreamer",
    fn: function(){
        console.log(this.user);// 输出: dreamer
    }
}
window.o.fn();
```

由输出可以反推出这里的this指向的是o对象，并没有执行window对象(**window是js中的全局对象，我们创建的变量实际上是给window添加属性，所以这里可以用window调用o对象**)。

```javascript
var o = {
    a: 10,
    b: {
        a:12,
        fn:function(){
            console.log(this.a); // 输出 12
        }
    }
}
o.b.fn();
```

由输出可反推这里的this指向的是b对象，并没有指向到a对象，由此可知开头说的谁调用就指向谁有些不准确，这里再补充一下: (**这里不包括call，apply，bind的使用**)

> 情况一: 如果一个函数中有this，但是他没有被上一级对象调用，那么this指向的就是window，这里需要说明的是： 在js的严格版中this指向的是undefined
>
> 情况二: 如果一个函数中有this，这个函数有被上一级对象所调用，那么this指向的就是上一次对象
>
> 情况三: 如果一个函数中有this，这个函数中包含多个对象，尽管这个函数是被最外层的对象所调用，this指向的也只是它上一级的对象

```javascript
var o = {
    a:10,
    b: {
        fn:function(){
            console.log(this.a) // 输出: undefined
        }
    }
}
o.b.fn();
```

尽管对象b中没有属性a，这里的this也指向b对象。对象情况二或者三，这里的this只会指向上一级对象。

## 4. exmaple-4

```javascript
var o ={
    a:10,
    b: {
        a: 12,
        fn:function(){
            console.log(this.a); // undefined
            console.log(this); // window
        }
    }
}
var j = o.b.fn;
j();
```

这里的this指向的是window。这里简单解释一下：

> this永远指向的是最后调用它的对象，也就是看它执行的时候是谁调用的，示例4中虽然函数fn是被对象b所引用，但是在将fn赋值给变量j的时候并没有执行，而最后调用j时是window对象调用的，故这里的this指向的是window对象。

## 5. example-5 构造函数

```javascript
function fn(){
    this.user = "dreamer";
}
var a = new fm();
console.log(a.user);  // 输出: dreamer
```

这里的a之所以可以调用函数fn中的user是因为**new关键字可以改变this的指向，将这个this指向对象a。** 使用new关键字就是创建一个对象实例，所以这里的a是对象；这里用变量a创建了一个fn实例(相当于是复制了一个fn到对象a里面)，此时仅仅是创建，并没有执行，**而调用这个fn函数的是对象a，故this自然就指向对象a**。

那为什么对象a中会有user? 因为你已经复制了一份fn函数到对象a中，用了new关键字就等同于复制了一份。

## 6. example-6  this遇见return

```javascript
function fn(){
    this.user="dreamer";
    return {};
}
var a = new fn;
console.log(a.user); // undefined
```

这里的this指向的是 return返回的{} 对象.

```javascript
function fn(){
    this.user="dreamer";
    return function(){};
}
var a = new fn;
console.log(a.user);	// undefined
```

这里的this指向的同样是return返回的 function(){} 对象。

```javascript
function fn(){
    this.user = "dreamer";
    return 1;
}
var a = new fn;
console.log(a.user); // dreamer
```

```javascript
function fn(){
    this.user = "dreamer";
    return undefined;
}
var a = new fn;
console.log(a.user); // dreamer
```

```javascript
function fn(){
    this.user = "dreamer";
    return null;
}
vara =new fn;
consoler.log(a.user); // dreamer
```

上面的return返回的1，undefined，null都比较特殊，1不是对象，null和undefined比较特殊，故这里的this还是指向那个函数的实例。

> 如果return返回值是一个对象，那么this指向的就是那个返回的对象；如果返回值不是一个对象那么this还是指向函数的实例。

## 7. example-7  call

```javascript
var a = {
    user:"dreamer",
    fn: function(){
        consoler.log(this.user); 	// 输出: undefined
    }
}
var b = a.fn;
b();
```

这里的this指向window，通过前面的实例可以了解到。

```javascript
var a = {
    user:"dreamer",
    fn: function(){
        console.log(this.user);	// 输出: dreamer
    }
}
var b = a.fn;
b.call(a);
```

> 通过在call方法，给第一个参数添加要把b添加到哪个环境中，简单说，this就会指向那个对象。

```javascript
var a = {
    user: "dreamer",
    fn: function(e,ee){
        console.log(this.user);// dreamer
        console.log(e+ee);	// 3
    }
}
var bb= a.fn;
b.call(a,1,2);
```

call方法除了第一个参数外，还可以添加多个参数.

## 8. example-8  apply

apply方法和call方法有些类似。

```javascript
var a = {
    user: "dreamer",
    fn: function(){
        console.log(this.user); // dreamer
    }
}
var bb = a.fn;
bb.apply(a);
```

这里同样是把bb添加的a的环境中，this指向a对象。

同样apply也可以传递多个参数，但是第二个参数必须是一个数组:

```javascript
var a = {
    user: "dreamer",
    fn: function(e,ee){
        console.log(this.user); // dreamer
        console.log(e+ee);	// 3
    }
}
var bb= a.fn;
bb.apply(a,[1,2])
```

或者:

```javascript
var a = {
   user: "dreamer",
   fn: function(){
       console.log(this.user); // dreamer
       console.log(e+ee); // 520
   }
}
var bb= a.fn;
var arr=[500,20];
bb.apply(a,arr);
```



## 9. example-9  bind

```javascript
var a = {
    user: "dreamer",
    fn: function(){
        console.log(this.user);
    }
}
var bb = a.fn;
bb.bind(a);
```

这样调用，发现代码其实么有打印，**这就是bind和call、apply方法的区别，bing方法返回的是一个修改后的函数**。

```javascript
var a = {
    user:"dreamer",
    fn: function(){
        console.log(this.user); // dreamer
    }
}
var bb = a.fn;;
var c = bb.bind(a);
console.log(c): // function(){[Native code]}
c();
```

bind同样可以传递多个参数:

```javascript
var a = {
    user:"dreamer",
    fn: function(e,d,f){
        console.log(this.user); // dreamer
        console.log(e,d,f); // 10,1,2
    }
}

var bb = a.fn;
var c = bb.bind(a,10);
c(1,2);
```







































