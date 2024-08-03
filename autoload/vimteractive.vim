" Vimteractive implementation
"
" Variables
" s:vimteractive_buffers
"   script-local variable that keeps track of vimteractive terminal buffers
"
" s:vimteractive_logfiles
"   script-local variable that keeps track of logfiles for each terminal
"
" b:vimteractive_connected_term
"   buffer-local variable held by buffer that indicates the name of the
"   connected terminal buffer
"
" b:vimteractive_term_type
"   buffer-local variable held by terminal buffer that indicates the terminal type

" Initialise the list of terminal buffer numbers on startup
if !exists('s:vimteractive_buffers')
    let s:vimteractive_buffers = []
end

" Initialise the list of logfiles on startup
if !exists('s:vimteractive_logfiles')
    let s:vimteractive_logfiles = {}
end

" Remove a terminal from the list on deletion.
function! s:del_term()
    let l:term_bufname = expand('<afile>')
    let l:term_bufnr = bufnr(term_bufname)
    let l:term_index = index(s:vimteractive_buffers, l:term_bufnr)
    if l:term_index >= 0
        call remove(s:vimteractive_buffers, l:term_index)
    endif
endfunction


" Reopen a terminal buffer in a split window if necessary
function! s:show_term()
    let l:open_bufnrs = map(range(1, winnr('$')), 'winbufnr(v:val)')
    if index(l:open_bufnrs, bufnr(b:vimteractive_connected_term))  == -1
        split
        execute ":b " . b:vimteractive_connected_term
        wincmd p
    endif
endfunction


" Generate a new terminal name
function! s:new_name(term_type)
    " Create a new terminal name
    let l:term_bufname = "term_" . a:term_type
    let i = 1
    while bufnr(l:term_bufname) != -1
        let l:term_bufname = "term_" . a:term_type . '_' . i
        let i += 1
    endwhile
    return l:term_bufname
endfunction


" Listen for Buffer close events if they're in the terminal list
autocmd BufDelete * call <SID>del_term()


" List all running terminal names
function! vimteractive#buffer_list(...)
    let l:vimteractive_buffers = copy(s:vimteractive_buffers)
    return map(l:vimteractive_buffers, 'bufname(v:val)')
endfunction


" Send list of lines to the terminal buffer, surrounded with a bracketed paste
function! vimteractive#sendlines(lines)
    " Autostart a terminal if desired
    if !exists("b:vimteractive_connected_term")
        if g:vimteractive_autostart
            call vimteractive#term_start('-auto-')
        else
            echoerr "No terminal connected."
            echoerr "call :Iterm to start a new one, or :Iconn to connect to an existing one"
            return
        endif
    endif

    " Check if connected terminal is still alive
    if index(s:vimteractive_buffers, b:vimteractive_connected_term) == -1
        echoerr "Vimteractive terminal " . b:vimteractive_connected_term . " has been deleted"
        echoerr "call :Iterm to start a new one, or :Iconn to connect to an existing one"
        return
    endif

    call s:show_term()

    let l:term_type = getbufvar(b:vimteractive_connected_term, "vimteractive_term_type")

    " Switch to insert mode if the terminal is currently in normal mode
    let l:term_status = term_getstatus(b:vimteractive_connected_term)
    if stridx(l:term_status,"normal") != -1
        let l:current_buffer = bufnr('%')
        execute ":b " . b:vimteractive_connected_term 
        execute "silent! normal! i"
        execute ":b " . l:current_buffer
    endif

    if match(a:lines, '\n') >= 0
        if has_key(g:vimteractive_brackets, l:term_type)
            let open_bracket = g:vimteractive_brackets[l:term_type][0]
            let close_bracket = g:vimteractive_brackets[l:term_type][1]
        else
            let open_bracket = g:open_bracketed_paste
            let close_bracket = g:close_bracketed_paste
        endif
        let b:lines = open_bracket . a:lines . close_bracket . "\<Enter>"
    else
        let b:lines = a:lines . "\<Enter>"
    endif
    call term_sendkeys(b:vimteractive_connected_term, b:lines)
endfunction

" Start a vimteractive terminal
function! vimteractive#term_start(term_type, ...)
    if has('terminal') == 0
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
        return
    endif

    " Determine the terminal type
    if a:term_type ==# '-auto-'
        let l:term_type = get(g:vimteractive_default_shells, &filetype, &filetype)
    else
        let l:term_type = a:term_type
    endif

    " Name the buffer
    let l:term_bufname = s:new_name(l:term_type)

    " Retrieve starting command
    if has_key(g:vimteractive_commands, l:term_type)
        let l:term_command = get(g:vimteractive_commands, l:term_type)
    else
        echoerr "Cannot determine terminal commmand for type " . l:term_type
        return
    endif

    " Assign a logfile name
    let l:logfile = tempname() . '-' . l:term_type . '.log'
    let l:term_command = substitute(l:term_command, '<LOGFILE>', l:logfile, '')

    " Pass any environment variables necessary for logging
    let $CHAT_CACHE_PATH="/" " sgpt logfiles

    " Add all other arguments to the command
    let l:term_command = l:term_command . ' ' . join(a:000, ' ')

    " Create a new term
    echom "Starting " . l:term_command
    if v:version < 801
        call term_start(l:term_command, {
            \ "term_name": l:term_bufname,
            \ "term_finish": "close",
            \ "vertical": g:vimteractive_vertical
            \ })
    else
        call term_start(l:term_command, {
            \ "term_name": l:term_bufname,
            \ "term_kill": "term",
            \ "term_finish": "close",
            \ "vertical": g:vimteractive_vertical
            \ })
    endif

    " Add this terminal to the buffer list, and store type
    call add(s:vimteractive_buffers, bufnr(l:term_bufname))
    let b:vimteractive_term_type = l:term_type
    let s:vimteractive_logfiles[bufnr(l:term_bufname)] = l:logfile

    " Turn line numbering off
    set nonumber norelativenumber
    if g:vimteractive_switch_mode
        " Switch to terminal-normal mode when entering buffer
        autocmd BufEnter <buffer> call feedkeys("\<C-W>N")
    endif
    " Make :quit really do the right thing
    cabbrev <buffer> q bdelete! "
    cabbrev <buffer> qu bdelete! "
    cabbrev <buffer> qui bdelete! "
    cabbrev <buffer> quit bdelete! "
    " Return to previous window
    wincmd p

    " Store name and type of current buffer
    let b:vimteractive_connected_term = bufnr(l:term_bufname)

    " Pause as necessary
    while term_getline(b:vimteractive_connected_term, 1) == ''
        sleep 10m " Waiting for prompt
    endwhile
    if get(g:vimteractive_slow_prompt, l:term_type)
        execute "sleep " . l:slow . "m"
    endif
    redraw

endfunction


" Connect to vimteractive terminal
function! vimteractive#connect(...)
    " Check that there are buffers to connect to
    if len(s:vimteractive_buffers) == 0
        echoerr "No vimteractive terminal buffers present"
        echoerr "call :Iterm to start a new one"
        return
    endif

    " Check if there was an argument passed to this function
    if a:0 == 0
        let l:bufname = ''
    else
        let l:bufname = a:1
    endif

    " Check if bufname isn't just ''
    if l:bufname == ''
        if len(s:vimteractive_buffers) ==# 1
            let l:bufname = vimteractive#buffer_list()[0]
        else
            echom "Please specify terminal from "
            echom vimteractive#buffer_list()
            return
        endif
    endif

    if !bufexists(l:bufname)
        echoerr "Buffer " . l:bufname . " is not found or already disconnected"
        return
    endif

    let b:vimteractive_connected_term = bufnr(l:bufname)
    echom "Connected " . bufname("%") . " to " . l:bufname

endfunction

function! vimteractive#get_response()
    let l:term_type = getbufvar(b:vimteractive_connected_term, "vimteractive_term_type")
    return g:vimteractive_get_response[l:term_type]()
endfunction

" Get the last response from the terminal for sgpt
function! vimteractive#get_response_sgpt()
    let l:logfile = s:vimteractive_logfiles[b:vimteractive_connected_term]
    let l:json_content = join(readfile(l:logfile), "\n")
    let l:json_data = json_decode(l:json_content)
    if len(l:json_data) > 0
        let l:last_response = l:json_data[-1]['content']
        return l:last_response
    endif
endfunction


" Get the last response from the terminal for gpt-command-line
function! vimteractive#get_response_gpt()
    let l:logfile = s:vimteractive_logfiles[b:vimteractive_connected_term]
    let log_data = readfile(l:logfile)
    let log_data_str = join(log_data, "\n")

    let last_session_index = strridx(log_data_str, 'gptcli-session - INFO - assistant: ')
    let end_text = strpart(log_data_str, last_session_index+35)
    let price_index = match(end_text, 'gptcli-price')
    let last_price_index = strridx(end_text, "\n", price_index-1)
    return strpart(end_text, 0, last_price_index)
endfunction


" Get the last response from the terminal for ipython
function! vimteractive#get_response_ipython()
    let l:logfile = s:vimteractive_logfiles[b:vimteractive_connected_term]
    let lines = readfile(l:logfile)
    let block = []
    for i in range(len(lines) - 1, 0, -1)
        if match(lines[i], '^#\[Out\]#') == 0
            let line = substitute(lines[i], '^#\[Out\]# ', '', '')
            call add(block, line)
        else
            break
        endif
    endfor
    let block = reverse(block)
    return join(block, "\n")
endfunction

" Cycle connection forward through terminal buffers
function! vimteractive#next_term()
    let l:current_buffer = b:vimteractive_connected_term 
    let l:current_index = index(s:vimteractive_buffers, l:current_buffer)
    let l:next_index = (l:current_index + 1) % len(s:vimteractive_buffers)
    call vimteractive#connect(vimteractive#buffer_list()[l:next_index])
endfunction

" Cycle connection backward through terminal buffers
function! vimteractive#prev_term()
    let l:current_buffer = b:vimteractive_connected_term
    let l:current_index = index(s:vimteractive_buffers, l:current_buffer)
    let l:prev_index = (l:current_index - 1 + len(s:vimteractive_buffers)) % len(s:vimteractive_buffers)
    call vimteractive#connect(vimteractive#buffer_list()[l:prev_index])
endfunction
