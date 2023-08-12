#!/bin/bash
export TTY

awk 1 | while IFS=$'\n' read -r line; do
    if [ -d "$line" ]; then
        printf -- "%s\n" "$line"
    fi
done