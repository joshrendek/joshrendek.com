---
title: 'Cloud9: Updating Go and getting Buffalo setup with Postgres'
date: 2020-07-18T00:46:27-04:00
draft: false
---

When you setup your cloud9 IDE for the first time, it comes pre-installed with
go1.9 - if you'd like to update to the latest (as of this writing), just run the
following commands:

```bash 
wget https://golang.org/dl/go1.14.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf ./go1.14.6.linux-amd64.tar.gz
mv /usr/bin/go /usr/bin/go-old # move the old binary
```

Edit your `.bashrc` file so your `$PATH` has the new location:

```
export PATH=$PATH:$HOME/.local/bin:$HOME/bin:/usr/local/go/bin
```

Source the file again so your settings are reloaded:

```bash 
source ~/.bashrc
```

And now `go version` should show 1.14.6 

Now lets install Buffalo with `gofish`:

```bash 
curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
gofish init
gofish install buffalo
buffalo version # should say 0.16.12 or whatever latest is
```

And finally let's setup postgres:

```bash 
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-12
sudo su - postgres 
psql
postgres=# create role ubuntu with superuser createdb login password 'ubuntu'; 
postgres=# create database ubuntu;
postgres=# exit
exit
```

You should now be to execute `psql` from your regular user.

Let's create our demo buffalo app:

```bash
buffalo new demo
cd demo
```

Edit your database.yml to look like this for development:

```bash 
---
development:
  url: {{envOr "DEV_DATABASE_URL" "postgres://ubuntu:ubuntu@/demo_development"}}
```

Then you can create and migrate your database:

```bash
buffalo db create && buffalo db migrate
```

Now just run `buffalo dev` in your Cloud9 terminal and you can preview your
application! (Cloud9 already sets the `PORT` env var).


And then you realize that auto-complete support doesn't work with a small little

> `This feature is in an experimental state for this language. It is not fully
implemented and is not documented or supported.` 

on the [AWS product page](https://docs.aws.amazon.com/cloud9/latest/user-guide/language-support.html), and go
back to IntelliJ.
