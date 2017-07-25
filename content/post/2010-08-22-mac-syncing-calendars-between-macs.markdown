---
date: 2010-08-22T12:45:16Z
title: 'MAC: Syncing Calendars between mac''s'
wordpress_id: 362
wordpress_url: http://bluescripts.net/?p=362
---

I work when I'm at home on my mac pro, but when I have to go places I want to use my mac book pro but make sure all my calendar information is up to date. After Google'ing around a bit, i found some applications but they were $50+ so here are few easy steps to sync from one computer to another for iCal:

Step 1: Get your other computer's IP address, and make sure SSH login is enabled

Step 2: Sync your SSH keys so you dont' have to type your password everytime:
<pre>scp ~/.ssh/id_rsa.pub USERNAME@192.168.1.3:~/.ssh/authorized_keys</pre>

Step 3: rsync your calendar data over
<pre>rsync -avz /Users/USERNAME/Library/Calendars/ USERNAME@192.168.1.3:/Users/USERNAME/Library/Calendars/</pre>

Step 4: crontab -e (to edit your crontab)
<pre>01 * * * * USERNAME rsync -avz /Users/USERNAME/Library/Calendars/ USERNAME@192.168.1.3:/Users/USERNAME/Library/Calendars/</pre>

And done, this will sync your calendar every hour to your other mac from your main computer
