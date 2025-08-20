" Common functions shared by all backends

" Prepare REPL information for starting a new session
function! vimteractive#common#prepare_repl_info(...) abort
    let l:repl_type = call("vimteractive#determine_repl_type", a:000)
    let l:repl_command = g:vimteractive_commands[l:repl_type]

    let l:tempname = tempname()
    let l:rand = fnamemodify(fnamemodify(l:tempname, ':h'), ':t')
    let l:num  = fnamemodify(l:tempname, ':t')
    
    let l:info = {}
    let l:info.repl_type = l:repl_type
    let l:info.repl_name = printf('/tmp/%s-%s-%s', l:rand, l:num, l:repl_type)
    let l:info.logfile_name = l:info.repl_name . '.log'
    let l:info.session_name = printf('%s-%s-%s', strftime("%Y-%m-%d"), l:rand, l:num)
    
    let l:command = substitute(l:repl_command, '<LOGFILE>', l:info.logfile_name, '')
    let l:command = substitute(l:command, '<SESSION>', l:info.session_name, '')
    let l:info.full_command = l:command . ' ' . join(a:000[1:], ' ')
    
    return l:info
endfunction

" Extract markdown code blocks from AI responses
function! vimteractive#common#extract_markdown_code_blocks(input) abort
    let result = ""
    let in_code_block = 0
    let lines = split(a:input, '\n')
    for line in lines
        if in_code_block == 0 && line =~ '^\s*```.*$'
            let in_code_block = 1
        elseif in_code_block == 1 && line =~ '^\s*```.*$'
            let in_code_block = 0
        elseif in_code_block == 1
            let result .= line . "\n"
        endif
    endfor
    if result == ""
        let result = a:input
    endif
    return result
endfunction

" Get the last response from the terminal for sgpt
function! vimteractive#common#get_response_sgpt(logfile_name) abort
    let l:json_content = join(readfile(a:logfile_name), "\n")
    let l:json_data = json_decode(l:json_content)
    if len(l:json_data) > 0
        let l:last_response = l:json_data[-1]['content']
        return l:last_response
    endif
endfunction

" Get the last response from the terminal for gpt-command-line
function! vimteractive#common#get_response_gpt(logfile_name) abort
    let l:log_data = readfile(a:logfile_name)
    let l:log_data_str = join(l:log_data, "\n")
    let l:last_session_index = strridx(l:log_data_str, 'gptcli-session - INFO - assistant: ')
    let l:end_text = strpart(l:log_data_str, l:last_session_index+35)
    let l:price_index = match(l:end_text, 'gptcli-price')
    let l:last_price_index = strridx(l:end_text, "\n", l:price_index-1)
    return strpart(l:end_text, 0, l:last_price_index)
endfunction

" Get the last response from the terminal for ipython
function! vimteractive#common#get_response_ipython(logfile_name) abort
    let lines = readfile(a:logfile_name)
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

" Get the last response from the terminal for zsh
function! vimteractive#common#get_response_zsh(logfile_name) abort
    let l:log_data = system("cat " . a:logfile_name . " | perl -pe '" . 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' . "' | col -b ")
    let lines = split(l:log_data, '\n')
    let i = len(lines) - 1
    while i > 0 && match(lines[i], g:vimteractive_zsh_prompt) != 0
        let i -= 1
    endwhile
    let j = i - 1
    while j > 0 && match(lines[j], g:vimteractive_zsh_prompt) != 0
        let j -= 1
    endwhile
    return join(lines[j+1:i-g:vimteractive_zsh_prompt_multiline], "\n")
endfunction