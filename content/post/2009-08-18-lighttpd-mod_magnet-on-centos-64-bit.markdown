---
date: 2009-08-18T11:20:17Z
title: Lighttpd + mod_magnet on CentOS (64 bit)
wordpress_id: 238
wordpress_url: http://bluescripts.net/?p=238
---

After about an hour of tinkering around on google and in the terminal here is what you need to do:

<pre>
wget http://www.lua.org/ftp/lua-5.1.2.tar.gz
tar xfz lua-5.1.2.tar.gz
cd lua-5.1.2
nano src/Makefile
</pre>

Replace:
<pre> CFLAGS= -O2 -Wall $(MYCFLAGS) </pre>
With:
<pre> CFLAGS= -O2 -Wall -fPIC $(MYCFLAGS) </pre>

<pre>
make linux install

wget http://luaforge.net/frs/download.php/2384/md5-1.0.2.tar.gz
tar xfz md5-1.0.2.tar.gz
cd md5-1.0.2
make
make install
cd ..
wget http://luaforge.net/frs/download.php/1678/luazlib-0.0.1.rar

wget wget http://www.rarlab.com/rar/unrar-3.7.7-centos.gz
gunzip unrar-3.7.7-centos.gz
chmod +x unrar-3.7.7-centos
./unrar-3.7.7-centos x luazlib-0.0.1.rar
cd luazlib-0.0.1
make
make install

export LUA_CFLAGS="-I/usr/local/include"
export LUA_LIBS="-L/usr/local/lib -llua"

cd LIGHTTPD_DIRECTORY
./configure -with-lua
make
make install
</pre>

All done!

Thanks to:
<a href="http://gadelkareem.com/2007/09/17/dynamic-content-caching-using-lighty-mod_magnet-lua/">http://gadelkareem.com/2007/09/17/dynamic-content-caching-using-lighty-mod_magnet-lua/</a> && <a href="http://www.verlihub-project.org/doku.phpid=howto_install_lua_library_on_64_bit">http://www.verlihub-project.org/doku.phpid=howto_install_lua_library_on_64_bit</a>
