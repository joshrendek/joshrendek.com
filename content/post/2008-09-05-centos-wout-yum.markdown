---
date: 2008-09-05T11:34:26Z
title: CentOS w/out Yum
wordpress_id: 75
wordpress_url: http://bluescripts.net/?p=75
---

Took me about 20 minutes to figure out why this wasn't working when installing yum:

After you follow the instructions atÂ <a href="http://wiki.centos.org/TipsAndTricks/BrokenVserver">http://wiki.centos.org/TipsAndTricks/BrokenVserver</a>
You get to the part where your trying to install rpm-python. This doesn't work quite as you'd hoped.Â

Error:
<pre>
# rpm -Uvh rpm-python-4.4.2-48.el5.i386.rpm

warning: rpm-python-4.4.2-48.el5.i386.rpm: Header V3 DSA signature: NOKEY, key ID e8562897

error: Failed dependencies:

Â Â  Â  Â  Â rpm = 4.4.2-48.el5 is needed by rpm-python-4.4.2-48.el5.i386

</pre>

So clear all the other RPM's you installed, download these three from the repository (varies if your using 64 bit or i386)

rpm-4.4.2-48.el5.i386.rpm Â  Â  Â  rpm-python-4.4.2-48.el5.i386.rpm

rpm-libs-4.4.2-48.el5.i386.rpm Â

Make sure all these are present then run:
<pre>rpm -Uvh *.rpm</pre>

Â This will install the libs and the RPM update at the same time so the error isn't thrown.</pre>
