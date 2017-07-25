---
date: 2011-11-21T00:00:00Z
title: Cucumber and Mysql2::Error Lock when deleting records
url: /2011/11/cucumber-and-mysql2-error-lock-when-deleting-records/
---

I was writing some cucumber features for reru_scrum when I ran into an issue with destroying user records and Mysql2 throwing a Lock error.

The full error:
{{< highlight ruby >}}
Mysql2::Error: Lock wait timeout exceeded; try restarting transaction: UPDATE `users` SET `last_sign_in_at` = '2011-11-22 00:06:32', `current_sign_in_at` = '2011-11-22 00:11:28', `sign_in_count` = 3, `updated_at` = '2011-11-22 00:11:28' WHERE `users`.`id` = 1
{{< / highlight >}}

A simple solution is to use the [database_cleaner](https://github.com/bmabey/database_cleaner) gem.

Inside your features/support/env.rb file:
{{< highlight ruby >}}
begin
  require 'database_cleaner'
  require 'database_cleaner/cucumber'
  DatabaseCleaner.strategy = :truncation
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end
{{< / highlight >}}

A good idea is to create the before and after hooks to use the DatabaseCleaner.start and DatabaseCleaner.clean methods.

Inside features/support/hooks.rb:

{{< highlight ruby >}}
Before do
  DatabaseCleaner.start
end

After do |scenario|
  DatabaseCleaner.clean
end
{{< / highlight >}}

You should then be able to run your features and have your database cleaned between steps.
