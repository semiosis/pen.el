#!/bin/bash

{
stty stop undef; stty start undef
} 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

rm -f /tmp/eval-output.txt
# Can't use cmd because elisp doesn't use single quote for strings
unbuffer emacsclient -a "" -e "(pen-eval-for-host $1)" &>/dev/null
sleep 0.1
cat /tmp/eval-output.txt
