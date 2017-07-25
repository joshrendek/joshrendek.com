---
categories: golang
comments: true
date: 2015-10-12T21:30:07Z
title: Influx Alert
url: /2015/10/influx-alert/
---

I've been very happy using InfluxDB with Grafana + StatsD but always wanted a nice way to alert on some of the data being fed into statsd/grafana so I wrote a little tool in Go to accomplish that:

Github: [https://github.com/joshrendek/influx-alert](https://github.com/joshrendek/influx-alert)

I hope someone finds this useful! It's got a few simple functions/comparisons done already and support for HipChat and Slack notifications.

# Documentation

## Influx Alert

This is a tool to alert on data that is fed into
InfluxDB (for example, via statsd) so you can get alerted on it.

## How to get it

Go to releases, or download the latest here: [v0.1](https://github.com/joshrendek/influx-alert/releases/download/0.1/influx-alert)

## How to Use

* `name`: the name of the alert ( will be used in notifier )
* `interval`: how often to check influxdb (in seconds)
* `timeshift`: how far back to go (query is like: `where time > now() - TIMESHIFT`
* `limit`: the max number of results to return
* `type`: influxdb (the only option for now)
* `function`: min/max/average are the only supported functions for now
* `query`: the influxdb query to run (omit any limit or where clause on the time)
* `trigger`: the type of trigger and value that would trigger it
  * `operator`: gt/lt
  * `value`: value to compare against (note all values are floats internally)
* `notifiers`: an array of notifiers, possible options are slack and hipchat

Example: ( see example.yml for more )

``` yaml
- name: Not Enough Foo
  type: influxdb
  function: average
  timeshift: 1h
  limit: 10
  interval: 10
  query: select * from "foo.counter"
  notifiers:
      - slack
      - hipchat
      - foobar
  trigger:
    operator: lt
    value: 10
```

## Environment Variables

``` bash
  * INFLUX_HOST
  * INFLUX_PORT (8086 is default)
  * INFLUX_DB
  * INFLUX_USER
  * INFLUX_PASS
  * SLACK_API_TOKEN
  * SLACK_ROOM
  * HIPCHAT_API_TOKEN
  * HIPCHAT_ROOM_ID
  * HIPCHAT_SERVER (optional)
  * DEBUG (optional)
```

## Supported Notifiers

* HipChat ( hosted and private servers )
* Slack ( Generate slack token: https://api.slack.com/web )

## Supported Backends

* InfluxDB v0.9
