#!/usr/bin/env m4bash
export TTY

# OK, how do I make this use sourcem4?
# [[sps:v +/"sourcem4() {" "$HOME/.shell_functions"]]

# e:/root/.emacs.d/host/pen.el/scripts/m4-scripts/bash.m4
# sps:bash-hs-test.sh

# Hmmm... it seems that after converting to a temp file
# the next bash interpreter loses some information such as
# the script name.
# How to get around this?
# i.e. "hsqf bash-hs-test.sh" will not work

_HS

echo hi | pavs
