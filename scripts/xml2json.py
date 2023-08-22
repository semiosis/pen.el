#!/bin/bash
export TTY

( hs "$(basename "$0")" "$@" "#" "<==" "$(ps -o comm= $PPID)" 0</dev/null ) &>/dev/null

# pip install defusedxml

python3.8 $HOME/repos/eliask/xml2json/xml2json.py "$@" | pavs
