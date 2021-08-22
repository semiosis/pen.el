#!/bin/bash
export TTY

# This is obsolete
# For reasons:
# - task may be in ink
# - task may be templated
# - does not take into account arity. file name should contain arity

for fp in *.prompt; do 
    name="$(cat "$fp" | yq -r ".title // empty" | slugify)"
    : "${name:="$(cat "$fp" | yq -r ".task // empty" | slugify)"}"
    : "${name:="$(cat "$fp" | yq -r ".doc // empty" | slugify)"}"
    echo "$name"
    mv "$fp" "${name}.prompt"
done