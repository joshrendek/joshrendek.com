---
categories: golang
comments: true
date: 2015-09-19T21:30:07Z
title: Using a custom HTTP Dialer in Go
url: /2015/09/using-a-custom-http-dialer-in-go/
---

Let's make a function to generate an HTTP client for us using a custom dialer:


{{< highlight go >}}
var DefaultDialer = &net.Dialer{}

func GetHttpClient() http.Client {
	tr := &http.Transport{
		Dial:                DefaultDialer.Dial,
	}

	client := http.Client{Transport: tr}
	return client
}
{{< / highlight >}}

Can you spot the bug?

By omitting the Timeout, KeepAlive timeouts in the first example, we've introduced a very subtle bug.

There is also another bug if you don't handle TLS timeouts as well.

[net/Dialer](http://golang.org/pkg/net/#Dialer) has some documentation on this.

Without providing a KeepAlive and a Timeout value, you could end up with connections that hang indefinitely. By omitting the TLS handshake timeout, the daemon would also hang trying to re-negotiate the SSL connection.

In my case this was causing a very random and hard to reproduce issue where the program would hang indefinitely.

Some good debugging tips are using `strace` to see what syscall its stuck in, and if your daemon is running in the foreground, using a `SIGQUIT` signal.

Here is a working version:

{{< highlight go >}}
var DefaultDialer = &net.Dialer{Timeout: 2 * time.Second, KeepAlive: 2 * time.Second}

func GetHttpClient() http.Client {
	tr := &http.Transport{
		Dial:                DefaultDialer.Dial,
		TLSHandshakeTimeout: 2 * time.Second,
}

	client := http.Client{Transport: tr}
	return client
}
{{< / highlight >}}
