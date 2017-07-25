---
categories: golang
comments: true
date: 2015-09-20T21:30:07Z
title: Golang Performance Tips
url: /2015/09/golang-performance-tips/
---

Below is some advice and notes that I wish I had when writing Go to deal with high amounts of requests (20k+/second). Have any extra tips? Leave them in the comments!

## Kernel Tuning

Step 1 is making sure your host OS isn't going to keel over when you start making thousands of requests/second or hammering the CPU.

Update `/etc/sysctl.conf` to have these lines:
``` bash
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 50000
```

`ip_local_port_range` - at the default of 30,000 and not modifying the `tw_reuse` and `tw_recycle` properties, we're effectively limited to 500 connections/second to a server. If this is still not enough you can configure additional IP's on the server and cycle between them.

`tcp_tw_reuse` will re-use an existing connection that is in `TIME-WAIT` for outgoing connections.

`tcp_tw_recycle` enables sockets to be recycled faster once they reach the `TIME-WAIT` state for both incoming and outgoing connections. Make sure you're not running anything through a NAT or this can cause problems with connections.

[Vinent Bernat](http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html) has a great explanation with state diagrams on his blog.

Next up are file descriptors. I prefer defining these in the init or upstart scripts, so you would call `ulimit -n 102400` and then call your go binary in the upstart script that way it is set before running. (Note: this will only work if the user has been properly given permissions to up their limit in `/etc/security/limits.d`.

[Upstart](http://upstart.ubuntu.com/wiki/Stanzas#limit) also provides a mechanism to set file limits in the job stanza.

## Golang Tuning

### Utilizing all CPUs ( < Go 1.5 )

You can use all the go-routines in the world and not use all your CPU cores and threads. In order to let your go program utilize all operating-system level threads, we need to tell the go runtime about them:

``` go
runtime.GOMAXPROCS(runtime.NumCPU())
```

This is no longer necessary as of Go 1.5 and is done automatically.

### Finish what you start

Make sure you call `.Close()` on your responses, and make sure you read the entire body. The documentation for `net/http/response` explicitly says that "it is the caller's responsibility to close Body" and that "neither ReadResponse nor Response.Write ever closes a connection." [net/http/response.go](https://golang.org/src/net/http/response.go)


### Don't be intimidated

You want to do things fast! But your confused by all the options for concurrency in go. Channels? Goroutines? Libraries to manage them? Stick with a simple worker pattern for best results. I've found many libraries that claim to manage concurrency for you (limiting running routines, or providing some interface to queueing jobs) fall short, break, or not utilize all CPU cores.

Here is a simple worker pattern that uses nothing but the standard library:

``` go
tasks := make(chan someDataStruct, 40)
var wg sync.WaitGroup

for i := 0; i < 40; i++ {
	wg.Add(1)
	go func() {
		for data := range tasks {
			// do some work on data
		}
		wg.Done()
	}()
}

// Push to it like this:
tasks <- someData

// Finish like this
close(tasks)
wg.Wait()
```

First, we make a channel containing `someDataStruct` as the type to be sent/received over it. We give it a buffer size of 40. Since we only have 40 routines spinning up, no more than 40 can be worked on at once.

When a caller is trying to push data to this channel and all slots are full, it will block until a slot is free, so keep this in mind and change accordingly if you need to.

Next we make a `WaitGroup` which will wait for all of our goroutines to finish. When we loop 40 times and say `wg.Add(1)` we're telling the `WaitGroup` that we're expecting 40 goroutines, and to wait for them to finish.

Next we iterate over data coming in our `tasks` channel and do some process on it (this is obviously where your program specific logic or function calls go).

When no more data is available on the channel we call `wg.Done()` which tells the `WaitGroup` a routine has finished.

Pushing data is simple by passing an instance of `someDataStruct` into the `tasks` channel.

Almost done! We now want to wait for everything to finish before our program exits. `close(tasks)` marks the channel as closed - and any other callers who try and send to it will get a nice fat error message.

Finally `wg.Wait()` says to wait until all 40 `wg.Done()`'s have been called.

### Errors

One of my favorite things about go is that its fast, real fast. Make sure you test, test, and test some more! Always make sure you fail gracefully (if a HTTP connection failed and you need to re-process a job, for instance) and push jobs back onto their queues when a failure is detected. If you have an unexpected race condition or other errors (run out of file descriptors, etc) go will very quickly churn through your job queue.

### But what about...

There are lots of other considerations, like what you're running this against. On small elasticsearch clusters using these patterns to send data from go daemons to ES, I've been able to hit 50k requests/second with still plenty of room to grow.

You may need to pay extra attention to what libraries your using: how many redis connections can you have open? How many do you need?

Are you using keep-alive connections for HTTP? Is your receiver setup properly (nginx configs, etc)?

Is your MySQL or PostgreSQL server tuned to allow this many connections? Make sure you use connection pooling!

### Lastly: Monitor all the things!

Send your data somewhere. I prefer StatsD, InfluxDB and Grafana for my monitoring stack. There is a ready-to-use go library [quipo/statsd](https://github.com/quipo/statsd) that I haven't had issues with. One important thing to do is throw any data sends into a goroutine otherwise you might notice a slowdown while it tries to send the data.

Whether you use Grafana or anything else, its important to monitor. Without metrics on how your systems are running (ops/s, latency, etc) you have no insight into whether or not new changes have affected the overall throughput of your system.

Have any extra tips? Leave them in the comments below!
