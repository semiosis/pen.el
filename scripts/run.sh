#!/bin/bash

export PS4='+	"$(basename $0)"	${LINENO}	 '

export NO_AUTO_START=n

export FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"

export SCRIPTS=/root/.emacs.d/pen.el/scripts
if test -d /root/.emacs.d/host/pen.el/scripts; then
    export SCRIPTS=/root/.emacs.d/host/pen.el/scripts
fi

export PATH=$EMACSD/host/pen.el/scripts-host:$EMACSD/pen.el/scripts-host:$PATH
export PATH=$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts:$PATH
export PATH=$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container:$PATH
export PATH="$(find "$SCRIPTS" -maxdepth 4 -mindepth 1 -type d | sed -z "s~\n~:~g" | sed "s/:\$//"):$PATH"
export PATH="$PATH:/root/go/bin"
export PATH="$PATH:/root/.cargo/bin/cargo"
export PATH="$PATH:/root/repos/go-ethereum/build/bin"

sn="$(basename -- "$0")"
if test -f $HOME/.emacs.d/host/pen.el/scripts/$sn && ! test "$HOME/.emacs.d/host/pen.el/scripts" = "$(dirname "$0")"; then
    ~/.emacs.d/host/pen.el/scripts/$sn "$@"
    exit "$?"
fi

/etc/init.d/cron start

# pen-restart-clipboard

xrdb -merge /root/.Xresources
xrdb -load /root/.Xresources

# { cat /etc/hosts | awk 1; echo "127.0.1.1	pen-$(hostname)"; } > /etc/hosts

hn="$(hostname)"
hhn="$(hostname | sed 's/^pen-//')"

IFS= read -r -d '' etchosts <<HEREDOC
127.0.0.1	localhost
127.0.1.1	$hn
127.0.1.1	$hhn
127.0.1.1 croogle docsets gallery racket racketpkgs bodaciousblog pydoc36 $hn

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HEREDOC

printf -- "%s\n" "$etchosts" > /etc/hosts

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

if test -f $HOME/.emacs.d/host/pen.el/config/pen.vim; then
    penvim_fp=$HOME/.emacs.d/host/pen.el/config/pen.vim
elif test -f $HOME/.emacs.d/pen.el/config/pen.vim; then
    penvim_fp=$HOME/.emacs.d/pen.el/config/pen.vim
fi

if test -d ~/.pen && ! test -f ~/.pen/pen.vim && test -f "$penvim_fp"; then
    cp -a "$penvim_fp" ~/.pen
fi

if test -f ~/.pen/pen.yaml; then
    ln -sf ~/.pen/pen.yaml /tmp/pen.yaml
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

    # This way only symlinks are sent to the docker container
    # So if I commit, no secrets may accidentally be committed to the container
    rm -rf ~/.pen/dotfiles-syms
    cp -as ~/.pen/dotfiles ~/.pen/dotfiles-syms
    rsync -rtlphx ~/.pen/dotfiles-syms/ ~
fi

if test -d ~/.emacs.d/host/pen.el/config; then
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zsh_aliases ~/.zsh_aliases
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zshenv ~/.zshenv
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/zshrc ~/.zshrc
    ln -sf ~/.emacs.d/host/pen.el/config/bash/bashrc ~/.bashrc
    ln -sf ~/.emacs.d/host/pen.el/config/shell_functions ~/.shell_functions
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/fzf.zsh ~/.fzf.zsh
    ln -sf ~/.emacs.d/host/pen.el/config/zsh/git.zsh ~/.git.zsh
    ln -sf ~/.emacs.d/host/pen.el/config/shellrc ~/.shellrc
    ln -sf ~/.emacs.d/host/pen.el/config/visidatarc ~/.visidatarc
    ln -sf ~/.emacs.d/host/pen.el/config/files.txt ~/notes/files.txt

    mkdir -p $HOME/.config/broot/
    ln -sf ~/.emacs.d/host/pen.el/config/broot-conf.toml ~/.config/broot/conf.toml
    rm -f ~/.config/broot/conf.hjson
else
    ln -sf ~/.emacs.d/pen.el/config/zsh/zsh_aliases ~/.zsh_aliases
    ln -sf ~/.emacs.d/pen.el/config/zsh/zshenv ~/.zshenv
    ln -sf ~/.emacs.d/pen.el/config/zsh/zshrc ~/.zshrc
    ln -sf ~/.emacs.d/pen.el/config/bash/bashrc ~/.bashrc
    ln -sf ~/.emacs.d/pen.el/config/shell_functions ~/.shell_functions
    ln -sf ~/.emacs.d/pen.el/config/zsh/fzf.zsh ~/.fzf.zsh
    ln -sf ~/.emacs.d/pen.el/config/zsh/git.zsh ~/.git.zsh
    ln -sf ~/.emacs.d/pen.el/config/shellrc ~/.shellrc
    ln -sf ~/.emacs.d/pen.el/config/visidatarc ~/.visidatarc
    ln -sf ~/.emacs.d/pen.el/config/files.txt ~/notes/files.txt

    mkdir -p $HOME/.config/broot/
    ln -sf ~/.emacs.d/pen.el/config/broot-conf.toml ~/.config/broot/conf.toml
    rm -f ~/.config/broot/conf.hjson
fi

test -f ~/.pen/git/config && ln -sf ~/.pen/git/config ~/.gitconfig
test -f ~/.pen/git/credentials && ln -sf ~/.pen/git/credentials ~/.git-credentials


if [ -f ~/.shellrc ]; then
    . ~/.shellrc
fi

if test -f $HOME/.emacs.d/host/pen.el/config/nvimrc; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/nvimrc ~/.vimrc
    ln -sf $HOME/.emacs.d/host/pen.el/config/nvimrc ~/.nvimrc
fi

if test -f $HOME/.emacs.d/host/pen.el/config/syntax.vim; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/syntax.vim ~/syntax.vim
fi

if test -f $HOME/.emacs.d/host/pen.el/config/profile; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/profile ~/.profile
fi

if test -d /root/.emacs.d/host/pen.el/config/vim-bundles; then
    rm -rf ~/.vim/bundle
    mkdir -p ~/.vim/bundle
    ln -sf /root/.emacs.d/host/pen.el/config/vim-bundles/* ~/.vim/bundle
fi

if test -f $HOME/.emacs.d/host/pen.el/config/tmux.conf; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/tmux.conf ~/.tmux.conf
fi

if test -f $HOME/.emacs.d/host/pen.el/config/tmux.conf; then
    ln -sf $HOME/.emacs.d/host/pen.el/config/tmux.conf $HOME/.tmux.conf
fi

if test -f "/root/.emacs.d/host/pen.el/config/screen-2color.ti"; then
    tic "/root/.emacs.d/host/pen.el/config/screen-2color.ti"
fi

if test -f "/root/.emacs.d/host/pen.el/config/screen-2color-norev.ti"; then
    tic "/root/.emacs.d/host/pen.el/config/screen-2color-norev.ti"
fi

if test -f "/root/.emacs.d/host/pen.el/config/Xresources"; then
    ln -sf "/root/.emacs.d/host/pen.el/config/Xresources" ~/.Xresourses
fi

if test -f "$EMACSD/host/pen.el/config/bash/scriptrc"; then
    ln -sf "$EMACSD/host/pen.el/config/bash/scriptrc" ~/.scriptrc
elif test -f "$EMACSD/pen.el/config/bash/scriptrc"; then
    ln -sf "$EMACSD/pen.el/config/bash/scriptrc" ~/.scriptrc
fi

if test -f $HOME/.emacs.d/host/pen.el/config/efm-langserver-config.yaml && ! test -f $HOME/.config/efm-langserver; then
    mkdir -p $HOME/.config/efm-langserver
    ln -sf $HOME/.emacs.d/host/pen.el/config/efm-langserver-config.yaml $HOME/.config/efm-langserver/config.yaml
fi

# Set up an ssh key for using git with github
# Actually, just use http
# setup-ssh.sh

if pen-rc-test host-ssh-master; then
    unbuffer pen-cterm-ssh -ssh -t -M sh &>/dev/null &
fi

if test "$EXPOSE_ETHEREUM" = y || pen-rc-test ethereum; then
    pen-sps geth
fi

# This creates the initial frame

stty stop undef 2>/dev/null; stty start undef 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export TERM=screen-256color

unset EMACSD_BUILTIN
test -d "/root/.emacs.d" && : "${EMACSD_BUILTIN:="/root/.emacs.d"}"
export EMACSD_BUILTIN

unset EMACSD
test -d "/root/.emacs.d/host" && : "${EMACSD:="/root/.emacs.d/host"}"
test -d "/root/.emacs.d" && : "${EMACSD:="/root/.emacs.d"}"
export EMACSD

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

    -no-quit-workers) {
        NO_QUIT_WORKERS=y
        shift
    }
    ;;

    *) break;
esac; done

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

# Must quit all emacs workers and relinquish their reservations before ever checking available pool
# run.sh *should* only happen when starting Pen for the first time, except for when the first argument is a file.
if ! test "$NO_QUIT_WORKERS" = y; then
    echo -n Resetting workers... 1>&2
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

term_env_arr=()

if pen-rc-test truecolor; then
    term_env_arr=(env COLORTERM=truecolor TERM="xterm-24bit" EMACS_TERM_TYPE="xterm-24bit")
fi

runclient() {
    # This does colourise the init but I think I prefer just a single colour
    # USE_NVC=y
    if test "$USE_NVC" = "y"; then
        unbuffer in-tm -d -n pen nvc "${term_env_arr[@]}" pen-emacsclient -s $SOCKET "$@" & disown
    else
        unbuffer in-tm -d -n pen "${term_env_arr[@]}" pen-emacsclient -s $SOCKET "$@" & disown
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

# In case I accidentally committed it
rm -f /tmp/pen.yaml
if test -n "$PEN_N_WORKERS"; then
    pen-rc-set -fp /tmp/pen.yaml n-workers "$PEN_N_WORKERS"
fi

if test -n "$PEN_NO_TIMEOUT"; then
    pen-rc-set -fp /tmp/pen.yaml no-timeout "$PEN_NO_TIMEOUT"
fi

if test -d "$HOME/.pen/elpa-full"; then
    sync-elpa-with-host
fi

# On startup these should always be offline
rm -f ~/.pen/pool/available/*
if ! ls ~/.pen/pool/available/* 2>/dev/null | grep -q pen-emacsd; then
    echo Starting worker pool in background 1>&2
    unbuffer pen-e sa &>/dev/null &
fi

# How to debug worker
# emacs -nw --daemon --debug-init
# How to debug non-worker
# emacs -nw --debug-init

if ! test -n "$DISPLAY"; then
    /usr/bin/nohup Xvfb :0 -screen 0 1x1x8 &>/dev/null &
fi

(
export TERM=zsh
tmux new -d -s init
tmux new -d -s localhost
)

if pen-rc-test -f black_and_white; then
    tmux-bw
fi

pen-ensure-deps

if test -n "$DISPLAY" && test "$PEN_USE_GUI" = y; then
    runclient -c -a "" "$@"
else
    # Start a fake X for the clipboard
    runclient -a "" -t "$@"
fi

# The clients are backgrounded

while true; do
  sleep 1000
done
