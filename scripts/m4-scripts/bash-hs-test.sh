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
# 'source the file' transformed file from the file? Hmm... maybe not.
# Ideas:
# - swap the file with the transformed file before running it.
# - pass the variables (e.g. $0) forward that would be lost.
# - make a bash extension that runs m4

_HS

echo hi | pavs
