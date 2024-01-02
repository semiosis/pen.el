#!/bin/bash
export TTY

eval `resize 2>/dev/null`

if test -n "$COLUMNS"; then
    : "${MAXCOLS:="200"}"

    if [ "$COLUMNS" -gt "$MAXCOLS" ]; then
        COLUMNS="$MAXCOLS"
    fi

    cut -c -$COLUMNS -
else
    cat
fi