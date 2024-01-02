#!/bin/bash
export TTY

test -d "/root/.pen/tmp" && : "${TMPDIR:="/root/.pen/tmp"}"
test -d "/tmp" && : "${TMPDIR:="/tmp"}"
export TMPDIR

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

test -d ~/.config && : ${XDG_CONFIG_HOME:=~/.config}
export XDG_CONFIG_HOME="$XDG_CONFIG_HOME"

# This fixes an issue where you only have one or the other
: "${TMUX:="$PEN_TMUX"}"
: "${PEN_TMUX:="$TMUX"}"

export SCRIPTS=$HOME/scripts
export SCRIPTS=/root/.emacs.d/host/pen.el/scripts
export PEN=/root/.pen

unset EMACSD_BUILTIN
test -d "/root/.emacs.d" && : "${EMACSD_BUILTIN:="/root/.emacs.d"}"
export EMACSD_BUILTIN

unset EMACSD
test -d "/root/.emacs.d/host" && : "${EMACSD:="/root/.emacs.d/host"}"
test -d "/root/.emacs.d" && : "${EMACSD:="/root/.emacs.d"}"
export EMACSD

export PENELD="$EMACSD/pen.el"

unset VIMCONFIG
test -d "/root/.vim/host" && : "${VIMCONFIG:="/root/.vim/host"}"
test -d "/root/.vim" && : "${VIMCONFIG:="/root/.vim"}"
export VIMCONFIG

unset VIMSNIPPETS
test -d "$EMACSD/pen.el/config/vim-bundles/vim-snippets/snippets" && : "${VIMSNIPPETS:="$EMACSD/pen.el/config/vim-bundles/vim-snippets/snippets"}"
export VIMSNIPPETS

unset YAMLMOD_PATH
test -d "$EMACSD/emacs-yamlmod" && : "${YAMLMOD_PATH:="$EMACSD/emacs-yamlmod"}"
test -d "$EMACSD_BUILTIN/emacs-yamlmod" && : "${YAMLMOD_PATH:="$EMACSD_BUILTIN/emacs-yamlmod"}"
export YAMLMOD_PATH

export PATH=$EMACSD/host/pen.el/scripts-host:$EMACSD/pen.el/scripts-host:$PATH
export PATH=$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts:$PATH
export PATH=$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container:$PATH
export PATH="$PATH:/root/go/bin"
export PATH="$PATH:/root/.cargo/bin/cargo"
export PATH="$PATH:/root/repos/go-ethereum/build/bin"
export PATH="$PATH:$(find "$SCRIPTS" -maxdepth 1 -mindepth 1 -type d | sed -z "s~\n~:~g" | sed "s/:\$//")"

# For the host:
# export PATH="$PATH:$(find "$SCRIPTS" -maxdepth 1 -mindepth 1 -type d | grep -v '/\.git' | sed -z "s~\n~:~g" | sed "s/:\$//")"
# export PATH="$PATH:$(find "$PENEL_DIR/scripts" -maxdepth 1 -mindepth 1 -type d | grep -v '/\.git' | grep -v /container/ | sed -z "s~\n~:~g" | sed "s/:\$//")"

if ! test -n "$PEN_WORKER"; then
    . ~/.cargo/env
fi

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

export EDITOR=sps-w-pin
# export BROWSER=sps-lg
export BROWSER=browser
# export PAGER="sps -iftty v"
export PAGER="pen-tpager"

[ -f "/root/.ghcup/env" ] && . "/root/.ghcup/env" # ghcup-env

# Needed for nlsh, but it killed pend because pen would infinite-loop load
# export SHELL="$(basename $0)"
# need to export the SHELL for apo/nlsh/guru/comint if it is a regular shell
candidate_shell="$(basename -- "$0")"
# This will work better because when I personally override SHELL in scripts, I leave out the full path
# Still had recursion with this
# if printf -- "%s\n" "$candidate_shell" | grep -q -P '^/'; then
# I have to be explicit
if printf -- "%s\n" "$candidate_shell" | grep -q -P '(bash|zsh|sh|fish)'; then
    case "$candidate_shell" in
        sh) {
            # This is to get around an issue in startup where when SHELL=sh was exported, paths were not found
            candidate_shell=bash
        }
        ;;

        *)
    esac
    : "${SHELL:="$candidate_shell"}"
    # Interestingly, I need 'a' shell to export or Pen.el GUI will hang when initiating Pen.
    : "${SHELL:="bash"}"
    # echo "$SHELL" >> /tmp/shells2.txt
    export SHELL
fi

# shanepy
export PYTHONPATH="$PYTHONPATH:$(glob "/root/pen_python_modules/*" | tr '\n' : | sed 's/:$//')"
