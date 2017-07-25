---
date: 2011-06-15T00:27:20Z
title: 'Ruby on Rails: Averaging Large Data Sets'
url: /2011/06/ruby-on-rails-averaging-large-data-sets/
wordpress_id: 472
wordpress_url: http://bluescripts.net/?p=472
---

Graphing objects client side is a great way to avoid generating them server side (since client side scales infinitely). You do however run into issue when you get into thousands, or hundreds of thousands of points (for example displaying 5 minute intervals in a month: 8928). When graphing this many points javascript can hang or cause the browser to seem like its not responding.

This is a simple solution that I've been using for a while to average data points from a Active Record model:
{{< highlight ruby >}}
def generic_graph(column, hours, multiplier = 1)
    beginning = Time.now.advance(:hours => -hours)
    x = YourModel.where("created_at > ?", beginning
    arr = []
    timeoffset = Time.zone.utc_offset/(60*60)
    Time.now.dst? ? timeoffset += 1 : 0

    if hours >= 48 #or whatever number works for you
      x.collect.each_with_index do |s,y|
        tmp_averaged = x[y..y+24].map{|ss| ss[column] } # collect 24 (or however many you want) records, then average them
        arr << [s.created_at.advance(:hours=>timeoffset).to_i*1000, tmp_averaged.average] # this is for going into the flot.js graphing library
      end
    else
      x.collect { |s| arr << [s.created_at.advance(:hours=>timeoffset).to_i*1000, s[column] ] }
    end

    arr.to_s #output for flot
  end
{{< / highlight >}}
