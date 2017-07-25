---
categories: golang
comments: true
date: 2015-11-02T21:30:07Z
title: 'Docker and ping: sendmsg: Operation not permitted'
url: /2015/11/docker-and-ping-sendmsg-operation-not-permitted/
---

You've raised your file descriptor limits, updated security limits, tweaked your network settings and done everything else in preperation to
launch your shiny new dockerized application.

Then you have performance issues and you can't understand why, it looks to be network related. Alright! Let's see what's going on:

``` bash
ping google.com
unknown host google.com
```

Maybe its DNS related.... Let's try again:

``` bash
ping 8.8.8.8
ping: sendmsg: Operation not permitted
```

That's odd, maybe it's a networking issue outside of our servers. Lets try pinging another host on the subnet:

``` bash
ping 10.10.0.50
ping: sendmsg: Operation not permitted
```

That's even more odd, our other host isn't having network issues at all. Lets try going the other way:

``` bash
ping 10.10.0.49 # the bad host
# Lots of packet loss
```

We're getting a lot of packet loss going from Host B to Host A (the problem machine). Maybe it's a bad NIC?

Just for fun I decided to try and ping localhost/127.0.0.1:

``` bash
ping 127.0.0.1
ping: sendmsg: Operation not permitted
```

That's a new one. What the heck is going on? Now at this point I derped out and didn't think to check `dmesg`. Lets assume you went down the road I went and derped.

What's the different between host A and B? Well, host B doesn't have docker installed!


``` bash
apt-get remove docker-engine; reboot

# .... wait for reboot

ping 127.0.0.1
# working
ping 8.8.8.8
# working
ping google.com
# working
```


``` bash
apt-get install docker-engine
ping 127.0.0.1
ping: sendmsg: Operation not permitted

ping 8.8.8.8
ping: sendmsg: Operation not permitted
```

Okay so it happens when docker is installed. We've isolated it. Kernel bug maybe? Queue swapping around kernels and still the same issue happens.

Fun side note: Ubuntu 14.04 has a kernel bug that prevents booting into LVM or software raided grub. [Launchpad Bug](https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1274320)

Switching back to the normal kernel (3.13) that comes with 14.04, we proceed. Docker bug? Hit up `#docker` on Freenode. Someone mentions checking dmesg and conntrack information.

Lo-and-behold, `dmesg` has tons of these:
``` bash
ip_conntrack: table full, dropping packet
# x1000
```

How does docker networking work? NAT! That mean's `iptables` needs to keep track of all your connections, hence the full message.

If you google the original message you'll see a lot of people telling you to check your iptables rules and ACCEPT/INPUT chains to make sure there isn't anything funky in there. If we combine this knowledge + the dmesg errors, we now know what to fix.

Lets update `sysctl.conf` and reboot for good measure ( you could also apply them with `sysctl -p` but I wanted to make sure everything was fresh. )

``` bash
net.ipv4.netfilter.ip_conntrack_tcp_timeout_established = 54000
net.netfilter.nf_conntrack_generic_timeout = 120
net.netfilter.nf_conntrack_max = 556000
```

Adjust the conntrack max until you hit a stable count (556k worked well for me) and don't get anymore connection errors. Start your shiny new docker application that makes tons of network connections and everything should be good now.

Hope this helps someone in the future, as Google really didn't have a lot of useful information on this message + Docker.
