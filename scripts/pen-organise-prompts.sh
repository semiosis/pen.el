#!/bin/bash
export TTY

for fp in *.prompt; do 
    name="$(cat "$fp" | yq -r ".title // empty" | slugify)"
    : "${name:="$(cat "$fp" | yq -r ".task // empty" | slugify)"}"
    : "${name:="$(cat "$fp" | yq -r ".doc // empty" | slugify)"}"
    echo "$name"
    mv "$fp" "${name}.prompt"
done