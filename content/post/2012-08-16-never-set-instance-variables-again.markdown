---
categories: ruby
date: 2012-08-16T00:00:00Z
title: Never Set Instance Variables Again
url: /2012/08/never-set-instance-variables-again/
---

Tired of doing this on every method in ruby?
{% codeblock lang:ruby %}
class Person
    def initialize(name)
        @name = name
    end
end
{% endcodeblock %}


Use the awesome power of ruby and metaprogramming to auto set method paramters to instance variables:

{% codeblock lang:ruby %}
class Person
    def initialize(name)
        method(__method__).parameters.collect {|x| instance_variable_set("@#{x[1]}", eval(x[1].to_s)) }
    end
end
{% endcodeblock %}

Now you can access your parameters being passed in as instance variables for an object. You can extract this out into a method to apply to all objects or just make a simple extension to include it in files that you wanted to use it in. While this is a trivial example, for methods with longer signatures this becomes a more appealing approach. I'll probably extract this out into a gem and post it here later.
