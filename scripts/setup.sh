#!/bin/bash

# Debian10 installation

cd ~
apt install git python vim emacs mosh curl make

# For emacs-yamlmod
apt install clang libclang1

test -d emacs || git clone "https://github.com/emacs-mirror/emacs"

# For building emacs
apt install autoconf texinfo gnutls30 gnutls28-dev pkg-config

(
cd emacs
git checkout 0a5e9cf2622a0282d56cc150af5a94b5d5fd71be
./autogen.sh
./configure -with-all --without-makeinfo --with-modules
make
)

# For Pen.el
## slugify
api install libc-bin
## unbuffer
apt install expect
## sponge
apt install moreutils

# rustc and cargo are for building emacs-yamlmod
# Debian GNU/Linux 10 does not have the required version of rustc
# rustc 1.41.1 will not build emacs-yaml
# rustc 1.51.0 will build it
rustc --version | grep -q " 1.5" || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cd ~/.emacs.d/emacs-yamlmod
source $HOME/.cargo/env
make
