Proper Vim Tmux Navigator
==================
Will you, vim, take tmux as your lawfully wedded terminal multiplexer, til death do you part?


Differences:
- Faster (hopefully)
	* Doesn't trigger autocmds when test-switching windows, 
	* Cleaned up vim< >tmux passing?
- Adds window resizing using the same principles as switching
	* Unifies both vim and tmux to use a more natural (for hjkl) direction-wise
	* Both takes count and allows key repeat
- Maximize/zoom also unified (using whatever that plug is)
- loop vim window navigation like how tmux does

Todo:
- command to set width of current pane/window to 80
- command like <C-w>= covering both vim and tmux
- auto-size (and then restore!!) windows as move between them, sorta like GoldenView but not buggy 
	and extending covering tmux (will prob be a bitch to get working)
	AND not fucking up vim horizontal viewport
	also would need to fix shell spewing prompts on resize or it would suck, but got an idea for how to fix that in fish
	^ this will be fucking glorious

- Fix up some inconsitencies as far as what makes stuff go where when
- Defer redraws somehow so press-and-hold works better?
- Add a way to force "the opposite" so don't have to fall back on seperate
	vim/tmux mappings to eg. maximize a tmux pane from within vim etc

- Maximize only in specific direction
- Minimize/bury
- Split creation something, maybe? Like my current <Leader>s[hjkl] / < Prefix >[hjkl] 
	resulting in	<Space>s[hjkl] / <C-s>[hjkl]
	Is nice because has very similar feel. But proper unified even better.

- Unified go-to-win a la prefix-c but for both tmux and vim
	Each window/pane gets an identifier to stick in tmux pane status /
	vim window statusline, and so can be jumped to directly

- extend this one step further, to iTerm/similar splits...
- END GOAL: Reimplement literally all of tmux in pure* vimscript 
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


- `<M-z>` => Previous split


Installation
------------

### Vim

``` vim
Plug 'tolgraven/proper-vim-tmux-navigator'
```

### tmux

To configure the tmux side of this customization there are two options:

#### Add a snippet

Add the following to your `~/.tmux.conf` file:

``` tmux
# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" "send-keys C-h"  "select-pane -L"
bind-key -n C-j if-shell "$is_vim" "send-keys C-j"  "select-pane -D"
bind-key -n C-k if-shell "$is_vim" "send-keys C-k"  "select-pane -U"
bind-key -n C-l if-shell "$is_vim" "send-keys C-l"  "select-pane -R"
bind-key -n C-\ if-shell "$is_vim" "send-keys C-\\" "select-pane -l"
```

#### TPM

If you'd prefer, you can use the Tmux Plugin Manager ([TPM][]) instead of
copying the snippet.
When using TPM, add the following lines to your ~/.tmux.conf:

``` tmux
set -g @plugin 'christoomey/vim-tmux-navigator'
run '~/.tmux/plugins/tpm/tpm'
```

Thanks to Christopher Sexton who provided the updated tmux configuration in
[this blog post][].

Configuration
-------------

### Custom Key Bindings

If you don't want the plugin to create any mappings, you can use the five
provided functions to define your own custom maps. You will need to define
custom mappings in your `~/.vimrc` as well as update the bindings in tmux to
match.

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

*Note* Each instance of `{Left-Mapping}` or `{Down-Mapping}` must be replaced
in the above code with the desired mapping. Ie, the mapping for `<ctrl-h>` =>
Left would be created with `nnoremap <silent> <c-h> :TmuxNavigateLeft<cr>`.

##### Autosave on leave

You can configure the plugin to write the current buffer, or all buffers, when navigating from Vim to tmux. This functionality is exposed via the `g:proper_tmux_navigator_save_on_switch` variable, which can have either of the following values:

Value  | Behavior
------ | ------
1      | `:update` (write the current buffer, but only if changed)
2      | `:wall` (write all buffers)

To enable this, add the following (with the desired value) to your ~/.vimrc:

```vim
" Write all buffers before navigating from Vim to tmux pane
let g:proper_tmux_navigator_save_on_switch = 2
```

##### Disable While Zoomed

By default, if you zoom the tmux pane running Vim and then attempt to navigate
"past" the edge of the Vim session, tmux will unzoom the pane. This is the
default tmux behavior, but may be confusing if you've become accustomed to
navigation "wrapping" around the sides due to this plugin.

We provide an option, `g:proper_tmux_navigator_disable_when_zoomed`, which can be used
to disable this unzooming behavior, keeping all navigation within Vim until the
tmux pane is explicitly unzoomed.

To disable navigation when zoomed, add the following to your ~/.vimrc:

```vim
" Disable tmux navigator when zooming the Vim pane
let g:proper_tmux_navigator_isable_when_zoomed = 1
```
or flip maybe
let g:proper_tmux_navigator_stick_to_visible = 0

#### Tmux

Alter each of the five lines of the tmux configuration listed above to use your
custom mappings. **Note** each line contains two references to the desired
mapping.

### Additional Customization

#### Restoring Clear Screen (C-l)

The default key bindings include `<Ctrl-l>` which is the readline key binding
for clearing the screen. The following binding can be added to your `~/.tmux.conf` file to provide an alternate mapping to `clear-screen`.

``` tmux
bind C-l send-keys 'C-l'
```

With this enabled you can use `<prefix> C-l` to clear the screen.

Thanks to [Brian Hogan][] for the tip on how to re-map the clear screen binding.

#### Nesting
If you like to nest your tmux sessions, this plugin is not going to work
properly. It probably never will, as it would require detecting when Tmux would
wrap from one outermost pane to another and propagating that to the outer
session.

By default this plugin works on the outermost tmux session and the vim
sessions it contains, but you can customize the behaviour by adding more
commands to the expression used by the grep command.

When nesting tmux sessions via ssh or mosh, you could extend it to look like
`'(^|\/)g?(view|vim|ssh|mosh?)(diff)?$'`, which makes this plugin work within
the innermost tmux session and the vim sessions within that one. This works
better than the default behaviour if you use the outer Tmux sessions as relays
to different hosts and have all instances of vim on remote hosts.

Similarly, if you like to nest tmux locally, add `|tmux` to the expression.

This behaviour means that you can't leave the innermost session with Ctrl-hjkl
directly. These following fallback mappings can be targeted to the right Tmux
session by escaping the prefix (Tmux' `send-prefix` command).

``` tmux
bind -r C-h run "tmux select-pane -L"
bind -r C-j run "tmux select-pane -D"
bind -r C-k run "tmux select-pane -U"
bind -r C-l run "tmux select-pane -R"
bind -r C-\ run "tmux select-pane -l"
```

Troubleshooting
---------------

### Vim -> Tmux doesn't work!

This is likely due to conflicting key mappings in your `~/.vimrc`. You can use
the following search pattern to find conflicting mappings
`\vn(nore)?map\s+\<c-[hjkl]\>`. Any matching lines should be deleted or
altered to avoid conflicting with the mappings from the plugin.

Another option is that the pattern matching included in the `.tmux.conf` is
not recognizing that Vim is active. To check that tmux is properly recognizing
Vim, use the provided Vim command `:TmuxPaneCurrentCommand`. The output of
that command should be a string like 'vim', 'Vim', 'vimdiff', etc. If you
encounter a different output please [open an issue][] with as much info about
your OS, Vim version, and tmux version as possible.

[open an issue]: https://github.com/christoomey/vim-tmux-navigator/issues/new


### It feels too slow

`:time system('echo')`

If you find that navigation within Vim (from split to split) is fine, but Vim
to a non-Vim tmux pane is delayed, it might be due to a slow shell startup.
Consider moving code from your shell's non-interactive rc file (e.g.,
`~/.zshenv`) into the interactive startup file (e.g., `~/.zshrc`) as Vim only
sources the non-interactive config.


### It Still Doesn't Work!!!

The tmux configuration uses an inlined grep pattern match to help determine if
the current pane is running Vim. If you run into any issues with the navigation
not happening as expected, you can try using [Mislav's original external
script][] which has a more robust check.

[Brian Hogan]: https://twitter.com/bphogan
[Mislav Marohnić's]: http://mislav.uniqpath.com/
[Mislav's original external script]: https://github.com/mislav/dotfiles/blob/master/bin/tmux-vim-select-pane
[TPM]: https://github.com/tmux-plugins/tpm
[configuration section below]: #custom-key-bindings
[this blog post]: http://www.codeography.com/2013/06/19/navigating-vim-and-tmux-splits
[this gist]: https://gist.github.com/mislav/5189704
