---
date: 2010-09-04T15:05:29Z
title: 'Windows 7: Installing CodeWarrior on 64 bit windows'
wordpress_id: 388
wordpress_url: http://bluescripts.net/?p=388
---

We're working with micro-controllers this semester and were told we needed CodeWarrior - the version we use in the lab was version 5.0 so I went ahead and downloaded that for home use (they have a Special free edition for students). BAM. Problem, the wizard would unpack everything then after the copying files step it would say : "The wizard was interupted while installing...." etc. I tried several fixes, one of them involved installing the Windows XP virtual machine, installing it in there, and then copying the files over. No dice, as the DLL's weren't registering and the regserv.bat file they used wasn't working either to install them.

<a href="http://www.freescale.com/webapp/sps/site/prod_summary.jsp?code=CW-SUITE-SPECIAL&amp;nodeId=0127262E703BC5&amp;fpsp=1&amp;tab=Design_Tools_Tab">Solution: find the buried 5.1 version on their website that works on 64 bit windows. None of the forum posts or other articles I found on google had this as a link. http://www.freescale.com/webapp/sps/site/prod_summary.jsp?code=CW-SUITE-SPECIAL&amp;nodeId=0127262E703BC5&amp;fpsp=1&amp;tab=Design_Tools_Tab</a>
