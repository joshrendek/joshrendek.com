---
date: 2010-09-15T12:14:01Z
title: 'Ruby on Rails, NGINX, and Passenger: Setting up the ultimate development environment'
wordpress_id: 409
wordpress_url: http://bluescripts.net/?p=409
---

My office (underneath the desks) is a mess of cables. I have a dual monitor setup for my mac pro, usually having documentation (or a video) on the second screen, and coding going on in my main 28" HANNS-G. I love developing rails applications on my mac because of the tools I have available to me and how easy it is to access them. However I wanted to keep running applications on linux (since thats where they end up going) and doing some other specific linux things.

I have all my programs / apps in a directory called /apps/ and I wanted to use Nginx and the passenger gem to handle everything.

I want to do all my development on my Mac and running the applications on linux. I have a spare Dell Vostro 200 that used to be my gaming desktop that now has CentOS installed on it.

Goals: Lets say I have an application called foobar . When (on my mac) I go to foobar.dev, it should go to my linux box and load the foobar app from nginx+passenger .

To keep everything in sync, I'm going to use NFS and export the directory from my mac to my linux box. Thankfully on mac it is ridiculously easy to setup NFS.

Replace things in caps like XXX and YOURUSERNAME with your information. Obviously if your network is different or mask, change it. I would not do this on a public server. I did this on my private, firewalled home network.

Just add this to /etc/exports:
<pre>/Users/YOURUSERNAME/apps/	-rw -mapall=root -network 192.168.0.0 -mask 255.255.0.0</pre>
You may need to restart NFSD on your mac:
<pre> sudo nfsd restart</pre>
Once your NFS is working you should be able to issue a command:
<pre> showmount -e</pre>
and you'll see your export list.

You can then mount this on your linux box:
<pre>cd /home
mkdir apps
mount -t nfs 192.168.1.XXX:/Users/YOURUSERNAME/apps apps</pre>
Next step you should install WEBMIN. You can this in a few different ways, but for CentOS:
<pre>cd ~
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.520-1.noarch.rpm
rpm -Uvh webmin-1.520-1.noarch.rpm</pre>
Login at https://YOURLINUXIP:10000/. We're going to setup BIND and the DNS server. You could do this without webmin, but webmin lets you do it in a few clicks, and setting up DNS isn't one of my strong points.

Navigate to Servers -> Bind DNS Server.

Click on "Create master zone". Enter "dev" into the domain, so it should look like this:
<p style="text-align: center;"><a href="http://bluescripts.net/wp-content/uploads/2010/09/Webmin-1.520-on-localhost.localdomain-CentOS-Linux-5.5.png"><img class="size-medium wp-image-410   aligncenter" title="Webmin 1.520 on localhost.localdomain (CentOS Linux 5.5)" src="http://bluescripts.net/wp-content/uploads/2010/09/Webmin-1.520-on-localhost.localdomain-CentOS-Linux-5.5-300x65.png" alt="" width="300" height="65" /></a></p>
<p style="text-align: left;">After that hit "Create".</p>
<p style="text-align: left;">Back on the "Module Index", click on the "dev" world icon, and click on Address records. Enter *.dev into the name field and the IP of your linux server, once created it should look like this:</p>
<p style="text-align: center;"><a href="http://bluescripts.net/wp-content/uploads/2010/09/Webmin-1.520-on-localhost.localdomain-CentOS-Linux-5.5-1.png"><img class="size-medium wp-image-413  aligncenter" title="Webmin 1.520 on localhost.localdomain (CentOS Linux 5.5)-1" src="http://bluescripts.net/wp-content/uploads/2010/09/Webmin-1.520-on-localhost.localdomain-CentOS-Linux-5.5-1-300x91.png" alt="" width="300" height="91" /></a></p>
<p style="text-align: left;">Hit "Apply configuration" in the very top right corner and your done with the linux DNS setup.</p>
<p style="text-align: left;">On your Mac, to use the new DNS go to System Preferences -> Network (choose your adapter) -> Advanced -> DNS.</p>
<p style="text-align: left;">I'm using Google DNS but you need to add your new DNS server in there as well. It should look like this when you're done (or similar, depending on your IPs and previous DNS configuration):</p>
<p style="text-align: center;"><a href="http://bluescripts.net/wp-content/uploads/2010/09/System-Preferences.png"><img class="size-medium wp-image-414  aligncenter" title="System Preferences" src="http://bluescripts.net/wp-content/uploads/2010/09/System-Preferences-300x259.png" alt="" width="300" height="259" /></a></p>
<p style="text-align: left;">DNS configuration is done, just to verify you should be able to ping ANYTHING.dev or foobar.dev or blah.dev and it should resolve to your linux server's IP:</p>
<p style="text-align: left;"></p>
<p style="text-align: center;"><a href="http://bluescripts.net/wp-content/uploads/2010/09/ping.png"><img class="size-medium wp-image-415  aligncenter" title="ping" src="http://bluescripts.net/wp-content/uploads/2010/09/ping-300x214.png" alt="" width="300" height="214" /></a></p>
<p style="text-align: left;">On your linux box, go ahead and install ruby, rails, and rubygems. Once you have that running and working, install passenger:</p>
<p style="text-align: left;"></p>

<pre>gem install passenger</pre>
<p style="text-align: left;">Then run the nginx setup:</p>

<pre>passenger-install-nginx-module</pre>
This will install Nginx for you and configure /opt/nginx/conf/nginx.conf for you as well.

I've shrunk my nginx.conf down to this, and modified it to load *.dev as server and host names.
<pre>#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    passenger_root /opt/ruby-enterprise-1.8.7-2010.01/lib/ruby/gems/1.8/gems/passenger-2.2.15;
    passenger_ruby /opt/ruby-enterprise-1.8.7-2010.01/bin/ruby;

    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
	server_name   ~^(www\.)?([-\w\.]+)\.\w+$;
        #charset koi8-r;

        #access_log  logs/host.access.log  main;
       		root   /home/apps/$2/public;
		passenger_enabled on;
		rails_env development;
    }

}</pre>
The important line is <strong>server_name Â  ~^(www\.)?([-\w\.]+)\.\w+$; </strong>This allows you to catch those domains.

My Mac is my database server (it has an SSD and 8 gigs of memory and is backed up, so I keep everything on it). Now I need to let my linux box connect to my mac pro's mysql instance.

I use SequelPro to do my database management, and you need to run the following queries:
<pre>CREATE USER 'root'@'%' IDENTIFIED BY 'YOURPASSWORD';
GRANT ALL PRIVILEGES ON *.* to 'root'@'%' WITH GRANT OPTION;</pre>
Run the query and you should be all set. You can start Nginx and your applications should start running when you go to foobar.dev or yourappname.dev !

I found this took a bit of time to do (although this tutorial should let you do it in a few minutes) but it saves me from having to worry about start/shutting down thin/mongrel's and other stuff on my mac.

Let me know if you have any comments or questions!
