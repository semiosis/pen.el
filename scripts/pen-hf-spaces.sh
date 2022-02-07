#!/bin/bash
export TTY

: "${PEN_MODEL:="valhalla/glide-text2im"}"

test -n "$PEN_PROMPT" || {
    echo No prompt given
    exit 1
}

td="$(mktemp -d)"

# Use 'jo'.

data="$(jo data="$(jo -a "$PEN_PROMPT")")"

curl -X POST "https://hf.space/gradioiframe/$PEN_MODEL/+/api/predict/" \
    -H 'Content-Type: application/json' \
    -d "$data"