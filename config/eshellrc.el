# Set a nice 256-color terminal.
(eshell/export "TERM=screen-256color")

# Emacs has all the paging we will ever need.
(eshell/export "PAGER=")

# Use Emacs for editing files.
(eshell/export "EDITOR=emacsclient")

# Don't put aliases in eshellrc.el
# When they run, it creates them here.
# $EMACSD/eshell/alias

# alias v pen-ewhich $1
# alias sp pen-ewhich $1
# alias e pen-find-file-create $1
# alias f find-file $1
# alias ff find-file $1
