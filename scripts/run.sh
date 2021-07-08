#!/bin/bash

# Debian10 run Pen

export YAMLMOD_PATH=/root/.emacs.d/emacs-yamlmod
export PATH=$PATH:/root/.emacs.d/pen.el/scripts
/root/emacs/src/emacs -nw --debug-init
