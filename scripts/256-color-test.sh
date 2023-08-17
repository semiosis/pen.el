#!/bin/bash
export TTY

# exec 2>/dev/null
# $HOME/source/tarballs/xterm-278/vttests/256colors.pl

256colors.pl | tr -s ' ' '\t' | columnate # | less -rS

# set -m
# (
# unbuffer timeout 0.3 256colors.pl & disown
# ) | tr -s ' ' '\t' | columnate COLUMNS=$COLUMNS # | less -rS
