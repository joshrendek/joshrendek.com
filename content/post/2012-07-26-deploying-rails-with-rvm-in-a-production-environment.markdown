---
date: 2012-07-26T00:00:00Z
title: Deploying Rails with RVM in a production environment
url: /2012/07/deploying-rails-with-rvm-in-a-production-environment/
---

Let's start out by logging into our machine and installing some pre-requistes (these can also be found by running rvm requirements as well):

{{< highlight bash >}}
sudo apt-get -y install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion git-core mysql-client libmysqlclient-dev libsasl2-dev libsasl2-dev mysql-server
{{< / highlight >}}

Lets also install nodejs:
{{< highlight bash >}}
curl -O http://nodejs.org/dist/v0.8.4/node-v0.8.4.tar.gz
tar xzvf node-v0.8.4.tar.gz
cd node-v0.8.4.tar.gz
./configure && make && sudo make install
{{< / highlight >}}


Now we can install ruby and RVM:
{{< highlight bash >}}
curl -L https://get.rvm.io | bash -s stable --ruby
source /home/ubuntu/.rvm/scripts/rvm
rvm use 1.9.3 --default
echo 'rvm_trust_rvmrcs_flag=1' > ~/.rvmrc
# sudo su before this
echo 'RAILS_ENV=production' >> /etc/environment
rvm gemset create tester
{{< / highlight >}}

And lastly nginx:
{{< highlight bash >}}
sudo apt-get install nginx
{{< / highlight >}}


Now let's make a simple rails application back on our development machine with 1 simple root action:
{{< highlight bash >}}
rails new tester -d=mysql
echo 'rvm use 1.9.3@tester --create' > tester/.rvmrc
cd tester
bundle install
rails g controller homepage index
rm -rf public/index.html
# Open up config/routes.rb and modify the root to to point to homepage#index
rake db:create
git init .
git remote add origin https://github.com/bluescripts/tester.git # replace this with your git repo
git add .; git ci -a -m 'first'; git push -u origin master
rails s
{{< / highlight >}}

Open your browser and go to http://localhost:3000 -- all good! Now lets make some modifications to our Gemfile:

{{< highlight ruby >}}
source 'https://rubygems.org'
gem 'rails', '3.2.6'
gem 'mysql2'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
gem 'jquery-rails'
gem 'capistrano', :group => :development
gem 'unicorn'
{{< / highlight >}}

and re-bundle:
{{< highlight bash >}} bundle {{< / highlight >}}

Now lets start prepping for deployment and compile our assets.

{{< highlight bash >}}
capify .
rake assets:precompile # dont forget to add it to git!
{{< / highlight >}}

Make a file called config/unicorn.rb:
{{< highlight ruby >}}

# config/unicorn.rb
# Set environment to development unless something else is specified
env = ENV["RAILS_ENV"] || "development"

site = 'tester'
deploy_user = 'ubuntu'

# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
worker_processes 4

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/tmp/#{site}.socket", :backlog => 64

# Preload our app for more speed
preload_app true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

pid "/tmp/unicorn.#{site}.pid"

# Production specific settings
if env == "production"
  # Help ensure your application will always spawn in the symlinked
  # "current" directory that Capistrano sets up.
  working_directory "/home/#{deploy_user}/apps/#{site}/current"

  # feel free to point this anywhere accessible on the filesystem
  shared_path = "/home/#{deploy_user}/apps/#{site}/shared"

  stderr_path "#{shared_path}/log/unicorn.stderr.log"
  stdout_path "#{shared_path}/log/unicorn.stdout.log"
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "/tmp/unicorn.#{site}.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # the following is *required* for Rails + "preload_app true",
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end
{{< / highlight >}}
\_

Now lets setup the config/deploy.rb to be more unicorn and git friendly, take note of the default environment settings which are taken from the server when running rvm info [modified version of ariejan.net's](http://ariejan.net/2011/09/14/lighting-fast-zero-downtime-deployments-with-git-capistrano-nginx-and-unicorn/):

{{< highlight ruby >}}
require "bundler/capistrano"

set :scm,             :git
set :repository,      "git@github.com:bluescripts/tester.git"
set :branch,          "origin/master"
set :migrate_target,  :current
set :ssh_options,     { :forward_agent => true }
set :rails_env,       "production"
set :deploy_to,       "/home/ubuntu/apps/tester"
set :normalize_asset_timestamps, false

set :user,            "ubuntu"
set :group,           "ubuntu"
set :use_sudo,        false

role :web,    "192.168.5.113"
role :db,     "192.168.5.113", :primary => true

set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

default_environment["RAILS_ENV"] = 'production'

default_environment["PATH"]         = "/home/ubuntu/.rvm/gems/ruby-1.9.3-p194/bin:/home/ubuntu/.rvm/gems/ruby-1.9.3-p194@global/bin:/home/ubuntu/.rvm/rubies/ruby-1.9.3-p194/bin:/home/ubuntu/.rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games"
default_environment["GEM_HOME"]     = "/home/ubuntu/.rvm/gems/ruby-1.9.3-p194"
default_environment["GEM_PATH"]     = "/home/ubuntu/.rvm/gems/ruby-1.9.3-p194:/home/ubuntu/.rvm/gems/ruby-1.9.3-p194@global"
default_environment["RUBY_VERSION"] = "ruby-1.9.3-p194"

default_run_options[:shell] = 'bash'

namespace :deploy do
  desc "Deploy your application"
  task :default do
    update
    restart
  end

  desc "Setup your git-based deployment app"
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
  end

  task :cold do
    update
    migrate
  end

  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end

  desc "Update the database (overwritten to avoid symlink)"
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids &&
      mkdir -p #{latest_release}/public &&
      mkdir -p #{latest_release}/tmp &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -s #{shared_path}/system #{latest_release}/public/system &&
      ln -s #{shared_path}/pids #{latest_release}/tmp/pids &&
      ln -sf #{shared_path}/database.yml #{latest_release}/config/database.yml
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = fetch(:public_children, %w(images stylesheets javascripts)).map { |p| "#{latest_release}/public/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat /tmp/unicorn.tester.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat /tmp/unicorn.tester.pid`"
  end

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end

    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}; #{rake} #{cmd}"
end
{{< / highlight >}}


Now lets try deploying (you may need to login to the server if this is the first time you've cloned from git to accept the SSH handshake):
{{< highlight bash >}}
cap deploy:setup
{{< / highlight >}}

Create your database config file in shared/database.yml:
{{< highlight yaml >}}
production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: tester_production
  pool: 5
  username: root
  password:
{{< / highlight >}}
\_

Go into current and create the database if you haven't already:
{{< highlight bash >}}
rake db:create
# cd down a level
cd ../
mkdir -p shared/pids
{{< / highlight >}}

Now we can run the cold deploy:

{{< highlight bash >}}
cap deploy:cold
cap deploy:start
{{< / highlight >}}

Now we can configure nginx:

Open up /etc/nginx/sites-enabled/default:
{{< highlight bash >}}
upstream tester {
	server unix:/tmp/tester.socket fail_timeout=0;
}
server {
	listen 80 default;
 	root /home/ubuntu/apps/tester/current/public;
	location / {
		proxy_pass  http://tester;
		proxy_redirect     off;

		proxy_set_header   Host             $host;
		proxy_set_header   X-Real-IP        $remote_addr;
		proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;

		client_max_body_size       10m;
		client_body_buffer_size    128k;

		proxy_connect_timeout      90;
		proxy_send_timeout         90;
		proxy_read_timeout         90;

		proxy_buffer_size          4k;
		proxy_buffers              4 32k;
		proxy_busy_buffers_size    64k;
		proxy_temp_file_write_size 64k;
	}

	location ~ ^/(images|javascripts|stylesheets|system|assets)/  {
		root /home/deployer/apps/my_site/current/public;
		expires max;
		break;
    }
}
{{< / highlight >}}

Now restart nginx and visit http://192.168.5.113/ ( replace with your server hostname/IP ). You should be all set!
