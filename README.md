Proper Vim Tmux Navigator
==================
Will you, vim, take tmux as your lawfully wedded terminal multiplexer, til death do you part?


Differences:
- Slightly faster (hopefully)
	* Doesn't trigger autocmds when test-switching windows, 
	* Cleaned up vim< >tmux passing?
- Adds window resizing using the same principles as switching
	* Unifies both vim and tmux to use a more natural (for hjkl) tmux-style direction wise
	* Both takes count and allows key repeat
- Maximize/zoom unified 
	* reimplement/steal vim-maximize
- Quit/close window/pane
- loop vim window navigation like how tmux does
- Direction-wise navigation always takes you to the window that makes sense, regardless
	of previous straight jumps
- Quickly double tapping `last window` takes you to the second most recent, etc?

Planned:
- command to set width of current pane/window to 80
- equalize a la <C-w>= covering both vim and tmux
- auto-size (and then restore!!) windows as move between them, sorta like GoldenView but not buggy 
	and extending covering tmux (will prob be a bitch to get working)
	AND not fucking up vim horizontal viewport
	also would need to fix shell spewing prompts on resize or it would suck, but got an idea for how to fix that in fish
	^ this will be fucking glorious

- Fix up some inconsitencies as far as what makes stuff go where when
- Defer redraws somehow so press-and-hold works better?
- Add a way to force "the opposite" so don't have to fall back on seperate
	vim/tmux mappings to eg. maximize a tmux pane from within vim etc
	* Still would want some specific shortcuts for this for some cases,
		like double tap zoom/maximize = outer. Maybe kill pane as well, but then def
		with a y/n prompt tho...
- Other prefix to anchor right/below so don't have to switch back and forth to resize certain ways.
	* Preferably using a timer so can press it just once and then spam

- Maximize only in specific direction
	* Just add an arrangement save to my existing mj/mk bindings, and extent to tmux
- Minimize/bury
- Split creation something, maybe? Like my current <Leader>s[hjkl] / < Prefix >[hjkl] 
	resulting in	<Space>s[hjkl] / <C-s>[hjkl]
	Is nice because has very similar feel. But proper unified even better.
	<M-s><M-[hjkl]> I guess?

- Unified go-to-win a la prefix-c but for both tmux and vim and even better
	Each window/pane gets an identifier to stick in tmux pane status /
	vim window statusline, and so can be jumped to directly

- Undo close. Not proper iTerm-style but at least restore window/position, buffer/contents,
	def feasible.

Eh:
- extend one step further, to iTerm/similar splits...
- Reimplement literally all of tmux in pure* vimscript 
	(*might have to resort to visual basic for the tricky bits)


Based on [christoomey's][] vim-tmux-navigator, in turn derived from
[Mislav Marohnić's][] tmux-navigator configuration


Usage
-----

Not a fan of plugs taking over a bunch of existing mappings like they own the place,
and you should prob sort your own binds to suit your workflow, conflicts, and conventions.
but some default ones can be enabled if you don't want to start from scratch.
Since these mappings are direct, and not behind a tmux-prefix, whatever mapping you 
go with will likely conflict with something or other, so choose your poison.

I would advice against the `<C-[hjkl]>` from vim-tmux-navigator, or my personal config:
`<M-hjkl>` to navigate, `<M-HJKL>` to resize (5 rows/3 lines by default)
Meta is superior imo, allowing easy one-handed navigation, case sensitivity,
and generally far fewer conflicts with conventional bindings in and out of vim.

Real rock star pro grammers keepin it home row might want to modal shit up with
eg. Karabiner + Hammerspoon for some non-modifier prefix action. And so should you!

My other defaults, I guess:
- `<M-z>` => Previous (last) window/pane
<M-m> 		=> Maximize
<M-q> 		=> Quit / close
<M-0> 		=> Equalize?


Recommendations
---------------

You already have caps lock remapped to esc + ctrl, right?
Here's another one:
<Tab> 		=> Tab + Meta-Shift


Installation
------------

### Vim

``` vim
Plug 'tolgraven/proper-vim-tmux-navigator'
```


Configuration
-------------

#### Vim

Add the following to your `~/.vimrc` to define your custom maps:

``` vim
let g:proper_tmux_navigator_no_mappings = 1

nnoremap <silent> {Left-Mapping} :TmuxNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :TmuxNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :TmuxNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :TmuxNavigateRight<cr>
nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>
```

##### Autosave on leave

Make this mirror &autowrite / &autowriteall I guess, simpler...
But keep the user var for manual set in case some freak wants it

##### Automatically exit zoom

By default, direction-wise navigation is restricted to what is visible -  
when at an edge, instead of automatically unzooming hidden panes, we keep it
WYSIWYG and wrap around.
Both these behaviors can be changed:

```vim
let g:proper_tmux_navigator_auto_unzoom = 1
let g:proper_tmux_navigator_disable_wrap = 1
```

#### Tmux



#### Nesting

Anyone interested in implementing this is welcome to do it.


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



[Brian Hogan]: https://twitter.com/bphogan
[Mislav Marohnić's]: http://mislav.uniqpath.com/
[Mislav's original external script]: https://github.com/mislav/dotfiles/blob/master/bin/tmux-vim-select-pane
[TPM]: https://github.com/tmux-plugins/tpm
[configuration section below]: #custom-key-bindings
[this blog post]: http://www.codeography.com/2013/06/19/navigating-vim-and-tmux-splits
[this gist]: https://gist.github.com/mislav/5189704
