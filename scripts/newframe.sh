#!/bin/bash

# This creates extra frames

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export TERM=xterm-256color
export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

emacsclient -e "(get-buffer-create $(cmd-nice-posix "*scratch*"))"

mkdir -p ~/.pen/ht-cache

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    emacsclient -c -a "" "$@"
else
    emacsclient -a "" -t "$@"
fi
