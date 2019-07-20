" Initialise the list of terminal buffer numbers on startup
if !exists('s:term_bufnrs')
    let s:term_bufnrs = []
end

" List the terminal buffer numbers
function! TermBufnrs()
    return copy(s:term_bufnrs)
endfunction

" Add a terminal to the list.
function! s:add_term(term_bufname)
    let term_bufnr = bufnr(a:term_bufname)
    call add(s:term_bufnrs, term_bufnr)
endfunction

" Remove a terminal from the list on deletion.
function! s:del_term()
    let term_bufname = expand('<afile>')
    let term_bufnr = bufnr(term_bufname)
    let term_index = index(s:term_bufnrs, term_bufnr)
    if term_index >= 0
        call remove(s:term_bufnrs, term_index)
    endif
endfunction

" Listen for Buffer close events if they're in the terminal list
autocmd BufDelete * call <SID>del_term()


" (Re)open a terminal buffer in a split window
function! s:show_term(bufnr)
	split
	execute ":b " . g:vimteractive_terminal[a:bufnr]
	wincmd p
endfunction

" Check terminal exists, and clean out any unused variables if it does not
function! s:check_alive(bufnr)
	if bufexists(g:vimteractive_terminal[a:bufnr])
		return 1
	else
		unlet g:vimteractive_terminal[a:bufnr]
		unlet g:vimteractive_current_term_type[a:bufnr]
		return 0
	endif
endfunction

" List all running terminal names
function! vimteractive#term_list(...)
    return map(s:term_bufnrs, 'bufname(v:val)')
endfunction

" Send list of lines to the terminal buffer, surrounded with a bracketed paste
function! vimteractive#sendlines(lines)
	let l:bufnr = bufnr('%')
	let l:term_buffer_name = get(g:vimteractive_terminal, l:bufnr, -1)
	if l:term_buffer_name == -1 || !s:check_alive(l:bufnr)
		if g:vimteractive_autostart
			call vimteractive#session('-auto-')
			let l:term_buffer_name = get(g:vimteractive_terminal, l:bufnr, -1)
			while term_getline(l:term_buffer_name, 1) == ''
				sleep 10m " Waiting for prompt
			endwhile
			let l:slow = get(g:vimteractive_slow_prompt, g:vimteractive_current_term_type[l:bufnr])
			if l:slow
				execute "sleep " . l:slow . "m"
			endif
			redraw
		else
			echoerr "Nowhere to send lines, call :Iterm first"
			return
		endif
	endif
	let l:term_type = g:vimteractive_current_term_type[l:bufnr]

	if bufwinnr(l:term_buffer_name) == -1
		call s:show_term(l:bufnr)
	endif

	if get(g:vimteractive_bracketed_paste, l:term_type, 1)
		call term_sendkeys(l:term_buffer_name,"[200~" . join(a:lines, "\n") . "[201~\n")
	else
		call term_sendkeys(l:term_buffer_name, join(a:lines, "\n") . "\n")
	endif
endfunction

" Start a vimteractive session
function! vimteractive#session(terminal_type)
    if has('terminal') == 0
        echoerr "Your version of vim is not compiled with +terminal. Cannot use vimteractive"
        return
    endif

	let l:bufnr = bufnr('%')
	let l:terminal_type = a:terminal_type
	if a:terminal_type ==# '-auto-'
		let term_type = get(g:vimteractive_default_shells, &filetype, &filetype)
		if has_key(g:vimteractive_commands, term_type)
			let l:terminal = get(g:vimteractive_commands, term_type)
			let l:terminal_type = term_type
		else
			echoerr "Cannot determine terminal commmand for filetype " . &filetype
			return
		endif
	else
		let l:terminal = get(g:vimteractive_commands, a:terminal_type)
	endif

	" If we have already running Vimteractive terminal
    if has_key(g:vimteractive_terminal, l:bufnr) && s:check_alive(l:bufnr)
		if g:vimteractive_current_term_type[l:bufnr] == l:terminal
			if bufwinnr(g:vimteractive_terminal[l:bufnr]) == -1
				call s:show_term(l:bufnr)
			else
				echom "Terminal of type " . l:terminal_type . " already running for this buffer"
			endif
		else
			echoerr "Cannot run: " . l:terminal
				\ ". Already running: " . g:vimteractive_terminal[l:bufnr]
		endif
		return
    endif

	let l:term_buffer_name = "term_" . l:terminal_type
	let i = 1
	while bufnr(l:term_buffer_name) != -1
		let l:term_buffer_name = "term_" . l:terminal_type . '_' . i
		let i += 1
	endwhile

	echom "Starting " . l:terminal
	" Else we want to create a new term
	call term_start(l:terminal, {
		\ "term_name": l:term_buffer_name,
		\ "term_finish": "close",
		\ "term_kill": "term"
		\ })
    call s:add_term(l:term_buffer_name)

	" Turn line numbering off
	set nonumber norelativenumber
	" Switch to terminal-normal mode when entering buffer
	autocmd BufEnter <buffer> call feedkeys("\<C-W>N")
	" Switch to insert mode when leaving buffer
	autocmd BufLeave <buffer> execute "silent! normal! i"
	" Make :quit really do the right thing
	cabbrev <buffer> q bdelete! "
	cabbrev <buffer> qu bdelete! "
	cabbrev <buffer> qui bdelete! "
	cabbrev <buffer> quit bdelete! "

	" Return to previous window
	wincmd p

	" Store name and type of current buffer
	let g:vimteractive_terminal[l:bufnr] = l:term_buffer_name
	let g:vimteractive_current_term_type[l:bufnr] = l:terminal_type
endfunction

" Connect to vimteractive session
function! vimteractive#connect(buffer_name = '')
	let l:buffer_name = a:buffer_name
	if strlen(a:buffer_name) ==# 0
		let all_terms = s:term_list()
		if len(all_terms) ==# 1
			let l:buffer_name = all_terms[0]
		else
			echom "Please, specify terminal"
			return
		endif
	endif

	if !bufexists(l:buffer_name)
		echoerr "Buffer " . l:buffer_name . " is not found or already disconnected"
		return
	endif

	let l:bufnr = bufnr('%')

	let g:vimteractive_terminal[l:bufnr] = l:buffer_name
	let g:vimteractive_current_term_type[l:bufnr] =
		\ substitute(l:buffer_name, '^term_\(.*\)\(_[0-9]\+\)\=$', '\1', '')
	echom "Connected " . bufname("%") . " to " . l:buffer_name
endfunction


