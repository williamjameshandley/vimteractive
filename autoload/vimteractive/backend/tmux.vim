" Tmux backend implementation for vimteractive

" Start a vimteractive terminal using tmux
function! vimteractive#backend#tmux#repl_start(...) abort
    " Get common REPL information
    let l:repl_info = call('vimteractive#common#prepare_repl_info', a:000)
    
    " Define the tmux command
    let l:tmux_command = "tmux new-session -dP -F '#{pane_id}:#{session_name}:' -n " . l:repl_info.repl_name

    " Now join them all together
    let l:xrepl_command = printf('%s "%s; read"', l:tmux_command, l:repl_info.full_command)

    " Pass any environment variables necessary for logging
    let $CHAT_CACHE_PATH="/" " sgpt logfiles

    " Get vim window id before starting the terminal
    let l:window_id_before = system("xdotool getactivewindow")

    " Start tmux
    let l:output = split(system(l:xrepl_command), ":")

    " Start terminal
    let l:xterm_command = printf('%s tmux attach -t %s & echo $!', g:vimteractive_terminal, l:output[1])
    let l:xterm_pid = system(l:xterm_command)
    let l:xterm_pid = substitute(l:xterm_pid, '\n', '', '')

    " Set slime target for this backend
    let g:slime_target = 'tmux'

    " Connect to terminal
    call vimteractive#backend#tmux#connect(l:repl_info.repl_name)

    " Move focus back to vim
    call system("xdotool windowactivate " . l:window_id_before)
endfunction

" Get list of tmux panes
function! vimteractive#backend#tmux#get_panes() abort
    if !exists('b:slime_config')
        let b:slime_config = {"socket_name": "default", "target_pane": ""}
    endif
    let l:tmux_panes = split(slime#targets#tmux#pane_names('', '', ''), "\n")
    let l:regex = '-\(' . join(keys(g:vimteractive_commands), '\|') . '\)\>'
    return filter(l:tmux_panes, 'match(v:val, l:regex) != -1')
endfunction

" Get pane names for completion
function! vimteractive#backend#tmux#get_repl_sessions() abort
    return map(vimteractive#backend#tmux#get_panes(), 'split(v:val, " ")[2]')
endfunction

" Get pane IDs
function! vimteractive#backend#tmux#get_pane_ids() abort
    return map(vimteractive#backend#tmux#get_panes(), 'split(v:val, " ")[0]')
endfunction

" Get active panes
function! vimteractive#backend#tmux#get_pane_activity() abort
    return filter(vimteractive#backend#tmux#get_panes(), 'match(v:val, "(active)") != -1')
endfunction

" Get the current pane name
function! vimteractive#backend#tmux#pane_name() abort
    let l:pane_id = b:slime_config["target_pane"]
    let l:pane_name_index = index(vimteractive#backend#tmux#get_pane_ids(), l:pane_id)
    return vimteractive#backend#tmux#get_repl_sessions()[l:pane_name_index]
endfunction

" Determine REPL type from pane name
function! vimteractive#backend#tmux#repl_type() abort
    for l:repl_type in keys(g:vimteractive_commands)
        if matchstr(vimteractive#backend#tmux#pane_name(), '-' . l:repl_type) != ''
            return l:repl_type
        endif
    endfor
    echoerr "Could not determine terminal type from pane name"
    return ""
endfunction

" Get logfile name
function! vimteractive#backend#tmux#logfile_name() abort
    return vimteractive#backend#tmux#pane_name() . '.log'
endfunction

" Connect to vimteractive terminal
function! vimteractive#backend#tmux#connect(...) abort
    let l:pane_names = vimteractive#backend#tmux#get_repl_sessions()
    if a:0 == 0 && len(l:pane_names) == 1
        let l:pane_name = l:pane_names[0]
        let l:pane_index = 0
    else
        let l:pane_name = a:1
        let l:pane_index = index(l:pane_names, l:pane_name)
    endif
    let l:pane_id = vimteractive#backend#tmux#get_pane_ids()[l:pane_index]
    let b:slime_config["target_pane"] = l:pane_id
    let b:slime_target = 'tmux'
    let g:slime_target = 'tmux'
    let b:vimteractive_backend = 'tmux'
    let l:repl_type = vimteractive#backend#tmux#repl_type()
    if index(g:vimteractive_bracketed_paste, l:repl_type) != -1
        let b:slime_bracketed_paste = 1
    else
        let b:slime_bracketed_paste = 0
    endif
    echo "Connected to " . l:pane_name
endfunction

" Check if terminal needs to be shown
function! vimteractive#backend#tmux#show_term() abort
    if !exists('b:slime_config') || !has_key(b:slime_config, 'target_pane')
        call vimteractive#backend#tmux#repl_start()
        return
    endif
    let l:pane_ids = vimteractive#backend#tmux#get_pane_ids()
    let l:pane_name_index = index(l:pane_ids, b:slime_config["target_pane"])
    if l:pane_name_index < 0
        call vimteractive#backend#tmux#repl_start()
    endif
endfunction

" Get response from REPL
function! vimteractive#backend#tmux#get_response() abort
    let l:repl_type = vimteractive#backend#tmux#repl_type()
    if has_key(g:vimteractive_get_response, l:repl_type)
        if l:repl_type == 'aichat'
            let l:response = vimteractive#backend#tmux#get_response_aichat()
        else
            " Use common log-based response functions
            let l:logfile_name = vimteractive#backend#tmux#logfile_name()
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
function! vimteractive#backend#tmux#get_response_aichat() abort
    " Get the pane prompt
    let l:repl_name = vimteractive#backend#tmux#pane_name()
    let l:prompt = fnamemodify(l:repl_name, ':t')
    let l:prompt = substitute(l:prompt, '-' . vimteractive#backend#tmux#repl_type(), '', '')

    " Capture the full tmux pane log.
    let l:tmux_command = printf('tmux capture-pane -J -p -t %s -S -', b:slime_config["target_pane"])
    let l:log_data = system(l:tmux_command)

    " Split the log data by newlines.
    let lines = split(l:log_data, '\n')

    let i = len(lines)- 1
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
function! vimteractive#backend#tmux#next_term() abort
    let l:pane_ids = vimteractive#backend#tmux#get_pane_ids()
    if empty(l:pane_ids) | return | endif
    let l:current_index = index(l:pane_ids, b:slime_config["target_pane"]) 
    let l:next_index = (l:current_index + 1) % len(l:pane_ids)
    call vimteractive#backend#tmux#connect(vimteractive#backend#tmux#get_repl_sessions()[l:next_index])
endfunction

" Cycle connection backward through terminal buffers
function! vimteractive#backend#tmux#prev_term() abort
    let l:pane_ids = vimteractive#backend#tmux#get_pane_ids()
    if empty(l:pane_ids) | return | endif
    let l:current_index = index(l:pane_ids, b:slime_config["target_pane"]) 
    let l:prev_index = (l:current_index - 1 + len(l:pane_ids)) % len(l:pane_ids)
    call vimteractive#backend#tmux#connect(vimteractive#backend#tmux#get_repl_sessions()[l:prev_index])
endfunction