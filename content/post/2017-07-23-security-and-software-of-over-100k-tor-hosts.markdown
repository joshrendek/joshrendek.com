---
categories: null
comments: true
date: 2017-07-23T11:26:57Z
title: Security and Software of over 100k Tor Hosts
draft: true
---

The goal of this project was to start with a base directory (in this case The Hidden Wiki) and start spidering out to discover all reachable Tor servers. Some restrictions were placed on this after a few trial runs:

* Only HTML/JSON was parsed/spidered for more links to follow (no jpegs/xml, etc)
* There were a few skipped websites, noteably: Facebook, Reddit, and a few Blockchain websites due to the amount of spidering/time that would be required
* Limited to 10k visits per host so we wouldn't infinitely keep spidering / some reasonable time frame to finish
* Non `200 OK` status responses were skipped

## Table of Contents

* <a href="#crawl-stats">Crawl Stats</a>
* Software
  * <a href="#top-40">Popular Servers</a>

<a name="crawl-stats"></a>
## Crawl Stats

| Metric | Count |
| ------------- | ------------- |
| Total Hosts | 107,067 |
| Total Scanned Pages | 14,177,383 |
| Total Visited (non-200+) | 17,038,091 |

<a name="top-40"></a>
## Software Stats

### Popular Web Servers

**Total with Server Header:**  15,630

**Total without header:**  91,437

Top 10 (full list of 282 available for download)
{{< highlight bash >}}
nginx | 9619
Apache/2.4.6 (CentOS) OpenSSL/1.0.1e-fips PHP/5.6.30 | 2659
Apache | 1056
nginx/1.6.2 | 249
nginx/1.13.1 | 210
Apache/2.4.10 (Debian) | 161
Apache/2.4.18 (Ubuntu) | 100
Apache/2.2.22 (Debian) | 90
Apache/2.4.7 (Ubuntu) | 82
lighttpd/1.4.31 | 80
FobbaWeb/0.1 | 78
{{< / highlight >}}
[Full list available here](/datasets/2017-07-tor/servers.txt)


Just from the `Server` header we can gather a bunch of useful information:

* 2,659 servers are running a potentially vulnerable OpenSSL version (1.0.1e) [[vulns](https://www.cvedetails.com/vulnerability-list/vendor_id-217/product_id-383/version_id-157548/Openssl-Openssl-1.0.1e.html)] and vulnerable Apache version [[vulns](https://www.cvedetails.com/vulnerability-list/vendor_id-45/product_id-66/version_id-161846/opdos-1/Apache-Http-Server-2.4.6.html)]
* Many servers are leaving the OS tag on, revealing a mix of operating systems. I think it's also a safe assumption to say the same people who would leave fingerprinting on will also be using the OS package of these servers, making it easy to combine both OS vulnerabilities and web server vulnerabilities to combine attack vectors:
  * CentOS
  * Debian
  * Ubuntu
  * Windows
  * Raspbian
  * Amazon Linux
  * Fedora
  * Red Hat
  * Trisquel
  * YellowDog
  * FreeBSD
  * Scientific Linux
  * Vine
* Some people are exposing application servers directly:
  * thin
  * node-static
  * gunicorn
  * Mojolicious
  * WSGI
  * Jetty
  * GlassFish
* Very old versions of IIS (5.0/6.0), Apache (1.3), and Nginx
* Nginx appears to dominate the server share on Tor - just taking the top 2 in account, nginx is at least 3.5x as popular as Apache
