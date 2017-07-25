---
date: 2009-01-23T19:30:28Z
title: TinyMCE and Flash
wordpress_id: 130
wordpress_url: http://bluescripts.net/?p=130
---

Kept trying to enable flash in a TinyMCE editor I was using and finally the following worked for extended_valid_elements:
<pre lang="php">
object[classid|codebase|width|height|data|type],param[name|value],embed[src|quality|width|height|type|pluginspage|bgcolor],a[name|href|target|title|onclick]
</pre>
I also added flash and media to my plugins init as well.

Hope this helps someone else with that annoying tag stripping issue!
