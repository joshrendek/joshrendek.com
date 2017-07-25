---
date: 2011-11-30T00:00:00Z
title: OSX + Vim + CTags (Exuberant) for fast context switching in large projects
url: /2011/11/osx-vim-ctags-exuberant-for-fast-context-switching-in-large-projects/
---

### Installing CTags (Exuberant)

Lets first install ctags-exuberant using Homebrew

{{< highlight bash >}}
brew install ctags-exuberant
{{< / highlight >}}

Remember the path that ctags got installed to, with version 5.8 on my machine it was in:
{{< highlight bash >}}
/usr/local/Cellar/ctags/5.8/bin/ctags
{{< / highlight >}}

### Setting up Vim/MacVim

Download the TagList plugin from [VimOnline](http://vim.sourceforge.net/scripts/script.php?script_id=273).

In your .vimrc file add the following:
{{< highlight bash >}}
let Tlist_Ctags_Cmd='/usr/local/Cellar/ctags/5.8/bin/ctags'

let g:Tlist_Ctags_Cmd='/usr/local/Cellar/ctags/5.8/bin/ctags'

fu! CTagGen()
    :execute "!" . g:Tlist_Ctags_Cmd .  " -R ."
endfunction

nmap <silent> :ctg :call CTagGen()
{{< / highlight >}}

Open up vim/MacVim, and type
{{< highlight bash >}}
:ctg
{{< / highlight >}}

You can then go to a controller for example:

Type in:
{{< highlight bash >}}
:Tlist
{{< / highlight >}}

And the follow should appear.

![ctag list]({{ site.s3 }}posts/ctag_vim.jpg)

Lets say I've got my cursor on StoryType and I want to go to the model, I can just hit Ctrl+] to get there. You can now do this for any method (helpers, methods, anything thats in your ctags file!).
