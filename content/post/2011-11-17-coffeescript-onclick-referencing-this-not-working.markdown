---
date: 2011-11-17T00:00:00Z
title: Coffeescript onclick referencing this not working
url: /2011/11/coffeescript-onclick-referencing-this-not-working/
---

When defining a event listener for objects in Coffeescript you nede to make sure you use a -> -- using a => will result in any references to attr() be "undefined"

Here is an example of some correct on click bindings that use the attr() methods

{{< highlight javascript >}}
  jQuery ($) ->
  $('[id^=story_]').click ->
    $( "#" +  $(this).attr("id") + "_loader")
      .load('/projects/' + $(this).attr('project_id') +
      '/story_types/' + $(this).attr('story_type_id') +
      '/stories/'+ $(this).attr('story_id') + '/tasks/new')
{{< / highlight >}}
