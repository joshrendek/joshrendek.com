---
date: 2009-03-18T21:37:27Z
title: Lighttpd, Mongrel, Ruby on Rails, and Lighttpd Proxy backend Performance Comparison
wordpress_id: 188
wordpress_url: http://bluescripts.net/?p=188
---

First I was kind of surprised at the lack of performance comparisons people have made between the different lighttpd proxies with a rails/mongrel cluster backend and which ones would be best.

Lets start off the the specs of the box:
Intel Atom 330 CPU
Standard 7,200RPM HDD
CentOS 5.2
2GB Ram
Lighttpd with 3 Mongrel Clusters running an online food ordering system I wrote (MySQL + Rails)

Other than that there was nothing special. I've done no kernel tweaking or any other performance optimizations with Lighttpd or any other part of the system.

Result Data	/ Proxy Type /	Result
<h2>Requests Per Second</h2>
<a href="http://bluescripts.net/wp-content/uploads/2009/03/requests-per-second.png"><img class="alignnone size-full wp-image-189" title="requests-per-second lighttpd rails mongrel cluster" src="http://bluescripts.net/wp-content/uploads/2009/03/requests-per-second.png" alt="requests-per-second lighttpd rails mongrel cluster" width="451" height="271" /></a>

Hash	       21.41
Round-Robin	39.73
First	40.07

Hash is the loser in the proxy test over all. The requests per second capabilities of it were nearly half of what Round-Robin and First were able to achieve with the 3 node mongrel cluster running in the background. This is to be expected though since the Hash algorithm (so far as I understand it) will send the same url requests to the same proxy to help caching, whereas round-robin and first proxy methods balance it over the 3 nodes (or however many you have running).
<h2>Total Time Taken</h2>
<a href="http://bluescripts.net/wp-content/uploads/2009/03/time-taken.png"><img class="alignnone size-full wp-image-190" title="time-taken" src="http://bluescripts.net/wp-content/uploads/2009/03/time-taken.png" alt="time-taken" width="451" height="271" /></a>

Hash 	467.20772
Round-Robin	251.725273
First	249.578092

Round-Robin are nearly neck and neck with the total time taken to return 10,000 hits with 250 concurrency, while the hash algorithm still lags far behind.
<h2>Transfer Rate</h2>
<a href="http://bluescripts.net/wp-content/uploads/2009/03/transfer-rate.png"><img class="alignnone size-full wp-image-191" title="transfer-rate" src="http://bluescripts.net/wp-content/uploads/2009/03/transfer-rate.png" alt="transfer-rate" width="451" height="271" /></a>

Hash 	59.74
Round-Robin	110.84
First	111.79

Since only one mongrel cluster is able to serve all the requests in Hash, where as 3 are able to in the Round Robin and First tests, the transfer rate is much higher. I'm sure this could have been improved even further had I put all static files like style sheets and images on a separate instance so Mongrel could just worry about the rails files instead of rails + static, but since this site only has about 5 or so images, I did not think it necessary.
<h2>Longest Request</h2>
<a href="http://bluescripts.net/wp-content/uploads/2009/03/longest-request.png"><img class="alignnone size-full wp-image-192" title="longest-request" src="http://bluescripts.net/wp-content/uploads/2009/03/longest-request.png" alt="longest-request" width="451" height="271" /></a>

Hash 	22795
Round-Robin	17132
First	11936

This is the result data where First comes through, beating Round Robin by a good portion (~6 seconds) and proving to be the quickest to serve up the website.
<h2>Load Averages</h2>
<a href="http://bluescripts.net/wp-content/uploads/2009/03/load-avg.png"><img class="alignnone size-full wp-image-193" title="load-avg" src="http://bluescripts.net/wp-content/uploads/2009/03/load-avg.png" alt="load-avg" width="451" height="271" /></a>

Hash 	1.15
Round-Robin	3.15
First	3.28

Since Hash is only using one mongrel cluster instance, instead of the 3, the CPU load was much lower. However, Round Robin and First were very close, but I believe that when comparing the request times for First and Round Robin, First is worth the <em>very</em> miniscule increase in server load.
<h3>Notes on Apache + Passenger + Mod_Rails + Phusion mumbo jumbo</h3>
I'm not going to claim to be an Apache expert, but one thing I'm positive about is Apache's slowness.... with everything. I go nuts when pages don't load fast because of server software and when I tried out Phusion Passenger / Mod Rails and apache (whatever you want to call it)... even with Enterprise ruby installed, it was still incredibly slow (noticable to me while just randomly hitting refresh).

While Phusion makes deploying rails apps a bit simpler / easier to add new apps, in the long run I view it as detrimental should your application ever grow. The reason I chose to work with mongrel and Lighttpd (although Nginx is another viable option) is because I looked at sites like GitHub and EngineYard (a large rails host) and checked a few of their web server headers and found them to be running Nginx (with a Mongrel backend I'm assuming).

If you're worried about memory I did not notice much of a difference between what my application used while in Phusion vs Mongrel, but one of the <span style="text-decoration: underline;"><strong>HUGE</strong></span> differences I did notice was when running `ab -n 1000 -c 10` the load would shoot up to 5, while Lighttpd's would barely hit .89. I didn't bother attempting `ab -n 10000 -c 250` with apache since I didn't want the box to melt/halt/be-killed-by-apache. If load isn't an issue and you're a die-hard Apache fan, stick with Phusion, but my tests put it <em>way</em> behind Lighttpd+Mongrel in comparison.

~~~~~~~~~~~~~~~~~~~~

If anyone has any suggestions for other analytic's to test let me know! I'd love to do some more research regarding this and post my findings since there seems to be a lack of them on google.

<strong>Proxy: Hash Raw Data</strong>

<pre>
Server Port:            80

Document Path:          /
Document Length:        2495 bytes

Concurrency Level:      250
Time taken for tests:   467.20772 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Total transferred:      28570261 bytes
HTML transferred:       24950000 bytes
Requests per second:    21.41 [#/sec] (mean)
Time per request:       11675.520 [ms] (mean)
Time per request:       46.702 [ms] (mean, across all concurrent requests)
Transfer rate:          59.74 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   3.2      0      35
Processing:    72 11547 1056.2  11694   22795
Waiting:       72 11547 1056.2  11694   22795
Total:         72 11548 1055.2  11694   22795

Percentage of the requests served within a certain time (ms)
  50%  11694
  66%  11717
  75%  11739
  80%  11794
  90%  11887
  95%  11907
  98%  11928
  99%  11942
 100%  22795 (longest request)
</pre>

<strong>Proxy Type: Round Robin Raw Data</strong>
<pre>
Server Port:            80

Document Path:          /
Document Length:        2495 bytes

Concurrency Level:      250
Time taken for tests:   251.725273 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Total transferred:      28570213 bytes
HTML transferred:       24950000 bytes
Requests per second:    39.73 [#/sec] (mean)
Time per request:       6293.132 [ms] (mean)
Time per request:       25.173 [ms] (mean, across all concurrent requests)
Transfer rate:          110.84 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   3.2      0      37
Processing:   103 6192 2439.0   6653   17132
Waiting:      103 6192 2439.0   6653   17132
Total:        103 6192 2438.5   6653   17132

Percentage of the requests served within a certain time (ms)
  50%   6653
  66%   7665
  75%   8169
  80%   8495
  90%   9038
  95%  10066
  98%  10377
  99%  10468
 100%  17132 (longest request)
</pre>

<strong>Proxy Type: First Raw Data</strong>
<pre>
--- Proxy: First 3.28 ---
Server Port:            80

Document Path:          /
Document Length:        2495 bytes

Concurrency Level:      250
Time taken for tests:   249.578092 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Total transferred:      28570190 bytes
HTML transferred:       24950000 bytes
Requests per second:    40.07 [#/sec] (mean)
Time per request:       6239.453 [ms] (mean)
Time per request:       24.958 [ms] (mean, across all concurrent requests)
Transfer rate:          111.79 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   3.3      0      37
Processing:   307 6169 621.6   6256   11936
Waiting:      306 6168 621.7   6256   11936
Total:        307 6169 620.0   6256   11936

Percentage of the requests served within a certain time (ms)
  50%   6256
  66%   6450
  75%   6550
  80%   6598
  90%   6734
  95%   6795
  98%   6858
  99%   6897
 100%  11936 (longest request)
</pre>
