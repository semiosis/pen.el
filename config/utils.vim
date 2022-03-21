" at least this works
" let r=system("tm -f -i spv 'fzf -nm'", "hi")
"fun! Tm(cmd, stdin)
"    return system("tm " + a:cmd, a:stdin)
"    " let r=system("tm -f -i spv 'fzf -nm'", "hi")
"endf

fun! FilterBufferWithCommand(cmd)
    " return system("tm -f -i -fout spv fzf", BufferContents())

    let filtered=system("tm -f -i -fout spv " . Q(a:cmd), BufferContents())

    if ! strlen(filtered) == 0
        exe("%d")
        call Insert(filtered)
    endif

    " return system("tm -f -i -fout spv " . a:cmd, BufferContents())
endf

fun! B(cmd, stdin)
    return system(a:cmd, a:stdin)
endf

fun! Tv(stdin)
    return system("tm vipe", a:stdin)
endf

fun! TvEmacs(stdin)
    return system("tm eipe", a:stdin)
endf

fun! GetBufferContents()
    return join(getline(1,'$'), "\n")
endf

fun! OpenContentsInVim()
    call Tv(GetBufferContents())
endf

fun! OpenContentsInEmacs()
    call TvEmacs(GetBufferContents())
endf

function! Chomp(string)
    return substitute(a:string, '\n\+$', '', '')
endfunction

function! ChompedSystem( ... )
    return substitute(call('system', a:000), '\n\+$', '', '')
endfunction

function! Ns(message)
    silent! call system('ns', a:message)
endfunction

function! Xc(message)
    silent! call system('xc -i', a:message)
endfunction

" yp should copy the path if the file exits. Otherwise, it should first
" save the buffer to a temporary file and then copy the path of the
" temporary file
function! SaveTemp()
    "if getcwd() == system('echo -n ~/dump')
    "    let tmpstr="~/dump/scratchXXXXXX.txt"
    "else
    "    let tmpstr="/tmp/scratchXXXXXX.txt"
    "endif
    let tmpstr="~/dump/tmp/scratchXXXXXX.txt"
    if bufname('%') == ''
        let a = system("/usr/bin/notify-send \"Consider using yt instead\"")
        let rf = system("/bin/mktemp ".tmpstr)
        exec "w! ".rf
        exec "e! ".rf
    endif
endfunction

fun! FilterWithFzf()
    call SaveTemp()
    call system("tm -f -t nw -noerror ".Q("f filter-with-fzf ".Q(expand('%:p')))." &")
endf

fun! RT()
    call SaveTemp()
    " call system("tm -f -S -tout nw -noerror ".Q("rtcmd -E ".Q("sed -n ".Q("/ /p")." | vi -"))."", GetBufferContents())
    "
    call system("tm -f -S -tout nw -noerror ".Q("siq"), GetBufferContents())
endf

" vimhelp a:000
fun! MapM(func, ...)
    let m = ''
    for s in a:000
        let m = m.'<Esc>'.s
    endfor

    if a:func =~ ")$"
        exec 'nnoremap '.m.' :call '.a:func.'<CR>'
        exec 'inoremap '.m.' <Esc>:call '.a:func.'<CR>'
        exec 'xnoremap '.m.' "zy:call '.a:func.'<CR>'
    else
        exec 'nnoremap '.m.' :call '.a:func.'()<CR>'
        exec 'inoremap '.m.' <Esc>:call '.a:func.'()<CR>'
        exec 'xnoremap '.m.' "zy:call '.a:func.'()<CR>'
    endif
endf
command! -nargs=+ MapM call MapM(<f-args>)


function! Q(string)
    return system('q', a:string)
endf

function! Qftln(string)
    return system('q -ftln', a:string)
endf

fun! Sys(cmd, ...)
    let a:arg2 = get(a:, 1, 0)

    if ! empty(a:arg2)
      call system(a:cmd, a:arg2)
    else
      call system(a:cmd)
    endif
endf

" strftime('%c')
" How does this function not even exist?
" Insert text here
fun! Insert(text)
    let g:inserted_text = a:text
    " put =strftime('%c') " this puts it on a new line
    if mode() == 'i'
        call feedkeys(g:inserted_text) " I don't know if this works or is needed
    else
        exec "normal! \"=g:inserted_text\rPl"
        " normal! "=g:inserted_text
        " normal! "=g:inserted_textPl
    endif
endf

fun! BufferContents()
    return join(getline(1, '$'), "\n")
endf
