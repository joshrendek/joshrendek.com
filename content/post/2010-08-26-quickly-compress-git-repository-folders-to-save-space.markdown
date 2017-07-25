---
date: 2010-08-26T19:51:13Z
title: Quickly compress git repository folders to save space
wordpress_id: 370
wordpress_url: http://bluescripts.net/?p=370
---

I keep all my Rails stuff in one folder (called apps) and I needed to clean up some disk space to keep my SSD sane, so I wrote this quick little ruby snippet to go through each directory and compress it:
<pre lang="ruby">
#!/usr/bin/env ruby

files = Dir.glob("*")

for f in files
   if File.directory?(f) then
       p `cd #{f}; /usr/local/bin/git gc`
   end
end
</pre>
