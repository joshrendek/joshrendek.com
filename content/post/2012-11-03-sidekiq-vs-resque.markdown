---
categories: ruby performance jruby ruby mri jvm
comments: true
date: 2012-11-03T00:00:00Z
title: Sidekiq vs Resque, with MRI and JRuby
url: /2012/11/sidekiq-vs-resque/
---

Before we dive into the benchmarks of Resque vs Sidekiq it will first help to have a better understanding of how forking and threading works in Ruby.

# Threading vs Forking

## Forking

When you fork a process you are creating an entire copy of that process: the address space and all open file descriptors. You get a separate copy of the address space of the parent process, isolating any work done to that fork. If the forked child process does a lot of work and uses a lot of memory, when that child exits the memory gets free'd back to the operating system. If your programming language (MRI Ruby) doesn't support actual kernel level threading, then this is the only way to spread work out across multiple cores since each process will get scheduled to a different core. You also gain some stability since if a child crashes the parent can just respawn a new fork, however there is a caveat. If the parent dies while there are children that haven't exited, then those children become zombies.

### Forking and Ruby

One important note about forking with Ruby is that the maintainers have done a good job on keeping memory usage down when forking. Ruby implements a copy on write system for memory allocation with child forks.

{{< highlight ruby >}}
require 'benchmark'

fork_pids = []

# Lets fill up some memory

objs = {}
objs['test'] = []
1_000_000.times do
  objs['test'] << Object.new
end



50.times do
    fork_pids << Process.fork do
        sleep 0.1
    end
end
fork_pids.map{|p| Process.waitpid(p) }
}
{{< / highlight >}}

We can see this in action here:

{{< figure src="/images/showdown/copy_on_write.png" >}}


However when we start modifying memory inside the child forks, memory quickly grows.

{{< highlight ruby >}}
50.times do
    fork_pids << Process.fork do
      1_000_000.times do
        objs << Object.new
      end
    end
end
fork_pids.map{|p| Process.waitpid(p) }
{{< / highlight >}}

We're now creating a million new objects in each forked child:

{{< figure src="/images/showdown/forced_copy_on_write.png" >}}


## Threading

Threads on the other hand have considerably less overhead since they share address space, memory, and allow easier communication (versus inter-process communication with forks). Context switching between threads inside the same process is also generally cheaper than scheduling switches between processes. Depending on the runtime being used, any issues that might occur using threads (for instance needing to use lots of memory for a task) can be handled by the garbage collector for the most part. One of the benefits of threading is that you do not have to worry about zombie processes since all threads die when the process dies, avoiding the issue of zombies.

## Threading with Ruby

As of 1.9 the GIL (Global Interpreter Lock) is gone! But it's only been renamed to the GVL (Global VM Lock). The GVL in MRI ruby uses a lock called ```rb_thread_lock_t``` which is a mutex around when ruby code can be run. When no ruby objects are being touched, you can actually run ruby threads in parallel before the GVL kicks in again (ie: system level blocking call, IO blocking outside of ruby). After these blocking calls each thread checks the interrupt ```RUBY_VM_CHECK_INTS```.

With MRI ruby threads are pre-emptively scheduled using a function called ```rb_thread_schedule``` which schedules an "interrupt" that lets each thread get a fair amount of execution time (every 10 microseconds). [[source: thread.c:1018]](http://svn.ruby-lang.org/cgi-bin/viewvc.cgi/trunk/thread.c?view=markup)

We can see an example of the GIL/GVL in action here:

{{< highlight ruby >}}
threads = []

objs = []
objs['test'] = []
1_000_000.times do
  objs << Object.new
end

50.times do |num|
  threads << Thread.new do
    1_000_000.times do
      objs << Object.new
    end
  end
end

threads.map(&:join)
{{< / highlight >}}

Normally this would be an unsafe operation, but since the GIL/GVL exists we don't have to worry about two threads adding to the same ruby object at once since only one thread can run on the VM at once and it ends up being an atomic operation *(although don't rely on this quirk for thread safety, it definitely doesn't apply to any other VMs)*.

Another important note is that the Ruby GC is doing a really horrible job during this benchmark.

{{< figure src="/images/showdown/threading_leak.png" >}}

The memory kept growing so I had to kill the process after a few seconds.

## Threading with JRuby on the JVM

JRuby specifies the use of native threads based on the operating system support using the ```getNativeThread``` call [[2]](https://github.com/jruby/jruby/blob/master/src/org/jruby/RubyThread.java#L216). JRuby's implementation of threads using the JVM means there is no GIL/GVL. This allows CPU bound processes to utilize all cores of a machine without having to deal with forking (which, in the case of resque, can be *very* expensive).

When trying to execute the GIL safe code above JRuby spits out a concurrency error: ```ConcurrencyError: Detected invalid array contents due to unsynchronized modifications with concurrent users```

We can either add a mutex around this code or modify it to not worry about concurrent access. I chose the latter:

{{< highlight ruby >}}
threads = []

objs = {}
objs['test'] = []
1_000_000.times do
  objs['test'] << Object.new
end

50.times do |num|
  threads << Thread.new do
    1_000_000.times do
      objs[num] = [] if objs[num].nil?
      objs[num] << Object.new
    end
  end
end

threads.map(&:join)
{{< / highlight >}}

Compared to the MRI version, ruby running on the JVM was able to make some optimizations and keep memory usage around 800MB for the duration of the test:

{{< figure src="/images/showdown/jvm_threading.png" >}}

Now that we have a better understanding of the differences between forking and threading in Ruby, lets move on to Sidekiq and Resque.

# Sidekiq and Resque

## Resque's view of the world

Resque assumes chaos in your environment. It follows the forking model with C and ruby and makes a complete copy of each resque parent when a new job needs to be run. This has its advantages in preventing memory leaks, long running workers, and locking. You run into an issue with forking though when you need to increase the amount of workers on a machine. You end up not having enough spare CPU cycles since the majority are being taken up handling all the forking.

Resque follows a simple fork and do work model, each worker will take a job off the queue and fork a new process to do the job.

[Resque @ Github](https://github.com/defunkt/resque)

## Sidekiq's view of the world

Unlike Resque, Sidekiq uses threads and is extremely easy to use as a drop in replacement to Resque since they both work on the same ```perform``` method. When you dig into the results below you can see that Sidekiq's claim of being able to handle a larger number of workers and amount of work is true. Due to using threads and not having to allocate a new stack and address space for each fork, you get that overhead back and are able to do more work with a threaded model.

Sidekiq follows the actor pattern. So compared to Resque which has N workers that fork, Sidekiq has an Actor manager, with N threads and one Fetcher actor which will pop jobs off Redis and hand them to the Manager. Sidekiq handles the "chaos" portion of Resque by catching all exceptions and bubbling them up to an exception handler such as Airbrake or Errbit.

Now that we know how Sidekiq and Resque work we can get on to testing them and comparing the results.

[Sidekiq @ Github](https://github.com/mperham/sideki://github.com/mperham/sidekiq)

# The Test Code

The idea behind the test was to pick a CPU bound processing task, in this case SHA256 and apply it across a set of 20 numbers, 150,000 times.

{{< highlight ruby >}}
require 'sidekiq'
require 'resque'
require 'digest'


# Running:
# sidekiq -r ./por.rb -c 240
#
# require 'sidekiq'
# require './por'
# queueing: 150_000.times { Sidekiq::Client.enqueue(POR, [rand(123098)]*20) }
# queueing: 150_000.times { Resque.enqueue(POR, [rand(123098)]*20) }

class POR
  include Sidekiq::Worker

  @queue = :por

  def perform(arr)
    arr.each do |a|
      Digest::SHA2.new << a.to_s
    end
  end

  def self.perform(arr)
    arr.each do |a|
      Digest::SHA2.new << a.to_s
    end
  end

end
{{< / highlight >}}

# Test Machine

```
      Model Name: Mac Pro
      Model Identifier: MacPro4,1
      Processor Name: Quad-Core Intel Xeon
      Processor Speed: 2.26 GHz
      Number of Processors: 2
      Total Number of Cores: 8
      L2 Cache (per Core): 256 KB
      L3 Cache (per Processor): 8 MB
      Memory: 12 GB
      Processor Interconnect Speed: 5.86 GT/s
```

This gives us a total of 16 cores to use for our testing. I'm also using a [Crucial M4 SSD](http://www.amazon.com/gp/product/B004W2JKZI/ref=as_li_qf_sp_asin_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B004W2JKZI&linkCode=as2&tag=josren-20)


# Results

## Time to Process 150,000 sets of 20 numbers

{{< figure src="/images/showdown/time_to_process.png" >}}


<center>
<table width="100%" style="text-align: center;">
<tr>
<td><strong>Type</strong></td><td><strong>Time to Completion (seconds)</strong></td>
</tr>
<tr>
<td>Sidekiq (JRuby) 150 Threads</td><td>88</td>
</tr>
<tr>
<td>Sidekiq (JRuby) 240 Threads</td><td>89</td>
</tr>
<tr>
<td>Sidekiq (JRuby) 50 Threads</td><td>91</td>
</tr>
<tr>
<td>Sidekiq (MRI) 5x50</td><td>98</td>
</tr>
<tr>
<td>Sidekiq (MRI) 3x50</td><td>120</td>
</tr>
<tr>
<td>Sidekiq (MRI) 50</td><td>312</td>
</tr>
<tr>
<td>Resque 50</td><td>396</td>
</tr>
</table>
</center>

<hr>

## All about the CPU

### Resque: 50 workers

{{< figure src="/images/showdown/resque_50.png" >}}

Here we can see that the forking is taking its toll on the available CPU we have for processing. Roughly 50% of the CPU is being wasted on forking and scheduling those new processes. Resque took 396 seconds to finish and process 150,000 jobs.

### Sidekiq (MRI) 1 process, 50 threads

{{< figure src="/images/showdown/mri_50.png" >}}

We're not fully utilizing the CPU. When running this test it pegged one CPU at 100% usage and kept it there for the duration of the test. We have a slight overhead with system CPU usage. Sidekiq took 312 seconds with 50 threads using MRI Ruby. Lets now take a look at doing things a bit resque-ish, and use multiple sidekiq processes to get more threads scheduled across multiple CPUs.

### Sidekiq (MRI) 3 processes, 50 threads

{{< figure src="/images/showdown/mri_3x50.png" >}}

We're doing better. We've cut our processing time roughly in third and we're utilizing more of our resources (CPUs). 3 Sidekiq processes with 50 threads each (for a total of 150 threads) took 120 seconds to complete 150,000 jobs.

### Sidekiq (MRI) 5 processes, 50 threads

{{< figure src="/images/showdown/mri_5x50.png" >}}

As we keep adding more processes that get scheduled to different cores we're seeing the CPU usage go up even further, however with more processes comes more overhead for process scheduling (versus thread scheduling). We're still wasting CPU cycles, but we're completing 150,000 jobs in 98 seconds.

### Sidekiq (JRuby) 50 threads

{{< figure src="/images/showdown/jruby_50.png" >}}

We're doing much better now with native threads. With 50 OS level threads, we're completing our set of jobs in 91 seconds.

### Sidekiq (JRuby) 150 threads & 240 Threads

{{< figure src="/images/showdown/jruby_150.png" >}}
{{< figure src="/images/showdown/jruby_240.png" >}}

We're no longer seeing a increase in (much) CPU usage and only a slight decrease in processing time. As we keep adding more and more threads we end up running into some thread contention issues with accessing redis and how quickly we can pop things off the queue.


# Overview

Even if we stick with the stock MRI ruby and go with Sidekiq, we're going to see a huge decrease in CPU usage while also gaining a little bit of performance as well.

Sidekiq, overall, provides a cleaner, more object oriented interface (in my opinion) to inspecting jobs and what is going on in the processing queue.

In Resque you would do something like: ``` Resque.size("queue_name") ```. However, in Sidekiq you would take your class, in this case, ```POR``` and call ```POR.jobs``` to get the list of jobs for that worker queue. (note: you need to ``` require 'sidekiq/testing'``` to get access to the jobs method).


The only thing I find missing from Sidekiq that I enjoyed in Resque was the ability to inspect failed jobs in the web UI. However Sidekiq more than makes up for that with the ability to automatically retry failed jobs (although be careful you don't introduce race conditions and accidentally DOS yourself).

And of course, JRuby comes out on top and gives us the best performance and bang for the buck (although your mileage may vary, depending on the task).

# Further Reading

<a href="http://www.amazon.com/gp/product/1934356972/ref=as_li_qf_sp_asin_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1934356972&linkCode=as2&tag=josren-20">Deploying with JRuby: Deliver Scalable Web Apps using the JVM (Pragmatic Programmers)</a><img src="http://www.assoc-amazon.com/e/ir?t=josren-20&l=as2&o=1&a=1934356972" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />

<a href="http://www.amazon.com/gp/product/B005SNJF28/ref=as_li_qf_sp_asin_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B005SNJF28&linkCode=as2&tag=josren-20">JRuby Cookbook</a><img src="http://www.assoc-amazon.com/e/ir?t=josren-20&l=as2&o=1&a=B005SNJF28" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />

# Sidekiq & Resque

[Sidekiq](https://github.com/mperham/sidekiq)

[Resque](https://github.com/defunkt/resque)
