# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
# export LS_OPTIONS='--color=auto'
# eval "`dircolors`"
# alias ls='ls $LS_OPTIONS'
# alias ll='ls $LS_OPTIONS -l'
# alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'
. "$HOME/.cargo/env"
export EMACSD=/root/.emacs.d
term_setup_fp_host="$EMACSD/host/pen.el/scripts/setup-term.sh"
term_setup_fp="$EMACSD/pen.el/scripts/setup-term.sh"
if [ -f "$term_setup_fp_host" ]; then
    . "$term_setup_fp_host"
elif [ -f "$term_setup_fp" ]; then
    . "$term_setup_fp"
fi

[ -f "/root/.ghcup/env" ] && source "/root/.ghcup/env" # ghcup-env

source /root/.config/broot/launcher/bash/br
source /root/repos/kanban.bash/kanban.completion

eval "$(direnv hook bash)"
