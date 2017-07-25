---
date: 2012-07-31T00:00:00Z
title: Upgrading to Mountain Lion and fixing your development environment
url: /2012/07/upgrading/
---

Upgrading to OSX Mountain Lion:

* Download and install the Mountain Lion Command Line Tools
* Download and install the https://github.com/kennethreitz/osx-gcc-installer/downloads/ CLI tools for gcc (no
* Download and install XQuartz

Run:
{{< highlight bash >}}
brew update
brew link autoconf # optional, not always needed
brew install automake # optional, not always needed
brew upgrade
rvm reinstall 1.9.3 --patch falcon
{{< / highlight >}}
