#!/bin/bash

export PS4='+	"$(basename $0)"	${LINENO}	 '

# Do this so emacs doesn't break when using docker commit
find ~/.emacs.d/host/ -empty -type d -exec rmdir {} \; 2>/dev/null

echo "$PEN_CONTAINER_NAME" > ~/pen_container_name.txt

echo "$PEN_SHARE_X" > ~/pen_has_gui.txt

mkdir -p ~/.pen/ports
# Calculate the ports on the outside, but record them here
: "${TTYD_PORT:="7681"}"
echo "$TTYD_PORT" > ~/.pen/ports/ttyd.txt
: "${KHALA_PORT:="9837"}"
echo "$KHALA_PORT" > ~/.pen/ports/khala.txt

sn="$(basename "$0")"
if test -f $HOME/.emacs.d/host/pen.el/scripts/$sn && ! test "$HOME/.emacs.d/host/pen.el/scripts" = "$(dirname "$0")"; then
    ~/.emacs.d/host/pen.el/scripts/$sn "$@"
    exit "$?"
fi

if test -f $HOME/.emacs.d/host/config/pen.vim; then
    penvim_fp=$HOME/.emacs.d/host/config/pen.vim
elif test -f $HOME/.emacs.d/host/config/pen.vim; then
    penvim_fp=$HOME/.emacs.d/host/config/pen.vim
fi

if test -d ~/.pen && ! test -f ~/.pen/pen.vim && test -f "$penvim_fp"; then
    cp -a "$penvim_fp" ~/.pen
fi

if test -d ~/.pen/documents/notes; then
    rm -rf ~/notes
    ln -sf ~/.pen/documents/notes ~/
fi

if test -d ~/.pen/dotfiles; then
    mkdir -p ~/.pen/dotfiles
    rm_fp=~/.pen/dotfiles/README
    if ! test -f "$rm_fp"; then
        echo "Place dotfile hardlinks or directories in this directory to replicate them in the container."
    fi

    for fp in ~/.pen/dotfiles/.* ~/.pen/dotfiles/*; do
        df_bn="$(basename "$fp")"
        if ! test -e ~/"$df_bn"; then
            ln -sf "$fp" ~/
        fi
    done
fi

if test -d ~/.emacs.d/host/pen.el/config; then
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zsh_aliases ~/.zsh_aliases
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zshenv ~/.zshenv
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zshrc ~/.zshrc
    ln -sf ~/.emacs.d/host/pen.el/config/shell_functions ~/.shell_functions
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/fzf.zsh ~/.fzf.zsh
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/git.zsh ~/.git.zsh
    ln -sf ~/.emacs.d/host/pen.el/config/shellrc ~/.shellrc
else
    ln -sf ~/.emacs.d/pen.el/config/zsh/zsh_aliases ~/.zsh_aliases
    ln -sf ~/.emacs.d/pen.el/config/zsh/zshenv ~/.zshenv
    ln -sf ~/.emacs.d/pen.el/config/zsh/zshrc ~/.zshrc
    ln -sf ~/.emacs.d/pen.el/config/shell_functions ~/.shell_functions
    ln -sf ~/.emacs.d/pen.el/config/zsh/fzf.zsh ~/.fzf.zsh
    ln -sf ~/.emacs.d/pen.el/config/zsh/git.zsh ~/.git.zsh
    ln -sf ~/.emacs.d/pen.el/config/shellrc ~/.shellrc
fi

if [ -f ~/.shellrc ]; then
    . ~/.shellrc
fi

if test -f $HOME/.emacs.d/host/pen.el/config/nvimrc; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/nvimrc ~/.vimrc
fi

if test -f $HOME/.emacs.d/host/pen.el/config/tmux.conf; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/tmux.conf ~/.tmux.conf
fi

if test -f $HOME/.emacs.d/host/pen.el/config/efm-langserver-config.yaml; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/efm-langserver-config.yaml $HOME/.config/efm-langserver/config.yaml
fi

# Set up an ssh key for using git with github
# Actually, just use http
# setup-ssh.sh

if pen-rc-test host-ssh-master; then
    unbuffer pen-cterm-ssh -ssh -t -M sh &>/dev/null &
fi

# This creates the initial frame

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export TERM=screen-256color
export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts
export PATH=$PATH:$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container
export PATH="$PATH:/root/go/bin"

if test -n "$PEN_USER"; then
    echo "$PEN_USER" > ~/pen_user.txt
fi

: "${SOCKET:="DEFAULT"}"

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -D) {
        SOCKET="$2"
        shift
        shift
    }
    ;;

    -no-quit-daemons) {
        NO_QUIT_DAEMONS=y
        shift
    }
    ;;

    *) break;
esac; done

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

# Must quit all emacs daemons and relinquish their reservations before ever checking available pool
# run.sh *should* only happen when starting Pen for the first time, except for when the first argument is a file.
if ! test "$NO_QUIT_DAEMONS" = y; then
    echo -n Resetting daemons... 1>&2
    unbuffer pen-e qa &>/dev/null
    echo " done."
fi

# This is a hack to run only on the initial docker run
# Without this check, "pen-tipe pen-eipe" will hang because it waits for a background job
if ! ls ~/.pen/pool/available/* 2>/dev/null | grep -q pen-emacsd; then
(
export PEN_USE_GUI=n
echo "ttyd running on port $TTYD_PORT, serving Pen.el on http"
ttyd -p "$TTYD_PORT" bash -l /root/.emacs.d/pen.el/scripts/newframe.sh &>/dev/null &
/inspircd-2.0.25/run/inspircd start &>/dev/null

echo Postgres running
pg_ctlcluster 11 main start
)
fi

# Right-click isn't very well supported with nvc, so I have disabled it
# ttyd -p 7681 nvc bash -l /root/.emacs.d/pen.el/scripts/newframe.sh &>/dev/null &

# if test "$USE_NVC" = "y"; then
#     set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(ignore-errors (disable-theme 'spacemacs-dark)))"
# else
#     set -- "$@" -e "(progn (get-buffer-create $(cmd-nice-posix "*scratch*"))(load-theme 'spacemacs-dark t))"
# fi

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

mkdir -p ~/.pen/prolog/databases

# emacs -nw --debug-init

# for in-tm
export PEN_NO_TM
export PEN_USE_GUI

runclient() {
    if test "$USE_NVC" = "y"; then
        in-tm nvc pen-emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
    else
        in-tm pen-emacsclient -s ~/.emacs.d/server/$SOCKET "$@"
    fi
}

# Do some cleanup
rm -f /tmp/elisp_bash*
rm -f /tmp/file_*

# Ensure some directories
mkdir -p /root/pensieves

# Sometimes packages have old, broken .elc files.
# Besides, i'm not convinced that it improves speed much
# and I really like transparency.
find ~/.emacs.d/elpa -name '*.elc' -exec rm {} \;

# TODO Make a --debug option to do this
# while :; do
# emacs -nw --debug-init
# done

pen-of-imagination | cat

# In case I accidentally committed it
rm -f /tmp/pen.yaml
if test -n "$PEN_N_DAEMONS"; then
    pen-rc-set -fp /tmp/pen.yaml n-daemons "$PEN_N_DAEMONS"
fi

if test -n "$PEN_NO_TIMEOUT"; then
    pen-rc-set -fp /tmp/pen.yaml no-timeout "$PEN_NO_TIMEOUT"
fi

# On startup these should always be offline
rm -f ~/.pen/pool/available/*
if ! ls ~/.pen/pool/available/* 2>/dev/null | grep -q pen-emacsd; then
    echo Starting daemon pool in background 1>&2
    unbuffer pen-e sa &>/dev/null &
fi

# How to debug daemon
# emacs -nw --daemon --debug-init
# How to debug non-daemon
# emacs -nw --debug-init

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    # Start a fake X for the clipboard
    nohup Xvfb :0 -screen 0 1x1x8 &>/dev/null &
    runclient -a "" -t "$@"
fi
