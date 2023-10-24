#!/bin/bash

mcd () {
    last_arg="${@: -1}"
    mkdir -p "$@" && cd "$last_arg"
}

# Debian11 installation

agi apt-file
apt-file update

export SSH_HOST_ALLOWED=n

export DUMP=/root/dump

unset EMACSD_BUILTIN
test -d "/root/.emacs.d" && : "${EMACSD_BUILTIN:="/root/.emacs.d"}"
export EMACSD_BUILTIN

unset EMACSD
test -d "/root/.emacs.d/host" && : "${EMACSD:="/root/.emacs.d/host"}"
test -d "/root/.emacs.d" && : "${EMACSD:="/root/.emacs.d"}"
export EMACSD

mkdir -p "$EMACSD"
mkdir -p "$HOME/dump"
mkdir -p "$HOME/repos"
mkdir -p "$EMACSD/server"

git() {
    /usr/bin/git "$@"
}

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

agi eog

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

tic $HOME/repos/pen.el/config/eterm-256color.ti
tic $HOME/repos/pen.el/config/screen-256color.ti
tic $HOME/repos/pen.el/config/screen-2color.ti
tic $HOME/repos/pen.el/config/screen-2color.ti
tic $HOME/repos/pen.el/config/xterm-24bit.ti
# tic /root/.emacs.d/host/pen.el/config/xterm-24bit.ti

rm -rf ~/.emacs.d
ln -s ~/repos/pen-emacsd ~/.emacs.d

cd
ln -s ~/.config "$EMACSD"

ln -sf ~/.emacs.d/pen.el/config/tmux.conf ~/.tmux.conf
ln -sf ~/.emacs.d/pen.el/config/tmux.conf.human ~/.tmux.conf.human
touch ~/.tmux.conf.main
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
. $HOME/.cargo/env
make -j 4 || :
)

# I need the tree entire tree, to get the commit I want
# So can't use --depth 1
(
cd
test -d emacs || git clone "https://github.com/emacs-mirror/emacs"
)

apt install cargo

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

(
cd "$DUMP/programs"
wget "http://ftp.us.debian.org/debian/pool/main/t/tree-sitter/libtree-sitter0_0.20.8-2_amd64.deb"
dpkg -i "libtree-sitter0_0.20.8-2_amd64.deb"
wget "http://ftp.us.debian.org/debian/pool/main/t/tree-sitter/libtree-sitter-dev_0.20.8-2_amd64.deb"
dpkg -i "libtree-sitter-dev_0.20.8-2_amd64.deb"
)

(
    cd /root/emacs
    # Has object-intervals
    # emacs 28
    # git checkout df882c9701
    # ./autogen.sh
    # ./configure --with-all --with-x-toolkit=yes --without-makeinfo --with-modules --with-gnutls=yes

    # emacs 29
    git checkout ec4d29c4494f32acf0ff7c5632a1d951d957f084
    # git clone --branch emacs-29 --depth 1 "https://github.com/emacs-mirror/emacs"
    # --with-native-compilation takes longer
    # --with-small-ja-dic appears to make it hang
    ./autogen.sh
    sudo apt install libsqlite3-dev libgccjit0 libgccjit-8-dev
    #./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes \
    #    --with-native-compilation --with-tree-sitter --with-small-ja-dic \
    #    --with-gif --with-png --with-jpeg --with-rsvg --with-tiff \
    #    --with-imagemagick

    # emacs-29
    ./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes --with-tree-sitter --with-small-ja-dic --with-gif --with-png --with-jpeg --with-rsvg --with-tiff --with-imagemagick

    # emacs-28
    ./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes --with-gif --with-png --with-jpeg --with-rsvg --with-tiff --with-imagemagick
    # make
    # Remove scripts from the path (because emacs will hang when it looks for
    # and finds cvs, and tries to run it.)

    export PATH="$(echo "$PATH" | sed 's/:/\n/g' | grep -v pen.el | sed '/^$/d' | s join :)"
    make -j$(nproc)
    make install
)
rm -rf /root/emacs

# I want huggingface transformers and I'm going to use clojure to access them
# (
# cd
# git clone --depth 1 "http://github.com/semiosis/huggingface-clj"
# )

# (
# cd
# git clone --depth 1 "https://github.com/syl20bnr/spacemacs"
# )

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

# https://go.dev/doc/install
(
cd
apt install wget
wget "https://go.dev/dl/go1.21.1.linux-amd64.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
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
plf String::Escape
cpanm String::Scanf
cpanm List::Gen
cpanm Graph::Easy
cpanm Text::Tabulate
agi libperl-dev # IO::AIO needs this to compile
cpanm IO::AIO
cpanm AnyEvent::AIO
cpanm Perl::LanguageServer
cpanm Emacs::PDE

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
cd ttyd
sed -i "s/ttyd - Terminal/Pen.el/" html/webpack.config.js
mkdir build && cd build
cmake ..
` # This was here but broke it: sed -i "s/^/# /" /usr/local/lib/cmake/libwebsockets/libwebsockets-config.cmake `
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

# IFS= read -r -d '' XR_CODE <<'HEREDOC'
# Emacs.pane.menubar.background: darkGrey
# Emacs.pane.menubar.foreground: black
# Emacs*menubar.margin: 0
# Emacs*shadowThickness: 1
# 
# ! xterm*faceSize: 20
# ! *font: -*-*-bold-*-*-*-18-*-*-*-*-*-*-*
# ! *boldfont: -*-*-bold-*-*-*-18-*-*-*-*-*-*-*
# ! xterm*font: -*-*-bold-*-*-*-18-*-*-*-*-*-*-*
# ! xterm*boldfont: -*-*-bold-*-*-*-18-*-*-*-*-*-*-*
# 
# xterm*faceName: Monospace:style=Bold:antialias=true:pixelsize=20
# HEREDOC
# printf -- "%s\n" "$XR_CODE" >> $HOME/.Xresources

IFS= read -r -d '' SHELL_CODE <<'HEREDOC'
stty stop undef; stty start undef; 
eval $(resize) &>/dev/null
sleep 0.1
{
. ~/.shell_environment
} 2>/dev/null
HEREDOC
printf -- "%s\n" "$SHELL_CODE" >> $HOME/.xterm-sh-rc

IFS= read -r -d '' SHELL_CODE <<'HEREDOC'
export EMACSD=/root/.emacs.d
term_setup_fp_host="$EMACSD/host/pen.el/scripts/setup-term.sh"
term_setup_fp="$EMACSD/pen.el/scripts/setup-term.sh"
if [ -f "$term_setup_fp_host" ]; then
    . "$term_setup_fp_host"
elif [ -f "$term_setup_fp" ]; then
    . "$term_setup_fp"
fi
HEREDOC

printf -- "%s\n" "$SHELL_CODE" >> ~/.bashrc

# printf -- "%s\n" "$SHELL_CODE" >> ~/.zshrc

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

# TODO Set up a full-blown go environment for compiling efm-langserver
(
cd
wget "https://go.dev/dl/go1.17.5.linux-amd64.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.5.linux-amd64.tar.gz
)
export PATH=$PATH:/usr/local/go/bin

(
git clone "https://github.com/semiosis/efm-langserver"
cd "efm-langserver"
)

# go language server
go install golang.org/x/tools/gopls@latest

(
cp -a "$EMACSD/pen.el/config/nvimrc" ~/.vimrc
)

mkdir -p "$HOME/.pen/conf/"
for fn in ff-url-patterns.txt reader-url-patterns.txt chrome-dom-url-patterns.txt; do
    test -f "$HOME/.pen/conf/$fn" ||
        cp -a "$EMACSD/host/pen.el/config/$fn" ~/.pen/conf ||
        cp -a "$EMACSD/pen.el/config/$fn" ~/.pen/conf
done

(
mkdir -p $HOME/.config/broot/
cp -a "$EMACSD/pen.el/config/broot-conf.toml" $HOME/.config/broot/conf.toml 
rm -f $HOME/.config/broot/conf.hjson
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
cd ~/repos
git clone --depth 1 "https://github.com/vim/vim"
cd vim
./configure --with-features=huge --enable-cscope --enable-multibyte --with-x --enable-perlinterp=yes --enable-pythoninterp=yes --enable-python3interp
make -j8
make install
)

(
cd ~/repos
git clone --depth 1 "https://github.com/semiosis/rangerconfig"
cd rangerconfig
git checkout pen
rm -rf ~/.config/ranger
ln -sf ~/repos/rangerconfig ~/.config/ranger
)

agi colorized-logs

# gnu parallel
apt install parallel

ln -sf ~/.emacs.d/pen.el/config/efm-langserver-config.yaml ~/.config/efm-langserver/config.yaml

agi silversearcher-ag
agi sshfs

# For vterm
agi libtool-bin

agi asciinema

# For apostrophe
agi inotify-tools iwatch

pen-x -sh "adduser pen" -e "New password" -s pen -c m -e "Retype" -s pen -c m -e "Full Name" -s Pen -c m -c m -c m -c m -c m -e correct -s Y -c m -i
# 1000
pen_id="$(id -u pen)"
(
cd /
agi git
agi perl
agi g++
agi make
wget https://github.com/inspircd/inspircd/archive/v2.0.25.tar.gz
tar zxf v2.0.25.tar.gz
mkdir -p inspircd-2.0.25/run/conf
mkdir -p inspircd-2.0.25/run/modules
mkdir -p inspircd-2.0.25/run/bin
mkdir -p inspircd-2.0.25/run/data
mkdir -p inspircd-2.0.25/run/logs
mkdir -p inspircd-2.0.25/run/build
cd inspircd-2.0.25/
pen-x \
    -sh "perl ./configure" \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "In what directory" -c m \
    -e "Enable epoll" -s y -c m \
    -e "One or more" -s y -c m \
    -e "Would you like" -s y -c m \
    -c m \
    -e "Would you like" -s y -c m \
    -e "Would you like" -s y -c m \
    -i
make -j 5
./configure --uid "$pen_id"
make install
cp -a ~/repos/pen.el/config/irc-config.conf /inspircd-2.0.25/run/conf/inspircd.conf
)

agi irssi

agi lolcat

# For timg
agi graphicsmagick libgraphicsmagick++-q16-12 libgraphicsmagick++1-dev
agi libavcodec-dev libavcodec58
agi libavformat58 libavformat-dev
agi libswscale-dev libswscale5
agi libturbojpeg0 libturbojpeg0-dev
agi libavutil56 libavutil-dev
agi libavdevice58 libavdevice-dev
(
    cd ~/repos
    git clone "https://github.com/hzeller/timg"
    cd timg
    mkdir -p build
    cd build
    # This is the clean of cmake
    rm -f CMakeCache.txt
    cmake ..
    make
)

agi ranger

(
    cd ~/repos
    git clone "https://github.com/mullikine/eterm-256color"
)

agi net-tools
agi netcat

agi vifm

(
    cd ~/repos
    git clone "http://github.com/semiosis/pensieve"
    cd pensieve
    lein deps
)
ln -s ~/repos/pensieve ~/.emacs.d/pensieve

pyf rich

agi xterm

agi mplayer

agi feh

mkdir -p ~/programs/zsh/dotfiles
mkdir -p ~/.pen/downloads
(
cd ~/repos
git clone --depth 1 "http://github.com/mullikine/oh-my-zsh"
)

# Ensure some directories
mkdir -p /root/pensieves

(
cd ~/repos
git clone "http://github.com/semiosis/rhizome"
ln -s ~/repos/rhizome ~/.emacs.d/rhizome
)

(
cd ~/repos
git clone "http://github.com/semiosis/khala"
ln -s ~/repos/khala ~/.emacs.d/khala
)

agi postgresql

agi nmap

(
cd ~/repos
git clone "https://github.com/charmbracelet/charm"
git clone "https://github.com/charmbracelet/bubbletea"
git clone "https://github.com/charmbracelet/lipgloss"
git clone "https://github.com/charmbracelet/wish"
git clone "https://github.com/charmbracelet/soft-serve"
)
pen-build-charm
go install github.com/charmbracelet/soft-serve/cmd/soft@latest

(
cd ~/repos
git clone "https://github.com/huginn/huginn"
)

(
cd ~/repos
git clone "https://github.com/semiosis/yas-snippets"
ln -sf ~/repos/yas-snippets ~/.emacs.d/snippets
)

(
cd ~/repos
git clone "https://github.com/lazamar/haskell-docs-cli"
cd haskell-docs-cli
cabal install
)

(
cd ~/repos
git clone "https://github.com/elaforge/fix-imports"
cd fix-imports
cabal install
)

# ispell
agi dialog apt-utils
agi dictionaries-common
dpkg --force-depends --configure -a
agi ispell

# localtunnel
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm install 12.14.1
npm install -g localtunnel
# lt --port 7681

agi iceweasel

(
cp -a ~/repos/pen.el/config/irc-config.conf /inspircd-2.0.25/run/conf/inspircd.conf
)

# Sadly, the hosts file may change, so this is not good enough
# I need to ensure that irc.localhost is in there when starting MTP
# This does make the container host-specific though. But it doesn't appear to cause problems
# Testing on the VPS worked fine.
# I think the host should be added when starting pen, in run.sh
(
touch /etc/hosts
echo "127.0.1.1	pen-$(hostname)" >> /etc/hosts
cat ~/repos/pen.el/config/hosts >> /etc/hosts
)

# This is what is required
mtp-ensure-hosts

# GLIDE
pyf "git+https://github.com/openai/glide-text2im"

# Prolog
agi swi-prolog
# prolog-pack-install lsp_server

# Python
agi ipython

# dig
agi dnsutils

# arp
agi arp-scan

# dhclient
agi isc-dhcp-client

agi mitmproxy

agi lsof


IFS= read -r -d '' racketshcode <<HEREDOC
raco pkg install --batch readline-gpl
raco pkg install --batch brag
raco pkg install --batch memoize
raco pkg install --batch glob
raco pkg install --batch racket-langserver
raco pkg install --batch irc
raco pkg install --batch python
raco pkg install --batch snappy
raco pkg install --batch linea
raco pkg install --batch shell-pipeline
raco pkg install --batch rash
raco pkg install --batch spipe
raco pkg install --batch describe
raco pkg install --batch --deps search-auto megaparsack
raco pkg install racket-langserver
raco pkg install pollen
raco pkg install --batch --deps search-auto
HEREDOC

printf -- "%s\n" "$racketshcode" | while read line; do
    line="$(p "$line" | sed 's/ --batch//')"
    eval "set -- $line"
    shift 3
    raco pkg install --batch --deps search-auto "$@"
done

# Create json from shell
agi jo

agi uuid

# yggdrasil
gpg --fetch-keys https://neilalexander.s3.dualstack.eu-west-2.amazonaws.com/deb/key.txt
gpg --export 569130E8CA20FBC4CB3FDE555898470A764B32C9 | sudo apt-key add -
echo 'deb http://neilalexander.s3.dualstack.eu-west-2.amazonaws.com/deb/ debian yggdrasil' | sudo tee /etc/apt/sources.list.d/yggdrasil.list
apt-get update

pip3 install ssdpy

# emacs-application-framework
# python3t-fitz
pip3 install --upgrade pip
pip3 install PyMuPDF

pip3 install binaryornot

# Install mysql -- for Croogle
apt install default-mysql-server
apt install php-mysqli
echo "\nport = 3360" >> /etc/mysql/my.cnf

pen-x -shE "mysql -u root" -e "MariaDB [" -s "flush privileges;" -c m \
    -e "MariaDB [" -s "USE mysql;" -c m \
    -e "MariaDB [" -s "UPDATE mysql.user SET authentication_string=PASSWORD('oracle') WHERE User = 'root';" -c m \
    -e "MariaDB [" -s "CREATE DATABASE fileindexdb;" -c m \
    -e "MariaDB [" -s "quit;" -c m \
    -i

mkdir -p /var/www/
ln -s ~/repos/wizard /var/www/wizard
mkdir -p /etc/apache2/sites-available

test -f $REPOS/googler/googler || (
    cd "$REPOS"
    git clone "https://github.com/jarun/googler"
    cd googler
    make
)

test -f $REPOS/ddgr/ddgr || (
    cd "$REPOS"
    git clone "https://github.com/jarun/ddgr"
    cd ddgr
    make
)

test -d $REPOS/gh-dash || (
    cd "$REPOS"
    git clone "https://github.com/dlvhdr/gh-dash"
    cd gh-dash
    go get -u github.com/dlvhdr/gh-dash
)

test -d $REPOS/figlet-fonts || (
    cd "$REPOS"
    git clone "https://github.com/xero/figlet-fonts"
)

test -d $REPOS/glow || (
    cd "$REPOS"
    git clone "https://github.com/charmbracelet/glow"
    cd glow
    go build
)

test -d $REPOS/go-ethereum || (
    cd "$REPOS"
    git clone "https://github.com/ethereum/go-ethereum"
    cd go-ethereum
    make all
    go run build/ci.go install ./cmd/geth
)

# Haskell: - gcup, cabal, hls
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
# =gcup tui= to configure
# To start a simple repl, run:
#   ghci
# 
# To start a new haskell project in the current directory, run:
#   cabal init --interactive
# 
# To install other GHC versions and tools, run:
#   ghcup tui
# 
# If you are new to Haskell, check out https://www.haskell.org/ghcup/install/#first-steps

# Install haskell dev tools
# https://gitlab.cecs.anu.edu.au/pages/2020-S2/courses/comp1100/resources/10-install/
cabal v2-install --install-method=copy ghcid
cabal v2-install --install-method=copy doctest
cabal install hoogle
cabal install stack2cabal
hoogle generate

# For the clipboard
agi xvfb

agi toilet

agi bindfs
agi elinks

# notify-send
agi libnotify-bin

# It turns out I need a normal user to install nix, which needs sudo
agi sudo

## Install nix and dap tools under the pen user
# login pen
# sh <(curl -L https://nixos.org/nix/install) --no-worker
# curl https://dapp.tools/install | sh

agi ispell

# Without gpg2, package-refresh will not work alongside my gpg config
agi gnupg2

(
cd
wget "https://github.com/smallhadroncollider/taskell/releases/download/1.11.4/taskell-1.11.4_x86-64-linux.deb"
dpkg -i taskell-1.11.4_x86-64-linux.deb
)

agi ripgrep

# common lisp
agi git build-essential automake libcurl4-openssl-dev
test -d "$REPOS/roswell" || (
    cd "$REPOS"
    git clone -b release https://github.com/roswell/roswell
    cd roswell
    sh bootstrap
    ./configure
    make
    sudo make install
    ros setup
)

# This is for browsing source code
(
cd /tmp
/usr/bin/git clone "https://github.com/sbcl/sbcl"
)

# This failed, annoyingly
# ros install clisp
# Perhaps I should just install clisp through apt. Yeah, I should do that.
agi clisp

# https://stackoverflow.com/q/70483583
ros install fukamachi/cl-project

# To use, add this to your $HOME/.emacs:
# (load (expand-file-name "$HOME/.roswell/helper.el"))
ros install slime

touch ~/.sbclrc
test -s ~/.sbclrc || echo > ~/.sbclrc

ros install sbcl

quicklisp-install str
quicklisp-install listopia
quicklisp-install sycamore
quicklisp-install access
quicklisp-install closer-mop

# mkdir -p /root/.emacs.d
# cp -a "$REPOS/roswell/lisp/helper.el" /root/.emacs.d/roswell-helper.el

mkdir -p /root/.vim
cp -a /root/repos/pen.el/config/inkpot.vim /root/.vim
cp -a /root/repos/pen.el/config/paste-replace.vim /root/.vim
cp -a /root/repos/pen.el/config/utils.vim /root/.vim
cp -a /root/repos/pen.el/config/pen.vim /root/.vim
cp -a /root/repos/pen.el/config/nvim-function-keysvimrc /root/.vim
cp -a /root/repos/pen.el/config/fixkeymaps-vimrc /root/.vim

mkdir -p /root/.emacs.d/eshell
cp -a /root/repos/pen.el/config/eshell/* /root/.emacs.d/eshell

# Ansible
agi libonig-dev
pip3 install 'ansible-navigator[ansible-core]'

# Xterm, etc.
cp -a /root/repos/pen.el/config/Xresources /root/.Xresources

# vim
(
cd ~/.vim
git clone "https://github.com/tpope/vim-pathogen"
ln -sf ~/.vim/vim-pathogen/autoload/pathogen.vim ~/.vim/autoload
mkdir -p ~/.vim/bundle
cp -a /root/repos/pen.el/config/vim-bundles/* /root/.vim/bundle
)

# Required by SaveTemp():
# /root/.emacs.d/host/pen.el/config/utils.vim
mkdir -p ~/dump/tmp/

pyf problog

cargo install grex

# Perl
agi perl-doc

agi wordnet

IFS= read -r -d '' LOCATE_CODE <<'HEREDOC'
PRUNE_BIND_MOUNTS="yes"
# PRUNENAMES=".git .bzr .hg .svn"
PRUNEPATHS="/tmp /volumes /var/spool /media /var/lib/os-prober /var/lib/ceph /home/.ecryptfs /var/lib/schroot"
PRUNEFS="NFS afs autofs binfmt_misc ceph cgroup cgroup2 cifs coda configfs curlftpfs debugfs devfs devpts devtmpfs ecryptfs ftpfs fuse.ceph fuse.cryfs fuse.encfs fuse.glusterfs fuse.gvfsd-fuse fuse.mfs fuse.rozofs fuse.sshfs fusectl fusesmb hugetlbfs iso9660 lustre lustre_lite mfs mqueue ncpfs nfs nfs4 ocfs ocfs2 proc pstore rpc_pipefs securityfs shfs smbfs sysfs tmpfs tracefs udev udf usbfs"
HEREDOC
printf -- "%s\n" "$LOCATE_CODE" >> /etc/updatedb.conf

# Python3.8 for AlephAlpha
# apt update
# make -j 4, also runs tests, annoyingly
(
agi build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
mcd $DUMP/programs
curl -O https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tar.xz
tar Jxf Python-3.8.2.tar.xz
cd Python-3.8.2
./configure --enable-optimizations
make -j 4
make altinstall
)

pip3.8 install --force-reinstall ipython
pip3.8 install --force-reinstall aleph-alpha-client


pip3.8 install bpython
pip3 install bpython

# Python3.10 for baca - epub viewer
# apt update
# make -j 4, also runs tests, annoyingly
(
agi build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
mcd $DUMP/programs
curl -O https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
tar Jxf Python-3.10.0.tar.xz
cd Python-3.10.0
./configure --enable-optimizations
make -j 4
make altinstall
)

pip3.10 install --force-reinstall ipython
pip3.10 install bpython
pip3.10 install baca
# paint for the terminal
pip3.10 install textual-paint

(
cd
git clone "http://github.com/mullikine/shanepy"
)

export PYTHONPATH="$PYTHONPATH:$(glob "/root/pen_python_modules/*" | tr '\n' : | sed 's/:$//')"

# For shanepy
for i in jsonpickle ptpython pyyaml; do
    pip3 install "$i"
    pip3.8 install "$i"
done

mkdir -p $HOME/.config
(
cd $HOME/.config
git clone "http://github.com/mullikine/.ptpython" ptpython
)

mkdir -p /root/.pen/documents/notes/ws/python
(
cd /root/.pen/documents/notes/ws/python
ln -sf /root/pen_python_modules/shanepy
)

apt-get install python3-venv
pip3 install --upgrade --force-reinstall virtualenv
pip3.8 install --upgrade --force-reinstall virtualenv

# For gtags
agi global

# https://www.wilfred.me.uk/blog/2022/09/06/difftastic-the-fantastic-diff/
cargo install difftastic

pyf yamlfmt

# rls is deprecated
# cargo install rls

# Currently not working. Apparantly, it's normal for the latest version to not work
# Install the rust language server (rust-analyzer) manually (rather than through emacs)
rm -f ~/.cargo/bin/rust-analyzer
# adds it to here: /root/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin
rustup component add rust-analyzer
rustup toolchain install nightly --component rust-analyzer-preview

# rm -f ~/.local/bin/rust-analyzer
# (
# cd "$(gc "https://github.com/rust-analyzer/rust-analyzer")"
# cargo xtask install --server
# )

# REPL
# $MYGIT/sigmaSd/IRust/README.md
cargo install irust

# For scope
agi mediainfo

# For fuse
agi libfuse3-dev libfuse3-3

# For glimpse search engine
agi glimpse

agi tclsh

agi elinks

pyf pdf2txt

# node
(
npm install -g npm@8.19.1
)

# Solidity
(
cd ~/repos/
git clone "http://github.com/mullikine/lsp-solidity-el"
cd /usr/local/bin/
wget https://github.com/ethereum/solidity/releases/download/v0.8.17/solc-static-linux -O solc
chmod a+x solc
)

(
npm install -g solidity-language-server
# https://github.com/ethereum/solidity/releases
)

(
cd "$HOME/repos"
git clone "http://github.com/mullikine/sh-source"
)

agi asciidoc
(
cd "$HOME/repos"
git clone "https://github.com/git/git"
cd git
make configure
./configure --prefix=/usr
make all doc
make install install-doc install-html
)

(
# cd "$HOME/programs"
# wget "https://github.com/helix-editor/helix/releases/download/23.05/helix-23.05-x86_64-linux.tar.xz"
# tar Jxf helix-23.05-x86_64-linux.tar.xz 
cd "$HOME/repos"
# update-rust
git clone "https://github.com/helix-editor/helix"
cd helix
cargo install --path helix-term --locked
cd /root/.config/helix
ln -sf /root/repos/helix/runtime
)

e ia quelpa quelpa-use-package

(
cat /etc/apt/sources.list | awk 1
echo deb http://deb.debian.org/debian bullseye-backports main
) | sponge /etc/apt/sources.list

# gomuks
# https://backports.debian.org/Instructions/
# need backports for libolm3
# libolm-dev is not available. Manually copy the .h file
(
agi libolm3
cd "$HOME/repos"
git clone "http://github.com/tulir/gomuks"
mkdir -p /usr/include/
cp /root/repos/pen.el/config/olm /usr/include/
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:${LD_LIBRARY_PATH}
ln -sf /usr/lib/x86_64-linux-gnu/libolm.so.3 /usr/lib/x86_64-linux-gnu/libolm.so
cd gomuks
go build
go install
)

# For markdown-mode
agi pandoc

(
# h-m-m is cool but it doesn't play well with terminals for typing, and gets buggy
# http://github.com/nadrad/h-m-m
agi php php-mbstring
sed -i '/;extension=mbstring/s/;//' /etc/php/7.3/cli/php.ini
cd "$HOME/repos"
git clone "http://github.com/nadrad/h-m-m"
cd h-m-m
sed -i '/<?php/aerror_reporting(0);' h-m-m
)

mkdir -p $HOME/downloads

agi strace

# bubbletea apps
go install github.com/maaslalani/gambit@latest
go install github.com/maaslalani/slides@latest
go install github.com/abhimanyu003/sttr@latest
go install github.com/torbratsberg/noted@latest

# These did not install
# go install github.com/MicheleFiladelfia/mandelbrot-cli@latest
# go install github.com/mergestat/mergestat@latest

# For any2org
agi pandoc

agi unionfs-fuse

# kanban
(
agi gawk
cd "$HOME/repos"
git clone "http://github.com/coderofsalvation/kanban.bash"
)

# jot
# https://github.com/araekiel/jot
cargo install jt

pip install jc

# For eaf
# agi libgit2-dev - doesn't seem to be the right version
# Don't bother building it. Rather, find the right deb. But forget eaf.

# For goaccess
# agi libmaxminddb-dev libmaxminddb0

agi ssdeep

pip install textual-markdown

cargo install teetty

mkdir -p ~/.local/bin
curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
chmod +x ~/.local/bin/rust-analyzer

# http://github.com/joshcho/ChatGPT.el/blob/main/README.org
# https://github.com/mullikine/ChatGPT-pen.el
pip install epc
pip install git+https://github.com/mmabrouk/chatgpt-wrapper
playwright install

# Used to display man pages for go files
go install github.com/appliedgocode/goman@latest

# For add-apt-repository
agi software-properties-common
# add-apt-repository ppa:pkgcrosswire/ppa
# add-apt-repository --remove ppa:pkgcrosswire/ppa

(
cd "$HOME/repos"
git clone "https://github.com/crosswire/xiphos"
cd xiphos
)

agi xiphos xiphos-data

agi ftp

# For latest tmux, which is needed for helix (hx) to display truecolor, which is not that important
# (
# cd "$HOME/repos"
# git clone "https://github.com/libevent/libevent"
# cd libevent
# mkdir build && cd build
# cmake ..     # Default to Unix Makefiles.
# make
# make install
# )


(
cd "/root/.emacs.d/manual-packages/"
git clone "https://github.com/Zacalot/bible-mode"
)

(
cd "$HOME/repos"
git clone "http://github.com/g4jc/diatheke-tui"
cd xiphos
)

mkfastmod NASB

go install github.com/maaslalani/draw@latest

agi yasm nasm

go install github.com/charmbracelet/gum@latest

agi calibre
agi sqlite3

# Generate epub from website, then use it in Baca
npm install -g percollate

# Sadly, the GUI doesn't seem to work
# goldendict - for Maori language, etc.
agi git pkg-config build-essential qt5-qmake \
    libvorbis-dev zlib1g-dev libhunspell-dev x11proto-record-dev \
    qtdeclarative5-dev libxtst-dev liblzo2-dev libbz2-dev \
    libao-dev libavutil-dev libavformat-dev libtiff5-dev libeb16-dev \
    libqt5webkit5-dev libqt5svg5-dev libqt5x11extras5-dev qttools5-dev \
    qttools5-dev-tools qtmultimedia5-dev libqt5multimedia5-plugins
# qmake-qt4 && make
# https://github.com/goldendict/goldendict

# https://github.com/konstare/gdcv
agi zlib1g-dev unzip
# cd "$HOME/repos/konstare/gdcv"; make gdcv

# cd "$(o "'https://github.com/konstare/gdcv")"

agi socat cpipe

# This is for the tm-vimbible command
mkdir -p $PENCONF/documents/notes/ws/vimbible

agi direnv

# For $EMACSD/host/pen.el/scripts/grepgithub.py
pip3.10 install bs4
pip3.10 install html5lib
pip3.10 install lxml

e ia topsy prism

(
cd "$EMACSD/manual-packages"
git clone "https://github.com/mickeynp/combobulate"
)

(
cd "$EMACSD/manual-packages"
git clone "https://github.com/alphapapa/obvious.el"
)

# A TUI common-lisp IDE
ros install lem-project/lem

(
cd "$HOME/repos"
git clone --recursive https://github.com/lem-project/lem
git clone https://github.com/lem-project/micros
cd lem
)
 

# (ql:quickload :swank)
xs quicklisp-install swank

# cd "$HOME/.roswell/local-projects/lem-project/lem"; sh-yank
{
cd $(ros -e '(princ (ql:where-is-system :lem))')
git submodule update --init --recursive
ros follow-dependency=t install lem-project/lem
}

# LSP - use this also in emacs
ros install lem-project/lem cxxxr/cl-lsp

pip install pip-search
pip3.8 install pip-search
pip3.10 install pip-search


# Python3.11 for baca - epub viewer
# apt update
# make -j 4, also runs tests, annoyingly
(
agi build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
mcd $DUMP/programs
curl -O https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tar.xz
tar Jxf Python-3.11.4.tar.xz
cd Python-3.11.4
./configure --enable-optimizations
make -j 4
make altinstall

# broot
cargo install --locked --features clipboard broot

# crossword is amazing
e ia crossword wordel most-used-words

# We don't need nvim yet
# ln -sf /root/.emacs.d/host/pen.el/config/nvimrc ~/.nvimrc
# ln -sf /root/.emacs.d/host/pen.el/config/nvim ~/.config/
# ln -sf /root/.emacs.d/host/pen.el/config/nvim/nvimrc ~/.nvimrc

# For bpython
pip3.10 install urwid

# BM25
pip3.10  install -qr requirements.txt

# rust disk usage analyzer
cargo install dua-cli --no-default-features --features tui-crossplatform

# go disk usage analyzer
go install github.com/dundee/gdu/v5/cmd/gdu@latest

# visidata
pen_python_version="$(pen-python --version | scrape '[0-9]+.[0-9]+')"
pen_python() {
    "pip$pen_python_version" "$@"
}
# for scraping with visidata
# https://github.com/visidata/vdplus/tree/develop/scraper
pen_python install --upgrade visidata
pen_python install bs4
pen_python install html5lib
pen_python install lxml
pen_python install requests_cache

# codesplunker
go install github.com/boyter/cs@v1.3.0

# ugrep is an advanced grep, with indexing.
# This might be quite useful, perhaps with emacs' counsel.
# ugrep -HnRi "Derek Prince" . | v
(
cd "$(gc "https://github.com/Genivia/ugrep")"
./build.sh --enable-pager
make install
agi antiword
)

(
cd "$(gc "https://github.com/exiftool/exiftool")"
perl Makefile.PL
make
make test
make install
)

ln -sf /root/.pen/documents/textmirror /root/text-mirror

# visidata
pip3.8 install tomli

pip3.8 install remarshal


# elinks
agi libmozjs-60-0 libmozjs-60-dev
agi python3-bs4
(
cd "$(gc "http://github.com/rkd77/elinks")"
./autogen.sh 
./configure --with-python=python3.8 && make && make install
)

e ia meson-mode
# /volumes/home/shane/var/smulliga/source/git/rkd77/elinks/meson.build

# for 'calc'
agi apcalc

agi libevent-dev

agi cmatrix

agi telnet

# Search and download transcripts
pip3.8 install ytps
pip3.8 install youtube-transcript-api
pip3.8 install trafilatura

# Haskell - but is this OK for Pen.el? Will it take much space to install?
# I guess I'll find out.
# cabal install xml-to-json

cargo install cargo-quickinstall
# xml-to-json STILL doesn't install
# cargo-quickinstall xml-to-json
cargo-quickinstall ripgrep

agi xmlstarlet

pip install defusedxml

(
cd "$(gc "https://github.com/eliask/xml2json")"
)

agi nvi
agi coreutils

go install github.com/antonmedv/walk@latest

(
cd "$(gc "https://github.com/xero/figlet-fonts")"
)

# Possible to play online against opponents
pip install cli-chess

agi unicode

ros install koji-kojiro/cl-repl

e ia mini-frame

# https://asciinema.org/~ronilan
# The games look cool but they haven't run
npm install -g impossible-flappy
npm install -g impossible-breakout
npm install -g impossible-hn

# Sadly can't install this -- too many new dependencies
# (
# cd "$DUMP/programs"
# wget "http://ftp.us.debian.org/debian/pool/main/g/gcc-13/libgcc-s1_13.2.0-2_amd64.deb"
# dpkg -i libgcc-s1_13.2.0-2_amd64.deb 
# wget "http://ftp.us.debian.org/debian/pool/main/e/enchant-2/libenchant-2-2_2.3.3-2_amd64.deb"
# dpkg -i libenchant-2-2_2.3.3-2_amd64.deb 
# wget "http://ftp.us.debian.org/debian/pool/main/e/enchant-2/libenchant-2-dev_2.3.3-2_amd64.deb"
# dpkg -i libenchant-2-dev_2.3.3-2_amd64.deb 
# cd "$(gc "https://github.com/eschluntz/compress")"
# ./install.sh
# )

# a database is a good idea to start speeding things up
e ia emacsql emacsql-mysql emacsql-psql emacsql-sqlite emacsql-sqlite3

(
if ! test -f ~/.pen/cross_references.tsv && test -d ~/.pen; then
    cd ~/.pen
    wget "https://a.openbible.info/data/cross-references.zip"
    unzip cross-references.zip
    mv cross_references.txt cross_references.tsv
fi
)

# Database
(
cd /root/dump/root/notes/databases/
test -f kjv.db || http://simoncozens.github.io/open-source-bible-data/cooked/sqlite/kjv.db
)
e ia edbi

# for emacs edbi
plf install DBD::SQLite 
plf install RPC::EPC::Service

pip install -U litecli

(
cd "$(gc "https://github.com/aaronjohnsabu1999/bible-databases/")"
)

go install github.com/mithrandie/csvq@latest

(
cd ~/repos/
git clone git://repo.or.cz/cwc.git
cd cwc
make -j$(nproc)
)

(
cd ~/repos/
git clone --recursive "https://github.com/chr15m/flk"
cd flk
make
newscript="$(mkw -f flk)"
)

e ia rubik

env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest

# Indent line wrap
e ia adaptive-wrap

# Rust file manager - pretty cool
cargo install --git https://github.com/sxyazi/yazi.git
# sadly, doesn't exist:
# cargo-quickinstall yazi

# I really don't want numpy actually
# pip install numpy

# This solves some problems:
git config --global --add safe.directory '*'
# Such as:
#  fatal: detected dubious ownership in repository at '/volumes/home/shane/var/smulliga/source/git/emacs-mirror/emacs'
# To add an exception for this directory, call:
# 
#         git config --global --add safe.directory /volumes/home/shane/var/smulliga/source/git/emacs-mirror/emacs

# emacs29
e ia treesit-auto

e ia gumshoe

# I should collect TUI tools because they could be useful
# for drawing ideas from to create widgets myself.
go install github.com/maaslalani/typer@latest

(
gc "https://github.com/gabe565/ascii-movie"

go install github.com/gabe565/ascii-movie@latest
)

# wordle
go install github.com/ajeetdsouza/clidle@latest

# For json
go install github.com/antonmedv/fx@latest
# https://manpages.debian.org/bookworm/gron/gron.1.en.html#BASIC_USAGE
agi gron

(
cd "$(gc "https://github.com/erikgeiser/promptkit")"
)

agi telnet zathura

pip install synonym-cli

pip install pipx
pipx install harlequin
pip3.10 install seagoat

# One day this might be great
# cargo install ruscii --examples

# For paper soccer - i need more updated versions
# agi libprotoc-dev libprotoc17
# agi libprotobuf17 libprotobuf-dev
# agi libprotobuf-c-dev libprotobuf-c1

# Greek and Hebrew Bibles
(
cd "$(gc "https://github.com/eliranwong/OpenHebrewBible")"
cd "$(gc "https://github.com/eliranwong/OpenGNT/")"
)

agi iftop nethogs

e ia mw-thesaurus

e ia maces-game typing-game

# eat sounds very cool
e ia iterators math-symbol-lists org-contacts org-transclusion osm parser-generator paced relint shelisp "shell-command+" eat

e ia lsp-origami lsp-dart lsp-pyright

pip3.8 install python-lsp-server

agi pv

e ia vimrc-mode

e ia keypression
e ia keypress-multi-event

# R
e ia tree-sitter-ess-r express ess-view-data ess-view ess-smart-underscore ess-smart-equals ess-r-insert-obj ess-R-data-view ess
agi r-base

# R language server
apt-get install git ssh curl bzip2 libffi-dev -y

sudo rm -rf /usr/local/lib/R
(
cd ~/dump/programs
wget "https://cran.r-project.org/src/base/R-4/R-4.3.1.tar.gz"
tar xf R-4.3.1.tar.gz 
cd R-4.3.1/
agi libpcre2-32-0 libpcre2-dev
./configure 
make -j 10
make install
)

# This debian version of R is not new enough
(
cd "$(gc "https://github.com/REditorSupport/languageserver")"
Rscript -e "install.packages(c('remotes', 'rcmdcheck'), repos = 'https://cloud.r-project.org')"
Rscript -e "remotes::install_deps(dependencies = TRUE)"
r-install-package languageserver
r-install-package lubridate
)

(
cd ~/dump/programs
wget "https://download1.rstudio.org/electron/focal/amd64/rstudio-2023.09.0-463-amd64.deb"
agi libclang-dev
# sudo apt --fix-broken install
sudo dpkg -i "rstudio-2023.09.0-463-amd64.deb"
)

e ia smalltalk-mode

# Failed to compile last time I tried
# {
# agi libfixposix3 libfixposix-dev
# cd "$(gc https://github.com/atlas-engineer/nyxt)"
# git-pull-submodules
# make all
# }

pip install lyricy

(
cd "$(gc "https://github.com/flonatel/pipexec")"
autoreconf -i 
./configure
make -j 10
make install
)

(
# cd "$(gc "http://github.com/theprophetictimeline/Bible-Gematria-Interlinear-Explorer")"
cd /volumes/home/shane/var/smulliga/source/git/theprophetictimeline/Bible-Gematria-Interlinear-Explorer
cp -a Complete.db ~/.pen/gematria-interlinear.db
)

e ia helm-dogears dogears
