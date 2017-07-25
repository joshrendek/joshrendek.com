---
date: 2009-02-06T12:13:42Z
title: Setting up a Development Machine With PHP, Lighty, Ruby, and Python
wordpress_id: 144
wordpress_url: http://bluescripts.net/?p=144
---

After getting my new mac book pro I had an extra laptop sitting around... so why not turn it into a little low power development box My goal is to get LigHTTPD, Ruby on Rails, PHP, MySQL, and Python to work together with lighty.

Step 1: Install Lighty
<div class="console">wget http://www.lighttpd.net/download/lighttpd-1.4.20.tar.gz

gunzip lighttpd-1.4.20.tar.gz

tar -xvf lighttpd-1.4.20.tar

cd lighttpd-1.4.20

./configure</div>
Here is a list of errors / fixes encountered while doing this from a bare-bones net install. Run ./configure after each one to see what else is broken / needs to be installed.
<table class="errors" border="0" cellspacing="3" cellpadding="2" width="100%">
<tbody>
<tr>
<td width="50%"><strong>Error</strong></td>
<td width="50%"><strong>Fix</strong></td>
</tr>
<tr>
<td valign="top">configure: error: no acceptable C compiler found in $PATH</td>
<td valign="top">yum install gcc</td>
</tr>
<tr>
<td valign="top">configure: error: pcre-config not found, install the pcre-devel package or build with --without-pcre</td>
<td valign="top">yum install pcre*</td>
</tr>
<tr>
<td valign="top">configure: error: zlib-headers and/or libs where not found, install them or build with --without-zlib</td>
<td valign="top">yum install zlib*</td>
</tr>
<tr>
<td valign="top">configure: error: bzip2-headers and/or libs where not found, install them or build with --without-bzip2</td>
<td valign="top">yum install bzip*</td>
</tr>
</tbody></table>
Copy the lighttpd conf to somewhere easy to find:
<div class="console">cp doc/lighttpd.conf /home/lighttpd.conf</div>
<div class="console">make
make install</div>
Now onto PHP:
<div class="console">yum install php</div>
That's done easily enough. Verify it's installed:
<div class="console">root@localhost lighttpd-1.4.20]# php -v
PHP 5.1.6 (cli) (built: Jul 16 2008 19:53:00)
Copyright (c) 1997-2006 The PHP Group
Zend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies</div>
Verify python's installed:
<div class="console">[root@localhost lighttpd-1.4.20]# python
Python 2.4.3 (#1, May 24 2008, 13:47:28)
[GCC 4.1.2 20070626 (Red Hat 4.1.2-14)] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>></div>
(hit ctrl+d to exit the python interpreter)

Install MySQL:
<div class="console">yum install mysql*</div>
( I just install them all as this is a dev server anyways )

Everything went okay so now onto Ruby
<div class="console">yum install ruby*</div>
Everything went okay, and all the software is installed. Now it's time to configure them.

<strong>First lets get PHP working with Lighty.</strong>
<div class="console">nano /etc/php.ini</div>
hit CTRL+V to page down real quick.... at the bottom of the file add:
<div class="console">cgi.fix_pathinfo = 1</div>
Save the file and exit.

First:
<div class="console">whereis php-cgi</div>
It should be in /usr/bin/php-cgi

Second:
<div class="console">adduser dev</div>
<div class="console">echo '' >> /home/dev/index.php</div>
Now lets open lighttpd.conf
<div class="console">nano /home/lighttpd.conf</div>
Un-comment the fastcgi, rewrite, and redirect lines.

Lets change the document root to be /home/dev/

Lets also make sure we change the user of Lighty:
<div class="console">## change uid to  (default: don't care)
server.username            = "dev"

## change uid to  (default: don't care)
server.groupname           = "dev"</div>
Now scroll down and add this to the bottom:
<div class="console">fastcgi.server = ( ".php" => ((
"bin-path" => "/usr/bin/php-cgi",
"socket" => "/tmp/php.socket"
)))</div>
Exit and save the file.

Lets try starting Lighty:
<div class="console">lighttpd -f /home/lighttpd.conf
2009-01-27 15:02:20: (log.c.84) opening errorlog '/var/log/lighttpd/error.log' failed: No such file or directory
2009-01-27 15:02:20: (server.c.888) Opening errorlog failed. Going down.</div>
<div class="console">mkdir /var/log/lighttpd
touch /var/log/lighttpd/error.log; touch /var/log/lighttpd/access.log; chown -R dev:dev /var/log/lighttpd;</div>
Start lighty again and you're all set!

Now lets see if PHP worked.... browse to your dev server's ip and you should see the php info page, and all is well.

<strong>Now lets get Ruby working</strong>
Now lets get Ruby-FCGI
<div class="console">wget http://sugi.nemui.org/pub/ruby/fcgi/ruby-fcgi-0.8.6.tar.gz; gunzip ruby-fcgi-0.8.6.tar.gz ; tar -xvf ruby-fcgi-0.8.6.tar;
cd ruby-fcgi-0.8.6
ruby install.rb config</div>
This fails so lets check for errors:
<div class="console">[root@localhost ruby-fcgi-0.8.6]# cat ext/fcgi/mkmf.log
have_header: checking for fcgiapp.h... -------------------- no

"gcc -E -I. -I/usr/lib/ruby/1.8/i386-linux -I/root/tmp/ruby-fcgi-0.8.6/ext/fcgi  -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m32 -march=i386 -mtune=generic -fasynchronous-unwind-tables -Wall -fno-strict-aliasing  -fPIC  conftest.c -o conftest.i"
conftest.c:1:21: error: fcgiapp.h: No such file or directory
checked program was:
/* begin */
1: #include
/* end */

--------------------

have_header: checking for fastcgi/fcgiapp.h... -------------------- no

"gcc -E -I. -I/usr/lib/ruby/1.8/i386-linux -I/root/tmp/ruby-fcgi-0.8.6/ext/fcgi  -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m32 -march=i386 -mtune=generic -fasynchronous-unwind-tables -Wall -fno-strict-aliasing  -fPIC  conftest.c -o conftest.i"
conftest.c:1:29: error: fastcgi/fcgiapp.h: No such file or directory
checked program was:
/* begin */
1: #include
/* end */

--------------------</div>
Fix:
<div class="console">wget http://www.fastcgi.com/dist/fcgi-2.4.0.tar.gz; gunzip fcgi-2.4.0.tar.gz; tar -xvf fcgi-2.4.0.tar; cd fcgi-2.4.0
./configure
make
make install</div>
Now lets try ruby again!
<div class="console">ruby install.rb config
ruby install.rb setup
ruby install.rb install</div>
Done :).

Now install gem: wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz

Gunzip, tar -xvf it and then compile it:

run <div class="console">ruby setup.rb</div>

That should install Gem for you.

Next you need to install Rails, which can be done very easily now

<div class="console">gem install rails</div>

When initially doing this I ran into an issue of Rails complaining (specifically when running the ruby script/server command) about not being able to find the specific database information.

First: start a project

<div class="console">cd /home/
mkdir ruby
cd ruby
rails demo
</div>

That creates your first demo project.

Now lets make a controller:
<div class="console">ruby script/generate controller hello
      exists  app/controllers/
      exists  app/helpers/
      create  app/views/hello
      exists  test/functional/
      create  app/controllers/hello_controller.rb
      create  test/functional/hello_controller_test.rb
      create  app/helpers/hello_helper.rb
</div>

Start the development server:

<div class="console">ruby script/server
=> Booting Mongrel (use 'script/server webrick' to force WEBrick)
=> Rails 2.2.2 application starting on http://0.0.0.0:3000
=> Call with -d to detach
=> Ctrl-C to shutdown server
** Starting Mongrel listening at 0.0.0.0:3000
** Starting Rails with development environment...
** Rails loaded.
** Loading any Rails specific GemPlugins
** Signals ready.  TERM => stop.  USR2 => restart.  INT => stop (no restart).
** Rails signals registered.  HUP => reload (without restart).  It might not work well.
** Mongrel 1.1.5 available at 0.0.0.0:3000
** Use CTRL-C to stop.
</div>

Browse to http://yourserverip:3000/hello
Error:
 MissingSourceFile in HelloController#index

no such file to load -- sqlite3

RAILS_ROOT: /home/ruby/demo

To fix:

Hit Ctrl+C to stop the web daemon, then:
<div class="console">cd config
nano database.yml
</div>

Change it to read something like:
<div class="console">development:
  adapter: mysql
  encoding: utf8
  database: ruby
  username: root
  password: PASSWORD
</div>

Now to install Ruby MySQL:
<div class="console">
gem install mysql -- \
--with-mysql-include=/usr/include/mysql \
--with-mysql-lib=/usr/lib64/mysql
</div>

Now try running the server again

<div class="console">ruby script/server</div>

and browse to http://yourserverip:3000/hello and you should get another error:
Unknown action

No action responded to index. Actions:


To fix, first exit the web server (Ctrl+C), then:
<div class="console">cd app
cd controllers
nano hello_controller.rb
# Change file to look like this:
class HelloController < ApplicationController
   def index
      render :text => "Hello World"
   end
end
</div>

Save and exit, and then:
<div class="console">cd ../../;
ruby script/server</div>

Browse to http://yourserverip:3000/hello

And voila, Rails! You should see: "Hello World!"

I did however find a simpler way to run this using Mongrel:
<div class="code">gem install mongrel</div>
Wait a few for it to install and then just change to your demo directory:
<div class="console">mongrel_rails start -d</div>


<strong>Now to setup a Python (via Django)</strong>
<div class="console">wget http://www.djangoproject.com/download/1.0.2/tarball/
tar -xzvf Django-1.0.2-final.tar.gz
cd Django-1.0.2-final
python setup.py install

cd /home/
mkdir python
cd python
django-admin.py startproject demo
cd demo
python manage.py runserver 0.0.0.0:8000
</div>

Browsing to http://yourserverip:8000/ you should see:

It worked!
Congratulations on your first Django-powered page.


You're now all set up with one server that can serve PHP, Python, and Ruby pages.

This is by no means a programming tutorial, I was simply showing how to get the basics set up for people to start quickly learning PHP, Python (web programming), and Ruby on Rails.

Please leave a comment if you spot a bug / error somewhere!
