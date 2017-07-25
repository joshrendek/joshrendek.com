---
date: 2010-12-25T13:02:11Z
title: 'Rails: Implementing fine grained ACLs while staying DRY'
url: /2010/12/rails-implementing-fine-grained-acls-while-staying-dry/
wordpress_id: 443
wordpress_url: http://bluescripts.net/?p=443
---

There don't seem to be any 'dynamic' ACL modules for rails ( CanCan is kind of there, but not quite ) -- I want to be able to modify permissions on the fly, preferably from an administration page.

This is done simply with a Role table and a few methods in application_controller and your User model. This allows you to easily check the serialized Role hash {"foo" => ["edit", "update"]} by calling current_user.can?("foo", "edit") and you'll know if they can edit the foo object.

<script src="https://gist.github.com/754956.js"> </script>
