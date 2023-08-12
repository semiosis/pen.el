#!/bin/bash

is_tty() {
    # If stout is a tty
    [[ -t 1 ]]
}

pager() {
    if is_tty; then
        fzf
    else
        cat
    fi
}

dir="$1"
: "${dir:="."}"

find "$dir" -path '*/.git*' -prune -o -print | sed -u 's=^\./==' | pager

# THis is too slow
# ag --hidden --ignore .git -f -g . "$dir" | pager
