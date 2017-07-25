---
categories: ruby
comments: true
date: 2012-12-25T00:00:00Z
title: 'Rb RFO Status: A Simple System Status Page in Ruby'
url: /2012/12/rb-rfo-status-simple-system-status-page-in-ruby/
---

*Rb RFO Status* is a simple system to post status updates to your team or customers in a easy to understand format so there is no delay in reporting a reason for outage.
It is modeled slightly after the [Heroku Status Page](http://status.heroku.com/).

**Source**: [https://github.com/bluescripts/rb_rfo_status](https://github.com/bluescripts/rb_rfo_status)

**Download**: [https://s3.amazonaws.com/josh-opensource/rb_rfo_status-0.1.war](https://s3.amazonaws.com/josh-opensource/rb_rfo_status-0.1.war)

It is licensed under the *MIT License* so do whatever you want with it!

I've already opened up a few issues on Github that are enhancements, but this serves as a super simple application to deploy to keep your customers and team informed of system states.

## Installation

Download the .war file and deploy it in your favorite container (Tomcat, etc). Once the war file is extracted you can modify the config settings and start it.

To run migrations on an extracted WAR file:

```
cd rb_rfo_status/WEB-INF
sudo RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_GEMFILE=Gemfile GEM_HOME=gems java -cp lib/jruby-core-1.7.1.jar:lib/jruby-stdlib-1.7.1.jar:lib/gems-gems-activerecord-jdbc-adapter-1.2.2.1-lib-arjdbc-jdbc-adapter_java.jar:lib/gems-gems-jdbc-mysql-5.1.13-lib-mysql-connector-java-5.1.13.jar org.jruby.Main -S rake db:migrate
```

## Screenshots

### Homepage

{{< figure src="https://www.evernote.com/shard/s4/sh/dd1aa9b9-cfcf-4257-af11-3d17d3f1e8dd/c7917a5540f04a60eacad189479e799c/res/6a125eeb-21c8-4f96-9ced-21169a89c527/skitch.png" >}}

### Creating an Incident

{{< figure src="https://www.evernote.com/shard/s4/sh/29176e2c-d770-4c6d-a593-369786d9079d/4c564af13979ba3d5e272c836cc830a2/res/bd810786-94fc-4652-86e1-27885f12bad8/skitch.png?resizeSmall&width=832" >}}

### Updating an incident

{{< figure src="https://www.evernote.com/shard/s4/sh/84afb640-b46c-40eb-9b30-00583685b7a5/915d77b53e7755498e1ef98a86c1ee57/res/8eabf163-959c-4f31-bf88-cbeb6d97dc77/skitch.png?resizeSmall&width=832" >}}

### A resolved incident

{{< figure src="https://www.evernote.com/shard/s4/sh/d0449a09-75e1-47bc-8bc9-7073b76bfdaa/7c68e52c97dc1b912c408f9f0c5bded0/res/b077981e-37e0-4e2b-a8e4-abc1ae092033/skitch.png?resizeSmall&width=832" >}}
