---
categories: security linux ubuntu
comments: true
date: 2013-01-17T00:00:00Z
title: Securing Ubuntu
url: /2013/01/securing-ubuntu/
---

## Table of Contents
#### [Initial Setup](#initial_setup)
#### [Setting up iptables and Fail2Ban](#iptables_fail2ban)
##### <span style='padding-left: 20px;'></span>[Fail2Ban](#fail2ban)
##### <span style='padding-left: 20px;'></span>[iptables rules](#iptables_rules)
#### [Make shared memory read-only](#shared_memory)
#### [Setting up Bastille Linux](#bastille)
##### <span style='padding-left: 20px;'></span>[Configuring Bastille](#bastille_config)
#### [sysctl hardening](#sysctl)
#### [Setting up a chroot environment](#chroot)
#### [Securing nginx inside the chroot](#nginx)
#### [Extras](#extras)

<a name="initial_setup"></a>
## Initial Setup

Let's login to our new machine and take some initial steps to secure our system. For this article I'm going to assume your username is `ubuntu`.

If you need to, setup your sudoers file by adding the following lines to `/etc/sudoers`:

``` bash
ubuntu ALL=(ALL:ALL) ALL # put this in the "User privilege specification" section
```

Edit your `~/.ssh/authorized_keys` and put your public key inside it. Make sure you can login without a password now once your key is in place.

Open up `/etc/ssh/sshd_config` and make sure these lines exist to secure SSH:

``` bash
# Only allow version 2 communications, version 1 has known vulnerabilities
Protocol 2
# Disable root login over ssh
PermitRootLogin no
# Load authorized keys files from a users home directory
AuthorizedKeysFile  %h/.ssh/authorized_keys
# Don't allow empty passwords to be used to authenticate
PermitEmptyPasswords no
# Disable password auth, you must use ssh keys
PasswordAuthentication no
```

Keep your current session open and restart sshd:

```
sudo service ssh restart
```

Make sure you can login from another terminal. If you can, move on.

Now we need to update and upgrade to make sure all of our packages are up to date and install two pre-requisites for later in the article: build-essential and ntp.

``` bash
sudo apt-get update
sudo apt-get install build-essential ntp
sudo apt-get upgrade
sudo reboot
```

<a name="iptables_fail2ban"></a>
## Setting up iptables and Fail2Ban

<a name="fail2ban"></a>
### Fail2Ban
```
sudo apt-get install fail2ban
```

Open up the fail2ban config and change the ban time, destemail, and maxretry `/etc/fail2ban/jail.conf`:

``` bash
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 3600
maxretry = 2
destemail = ubuntu@yourdomain.com
action = %(action_mw)s

[ssh]

enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 2
```

Now restart fail2ban.

```
sudo service fail2ban restart
```

If you try and login from another machine and fail, you should see the ip in iptables.
```
# sudo iptables -L
Chain fail2ban-ssh (1 references)
target     prot opt source               destination
DROP       all  --  li203-XX.members.linode.com  anywhere
RETURN     all  --  anywhere             anywhere
```


<a name="iptables_rules"></a>
### iptables Rules

Here are my default iptables rules, it opens up port 80 and 443 for HTTP/HTTPS communication, and allows port 22.
We also allow ping and then log all denied calls and then reject everything else. If you have other services you need to run, such as a game server or something else, you'll have to add the rules to open up the ports in the iptables config.

`/etc/iptables.up.rules`
``` text
*filter

# Accepts all established inbound connections
 -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allows all outbound traffic
# You could modify this to only allow certain traffic
 -A OUTPUT -j ACCEPT

# Allows HTTP and HTTPS connections from anywhere (the normal ports for websites)
 -A INPUT -p tcp --dport 443 -j ACCEPT
 -A INPUT -p tcp --dport 80 -j ACCEPT
# Allows SSH connections for script kiddies
# THE -dport NUMBER IS THE SAME ONE YOU SET UP IN THE SSHD_CONFIG FILE
 -A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT

# Now you should read up on iptables rules and consider whether ssh access
# for everyone is really desired. Most likely you will only allow access from certain IPs.

# Allow ping
 -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

# log iptables denied calls (access via 'dmesg' command)
 -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# Reject all other inbound - default deny unless explicitly allowed policy:
 -A INPUT -j REJECT
 -A FORWARD -j REJECT

COMMIT
```

We can load that up into iptables:
``` bash
sudo iptables-restore < /etc/iptables.up.rules
```

Make sure it loads on boot by putting it into the if-up scripts:
`/etc/network/if-up.d/iptables`
``` bash
#!/bin/sh
iptables-restore /etc/iptables.up.rules
```

Now make it executable:
``` bash
chmod +x /etc/network/if-up.d/iptables
```

Rebooting here is optional, I usually reboot after major changes to make sure everything boots up properly.

If you're getting hit by scanners or brute-force attacks, you'll see a line similar to this in your `/var/log/syslog`:
```
Jan 18 03:30:37 localhost kernel: [   79.631680] iptables denied: IN=eth0 OUT= MAC=04:01:01:40:70:01:00:12:f2:c6:e8:00:08:00 SRC=87.13.110.30 DST=192.34.XX.XX LEN=64 TOS=0x00 PREC=0x00 TTL=34 ID=57021 DF PROTO=TCP SPT=1253 DPT=135 WINDOW=53760 RES=0x00 SYN URGP=0
```

<a name="shared_memory"></a>
## Read only shared memory

A common exploit vector is going through shared memory (which can let you change the UID of running programs and other malicious actions). It can also be used as a place to drop files once an initial breakin has been made. An example of one such exploit is available [here](http://www.juniper.net/security/auto/vulnerabilities/vuln17587.html).

Open `/etc/fstab/`:
``` bash
tmpfs     /dev/shm     tmpfs     defaults,ro     0     0
```

Once you do this you need to reboot.

<a name="bastille"></a>
## Setting up Bastille Linux

> The Bastille Hardening program "locks down" an operating system, proactively configuring the system for increased security and decreasing its susceptibility to compromise. Bastille can also assess a system's current state of hardening, granularly reporting on each of the security settings with which it works.

`Bastille: Installation and Setup`
``` bash
sudo apt-get install bastille # choose Internet site for postfix
# configure bastille
sudo bastille
```

After you run that command you'll be prompted to configure your system, here are the options I chose:

<a name="bastille_config"></a>
### Configuring Bastille
* File permissions module: Yes (suid)
* Disable SUID for mount/umount: Yes
* Disable SUID on ping: Yes
* Disable clear-text r-protocols that use IP-based authentication? Yes
* Enforce password aging? No (situation dependent, I have no users accessing my machines except me, and I only allow ssh keys)
* Default umask: Yes
* Umask: 077
* Disable root login on tty's 1-6: No
* Password protect GRUB prompt: No (situation dependent, I'm on a VPS and would like to get support in case I need it)
* Password protect su mode: Yes
* default-deny on tcp-wrappers and xinetd? No
* Ensure telnet doesn't run? Yes
* Ensure FTP does not run? Yes
* display authorized use message? No (situation dependent, if you had other users, Yes)
* Put limits on system resource usage? Yes
* Restrict console access to group of users? Yes (then choose root)
* Add additional logging? Yes
* Setup remote logging if you have a remote log host, I don't so I answered No
* Setup process accounting? Yes
* Disable acpid? Yes
* Deactivate nfs + samba? Yes (situation dependent)
* Stop sendmail from running in daemon mode? No (I have this firewalled off, so I'm not concerned)
* Deactivate apache? Yes
* Disable printing? Yes
* TMPDIR/TMP scripts? No (if a multi-user system, yes)
* Packet filtering script? No (we configured the firewall previously)
* Finished? YES! & reboot

You can verify some of these changes by testing them out, for instance, the SUID change on ping:

`Bastille: Verifying changes`
``` bash
ubuntu@app1:~$ ping google.com
ping: icmp open socket: Operation not permitted
ubuntu@app1:~$ sudo ping google.com
PING google.com (74.125.228.72) 56(84) bytes of data.
64 bytes from iad23s07-in-f8.1e100.net (74.125.228.72): icmp_req=1 ttl=55 time=9.06 ms
^C
--- google.com ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 9.067/9.067/9.067/0.000 ms
```

<a name="sysctl"></a>
## Sysctl hardening

Since our machine isn't running as a router and is going to be running as an application/web server, there are additional
steps we can take to secure the machine. Many of these are from the NSA's security guide, which you can read in its entirety
[here](http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf).

`/etc/sysctl.conf http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf Source`
``` bash
# Protect ICMP attacks
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Turn on protection for bad icmp error messages
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Turn on syncookies for SYN flood attack protection
net.ipv4.tcp_syncookies = 1

# Log suspcicious packets, such as spoofed, source-routed, and redirect
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disables these ipv4 features, not very legitimate uses
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Enables RFC-reccomended source validation (dont use on a router)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Make sure no one can alter the routing tables
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Host only (we're not a router)
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0


# Turn on execshild
kernel.exec-shield = 1
kernel.randomize_va_space = 1

# Tune IPv6
net.ipv6.conf.default.router_solicitations = 0
net.ipv6.conf.default.accept_ra_rtr_pref = 0
net.ipv6.conf.default.accept_ra_pinfo = 0
net.ipv6.conf.default.accept_ra_defrtr = 0
net.ipv6.conf.default.autoconf = 0
net.ipv6.conf.default.dad_transmits = 0
net.ipv6.conf.default.max_addresses = 1

# Optimization for port usefor LBs
# Increase system file descriptor limit
fs.file-max = 65535

# Allow for more PIDs (to reduce rollover problems); may break some programs 32768
kernel.pid_max = 65536

# Increase system IP port limits
net.ipv4.ip_local_port_range = 2000 65000

# Increase TCP max buffer size setable using setsockopt()
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 87380 8388608

# Increase Linux auto tuning TCP buffer limits
# min, default, and max number of bytes to use
# set max to at least 4MB, or higher if you use very high BDP paths
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1
```

After making these changes you should reboot.

<a name="chroot"></a>
## Setting up a chroot environment

We'll be setting up a chroot environment to run our web server and applications in. Chroot's provide isolation from the rest of the operating system, so even in the event of a application compromise, damage can be mitigated.

`chroot: Installation and Setup`
``` bash
sudo apt-get install debootstrap dchroot
```
Now add this to your `/etc/schroot/schroot.conf` file, precise is the release of Ubuntu I'm using, so change it if you need to:

`/etc/schroot/schroot.conf`
``` bash
[precise]
description=Ubuntu Precise LTS
location=/var/chroot
priority=3
users=ubuntu
groups=sbuild
root-groups=root
```

Now bootstrap the chroot with a minimal Ubuntu installation:

``` bash
sudo debootstrap --variant=buildd --arch amd64 precise /var/chroot/ http://mirror.anl.gov/pub/ubuntu/
sudo cp /etc/resolv.conf /var/chroot/etc/resolv.conf
sudo mount -o bind /proc /var/chroot/proc
sudo chroot /var/chroot/
apt-get install ubuntu-minimal
apt-get update

```

Add the following to `/etc/apt/sources.list` inside the chroot:
``` bash
deb http://archive.ubuntu.com/ubuntu precise main
deb http://archive.ubuntu.com/ubuntu precise-updates main
deb http://security.ubuntu.com/ubuntu precise-security main
deb http://archive.ubuntu.com/ubuntu precise universe
deb http://archive.ubuntu.com/ubuntu precise-updates universe
```



Let's test out our chroot and install nginx inside of it:
``` bash
apt-get update
apt-get install nginx
```


<a name="nginx"></a>
## Securing nginx inside the chroot


First thing we will do is add a www user for nginx to run under:
`Adding a application user`
``` bash
sudo chroot /var/chroot
useradd www -d /home/www
mkdir /home/www
chown -R www.www /home/www
```

Open up `/etc/nginx/nginx.conf` and make sure you change user to www inside the chroot:
``` bash
user www;
```

We can now start nginx inside the chroot:
``` bash
sudo chroot /var/chroot
service nginx start
```

Now if you go to http://your_vm_ip/ you should see "Welcome to nginx!" running inside your fancy new chroot.

We also need to setup ssh to run inside the chroot so we can deploy our applications more easily.

`Chroot: sshd`
``` bash
sudo chroot /var/chroot
apt-get install openssh-server udev
```

Since we already have SSH for the main host running on 22, we're going to run SSH for the chroot on port 2222. We'll copy over our config from outside the chroot to the chroot.

`sshd config`
``` bash
sudo cp /etc/ssh/sshd_config /var/chroot/etc/ssh/sshd_config
```

Now open the config and change the bind port to 2222.

We also need to add the rules to our firewall script:
`/etc/iptables.up.rules`
``` bash
# Chroot ssh
 -A INPUT -p tcp -m state --state NEW --dport 2222 -j ACCEPT
```

Now make a startup script for chroot-precise in `/etc/init.d/chroot-precise:
`/etc/init.d/chroot-precise`
``` bash
mount -o bind /proc /var/chroot/proc
mount -o bind /dev /var/chroot/dev
mount -o bind /sys /var/chroot/sys
mount -o bind /dev/pts /var/chroot/dev/pts
chroot /var/chroot service nginx start
chroot /var/chroot service ssh start
```

Set it to executable and to start at boot:
``` bash
sudo chmod +x /etc/init.d/chroot-precise
sudo update-rc.d chroot-precise defaults
```

Next is to put your public key inside the `.ssh/authorized_keys` file for the www user inside the chroot so you can ssh and deploy your applications.

If you want, you can test your server and reboot it now to ensure nginx and ssh boot up properly. If it's not running right now, you start it: `sudo /etc/init.d/chroot-precise`.

You should now be able to ssh into your chroot and main server without a password.

<a name="extras"></a>
## Extras

I would like to also mention the [GRSecurity kernel patch](http://grsecurity.net/). I had tried several times to install this (two different versions were released while I was writing this) and both make the kernel unable to compile. Hopefully they'll fix these bugs and I'll be able to update this article with notes on setting GRSecurity up as well.


I hope this article proved useful to anyone trying to secure a Ubuntu system, and if you liked it please share it!
