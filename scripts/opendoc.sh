#!/bin/bash
export TTY

. $SCRIPTS/lib/hs

fp="$1"
fn=$(basename "$fp")
dn=$(dirname "$fp")
ext="${fn##*.}"
mant="${fn%.*}"

rp="$(realpath "$fp")"

is_tty() {
    # If stout is a tty
    [[ -t 1 ]]
}

if is_tty; then
    yn "txt?" && {
        doc2txt "$rp"
        exit 0
    }
else
    sph doc2txt "$rp"
fi

cd "$dn"

np="$mant.pdf"

if ! test -f "$np"; then
    # This only works if libreoffice is not already running
    # Perhaps I should use docker.
    libreoffice --convert-to pdf "$fn" --outdir "$dn"
fi

z "$np"

# echo "$mant.pdf"
# TODO: Return the path of the resulting pdf
# ns "finish this script: opendoc.sh"
# zcd .