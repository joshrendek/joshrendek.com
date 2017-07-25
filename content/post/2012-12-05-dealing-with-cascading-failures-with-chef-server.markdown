---
categories: chef ruby
comments: true
date: 2012-12-05T00:00:00Z
title: Dealing with cascading failures with Chef Server
url: /2012/12/dealing-with-cascading-failures-with-chef-server/
---

[Chef](http://www.opscode.com/) is awesome. Being able to recreate your entire environment from a recipe is an inredibly powerful tool, and I had started using Chef a few months ago. When I had initially configured the Chef server I hadn't paid much attention to the couchdb portion of it until I had a chef-server hiccup. Here are a few things to watch out for when running chef-server:

* Setup CouchDB [compaction](http://wiki.apache.org/couchdb/Compaction) - Chef had a CouchDB size of 30+GB (after compaction it was only a few megabytes).
* When resizing instances, make sure you setup RabbitMQ to use a [NODENAME](http://www.rabbitmq.com/configure.html). If you don't you'll run into an issue with RabbitMQ losing the database's that were setup (by default, they're based on hostname... so if you resize a EC2 instance the hostname may change, and you'll either have to do some moving around or manually set the NODENAME to the previous hostname).
* Client's may fail to validate after this - requiring a regeneration of the validation.pem, which is fine since this file is only used for the initial bootstrap of a server.
* Make sure you run your chef recipes you setup (for instance monitoring) on your chef-server.

I hope these tips will be helpful to other people when they run into a Chef/CouchDB/RabbitMQ issue after a server resize or hostname change. Another really helpful place is #chef on freenode's IRC servers.
