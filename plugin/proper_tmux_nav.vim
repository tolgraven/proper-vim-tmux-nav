if exists('g:loaded_proper_tmux_nav') || &compatible || v:version < 700 | finish | endif
let g:loaded_proper_tmux_nav = 1

let g:proper_tmux_nav_save_on_switch = get(g:, 'proper_tmux_nav_save_on_switch', 	0)
let g:proper_tmux_nav_disable_zoomed = get(g:, 'proper_tmux_nav_disable_zoomed', 	0)
let g:proper_tmux_nav_small_resize 	 = get(g:, 'proper_tmux_nav_small_resize', 		2)
let g:proper_tmux_nav_large_resize 	 = get(g:, 'proper_tmux_nav_large_resize', 		g:proper_tmux_nav_small_resize * 5)
let g:proper_tmux_nav_mapping_preset = get(g:, 'proper_tmux_nav_mapping_preset', '')

function! s:TmuxOrTmateExecutable() 			"no harm keeping support for this I guess? Tho is it the reason for the fancy socket dance bs?
  return (match($TMUX, 'tmate') != -1 ? 'tmate' : 'tmux')
endfunction

function! s:InTmuxSession()
  return $TMUX != ''
endfunction

function! s:TmuxVimPaneIsZoomed()
  return s:TmuxCommand("display-message -p '#{window_zoomed_flag}'") == 1
endfunction

function! s:TmuxSocket() "The socket path is the first value in the comma-separated list of $TMUX.
  return split($TMUX, ',')[0]
endfunction

function! s:TmuxCommand(args)
  " let cmd = s:TmuxOrTmateExecutable() . ' -S ' . s:TmuxSocket() . ' ' . a:args
	let cmd = 'tmux '	. a:args	"like seriously do we need the socket? Seems to always pick the right on right up front from what I vcan tell
  return system(cmd)
endfunction

function! s:TmuxPaneCurrentCommand()
  echo s:TmuxCommand("display-message -p '#{pane_current_command}'")
endfunction
command! TmuxPaneCurrentCommand call s:TmuxPaneCurrentCommand()

function! s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)
  if g:proper_tmux_nav_disable_zoomed && s:TmuxVimPaneIsZoomed() | return 0 | endif
  return a:tmux_last_pane || a:at_tab_page_edge
endfunction


let s:tmux_is_last_pane = 0
augroup proper_tmux_nav | autocmd!
  autocmd WinEnter * let s:tmux_is_last_pane = 0
augroup END


" Like `wincmd` but also change tmux panes instead of vim windows when needed.
function! s:TmuxWinCmd(direction)
  if s:InTmuxSession()		| call s:TmuxAwareNavigate(a:direction)
  else										| call s:VimNavigate(a:direction)
  endif
endfunction


function! s:TmuxAwareNavigate(direction)
  let nr = winnr()
	let s:saved_shell = &shell | set shell=bash 		"not sure whether to run with this or just stick to debug. But for me system('echo') thru fish is like 0.07s (after fixing a bunch of stuff, like 0.3 priot?), zsh 0.07?, bash 0.01...
	"but then again it all definitely pales in comparison with just killing airline or whatever, fucking hell what's going on with that.
  let tmux_last_pane = (a:direction == 'p' && s:tmux_is_last_pane)
  if !tmux_last_pane | call s:VimNavigate(a:direction) | endif
  let at_tab_page_edge = (nr == winnr()) 	"did we get anywhere?
  " Forward the switch panes command to tmux if:
  " a) we're toggling between the last tmux pane
  " b) we tried switching windows in vim but it didn't have effect.
  if s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)
    if g:proper_tmux_nav_save_on_switch == 1
      try 	| update 	" save the active buffer. See :help update
      catch /^Vim\%((\a\+)\)\=:E32/ " catches the no file name error
      endtry
    elseif g:proper_tmux_nav_save_on_switch == 2
      try 	| wall 		" save all the buffers. See :help wall
      catch /^Vim\%((\a\+)\)\=:E141/ " catches the no file name error
      endtry
    endif
    let args = 'select-pane -t ' . shellescape($TMUX_PANE) . ' -' . tr(a:direction, 'phjkl', 'lLDUR')
    silent call s:TmuxCommand(args)
    let s:tmux_is_last_pane = 1
  else
    let s:tmux_is_last_pane = 0
  endif
	let &shell = s:saved_shell
endfunction


function! s:WindowMaximize()
	let numwindows = winnr('$')
	if numwindows == 1 | call system('tmux resize-pane -Z')
	else 							 | execute 'MaximizerToggle!'	 
	endif
endfunction


function! s:VimNavigate(direction) abort
  try
    execute 'wincmd ' . a:direction
  catch
    echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd k' | echohl None
  endtry

	" let s:timer = timer_start(100, function('s:DeferredAutocmdsCallback'))
endfunction

function! s:DeferredAutocmdsCallback(...) abort

endfunction


let s:vim_to_tmux ={ '<':'-L', '>':'-R', '+':'-D', '-':'-U' }
"XXX: cant resize smaller than like 10 wide, weird cause eg tinykeymap doesnt share that issue
function! s:TmuxAwareResize(sign, amount) 			"resize window by direction instead of +- etc
	if winnr('$') == 1	| let pass_to_tmux = 1 		"only one vim window, go straight to tmux
	else								| let initial = winnr() 	"save the original window index
		let isvert = (a:sign =~ '<\|>') ? 'vertical ' : ''
		let anchor = (isvert == 'vertical ') ? 'h' : 'k'
		let prefix = (a:sign =~ '<\|-') ? '-' : '+'
		execute 'noautocmd wincmd ' . anchor
		if winnr()	!= initial 	"did find other window towards anchor point
			"edge case: trying to resize from bottom/right window if have three, flips. so test moving again...
			"DUMB: breaks again with four in a row. should prob handle that, then give up because fuck the kind of person with five windows in one single dimension
			let new = winnr() | execute 'noautocmd wincmd ' . anchor
			if winnr() != new   	"did find third win. Anchor is flipped, so change strategy
				execute 'noautocmd ' . initial . 'wincmd w'
				execute 'noautocmd ' . isvert . 'resize ' .(prefix == '+' ? '-' : '+').a:amount
			else									"no third window this direction
				execute 'noautocmd ' . isvert . 'resize ' .prefix.a:amount
				execute 'noautocmd ' . initial . 'wincmd w'
			endif
		else										"try other side
			execute 'noautocmd wincmd ' . (anchor == 'h' ? 'l' : 'j')
			if winnr() != initial	"moved away from anchor. switch back, then resize
				execute 'noautocmd' . initial . 'wincmd w'
				execute 'noautocmd ' . isvert . ' resize ' .prefix.a:amount
			else 	| let pass_to_tmux = 1 | endif	"def nothing to resize in vim
		endif
	endif

	if get(l:, 'pass_to_tmux', 0)
			let tmuxcmd = s:vim_to_tmux[a:sign]
			execute 'call system("tmux resize-pane' . tmuxcmd .' '. a:amount '")'
	endif
endfunction


noremap <silent> <Plug>TmuxNavigateLeft 		:call <SID>TmuxWinCmd('h')<CR>
noremap <silent> <Plug>TmuxNavigateDown 		:call <SID>TmuxWinCmd('j')<CR>
noremap <silent> <Plug>TmuxNavigateUp 			:call <SID>TmuxWinCmd('k')<CR>
noremap <silent> <Plug>TmuxNavigateRight 		:call <SID>TmuxWinCmd('l')<CR>
noremap <silent> <Plug>TmuxNavigatePrevious :call <SID>TmuxWinCmd('p')<CR>

noremap	<silent> <Plug>TmuxResizeLeft 			:call <SID>TmuxAwareResize('<', g:proper_tmux_nav_small_resize * 2)<CR>
noremap	<silent> <Plug>TmuxResizeDown 			:call <SID>TmuxAwareResize('+', g:proper_tmux_nav_small_resize)<CR>
noremap <silent> <Plug>TmuxResizeUp 				:call <SID>TmuxAwareResize('-', g:proper_tmux_nav_small_resize)<CR>
noremap <silent> <Plug>TmuxResizeRight 			:call <SID>TmuxAwareResize('>', g:proper_tmux_nav_small_resize * 2)<CR>
noremap <silent> <Plug>TmuxResizeLargeLeft 	:call <SID>TmuxAwareResize('<', float2nr(g:proper_tmux_nav_large_resize * 1.5))<CR>
noremap <silent> <Plug>TmuxResizeLargeDown 	:call <SID>TmuxAwareResize('+', float2nr(g:proper_tmux_nav_large_resize))<CR>
noremap <silent> <Plug>TmuxResizeLargeUp 		:call <SID>TmuxAwareResize('-', float2nr(g:proper_tmux_nav_large_resize))<CR>
noremap <silent> <Plug>TmuxResizeLargeRight :call <SID>TmuxAwareResize('>', float2nr(g:proper_tmux_nav_large_resize * 1.5))<CR>

" if s:UseTmuxNavigatorMappings()
	nmap	<M-H> 				<Plug>TmuxResizeLeft
	nmap	<M-J> 				<Plug>TmuxResizeDown
	nmap 	<M-K> 				<Plug>TmuxResizeUp
	nmap 	<M-L> 				<Plug>TmuxResizeRight
	imap	<M-H> 				<Plug>TmuxResizeLeft
	imap	<M-J> 				<Plug>TmuxResizeDown
	imap 	<M-K> 				<Plug>TmuxResizeUp
	imap 	<M-L> 				<Plug>TmuxResizeRight

	nmap  <Leader>hh 		<Plug>TmuxResizeLargeLeft
	nmap  <Leader>jj 		<Plug>TmuxResizeLargeDown
	nmap  <Leader>kk 		<Plug>TmuxResizeLargeUp
	nmap  <Leader>ll 		<Plug>TmuxResizeLargeRight

  nmap  <M-h> 				<Plug>TmuxNavigateLeft
  nmap  <M-j> 				<Plug>TmuxNavigateDown
  nmap  <M-k> 				<Plug>TmuxNavigateUp
  nmap  <M-l> 				<Plug>TmuxNavigateRight
  nmap  <M-z> 				<Plug>TmuxNavigatePrevious
  imap  <M-h> 				<Plug>TmuxNavigateLeft
  imap  <M-j> 				<Plug>TmuxNavigateDown
  imap  <M-k> 				<Plug>TmuxNavigateUp
  imap  <M-l> 				<Plug>TmuxNavigateRight
  imap  <M-z> 				<Plug>TmuxNavigatePrevious
" endif
