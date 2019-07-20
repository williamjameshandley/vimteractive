" Vimteractive implementation
"
" Variables
" s:vimteractive_buffers
"   script-local variable that keeps track of vimteractive terminal buffers
"
" b:vimteractive_connected_terminal
"   buffer-local variable held by buffer that indicates the name of the
"   connected terminal buffer
"
" b:vimteractive_terminal_type
"   buffer-local variable held by terminal buffer that indicates the terminal type


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


" Listen for Buffer close events if they're in the terminal list
autocmd BufDelete * call <SID>del_term()

" List all running terminal names
function! vimteractive#buffer_list(...)
    let l:vimteractive_buffers = copy(s:vimteractive_buffers)
    return map(l:vimteractive_buffers, 'bufname(v:val)')
endfunction


" Reopen a terminal buffer in a split window if necessary
function! s:show_term()
    let l:open_bufnrs = map(range(1, winnr('$')), 'winbufnr(v:val)')
    if index(l:open_bufnrs, bufnr(b:vimteractive_connected_terminal))  == -1
        split
        execute ":b " . b:vimteractive_connected_terminal
        wincmd p
    endif
endfunction


" Send list of lines to the terminal buffer, surrounded with a bracketed paste
function! vimteractive#sendlines(lines)
    " Autostart a terminal if desired
    if !exists("b:vimteractive_connected_terminal") 
		if g:vimteractive_autostart
            call vimteractive#term_start('-auto-')
		else
			echoerr "No terminal connected."
            echoerr "call :Iterm to start a new one, or :Iconn to connect to an existing one"
			return
		endif
    endif

    " Check if connected terminal is still alive
    if index(s:vimteractive_buffers, b:vimteractive_connected_terminal) == -1
        echoerr "Vimteractive terminal " . b:vimteractive_connected_terminal . " has been deleted"
        echoerr "call :Iterm to start a new one, or :Iconn to connect to an existing one"
        return
    endif

    call s:show_term()

	let l:term_type = getbufvar(b:vimteractive_connected_terminal, "term_type")
	if get(g:vimteractive_bracketed_paste, l:term_type, 1)
		call term_sendkeys(b:vimteractive_connected_terminal,"[200~" . join(a:lines, "\n") . "[201~\n")
	else
		call term_sendkeys(b:vimteractive_connected_terminal, join(a:lines, "\n") . "\n")
	endif
endfunction

" Generate a new terminal name

function! s:new_name(terminal_type)
    " Create a new terminal name
	let l:term_bufname = "term_" . a:terminal_type
	let i = 1
	while bufnr(l:term_bufname) != -1
		let l:term_bufname = "term_" . a:terminal_type . '_' . i
		let i += 1
	endwhile
    return l:term_bufname
endfunction


" Start a vimteractive terminal
function! vimteractive#term_start(terminal_type)
    if has('terminal') == 0
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
        return
    endif

    " Determine the terminal type
	if a:terminal_type ==# '-auto-'
		let l:terminal_type = get(g:vimteractive_default_shells, &filetype, &filetype)
	else
        let l:terminal_type = a:terminal_type
	endif

    " Retrieve starting command
    if has_key(g:vimteractive_commands, l:terminal_type)
        let l:terminal_command = get(g:vimteractive_commands, l:terminal_type)
    else
        echoerr "Cannot determine terminal commmand for filetype " . &filetype
        return
    endif

	" Create a new term
	echom "Starting " . l:terminal_command
    let l:term_bufname = s:new_name(l:terminal_type)
	call term_start(l:terminal_command, {
		\ "term_name": l:term_bufname,
		\ "term_finish": "close",
		\ "term_kill": "term"
		\ })

    " Add this terminal to the buffer list, and store type
    call add(s:vimteractive_buffers, bufnr(l:term_bufname))
    let b:vimteractive_terminal_type = l:terminal_type

	" Turn line numbering off
	set nonumber norelativenumber
	" Switch to terminal-normal mode when entering buffer
	autocmd BufEnter <buffer> call feedkeys("\<C-W>N")
	" Switch to insert mode when leaving buffer
	autocmd BufLeave <buffer> execute "silent! normal! i"
	" Return to previous window
	wincmd p

	" Store name and type of current buffer
    let b:vimteractive_connected_terminal = bufnr(l:term_bufname)

    " Pause as necessary
    while term_getline(b:vimteractive_connected_terminal, 1) == ''
        sleep 10m " Waiting for prompt
    endwhile
    if get(g:vimteractive_slow_prompt, l:terminal_type)
        execute "sleep " . l:slow . "m"
    endif
    redraw

endfunction


" Connect to vimteractive terminal
function! vimteractive#connect(buffer_name = '')
	let l:buffer_name = a:buffer_name
	if strlen(a:buffer_name) ==# 0
		if len(s:vimteractive_buffers) ==# 1
			let l:buffer_name = vimteractive#buffer_list()[0] 
		else
			echom "Please specify terminal from "
            echom vimteractive#buffer_list()
			return
		endif
	endif

	if !bufexists(l:buffer_name)
		echoerr "Buffer " . l:buffer_name . " is not found or already disconnected"
		return
	endif

    let b:vimteractive_connected_terminal = bufnr(l:buffer_name)
	echom "Connected " . bufname("%") . " to " . l:buffer_name

endfunction
