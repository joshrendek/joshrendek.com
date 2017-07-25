---
categories: ruby jekyll
comments: true
date: 2012-08-19T00:00:00Z
title: Fixing Psych::SyntaxError when using Jekyll
url: /2012/08/fixing-psych-syntaxerror-when-using-jekyll/
---

I was working on my blog and moving some posts around when I kept getting a Psych::SyntaxError when generating it with Jekyll and ruby 1.9.x. Unfortunately the default stack trace doesn't provide much information on what file was causing the issue, so a quick way to find out is opening up irb:

{% codeblock Example to run in irb - sample.rb lang:ruby %}
require 'yaml'
Dir.foreach("source/_posts").each {|f| YAML.load_file("source/_posts/" + f) unless f == "." || f == ".." }
{% endcodeblock %}
