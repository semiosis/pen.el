#!/bin/bash
module="$1"; shift
find  $@ -name $module.erl | xargs gsed -E -n '/-export\(/,/\)./p' | gsed -E -e '/%/d' | gsed -E -e 's/ //g' | gsed -E -e 's/\t//g' | gsed -E -e '/^$/d' | gsed -E -e '/-export\(\[.*\\]\)./{ n ; d }' | gsed -E -e 's/-export.*\(\[//g' | gsed -E -e 's/\]\).//g' | gsed -E 's/\,/\
/g' | gsed -E '/^$/d' | grep /
