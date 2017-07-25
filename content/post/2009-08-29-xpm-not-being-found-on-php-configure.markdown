---
date: 2009-08-29T19:48:14Z
title: XPM not being found on php configure
wordpress_id: 254
wordpress_url: http://bluescripts.net/2009/08/xpm-not-being-found-on-php-configure/
---

Just spent the better portion of my day fixing a buggered PHP installation...

The magic line:
--with-mysql --enable-shmop --enable-track-vars --enable-sockets --enable-sysvsem --enable-sysvshm --enable-magic-quotes --enable-mbstring --with-curl --with-mcrypt --with-freetype-dir=/usr --with-exec-dir=/usr/bin --with-mhash=shared --with-pear=/usr/share/pear --with-zlib --with-openssl --with-xml  --enable-gd-native-ttf --with-png --with-zlib --with-zlib-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr --with-gd=/usr

^^ MAKE SURE --with-gd=/usr is at THE END
