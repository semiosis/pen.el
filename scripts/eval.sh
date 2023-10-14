#!/bin/bash

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

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts::$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container

last_arg="${@: -1}"
last_arg="$(p "$last_arg" | pen-str unonelineify-safe)"
# last_arg="$(p "$last_arg" | pen-bs '\\')"

# echo "$last_arg" > /tmp/yo.txt

shopt -s nullglob
if test "$USE_POOL" = "y"; then
    # ugh... using sentinels is a pain. Just select one.
    # Just take the first one
    # SOCKET="$(basename "$(shopt -s nullglob; cd $HOME/.pen/pool/available; ls pen-emacsd-* | shuf -n 1)")"

    mkdir -p ~/.pen/pool/available
    for socket_fp in ~/.pen/pool/available/pen-emacsd-*; do
        SOCKET="$(basename "$socket_fp")"
        echo "$SOCKET" >> /tmp/d.txt
        break
    done

    test -z "$SOCKET" && exit 1
    test "$SOCKET" = DEFAULT && exit 1
    rm -f ~/.pen/pool/available/$SOCKET
fi

# Can't use a timestamp because I might want to try eval.sh again
# prompt_id="$(cmd "$@" | sha1sum | awk '{print $1}')"

# Add the date so never any collisions
# fp="/tmp/eval-output-${SOCKET}-$prompt_id.txt"
# fp="/tmp/eval-output-${SOCKET}-$prompt_id.txt"

# This is not the place to memoise with prompt sha
fp="/tmp/eval-output-${SOCKET}-$(uuid || :).txt"
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
