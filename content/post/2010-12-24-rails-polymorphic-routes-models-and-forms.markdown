---
date: 2010-12-24T16:54:36Z
title: 'Rails: Polymorphic routes, models, and forms'
url: /2010/12/rails-polymorphic-routes-models-and-forms/
wordpress_id: 437
wordpress_url: http://bluescripts.net/?p=437
---

I'm currently working on a project where I'm trying to make everything as extensible as possible. I have a Ticket model and I want everything to be ticketable (thats my polymorphic association).

The problem is that I want the URLs to be sensible and still have my polymorphic attribute loaded automatically without having to do *to* much hacking / un-dry code, so I wanted the URLs to be: /users/1/tickets/new.

This needs to be applied to any arbitrary number of models that has_many :tickets, :as => :ticketable .

The tickets controller needs to be able to get the object, and set it for a user to access it for the polymorphic form. <em>instance_set_variable</em> is the magic that lets this happen very easily. By having the before filter on create and new requests, the :get_object is called each request for those actions and the nested resources parent object is found and loaded into a variable called @ticketable .

The last bit of magic is the form_for that lets you create the ticket and have ticketable be automatically filled in by the rails engine with one little modification in the ticket_controllers.rb create method. Thats it!

<script src="https://gist.github.com/754505.js"> </script>
