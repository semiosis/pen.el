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

if test "$USE_NVC" = "y"; then
    set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(ignore-errors (disable-theme 'spacemacs-dark)))"
else
    set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(load-theme 'spacemacs-dark t))"
fi

mkdir -p ~/.pen/ht-cache

in-tm() {
    if test "$PEN_USE_GUI" = "y"; then
        "$@"
    else
        pen-tm init-or-attach "$@"
    fi
} 

runclient() {
    if test "$USE_NVC" = "y"; then
        in-tm nvc emacsclient "$@"
    else
        in-tm emacsclient "$@"
    fi
}

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    runclient -a "" -t "$@"
fi
