"Vimteractive
"
" A vim plugin to send line(s) from the current buffer to a terminal bufffer
"
"  author : Will Handley <williamjameshandley@cam.ac.uk>
"    date : 2018-06-20
" licence : GPL 3.0

" Plugin variables
" ================

" Variables for running the various sessions
if !has_key(g:, 'vimteractive_commands')
	let g:vimteractive_commands = { }
endif

if !exists('g:vimteractive_termina')
    let g:vimteractive_terminal = 'xterm -e'
endif

let g:slime_target = 'tmux'

let g:vimteractive_commands.ipython = "ipython --matplotlib --no-autoindent --logfile='-o <LOGFILE>'"
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
let g:vimteractive_commands.gpt = 'gpt --log_file <LOGFILE>'

" Override default shells for different filetypes
if !has_key(g:, 'vimteractive_default_shells')
	let g:vimteractive_default_shells = { }
endif

let g:vimteractive_get_response = {
            \ 'ipython': function('vimteractive#get_response_ipython'),
            \ 'sgpt': function('vimteractive#get_response_sgpt'),
            \ 'gpt': function('vimteractive#get_response_gpt')
            \}

" Plugin commands
" ===============

if !has_key(g:, 'vimteractive_loaded')
	let g:vimteractive_loaded = 1

	" Building :I* commands (like :Ipython, :Iipython and so)
	for repl_type in keys(g:vimteractive_commands)
		execute 'command! -nargs=? I' . repl_type . " :call vimteractive#repl_start('" . repl_type . "', <f-args>)"
	endfor

	command! Iterm :call vimteractive#repl_start('-auto-')
	command! -nargs=? -complete=customlist,vimteractive#get_pane_names Iconn
		\ :call vimteractive#connect(<f-args>)
endif


" Plugin key mappings
" ===================

" Control-S in normal or insert mode to send current line
nnoremap <silent> <C-s> :<c-u>call vimteractive#send_lines(v:count1)<cr>
inoremap <silent> <C-s> <C-o>:let save_cursor = getpos('.')<CR><Esc>:<c-u>call vimteractive#send_lines(v:count1)<cr>:call setpos('.', save_cursor)<CR>i

" Control-S in visual mode to send multiple lines
vnoremap <silent> <C-s> :<c-u>call vimteractive#send_op(visualmode(), 1)<cr>

" Alt-S in normal mode to send all lines up to this point TODO: Fix this
nnoremap <silent> <A-s> :<c-u>call vimteractive#send_range(1,'.')<cr>

" Control-Y in normal mode to get last response
noremap  <silent> <C-y>      :put =vimteractive#get_response()<CR>
inoremap <silent> <C-y> <C-o>:let save_cursor = getpos('.')<CR><Esc>:put =vimteractive#get_response()<CR>:call setpos('.', save_cursor)<CR>i 

" cycle through terminal buffers in the style of unimpaired
nnoremap <silent> ]v :call vimteractive#next_term()<CR>
nnoremap <silent> [v :call vimteractive#prev_term()<CR>
