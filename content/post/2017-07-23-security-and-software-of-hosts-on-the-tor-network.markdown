---
categories: null
comments: true
date: 2017-07-23T11:26:57Z
title: Security and Software of hosts on the Tor Network
---

The goal of this project was to start with a base directory (in this case The Hidden Wiki) and start spidering out to discover all reachable Tor servers. Some restrictions were placed on this after a few trial runs:

* Only HTML/JSON was parsed/spidered for more links to follow (no jpegs/xml, etc)
* There were a few skipped websites, noteably: Facebook, Reddit, and a few Blockchain websites due to the amount of spidering/time that would be required
* Limited to 10k visits per host so we wouldn't infinitely keep spidering / some reasonable time frame to finish
* Non `200 OK` status responses were skipped

# Table of Contents

* <a href="#stack">Stack & Tools</a>
* <a href="#crawl-stats">Crawl Stats</a>
* <a href="#security-headers">Security Headers</a>
* Software
  * <a href="#source-code">Source Code Hosting</a>
  * <a href="#build-servers">Build Servers</a>
  * <a href="#top-40">Popular Servers</a>
* <a href="#summary">Summary</a>

<a name="stack"></a>
# Stack & Tools

I used a few different tools to build this out:

* HA Proxy to load balance between `tor` SOCKs proxies so multiple could be run at the same time to saturate a network link
* Redis to store state information about visits
* Golang for the spidering
* Postgres for data storage

This was all run on a single dedicated server over the period of about 1 week, multiple prototypes ran before that to flush out bugs.

<a name="crawl-stats"></a>
# Crawl Stats

| Metric | Count |
| ------------- | ------------- |
| Total Hosts | 107,067 |
| Total Scanned Pages | 14,177,383 |
| Total Visited (non-200+) | 17,038,091 |

<a name="security-headers"></a>
# Security Headers

| Technology | % using |
| --- | --- |
| Content Security Policy (CSP) | 0.15% |
| Secure Cookie | 0.01% |
| -- httpOnly | 0% |
| Cross-origin Resource Sharing (CORS) | 0.07% |
| -- Subresource Integrity (SRI) | 0% |
| **Public Key Pinning (HPKP)** | 0.01% |
| **Strict Transport Security (HSTS)** | 0.11% |
| X-Content-Type-Options (XCTO) | 0.52% |
| X-Frame-Options (XFO)| 0.58% |
| X-XSS-Protection | 0% |

Some of these headers are interesting when viewed through a Tor light. HSTS and HPKP for example, can be used for super cookies and tracking (although tor does protect against this across new identities) [(source)](https://www.torproject.org/projects/torbrowser/design/).

Services implementing CORS also help protect users by preventing cookie finger printing via scripts and other malicious finger printing methods.

# Software Stats

We can fingerprint and figure out exposed software by taking a look at a few different signatures, like cookies and headers. There are other methods to fingerprint using the response body but due to server restrictions and time I couldn't save every single page source, so the results based on headers/titles are below:

<a name="source-code"></a>
## Source code hosting

| Software | Type | Identifier |
| --------- | ---- |--------- |
| Gitea | Cookie | `i_like_gitea` [[src](https://github.com/go-gitea/gitea/blob/0b177574c92b2f8c4a4d0d9de01ff1bf5eda06a2/modules/setting/setting.go#L1247)] |
| GitLab | Cookie | `gitlab_session` [[src](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/initializers/session_store.rb#L13)]|
| Gogs | Forked version has header | `X-Clacks-Overhead: GNU Terry Pratchett` from NotABug.org |


<a name="build-servers"></a>
## Build Servers

I'm going to focus on build servers because I think this is the most easy to breach front. Not only has Jenkins had some serious RCE's in the past, it is very helpful in identifying itself with headers and debug information as seen below. People also generally store sensitive information in build servers as well, such as SSH keys and cloud provider credentials.

{{< highlight bash >}}
| X-Jenkins-Session: 8965d09b
| X-Instance-Identity: MIIBIjANBgkqhkiG9w0BAQEFAA.....
| Server: Jetty(9.2.z-SNAPSHOT)
| X-Xss-Protection: 1
| X-Jenkins: 2.60.1
| X-Jenkins-Cli-Port: 46689
| X-Content-Type-Options: nosniff nosniff
| X-Frame-Options: sameorigin sameorigin
| X-Hudson-Theme: default
| X-Jenkins-Cli2-Port: 46689
| Referrer-Policy: same-origin
| Content-Type: text/html;charset=UTF-8
| X-Hudson: 1.395
| X-Hudson-Cli-Port: 46689
| Set-Cookie: JSESSIONID.112b5e69=16uts5qfqz6j....Path=/;Secure;HttpOnly
{{< /highlight >}}

We can get Jenkins version, CLI ports, and Jetty versions all from just visiting the host.


| Software | Type | Identifier |
| --------- | ---- |--------- |
| Jenkins | Headers | `X-Jenkins-` and `X-Hudson-` style headers |
| GitLab | Cookie | `gitlab_session` |
| Gocd | Cookie Path / Title | Generally sets a cookie path at `/go` and uses `- Go` in `<title>` tags |
| Drone | Title | Sets a ` drone` title |

Unfortunately I was unable to find any exposed Gocd or Drone servers.

## Software Tracking

| Software | Type | Identifier |
| --------- | ---- |--------- |
| Trac | Cookie | `trac_session` |
| Redmine | Cookie | `redmine_session` |

I was not able to find any running BugZilla, Mantis or OTRS instances.

<a name="top-40"></a>
## Popular Web Servers

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


<a name="summary"></a>
# Summary

This was a fun project to work on and I learned quite a bit about scaling up the tor binary in order to scan the network faster. I'm hoping to make this process a bit less manual and start publishing these results regularly over at my security data website, [https://hnypots.com](https://hnypots.com)

Have any suggestions for other software to look for? Leave a comment and let me know!
