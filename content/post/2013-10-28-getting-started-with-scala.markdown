---
categories: scala
comments: true
date: 2013-10-28T00:00:00Z
title: Getting started with Scala
url: /2013/10/getting-started-with-scala/
---

Recently I've been getting into more Java and (attempting to) Scala development. I always got annoyed with the Scala ecosystem for development and would get fed up and just go back to writing straight Java (*cough*sbt*cough*). Today I decided to write down everything I did and get a sane process going for Scala development with SBT.

I decided to write a small Scala client for [OpenWeatherMap](http://openweathermap.org) - here is what I went through.

A brief guide on naming conventions is [here](http://docs.scala-lang.org/style/naming-conventions.html). I found this useful just to reference conventions since not everything is the same as Ruby (camelCase vs snake\_case for instance).

## Setting up and starting a project

First make sure you hava a JVM installed, Scala, and SBT. I'll be using Scala 2.10.2 and SBT 0.12.1 since that is what I have installed.

One of the nice things I like about Ruby on Rails is the project generation ( aka: `rails new project [opts]` ) so I was looking for something similar with Scala.

Enter giter8: [https://github.com/n8han/giter8](https://github.com/n8han/giter8)

giter8 runs through SBT and has [templates](http://github.com/n8han/giter8/wiki/giter8-templates) available for quickstart.

Follow the install instructions and install giter8 into SBT globally and load SBT to make sure it downloads and installs.

Once you do that you can pick a template from the list, or go with the one I chose: `fayimora/basic-scala-project` which sets up the directories properly and also sets up [ScalaTest](www.scalatest.org), a testing framework with a DSL similar to RSpec.

To setup your project you need to run:

```
g8 fayimora/basic-scala-project
```

You'll be prompted with several questions and then your project will be made. Switch into that directory and run `sbt test` to make sure the simple HelloWorld passes and everything with SBT is working.

## Setting up IntelliJ

For Java and Scala projects I stick with IntelliJ over my usual vim. When using Java IntelliJ is good about picking up library and class path's and resolving dependencies (especially if you are using Maven). However there isn't a good SBT plugin (as of writing this) that manages to do all this inside IntelliJ.

The best plugin for SBT I've found that does this is [sbt-idea](https://github.com/mpeltonen/sbt-idea). You're going to need to make a `project/plugins.sbt` file:

{{< highlight scala >}}
addSbtPlugin("com.github.mpeltonen" % "sbt-idea" % "1.5.2")
{{< / highlight >}}

and now you can generate your `.idea` files by running: `sbt gen-idea`

IntelliJ should now resolve your project dependencies and you can start coding your project.

## Final Result

[scala-weather](https://github.com/joshrendek/scala-weather) - A simple to use OpenWeatherMap client in Scala set up with Travis-CI and CodeClimate. This is just the first of several projects I plan on working on / open sourcing to get my feet wet with Scala more.

## Useful libraries

* HTTP: [Bee Client](www.bigbeeconsultants.co.uk/bee-client)
* HTTP Mocking: [BetaMax](http://freeside.co/betamax/)
* JSON Parsing: [Json4s](http://json4s.org/)
* Testing: [ScalaTest](http://scalatest.org)
* Logging: [logback](http://logback.qos.ch/)


## Notes
By default Bee Client will log everything to STDOUT - you'll need to configure [logback](http://logback.qos.ch) with an XML file located in `src/main/resources/logback.xml`:

{{< highlight xml >}}
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <root level="ERROR">
        <appender-ref ref="STDOUT" />
    </root>
</configuration>
{{< / highlight >}}
