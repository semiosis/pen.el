#!/bin/bash

export PS4='+	"$(basename $0)"	${LINENO}	 '

sn="$(basename "$0")"
if test -f $HOME/.emacs.d/host/pen.el/scripts/$sn && ! test "$HOME/.emacs.d/host/pen.el/scripts" = "$(dirname "$0")"; then
    ~/.emacs.d/host/pen.el/scripts/$sn "$@"
    exit "$?"
fi

# This creates extra frames

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export TERM=screen-256color

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

cmd-onelineify-safe() {
    for var in "$@"
    do
        printf "'%s' " "$(printf %s "$var" | pen-str onelineify-safe)";
    done | sed 's/ $//'
}

# cmd-unonelineify-safe is used for an eval. Therefore, I must properly escape contained single quotes
cmd-unonelineify-safe() {
    for var in "$@"
    do
        printf "'%s' " "$(printf %s "$var" | pen-str unonelineify-safe | sed "s/'/'\\\\''/g")";
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

export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts::$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container

shopt -s nullglob
if test "$USE_POOL" = "y"; then
    # ugh... using sentinels is a pain. Just select one.
    # Just take the first one
    # SOCKET="$(basename "$(shopt -s nullglob; cd $HOME/.pen/pool/available; ls pen-emacsd-* | shuf -n 1)")"

    # Wait until free clients

    # TODO Use e:with-exponential-backoff

    while test -z "$SOCKET"; do
        # ls ~/.pen/pool/available/pen-emacsd-* | pen-tv &>/dev/null

        for socket_fp in ~/.pen/pool/available/pen-emacsd-*; do
            SOCKET="$(basename "$socket_fp")"
            echo "$SOCKET" >> /tmp/d.txt
            break
        done
        if test -n "$SOCKET"; then
            break
        fi
        echo
        echo "$(date-ts-hr)"
        echo "Waiting for socket..." 1>&2
        sleep 1
    done

    test -z "$SOCKET" && exit 1
    test "$SOCKET" = DEFAULT && exit 1
    rm -f ~/.pen/pool/available/$SOCKET
fi

: "${SOCKET:="DEFAULT"}"

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

eval "set -- $(cmd-unonelineify-safe "$@")"

if ! test -f "$1" && test "$1" = "-e"; then
    shift
    extra_lisp="$@"
    if test "$USE_NVC" = "y"; then
        set -- -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(pen-banner)(ignore-errors (disable-theme 'spacemacs-dark))$extra_lisp)"
    else
        set -- -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(pen-banner)(pen-set-faces)$extra_lisp)"
    fi
fi

mkdir -p ~/.pen/ht-cache

# for in-tm
export PEN_NO_TM
export PEN_USE_GUI

marker="🖊"

unset INTERACTIVE
# Frusratingly there is an issue with pen-x and drawing the Pen.el emacs.
# I think the issue is most likely unicode inside my emacs, or ansi colours in my emacs.
# Unfortunately there's no way around this.
# Confirmed after seeing the difference with emacs -nw and emacs -nw -Q.
# I can't use expect to run interactive emacs commands.
# Instead, I must find another way.
runclient() {
    if test "$USE_NVC" = "y"; then
        if test "$INTERACTIVE" = y; then
            last_arg="${@: -1}"
            test "$#" -gt 0 && set -- "${@:2:$(($#-2))}" # shift last 2 args

            pen-x -sh "$(pen-nsfa in-tm nvc pen-emacsclient -s $HOME/.emacs.d/server/$SOCKET "$@")" -e "$marker" -m : -s "$last_arg" -c m -i
        else
            in-tm nvc pen-emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
        fi
    else
        if test "$INTERACTIVE" = y; then
            last_arg="${@: -1}"
            test "$#" -gt 0 && set -- "${@:2:$(($#-2))}" # shift last 2 args

            pen-x -sh "$(pen-nsfa in-tm pen-emacsclient -s $HOME/.emacs.d/server/$SOCKET "$@")" -e "$marker" -m : -s "$last_arg" -c m -i
        else
            in-tm pen-emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
        fi
    fi
}

if test -n "$PEN_PROMPT"; then
    mkdir -p ~/.pen/eipe
    # pen-tm -d nw -d -fargs vim "/root/.pen/eipe/${SOCKET}_prompt"
    printf -- "%s" "$PEN_PROMPT" > "/root/.pen/eipe/${SOCKET}_prompt"
fi

if test -n "$PEN_HELP"; then
    mkdir -p $HOME/.pen/eipe
    printf -- "%s" "$PEN_HELP" > "/root/.pen/eipe/${SOCKET}_help"
fi

# Create an overlay over the buffer with this info
# - prompt function name
# - example of prompt output
if test -n "$PEN_OVERLAY"; then
    mkdir -p ~/.pen/eipe
    printf -- "%s" "$PEN_OVERLAY" > "/root/.pen/eipe/${SOCKET}_overlay"
fi

if test -n "$PEN_PREOVERLAY"; then
    mkdir -p $HOME/.pen/eipe
    printf -- "%s" "$PEN_PREOVERLAY" > "/root/.pen/eipe/${SOCKET}_preoverlay"
fi

if test -n "$PEN_EIPE_DATA"; then
    mkdir -p $HOME/.pen/eipe
    printf -- "%s" "$PEN_EIPE_DATA" > "/root/.pen/eipe/${SOCKET}_eipe_data"
fi

if test "$#" -eq 1 && test -d "$1"; then
    dir="$1"
    shift
    set -- -e "(dired $(cmd-nice -ff "$dir"))"
elif test "$#" -eq 1 && test -f "$1"; then
    file="$1"
    shift
    set -- -e "(find-file $(cmd-nice -ff "$file"))"
fi

# I don't want to open directly or killing the buffer will kill the frame
# pen-emacsclient -s ~/.emacs.d/server/DEFAULT '-a' '' '-t' '/volumes/home/shane/var/smulliga/source/git/zyrolasting/racket-koans'
# pen-emacsclient -s ~/.emacs.d/server/DEFAULT '-a' '' '-t' -e '(dired "/volumes/home/shane/var/smulliga/source/git/zyrolasting/racket-koans")'

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    runclient -a "" -t "$@"
fi

if test "$USE_POOL" = "y"; then
    touch ~/.pen/pool/available/$SOCKET
    # tmux neww -d -n fix-$SOCKET "shx pen-fix-worker $SOCKET"
fi
