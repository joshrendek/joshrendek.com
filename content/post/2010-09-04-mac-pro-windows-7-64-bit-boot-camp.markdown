---
date: 2010-09-04T15:00:14Z
title: 'Mac Pro: Windows 7 64 Bit Boot camp'
wordpress_id: 385
wordpress_url: http://bluescripts.net/?p=385
---

After about 3 hours yesterday of banging my head on the desk, andÂ re burningÂ copies of my windows 7 disk thinking it had scratches, it ended up being the boot records that were FUBAR'd. I would go through all the steps, install everything, enter my user information and then it would go into its final and fourth reboot sequence, but would then stop at a black/blank screen with a blinking cursor. If I still had the DVD in it would say "Press any key to boot from the CD or DVD...._" where _ is the blinking cursor that appeared when Windows was really supposed to boot up.

A lot of the Apple forums etc said to reset your RAM, etc, however the REALLY wierd part about this was that inside OSX I could boot into the bootcamp partition withÂ Parallels, but booting into windows normallyÂ wouldn'tÂ work, so I knew the installation was fine.

The problem was with the master boot record. Insert the DVD and boot from it, go to "Repair" and choose the restore from image option(s)... It wouldn't find anything so I just click cancel on that and it brought me to the Repair Menu where it has things like Fix boot records, command prompt, etc. The Fix wizard wasn't working for me, so I had to go into the command prompt and type these commands in:
<pre>Bootrec.exe /FixMbr
Bootrec.exe /FixBoot
Bootrec.exe /RebuildBcd</pre>
Press enter after each one. the /RebuildBcd command complained and said : "Windows installations found: 0" however it said the command completed successfully. Close out of the command prompt, reboot, and enjoy your bootcamp!
