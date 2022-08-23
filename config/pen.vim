function! GetLast20LinesBeforeCursor()
    let end = line('.')
    let start = end - 20
    if start < 1
        let start = 1
    endif
    let s = ""
    for i in range(start, end - 1)
        let s .= getline(i) . "\n"
    endfor
    let s .= getline(end)[:col('.') - 1]

    return s
endfunction

" put this after a character to use the 'combining macron'

function! VisualPrompt(fun, ...)
    let args = a:000
    let s = ""
    for arg in args
        let s = s . ' ' . Q(arg) . ''
    endfor

    let cmd = a:fun . s
    " let s = system("pena -fz --pool -u " . cmd, @p)
    " let s = system(Tv("pena -fz " . cmd), @p)
    let s = system("pena -fz " . cmd, @p)
    let @p = s

    " paste from p register
    exe "normal! gv\"pp"
endfunction

function! FzVisualPrompt(input)
    let fun = system("pen-tm -w -sout -vipe sps penz")
    let @p = system("penf -ask " . fun, a:input)

    " paste from p register
    exe "normal! gv\"pp"
endfunction

fun! Insert(text)
    let g:inserted_text = a:text
    if mode() == 'i'
        call feedkeys(g:inserted_text)
    else
        exec "normal! \"=g:inserted_text\rPl"
    endif
endf

function! Chomp(string)
    return substitute(a:string, '\n\+$', '', '')
endfunction

function! InsertPrompt(fun, in, ...)
    let args = a:000
    let s = ""
    " skip the first of the variadic args because it's the input
    for arg in args[1:]
        let s = s . ' ' . Q(arg) . ''
    endfor

    let cmd = a:fun . s

    " In order for this to work, I need to put each generation into a one-liner
    " One-linerise the json
    " let s = Chomp(system("pena -fz --pool -u " . cmd, a:in))
    let s = Chomp(system("pena -fz " . cmd, a:in))

    " Write s to file /tmp/test.txt

    " call Insert(s)
    " return ""

    " return s."\n"
    " return s

    " This adds a newline and backspaces it so
    " The screen is properly flushed.
    exec "return s.\"\\n\<C-h>\""
endfunction

" tmux neww seems to circumvent an issue on the host
function! Guru()
    return system("guru -sps -win")
endfunction

function! VisualGuru(input)
    let result = system("guru -sps", a:input)
endfunction

xnoremap Zv "py:silent! call FzVisualPrompt(@p)<CR>
xnoremap Zg "py:silent! call VisualGuru(@p)<CR>
nnoremap Zg :silent! call Guru()<CR>

xnoremap Zt "py:silent! call VisualPrompt("pf-transform-code/3", expand("%:e"), input("transformation: "))<CR>
inoremap <expr> <C-y> InsertPrompt("pf-generic-completion-50-tokens/1", GetLast20LinesBeforeCursor())

fun! CharAtCursor()
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endf

fun! ReselectVisual()
    " New function
    " echom visualmode()
    " call system("tv", visualmode())
    if visualmode() == "V"
       " we are in visual line mode
        normal! mxgv`x
    elseif visualmode() == "\<C-V>"
       " we are in visual block mode
        normal! mxgv`x
    else
        normal! mxgv
    endif
endf

fun! Byte(...)
    " https://vi.stackexchange.com/questions/2410/how-to-make-a-vimscript-function-with-optional-arguments
    let indicator = get(a:, 1, ".")
    return line2byte(line(indicator))+col(indicator)-1
endf

" I can improve on these to be more picky
fun! SearchUpDiffColPicky()
    let charatcursor = escape(CharAtCursor(), "*./\\")
    if empty(charatcursor)
        let charatcursor = ' '
    endif
    "exe '?\%'.virtcol('.').'v'.charatcursor.'\@!'
    silent! exe '?\%'.virtcol('.').'v'.charatcursor.'\@!'
endf

fun! SearchDownDiffColPicky()
    let charatcursor = escape(CharAtCursor(), "*./\\")
    if empty(charatcursor)
        let charatcursor = ' '
    endif
    "exe '/\%'.virtcol('.').'v'.charatcursor.'\@!'
    silent! exe '/\%'.virtcol('.').'v'.charatcursor.'\@!'
endf

fun! SearchUpDiffCol()
    let charatcursor = escape(CharAtCursor(), "*./\\")
    if empty(charatcursor)
        let charatcursor = ' '
    endif
    "exe '?\%'.virtcol('.').'v'.charatcursor.'\@!'
    silent! exe '?\C\%'.virtcol('.').'v\('.charatcursor.'\| \|$\)\@!'
endf

fun! SearchDownDiffCol()
    let charatcursor = escape(CharAtCursor(), "*./\\")
    if empty(charatcursor)
        let charatcursor = ' '
    endif
    "exe '/\%'.virtcol('.').'v'.charatcursor.'\@!'
    silent! exe '/\C\%'.virtcol('.').'v\('.charatcursor.'\| \|$\)\@!'
endf

nnoremap <Esc>_ :call SearchUpDiffCol()<CR>
nnoremap <Esc>+ :call SearchDownDiffCol()<CR>
xnoremap <Esc>_ <C-c>:call SearchUpDiffCol() \| call ReselectVisual()<CR>
xnoremap <Esc>+ <C-c>:call SearchDownDiffCol() \| call ReselectVisual()<CR>
nnoremap <Esc>- :call SearchUpDiffColPicky()<CR>
nnoremap <Esc>= :call SearchDownDiffColPicky()<CR>
xnoremap <Esc>- <C-c>:call SearchUpDiffColPicky() \| call ReselectVisual()<CR>
xnoremap <Esc>= <C-c>:call SearchDownDiffColPicky() \| call ReselectVisual()<CR>
