---
title: 'Helm: Error: UPGRADE FAILED: "CHARTNAME" has no deployed releases'
date: 2019-03-19T08:46:27-04:00
draft: false
---

If you've been using helm you've inevitably run into a case where a

``` shell
helm upgrade --install
```

 has failed and helm is stuck in a **FAILED** state when you list your deployments.


Try and make sure any old pods are cleared up (ie: if they're OutOfEphemeralStorage or something other error condition).

Next to get around this without doing a `helm delete NAME --purge`:

``` shell
helm rollback NAME REVISION
```

<br>
Where `REVISION` is the failed revision deploy. You can then re-run your upgrade.

This should hopefully go away in Helm 3.
