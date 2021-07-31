#!/bin/bash
export TTY

for fp in *.prompt; do 
    name="$(cat "$fp" | yq -r .title | slugify )"
    echo "$name"
    mv "$fp" "${name}.prompt"
done