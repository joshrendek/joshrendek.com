---
date: 2009-07-14T21:03:40Z
title: Gem/Rails CRC Error
wordpress_id: 226
wordpress_url: http://bluescripts.net/?p=226
---

<pre>[root@unknown openssl]# gem install rails --verbose
GET 200 OK: http://gems.rubyforge.org/latest_specs.4.8.gz
GET 200 OK: http://gems.rubyforge.org/specs.4.8.gz
Installing gem activesupport-2.3.2
ERROR:  While executing gem ... (Zlib::GzipFile::CRCError)
    invalid compressed data -- crc error</pre>
After about an hour on the rails IRC and talking with a friend over instant messaging about possible issues it ended up boiling down to openssl and openssl-dev not being installed. Install those but you're not done yet.

cd to your ruby directory then go into the ext directory, once in there cd openssl; ruby extconf.rb; make; make install, cd ../; cd zlib; ruby extconf.rb; make; make install

And the shebang line: gem install rails --verbose and you should be all good to go now :)

Hope this helps someone else as google was pretty empty with any "resolved" solutions.
