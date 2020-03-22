---
title: 'Buffalo, gqlgen, and graphql subscriptions'
date: 2020-03-21T08:46:27-04:00
draft: false
---

Here's a sample application to show how to stitch together Buffalo, gqlgen
and graphql subscriptions. [Github Repo](https://github.com/joshrendek/graphql-subscriptions-example)

I'll go over the important parts here. After generating your buffalo application
you'll need a graphql schema file and a gqlgen config file:

``` graphql
# schema.graphql
type Example {
	message: String
}


type Subscription {
    exampleAdded: Example!
}
```

and your config file:

```yaml 
# gqlgen.yml
struct_tag: json
schema:
- schema.graphql
exec:
  filename: exampleql/exec.go
  package: exampleql
model:
  filename: exampleql/models.go
  package: exampleql
resolver:
  filename: exampleql/resolver.go
  type: Resolver
```


Next lets generate our graphql files: 

```sh
go run github.com/99designs/gqlgen --verbose
```


Now we can open up our `resolver.go` file and add a `New` method to make
creating the handler easier:

```go 
func New() Config {
	return Config{
		Resolvers: &Resolver{},
	}
}
```

Let's also add our resolver implementation:


```go 
func (r *subscriptionResolver) ExampleAdded(ctx context.Context) (<-chan *Example, error) {
	msgs := make(chan *Example, 1)

	go func() {
		for {
			msgs <- &Example{Message: randString(50)}
			time.Sleep(1 * time.Second)
		}
	}()
	return msgs, nil
}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randString(n int) *string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	s := string(b)
	return &s
}
```



Inside your `app.go` file you'll need to add a few handlers and wrap them in
buffalo's handler as well:

``` go

c := cors.New(cors.Options{
	AllowedOrigins:   []string{"http://localhost:3000"},
	AllowCredentials: true,
})

srv := handler.New(exampleql.NewExecutableSchema(exampleql.New()))
srv.AddTransport(transport.POST{})
srv.AddTransport(transport.Websocket{
	KeepAlivePingInterval: 10 * time.Second,
	Upgrader: websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	},
})

app.ANY("/query", buffalo.WrapHandler(c.Handler(srv)))

app.GET("/play", buffalo.WrapHandler(playground.Handler("Example", "/query")))

```

Now if you head over to the playground and run this query:

```graphql 
subscription {
  exampleAdded {
    message
  }
}
```

You should see something like this scrolling by:

<div style='position:relative; padding-bottom:calc(39.43% + 44px)'><iframe src='https://gfycat.com/ifr/TintedQuickJohndory' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe></div>

<br>
Things to note:

* This is not production ready code
* If you were doing something with multiple load balanced nodes you should be
  using something like Redis or NATs pubsub to handle messaging
* This isn't cleaning up channels or doing anything that you should be doing for
  live code
