#!/bin/bash

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

# Can't use cmd because elisp doesn't use single quote for strings
emacsclient -a "" -e "$@"
