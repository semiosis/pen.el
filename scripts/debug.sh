#!/bin/bash
export TTY

# Source this file, or utils.sh

if test "$DEBUG" = "y"; then
    {
        echo
        # Use 'command' or -xv will apply to cmd
        command cmd RUN: "$(basename "$0")" "$@" "#" "<==" "$(ps -o comm= $PPID)" 0</dev/null | udl
    } 1>&2

    export PS4='+	"$(basename $0)"	${LINENO}	 '
    set -xv
fi
