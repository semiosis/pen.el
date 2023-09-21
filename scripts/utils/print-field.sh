#!/bin/bash
export TTY

delim='[ \t\n]+'

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    -d) {
        delim="$2"
        shift
        shift
    }
    ;;

    *) break;
esac; done

n="$1"; : ${n:="1"}

# s field "$n"

awk -F"$delim" '{print $'$n'}'