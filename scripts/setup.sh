#!/bin/bash

# Debian10 installation

export EMACSD=$HOME/.emacs.d
mkdir -p "$EMACSD"

agi() {
    apt install -y "$@"
}

cd ~
agi git python3 vim emacs mosh curl make xsel

# For nlsh and ii
agi rlwrap

# For emacs-yamlmod
agi clang libclang1

test -d emacs || git clone "https://github.com/emacs-mirror/emacs"

# For building emacs
# --with-modules is required to load emacs-yamlmod
agi autoconf texinfo gnutls30 gnutls28-dev pkg-config

(
cd emacs
git checkout 0a5e9cf2622a0282d56cc150af5a94b5d5fd71be
./autogen.sh
./configure -with-all --without-makeinfo --with-modules
make
)

agi python3-pip

# For lm-complete
pip3 install openai

# For tidy-prompt
pip3 install yq python-json2yaml

# For Pen.el
## slugify
agi libc-bin
## unbuffer
agi expect
## sponge
agi moreutils

(
cd ~/.emacs.d
test -d prompts || git clone "https://github.com/semiosis/prompts"
)

ln -sf ~/.emacs.d/pen.el/src/init.el ~/.emacs

mkdir -p "$EMACSD/comint-history"

# rustc and cargo are for building emacs-yamlmod
# Debian GNU/Linux 10 does not have the required version of rustc
# rustc 1.41.1 will not build emacs-yaml
# rustc 1.51.0 will build it
rustc --version | grep -q " 1.5" || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cd "$EMACSD/emacs-yamlmod"
source $HOME/.cargo/env
make
