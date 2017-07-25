---
categories: security linux
comments: true
date: 2013-02-26T00:00:00Z
title: Why setuid Is Bad and What You Can Do
url: /2013/02/why-setuid-is-bad-and-what-you-can-do/
---

## Why `setuid` is Bad
`setuid` allows a binary to be run as a different user then the one invoking it. For example, ping needs to use low level system interfaces (`socket`, `PF_INET`, `SOCK_RAW`, etc) in order to function properly. We can watch this in action by starting ping in another terminal window ( `ping google.com` ) and then using `strace` to see the syscall's being made:

`sudo strace -p PID` and we get the following:

``` bash
munmap(0x7f329e7ea000, 4096)            = 0stat("/etc/resolv.conf", {st_mode=S_IFREG|0644, st_size=185, ...}) = 0
socket(PF_INET, SOCK_DGRAM|SOCK_NONBLOCK, IPPROTO_IP) = 4
connect(4, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("8.8.8.8")}, 16) = 0
```


We can find all setuid programs installed by issuing the command:

``` bash
sudo find / -xdev \( -perm -4000 \) -type f -print0 -exec ls -l {} \;
```

This will find all commands that have the root setuid bit set in their permission bit.

<a name="top"></a>
#### `setuid` list for a few popular operating systems:

Of particular interest in OpenBSD, where a lot of work was done to remove and switch programs from needing to use setuid/gid permissions. OpenIndiana is the worst offender and has the widest vector for attack.

* [Ubuntu](#ubuntu) (22 binaries)
* [CentOS](#centos) (21 binaries)
* [OpenBSD](#openbsd) (3 binaries)
* [OpenIndiana](#openindiana) (53 binaries)

`setuid` escalation is a common attack vector and can allow unprivileged code to be executed by a regular user, and then escalate itself to root and drop you in on the root shell.

***Here are a few examples:***

#### CVE-2012-0056: Exploiting /proc/pid/mem
[http://blog.zx2c4.com/749](http://blog.zx2c4.com/749) - C code that uses a bug in the way the Linux kernel checked permissions on /proc/pid/mem and then uses that to exploit the su binary to give a root shell.

#### CVE-2010-3847: Exploiting via $ORIGIN and file descriptors
[http://www.exploit-db.com/exploits/15274/](http://www.exploit-db.com/exploits/15274/) - By exploiting a hole in the way the $ORIGIN is checked, a symlink can be made to a program that uses `setuid` and `exec`'d 'to obtain the file descriptors which then lets arbitrary code injection (in this case a call to `system("/bin/bash")`).


More of these can be found at [http://www.exploit-db.com/shellcode/](http://www.exploit-db.com/shellcode/) and just [searching google for `setuid` exploits](https://www.google.com/search?q=setuid+exploits).

So you may not want to completely disable the `setuid` flag on all the binaries for your distribution, but we can turn on some logging to watch when they're getting called and install a kernel patch that will secure the OS and help prevent 0-days that may prey on `setuid` vulnerabilities.

## How to log setuid calls

I will detail the steps to do this on Ubuntu, but they should apply to the other audit daemons on CentOS.

Let's first install auditd: `sudo apt-get install auditd`

Let's open up `/etc/audit/audit.rules`, and with a few tweaks with vim, we can insert the list we generated with find into the audit rule set (explanation of each flag after the jump):
``` bash
# This file contains the auditctl rules that are loaded# whenever the audit daemon is started via the initscripts.
# The rules are simply the parameters that would be passed
# to auditctl.

# First rule - delete all
-D

# Increase the buffers to survive stress events.
# Make this bigger for busy systems
-b 320

# Feel free to add below this line. See auditctl man page

-a always,exit -F path=/usr/lib/pt_chown -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/lib/eject/dmcrypt-get-device -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/lib/dbus-1.0/dbus-daemon-launch-helper -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/lib/openssh/ssh-keysign -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/uuidd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/pppd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/at -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/mtr -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/sudoedit -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/traceroute6.iputils -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chsh -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chfn -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/gpasswd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/newgrp -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/fusermount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/umount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/ping -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/ping6 -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/su -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/mount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
```

``` text
-a: appends the always, and exit rules. This says to always make a log at syscall entry and syscall exit.
-F
     path= says filter to the executable being called
     perm=x says filter on the program being executable
     auid>= says log all calls for users who have a UID above 500 (regular user accounts start at 1000 generally)
     auid!=4294967295 sometimes a process may start before the auditd, in which case it will get a auid of 4294967295
-k passes a filter key that will be put into the record log, in this case its "privileged"
```


So now when we run ping google.com we can see a full audit trail in `/var/log/audit/audit.log`:

``` bash
type=SYSCALL msg=audit(1361852594.621:48): arch=c000003e syscall=59 success=yes exit=0 a0=f43de8 a1=d40488 a2=ed8008 a3=7fffc9c9a150 items=2 ppid=1464 pid=1631 auid=1000 uid=1000 gid=1000 euid=0 suid=0 fsuid=0 egid=1000 sgid=1000 fsgid=1000 tty=pts1 ses=6 comm="ping" exe="/bin/ping" key="privileged"type=EXECVE msg=audit(1361852594.621:48): argc=2 a0="ping" a1="google.com"
type=BPRM_FCAPS msg=audit(1361852594.621:48): fver=0 fp=0000000000000000 fi=0000000000000000 fe=0 old_pp=0000000000000000 old_pi=0000000000000000 old_pe=0000000000000000 new_pp=ffffffffffffffff new_pi=0000000000000000 new_pe=ffffffffffffffff
type=CWD msg=audit(1361852594.621:48):  cwd="/home/ubuntu"
type=PATH msg=audit(1361852594.621:48): item=0 name="/bin/ping" inode=131711 dev=08:01 mode=0104755 ouid=0 ogid=0 rdev=00:00
type=PATH msg=audit(1361852594.621:48): item=1 name=(null) inode=934 dev=08:01 mode=0100755 ouid=0 ogid=0 rdev=00:00
```

## Next steps: Patching and upgrading the kernel with GRSecurity

GRSecurity is an awesome tool in the security-minded system administrators toolbag. It will prevent zero days (like the proc mem exploit explained above [<sup>1</sup>](http://en.wikibooks.org/wiki/Grsecurity/Appendix/Grsecurity_and_PaX_Configuration_Options#Remove_addresses_from_.2Fproc.2F.3Cpid.3E.2F.5Bsmaps.7Cmaps.7Cstat.5D) ) by securing which areas a user can access. A full list can be seen at [http://en.wikibooks.org/wiki/Grsecurity/Appendix/Grsecurity_and_PaX_Configuration_Options](http://en.wikibooks.org/wiki/Grsecurity/Appendix/Grsecurity_and_PaX_Configuration_Options) and [http://en.wikipedia.org/wiki/Grsecurity#Miscellaneous_features](http://en.wikipedia.org/wiki/Grsecurity#Miscellaneous_features), I suggest going through these and seeing if you want to continue with this.

**The following below is for advanced users. Not responsible for any issues you may run into, please make sure to test this in a staging/test environment.**

Here are the steps I followed to install the patch:

``` bash
# Start by downloading the latest kernel
wget http://www.kernel.org/pub/linux/kernel/v3.0/linux-3.2.39.tar.bz2

# Next extract it
tar xjvf linux-3.2.39.tar.bz2
cd linux-3.2.39

# Copy over your current kernel configuration:
cp -vi /boot/config-`uname -r` .config

# Updates the config file to match old config and prompts for any new kernel options.
make oldconfig

# This will make sure only modules get compiled only if they are in your kernel.
make localmodconfig

# Bring up the configuration menu
make menuconfig
```

Once your in the menu config you can browse to the `Security` section and go to `Grsecurity` and enable it. I set the configuration method to automatic and then went to Customize. For example, you can now go to `Kernel Auditing -> Exec logging` to turn on some additional logging to shell activities (**WARNING: this will generate a lot of log activity, decide if you want to use this or not). I suggest going through all of these and reading through their menu help descriptions (when selecting one, press the `?` key to bring up the help**).

Now we'll finish making the kernel and compiling it:

``` bash
# Now we can compile the kernel
make -j2 # where 2 is the # of CPU's + 1

# Install and load the dynamic kernel modules
sudo make modules_install

# Finally install kernel
sudo make install
```

We can now reboot and boot into our GRsecurity patched kernel!


Hopefully this article has provided some insight into what the `setuid` flag does, how it has and can be exploited, and what we can do to prevent this in the future.

Here are a few links to useful books on the subject of shellcode and exploits that I reccomend:

### Below is the list of `setuid` binaries on each OS
<a name="ubuntu"></a>
#### Ubuntu 12.04 LTS (22)
[back to top](#top)
``` bash
-rwsr-xr-x 1 root    root        31304 Mar  2  2012 /bin/fusermount-rwsr-xr-x 1 root    root        94792 Mar 30  2012 /bin/mount
-rwsr-xr-x 1 root    root        35712 Nov  8  2011 /bin/ping
-rwsr-xr-x 1 root    root        40256 Nov  8  2011 /bin/ping6
-rwsr-xr-x 1 root    root        36832 Sep 12 18:29 /bin/su
-rwsr-xr-x 1 root    root        69096 Mar 30  2012 /bin/umount
-rwsr-sr-x 1 daemon  daemon      47928 Oct 25  2011 /usr/bin/at
-rwsr-xr-x 1 root    root        41832 Sep 12 18:29 /usr/bin/chfn
-rwsr-xr-x 1 root    root        37096 Sep 12 18:29 /usr/bin/chsh
-rwsr-xr-x 1 root    root        63848 Sep 12 18:29 /usr/bin/gpasswd
-rwsr-xr-x 1 root    root        62400 Jul 28  2011 /usr/bin/mtr
-rwsr-xr-x 1 root    root        32352 Sep 12 18:29 /usr/bin/newgrp
-rwsr-xr-x 1 root    root        42824 Sep 12 18:29 /usr/bin/passwd
-rwsr-xr-x 2 root    root        71288 May 31  2012 /usr/bin/sudo
-rwsr-xr-x 2 root    root        71288 May 31  2012 /usr/bin/sudoedit
-rwsr-xr-x 1 root    root        18912 Nov  8  2011 /usr/bin/traceroute6.iputils
-rwsr-xr-- 1 root    messagebus 292944 Oct  3 13:03 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
-rwsr-xr-x 1 root    root        10408 Dec 13  2011 /usr/lib/eject/dmcrypt-get-device
-rwsr-xr-x 1 root    root       240984 Apr  2  2012 /usr/lib/openssh/ssh-keysign
-rwsr-xr-x 1 root    root        10592 Oct  5 16:08 /usr/lib/pt_chown
-rwsr-xr-- 1 root    dip        325744 Feb  4  2011 /usr/sbin/pppd
-rwsr-sr-x 1 libuuid libuuid     18856 Mar 30  2012 /usr/sbin/uuidd
```

<a name="centos"></a>
#### CentOS 6.3 (21)
[back to top](#top)
``` bash
-rwsr-xr-x. 1 root root  76056 Nov  5 05:21 /bin/mount-rwsr-xr-x. 1 root root  40760 Jul 19  2011 /bin/ping
-rwsr-xr-x. 1 root root  36488 Jul 19  2011 /bin/ping6
-rwsr-xr-x. 1 root root  34904 Jun 22  2012 /bin/su
-rwsr-xr-x. 1 root root  50496 Nov  5 05:21 /bin/umount
-rwsr-x---. 1 root dbus  46232 Sep 13 13:04 /lib64/dbus-1/dbus-daemon-launch-helper
-rwsr-xr-x. 1 root root  10272 Apr 16  2012 /sbin/pam_timestamp_check
-rwsr-xr-x. 1 root root  34840 Apr 16  2012 /sbin/unix_chkpwd
-rwsr-xr-x. 1 root root  54240 Jan 30  2012 /usr/bin/at
-rwsr-xr-x. 1 root root  66352 Dec  7  2011 /usr/bin/chage
-rws--x--x. 1 root root  20184 Nov  5 05:21 /usr/bin/chfn
-rws--x--x. 1 root root  20056 Nov  5 05:21 /usr/bin/chsh
-rwsr-xr-x. 1 root root  47520 Jul 19  2011 /usr/bin/crontab
-rwsr-xr-x. 1 root root  71480 Dec  7  2011 /usr/bin/gpasswd
-rwsr-xr-x. 1 root root  36144 Dec  7  2011 /usr/bin/newgrp
-rwsr-xr-x. 1 root root  30768 Feb 22  2012 /usr/bin/passwd
---s--x--x. 2 root root 219272 Aug  6  2012 /usr/bin/sudo
---s--x--x. 2 root root 219272 Aug  6  2012 /usr/bin/sudoedit
-rwsr-xr-x. 1 root root 224912 Nov  9 07:49 /usr/libexec/openssh/ssh-keysign
-rws--x--x. 1 root root  14280 Jan 31 06:30 /usr/libexec/pt_chown
-rwsr-xr-x. 1 root root   9000 Sep 17 05:55 /usr/sbin/usernetctl
```

<a name="openbsd"></a>
#### OpenBSD 5.2 (3)
[back to top](#top)
``` bash
-r-sr-xr-x  1 root  bin       242808 Aug  1  2012 /sbin/ping-r-sr-xr-x  1 root  bin       263288 Aug  1  2012 /sbin/ping6
-r-sr-x---  1 root  operator  222328 Aug  1  2012 /sbin/shutdown
```

<a name="openindiana"></a>
#### OpenIndiana 11 (53)
[back to top](#top)
``` bash
-rwsr-xr-x   1 root     bin        64232 Jun 30  2012 /sbin/wificonfig--wS--lr-x   1 root     root           0 Dec 11 15:20 /media/.hal-mtab-lock
-r-sr-xr-x   1 root     bin       206316 Dec 11 21:00 /usr/lib/ssh/ssh-keysign
-rwsr-xr-x   1 root     adm        12140 Jun 30  2012 /usr/lib/acct/accton
-r-sr-xr-x   1 root     bin        23200 Jun 30  2012 /usr/lib/fs/ufs/quota
-r-sr-xr-x   1 root     bin       111468 Jun 30  2012 /usr/lib/fs/ufs/ufsrestore
-r-sr-xr-x   1 root     bin       106964 Jun 30  2012 /usr/lib/fs/ufs/ufsdump
-r-sr-xr-x   1 root     bin        18032 Jun 30  2012 /usr/lib/fs/smbfs/umount
-r-sr-xr-x   1 root     bin        18956 Jun 30  2012 /usr/lib/fs/smbfs/mount
-r-sr-xr-x   1 root     bin        12896 Jun 30  2012 /usr/lib/utmp_update
-r-sr-xr-x   1 root     bin        35212 Jun 30  2012 /usr/bin/fdformat
-r-s--x--x   2 root     bin       188080 Jun 30  2012 /usr/bin/sudoedit
-r-sr-xr-x   1 root     sys        34876 Jun 30  2012 /usr/bin/su
-r-sr-xr-x   1 root     bin        42504 Jun 30  2012 /usr/bin/login
-r-sr-xr-x   1 root     bin       257288 Jun 30  2012 /usr/bin/pppd
-r-sr-xr-x   1 root     sys        46208 Jun 30  2012 /usr/bin/chkey
-r-sr-xr-x   1 root     sys        29528 Jun 30  2012 /usr/bin/amd64/newtask
-r-sr-xr-x   2 root     bin        24432 Jun 30  2012 /usr/bin/amd64/w
-r-sr-xr-x   1 root     bin      3224200 Jun 30  2012 /usr/bin/amd64/Xorg
-r-sr-xr-x   2 root     bin        24432 Jun 30  2012 /usr/bin/amd64/uptime
-rwsr-xr-x   1 root     sys        47804 Jun 30  2012 /usr/bin/at
-r-sr-xr-x   1 root     bin         8028 Jun 30  2012 /usr/bin/mailq
-r-sr-xr-x   1 root     bin        33496 Jun 30  2012 /usr/bin/rsh
-r-sr-xr-x   1 root     bin        68704 Jun 30  2012 /usr/bin/rmformat
-r-sr-sr-x   1 root     sys        31292 Jun 30  2012 /usr/bin/passwd
-rwsr-xr-x   1 root     sys        23328 Jun 30  2012 /usr/bin/atrm
-r-sr-xr-x   1 root     bin        97072 Jun 30  2012 /usr/bin/xlock
-r-sr-xr-x   1 root     bin        78672 Jun 30  2012 /usr/bin/rdist
-r-sr-xr-x   1 root     bin        27072 Jun 30  2012 /usr/bin/sys-suspend
-r-sr-xr-x   1 root     bin        29304 Jun 30  2012 /usr/bin/crontab
-r-sr-xr-x   1 root     bin        53080 Jun 30  2012 /usr/bin/rcp
-r-s--x--x   2 root     bin       188080 Jun 30  2012 /usr/bin/sudo
-r-s--x--x   1 uucp     bin        70624 Jun 30  2012 /usr/bin/tip
-rwsr-xr-x   1 root     sys        18824 Jun 30  2012 /usr/bin/atq
-r-sr-xr-x   1 root     bin       281732 Jun 30  2012 /usr/bin/xscreensaver
-r-sr-xr-x   1 root     bin      2767780 Jun 30  2012 /usr/bin/i86/Xorg
-r-sr-xr-x   1 root     sys        22716 Jun 30  2012 /usr/bin/i86/newtask
-r-sr-xr-x   2 root     bin        22020 Jun 30  2012 /usr/bin/i86/w
-r-sr-xr-x   2 root     bin        22020 Jun 30  2012 /usr/bin/i86/uptime
-rwsr-xr-x   1 root     sys        13636 Jun 30  2012 /usr/bin/newgrp
-r-sr-xr-x   1 root     bin        39224 Jun 30  2012 /usr/bin/rlogin
-rwsr-xr-x   1 svctag   daemon    108964 Jun 30  2012 /usr/bin/stclient
-r-sr-xr-x   1 root     bin        29324 Jun 30  2012 /usr/xpg4/bin/crontab
-rwsr-xr-x   1 root     sys        47912 Jun 30  2012 /usr/xpg4/bin/at
-r-sr-xr-x   3 root     bin        41276 Jun 30  2012 /usr/sbin/deallocate
-rwsr-xr-x   1 root     sys        32828 Jun 30  2012 /usr/sbin/sacadm
-r-sr-xr-x   1 root     bin        46512 Jun 30  2012 /usr/sbin/traceroute
-r-sr-xr-x   1 root     bin        18016 Jun 30  2012 /usr/sbin/i86/whodo
-r-sr-xr-x   1 root     bin        55584 Jun 30  2012 /usr/sbin/ping
-r-sr-xr-x   3 root     bin        41276 Jun 30  2012 /usr/sbin/allocate
-r-sr-xr-x   1 root     bin        37320 Jun 30  2012 /usr/sbin/pmconfig
-r-sr-xr-x   3 root     bin        41276 Jun 30  2012 /usr/sbin/list_devices
-r-sr-xr-x   1 root     bin        24520 Jun 30  2012 /usr/sbin/amd64/whodo
```
