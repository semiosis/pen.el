#!/bin/bash
export TTY

awk 1 | while IFS=$'\n' read -r line; do
    if [ -f "$line" ]; then
        printf -- "%s\n" "$line"
    fi
done
