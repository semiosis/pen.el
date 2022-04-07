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
        let s = s . ' "' . arg . '"'
    endfor

    let cmd = a:fun . s
    let s = system("pena -fz --pool -u " . cmd, @p)
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
        let s = s . ' "' . arg . '"'
    endfor

    let cmd = a:fun . s

    " In order for this to work, I need to put each generation into a one-liner
    " One-linerise the json
    let s = Chomp(system("pena -fz --pool -u " . cmd, a:in))

    " call Insert(s)
    " return ""

    return s
endfunction

function! Guru()
    return system("guru -sps -win")
endfunction

function! VisualGuru(input)
    let result = system("guru -sps", a:input)
endfunction

xnoremap Zv "py:silent! call FzVisualPrompt(@p)<CR>
xnoremap Zg "py:silent! call VisualGuru(@p)<CR>
nnoremap Zg :silent! call Guru()<CR>

xnoremap Zt "py:silent! call VisualPrompt("pf-transform-code/3", @p, "vim", input("transformation: "))<CR>
inoremap <expr> <C-y> InsertPrompt("pf-generic-completion-50-tokens/1", GetLast20LinesBeforeCursor())
