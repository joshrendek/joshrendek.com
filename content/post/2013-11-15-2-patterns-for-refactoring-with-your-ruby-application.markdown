---
categories: ruby refactoring
comments: true
date: 2013-11-15T00:00:00Z
title: 2 patterns for refactoring with your ruby application
url: /2013/11/2-patterns-for-refactoring-with-your-ruby-application/
---

When working on a rails application you can sometimes find duplicated or very similar code between two different controllers (for instance a UI element and an API endpoint).
Realizing that you have this duplication there are several things you can do. I'm going to go over how to extract this code out into the
query object pattern <sup>[1](http://www.martinfowler.com/eaaCatalog/queryObject.html)</sup>
and clean up our constructor using the builder pattern <sup>[2](http://en.wikipedia.org/wiki/Builder_pattern)</sup> adapted to ruby.

I'm going to make a few assumptions here, but this should be applicable to any
data access layer of your application. I'm also assuming you're using something like Kaminari for pagination and have a model
for `People`.

``` ruby

def index
  page = params[:page] || 1
  per_page = params[:per_page] || 50
  name = params[:name]
  sort = params[:sort_by] || 'last_name'
  direction = params[:sort_direction] || 'asc'

  query = People
  query = query.where(name: name) if name.present?
  @results = query.order("#{sort} #{direction}").page(page).per_page(per_page)
end

```

So we see this duplicated elsehwere in the code base and we want to clean it up. Lets first start by extracting this out into a new class called `PeopleQuery`.

I usually put these under `app/queries` in my rails application.

``` ruby

class PeopleQuery
  attr_accessor :page, :per_page, :name, :sort, :direction, :query
  def initialize(page, per_page, name, sort, direction)
    self.page = page || 1
    self.per_page = per_page || 50
    self.name = name
    self.sort = sort || 'last_name'
    self.direction = direction || 'asc'
    self.query = People
  end

  def build
    self.query = self.query.where(name: self.name) if self.name.present?
    self.query.order("#{self.sort} #{self.direction}").page(self.page).per_page(self.per_page)
  end
end

```

Now our controller looks like this:

``` ruby

def index
  query = PeopleQuery.new(params[:page], params[:per_page], params[:name], params[:sort], params[:direction])
  @results = query.build
end

```

Much better! We've decoupled our control from our data access object (`People`/ActiveRecord), moved some of the query logic outside of the controller and into
a specific class meant to deal with building it. But that constructor doesn't look very nice. We can do better since we're using ruby.

Our new `PeopleQuery` class will look like this and will use a block to initialize itself instead of a long list of constructor arguments.

```
class PeopleQuery
  attr_accessor :page, :per_page, :name, :sort, :direction, :query
  def initialize(&block)
    yield self
    self.page ||= 1
    self.per_page =|| 50
    self.sort ||= 'last_name'
    self.direction ||= 'asc'
    self.query = People
  end

  def build
    self.query = self.query.where(name: self.name) if self.name.present?
    self.query.order("#{self.sort} #{self.direction}").page(self.page).per_page(self.per_page)
  end
end
```

We yield first to let the caller set the values and then after yielding we set our default values if they weren't passed in. There is another method of doing this
with `instance_eval` but you end up losing variable scope and the constructor looks worse since you have to start passing around the params variable to get access to it, so we're
going to stick with yield.


``` ruby

def index
  query = PeopleQuery.new do |query|
    query.page = params[:page]
    query.per_page = params[:per_page]
    query.name = params[:name]
    query.sort = params[:sort]
    query.direction = params[:direction]
  end
  @results = query.build
end

```

And that's it! We've de-duplicated some code (remember we assumed dummy controller's index method was duplicated elsewhere in an API call in a seperate namespaced controller),
extracted out a common query object, decoupled our controller from ActiveRecord, and built up a nice way to construct the query object using the builder pattern.
