#!/bin/bash

# Need to be able to run a whole list of grep/sed/posix grep queries on
# the mimetype, but only execute one at a time

# DONE Make string test wrapper
# tt "string1" -p "posix regex"
# tt "string1" -v "vim regex"
# tt "string1" -g "grep glob"


# Do not use tt here. It will create an infinite loop
# if tt -t "$rp"; then
#     printf -- "%s\n" "text"
# fi
# exit 0

CMD=''
for (( i = 1; i <= $#; i++ )); do
    eval ARG=\${$i}
    CMD="$CMD $(printf -- "%s" "$ARG" | q)"
done

# -M 
cmd="/usr/bin/mimetype -b -L $CMD"
eval "$cmd"
