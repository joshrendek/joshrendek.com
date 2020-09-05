---
title: 'Go Buffalo: Adding a 2nd database'
date: 2020-09-04T00:46:27-04:00
draft: false
---

If you need to connect to multiple databases in your buffalo app open up your
`models/models.go` file:

Up at the top add a new var like:

```go 
var YourDB *pop.Connection
```

then in the `init()` func you can connect to it - the important part is to make
sure you call `.Open`:

```go 
	YourDB, err = pop.NewConnection(&pop.ConnectionDetails{
		Dialect: "postgres",
		URL:     envy.Get("EXTRA_DB_URL", "default_url_here"),
	})
	if err != nil {
		log.Fatal(err)
	}
```

That's it! You can now connect to a 2nd database from within your app.
