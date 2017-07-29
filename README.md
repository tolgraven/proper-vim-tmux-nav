Proper Vim Tmux Nav
==================
Will you, vim, take tmux as your lawfully wedded terminal multiplexer, til death do you part?

**WIP but nav and resize mostly functional**

Differences from vim-tmux-navigator:
- Slightly or amazingly faster (depending on how heavy your shell is)
	* Doesn't trigger Vim autocmds when test-switching windows 
	* Makes system() calls using sh, so even if you have a slow-to-start fish/zsh/bash/whatever setup it won't break yer groove
- Adds window resizing using the same principles as switching
	* Unifies vim and tmux to use the more natural (for hjkl) tmux-style direction-wise
	* Takes count, allows key repeat
- Quit/close window/pane (p dangerous I guess, optional)

Planned:
- Maximize/zoom unified (reimplement/steal vim-maximize etc)
- looparound vim window navigation like how tmux does
- Direction-wise navigation always taking you to the nearest window/pane in that direction, even between tmux and vim and regardless of previous jumps...
- Quickly double tapping `last window` takes you to the second most recent, etc?
	Like how Tab Ahead works in Chrome

Maybe:
- command to set width of current pane/window to 80
- equalize a la <C-w>= covering both vim and tmux
- auto-size (and restore!) windows as move between them, sorta like GoldenView but not buggy and extending covering tmux (will prob be a bitch to get working)
	* AND not fucking up vim horizontal viewport
	* also would need to fix shell spewing prompts on resize or it would suck, but got an idea for how to fix that in fish
	^ this will be fucking glorious

- Defer redraws somehow so press-and-hold works better?
- Add a way to force "the opposite" so don't have to fall back on seperate vim/tmux mappings to eg. maximize a tmux pane from within vim etc
	* Still would want some specific shortcuts for this for some cases,
		like double tap zoom/maximize = outer. Maybe kill pane as well, but then def with a y/n prompt tho...
- Other prefix to anchor right/below so don't have to switch back and forth to resize certain ways.
	* Preferably using a timer so can press it just once and then spam

- Maximize only in specific direction instead of completely
	* For basic, just add an arrangement save to my existing mj/mk bindings, and extend to tmux
	* But actual point of it is obviously the restore part...
- Minimize/bury
- Split creation something, maybe? Like my current <Leader>s[hjkl] / < Prefix ><M-[hjkl]>
	aka	<Space>s[hjkl] / <C-s><M-[hjkl]>
	Is nice because has very similar feel. But proper unified even better.
	* <M-s><M-[hjkl]> I guess?
	* Considering tmux has ability to do leader key type shit now maybe just hook on space (or whatever lesser key idiots might be using) when vim is up?
		And have tmux handle it.

- Unified go-to-win a la prefix-q but for both tmux and vim and even better
	Each window/pane gets an identifier to stick in tmux pane status /
	vim window statusline, and so can be jumped to directly

- Undo close. Not proper iTerm-style but at least restore window/position, buffer/contents,
	def feasible.

Obviously:
- extend one step further, to iTerm/similar splits...
- Reimplement literally all of tmux in pure* vimscript 
	(*might have to resort to visual basic for the tricky bits)


Based on [christoomey's][] vim-tmux-navigator, in turn derived from
[Mislav Marohnić's][] tmux-navigator configuration


Usage
-----

Not a fan of plugs taking over a bunch of existing mappings like they own the place,
and you should prob sort your own binds to suit your workflow, conflicts, and conventions.
but some default ones can be enabled if you* know what's good for you.
Since these mappings are direct, and not behind a tmux-prefix, whatever mapping you 
go with will likely conflict with something or other, so pick your poison**.

* I
** I have the best poison

Anyways, fuck the `<C-[hjkl]>` from vim-tmux-navigator, use my config:
`<M-hjkl>` to navigate, `<M-HJKL>` to resize (4 rows/2 lines by default)
Meta is superior, allowing easy one-handed navigation, case sensitivity,
and far fewer conflicts with conventional bindings in and out of vim.

Real rock star pro grammers keepin it home row might want to modal shit up with
Karabiner + Hammerspoon for some non-modifier prefix action. And so should you!

You already have caps lock remapped to Esc / Ctrl, right? Otherwise quit reading and do that
Here's another one:
<Tab> 		=> Tab / Meta-Shift

My other defaults, I guess:
- `<M-z>` => Previous (last) window/pane
<M-m> 		=> Maximize
<M-q> 		=> Quit / close
<M-0> 		=> Equalize?


Recommendations
---------------

Help me do the boring bits I can't bother with please


Installation
------------

### Vim

``` vim
Plug 'tolgraven/proper-vim-tmux-nav'
```


Configuration
-------------

#### Vim

Add the following to your `~/.vimrc` to define your custom maps:

``` vim
let g:proper_tmux_nav_no_mappings = 1

nnoremap <silent> {Left-Mapping} :TmuxNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :TmuxNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :TmuxNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :TmuxNavigateRight<cr>
nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>
```

##### Autosave on leave

Make this mirror &autowrite / &autowriteall I guess? simpler...
But keep the user var for manual set in case some freak wants it

##### Automatically exit zoom

By default, direction-wise navigation is restricted to what is visible -  
when at an edge, instead of automatically unzooming hidden panes, keep it WYSIWYG and wrap.
Both these behaviors can be changed:

```vim
let g:proper_tmux_nav_auto_unzoom = 1
let g:proper_tmux_nav_disable_wrap = 1
```

#### Tmux



#### Nesting

Someone please implement.


Troubleshooting
---------------

### Vim -> Tmux doesn't work!

Ensure the mappings are correctly activated in both vim and tmux.
[make a script to check]

or check manually:
```
tmux list-keys
:map
``````

### Sluggish performance

Watch for:
- Slow shell startup / system() calls
- Vim plugins, especially with autocmds running on WinLeave / WinEnter
	(Airline, for example)

`:time system('echo')`

If you find that navigation within Vim (from split to split) is fine, but Vim
to a non-Vim tmux pane is delayed, it might be due to a slow shell startup.
Consider moving code from your shell's non-interactive rc file (e.g.,
`~/.zshenv`) into the interactive startup file (e.g., `~/.zshrc`) as Vim only
sources the non-interactive config.

If tmux nav is fast, but Vim slow, compare time to regular <C-w>, it's likely similar, and likely due to Airline being a fatass :(


[Brian Hogan]: https://twitter.com/bphogan
[Mislav Marohnić's]: http://mislav.uniqpath.com/
[Mislav's original external script]: https://github.com/mislav/dotfiles/blob/master/bin/tmux-vim-select-pane
[TPM]: https://github.com/tmux-plugins/tpm
[configuration section below]: #custom-key-bindings
[this blog post]: http://www.codeography.com/2013/06/19/navigating-vim-and-tmux-splits
[this gist]: https://gist.github.com/mislav/5189704
