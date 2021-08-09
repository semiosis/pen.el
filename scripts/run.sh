#!/bin/bash

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

(
    cd "$HOME/butterfly"
    ./butterfly.server.py --host=localhost --port=57575 --unsecure --shell=pen
) &

# emacs -nw --debug-init
emacsclient -a "" -t