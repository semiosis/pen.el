{
stty stop undef; stty start undef
} 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export TERM=xterm-256color
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts
export PATH="$PATH:/root/go/bin"
export PATH="$PATH:/root/.cargo/bin/cargo"
. ~/.cargo/env

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

if [ -f ~/.shellrc ]; then
    . ~/.shellrc
fi