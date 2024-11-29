#!/bin/bash
export TTY

. $SCRIPTS/lib/hs

# pip install defusedxml

python3.8 $HOME/repos/eliask/xml2json/xml2json.py "$@" | pavs
