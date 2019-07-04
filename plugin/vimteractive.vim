"Vimteractive
"
" A vim plugin to send line(s) from the current buffer to a terminal bufffer
"
"  author : Will Handley <williamjameshandley@cam.ac.uk>
"    date : 2018-06-20
" licence : GPL 3.0

" Plugin variables
" ================

" Name of the vimteractive terminal buffer
let g:vimteractive_buffer_name = "vimteractive_buffer"
let g:vimteractive_terminal = ''
let g:current_term_type = ''

" Variables for running the various sessions
"
if !has_key(g:, 'vimteractive_commands')
	let g:vimteractive_commands = { }
endif

let g:vimteractive_commands.ipython = 'ipython --matplotlib --no-autoindent'
let g:vimteractive_commands.python = 'python'
let g:vimteractive_commands.bash = 'bash'
let g:vimteractive_commands.zsh = 'zsh'
let g:vimteractive_commands.julia = 'julia'
let g:vimteractive_commands.maple = 'maple -c "interface(errorcursor=false);"'
let g:vimteractive_commands.clojure = 'clojure'

" Override default shells for different filetypes
if !has_key(g:, 'vimteractive_default_shells')
	let g:vimteractive_default_shells = { }
endif

" If 0, disable bracketed paste escape sequences
let g:vimteractive_bracketed_paste = {
	\ 'clojure': 0
	\ }

if !has_key(g:, 'vimteractive_loaded')
	let g:vimteractive_loaded = 1

	for term_type in keys(g:vimteractive_commands)
		execute 'command! I' . term_type . " :call vimteractive#session('" . term_type . "')"
	endfor

	command! Iterm :call vimteractive#session('-auto-')
endif

" Control-S in normal mode to send current line
noremap  <silent> <C-s>      :call vimteractive#sendline(getline('.'))<CR>

" Control-S in insert mode to send current line
inoremap <silent> <C-s> <Esc>:call vimteractive#sendline(getline('.'))<CR>a

" Control-S in visual mode to send multiple lines
vnoremap <silent> <C-s> <Esc>:call vimteractive#sendlines(getline("'<","'>"))<CR>

" Alt-S in normal mode to send all lines up to this point
noremap <silent> <A-s> :call vimteractive#sendlines(getline(1,'.'))<CR>


" Plugin Behaviour
" ================

" Switch to normal mode when entering terminal window
autocmd BufEnter * if &buftype == 'terminal' && bufname('%') == g:vimteractive_buffer_name | call feedkeys("\<C-W>N")  | endif

" Switch back to terminal mode when exiting
autocmd BufLeave * if &buftype == 'terminal'  && bufname('%') == g:vimteractive_buffer_name | execute "silent! normal! i"  | endif
