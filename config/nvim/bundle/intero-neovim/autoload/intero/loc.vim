""""""""""
" Location:
"
" This file contains code for parsing locations and jumping to them.
""""""""""

function! intero#loc#go_to_def() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        call intero#repl#send(intero#util#make_command(':loc-at'))
        call intero#process#add_handler(function('s:handle_loc'))
    endif
endfunction

function! intero#loc#get_identifier_information() abort
    " Returns information about the identifier under the point. Return type is
    " a dictionary with the keys 'module', 'line', 'beg_col', 'end_col', and
    " 'identifier'.
    let l:module = intero#loc#detect_module()
    let l:line = line('.')
    let l:identifier = intero#util#get_haskell_identifier()
    let l:winview = winsaveview()
    normal! |
    call search('\<' . l:identifier . '\>', '', l:line)
    let l:beg_col = intero#util#getcol(l:line, col('.'))
    let l:end_col = l:beg_col + len(l:identifier)
    let l:cmd = join([':loc-at', l:module, l:line, l:beg_col, l:line, l:end_col, l:identifier], ' ')
    call winrestview(l:winview)
    return { 'module': l:module, 'line': l:line, 'beg_col': l:beg_col, 'end_col': l:end_col, 'identifier': l:identifier }
endfunction

function! intero#loc#detect_module() abort "{{{
    let l:regex = '^\C>\=\s*module\s\+\zs[A-Za-z0-9._]\+'
    for l:lineno in range(1, line('$'))
        let l:line = getline(l:lineno)
        let l:pos = match(l:line, l:regex)
        if l:pos != -1
            let l:synname = synIDattr(synID(l:lineno, l:pos+1, 0), 'name')
            if l:synname !~# 'Comment'
                return matchstr(l:line, l:regex)
            endif
        endif
        let l:lineno += 1
    endfor
    return 'Main'
endfunction "}}}

""""""""""
" Private:
""""""""""

function! s:handle_loc(resp) abort
    let l:response = join(a:resp, "\n")
    let l:split = split(l:response, ':')
    if len(l:split) != 2
        echom l:response
        return
    endif
    let l:pack_or_path = l:split[0]
    let l:module_or_loc = l:split[1]

    if l:module_or_loc =~# '[\h\+\.\?]\+'
        echom l:response
    else
        let l:loc_split = split(l:module_or_loc, '-')
        let l:start = substitute(l:loc_split[0], '\m[\(\)]', '', 'g')
        let l:end = substitute(l:loc_split[1], '\m[\(\)]', '', 'g')
        let l:start_split = split(l:start, ',')
        let l:start_row = l:start_split[0]
        let l:start_col = l:start_split[1]
        let l:cwd = getcwd()
        " jump to the appropriate location, taking care to add exactly one
        " entry to the jumplist
        if l:pack_or_path != l:cwd . '/' . expand('%')
            exec 'edit ' . l:pack_or_path
            call cursor(l:start_row, l:start_col)
        else
            exec 'normal ' . l:start_row . 'G' . l:start_col . '|'
        endif
        exec 'cd ' . l:cwd
    endif
endfunction
