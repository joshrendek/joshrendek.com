---
categories: go golang
comments: true
date: 2014-06-09T00:00:00Z
title: A useful logger in Go
url: /2014/06/a-useful-logger-in-go/
---

Small function that will print out useful information when invoked:

{{< highlight go >}}
func logMsg(msg string) {
	pc, _, _, _ := runtime.Caller(1)
	caller := runtime.FuncForPC(pc).Name()
	_, file, line, _ := runtime.Caller(0)
	sp := strings.Split(file, "/")
	short_path := sp[len(sp)-2 : len(sp)]
	path_line := fmt.Sprintf("[%s/%s:%d]", short_path[0], short_path[1], line)
	log_string := fmt.Sprintf("[%s]%s %s:: %s", time.Now(), path_line, caller, msg)
	fmt.Println(log_string)
}
{{< / highlight >}}

Sample output:
``` bash
[2014-06-10 01:38:45.812215998 +0000 UTC][src/trex-client.go:15]{main.main}:: checking jobs - finish
[2014-06-10 01:38:47.329650331 +0000 UTC][src/trex-client.go:15]{main.main}:: building package list - start
```
