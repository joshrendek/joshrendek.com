---
date: 2011-08-25T00:00:00Z
title: MySQL Slave not syncing after reboot
url: /2011/08/mysql-slave-not-syncing-after-reboot/
---

Earlier today I had a MySQL slave go down for a few hours, which wasn't a big deal. When it was brought back up it wasn't syncing properly:

{{< highlight ruby >}}
Seconds_Behind_Master: NULL
{{< / highlight >}}

Apparently there was an issue with a query that was showing up under LAST_ERROR; running

{{< highlight ruby >}}
STOP SLAVE;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
START SLAVE;
{{< / highlight >}}

fixed the issue and then issued another SHOW SLAVE STATUS\G; and got the correct output:
{{< highlight ruby >}}
Seconds_Behind_Master: 27269
{{< / highlight >}}

About half an hour later the slave was all caught up and replication was working again.
