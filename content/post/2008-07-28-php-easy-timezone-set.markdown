---
date: 2008-07-28T21:09:04Z
title: PHP easy timezone set
wordpress_id: 17
wordpress_url: http://bluescripts.net/?p=17
---

Here is a quick way to set a timezone:

<span style="font-family: courier,monospace;"> <php putenv('TZ=America/New_York'); ></span>

A list of timezones for php: <a href="http://www.theprojects.org/dev/zone.txt" target="_blank">http://www.theprojects.org/dev/zone.txt</a>

To get the timezones into a file quickly:

wget http://www.theprojects.org/dev/zone.txt

cat zone.txt | awk '{ print $3}' >> timezones.txt

Remove the first few lines and you have an easily read file that you can make a selection box out of.
