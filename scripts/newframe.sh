#!/bin/bash

sn="$(basename "$0")"
if test -f $HOME/.emacs.d/host/pen.el/scripts/$sn && ! test "$HOME/.emacs.d/host/pen.el/scripts" = "$(dirname "$0")"; then
    ~/.emacs.d/host/pen.el/scripts/$sn "$@"
    exit "$?"
fi

# This creates extra frames

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export TERM=xterm-256color
export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

: "${SOCKET:="DEFAULT"}"

cmd-onelineify-safe() {
    for var in "$@"
    do
        printf "'%s' " "$(printf %s "$var" | pen-str onelineify-safe)";
    done | sed 's/ $//'
}

cmd-unonelineify-safe() {
    for var in "$@"
    do
        printf "'%s' " "$(printf %s "$var" | pen-str unonelineify-safe)";
    done | sed 's/ $//'
}

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -D) {
        SOCKET="$2"
        shift
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
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

shopt -s nullglob
if test "$USE_POOL" = "y"; then
    # ugh... using sentinels is a pain. Just select one.
    # Just take the first one
    # SOCKET="$(basename "$(shopt -s nullglob; cd $HOME/.pen/pool/available; ls pen-emacsd-* | shuf -n 1)")"

    for socket_fp in ~/.pen/pool/available/pen-emacsd-*; do
        SOCKET="$(basename "$socket_fp")"
        echo "$SOCKET" >> /tmp/d.txt
        break
    done

    test -z "$SOCKET" && exit 1
    test "$SOCKET" = DEFAULT && exit 1
    rm -f ~/.pen/pool/available/$SOCKET
fi

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

eval "set -- $(cmd-unonelineify-safe "$@")"

if ! test -f "$1" && test "$1" = "-e"; then
    shift
    extra_lisp="$@"
    if test "$USE_NVC" = "y"; then
        set -- -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(ignore-errors (disable-theme 'spacemacs-dark))$extra_lisp)"
    else
        set -- -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(load-theme 'spacemacs-dark t)$extra_lisp)"
    fi
fi

mkdir -p ~/.pen/ht-cache

in-tm() {
    if test "$PEN_NO_TM" = "y"; then
        "$@"
    elif inside-docker-p && test -n "$TMUX"; then
        "$@"
    elif test "$PEN_USE_GUI" = "y"; then
        "$@"
    else
        pen-tm init-or-attach "$@"
    fi
}

runclient() {
    if test "$USE_NVC" = "y"; then
        in-tm nvc emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
    else
        in-tm emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
    fi
}

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    runclient -a "" -t "$@"
fi

if test "$USE_POOL" = "y"; then
    touch ~/.pen/pool/available/$SOCKET
    # tmux neww -d -n fix-$SOCKET "shx pen-fix-daemon $SOCKET"
fi
