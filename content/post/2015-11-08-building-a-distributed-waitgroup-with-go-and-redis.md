---
categories: golang
comments: true
date: 2015-11-08T21:30:07Z
title: Building a distributed WaitGroup with Go and Redis
url: /2015/11/building-a-distributed-waitgroup-with-go-and-redis/
---

If you've done any concurrency work in Go you've used WaitGroups. They're awesome!

Now lets say you have a bunch of workers that do some stuff, but at some point they all need to hit a single API that your rate limited against.

You could move to just using a single process and limiting it that way, but that doesn't scale out very well.

While there are quite a few distributed lock libraries in Go, I didn't find any that worked similarly to WaitGroups, so I set out to write one.

( If you just want the library, head on over to Github [https://github.com/joshrendek/redis-rate-limiter](https://github.com/joshrendek/redis-rate-limiter) )

Design goals:

* Prevent deadlocks
* Hard limit on concurrency (dont accidentally creep over)
* Keep it simple to use
* Use redis
* Keep the design similar to `sync.WaitGroup` by using Add() and Done()

Initially I started off using `INCR`/`DECR` with `WATCH`. This somewhat worked but was causing the bucket to over-flow and go above the limit I defined.

Eventually I found the `SETNX` command and decided using a global lock with that around adding was the way to go.

So the final design goes through this flow for Add():

1. Use SETNX to check if a key exists; loop until it doesn't error (aka the lock is available for acquiring)
2. Immediately add an expiration to the lock key once acquired so we don't deadlock
3. Check the current number of workers running; wait until it is below the max rate
4. Generate a uuid for the worker lock, use this to SET a key and also add to a worker set
5. Set an expiration on the worker lock key based on uuid so the worker doesn't deadlock
6. Unlock the global lock from SETNX by deleting the key
7. Clean old, potentially locked workers

Removing is much simpler with Done():

1. Delete the worker lock key
2. Remove the worker lock from the worker set

For (1) we want to make sure we don't hammer Redis or the CPU - so we make sure we can pass an option for a sleep duration while busy-waiting.

(2) Prevents the global lock from stalling out if a worker is cancelled in the middle of a lock acquisition.

Waiting for workers in (3) is done by making sure the cardinanality ( `SCARD` ) of the worker set is less than the worker limit. We loop and wait until this count goes down so we don't exceed our limit.

(4) and (5) uses a UUID library to generate a unique id for the worker lock name/value. This gets added via `SADD` to the wait group worker set and also set as a key as well.
We set a key with a TTL based on the UUID so we can remove it from the set via another method if it no longer exists.

(6) frees the global lock allowing other processes to acquire it while they wait in (1).

To clear old locks in (7) we need to take the members in the worker set and then query with `EXISTS` to see if the key still exists.
If it doesn't exist but it is still in the set, we know something bad happened. At this point we need to remove it from the
worker set so that the slot frees up. This will prevent worker deadlocks from happening if it fails to reach the Done() function.

The `Add()` function returns a UUID string that you then pass to `Done(uuid)` to remove the worker locks. I think this was the simplest approach for doing this however if you have other ideas let me know!

That's it! We now have a distributed wait group written in go as a library. You can see the source and how to use it over at [https://github.com/joshrendek/redis-rate-limiter](https://github.com/joshrendek/redis-rate-limiter).
