#!/bin/bash

# Debian10 installation

export EMACSD=$HOME/.emacs.d
mkdir -p "$EMACSD"
mkdir -p "$HOME/dump"
mkdir -p "$HOME/repos"
mkdir -p "$EMACSD/server"

agi() {
    apt install -y "$@"
}

pyf() {
    pip3 install "$@"
}

cd
agi git python3 vim emacs mosh curl make xsel locales

locale-gen en_IN.utf-8
export LANG=en_US

# For nlsh and ii
agi rlwrap

# For emacs-yamlmod
agi clang libclang1

# For building emacs
# --with-modules is required to load emacs-yamlmod
agi autoconf texinfo libgnutls30 libgnutls28-dev pkg-config

agi python3-pip

# For lm-complete
pyf openai

# For tidy-prompt
pyf yq python-json2yaml

# For AIX API
pyf aixapi requests

pyf huggingface_hub

# For Pen.el
## slugify
agi libc-bin
## unbuffer
agi expect
## pen-sponge
agi moreutils
agi jq
agi neovim
pyf jsonnet

agi tmux

agi swi-prolog-nox
# pyf problog

mkdir -p /root/org-roam

# test -d "huggingface.el" || git clone --depth 1 "http://github.com/semiosis/huggingface.el"

mkdir -p ~/repos/pen-emacsd

mkdir -p ~/.config
(
cd ~/repos/pen-emacsd
test -d prompts || git clone --depth 1 "https://github.com/semiosis/prompts"
test -d engines || git clone --depth 1 "https://github.com/semiosis/engines"
test -d ~/.config/efm-langserver || git clone --depth 1 "https://github.com/semiosis/pen-efm-config" ~/.config/efm-langserver
test -d interpreters || git clone --depth 1 "https://github.com/semiosis/interpreters"
test -d "pen.el" || git clone --depth 1 "https://github.com/semiosis/pen.el"
test -d "ink.el" || git clone --depth 1 "https://github.com/semiosis/ink.el"
test -d "openai-api.el" || git clone --depth 1 "https://github.com/semiosis/openai-api.el"
test -d "pen-contrib.el" || git clone --depth 1 "https://github.com/semiosis/pen-contrib.el"
test -d glossaries || git clone --depth 1 "https://github.com/semiosis/glossaries"
test -d emacs-yamlmod || git clone --depth 1 "https://github.com/perfectayush/emacs-yamlmod"
)

cd
ln -s ~/.config "$EMACSD"

ln -sf ~/.emacs.d/pen.el/config/tmux.conf ~/.tmux.conf
ln -sf ~/.emacs.d/pen.el/src/init-setup.el ~/.emacs
ln -sf ~/.emacs.d/pen.el/config/shellrc ~/.shellrc
echo ". ~/.shellrc" >> ~/.profile

mkdir -p "$EMACSD/comint-history"

# rustc and cargo are for building emacs-yamlmod
# Debian GNU/Linux 10 does not have the required version of rustc
# rustc 1.41.1 will not build emacs-yaml
# rustc 1.51.0 will build it
rustc --version | grep -q " 1.5" || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

export PATH="$PATH:/root/.cargo/bin/cargo"
. ~/.cargo/env
cargo install xsv

(
cd "$EMACSD/emacs-yamlmod"
source $HOME/.cargo/env
make -j 4 || :
)

# I need the tree entire tree, to get the commit I want
# So can't use --depth 1
(
cd
test -d emacs || git clone "https://github.com/emacs-mirror/emacs"
)

apt install libx11-dev
apt install libgtk2.0-dev
apt install libjpeg-dev
apt install libxpm-dev
apt install libpng-dev
apt install libpng16-16
apt install libgif-dev
apt install libtiff-dev
apt install libgnutls28-dev
apt install libjansson-dev
apt install imagemagick-6.q16 libmagick++-6-headers libmagick++-dev
apt install libgtk-3-0 libgtk-3-dev
apt install cargo

(
    cd /root/emacs
    # Has object-intervals
    git checkout df882c9701
    ./autogen.sh
    ./configure --with-all --with-x-toolkit=yes --without-makeinfo --with-modules --with-gnutls=yes
    make
    make install
)
rm -rf /root/emacs

# I want huggingface transformers and I'm going to use clojure to access them
# (
# cd
# git clone --depth 1 "http://github.com/semiosis/huggingface-clj"
# )

(
cd
git clone --depth 1 "https://github.com/syl20bnr/spacemacs"
)

apt install libreadline-dev
apt install libbsd-dev
# (
# cd
# git clone --depth 1 "https://gitlab.com/rosie-pattern-language/rosie"
# cd rosie
# make
# make install
# )

(
export TERM=xterm
unbuffer emacs -nw --eval "(kill-emacs)"
)

(
cd
ln -sf /root/.emacs.d/pen.el/scripts/setup.sh
ln -sf /root/.emacs.d/pen.el/scripts/run.sh
)

ln -sf ~/.emacs.d/pen.el/src/init.el ~/.emacs

(
cd
git clone "https://github.com/dieggsy/eterm-256color"
tic -s ./eterm-256color/eterm-256color.ti
)

apt install chromium

(
cd
wget "http://ports.ubuntu.com/pool/universe/libh/libhtml-html5-parser-perl/libhtml-html5-parser-perl_0.301-2_all.deb"
dpkg -i libhtml-html5-parser-perl_0.301-2_all.deb || true
agi libhtml-html5-parser-perl
agi libhtml-html5-entities-perl
)

(
cd
apt install wget
wget "https://golang.org/dl/go1.17.linux-amd64.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
)

(
cd
git clone "https://github.com/Aleph-Alpha/aleph-alpha-client"
python3 setup.py build install
)

(
apt install libxml2-dev libseccomp-dev
apt install libcurl4-gnutls-dev
cd
git clone "https://github.com/eafer/rdrview"
make
make install
)

(
export PATH=$PATH:/usr/local/go/bin
go get github.com/mattn/efm-langserver
go get mvdan.cc/xurls/cmd/xurls
)
# ~/go/bin/efm-langserver

apt install bc

# curl -L http://cpanmin.us | perl - --sudo App::cpanminus

curl -L http://cpanmin.us | perl - App::cpanminus
cpanm --force String::Escape
cpanm String::Scanf
cpanm List::Gen
cpanm Graph::Easy
cpanm Text::Tabulate
agi libperl-dev # IO::AIO needs this to compile
cpanm IO::AIO
cpanm AnyEvent::AIO
cpanm Perl::LanguageServer

mkdir -p ~/.config/efm-langserver

pip3 install jinja2-cli
agi imagemagick
agi icoutils
agi x11-apps

# urlencode
agi gridsite-clients
agi w3m
agi fzf

# This is kinda optional but will give you a web-facing Pen
agi libssl-dev
# pyf butterfly

# for ttyd
(
cd
git clone https://libwebsockets.org/repo/libwebsockets
cd libwebsockets && mkdir build && cd build
cmake -DLWS_WITH_LIBUV=ON -DLWS_WITH_MBEDTLS=ON ..
make -j 4 && make install
)

# ttyd
apt install libmbedtls12 libmbedtls-dev
(
cd
agi build-essential cmake git libjson-c-dev
git clone https://github.com/tsl0922/ttyd.git
cd ttyd && mkdir build && cd build
cmake ..
sed -i "s/^/# /" /usr/local/lib/cmake/libwebsockets/libwebsockets-config.cmake
make -j 4 && make install
)

# tree-sitter cli
(
git clone "https://github.com/tree-sitter/tree-sitter"
cd tree-sitter/cli
cargo install --path .
)

agi unzip

mkdir -p ~/.fonts
mkdir -p /usr/share/fonts/opentype

# Place your fonts

fc-cache -f -v

# Then in emacs:
# (unicode-fonts-setup)

pip3 install cohere
pip3 install spacy
agi zsh
agi nano
agi ssh
agi moreutils # vipe
agi xclip
agi buffer

IFS= read -r -d '' SHELL_CODE <<'HEREDOC'
export EMACSD=/root/.emacs.d
term_setup_fp="$EMACSD/pen.el/scripts/setup-term.sh"
if [ -f "$term_setup_fp" ]; then
    . "$term_setup_fp"
fi
HEREDOC

printf -- "%s\n" "$SHELL_CODE" >> ~/.bashrc
printf -- "%s\n" "$SHELL_CODE" >> ~/.zshrc

# clojure
agi openjdk-11-jre
(
curl -O https://download.clojure.org/install/linux-install-1.10.3.1040.sh
chmod +x linux-install-1.10.3.1040.sh
./linux-install-1.10.3.1040.sh
)
(
cd /usr/local/bin/
wget "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
chmod a+x lein
# Then need to run lein once
lein
)

(
cp -a "$EMACSD/pen.el/config/nvimrc" ~/.vimrc
)

# For compiling vim
agi ruby-dev
agi gettext
agi libsm-dev
agi libncurses5-dev
agi libgtk2.0-dev libatk1.0-dev
agi libcairo2-dev python-dev
agi python-dev git
agi python3-dev git
agi libpython3-dev
(
mkdir -p ~/repos/vim
cd ~/repos
git clone --depth 1 "https://github.com/vim/vim"
cd vim
./configure --with-features=huge --enable-cscope --enable-multibyte --with-x --enable-perlinterp=yes --enable-pythoninterp=yes --enable-python3interp
make -j8
make install
)