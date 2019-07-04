" Send list of lines to the terminal buffer, surrounded with a bracketed paste
function! vimteractive#sendlines(lines)
	if get(g:vimteractive_bracketed_paste, g:current_term_type, 1)
		call term_sendkeys(g:vimteractive_buffer_name,"[200~" . join(a:lines, "\n") . "[201~\n")
	else
		call term_sendkeys(g:vimteractive_buffer_name, join(a:lines, "\n") . "\n")
	endif
endfunction

" Send a line to the terminal buffer
function! vimteractive#sendline(line)
	call vimteractive#sendlines([a:line])
endfunction

" Start a vimteractive session
function! vimteractive#session(terminal_type)

    if has('terminal') == 0
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
        return
    endif

	if a:terminal_type == '-auto-'
		let term_type = get(g:vimteractive_default_shells, &filetype, &filetype)
		if has_key(g:vimteractive_commands, term_type)
			let l:terminal = get(g:vimteractive_commands, term_type)
			let g:current_term_type = term_type
		else
			echoerr "Cannot determine terminal commmand for filetype " . &filetype
			return
		endif
	else
		let l:terminal = get(g:vimteractive_commands, a:terminal_type)
		let g:current_term_type = a:terminal_type
	endif

    if g:vimteractive_terminal != '' && g:vimteractive_terminal != l:terminal
        echoerr "Cannot run: " . l:terminal " Alreading running: " . g:vimteractive_terminal
        return
    endif

    if bufnr(g:vimteractive_buffer_name) == -1
        " If no vimteractive buffer exists:
        " Start the terminal
        let job = term_start(l:terminal, {"term_name":g:vimteractive_buffer_name})
        set nobuflisted                          " Unlist the buffer
        set norelativenumber                     " Turn off line numbering if off
        set nonumber                             " Turn off line numbering if off
        wincmd p                                 " Return to the previous window
        let g:vimteractive_terminal = l:terminal " Name the current terminal

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

