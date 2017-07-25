---
categories: ruby
comments: true
date: 2013-07-04T00:00:00Z
title: A simple ruby plugin system
url: /2013/07/a-simple-ruby-plugin-system/
---

Let's start out with a simple directory structure:

``` bash
.
├── plugin.rb
├── main.rb
└── plugins
    ├── cat.rb
    └── dog.rb

1 directory, 3 files
```

All the plugins we will use for our library will be loaded from `plugins`. Now lets make a simple
`Plugin` class and register our plugins.

``` ruby

class Plugin
  # Keep the plugin list inside a set so we don't double-load plugins
  @plugins = Set.new

  def self.plugins
    @plugins
  end

  def self.register_plugins
    # Iterate over each symbol in the object space
    Object.constants.each do |klass|
      # Get the constant from the Kernel using the symbol
      const = Kernel.const_get(klass)
      # Check if the plugin has a super class and if the type is Plugin
      if const.respond_to?(:superclass) and const.superclass == Plugin
        @plugins << const
      end
    end
  end
end

```

We've now made a simple class that will contain all of our plugin data when we call `register_plugins`.

Now for our Dog and Cat classes:

``` ruby
class DogPlugin < Plugin

  def handle_command(cmd)
    p "Command received #{cmd}"
  end

end
```

``` ruby
class CatPlugin < Plugin

  def handle_command(cmd)
    p "Command received #{cmd}"
  end

end
```

Now combine this all together in one main entry point and we have a simple plugin system that lets us
send messages to each plugin through a set method ( `handle_command` ).

``` ruby

require './plugin'
Dir["./plugins/*.rb"].each { |f| require f }
Plugin.register_plugins

# Test that we can send a message to each plugin
Plugin.plugins.each do |plugin|
  plugin.handle_command('test')
end

```

This is a very simple but useful way to make a plugin system to componentize projects like a chat bot for IRC.
