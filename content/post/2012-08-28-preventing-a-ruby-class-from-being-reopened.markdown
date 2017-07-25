---
categories: ruby
comments: true
date: 2012-08-28T00:00:00Z
title: Preventing a ruby class from being reopened
url: /2012/08/preventing-a-ruby-class-from-being-reopened/
---

I saw the question of "How can I prevent a class from being reopened again in Ruby?" pop up on the Ruby mailing list. While this is somewhat against the nature of ruby, it can be accomplished:

{% codeblock lang:ruby %}
class Foo
  def Foo.method_added(name)
    raise "This class is closed for modification"
  end
end

class Foo
  def testing
    p "test"
  end
end
{% endcodeblock %}

This will raise an exception anytime someone tries to reopen the class.
