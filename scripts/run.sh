#!/bin/bash

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US

export TERM=xterm-256color
export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

# This should be 'pen' if on the host but 'emacs -nwemacsclient -a "" -t' if inside docker
butterfly.server.py \
    --login=False \
    --host=0.0.0.0 \
    --port=57575 \
    --unsecure \
    --cmd="bash -l $EMACSD/pen.el/scripts/newframe.sh" \
    --shell=bash \
    --i-hereby-declare-i-dont-want-any-security-whatsoever &

mkdir -p ~/.pen/ht-cache

# emacs -nw --debug-init

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    emacsclient -c -a "" ~/.pen
else
    emacsclient -a "" -t
fi