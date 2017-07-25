---
date: 2012-02-28T00:00:00Z
title: Why the Cloud isn't for your Startup
url: /2012/02/why-the-cloud-isnt-for-your-startup/
---

### The Lure

You're a new startup, you're tight on funds and don't have the server knowledge to run your own servers, but you plan on growing exponentially very quickly. You have three choices:

* Suck it up and learn some sysadmin skills (or hire one)
* Use a PaaS provider (such as EngineYard, Heroku, or EC2)
* Use a mix of both

But how do you know which path to take?

I'll be using my experience running Servly for most of this article. I've been using dedicated servers and virtual machines and the cloud for over 6 years with Servly and other business ventures.

### How valuable is your time when shit hits the fan?

When using services like EC2 and Amazon, you need to be aware that the support levels are different versus a regular dedicated hosting provider. The last time I had a ticket in with Heroku it had taken well over 4 hours to even get a response.

Support with a dedicated server is different. Of the two hosting providers that I've been using ([WooServers](http://wooservers.com) and [Voxel](http://voxel.net/)), I have been given top notch support. Tickets are answered in minutes, and 911's are answered in seconds. Large conglomerate cloud providers just can't beat that service.

There are other considerations to make as well. With traditional cloud offerings (EC2, Rackspace, EngineYard) and dedicated servers you are given root access to the servers, but with Heroku you're locked in to their read-only file system and configuration. You miss out on the ability to tweak your configuration for maximum performance.

With dedicated hardware you can control your infastructure in a much more fine grained way than with a PaaS offering. All of this ties back into support; support that is familiar with the hardware and support that isn't just working for the lowest common denominator in terms of performance based across a massive cloud. With dedicated hardware you get the control and support that one would expect from a paid service, while still being able to customize your system to YOUR needs, and not the needs of the baseline.

### Benchmark like crazy

Besides knowing how your application's innards look you also need to know how it performs. Find bottlenecks, memory leaks, optmizations you can make, database indexes you might be missing, etc.

Servly's main focus is the dashboard, and the API server's use to communicate their status updates. Every ~5 minutes the server gets bombarded with hundreds of concurrent requests all vying for database access.

One of the issues I noticed was the occasional 502 Gateway error. There were two problems:

* Not enough nginx workers
* Not enough unicorn works with a high timeout

There is no magic formula to find out what the right balance is without running your own tests. When I started testing a simple

{{< highlight bash >}}
ab -c 100 -n 1000 http://foobar.servly.com/
{{< / highlight >}}

was returning about 78 failed requests out of 1000. Good, but not good enough.

Editing the nginx configuration several more times I got rid of the writev() failed (107: Transport endpoint is not connected) while sending request to upstream error.  The nginx worker count is now at 16.

The next error was a upstream timeout that would ocassionally happen during that 5 minute burst period. Modifying the number of unicorn slaves to 24, upping the backlog, and tweaking the timeout has reduced all of the gateway errors.

I was now able to scale up from 100-1000 concurrent requests without any failures being reported from ab.

### Scaling on the cloud vs bare metal

For very small projects, or throwaway prototypes, Heroku and other free services are great. However once you're project starts growing, the costs can grow exponentially.

Currently Servly runs on:

* 2.6Ghz Quadcore i5
* 8GB of RAM
* Intel X25 SSD. This provides excellent throughput for both the database and the workers. I also have a spare drive to do backups to (as well as offsite backups).
* Server is hosted at [WooServer](http://wooservers.com/)

I also have a MySQL slave for backups in addition to S3 and several spare VM's running as a standby.

Software wise there are:

* 24 Unicorn slaves
* 10 Background workers
* About 3GB of data is being stored in memory from the database cache


### Cost Comparisons

### Heroku
* 24 Dynos: $827
* 10 Workers: $323
* Fugu Database: $400

Total: $1,587/mo

### Engine Yard
* 1 Extra Large instance

Total: $959

I could've gone with a smaller medium instance, however I need the IO to be as high as possible. Even on this it's still going to be pretty terrible, this also applies to Heroku's offerings as well, since the Fugu database is on the very conservative side and both are layers ontop of Amazon's EC2. [1]

### Dedicated
* 2.6ghz Quadcore i5
* 8GB RAM
* 80GB Intexl X-25 SSD
* 80GB Secondary drive
* 5TB of bandwidth

Total: $145/mo

For the price of running Heroku relatively maxed out on dyno's, I could get 11 dedicated servers. Thats roughly:

* 28Ghz on 44 cores
* 88GB of RAM
* 880GB of SSD storage
* 880GB of backup storage
* 55TB of transfer


### But I don't know anything about servers
Learn. You may stumble at first, but there are plenty of outlets to get help at. You can go on Freenode's IRC, Mailing lists, and Stack Exchange. You could even hire a part time sysadmin. Once you really start scaling the cost of using Heroku versus what you could get with bare metal becomes so great that you could eventually just hire a full time sysadmin to manage your dedicated servers.

### What are others doing?

GitHub was a large player to move from the cloud at EngineYard to a more mixed infastructure of bare metal and spot instances to Rackspace. [2] They were able to get nearly 6x the RAM and nearly 4x the CPU cores; one of their main focal points was cost in addition to control, flexibility, capacity.

There are also plenty of success stories over at Heroku's success page: [http://success.heroku.com/](http://success.heroku.com/)

### What the cloud is good for
Temporary data crunching. Have a sudden spike in your job queue? Crank up some more virtual machines to plow through them, then turn them off to save money. All of this can be automated with tools like Blueprint, Puppet, and Chef.

Backups. With the price of S3 being around 8 cents per  GB, its entirely feasable to back everything up off site for disaster recovery to the cloud.


### Bottom Line
You and your team need to evaluate your business needs and decide on what option is best for your company. If you already have a competent sysadmin or a developer who has played both roles before, it would make much more sense to use bare metal. If no one in your team has the experience, or time, to learn devops, then a PaaS solution like Heroku would be a more logical choice.


[1] [http://www.krenger.ch/blog/amazon-ec2-io-performance/](http://www.krenger.ch/blog/amazon-ec2-io-performance/)

[2] [https://github.com/blog/493-github-is-moving-to-rackspace](https://github.com/blog/493-github-is-moving-to-rackspace)
