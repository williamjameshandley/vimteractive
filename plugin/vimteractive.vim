"Vimteractive
"
" A vim plugin to send line(s) from the current buffer to a terminal bufffer
"
"  author : Will Handley <williamjameshandley@cam.ac.uk>
"    date : 2018-06-20
" licence : GPL 3.0

" Plugin variables
" ================

" Automatically start default terminal on first ^S
if !has_key(g:, 'vimteractive_autostart')
	let g:vimteractive_autostart = 1
endif

" Start in a horizontal terminal by default
if !has_key(g:, 'vimteractive_vertical')
    let g:vimteractive_vertical = 0
endif

" Switch to normal mode when entering the buffer by default
if !has_key(g:, 'vimteractive_switch_mode')
    let g:vimteractive_switch_mode = 1
endif

" Variables for running the various sessions
if !has_key(g:, 'vimteractive_commands')
	let g:vimteractive_commands = { }
endif

let g:vimteractive_commands.ipython = 'ipython --matplotlib --no-autoindent --logfile="-o <LOGFILE>"'
let g:vimteractive_commands.python = 'python'
let g:vimteractive_commands.bash = 'bash'
let g:vimteractive_commands.zsh = 'zsh'
let g:vimteractive_commands.julia = 'julia'
let g:vimteractive_commands.maple = 'maple -c "interface(errorcursor=false);"'
let g:vimteractive_commands.clojure = 'clojure'
let g:vimteractive_commands.apl = 'apl'
let g:vimteractive_commands.R = 'R'
let g:vimteractive_commands.mathematica = 'math'
let g:vimteractive_commands.sgpt = 'sgpt --repl <LOGFILE>'

" Override default shells for different filetypes
if !has_key(g:, 'vimteractive_default_shells')
	let g:vimteractive_default_shells = { }
endif

" If 0, disable bracketed paste escape sequences
if !has_key(g:, 'vimteractive_bracketed_paste_default')
    let g:vimteractive_bracketed_paste_default=1
endif
if !has_key(g:, 'vimteractive_bracketed_paste')
	let g:vimteractive_bracketed_paste = { }
endif
let g:vimteractive_bracketed_paste.clojure = 0
let g:vimteractive_bracketed_paste.python = 0
let g:vimteractive_bracketed_paste.python2 = 0
let g:vimteractive_bracketed_paste.python3 = 0
let g:vimteractive_bracketed_paste.apl = 0
let g:vimteractive_bracketed_paste.mathematica = 0

" If present, wait this amount of time in ms when starting term on ^S
if !has_key(g:, 'vimteractive_slow_prompt')
	let g:vimteractive_slow_prompt = { }
endif
let g:vimteractive_slow_prompt.clojure = 200

let g:vimteractive_get_response = {
            \ 'ipython': function('vimteractive#get_response_ipython'),
            \ 'sgpt': function('vimteractive#get_response_sgpt')
            \}

" Plugin commands
" ===============

if !has_key(g:, 'vimteractive_loaded')
	let g:vimteractive_loaded = 1

	" Building :I* commands (like :Ipython, :Iipython and so)
	for term_type in keys(g:vimteractive_commands)
		execute 'command! -nargs=? I' . term_type . " :call vimteractive#term_start('" . term_type . "', <f-args>)"
	endfor

	command! Iterm :call vimteractive#term_start('-auto-')
	command! -nargs=? -complete=customlist,vimteractive#buffer_list Iconn
		\ :call vimteractive#connect(<f-args>)
endif


" Plugin key mappings
" ===================

" Control-S in normal mode to send current line
noremap  <silent> <C-s>      :call vimteractive#sendlines(getline('.'))<CR>

" Control-S in insert mode to send current line
inoremap <silent> <C-s> <Esc>:call vimteractive#sendlines(getline('.'))<CR>a

" Control-S in visual mode to send multiple lines
vnoremap <silent> <C-s> m`""y:call vimteractive#sendlines(substitute(getreg('"'), "\n*$", "", ""))<CR>``

" Alt-S in normal mode to send all lines up to this point
noremap <silent> <A-s> :call vimteractive#sendlines(join(getline(1,'.'), "\n"))<CR>

" Control-Y in normal mode to get last response
noremap  <silent> <C-y>      :put =vimteractive#get_response()<CR>

" Control-Y in insert mode to get last response
inoremap <silent> <C-y> <Esc>:put =vimteractive#get_response()<CR>a

" cycle through terminal buffers in the style of unimpaired
nnoremap ]v :call vimteractive#next_term()<CR>
nnoremap [v :call vimteractive#prev_term()<CR>
