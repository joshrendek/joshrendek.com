---
date: 2010-09-05T22:01:34Z
title: CentOS GCC not found + other weird errors after hdd cloned
wordpress_id: 401
wordpress_url: http://bluescripts.net/?p=401
---

A week or so ago the HDD started failing on my web server, so I had the DC clone the HDD for me. Some files however got lost in transit (bad sectors) and when I was trying to install nginx to get some testing done, I kept getting this error:

<pre>./configure
C compiler not found
</pre>

Apparently it wasn't finding GCC, even though it was definitely installed. After looking around a bit at the system and talking with a few people on IRC #linux, found out that some header files and other files were missing from /usr/include. Here is an example of some of the errors  I got with a simple hello world C++ program:

<pre lang="cpp">
[root@dispersion ~]# cat test.cpp
#include <iostream>

using namespace std;

int main(){ cout << "hello wolrd " << endl;  return 0; }
[root@dispersion ~]# gcc test.cpp
In file included from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/x86_64-redhat-linux/bits/os_defines.h:39,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/x86_64-redhat-linux/bits/c++config.h:1202,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/iostream:43,
                 from test.cpp:1:
/usr/include/features.h:329:25: error: sys/cdefs.h: No such file or directory
In file included from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/cstdlib:71,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/bits/stl_algobase.h:67,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/bits/char_traits.h:46,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/ios:45,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/ostream:44,
                 from /usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/iostream:44,
                 from test.cpp:1:
/usr/include/stdlib.h:438:49: error: sys/types.h: No such file or directory
/usr/include/string.h:28: error: â€˜__BEGIN_DECLSâ€™ does not name a type
/usr/include/string.h:44: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:51: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:59: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:63: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:67: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:73: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:78: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:84: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:89: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:93: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:96: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:100: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:103: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:107: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:111: error: expected initializer before â€˜__THROWâ€™
/usr/include/xlocale.h:28: error: expected constructor, destructor, or type conversion before â€˜typedefâ€™
/usr/include/xlocale.h:40: error: expected constructor, destructor, or type conversion before â€˜;â€™ token
/usr/include/string.h:121: error: â€˜__locale_tâ€™ has not been declared
/usr/include/string.h:122: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:125: error: â€˜__locale_tâ€™ has not been declared
/usr/include/string.h:125: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:131: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:139: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:167: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:171: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:177: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:184: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:189: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:192: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:195: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:200: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:205: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:212: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:218: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:227: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:233: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:236: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:242: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:249: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:256: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:281: error: expected constructor, destructor, or type conversion before â€˜externâ€™
/usr/include/string.h:288: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:293: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:296: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:300: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:304: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:308: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:312: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:317: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:320: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:326: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:330: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:337: error: â€˜__locale_tâ€™ has not been declared
/usr/include/string.h:338: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:341: error: â€˜__locale_tâ€™ has not been declared
/usr/include/string.h:342: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:350: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:356: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:359: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:363: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:365: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:371: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:374: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:377: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:380: error: expected initializer before â€˜__THROWâ€™
/usr/include/string.h:387: error: expected initializer before â€˜__THROWâ€™
/usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/cstring:78: error: expected constructor, destructor, or type conversion before â€˜namespaceâ€™
/usr/lib/gcc/x86_64-redhat-linux/4.1.2/../../../../include/c++/4.1.2/x86_64-redhat-linux/bits/gthr.h:33: error: expected declaration before end of line
[root@dispersion ~]#
</pre>

The solution was to go to another server (which I have several) of the same architecture, and SCP (or rsync, take your pick) the /usr/include directory over.

Problem solved.
