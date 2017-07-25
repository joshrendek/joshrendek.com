---
date: 2009-03-31T15:54:54Z
title: Rails remote IP address from behind a proxy
wordpress_id: 198
wordpress_url: http://bluescripts.net/2009/03/rails-remote-ip-address-from-behind-a-proxy/
---

Since I have a cluster of 3 mongrels running behind lighttpd the usualy request.env['REMOTE_ADDR'] wasn't working ...

what ended up working was request.env['HTTP_X_FORWARDED_FOR'] to get the users IP
