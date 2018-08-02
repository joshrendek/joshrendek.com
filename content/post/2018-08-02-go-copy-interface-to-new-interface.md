---
title: "Go: Copying an interface to a new interface to unmarshal types"
date: 2018-08-02T08:46:27-04:00
draft: false
---

This is useful if you're building a generic library/package and want to let people pass in types and convert to them/return them.

```
package main

import (
	"encoding/json"
	"fmt"
	"reflect"
)

type Monkey struct {
	Bananas int
}

func main() {
	deliveryChan := make(chan interface{}, 1)
	someWorker(&Monkey{}, deliveryChan)
	monkey := <- deliveryChan
	fmt.Printf("Monkey: %#v\n", monkey.(*Monkey))
}

func someWorker(inputType interface{}, deliveryChan chan interface{}) {
	local := reflect.New(reflect.TypeOf(inputType).Elem()).Interface()
	json.Unmarshal([]byte(`{"Bananas":20}`), local)
	deliveryChan <- local
}
```



<br>
Line 21 is getting the type passed in and creating a new pointer of that struct type, equivalent to `&Monkey{}`

Line 22 should be using whatever byte array your popping off a MQ or stream or something else to send back.
