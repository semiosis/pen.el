
" help 'cpoptions'
function! SyncToXClipboardMinimise()
    " silent! call system('xclip-in-nokill.sh', @")
    " silent! let a = system('xclip-in-nokill-minimise.sh', @")
    silent! let a = system('xc', @")
endfunction

function! SyncToXClipboardNominimise()
    " silent! call system('xclip-in-nokill.sh', @")
    " silent! let a = system('xclip-in-nokill-notify.sh', @")
    silent! let a = system('xc', @")
endfunction


function! StartCheckSameSearchHighlight(selectkeys, ...)
    " In vim search patterns, to enable \V and \c, you do \V\c

    " This funuction could be improved upon by making vim check to see
    " if it's inside searched text, then highlight the text. Hard to to
    " though. Not sure how.
    let oldsearch=@/
    "let oldsearch='\V\c'.escape(@/, '\/')
    "normal vit"zy
    silent! exe "normal " . a:selectkeys
    silent! exe "normal! \"zy"
    "let @/=@z
    "let @/='\V\c'.escape(@z, '\/')
    "first search should be case sensitive, after copy it becomes
    "insesitive
    " then we don't need a mapping like this
    " nmap <silent> <leader>c ;let @/ = substitute(@/,'^\\V\\c','\\V','')<CR>
    if a:0 > 0 && a:1
        let @/='\<'.escape(@z, '\/').'\>'
    else
        let @/='\V\c'.escape(@z, '\/')
    endif
    let newsearch=@/
    if &hlsearch
        if oldsearch == newsearch
            " this is meant to highlight the searched for word under cursor
            "normal v//e
            exe "normal " . a:selectkeys
            "normal vito
        endif
    endif
endfunction

" Disable & because it's used to repeat the last substitution.
" xnoremap <silent> & "zy:silent! let @/ = '\V\c'.escape(@z, '\/')<bar>set hlsearch<Bar>let @+ = @z<Bar>silent! call SyncToXClipboardMinimise()<CR>
xnoremap <silent> * "zy:silent! let @/ = '\V\c'.escape(@z, '\/')<bar>set hlsearch<Bar>let @+ = @z<Bar>silent! call SyncToXClipboardMinimise()<CR>
xnoremap <silent> ( "zy:silent! let @/ = '\V\c'.escape(@z, '\/')<bar>set hlsearch<Bar>let @+ = @z<Bar>silent! call SyncToXClipboardMinimise()<CR>
xnoremap <silent> ) "zy:silent! let @/ = '\V\c'.escape(@z, '\/')<bar>set hlsearch<Bar>let @+ = @z<Bar>silent! call SyncToXClipboardMinimise()<CR>
xnoremap <silent> i "zy:silent! let @/ = '\V\c\<'.escape(@z, '\/').'\>'<bar>set hlsearch<Bar>let @+ = @z<Bar>silent! call SyncToXClipboardMinimise()<CR>
" nmap <silent> & ;call StartCheckSameSearchHighlight("viw")<bar>set hlsearch<CR>
nmap <silent> * ;call StartCheckSameSearchHighlight("vit")<bar>set hlsearch<CR>
nmap <silent> ( ;call StartCheckSameSearchHighlight("viq")<bar>set hlsearch<CR>
nmap <silent> ) ;call StartCheckSameSearchHighlight("viW")<bar>set hlsearch<CR>
nmap <silent> i ;call StartCheckSameSearchHighlight("vit", 1)<bar>set hlsearch<CR>