"Vimteractive
"
" A vim plugin to send line(s) from the current buffer to a terminal bufffer
"
"  author : Will Handley <williamjameshandley@cam.ac.uk>
"    date : 2018-06-20
" licence : GPL 3.0

" Plugin variables
" ================

" The name of the vimteractive terminal buffer
let g:vimteractive_buffer_name = "Vimteractive"
let g:vimteractive_terminal = ''

" User commands
" =============

" Commands to start a session
command!  Iipython :call Vimteractive_session('ipython --matplotlib --no-autoindent') 
command!  Ipython  :call Vimteractive_session('python')  
command!  Ibash    :call Vimteractive_session('bash')
command!  Imaple   :call Vimteractive_session('maple -c "interface(errorcursor=false);"')

" Control-S in normal mode to send current line
noremap  <silent> <C-s>      :call Vimteractive_sendline(getline('.'))<CR>

" Control-S in insert mode to send current line
inoremap <silent> <C-s> <Esc>:call Vimteractive_sendline(getline('.'))<CR>a

" Control-S in visual mode to send multiple lines
vnoremap <silent> <C-s> <Esc>:call Vimteractive_sendlines(getline("'<","'>"))<CR>


" Plugin commands
" ===============

" Send a line to the terminal buffer
function! Vimteractive_sendline(line)
    call term_sendkeys(g:vimteractive_buffer_name, a:line."\n")
endfunction

" Send list of lines one at a time to the terminal buffer
function! Vimteractive_sendlines(lines)
    for l in a:lines
        call Vimteractive_sendline(l)
        " Pause to let prompt catch up
        sleep 50m
    endfor
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

" Deactivate global variable on deletion
autocmd BufDelete,QuitPre * if &buftype == 'terminal' | let g:vimteractive_terminal='' | execute ":bd " . g:vimteractive_buffer_name  | endif
