#!/bin/bash

test -d "/root/.pen/tmp" && : "${TMPDIR:="/root/.pen/tmp"}"
test -d "/tmp" && : "${TMPDIR:="/tmp"}"

export PS4='+	"$(basename $0)"	${LINENO}	 '

sn="$(basename "$0")"
if test -f $HOME/.emacs.d/host/pen.el/scripts/$sn && ! test "$HOME/.emacs.d/host/pen.el/scripts" = "$(dirname "$0")"; then
    ~/.emacs.d/host/pen.el/scripts/$sn "$@"
    exit "$?"
fi

{
stty stop undef; stty start undef
} 2>/dev/null

exec 0</dev/null

# set -xv

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

: "${SOCKET:="DEFAULT"}"

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -D) {
        SOCKET="$2"
        shift
        shift
    }
    ;;

    -nto) {
        PEN_NO_TIMEOUT=y
        shift
    }
    ;;

    --parallel|--pool) {
        export USE_POOL=y
        shift
    }
    ;;

    *) break;
esac; done

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

export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts::$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container

test "$#" -gt 0 && last_arg="${@: -1}"
last_arg="$(p "$last_arg" | pen-str unonelineify-safe)"
# last_arg="$(p "$last_arg" | pen-bs '\\')"

# echo "$last_arg" > $TMPDIR/yo.txt

shopt -s nullglob
if test "$USE_POOL" = "y"; then
    # ugh... using sentinels is a pain. Just select one.
    # Just take the first one
    # SOCKET="$(basename "$(shopt -s nullglob; cd $HOME/.pen/pool/available; ls pen-emacsd-* | shuf -n 1)")"

    mkdir -p ~/.pen/pool/available
    for socket_fp in ~/.pen/pool/available/pen-emacsd-*; do
        SOCKET="$(basename "$socket_fp")"
        echo "$SOCKET" >> $TMPDIR/d.txt
        break
    done

    test -z "$SOCKET" && exit 1
    test "$SOCKET" = DEFAULT && exit 1
    rm -f ~/.pen/pool/available/$SOCKET
fi

# Can't use a timestamp because I might want to try eval.sh again
# prompt_id="$(cmd "$@" | sha1sum | awk '{print $1}')"

# Add the date so never any collisions
# fp="$TMPDIR/eval-output-${SOCKET}-$prompt_id.txt"
# fp="$TMPDIR/eval-output-${SOCKET}-$prompt_id.txt"

# This is not the place to memoise with prompt sha
fp="$TMPDIR/eval-output-${SOCKET}-$(uuid || :).txt"
if ! test -s "$fp"; then
    rm -f "$fp"
fi

# Consider using timeout here
# Part of the reason there is a timeout is that the engines used may be unknown by the prompter, due to the shell interop.
# The human engine should have executive power though to prevent the timeout.
# The omission is made here:
# vim +/"# No timeout for human engine" "$HOME/source/git/semiosis/pen.el/scripts/lm-complete-generic"
# So at this point, we simply have a timeout which we can disable if we want.
# The bash interop isn't normally *supposed* to use the human engine, so, this is ok to keep it as default here.
sentinel_string="tm_sentinel_${RANDOM}_$$"
# unbuffer pen-emacsclient -a "" -s $SOCKET -e "(pen-eval-for-host \"$fp\" \"~/.pen/pool/available/$SOCKET\" $last_arg)"
tmux neww -d -n eval-ec-$SOCKET "echo $(cmd "$PEN_PF_INVOCATION") | hls green 1>&2; PEN_NO_TIMEOUT=$PEN_NO_TIMEOUT $(cmd pen-timeout 10 unbuffer pen-emacsclient -a "" -s $SOCKET -e "(pen-eval-for-host \"$fp\" \"~/.pen/pool/available/$SOCKET\" $last_arg)"); tmux wait-for -S '$sentinel_string';"
tmux wait-for "$sentinel_string"

export SOCKET
export USE_POOL

# Can't remove this sleep yet.
# Do this to test.
# cd "$NOTES"; penf -u pf-very-witty-pick-up-lines-for-a-topic/1 imagination
sleep 0.1

# I need to hide the fact that it failed. Otherwise, I can't cancel comint commands without polluting the repl
if test -s "$fp"; then
    0</dev/null cat "$fp" 2>/dev/null
fi

rm -f "$fp"

# touch ~/.pen/pool/available/$SOCKET

# sleep 1
# nohup pen-fix-worker $SOCKET

if test "$USE_POOL" = "y"; then
    tmux neww -d -n fix-$SOCKET "shx pen-fix-worker $SOCKET"
fi
