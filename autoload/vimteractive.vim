" vimteractive implementation - dispatcher for backend implementations

" Helper function to dispatch calls to the correct backend
function! s:dispatch(func, args) abort
    " Get backend from buffer variable, fallback to global
    let l:backend = get(b:, 'vimteractive_backend', g:vimteractive_backend)
    
    let l:func_name = 'vimteractive#backend#' . l:backend . '#' . a:func
    return call(l:func_name, a:args)
endfunction

" Helper function to determine REPL type
function! vimteractive#determine_repl_type(...) abort
    if a:0 == 0
        if has_key(g:vimteractive_commands, &filetype)
            let l:repl_type = &filetype
        else
            let l:repl_type = g:vimteractive_default_repl
        endif
    else
        let l:repl_type = a:1
    endif
    let l:repl_type = get(g:vimteractive_default_repls, l:repl_type, l:repl_type)
    return l:repl_type
endfunction

" Public interface functions that dispatch to backends

" Start a vimteractive terminal
function! vimteractive#repl_start(...) abort
    return s:dispatch('repl_start', a:000)
endfunction

" Connect to vimteractive terminal
function! vimteractive#connect(...) abort
    return s:dispatch('connect', a:000)
endfunction

" Show terminal if necessary
function! vimteractive#show_term() abort
    return s:dispatch('show_term', [])
endfunction

" Get response from terminal
function! vimteractive#get_response() abort
    return s:dispatch('get_response', [])
endfunction

" Get list of REPL sessions for completion
function! vimteractive#get_pane_names(...) abort
    return s:dispatch('get_repl_sessions', a:000)
endfunction

" Cycle connection forward through terminals
function! vimteractive#next_term() abort
    return s:dispatch('next_term', [])
endfunction

" Cycle connection backward through terminals
function! vimteractive#prev_term() abort
    return s:dispatch('prev_term', [])
endfunction

" Send functions that use vim-slime

function! vimteractive#send_lines(count) abort
    call vimteractive#show_term()
    call slime#send_lines(a:count)
endfunction

function! vimteractive#send_op(type, ...) abort
    call vimteractive#show_term()
    call slime#send_op(a:type, a:000)
endfunction

function! vimteractive#send_range(startline, endline) abort
    call vimteractive#show_term()
    call slime#send_range(a:startline, a:endline)
endfunction

" Response retrieval functions that map to common implementations
function! vimteractive#get_response_ipython() abort
    return vimteractive#common#get_response_ipython(s:dispatch('logfile_name', []))
endfunction

function! vimteractive#get_response_sgpt() abort
    return vimteractive#common#get_response_sgpt(s:dispatch('logfile_name', []))
endfunction

function! vimteractive#get_response_gpt() abort
    return vimteractive#common#get_response_gpt(s:dispatch('logfile_name', []))
endfunction

function! vimteractive#get_response_zsh() abort
    return vimteractive#common#get_response_zsh(s:dispatch('logfile_name', []))
endfunction

function! vimteractive#get_response_aichat() abort
    " This one is backend-specific
    return s:dispatch('get_response_aichat', [])
endfunction

" Backward compatibility functions
function! vimteractive#get_panes(...) abort
    " Only works with tmux backend
    if get(b:, 'vimteractive_backend', g:vimteractive_backend) == 'tmux'
        return vimteractive#backend#tmux#get_panes()
    else
        return []
    endif
endfunction

function! vimteractive#get_pane_ids(...) abort
    " Only works with tmux backend
    if get(b:, 'vimteractive_backend', g:vimteractive_backend) == 'tmux'
        return vimteractive#backend#tmux#get_pane_ids()
    else
        return []
    endif
endfunction

function! vimteractive#pane_name() abort
    return s:dispatch('pane_name', [])
endfunction

function! vimteractive#repl_type() abort
    return s:dispatch('repl_type', [])
endfunction

function! vimteractive#logfile_name() abort
    return s:dispatch('logfile_name', [])
endfunction

function! vimteractive#extract_markdown_code_blocks(input) abort
    return vimteractive#common#extract_markdown_code_blocks(a:input)
endfunction