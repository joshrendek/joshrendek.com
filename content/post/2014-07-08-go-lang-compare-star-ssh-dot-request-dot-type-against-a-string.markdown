---
categories: go golang security
comments: true
date: 2014-07-08T00:00:00Z
title: Go-lang compare *ssh.Request.Type against a string
url: /2014/07/go-lang-compare-star-ssh-dot-request-dot-type-against-a-string/
---

I was working on the agent for [SSH Pot](http://sshpot.com/) and ran into something interesting last night. A lot of the brute force attempts attempt to run a command like this:

``` bash
ssh user@host 'uname'
```

This is different than:


``` bash
ssh user@host
$ uname
```

The first command is executing a command then exiting, the second is actually logging in and giving the user a shell. The first requests a exec subsystem and the second requests a shell subsystem - so there are two ways to handle it.


{{< highlight go >}}
func HandleShellRequest(channel ssh.Channel, in <-chan *ssh.Request) {
	for req := range in {
		ok := true
		logfile.Println("[request " + req.Type + "]: " + string(req.Payload))
		switch req.Type {
		case "shell":
			req.Reply(ok, nil)
		case "exec":
			if string(req.Payload) == string("uname") {
				channel.Write([]byte("\n\rLinux\n\r"))
			}

			channel.Close()
		}
	}
}
{{< / highlight >}}

When logging in my logfile it would show something like:

``` bash
[request exec]: uname
```

And even when comparing the two side by side with something like this:

{{< highlight go >}}
logfile.Println("["+string(req.Payload)+"]:["+"uname"+"]")
{{< / highlight >}}

I would get this output:

``` bash
[uname]:[uname]
```

Yet the comparison on line 9 would not get hit. After sitting and thinking about it for a while I decided to print the bytes out:

``` bash
INFO: 2014/07/07 23:15:18 sshd.go:157: [0 0 0 5 117 110 97 109 101]
INFO: 2014/07/07 23:15:18 sshd.go:158: [117 110 97 109 101]
```

Aha! So for some reason req.Payload is padded with 3 null bytes and a ENQ byte (hex 5).

Here is the corrected version removing the correct bytes - now the string comparison works:


{{< highlight go >}}
func HandleShellRequest(channel ssh.Channel, in <-chan *ssh.Request) {
	for req := range in {
		ok := true
		logfile.Println("[request " + req.Type + "]: " + string(req.Payload))
		switch req.Type {
		case "shell":
			req.Reply(ok, nil)
		case "exec":
			if string(req.Payload[4:]) == string("uname") {
				channel.Write([]byte("\n\rLinux\n\r"))
			}

			channel.Close()
		}
	}
}
{{< / highlight >}}
