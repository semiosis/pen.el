# Set a nice 256-color terminal.
(eshell/export "TERM=screen-256color")

# Emacs has all the paging we will ever need.
(eshell/export "PAGER=")

# Use Emacs for editing files.
(eshell/export "EDITOR=emacsclient")

alias ff 'find-file $1'
alias f 'find-file $1'

alias e 'find-file $1'
alias sp 'find-file $1'
alias og 'find-file $1'
alias xr 'find-file $1'
alias v 'find-file $1'