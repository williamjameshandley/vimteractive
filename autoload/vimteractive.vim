" Vimteractive implementation
"
" Variables
" s:vimteractive_buffers
"   script-local variable that keeps track of vimteractive terminal buffers
"
" b:vimteractive_connected_term
"   buffer-local variable held by buffer that indicates the name of the
"   connected terminal buffer
"
" b:vimteractive_term_type
"   buffer-local variable held by terminal buffer that indicates the terminal type
"
" b:uid
"   buffer-local variable held by terminal buffer that indicates a
"   time-dependent UID for disambiguating per-session files


" Initialise the list of terminal buffer numbers on startup
if !exists('s:vimteractive_buffers')
    let s:vimteractive_buffers = []
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

    if get(g:vimteractive_bracketed_paste, l:term_type, g:vimteractive_bracketed_paste_default)
        call term_sendkeys(b:vimteractive_connected_term,"[200~" . a:lines . "[201~\n")
    else
        call term_sendkeys(b:vimteractive_connected_term, a:lines . "\n")
    endif
endfunction

function! vimteractive#get_output()

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

    " Generate a time-dependent UID for naming the terminal command etc
    let b:uid = strftime('%Y-%m-%d-%H:%M:%S')
    let l:term_command = substitute(l:term_command, 'UID', b:uid, '')

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
    if (l:term_type == 'sgpt')
        let l:cache_path = getenv('CHAT_CACHE_PATH')
        if l:cache_path == v:null
            let l:cache_path = '/tmp/shell_gpt/chat_cache'
        endif
        let l:filename = l:cache_path . '/vimteractive-UID'
        let l:filename = substitute(l:filename, 'UID', b:uid, '')
        let l:json_content = join(readfile(l:filename), "\n")
        let l:json_data = json_decode(l:json_content)
        if len(l:json_data) > 0
            let l:last_response = l:json_data[-1]['content']
            return l:last_response
        endif
    elseif (l:term_type == 'Ipython')
        let l:cache_loc = '/tmp/vimteractive_ipython-UID'
        let l:filename = substitute(l:cache_loc, 'UID', b:uid, '')
        let lines = readfile(l:filename)
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
    endif
endfunction
