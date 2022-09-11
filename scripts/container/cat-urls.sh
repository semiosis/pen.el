#!/bin/bash
export TTY

awk 1 | while IFS=$'\n' read -r line; do
    echo "cat $line"
    elinks-dump "$line"
    echo
done
