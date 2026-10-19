#!/bin/bash
export TTY

set -o pipefail

# "vh:s:"
optstring="$1"
shift

while getopts "$optstring" arg; do
    if test "$arg" = ?; then
        exit 1
    fi
    echo "$arg"
    echo "$OPTARG" # val
done
# echo "lastarg=$arg" 1>&2
