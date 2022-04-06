#!/bin/bash
export TTY

# This script is sourced

{
stty stop undef; stty start undef
} 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export TERM=screen-256color
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$EMACSD/host/pen.el/scripts-host:$EMACSD/pen.el/scripts-host:$PATH
export PATH=$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts:$PATH
export PATH=$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container:$PATH
export PATH="$PATH:/root/go/bin"
export PATH="$PATH:/root/.cargo/bin/cargo"

if ! test -n "$PEN_DAEMON"; then
    . ~/.cargo/env
fi

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

export EDITOR=sps-w-pin
export BROWSER=sps-lg

[ -f "/root/.ghcup/env" ] && . "/root/.ghcup/env" # ghcup-env

# Needed for nlsh, but it killed pend because pen would infinite-loop load
# export SHELL="$(basename $0)"
# need to export the SHELL for apo/nlsh/guru/comint if it is a regular shell
candidate_shell="$(basename $0)"
# This will work better because when I personally override SHELL in scripts, I leave out the full path
if printf -- "%s\n" "$candidate_shell" | grep -q -P '^/'; then
    export SHELL="$candidate_shell"
fi