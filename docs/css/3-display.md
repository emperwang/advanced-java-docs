# display布局以及position

## 浮动显示

```css
/*
浮动会从正常的文档流中脱离,但会在其父类容器中记性定位
*/
display: float;  
```



## 绝对定位

```css
/* 脱离文档流
如果父元素没有指定相对定位,则会根据设置的top,left值在窗口中进行定位*/
position: absulate;
```



## 相对定位

```css
/*没有脱离文档流
相对于自己在正常文档流中的位置进行相对移动
*/
position: relative;
```

## sticky

```css
/* 脱离正常文档流
类似于绝对定位,只不过会在移动到定位后,会固定咋哪里
*/
position: sticky;
```



## fixed

```css
position: fixed;
```





## inline

```css
/* 行内元素,width height 等不起作用
*/
display: inline;
/* 行内块元素,此时指定宽高才会生效
*/
display: inline-block;
```



## block

```css
/* 块元素
*/
display: block;
```



## flex

```css
/* flex布局
*/
display: flex;
flex-basis:100px;
flex:1; // 是flex-grow  flex-shirk  flex-basis 的简写形式
flex-direction: column; // row row-reverse column column-reverse
flex-flow: column wrap ; //是 flex-direction flex-wrap的简写模式
flex-grow:1;
flex-shirk:1;
flex-wrap: wrap;
align-items: center;
justify-content: center;// start end center flex-start flex-end space-between space-around strtch
align-self:flex-start; // flex-start flex-end center 
order: 1; 
```



## grid

```css
/* grid布局
*/
display: grid;
grid-template-columns:100px 1fr; // mdn
grid-auto-columns: auto;
grid-template-rows:1fr 2fr;
grid-auto-rows: auto;
grid-auto-flow: row; // column

grid-column: 1 / 3; // 是一个简写表示: grid-column-start  grid-column-end
grid-column-start: 1;
grid-column-end -1;

grid-row:1 / 3; // 简写: grid-row-start  grid-row-end
grid-row-start: 1;
grid-row-end: 1;

grid-area: 1 / 2 / 2 / 4; // 是一个简写,从左到右:grid-row-start/grid-column-start/grid-row-end/grid-column-end;

// 这是一个命名形式的 布局
grid-template-areas: 
			"b	b	a"
			"b  b   c"
			"b  b   c"
grid-template: ; // 是grid-template-areas 和 grid-template-row 和grid-template-column 的组合简写
```













