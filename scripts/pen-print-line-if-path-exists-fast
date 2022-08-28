#!/bin/bash
export TTY

awk 1 | while IFS=$'\n' read -r line; do
    #match="$(locate "$line")"
    #if [ -n "$match" ]; then
    #    printf -- "%s\n" "$line"
    #fi

    if [ -e "$line" ]; then
        printf -- "%s\n" "$line"
    fi
done
