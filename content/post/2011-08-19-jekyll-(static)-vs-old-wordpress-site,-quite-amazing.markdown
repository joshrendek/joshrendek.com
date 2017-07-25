---
date: 2011-08-19T00:00:00Z
title: Jekyll (static) vs old Wordpress site, quite amazing
url: /2011/08/jekyll-(static)-vs-old-wordpress-site,-quite-amazing/
---

One of the interesting things about switching to a static site (even when I had cacheing and everything tuned in WP) is the load times.

### Requests per second
- Wordpress: 9.5
- Jekyll: 182.96

### Time per request
- Wordpress: 2631.395 ms
- Jekyll: 245.954 ms

### Time per request (across all concurrent)
- Wordpress: 105.256 ms
- Jekyll: 5.466 ms

Basically jekyll is about 1000-2000% faster at rendering pages.


Thats about it on what I really cared about... the website now loads blazingly fast and Jekyll is awesome to write in with markdown.
