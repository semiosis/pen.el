#!/bin/bash
export TTY

# set -xv

awk 1 | while IFS=$'\n' read -r line; do
    # printf -- "%s\n" "_${line}_"
    # locate "$line"

    # use the serach engine for this instead

    match="$(locate -- "$line")"
    if [ -n "$match" ]; then
        printf -- "%s\n" "$line"
    fi

    #if [ -e "$line" ]; then
    #    printf -- "%s\n" "$line"
    #fi
done
