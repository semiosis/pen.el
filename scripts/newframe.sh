#!/bin/bash

# Debian10 run Pen

# export PEN_DEBUG=y

export TERM=xterm-256color
export LANG=en_US

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

emacsclient -e "(get-buffer-create $(cmd-nice-posix "*scratch*"))"

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    emacsclient -c -a "" "$@"
else
    emacsclient -a "" -t "$@"
fi
