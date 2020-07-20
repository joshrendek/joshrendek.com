---
title: 'VS Code Server: Go and getting Buffalo setup with Postgres'
date: 2020-07-20T00:46:27-04:00
draft: false
---

We'll go over everything needed to get a small development environment up and running using code-server, buffalo and postgres for a remote dev environment.

First lets install Go and Buffalo with `gofish`:

```bash 
apt-update
curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
gofish init
gofish install go 
gofish install buffalo
buffalo version # should say 0.16.12 or whatever latest is
```

Install docker

    curl -fsSL get.docker.com | bash
    
Install NodeJS & Yarn:

    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update && sudo apt-get install yarn


Install code-server

    curl -fsSL https://code-server.dev/install.sh | sh
    
Add your user:

    sudo usermod -aG docker YOURUSER
    # you made need to reboot after this step to get your user to talk to the docker daemon properly


Start code-server, as your *regular* user (ie: not sudo):

    systemctl --user enable --now code-server

Edit your config *only do this if its on a private, trusted network, don't do
this on an internet exposed server*

`.config/code-server/config.yaml`:

```yaml
bind-addr: 0.0.0.0:8080
auth: none
password: xxxx
cert: false
```

Restart the server:

```yaml 
systemctl --user restart code-server
```

And finally let's setup postgres:

```bash 
# for the server, this is quickest/easiest
docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 --restart=always -d postgres
# for client
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-client-12
```

You can now psql to your app from the terminal:

    postgres://postgres:postgres@127.0.0.1:5432/demo_test?sslmode=disable

Let's create our demo buffalo app:

```bash
buffalo new demo
cd demo
```

Edit your database.yml to look like this for development:

```bash 
---
development:
  url: {{envOr "DEV_DATABASE_URL" "postgres://postgres:postgres@127.0.0.1:5432/demo_test?sslmode=disable"}}
```

Then you can create and migrate your database:

```bash
buffalo db create && buffalo db migrate
```

Now just run `buffalo dev` in your VS Code terminal and you can browse your app
and start working on it.

If you want other things like the clipboard to work properly, I'd suggest
setting up a proxy with auth and a real SSL certificate, for example using Traefik or Caddy.
