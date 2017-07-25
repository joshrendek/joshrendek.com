---
categories: null
comments: true
date: 2013-08-25T00:00:00Z
published: false
title: Notes on Scala and Play! coming from Ruby and Rails
url: /2013/08/notes-on-scala-and-play-coming-from-ruby-and-rails/
---

Make sure you have a `~/.sbtconfig` with the following:

```
SBT_OPTS="-XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:PermSize=256M -XX:MaxPermSize=512M"
```


### Building SBT packages locally from source:

Clone the repo:

```
git clone https://github.com/debasishg/scala-redis.git
```

Run `sbt` and setup your pgp keyring to publish:

```
set pgpReadOnly := false
pgp-cmd gen-key # fill out all the prompts
publish-local # install to local ivy
```


Using it locally with Play! is easy - Open up your project `Build.scala` and make sure your dependencies look somewhat like:

```
val appDependencies = Seq(
    jdbc,
    anorm,
    "net.debasishg" %% "redisclient" % "2.10"
  )
```

### Build.scala dependencies not showing up in IntelliJ?

You'll need to run the idea plugin from play everytime you add a dependency:

```
play idea
```

And this will update your IntelliJ project to add the dependency resolution.
