" markdown filetype file
au BufRead,BufNewFile *.pash  set filetype=sh

" Shell script (Arch Linux) or PHP file (Drupal)
au BufNewFile,BufRead *.install
	\ if getline(1) =~ 'env pash' |
	\   call dist#ft#SetFileTypeSH("bash") |
	\ endif
