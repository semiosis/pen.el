#!/bin/bash

# This creates the initial frame

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export TERM=xterm-256color
export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts
export PATH="$PATH:/root/go/bin"

if test -n "$PEN_USER"; then
    echo "$PEN_USER" > ~/pen_user.txt
fi

: "${SOCKET:="default"}"

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -D) {
        SOCKET="$2"
        shift
        shift
    }
    ;;

    *) break;
esac; done

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

(
export PEN_USE_GUI=n
ttyd -p 7681 bash -l /root/.emacs.d/pen.el/scripts/newframe.sh &>/dev/null &
)

# Right-click isn't very well supported with nvc, so I have disabled it
# ttyd -p 7681 nvc bash -l /root/.emacs.d/pen.el/scripts/newframe.sh &>/dev/null &

# if test "$USE_NVC" = "y"; then
#     set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(ignore-errors (disable-theme 'spacemacs-dark)))"
# else
#     set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(load-theme 'spacemacs-dark t))"
# fi

echo "ttyd running on port 7681, serving Pen.el on http"

# # This should be 'pen' if on the host but 'emacs -nwemacsclient -a "" -t' if inside docker
# butterfly.server.py \
#     --login=False \
#     --host=0.0.0.0 \
#     --port=57575 \
#     --unsecure \
#     --cmd="bash -l newframe.sh" \
#     --shell=bash \
#     --i-hereby-declare-i-dont-want-any-security-whatsoever &

mkdir -p ~/.pen/ht-cache

# emacs -nw --debug-init

in-tm() {
    if test -n "$TMUX" || test "$PEN_USE_GUI" = "y"; then
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

# How to debug daemon
# emacs -nw --daemon --debug-init
# How to debug non-daemon
# emacs -nw --debug-init

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    runclient -a "" -t "$@"
fi
