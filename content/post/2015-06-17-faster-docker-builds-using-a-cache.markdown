---
categories: null
comments: true
date: 2015-06-17T21:30:07Z
title: Faster docker builds using a cache
url: /2015/06/faster-docker-builds-using-a-cache/
---

If you're using bundler for your ruby or rails project and docker you will run into docker having to install your gems everytime. You can either make a base image that has the bundle cache already on it, or you can make a small cache step in your Dockerfile.

Here I've setup a cache user and host to store the cache tar. It will attempt to download and untar it, run `bundle`, then attempt to tar and re-upload it.

``` bash
RUN scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cache@172.17.42.1:~/project.tar.gz . || true
RUN tar xzf project.tar.gz || true
RUN bundle install --deployment --without development test
RUN tar czf project.tar.gz vendor
RUN scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no project.tar.gz cache@172.17.42.1:~/ || true
```

Doing this cut build times for my image from a few minutes to a few seconds. If you have any other tricks for speeding up builds, let me know!
