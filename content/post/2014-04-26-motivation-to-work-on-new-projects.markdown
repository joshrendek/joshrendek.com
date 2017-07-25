---
categories: rants
comments: true
date: 2014-04-26T00:00:00Z
title: Motivation to work on new projects
url: /2014/04/motivation-to-work-on-new-projects/
---

Whenever I have spare time ( often around Christmas or when I'm on vacation/traveling ), I tend to fill it with working on projects I've built up in my backlog. I'm also really trying to keep a continuous streak of OSS commits going on Github (something about filling that chart up makes me want to work harder). Here's my process and how I go about working on personal projects and try to stay motivated - if you have any ideas I'd love to hear them in the comments!

## Have a backlog

I use Evernote for all my ideas and project notes:

![Evernote](/images/motivation/evernote.png)

I have two columns - one for things in progress or to do and one for projects that are done ( with a link to any github repos I published ). When I have some downtime but don't feel like actually writing any code - I'll write out plans for what the project needs (use cases, backend needs, software I plan on using, etc) and do research and store all that as a sub-note in Evernote (you can see that with the light green link to the HAProxy Frontend ) under the main page. Plus I can easily share these with friends for feedback by just copying the share URL.

## Use small milestones to build up bigger ones

For instance, when I was working on the code for [http://ifcfg.net/](https://github.com/joshrendek/scala-ifcfg-api) I decided there were two major components I would need to create: the web api to access the data, and then a backing library to do some web scraping to gather BGP data.
I started out writing a small scraper in Scala for scraping BGP and looking glass info (which involved learning some more SBT, and selenium apis for Scala) and then moved onto learning a small amount of the Play! framework and exposing my library via that api. This let me focus on one small component at a time and finish it ( I have a habit of leaving personal projects unfinished or taking a long time to finish them if I let the scope creep beyond what I deemed as minimum requirements ).

## Pick an interesting project

There are some areas I just don't have an interest in - like writing an application to track golf scores.

So pick something you like - I love doing backend systems and APIs - pick something your passionate about already or a topic you want to learn more about.

## Learn

If I'm working on a personal project and not learning anything new (even if its just a new way to test, for instance) - I get bored, *really* quickly. I've been stemming this by trying to pick up new languages as I work on projects and working on projects with broader goals.

For instance, my latest project I'm working on is [Patchasaurus](https://github.com/joshrendek/patchasaurus) ( yes there isn't a readme yet ). I know theres a gap in the systems world for (open source) patch management, especially focused on Ubuntu and Debian - so I decided to write a small initial version of one.
I had been playing around with Go at work (and boy is it nice to get a HTTP API running in a few MB of RAM) and decided to write the _agent_ for patchasaurus in that ( nicknamed _trex_ ).
I've been learning how to cross compile programs in Go, what libraries don't work with cross-compilation (looking at you `os/user`) and a nice work flow for testing these while developing them ( sshfs is great for this with VirtualBox or Vagrant ).
I also chose to use Rails 4.1 as the management interface since I wanted to stay up to date with the new Rails features - turns out `spring` is very nice and a great improvement over the guard work flow I've used before.

## Don't focus on processes versus getting things done

I'm a big fan of testing, and TDD, however I'm not always in the mood to do it. Sometimes I just want to see results and I'll go back and refactor and test later. Picking what works for you on a specific project/component, and getting it done I think is much more important than rigidly following a specific set of guidelines on every project you do ( aka: test first, setup CI before any code, etc ).


## Don't get in a rut

Staring at HackerNews or Reddit all day can be daunting - try and not focus on what everyone else is doing and instead focus on what you're getting done and how you're improving yourself.

Also don't let this influence your technology choices. Sometimes there are articles trending for `AngularJS` or `Ruby on Rails` - stick with what you picked ( unless you really want to learn that new tech ) - or figure out ways to incorporate that into smaller components of your project. Don't throw away all that progress just because you saw a few posts reach the page!

## Take breaks

Don't spend all day coding - take breaks, go for a walk, a run, play with your dog, play a video game - something that can give you a moment to breathe and think about something else or give you time to re-focus on the grand vision you've been laboring over. Figure out what works for you to relax and do it to break up that screen glow tan you're getting.

## Talk about what you're working on

Talk with friends to brainstorm ideas, pair up on some problems, see if theres a more idiomatic way to do a function in the language your using ( for example, I spent some time trying to see if there were any `map()` equivalents on #go-nuts), and blog about what you're doing if that's your style.

Knowing people are using code and software I've written is a huge motivating factor to working on future projects ( star/watch counts on Github, downloads on RubyGems, traffic to my blog, etc).


## Finish!!

Yes it can be hard, but figure out what *finished* means to you, and do it. Publish it on Github, submit it to HackerNews, post it to reddit, get it hooked into TravisCI - make sure you come to the finish line of each component or project you're working on. Building up these small accomplishments can help set a streak for the future so you have the motivation to power through and get items done.

Sometimes you're more interested in getting an application finished than on the deployment process - throw it on Heroku, a shared hosting provider, etc.  There's nothing wrong with some shared hosting for a small project. Don't let things like deployment stop you from finishing!
