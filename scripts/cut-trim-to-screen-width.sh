#!/bin/bash
export TTY

eval `resize`

: "${MAXCOLS:="200"}"
# MAXCOLS="$(myrc .ideal_screenwidth_read)"

if [ "$COLUMNS" -gt "$MAXCOLS" ]; then
    COLUMNS="$MAXCOLS"
fi

cut -c -$COLUMNS -