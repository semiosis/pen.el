#!/bin/bash
export TTY

. $SCRIPTS/lib/hs

echo "$TESTBASH"

"$@"
