" Setup plugin mappings for the most common ways to interact with the terminal.
noremap  <C-s>      :call term_sendkeys("vimteractive", getline('.')."\n")<CR>
inoremap <C-s> <Esc>:call term_sendkeys("vimteractive", getline('.')."\n")<CR>a
xnoremap <C-S>      :call term_sendkeys("vimteractive", getreg('*'))<CR> 


function! Vimteractive_session(command)
    if has('terminal') 
        " Start the terminal
        let job = term_start(a:command, {"term_name":"vimteractive ".a:command})
        " Return to the previous window
        wincmd p
    else
        " Send error message
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
    endif
endfunction

" Setup plugin mappings for the most common ways to interact with ipython.
command!  Iipython :call Vimteractive_session('ipython --simple-prompt') 
command!  Ipython  :call Vimteractive_session('python')  
command!  Ibash    :call Vimteractive_session('bash')
command!  Imaple   :call Vimteractive_session('maple -c "interface(errorcursor=false);"')


