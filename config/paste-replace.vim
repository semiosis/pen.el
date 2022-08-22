" help 'cpoptions'
function! SyncToXClipboardMinimise()
    silent! let a = system('xc -i -m', @")
endfunction

function! SyncToXClipboardUnminimise()
    silent! let a = system('xc -i -u -m', @")
endfunction

function! SyncToXClipboardNominimise()
    silent! let a = system('xc -i', @")
endfunction

function! SyncFromXClipboard()
    silent! let @"=system('xc')
endfunction

" Copy current buffer path and line num relative to root of VIM session to system clipboard
nnoremap yl :let @"="vim "."+".line(".")." ".expand("%:pj")<CR>:silent! call SyncToXClipboardNominimise()<CR>:echo "Copied file path and line num"<CR>

function! AppendLineToClipboard()
    "call setpos('.', save_cursor)
    let @+ .= getline(".")."\n"
    let @/ = getline(".")
    echom "Appended"
endfunction

function! AppendSelectionToClipboard()
    let @+ .= getline(".")."\n"
    let @/ = getline(".")
    echom "Appended"
endfunction

nnoremap <silent> ya :call AppendLineToClipboard()<CR>
xnoremap <silent> <M-y> :call AppendSelectionToClipboard()<CR>
nnoremap <silent> daa :call AppendLineToClipboard()<BAR>:normal! "ddd<CR>

function! CopyStartCommand()
    let sc=system("tm unimplemented copy-tmux-start-command.sh")
    echo sc
endfunction

nnoremap yt :call CopyStartCommand()<CR>

function! CopyGitPathMaster(arg)
    let sc=system("xa git-file-to-url -m | xc -n -i", a:arg)
    echo sc
endfunction

function! CopyGitPathSha(arg)
    let sc=system("xa git-file-to-url -s | xc -n -i", a:arg)
    echo sc
endfunction

function! CopyGitPath(arg)
    let sc=system("xa git-file-to-url | xc -n -i", a:arg)
    echo sc
endfunction

function! OpenGitPathChrome(arg)
    let sc=system("xa git-file-to-url | xa chrome &", a:arg)
    echo sc
endfunction

nnoremap yG :call CopyGitPathSha(expand('%:p'))<CR>
nnoremap ym :call CopyGitPathMaster(expand('%:p'))<CR>
nnoremap yg :call CopyGitPath(expand('%:p'))<CR>
nnoremap yo :call OpenGitPathChrome(expand('%:p'))<CR>

nnoremap yp :silent! call SaveTemp()<CR>:let @"=expand("%:pj")<CR>:silent! call SyncToXClipboardMinimise()<CR>:echom "Copied file path to clipboard"<CR>
nnoremap yP :silent! call SaveTemp()<CR>:let @"=expand("%:pj")<CR>:silent! call SyncToXClipboardUnminimise()<CR>:echom "Copied file path to clipboard"<CR>
nnoremap yf :let @"=expand("%:t")<CR>:silent! call SyncToXClipboardNominimise()<CR>:echom "Copied file name to clipboard"<CR>
nnoremap yd :let @"=matchstr(expand("%:pj"),"^.*/")<CR>:silent! call SyncToXClipboardNominimise()<CR>:echom "Copied file directory to clipboard"<CR>
nnoremap yh :!makepublic.sh %<CR>

" Don't do for yy because SyncToXClipboardNominimise always stripts
" the newline
"nnoremap yy yy:silent! call SyncToXClipboardNominimise()<CR>
"xnoremap y y:silent! call SyncToXClipboardNominimise()<CR>

" select to end of line
nnoremap <C-y> v$h
xnoremap <C-y> y:silent! call SyncToXClipboardNominimise()<CR>

"nnoremap p :silent! call SyncFromXClipboard()<CR>p
"xmap p :silent! call SyncFromXClipboard()<CR>p

let s:cpo_save = &cpo
set cpo&vim
"------------------------------------------------------------------------
" Replaces but doesn't update.  Use to paste what's in the clipboard over another thing.
xnoremap <silent> p @='"zxP'<CR>

" Replaces with whatever was removed and updates @" with the replaced text.
xnoremap <silent> v p

"xnoremap v "-p

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:


" this way, can copy a bunch of python lines without the indenting, for
" easy pasting into ipython
function! TrimClipboard()
    let @"=substitute(@", '^\s\+', '', '')
    let @"=substitute(@", '\n\s\+', '\n', 'g')
    let @*=@"
    let @+=@"
endfunction

xnoremap <silent> Y y:call TrimClipboard()<CR>:silent! call SyncToXClipboardNominimise()<CR>
