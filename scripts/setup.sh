#!/bin/bash

# Debian10 installation

agi() {
    apt install -y "$@"
}

cd ~
agi git python vim emacs mosh curl make

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

agi python-pip

# For lm-complete
pip install openai

# For lm-complete.sh
pip install yq

# For Pen.el
## slugify
agi libc-bin
## unbuffer
agi expect
## sponge
agi moreutils

(
mkdir -p ~/.emacs.d
cd ~/.emacs.d
test -d prompts || git clone "https://github.com/semiosis/prompts"
)

mkdir -p "/root/.emacs.d/comint-history"

# rustc and cargo are for building emacs-yamlmod
# Debian GNU/Linux 10 does not have the required version of rustc
# rustc 1.41.1 will not build emacs-yaml
# rustc 1.51.0 will build it
rustc --version | grep -q " 1.5" || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cd ~/.emacs.d/emacs-yamlmod
source $HOME/.cargo/env
make
