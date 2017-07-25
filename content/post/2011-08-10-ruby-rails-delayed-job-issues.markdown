---
date: 2011-08-10T01:48:12Z
title: 'Ruby on Rails: Delayed Job issues'
url: /2011/08/ruby-rails-delayed-job-issues/
wordpress_id: 480
wordpress_url: http://bluescripts.net/?p=480
---

Thankfully the <a href="https://github.com/collectiveidea/delayed_job/issues?sort=created&amp;direction=desc&amp;state=open">issue tracker</a> on Github was a great help, but I recently ran into two issues I've never had the pleasure of encountering before while using DJ:

"nil is not a symbol" as a failure message. When running the background jobs for Servly, this was occurring on the status checks (its a pretty long list of checks on a server to reduce false positives, including distributed pings).Â  The problem with having the longer definition was the way DJ serializes the ruby code to store in the database. It was originally using a TEXT(65535) field as the data type in MySQL -- <em><strong>changing this to LongText fixed the issue.</strong></em> The mysterious part about this whole issue was it would run fine from the console, but not from the workers (which makes sense in hindsight because of the limited space available for the serialized object in the delayed_job table).

Here is a snippet of the stack trace (for anyone who might Google it), and <a href="https://github.com/collectiveidea/delayed_job/issues/264">the link to the Github Issue</a>:

{{< highlight ruby >}}nil is not a symbol
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/performable_method.rb:20:in <code>perform'
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/backend/base.rb:87:in</code>invoke_job'
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/worker.rb:120:in <code>block (2 levels) in run'
 /usr/local/lib/ruby/1.9.1/timeout.rb:57:in</code>timeout'
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/worker.rb:120:in <code>block in run'
 /usr/local/lib/ruby/1.9.1/benchmark.rb:309:in</code>realtime'
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/worker.rb:119:in <code>run'
 /usr/local/lib/ruby/gems/1.9.1/gems/delayed_job-2.1.4/lib/delayed/worker.rb:177:in</code>reserve_and_run_one_job'

{{< / highlight >}}

The <a href="https://github.com/collectiveidea/delayed_job/issues/277">second issue</a> was a combination of things:

The worker resides on a separate node from the main application stack and connects to the database remotely (still over a private LAN). The first thing I noticed was workers dieing silently; a lot of hits on Google pointed to MySQL losing its connection (the default in database.yml/ActiveRecordÂ  is reconnect: false) -- changing this to reconnect: true fixed that issue of workers dieing silently.

Another problem with workers dieing off silently was a lack of information; adding these two lines to the delayed_job_config initializer produced a lot more meaningful errors:

{{< highlight ruby >}}
Delayed::Worker.logger = Rails.logger
Delayed::Worker.logger.auto_flushing = 1{{< / highlight >}}

And finally -- a version specific bug; delayed_job was running into race conditions on locking jobs it was working on:

{{< highlight ruby >}}Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction: UPDATE <code>delayed_jobs</code> SET locked_at = '2011-08-08 21:30:10', locked_by = 'delayed_job.10 host:226237 pid:27929' WHERE ((run_at <= '2011-08-08 21:30:10' AND (locked_at IS NULL OR locked_at < '2011-08-08 21:15:10') OR locked_by = 'delayed_job.10 host:226237 pid:27929') AND failed_at IS NULL) ORDER BY priority ASC, run_at ASC LIMIT 1 Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction: UPDATE <code>delayed_jobs</code> SET locked_at = '2011-08-08 21:30:10', locked_by = 'delayed_job.0 host:226237 pid:27869' WHERE ((run_at <= '2011-08-08 21:30:10' AND (locked_at IS NULL OR locked_at < '2011-08-08 21:15:10') OR locked_by = 'delayed_job.0 host:226237 pid:27869') AND failed_at IS NULL) ORDER BY priority ASC, run_at ASC LIMIT 1{{< / highlight >}}

Upgrading from delayed_job 2.1.2 to 2.1.4 fixed the issue; apparently 2.1.3 may have also been affected.

Aside from these few issues delayed job has been wonderful to use in production and will continue to be used for handling all of Servly's background tasks and processes.
