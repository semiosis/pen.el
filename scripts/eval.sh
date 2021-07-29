#!/bin/bash

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

CMD="$(cmd "$@")"
: ${CMD:="$(cmd "$@")"}

# emacs -nw --debug-init
emacsclient -a "" -e "$CMD"
