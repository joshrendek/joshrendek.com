---
date: 2012-04-04T00:00:00Z
title: MySQL Performance tuning constant references vs index merges and intersects
url: /2012/04/mysql-performance-tuning-constant-references-vs-index-merges-and-intersects/
---

I had a query that, after adding indexes, was taking anywhere from 1.5 to 5ms to return on my local machine. In production and staging environments it was taking 500+ms to return.

The query was producing different optimizer paths:

### The good optimizer:
{{< highlight ruby >}}
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: activities
         type: ref
possible_keys: index_activities_on_is_archived,index_activities_on_equipment_id,index_activities_on_date_completed,index_activities_on_shop_id
          key: index_activities_on_shop_id
      key_len: 5
          ref: const
         rows: 1127
     filtered: 100.00
        Extra: Using where
{{< / highlight >}}

### The bad optimizer:
{{< highlight ruby >}}
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: activities
         type: index_merge
possible_keys: index_activities_on_is_archived,index_activities_on_equipment_id,index_activities_on_date_completed,index_activities_on_shop_id
          key: index_activities_on_shop_id,index_activities_on_is_archived
      key_len: 5,2
          ref: NULL
         rows: 1060
        Extra: Using intersect(index_activities_on_shop_id,index_activities_on_is_archived); Using where
{{< / highlight >}}

My first thought was it might have been the MySQL versions since I was running 5.5 locally and 5.0 in production, but that turned out not to be the case.

Next was to make sure my database was an exact replica of the one in production. After ensuring this I still ended up with the same results from the optimizer.

My last guess was server configuration. The issue ended up being query-cacheing being turned off in production and staging but not on my local machine. Turning this  on, restarted mysqld, and re-running the query produced the good optmizer results on both my local machine and production.
