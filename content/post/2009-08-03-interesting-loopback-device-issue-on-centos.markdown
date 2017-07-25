---
date: 2009-08-03T19:03:17Z
title: Interesting Loopback Device issue on CentOS
wordpress_id: 229
wordpress_url: http://bluescripts.net/2009/08/interesting-loopback-device-issue-on-centos/
---

Was playing around with using the loopback devices to mount some OS images on CentOS and following the losetup followed by a mount command would indeed mount the image, but umount wouldn't unmount it and would leave it stagnant, leaving me with this error:

<pre>ioctl: LOOP_CLR_FD: Device or resource busy</pre>

Interestingly enough though the lomount command
<pre>lomount -diskimage OS.img -partition 1  /MOUNTFOLDER</pre>
and then using umount to unmount the mountfolder would unmount the loopback device properly and free it for re-use.

Hope this helps someone!
