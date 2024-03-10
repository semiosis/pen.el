#!/bin/bash
fp="$1"
rp="$(realpath "$fp")"
dn="$(dirname "$rp")"
cd "$dn"
bn="$(basename "$fp")"
ext="${fp##*.}"

count="$2"

# : ${GIT_PREFIX:="n"}
# if [ -n "$GIT_PREFIX" ]; then
#     cd "$GIT_PREFIX";
# fi

if [[ $# == 1 ]]; then
    # If only the last commit then don't use !
    git difftool $(git log --oneline -- "$bn"|head -n 1|cut -d ' ' -f 1)\^ -- "$bn"
elif [[ $# == 2 ]]; then
    # It might also be cool to diff everything down to the level. Yes. Never use \^!
    git difftool $(git log --oneline -- "$bn"|sed -n $(expr 1 + $count)p|cut -d ' ' -f 1)\^ -- "$bn"
else
    echo "Example ‘git dp draw.c’ or ‘git dp draw.c 2’"
fi
