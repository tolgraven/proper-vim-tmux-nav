if exists('g:loaded_proper_tmux_navigator') || &cp || v:version < 700 | finish | endif
let g:loaded_proper_tmux_navigator = 1

let g:proper_tmux_navigator_save_on_switch = get(g:, 'proper_tmux_navigator_save_on_switch', 0)
let g:proper_tmux_navigator_disable_when_zoomed = get(g:, 'proper_tmux_navigator_disable_when_zoomed', 0)
function! s:TmuxOrTmateExecutable() 			"no harm keeping support for this I guess? Tho is it the reason for the fancy socket dance bs?
  return (match($TMUX, 'tmate') != -1 ? 'tmate' : 'tmux')
endfunction

function! s:UseTmuxNavigatorMappings()
  let preset = get(g:, 'proper_tmux_navigator_mapping_preset', '')
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

let s:tmux_is_last_pane = 0
augroup proper_tmux_navigator | autocmd!
  autocmd WinEnter * let s:tmux_is_last_pane = 0
augroup END

" Like `wincmd` but also change tmux panes instead of vim windows when needed.
function! s:TmuxWinCmd(direction)
  if s:InTmuxSession()		| call s:TmuxAwareNavigate(a:direction)
  else										| call s:VimNavigate(a:direction)
  endif
endfunction

function! s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)
  if g:proper_tmux_navigator_disable_when_zoomed && s:TmuxVimPaneIsZoomed() | return 0 | endif
  return a:tmux_last_pane || a:at_tab_page_edge
endfunction

function! s:TmuxAwareNavigate(direction)
  let nr = winnr()
	let s:saved_shell = &shell | set shell=bash 		"not sure whether to run with this or just stick to debug. But for me system('echo') thru fish is like 0.07s (after fixing a bunch of stuff, like 0.3 priot?), zsh 0.07?, bash 0.01...
	"but then again it all definitely pales in comparison with just killing airling or whatever
	"fucking hell what's going on with that.
  let tmux_last_pane = (a:direction == 'p' && s:tmux_is_last_pane)
  if !tmux_last_pane | call s:VimNavigate(a:direction) | endif
  let at_tab_page_edge = (nr == winnr()) 	"did we get anywhere?
  " Forward the switch panes command to tmux if:
  " a) we're toggling between the last tmux pane
  " b) we tried switching windows in vim but it didn't have effect.
  if s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)
    if g:proper_tmux_navigator_save_on_switch == 1
      try 	| update 	" save the active buffer. See :help update
      catch /^Vim\%((\a\+)\)\=:E32/ " catches the no file name error
      endtry
    elseif g:proper_tmux_navigator_save_on_switch == 2
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

	" noautocmd execute 'wincmd ' . a:direction 			
	" execute 'noautocmd wincmd ' . a:direction			|"no duh, breaks diminactive etc
	" execute 'wincmd ' . a:direction
endfunction

function! s:DeferredAutocmdsCallback(...) abort

endfunction


function! s:TmuxAwareResize(sign, amount) 	"resize window by direction instead of +- etc
	if winnr('$') == 1	| let pass_to_tmux = 1
	else								| let initial = winnr() 	"save the original window index
		let isvert = (a:sign =~ '<\|>') ? 'vertical ' : ''
		let anchor = (isvert == 'vertical ') ? 'h' : 'k'
		let prefix = (a:sign =~ '<\|-') ? '-' : '+'
		execute 'noautocmd wincmd ' . anchor
		if winnr()	!= initial 	"did find other window towards anchor point
			"edge case: trying to resize from bottom/right window if have three, flips. so test moving again...
			let new = winnr() | execute 'noautocmd wincmd ' . anchor
			if winnr() != new   "did find third win. Anchor is flipped, so change strategy
				execute 'noautocmd ' . initial . 'wincmd w'
				execute 'noautocmd ' . isvert . 'resize ' .(prefix == '+' ? '-' : '+').a:amount
			else			"no third window this direction
				execute 'noautocmd ' . isvert . 'resize ' .prefix.a:amount
				execute 'noautocmd ' . initial . 'wincmd w'
			endif
		else				"try other side
			execute 'noautocmd wincmd ' . (anchor == 'h' ? 'l' : 'j')
			if winnr() != initial	"moved away from anchor. switch back, then resize
				execute 'noautocmd' . initial . 'wincmd w'
				execute 'noautocmd ' . isvert . ' resize ' .prefix.a:amount
			else 	| let pass_to_tmux = 1 | endif	"def nothing to resize in vim
		endif
	endif

	if get(l:, 'pass_to_tmux', 0)
			let vim_to_tmux ={ '<':'-L', '>':'-R', '+':'-D', '-':'-U' }
			let tmuxcmd = vim_to_tmux[a:sign]
			execute 'call system("tmux resize-pane' . tmuxcmd .' '. a:amount '")'
	endif
endfunction

let s:TmuxResizeAmount = 2

" command! TmuxNavigateLeft			call s:TmuxWinCmd('h')
" command! TmuxNavigateDown			call s:TmuxWinCmd('j')
" command! TmuxNavigateUp				call s:TmuxWinCmd('k')
" command! TmuxNavigateRight		call s:TmuxWinCmd('l')
" command! TmuxNavigatePrevious call s:TmuxWinCmd('p')
noremap <silent> <Plug>TmuxNavigateLeft 		:call <SID>TmuxWinCmd('h')<CR>
noremap <silent> <Plug>TmuxNavigateDown 		:call <SID>TmuxWinCmd('j')<CR>
noremap <silent> <Plug>TmuxNavigateUp 			:call <SID>TmuxWinCmd('k')<CR>
noremap <silent> <Plug>TmuxNavigateRight 		:call <SID>TmuxWinCmd('l')<CR>
noremap <silent> <Plug>TmuxNavigatePrevious :call <SID>TmuxWinCmd('p')<CR>
" noremap	<silent> <Plug>TmuxResizeLeft 			:call <SID>TmuxAwareResize('<', s:TmuxResizeAmount * 2)<CR>
" noremap	<silent> <Plug>TmuxResizeDown 			:call <SID>TmuxAwareResize('+', s:TmuxResizeAmount)<CR>
" noremap <silent> <Plug>TmuxResizeUp 				:call <SID>TmuxAwareResize('-', s:TmuxResizeAmount)<CR>
" noremap <silent> <Plug>TmuxResizeRight 			:call <SID>TmuxAwareResize('>', s:TmuxResizeAmount * 2)<CR>
noremap	<silent> <Plug>TmuxResizeLeft 			:call <SID>TmuxAwareResize('<', 4)<CR>
noremap	<silent> <Plug>TmuxResizeDown 			:call <SID>TmuxAwareResize('+', 2)<CR>
noremap <silent> <Plug>TmuxResizeUp 				:call <SID>TmuxAwareResize('-', 2)<CR>
noremap <silent> <Plug>TmuxResizeRight 			:call <SID>TmuxAwareResize('>', 4)<CR>

" if s:UseTmuxNavigatorMappings()
	nmap	<M-H> 				<Plug>TmuxResizeLeft
	nmap	<M-J> 				<Plug>TmuxResizeDown
	nmap 	<M-K> 				<Plug>TmuxResizeUp
	nmap 	<M-L> 				<Plug>TmuxResizeRight
	" noremap	 	<silent> <M-H> 				:call s:TmuxAwareResize('<', 4)<CR>
	" noremap	 	<silent> <M-J> 				:call s:TmuxAwareResize('+', 2)<CR>
	" noremap 	<silent> <M-K> 				:call s:TmuxAwareResize('-', 2)<CR>
	" noremap 	<silent> <M-L> 				:call s:TmuxAwareResize('>', 4)<CR>
	" inoremap 	<silent> <M-H> 	 <C-O>:call s:TmuxAwareResize('<', 4)<CR>
	" inoremap 	<silent> <M-J> 	 <C-O>:call s:TmuxAwareResize('+', 2)<CR>
	" inoremap 	<silent> <M-K> 	 <C-O>:call s:TmuxAwareResize('-', 2)<CR>
	" inoremap 	<silent> <M-L> 	 <C-O>:call s:TmuxAwareResize('>', 4)<CR>

	noremap <silent> <Leader>hh 		:call s:TmuxAwareResize('<', 15)<CR>
	noremap <silent> <Leader>jj 		:call s:TmuxAwareResize('+', 10)<CR>
	noremap <silent> <Leader>kk 		:call s:TmuxAwareResize('-', 10)<CR>
	noremap <silent> <Leader>ll 		:call s:TmuxAwareResize('>', 15)<CR>
  " nnoremap <silent> <c-h> :TmuxNavigateLeft<cr>
  " nnoremap <silent> <c-j> :TmuxNavigateDown<cr>
  " nnoremap <silent> <c-k> :TmuxNavigateUp<cr>
  " nnoremap <silent> <c-l> :TmuxNavigateRight<cr>
  " nnoremap <silent> <c-\> :TmuxNavigatePrevious<cr>
  nmap  <M-h> <Plug>TmuxNavigateLeft
  nmap  <M-j> <Plug>TmuxNavigateDown
  nmap  <M-k> <Plug>TmuxNavigateUp
  nmap  <M-l> <Plug>TmuxNavigateRight
  nmap  <M-z> <Plug>TmuxNavigatePrevious
" endif
