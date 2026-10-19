#!/bin/bash
export TTY

IFS= read -rd '' file_contents < <(cat);typeset -p file_contents &>/dev/null

# TODO Do the same with requires but to the top

nondks="$(printf -- "%s" "$file_contents" | grep -vP "^\\(define-key ")"
dks="$(printf -- "%s" "$file_contents" | grep -P "^\\(define-key ")"

{
printf -- "%s\n" "$nondks"
printf -- "%s\n" "$dks"
} | sed "s/^\\s\\+$//" | max-one-empty-line.sh
