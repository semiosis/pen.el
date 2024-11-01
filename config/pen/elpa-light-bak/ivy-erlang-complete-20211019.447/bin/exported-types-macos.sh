#!/bin/bash
module="$1"; shift
find $@ -name $module.erl | xargs gsed -E -n '/-export_type\(/,/\)./p' | gsed -E -e '/%/d' | gsed -E -e 's/ //g' | gsed -E -e 's/\t//g' | gsed -E -e '/^$/d' | gsed -E -e '/-export_type\(\[.*\\]\)./{ n ; d }' | gsed -E -e 's/-export_type.*\(\[//g' | gsed -E -n '/^-.*\(/,/\)./!p' | gsed -E 's/]//' | gsed -E 's/\).//' | gsed -E 's/\,/\n/g' | gsed -E '/^$/d' | grep /
