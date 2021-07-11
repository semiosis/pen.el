#!/bin/bash

# Debian10 run Pen

# export PEN_DEBUG=y

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/pen.el/scripts

/root/emacs/src/emacs -nw --debug-init
