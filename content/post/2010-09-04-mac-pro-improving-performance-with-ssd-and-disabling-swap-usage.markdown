---
date: 2010-09-04T14:53:34Z
title: 'Mac Pro: Improving Performance with SSD and disabling SWAP usage'
wordpress_id: 374
wordpress_url: http://bluescripts.net/?p=374
---

If you have an SSD and plenty of available memory you should see a significant increase in performance when using this. I have 2x Core i7 - 8GB RAM, ATI Radeon HD 4800 series and a 128GB SSD. I first noticed some issues when a few apps started to slow down (if you can call it that when running with a solid state ;) ) - anyways, the memory management portion of Mac OS X is "special" in the sense that it's horrible.

I would have 6GB of memory free and it would be paging into swap memory and causing read/writes to my SSD. Of course this is bad anyways for a SSD to be used like that, so the solution was to simply turn off swap usage.

For others doing this, make sure you have enough memory, or you'll run into issues. To turn off swap run the following commands in terminal:
<pre>sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
sudo rm /private/var/vm/swapfile*</pre>
Reboot and your done. I keep Activity Monitor running on the side so I can see how much memory is being used so I don't crash, but even with RubyMine open or playing StarCraft II I still usually have at least a GB or two of memory free.

[caption id="attachment_381" align="alignnone" width="637" caption="I set the inactive and free colors the same since they are, in essence, the same for what I want to watch."]<img class="size-full wp-image-381 " title="Activity Monitor" src="http://bluescripts.net/wp-content/uploads/2010/09/Activity-Monitor.jpg" alt="" width="637" height="478" />[/caption]

And here is a shot of my OSX bar and how it looks to show free memory:

<img class="alignnone size-full wp-image-382" title="Dock" src="http://bluescripts.net/wp-content/uploads/2010/09/Dock.jpg" alt="" width="44" height="954" />
