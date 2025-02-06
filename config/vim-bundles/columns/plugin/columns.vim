function! AddColumns(ncols)
    " count is a special variable. Don't use it.
    " Inject the count using the binding. i.e. v:count1

    let g:ncolumns=a:ncols

    if exists("g:disable_columnate") && g:disable_columnate == 1
        return
    endif
    let savepos = getpos('.')
    windo set noscrollbind
    let c=a:ncols
    if ! c > 0
        let c=1
    endif
    for i in range(1, c)
        normal! v
    endfor
    " this is ideal but it's making the last column not scrolled
    " work out why
    "windo set scrollopt=ver
    " still having problems with ver (after searching for something,
    " window offset is messed up. Dont get this problem without ver)
    windo set scrollbind
    "windo normal zH
    call setpos('.', savepos) " need this here if I disable scrollopt
    "above
    normal! t
    for i in range(1, c)
        normal! l
    endfor
    for i in range(1, c)
        normal! h
    endfor
    call setpos('.', savepos)
    let g:hidecolums = 0
endfunction

nnoremap <C-W>, :<C-U>call AddColumns(v:count1)<CR>

command! -nargs=? Columns call AddColumns(<q-args>)
