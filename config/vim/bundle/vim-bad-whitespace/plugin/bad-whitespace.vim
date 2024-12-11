" bad-whitespace.vim - Highlights whitespace at the end of lines
" '
" Maintainer:   Bit Connor <bit@mutantlemon.com>
" Version:      0.3

function! s:ShowBadWhitespace()
  syn match badWhiteSpace /\s\+$/ display
  match badWhiteSpace /\s\+$/
  autocmd InsertLeave <buffer> match badWhiteSpace /\s\+$/
  autocmd InsertEnter <buffer> match badWhiteSpace /\s\+\%#\@<!$/
  "hi def link badWhiteSpace Error
  "hi def link badWhiteSpace ColorColumn
  "exec "hi badWhiteSpace cterm=NONE ctermfg=232 ctermbg=233"
  "exec "hi badWhiteSpace cterm=NONE ctermfg=233 ctermbg=232"
  "exec "hi badWhiteSpace cterm=NONE ctermfg=52 ctermbg=232"
  exec "hi badWhiteSpace cterm=NONE ctermfg=234 ctermbg=232"
endfunction

autocmd BufWinEnter,WinEnter,FileType,BufReadPost * call <SID>ShowBadWhitespace()

function! s:EraseBadWhitespace(line1,line2)
  let l:save_cursor = getpos(".")
  silent! execute ':' . a:line1 . ',' . a:line2 . 's/\s\+$//'
  call setpos('.', l:save_cursor)
endfunction

" Run :EraseBadWhitespace to remove end of line white space.
command! -range=% EraseBadWhitespace call <SID>EraseBadWhitespace(<line1>,<line2>)
