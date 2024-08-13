" Vimteractive implementation

" Reopen a terminal buffer in a split window if necessary
function! vimteractive#show_term() abort
    if !exists('b:slime_config')
        let b:slime_config = {"socket_name": "default", "target_pane": ""}
    endif
    let b:slime_bracketed_paste = 1
    let l:pane_name_index = index(vimteractive#get_pane_ids(), b:slime_config["target_pane"])
    if l:pane_name_index < 0
        call vimteractive#repl_start('-auto-')
    endif
endfunction

" Start a vimteractive terminal
function! vimteractive#repl_start(repl_type, ...) abort
    " Determine the terminal type
    let l:repl_type = a:repl_type
    if l:repl_type ==# '-auto-'
        let l:repl_type = get(g:vimteractive_default_shells, &filetype, &filetype)
    endif

    " Retrieve starting command
    let l:repl_command = get(g:vimteractive_commands, l:repl_type, g:vimteractive_commands.gpt)

    " Assign session, repl and logfile names
    let l:tempname = tempname()
    let l:repl_name = fnamemodify(l:tempname, ':p:h') . '-' . fnamemodify(l:tempname, ':t:r') . '-' . l:repl_type
    let l:logfile_name = l:repl_name . '.log'

    " Define the terminal command
    let l:repl_command = substitute(l:repl_command, '<LOGFILE>', l:logfile_name, '')
    let l:repl_command = l:repl_command . ' ' . join(a:000, ' ')

    " Define the tmux command
    let l:tmux_command = "tmux new-session -n " . l:repl_name

    " Define the cleanup command
    let l:rm_command = "rm " . l:logfile_name

    " Now join them all together
    let l:xrepl_command = printf('%s %s "%s && %s" &', g:vimteractive_terminal, l:tmux_command, l:repl_command, l:rm_command)

    " Pass any environment variables necessary for logging
    let $CHAT_CACHE_PATH="/" " sgpt logfiles

    " Get the list of panes before starting the terminal
    let l:panes_before = vimteractive#get_panes()
    let l:window_id_before = system("xdotool getactivewindow")

    " Start the terminal
    call system(l:xrepl_command)

    " Wait for the new pane to appear, and attach to this in slime
    let b:slime_config["target_pane"] = vimteractive#find_new_pane(l:panes_before)

    " Move focus back to vim
    call system("xdotool windowactivate " . l:window_id_before)

endfunction

function! vimteractive#get_panes() abort
    if !exists('b:slime_config')
        let b:slime_config = {"socket_name": "default", "target_pane": ""}
    endif
    let l:tmux_panes = split(slime#targets#tmux#pane_names('', '', ''), "\n")
    let l:regex = '-\(' . join(keys(g:vimteractive_commands), '\|') . '\)\>'
    return filter(l:tmux_panes, 'match(v:val, l:regex) != -1')
endfunction

function! vimteractive#get_pane_names(...) abort
    return map(vimteractive#get_panes(), 'split(v:val, " ")[2]')
endfunction

function! vimteractive#get_pane_ids(...) abort
    return map(vimteractive#get_panes(), 'split(v:val, " ")[0]')
endfunction

function! vimteractive#get_pane_activity(...) abort
    return filter(vimteractive#get_panes(), 'match(v:val, "(active)") != -1')
endfunction

function! vimteractive#find_new_pane(list_before) abort
    let l:list_after = copy(a:list_before)
    while len(l:list_after) == len(a:list_before)
        let l:list_after = vimteractive#get_panes()
    endwhile
    let l:new_pane = filter(l:list_after, 'index(a:list_before, v:val) == -1')
    return split(l:new_pane[0])[0]
endfunction

function! vimteractive#pane_name(...) abort
    if a:0 == 0
        let l:pane_id = b:slime_config["target_pane"]
    else
        let l:pane_id = a:1
    endif
    let l:pane_name_index = index(vimteractive#get_pane_ids(), l:pane_id)
    return vimteractive#get_pane_names()[l:pane_name_index]
endfunction

function! vimteractive#repl_type() abort
    for l:repl_type in keys(g:vimteractive_commands)
        if matchstr(vimteractive#pane_name(), '-' . l:repl_type) != ''
            return l:repl_type
        endif
    endfor
    echoerr "Could not determine terminal type from pane name"
    return 1
endfunction

function! vimteractive#logfile_name() abort
    return vimteractive#pane_name() . '.log'
endfunction


" Connect to vimteractive terminal
function! vimteractive#connect(pane_name) abort
    let l:pane_index = index(vimteractive#get_pane_names(), a:pane_name)
    let l:pane_id = vimteractive#get_pane_ids()[l:pane_index]
    let b:slime_config["target_pane"] = l:pane_id
    echom "Connected to " . a:pane_name
endfunction

function! vimteractive#get_response() abort
    let l:repl_type = vimteractive#repl_type()
    return g:vimteractive_get_response[l:repl_type]()
endfunction

" Get the last response from the terminal for sgpt
function! vimteractive#get_response_sgpt() abort
    let l:logfile_name =  vimteractive#logfile_name() 
    let l:json_content = join(readfile(l:logfile_name), "\n")
    let l:json_data = json_decode(l:json_content)
    if len(l:json_data) > 0
        let l:last_response = l:json_data[-1]['content']
        return l:last_response
    endif
endfunction

" Get the last response from the terminal for gpt-command-line
function! vimteractive#get_response_gpt() abort
    let l:logfile_name = vimteractive#logfile_name()
    let l:log_data = readfile(l:logfile_name)
    let l:log_data_str = join(l:log_data, "\n")
    let l:last_session_index = strridx(l:log_data_str, 'gptcli-session - INFO - assistant: ')
    let l:end_text = strpart(l:log_data_str, l:last_session_index+35)
    let l:price_index = match(l:end_text, 'gptcli-price')
    let l:last_price_index = strridx(l:end_text, "\n", l:price_index-1)
    return strpart(l:end_text, 0, l:last_price_index)
endfunction

" Get the last response from the terminal for ipython
function! vimteractive#get_response_ipython() abort
    let l:logfile_name = vimteractive#logfile_name()
    let lines = readfile(l:logfile_name)
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
function! vimteractive#next_term() abort
    let l:pane_ids = vimteractive#get_pane_ids()
    let l:current_index = index(l:pane_ids, b:slime_config["target_pane"]) 
    let l:next_index = (l:current_index + 1) % len(l:pane_ids)
    call vimteractive#connect(vimteractive#get_pane_names()[l:next_index])
endfunction

" Cycle connection backward through terminal buffers
function! vimteractive#prev_term() abort
    let l:pane_ids = vimteractive#get_pane_ids()
    let l:current_index = index(l:pane_ids, b:slime_config["target_pane"]) 
    let l:prev_index = (l:current_index - 1 + len(l:pane_ids)) % len(l:pane_ids)
    call vimteractive#connect(vimteractive#get_pane_names()[l:prev_index])
endfunction

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
