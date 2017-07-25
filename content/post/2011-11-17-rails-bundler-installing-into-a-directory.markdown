---
date: 2011-11-17T00:00:00Z
title: 'Rails: bundler installing into a directory'
url: /2011/11/rails-bundler-installing-into-a-directory/
---

If you run into an issue with bundler always installing into a directory then you may have accidentily run:

{{< highlight ruby >}}
bundle install foobar
{{< / highlight >}}
and now its installing into foobar.

You can run:
{{< highlight ruby >}}
bundle install --system
{{< / highlight >}}

To go back to installing gems to the system/RVM path.
