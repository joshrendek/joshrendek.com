---
comments: true
date: 2015-09-23T21:30:07Z
title: Getting upstart to log to syslog with tags
url: /2015/09/getting-upstart-to-log-to-syslog-with-tags/
---

I was setting up the ELK stack and had quite a fun time trying to get upstart to log to syslog WITH a log tag ( aka: `my-application` ) so it could be filtered inside Kibana.

Here is a working example for `STDOUT` and `STDERR`:

``` bash
respawn
respawn limit 15 5

start on runlevel [2345]
stop on runlevel [06]

setuid app-user
setgid app-user

script
  # Redirect stdout to syslog
  mkfifo /tmp/app-stdout-fifo
  ( logger -p user.info -t your-app-tag </tmp/app-stdout-fifo & )
  exec 1>/tmp/app-stdout-fifo
  rm /tmp/app-stdout-fifo

  # Redirect stderr to syslog
  mkfifo /tmp/app-stderr-fifo
  ( logger -p user.err  -t your-app-tag </tmp/app-stderr-fifo & )
  exec 2>/tmp/app-stderr-fifo
  rm /tmp/app-stderr-fifo

  exec ./your-app-binary
end script
```

Hope this helps someone else, there as a lot of mis-leading and broken examples on Google & StackOverflow.
