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
let g:vimteractive_buffer_name = "Vimteractive"
let g:vimteractive_terminal = ''

" Variables for running the various sessions
let g:vimteractive_ipython_command = 'ipython --matplotlib --no-autoindent'
let g:vimteractive_python_command = 'python'
let g:vimteractive_bash_command = 'bash'
let g:vimteractive_maple_command = 'maple -c "interface(errorcursor=false);"'

" User commands
" =============

" Commands to start a session
command!  Iipython :call Vimteractive_session(g:vimteractive_ipython_command) 
command!  Ipython  :call Vimteractive_session(g:vimteractive_python_command)  
command!  Ibash    :call Vimteractive_session(g:vimteractive_bash_command)
command!  Imaple   :call Vimteractive_session(g:vimteractive_maple_command)

" Control-S in normal mode to send current line
noremap  <silent> <C-s>      :call Vimteractive_sendline(getline('.'))<CR>

" Control-S in insert mode to send current line
inoremap <silent> <C-s> <Esc>:call Vimteractive_sendline(getline('.'))<CR>a

" Control-S in visual mode to send multiple lines
vnoremap <silent> <C-s> <Esc>:call Vimteractive_sendlines(getline("'<","'>"))<CR>

" Alt-S in normal mode to send all lines up to this point
noremap <silent> <A-s> :call Vimteractive_sendlines(getline(1,'.'))<CR>


" Plugin commands
" ===============

" Send a line to the terminal buffer
function! Vimteractive_sendline(line)
    call term_sendkeys(g:vimteractive_buffer_name, a:line."\n")
endfunction

" Send list of lines one at a time to the terminal buffer
function! Vimteractive_sendlines(lines)
    call term_sendkeys(g:vimteractive_buffer_name,"[200~" . join(a:lines, "\n") . "[201~\n")
endfunction

" Start a vimteractive session
function! Vimteractive_session(terminal)

    if has('terminal') == 0
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
        return
    endif

    if g:vimteractive_terminal != '' && g:vimteractive_terminal != a:terminal
        echoerr "Cannot run: " . a:terminal " Alreading running: " . g:vimteractive_terminal
        return
    endif

    if bufnr(g:vimteractive_buffer_name) == -1
        " If no vimteractive buffer exists:
        " Start the terminal
        let job = term_start(a:terminal, {"term_name":g:vimteractive_buffer_name})
        " Unlist the buffer
        set nobuflisted
        " Return to the previous window
        wincmd p
        " Name the current terminal
        let g:vimteractive_terminal = a:terminal

    elseif bufwinnr(g:vimteractive_buffer_name) == -1
        " Else if vimteractive buffer not open:
        " Split the window
        split
        " switch the top window to the vimteractive buffer
        execute ":b " . g:vimteractive_buffer_name
        " Return to the previous window
        wincmd p

    else
        " Else if throw error
        echoerr "vimteractive already open. Quit before opening a new buffer"
    endif
endfunction


" Plugin Behaviour
" ================

" Switch to normal mode when entering terminal window
autocmd BufEnter * if &buftype == 'terminal' | call feedkeys("\<C-W>N")  | endif

" Switch back to terminal mode when exiting
autocmd BufLeave * if &buftype == 'terminal' | silent! normal! i  | endif
