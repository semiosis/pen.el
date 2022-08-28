#!/bin/bash
export TTY

awk 1 | while IFS=$'\n' read -r line; do
    if which "$line" &>/dev/null; then
        printf -- "%s\n" "$line"
    fi
done
