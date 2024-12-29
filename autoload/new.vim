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

