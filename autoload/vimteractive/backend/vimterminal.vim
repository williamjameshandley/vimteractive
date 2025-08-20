" Vim terminal backend implementation for vimteractive

" Start a vimteractive terminal using vim's native terminal
function! vimteractive#backend#vimterminal#repl_start(...) abort
    " Check for terminal support
    if !exists("*term_start")
        echoerr "vimteractive: vim terminal support requires vim built with :terminal support"
        return
    endif

    " Get common REPL information
    let l:repl_info = call('vimteractive#common#prepare_repl_info', a:000)

    " Pass any environment variables necessary for logging
    let $CHAT_CACHE_PATH="/" " sgpt logfiles

    " Save current window to return to it
    let l:winid = win_getid()

    " Set slime target for this backend
    let g:slime_target = 'vimterminal'

    " Start the terminal with the REPL command
    let l:term_options = {}
    if exists('g:vimteractive_vimterminal_config')
        let l:term_options = g:vimteractive_vimterminal_config
    endif
    let l:term_options['term_name'] = l:repl_info.repl_name
    let l:bufnr = term_start(l:repl_info.full_command, l:term_options)

    " Set the buffer name for identification
    execute 'file ' . l:repl_info.repl_name

    " Store buffer info for connection
    let b:vimteractive_repl_type = l:repl_info.repl_type
    let b:vimteractive_logfile = l:repl_info.logfile_name

    " Return to original window
    call win_gotoid(l:winid)

    " Connect to the new terminal
    call vimteractive#backend#vimterminal#connect(l:bufnr)
endfunction

" Get list of terminal buffers
function! vimteractive#backend#vimterminal#get_terminals() abort
    let l:bufs = filter(term_list(), "term_getstatus(v:val) =~ 'running'")
    let l:result = []
    for l:bufnr in l:bufs
        let l:bufinfo = getbufinfo(l:bufnr)[0]
        let l:name = l:bufinfo.name
        " Only include vimteractive terminals (those with our naming pattern)
        if l:name =~ '/tmp/.*-\(' . join(keys(g:vimteractive_commands), '\|') . '\)'
            call add(l:result, {'bufnr': l:bufnr, 'name': l:name})
        endif
    endfor
    return l:result
endfunction

" Get terminal sessions for completion
function! vimteractive#backend#vimterminal#get_repl_sessions() abort
    let l:terminals = vimteractive#backend#vimterminal#get_terminals()
    return map(l:terminals, 'v:val.name')
endfunction

" Get terminal buffer numbers
function! vimteractive#backend#vimterminal#get_buffer_ids() abort
    let l:terminals = vimteractive#backend#vimterminal#get_terminals()
    return map(l:terminals, 'v:val.bufnr')
endfunction

" Get the current terminal name
function! vimteractive#backend#vimterminal#pane_name() abort
    if !exists('b:slime_config') || !has_key(b:slime_config, 'bufnr')
        echoerr "No terminal connected"
        return ""
    endif
    let l:bufnr = b:slime_config.bufnr
    return bufname(l:bufnr)
endfunction

" Determine REPL type from terminal name
function! vimteractive#backend#vimterminal#repl_type() abort
    let l:name = vimteractive#backend#vimterminal#pane_name()
    for l:repl_type in keys(g:vimteractive_commands)
        if matchstr(l:name, '-' . l:repl_type) != ''
            return l:repl_type
        endif
    endfor
    echoerr "Could not determine terminal type from buffer name"
    return ""
endfunction

" Get logfile name
function! vimteractive#backend#vimterminal#logfile_name() abort
    return vimteractive#backend#vimterminal#pane_name() . '.log'
endfunction

" Connect to vimteractive terminal
function! vimteractive#backend#vimterminal#connect(...) abort
    let l:terminals = vimteractive#backend#vimterminal#get_terminals()
    
    if a:0 == 0 && len(l:terminals) == 1
        " If no argument and only one terminal, connect to it
        let l:bufnr = l:terminals[0].bufnr
    elseif a:0 > 0
        " If argument provided, it could be bufnr or name
        if type(a:1) == type(0)
            " It's a buffer number
            let l:bufnr = a:1
        else
            " It's a name, find the corresponding buffer
            for l:term in l:terminals
                if l:term.name == a:1
                    let l:bufnr = l:term.bufnr
                    break
                endif
            endfor
        endif
    else
        " Multiple terminals, need to choose
        let l:choices = []
        for l:idx in range(len(l:terminals))
            let l:term = l:terminals[l:idx]
            call add(l:choices, printf("%2d. %s (buffer %d)", l:idx + 1, l:term.name, l:term.bufnr))
        endfor
        let l:choice = inputlist(l:choices)
        if l:choice > 0 && l:choice <= len(l:terminals)
            let l:bufnr = l:terminals[l:choice - 1].bufnr
        else
            return
        endif
    endif

    " Validate buffer exists and is a terminal
    if !bufexists(l:bufnr) || term_getstatus(l:bufnr) !~ 'running'
        echoerr "Invalid terminal buffer"
        return
    endif

    " Set up slime configuration
    let b:slime_config = {'bufnr': l:bufnr}
    let b:slime_target = 'vimterminal'
    let g:slime_target = 'vimterminal'
    let b:vimteractive_backend = 'vimterminal'
    
    " Determine REPL type and set bracketed paste
    let l:name = bufname(l:bufnr)
    for l:repl_type in keys(g:vimteractive_commands)
        if matchstr(l:name, '-' . l:repl_type) != ''
            if index(g:vimteractive_bracketed_paste, l:repl_type) != -1
                let b:slime_bracketed_paste = 1
            else
                let b:slime_bracketed_paste = 0
            endif
            break
        endif
    endfor
    
    echo "Connected to " . bufname(l:bufnr)
endfunction

" Check if terminal needs to be shown
function! vimteractive#backend#vimterminal#show_term() abort
    if !exists('b:slime_config') || !has_key(b:slime_config, 'bufnr')
        call vimteractive#backend#vimterminal#repl_start()
        return
    endif
    let l:bufnr = b:slime_config.bufnr
    if !bufexists(l:bufnr) || term_getstatus(l:bufnr) !~ 'running'
        call vimteractive#backend#vimterminal#repl_start()
    endif
endfunction

" Get response from REPL
function! vimteractive#backend#vimterminal#get_response() abort
    let l:repl_type = vimteractive#backend#vimterminal#repl_type()
    if has_key(g:vimteractive_get_response, l:repl_type)
        if l:repl_type == 'aichat'
            let l:response = vimteractive#backend#vimterminal#get_response_aichat()
        else
            " Use common log-based response functions
            let l:logfile_name = vimteractive#backend#vimterminal#logfile_name()
            let l:response = vimteractive#common#get_response_{l:repl_type}(l:logfile_name)
        endif
        if g:vimteractive_extract_markdown_code_blocks
            let l:response = vimteractive#common#extract_markdown_code_blocks(l:response)
        endif
        return l:response
    else
        echoerr "Response retrieval not implemented for " . l:repl_type
        return ""
    endif
endfunction

" Get the last response from the aichat terminal
function! vimteractive#backend#vimterminal#get_response_aichat() abort
    if !exists('b:slime_config') || !has_key(b:slime_config, 'bufnr')
        echoerr "No terminal connected"
        return ""
    endif
    
    let l:bufnr = b:slime_config.bufnr
    if !bufexists(l:bufnr) || term_getstatus(l:bufnr) !~ 'running'
        echoerr "Terminal buffer not running"
        return ""
    endif

    " Get the terminal name for prompt detection
    let l:repl_name = bufname(l:bufnr)
    let l:prompt = fnamemodify(l:repl_name, ':t')
    let l:prompt = substitute(l:prompt, '-' . vimteractive#backend#vimterminal#repl_type(), '', '')

    " Get all lines from the terminal buffer
    let lines = getbufline(l:bufnr, 1, '$')

    " Find the last two prompts and extract text between them
    let i = len(lines) - 1
    while i > 0 && match(lines[i], l:prompt) == -1
        let i -= 1
    endwhile
    let j = i - 1
    while j > 0 && match(lines[j], l:prompt) == -1
        let j -= 1
    endwhile
    return join(lines[j+1:i-1], "\n")
endfunction

" Cycle connection forward through terminal buffers
function! vimteractive#backend#vimterminal#next_term() abort
    let l:buffer_ids = vimteractive#backend#vimterminal#get_buffer_ids()
    if !exists('b:slime_config') || !has_key(b:slime_config, 'bufnr')
        if len(l:buffer_ids) > 0
            call vimteractive#backend#vimterminal#connect(l:buffer_ids[0])
        endif
        return
    endif
    let l:current_index = index(l:buffer_ids, b:slime_config.bufnr) 
    let l:next_index = (l:current_index + 1) % len(l:buffer_ids)
    call vimteractive#backend#vimterminal#connect(l:buffer_ids[l:next_index])
endfunction

" Cycle connection backward through terminal buffers
function! vimteractive#backend#vimterminal#prev_term() abort
    let l:buffer_ids = vimteractive#backend#vimterminal#get_buffer_ids()
    if !exists('b:slime_config') || !has_key(b:slime_config, 'bufnr')
        if len(l:buffer_ids) > 0
            call vimteractive#backend#vimterminal#connect(l:buffer_ids[-1])
        endif
        return
    endif
    let l:current_index = index(l:buffer_ids, b:slime_config.bufnr) 
    let l:prev_index = (l:current_index - 1 + len(l:buffer_ids)) % len(l:buffer_ids)
    call vimteractive#backend#vimterminal#connect(l:buffer_ids[l:prev_index])
endfunction