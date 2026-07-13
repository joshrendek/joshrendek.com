---
date: 2008-09-04T08:34:52Z
title: sar command
wordpress_id: 72
wordpress_url: http://bluescripts.net/?p=72
---

I'm always trying to find a good method of monitoring system performance and logging it, but today I ran into a rather strange issue that I couldn't find on google.

sar 0 was returning high idle percentages:
<pre>
# sar -u 0

08:17:29 AM Â  Â  Â  CPU Â  Â  %user Â  Â  %nice Â  %system Â  %iowait Â  Â  %idle

08:17:29 AM Â  Â  Â  all Â  Â  18.11 Â  Â  Â 0.01 Â  Â  11.66 Â  Â  70.22 Â  Â 3549.42
<div>running top didn't produce 3.5k % idle and in fact the system was nearly 98% idle.Â </div>
<div>The quick fix is to simply run</div>
<div></div>
<pre>yum update sysstat</pre>
<div>That fixed the problem immediately on the box I was using.</div>
<div></div>
<div>Hope this helps someone else.</div></pre>
