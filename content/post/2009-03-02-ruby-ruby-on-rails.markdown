---
date: 2009-03-02T23:04:41Z
title: Ruby & Ruby on Rails
wordpress_id: 181
wordpress_url: http://bluescripts.net/2009/03/ruby-ruby-on-rails/
---

I've decided to finally tackle learning rails by developing my next project in it.

However I was setting up Ruby/Rails when trying to run gem install rails returned this error:

/usr/local/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in
`gem_original_require': no such file to load -- zlib (LoadError)

After I ran yum install zlib* and hit yes to the devel libraries, went back to ruby source, did make clean, ./configure, make, make install then switched to the ruby gem source and ran ruby setup.rb and then gem install rails worked fine.
