---
date: 2009-03-03T22:02:16Z
title: Random Ruby Rumblings
wordpress_id: 182
wordpress_url: http://bluescripts.net/2009/03/random-ruby-rumblings/
---

I'm going to keep updating this post as I make some more findings about Rails that I think are pretty good assumptions a newbie should learn about:

<strong>Case 2, forms: </strong>
I made an array using split(",") in the controller, then in the view I was looping through and could puts them out fine, however the ultimate goal was to use them in a form. Basically I needed it to be name="order[field_name]" name="order[field_name_2]"

GOOD Code to do this:
<% for c in @customize_this %>
		<%= form.check_box :"#{c}" %>
<% end %>

However I had originally gotten name="order[c]" name="order[c]" - basically the same thing for all items in the list...
The BAD code was this:
<% for c in @customize_this %>
		<%= form.check_box :c %>
<% end %>

Best place to read more about it: <a href="http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html">http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html</a>

<strong>Case 1, links:</strong>
Good: <b><%= link_to "#{item.name}", :action => "customize", :id => item.id %></b><br>
Bad: 			<b><%= link_to "#{item.name}", :action => "customize/#{item.id}" %></b><br>
