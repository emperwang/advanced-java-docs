# go switch 语句

## switch语法

```go
switch expr {
    case expression, expression...:{
    }
    case expression, expression...:{
    }
    ...
    default: {
    }
}

var a int = 10
switch {
    case a >0 && a<10>...:{
    }
    case expression, expression...:{
    }
    ...
    default: {
    }
}


// type switch
switch x.(type){
    case type1: {
    }

    case type2: {
    }

    default: {

    }
}

```