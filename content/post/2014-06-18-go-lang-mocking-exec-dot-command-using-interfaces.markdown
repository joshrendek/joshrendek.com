---
categories: go golang
comments: true
date: 2014-06-18T00:00:00Z
title: 'Go-lang: mocking exec.Command using interfaces'
url: /2014/06/go-lang-mocking-exec-dot-command-using-interfaces/
---

This is a short example showing how to use an interface to ease testing, and how to use an interface with running shell commands / other programs and providing mock output.

<center>
<a href="https://github.com/joshrendek/go-exec-mock-example">Source on Github</a>
</center>

Here is our main file that actually runs the commands and prints out "hello".

{{< highlight go >}}
package main

import (
	"fmt"
	"os/exec"
)

// first argument is the command, like cat or echo,
// the second is the list of args to pass to it
type Runner interface {
	Run(string, ...string) ([]byte, error)
}

type RealRunner struct{}

var runner Runner

// the real runner for the actual program, actually execs the command
func (r RealRunner) Run(command string, args ...string) ([]byte, error) {
	out, err := exec.Command(command, args...).CombinedOutput()
	return out, err
}

func Hello() string {
	out, err := runner.Run("echo", "hello")
	if err != nil {
		panic(err)
	}
	return string(out)
}

func main() {
	runner = RealRunner{}
	fmt.Println(Hello())
}
{{< / highlight >}}

Here is our test file. We start by defining our `TestRunner` type and implementing the `Run(...)` interface for it.

This function builds up a command to run the current test file and run the `TestHelperProcess` function passing along all the args you originally sent. This lets you do things like return different output for different commands you want to run.

The `TestHelperProcess` function exits when run in the context of the test file, but runs when specified in the files arguments.

{{< highlight go >}}
package main

import (
	"fmt"
	"os"
	"os/exec"
	"testing"
)

type TestRunner struct{}

func (r TestRunner) Run(command string, args ...string) ([]byte, error) {
	cs := []string{"-test.run=TestHelperProcess", "--"}
	cs = append(cs, args...)
	cmd := exec.Command(os.Args[0], cs...)
	cmd.Env = []string{"GO_WANT_HELPER_PROCESS=1"}
	out, err := cmd.CombinedOutput()
	return out, err
}

func TestHello(t *testing.T) {
	runner = TestRunner{}
	out := Hello()
	if out == "testing helper process" {
		t.Logf("out was eq to %s", string(out))
	}
}

func TestHelperProcess(*testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}
	defer os.Exit(0)
	fmt.Println("testing helper process")
}
{{< / highlight >}}

Hopefully this helps someone else! I had a hard time finding some good, short examples on the internet that combined both interfaces and mocking like this.

<center>
<a href="http://golang.org/src/pkg/os/exec/exec_test.go">More examples from os/exec/exec_test.go</a>
</center>
