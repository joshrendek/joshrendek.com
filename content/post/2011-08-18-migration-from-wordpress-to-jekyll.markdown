---
date: 2011-08-18T00:00:00Z
title: Migration from WordPress to Jekyll
url: /2011/08/migration-from-wordpress-to-jekyll/
---

While I love WordPress - I think it was a bit of overkill for what I was doing on this blog so I converted everything to Jekyll, and threw all my images up on Amazon's S3. I've also migrated all the comments over to Disqus.

One of the problems I ran into was getting the URLs to map the same; the _config.yml that worked for me was:



{{< highlight ruby >}}
pygments: true
markdown: rdiscount
permalink: /:year/:month/:title
paginate: 10
{{< / highlight >}}

And then to get my /apps/ working again I made a directory structure like this:
{{< highlight ruby >}}
apps//bluebug:
BlueBug.zip	index.markdown

apps//greenmail:
index.markdown

apps//light_logify:
index.markdown

apps//pyultradns:
index.markdown

apps//quote-of-the-day-tweeter:
index.markdown

apps//rails_rrdtool:
index.markdown

apps//server-setup-fu:
index.markdown

apps//servly:
index.markdown

apps//ventrilo-ping-analyzer:
index.markdown

{{< / highlight >}}

Some nice helper scripts I've found:

### Creating a new post

{{< highlight ruby >}}
#!/usr/bin/env ruby

# Script to create a jekyll blog post using a template. It takes one input parameter
# which is the title of the blog post
# e.g. command:
# $ ./new.rb "helper script to create new posts using jekyll"
#
# Author:Khaja Minhajuddin (http://minhajuddin.com)

# Some constants
TEMPLATE = "template.markdown"
TARGET_DIR = "_posts"

# Get the title which was passed as an argument
title = ARGV[0]
# Get the filename
filename = title.gsub(' ','-')
filename = "#{ Time.now.strftime('%Y-%m-%d') }-#{filename.downcase}.markdown"
filepath = File.join(TARGET_DIR, filename)

# Create a copy of the template with the title replaced
new_post = File.read(TEMPLATE)
new_post.gsub!('TITLE', title);

# Write out the file to the target directory
new_post_file = File.open(filepath, 'w')
new_post_file.puts new_post
new_post_file.close

puts "created => #{filepath}"

{{< / highlight >}}

### Publishing a new post
{{< highlight ruby >}}
jekyll && rsync -avz -e 'ssh -p SSHPORT' --delete . USERNAME@DOMAIN.com:/home/YOURPATH/
{{< / highlight >}}
