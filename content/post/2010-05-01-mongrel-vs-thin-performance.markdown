---
date: 2010-05-01T14:58:08Z
title: Mongrel vs Thin Performance
wordpress_id: 328
wordpress_url: http://bluescripts.net/?p=328
---

<img class="alignnone" title="Mongrel vs Thin" src="http://bluescripts.net/wp-content/uploads/2010/05/mvt.png" alt="" width="549" height="381" />

Thin won out in pretty much every category showing it can handle a larger volume of traffic faster than mongrel can.
<pre>-------------------------------------
MONGREL

Server Software:        Mongrel
Server Hostname:        127.0.0.1
Server Port:            3000

Document Path:          /
Document Length:        1184 bytes

Concurrency Level:      10
Time taken for tests:   65.020 seconds
Complete requests:      1000
Failed requests:        0
Write errors:           0
Total transferred:      1722107 bytes
HTML transferred:       1184000 bytes
Requests per second:    15.38 [#/sec] (mean)
Time per request:       650.195 [ms] (mean)
Time per request:       65.020 [ms] (mean, across all concurrent requests)
Transfer rate:          25.87 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   2.2      0      60
Processing:   290  647  76.9    618     966
Waiting:      174  599  67.2    576     930
Total:        291  648  77.0    618     968

Percentage of the requests served within a certain time (ms)
  50%    618
  66%    675
  75%    695
  80%    704
  90%    750
  95%    795
  98%    866
  99%    896
 100%    968 (longest request)

-------------------------------------
THIN

Server Software:        thin
Server Hostname:        127.0.0.1
Server Port:            3000

Document Path:          /
Document Length:        1184 bytes

Concurrency Level:      10
Time taken for tests:   53.618 seconds
Complete requests:      1000
Failed requests:        0
Write errors:           0
Total transferred:      1685045 bytes
HTML transferred:       1184000 bytes
Requests per second:    18.65 [#/sec] (mean)
Time per request:       536.184 [ms] (mean)
Time per request:       53.618 [ms] (mean, across all concurrent requests)
Transfer rate:          30.69 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.7      0      17
Processing:    35  534 100.8    512    1115
Waiting:       35  485 110.8    502     879
Total:         36  535 100.9    513    1116

Percentage of the requests served within a certain time (ms)
  50%    513
  66%    549
  75%    570
  80%    577
  90%    657
  95%    710
  98%    799
  99%    880
 100%   1116 (longest request)
</pre>
