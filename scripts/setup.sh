#!/bin/bash

# Debian10 installation

export SSH_HOST_ALLOWED=n

export DUMP=/root/dump
export EMACSD=$HOME/.emacs.d
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

tic $HOME/repos/pen-emacsd/pen.el/config/eterm-256color.ti
tic $HOME/repos/pen-emacsd/pen.el/config/screen-256color.ti
tic $HOME/repos/pen-emacsd/pen.el/config/screen-2color.ti

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

go get "golang.org/x/tools/gopls@latest"

(
cp -a "$EMACSD/pen.el/config/nvimrc" ~/.vimrc
)

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
cp -a ~/repos/pen-emacsd/pen.el/config/irc-config.conf /inspircd-2.0.25/run/conf/inspircd.conf
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
)
pen-build-charm

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
cp -a ~/repos/pen-emacsd/pen.el/config/irc-config.conf /inspircd-2.0.25/run/conf/inspircd.conf
)

# Sadly, the hosts file may change, so this is not good enough
# I need to ensure that irc.localhost is in there when starting MTP
# This does make the container host-specific though. But it doesn't appear to cause problems
# Testing on the VPS worked fine.
# I think the host should be added when starting pen, in run.sh
(
touch /etc/hosts
echo "127.0.1.1	pen-$(hostname)" >> /etc/hosts
cat ~/repos/pen-emacsd/pen.el/config/hosts >> /etc/hosts
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
# sh <(curl -L https://nixos.org/nix/install) --no-daemon
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
cp -a /root/repos/pen-emacsd/pen.el/config/inkpot.vim /root/.vim
cp -a /root/repos/pen-emacsd/pen.el/config/paste-replace.vim /root/.vim
cp -a /root/repos/pen-emacsd/pen.el/config/utils.vim /root/.vim
cp -a /root/repos/pen-emacsd/pen.el/config/pen.vim /root/.vim
cp -a /root/repos/pen-emacsd/pen.el/config/nvim-function-keysvimrc /root/.vim
cp -a /root/repos/pen-emacsd/pen.el/config/fixkeymaps-vimrc /root/.vim

# Ansible
agi libonig-dev
pip3 install 'ansible-navigator[ansible-core]'

# Xterm, etc.
cp -a /root/repos/pen-emacsd/pen.el/config/Xresources /root/.Xresources

# vim
(
cd ~/.vim
git clone "https://github.com/tpope/vim-pathogen"
ln -sf ~/.vim/vim-pathogen/autoload/pathogen.vim ~/.vim/autoload
mkdir -p ~/.vim/bundle
cp -a /root/repos/pen-emacsd/pen.el/config/vim-bundles/* /root/.vim/bundle
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

# Currently not working. Apparantly, it's normal for the latest version to not work
# Install the rust language server (rust-analyzer) manually (rather than through emacs)
rustup toolchain install nightly --component rust-analyzer-preview
(
cd ~/repos/
git clone "https://github.com/rust-analyzer/rust-analyzer"
cargo xtask install --server
)

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
