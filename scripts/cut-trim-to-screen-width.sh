#!/bin/bash
export TTY

is_emacs_shell() {
    [[ $INSIDE_EMACS == *,comint ]] || [[ $INSIDE_EMACS == *,eshell ]];
}

is_tty() {
    # If stout is a tty
    [ -t 1 ] && ! test "$TERM" = "dumb" && ! is_emacs_shell;
}

if is_tty; then
    eval `resize 2>/dev/null`
fi

if test -n "$COLUMNS"; then
    : "${MAXCOLS:="200"}"

    if [ "$COLUMNS" -gt "$MAXCOLS" ]; then
        COLUMNS="$MAXCOLS"
    fi

    cut -c -$COLUMNS -
else
    cat
fi