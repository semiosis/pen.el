#!/bin/bash
export TTY

# https://unix.stackexchange.com/questions/383164/how-to-transpose-a-text-file-on-character-basis
# https://stackoverflow.com/questions/58315066/bash-shell-scripting-transpose-rows-and-columns

# ( hs "$(basename "$0")" "$@" "#" "<==" "$(ps -o comm= $PPID)" 0</dev/null ) &>/dev/null

rs -T