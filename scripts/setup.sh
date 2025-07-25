#!/bin/bash

ln -sf ~/.pen/downloads ~/downloads

mkdir -p ~/source/gist

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

export PENELD="$EMACSD/pen.el"

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
tic $HOME/repos/pen.el/config/screen-2color-rev.ti
tic $HOME/repos/pen.el/config/vt100rev.ti
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

ln -sf ~/.pen/git/config ~/.gitconfig
ln -sf ~/.pen/git/credentials ~/.git-credentials

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
make -j $(nproc) || :
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
    cd ~/repos
    git clone --branch emacs-29 --depth 1 "https://github.com/emacs-mirror/emacs"
    cd emacs

    # Has object-intervals
    # emacs 28
    # git checkout df882c9701
    # ./autogen.sh
    # ./configure --with-all --with-x-toolkit=yes --without-makeinfo --with-modules --with-gnutls=yes

    # emacs 29
    # git checkout ec4d29c4494f32acf0ff7c5632a1d951d957f084

    # git clone --branch emacs-29 --depth 1 "https://github.com/emacs-mirror/emacs"
    # --with-native-compilation takes longer
    # --with-small-ja-dic appears to make it hang
    ./autogen.sh
    # Debian 10
    # sudo apt install libsqlite3-dev libgccjit0 libgccjit-8-dev
    # Debian 12
    sudo apt install libsqlite3-dev libgccjit0 libgccjit-12-dev libfribidi0 libfribidi-dev

    # On Debian 12 I had to install this deb manually
    (
        cd /tmp
        wget "http://ftp.us.debian.org/debian/pool/main/f/fribidi/libfribidi-dev_1.0.8-2.1_amd64.deb"
        dpkg -i libfribidi-dev_1.0.8-2.1_amd64.deb
    )

    ./autogen.sh

    #./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes \
    #    --with-native-compilation --with-tree-sitter --with-small-ja-dic \
    #    --with-gif --with-png --with-jpeg --with-rsvg --with-tiff \
    #    --with-imagemagick

    # emacs-29
    ./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes --with-tree-sitter --with-small-ja-dic --with-gif --with-png --with-jpeg --with-rsvg --with-tiff --with-imagemagick

    # emacs-28
    # ./configure --with-all --with-x-toolkit=yes --with-modules --with-gnutls=yes --with-gif --with-png --with-jpeg --with-rsvg --with-tiff --with-imagemagick
    # make
    # Remove scripts from the path (because emacs will hang when it looks for
    # and finds cvs, and tries to run it.)

    export PATH="$(echo "$PATH" | sed 's/:/\n/g' | grep -v pen.el | sed '/^$/d' | s join :)"

    # Patch emacs to add a hook for when hscroll is changed
    ( cd src; git apply $PENELD/config/emacs/hscroll-01.01.25.patch; )

    make -j$(nproc)
    make install
)
# rm -rf /root/emacs

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

(
cd
git clone "https://gitlab.com/rosie-pattern-language/rosie"
cd rosie
make
make installforce
)

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
make -j $(nproc) && make install
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
make -j $(nproc) && make install
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

# Also, install this font:
# /root/.pen/PkgTTC-IosevkaEtoile-28.0.1.zip

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
cd ~
curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
chmod +x linux-install.sh
./linux-install.sh
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
` # vim 8.2.3908: git checkout 27708e6c `
make clean
make distclean
./configure --with-features=huge --enable-cscope --enable-multibyte --with-x --enable-perlinterp=yes --enable-pythoninterp=yes --enable-python3interp
make -j $(nproc)
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
make -j $(nproc)
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
raco pkg install symalg
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

# test -d $REPOS/glow || (
#     cd "$REPOS"
#     git clone "https://github.com/charmbracelet/glow"
#     cd glow
#     go build
# )
go install github.com/charmbracelet/glow@latest

test -d $REPOS/go-ethereum || (
    cd "$REPOS"
    git clone "https://github.com/ethereum/go-ethereum"
    cd go-ethereum
    make all
    go run build/ci.go install ./cmd/geth
)

# If I want to do anything seriously with haskell then I should start with ghcup as it knows about the complications of stack and cabal
# https://www.haskell.org/ghcup/install/
# curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

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
mkdir -p /root/.vim/colors
cp -a /root/repos/pen.el/config/inkpot.vim /root/.vim/colors
cp -a /root/repos/pen.el/config/paste-replace.vim /root/.vim
cp -a /root/repos/pen.el/config/utils.vim /root/.vim
cp -a /root/repos/pen.el/config/pen.vim /root/.vim
cp -a /root/repos/pen.el/config/nvim-function-keysvimrc /root/.vim
cp -a /root/repos/pen.el/config/fixkeymaps-vimrc /root/.vim

test -d ~/.config && : ${XDG_CONFIG_HOME:=~/.config}
export XDG_CONFIG_HOME="$XDG_CONFIG_HOME"

mkdir -p "$XDG_CONFIG_HOME/tig"
cp -a /root/.emacs.d/host/pen.el/config/tigrc "$XDG_CONFIG_HOME/tig/config"
cp -a /root/.emacs.d/host/pen.el/config/molokai-like-theme.tigrc "$XDG_CONFIG_HOME/tig/theme.tigrc"

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
# make -j $(nproc), also runs tests, annoyingly
(
agi build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
mcd $DUMP/programs
curl -O https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
tar Jxf Python-3.10.0.tar.xz
cd Python-3.10.0
./configure --enable-optimizations
make -j $(nproc)
make altinstall
)

# TODO Learn to install these in a venv
# https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/

# It seems as though my laptop screen is dying.

pip3.10 install --force-reinstall ipython

mkdir -p ~/.pen/virtualenvs

# Instead of doing it like this, allow the scripts to install themself
# pip3.10 install bpython
# pip3.10 install baca

bpython -install-only
baca -install-only
hexabyte -install-only
# paint for the terminal
textual-paint -install-only

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
cd "$(gc "https://github.com/tmux/tmux")"
make clean
make distclean
./autogen.sh
./configure --enable-sixel --prefix=$HOME/.local
make -j $(nproc)
make install
)

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
# https://stackoverflow.com/questions/6839204/how-to-turn-on-regexp-in-sqlite3-and-rails-3-1
# https://stackoverflow.com/questions/5071601/how-do-i-use-regex-in-a-sqlite-query
# sqlite3-pcre implements REGEXP for SQLite.
agi sqlite3-pcre

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

# (ql:quickload :swank)
xs quicklisp-install swank

# lem
apt-get update && apt-get install gcc libncurses-dev -y

# Install through git
# (
# ros install qlot
# cd "$HOME/repos"
# git clone --recursive https://github.com/lem-project/lem
# git clone https://github.com/lem-project/micros
# cd lem
# qlot install
# qlot exec sbcl --noinform --no-sysinit --no-userinit --load .qlot/setup.lisp --load scripts/build-ncurses.lisp
# )
# # Run lem
# qlot exec sbcl --eval "(ql:quickload :lem-ncurses)" --eval "(lem:lem)" --quit

# A TUI common-lisp IDE
ros install lem-project/lem
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
# make -j $(nproc), also runs tests, annoyingly
(
agi build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
mcd $DUMP/programs
curl -O https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tar.xz
tar Jxf Python-3.11.4.tar.xz
cd Python-3.11.4
./configure --enable-optimizations
make -j $(nproc)
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
pip install -U mycli
pip install -U pgcli

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
    make -j $(nproc)
    make install
)

# agi r-base r-base-dev

# This Debian 10 version of R is not new enough
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
    make -j $(nproc)
    make install
)

(
    # cd "$(gc "http://github.com/theprophetictimeline/Bible-Gematria-Interlinear-Explorer")"
    cd /volumes/home/shane/var/smulliga/source/git/theprophetictimeline/Bible-Gematria-Interlinear-Explorer
    cp -a Complete.db ~/.pen/gematria-interlinear.db
)

e ia helm-dogears dogears

(
    agi libjpeg-dev
    agi librsvg2-2 librsvg2-bin librsvg2-dev
    agi libtiff5 libtiff-dev
    agi libwebp6 libwebp-dev
    cd "$(gc "https://github.com/hpjansson/chafa")"
    git checkout origin/1.12
    ./autogen.sh
    make -j $(nproc)
    make install
    ldconfig
)

(
    cd "$(gc "https://github.com/marianosimone/epub-thumbnailer")"
    pip3.10 install pillow
    python3.10 install.py install
)

agi zathura zathura-djvu zathura-pdf-poppler

(
    agi ffmpegthumbnailer
    agi libffmpegthumbnailer-dev
    agi libffmpegthumbnailer4v5
    agi imagemagick imagemagick-6.q16 libmagick++-6-headers libmagick++-dev
    agi poppler libpoppler-cil libpoppler-cil-dev libpoppler-dev libpoppler82
    agi wkhtmltopdf
    agi unzip
    agi p7zip-full
    agi unrar-free
    agi catdoc
    agi docx2txt
    agi odt2txt

    agi bat
    # https://github.com/sharkdp/bat
    
    # agi gnumeric
    # agi exiftool
    # agi iso-info
    # agi transmission
    # agi mcomix

    cd "$(gc "https://github.com/horriblename/lfimg-sixel")"
    make install

    echo "set previewer ~/.config/lf/preview" > /root/.config/lf/lfrc
)

agi tesseract-ocr tesseract-ocr-chi-sim
# (
# cd "$(gc "http://github.com/writecrow/ocr2text")"
# pip install --user --requirement requirements.txt
# )

apt install ocrmypdf

# (
# cd "$(gc "https://github.com/ocrmypdf/OCRmyPDF")"
# )

agi info

e ia eat

pip3.11 install poetry

(
` # cd "$(gc "http://github.com/thetacom/hexabyte")"`
cd /volumes/home/shane/var/smulliga/source/git/thetacom/hexabyte
poetry build
poetry install
)

e ia m4-mode

agi info
agi ed

e ia perfect-margin

cargo install du-dust

agi tig

(
cd "$(gc "https://github.com/gohugoio/hugo")";
go install --tags extended;
)

(
cd "$(gc "http://github.com/dzello/reveal-hugo")"
)

(
cd $HOME/programs
wget "https://github.com/muammar/mkchromecast/releases/download/0.3.8.1/mkchromecast_0.3.8.1-1_all.deb"
sudo dpkg -i mkchromecast_0.3.8.1-1_all.deb
sudo apt --fix-broken install
)

(
cd $HOME/programs
wget "https://github.com/GothenburgBitFactory/taskwarrior/releases/download/v2.6.2/task-2.6.2.tar.gz"
tar zxf task-2.6.2.tar.gz
cd $HOME/programs/task-2.6.2
cmake -DCMAKE_BUILD_TYPE=release .
make -j $(nproc)
sudo make install
` # not much need for the code, tbh `
cd "$(gc "https://github.com/kdheepak/taskwarrior-tui")"
cargo install taskwarrior-tui
)

# I don't think it can be built under Pen.el
# I might need the host to build ZealOS
# But perhaps I can *run* ZealOS from Pen.el
# For building and running ZealOS
agi xorriso
agi parted
agi kmod # for modprobe
agi qemu-system-x86

# notmuch-setup

# afew/oldoldstable 1.3.0-1 all
# alot/oldoldstable 0.8.1-1+deb10u1 all
# alot-doc/oldoldstable 0.8.1-1+deb10u1 all
# astroid/oldoldstable 0.14-2.1 amd64
# gmailieer/oldoldstable 0.10-1 all
# libnotmuch-dev/oldoldstable 0.28.4-1 amd64
# libnotmuch5/oldoldstable,now 0.28.4-1 amd64 [installed,automatic]
# muchsync/oldoldstable 5-1 amd64
# notmuch/oldoldstable 0.28.4-1 amd64
# notmuch-addrlookup/oldoldstable 9-2 amd64
# notmuch-doc/bullseye-backports 0.37-1~bpo11+2 all
# notmuch-emacs/oldoldstable 0.28.4-1 all
# notmuch-git/bullseye-backports 0.37-1~bpo11+2 all
# notmuch-mutt/oldoldstable 0.28.4-1 all
# notmuch-vim/oldoldstable 0.28.4-1 all
# python-notmuch/oldoldstable 0.28.4-1 all
# python3-notmuch/oldoldstable,now 0.28.4-1 all [installed]
# python3-notmuch2/bullseye-backports 0.37-1~bpo11+2 amd64
# ruby-notmuch/oldoldstable 0.28.4-1 amd64

e ia org-super-agenda

# Hymns
agi timidity

# https://askubuntu.com/questions/972510/how-to-set-alsa-default-device-to-pulseaudio-sound-server-on-docker

# apt-get install -y --no-install-recommends \
#     alsa-oss \
#     alsa-tools \
#     alsa-utils \
#     libsndfile1 \
#     libsndfile1-dev

# Wrap lines
e ia visual-fill-column

e ia ox-hugo easy-hugo
e ia orthodox-christian-new-calendar-holidays
e ia org-alert

e ia eshell-prompt-extras eshell-git-prompt eshell-z eshell-vterm eshell-up eshell-toggle eshell-syntax-highlighting eshell-prompt-extras eshell-outline eshell-info-banner eshell-git-prompt eshell-fringe-status eshell-fixed-prompt eshell-did-you-mean eshell-bookmark eshell-autojump

e ia universal-sidecar-roam universal-sidecar-elfeed-score universal-sidecar-elfeed-related universal-sidecar org-roam-ql-ql org-roam-ql org-roam org-roam-ui org-roam-timestamps org-roam-ql-ql org-roam-ql org-roam-bibtex org-roam gkroam consult-org-roam

e ia org-sql org-roam-ql-ql org-roam-ql org-ql helm-org-ql
e ia org-parser

e ia prism

e ia org-shoplist org-listcruncher org-autolist

e ia list-environment
e ia load-bash-alias
e ia babashka

# for notdeft and building notmuch
agi xapian-tools xapian-examples libxapian-dev libxapian30

# notdeft
# Set up xiphos toolchain
# None of these seemed to work
agi dbus libdbus-1-3 libdbus-1-dev libdbus-c++-bin libdbus-c++-dev libdbus2.0-cil libdbus2.0-cil-dev
# This got dbus going
agi dbus-x11
# This is required for xiphos build
agi libdbus-glib-1-dev-bin itstool desktop-file-utils appstream-util yelp-tools uuid-runtime
agi libbiblesync-dev libbiblesync1.1
agi fp-utils # for chmcmd

# Docs say
agi intltool libdbus-glib-1-dev libwebkitgtk-3.0-dev libxml2-dev libgsf-1-dev libgconfmm-2.6-dev libsword-dev uuid-dev libwebkitgtk-dev libglade2-dev

# Trying this
agi intltool libdbus-glib-1-dev libwebkit2gtk-4.0-dev libxml2-dev libgsf-1-dev libgconfmm-2.6-dev libsword-dev uuid-dev libwebkitgtk-dev libglade2-dev

# 
(
cd "$(gc "https://github.com/crosswire/xiphos")"
)

agi command-not-found
update-command-not-found

e ia calfw calfw-org calfw-ical calfw-howm calfw-gcal calfw-cal

e ia yatemplate templatel template-overlays ptemplate-templates ptemplate license-snippets

# Actually, I don't know about this.
# It uses an api.
# e ia helm-gitignore license-templates gitignore-templates

e ia yasnippet-snippets

e ia org-appear

# email TUI that works with notmuch
cargo install meli
# another one that looks interesting:
# https://github.com/soywod/himalaya
# another one that looks interesting:
# https://github.com/purebred-mua/purebred

meli create-config
mv ~/.config/meli ~/.pen
ln -sf ~/.pen/meli ~/.config
# meli edit-config
meli install-man /root/.local/share

cargo install himalaya

# Set up sendmail
# https://www.tutorialspoint.com/configure-sendmail-with-gmail-on-ubuntu
(
mkdir -p /etc/mail/
ln -sf /root/.pen/sendmail.mc /etc/mail/sendmail.mc
)

# Finances in emacs
e ia ledger-mode ledger-import hledger-mode flymake-hledger flycheck-ledger flycheck-hledger company-ledger

e ia org-ref-prettify org-ref

e ia crontab-mode

# e ia sc

e ia addressbook-bookmark

agi libasound2-dev
cargo install termusic termusic-server

# APL
agi gnuplot
e ia gnu-apl-mode
apt install libtinfo5
apt install libtinfo6
(
cd "$HOME/programs"
wget "https://ftp.gnu.org/gnu/apl/apl_1.8-1_amd64.deb"
)

agi sc
(
cd "$(gc "https://github.com/andmarti1424/sc-im")"
make -C src
make -C src install
)

# elfeed
e ia elfeed elfeed-webkit elfeed-web elfeed-tube-mpv elfeed-tube elfeed-summary elfeed-protocol elfeed-org elfeed-goodies elfeed-dashboard elfeed-curate elfeed-score elfeed-autotag universal-sidecar-elfeed-score universal-sidecar-elfeed-related el-secretario-elfeed

e ia ace-popup-menu

e ia transducers

e ia wiki-nav wikinfo wikinforg tracwiki-mode plain-org-wiki org-multi-wiki ox-mediawiki mediawiki helm-wikipedia helm-org-multi-wiki

e ia docker docker-tramp docker-compose-mode docker-cli docker-api dockerfile-mode dockerfile-ts-mode

# TODO Build buffer-agnostic persistent annotanion
# Annotation commands
e ia annotate
e ia annotation

(
cd "$(git clone "https://github.com/jkitchin/ov-highlight/")"
sed -i "s/<return>/RET/g" /root/repos/ov-highlight/ov-highlight.el
)

e ia minions

agi xdotool

# For visidata
# cd "$PENCONF/documents/notes"; fpvd Music\ Data\ Base.xls
pip3 install xlrd openpyxl

e ia define-it
e ia helm-wordnet

e ia font-lock-studio

# Install printing software
apt install cups-bsd
apt install lpr
apt install lprng

e ia org-journal org-journal-tags org-journal-list

e ia gitlab ivy-gitlab helm-gitlab gitlab-snip-helm gitlab-pipeline gitlab-ci-mode-flycheck gitlab-ci-mode

# e ia ebdb company-ebdb
(
cd /root/repos
git clone "https://github.com/girzel/ebdb"
git clone "https://github.com/emacsmirror/company-ebdb"
)

e ia keycast

agi plsense

agi font-manager

# OpenJDK
# https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_linux-x64_bin.tar.gz
(
cd /root/programs
wget "https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_linux-x64_bin.tar.gz"
tar zxf "openjdk-21.0.1_linux-x64_bin.tar.gz"
)

# A P2P filesystem
e ia hyperdrive

e ia denote-refs denote-menu denote

e ia docker slime-docker mermaid-docker-mode lsp-docker docker-tramp docker-compose-mode docker-cli docker-api dockerfile-mode dockerfile-ts-mode

timedatectl set-timezone "Pacific/Auckland"
# Test:
# ls -l /etc/localtime

e ia nano-agenda

raco pkg update racket-langserver

# Sendmail
agi sendmail sma

e ia helm-eww markdown-preview-eww

agi fp-compiler fp-ide fp-docs fp-units-base fp-units-db
# dpkg -S /usr/bin/x86_64-linux-gnu-fpcmkcfg-3.0.4
/usr/bin/x86_64-linux-gnu-fpcmkcfg-3.0.4

# emacs lsp booster (for performance)
# https://www.reddit.com/r/emacs/comments/18ybxsa/emacs_lspmode_performance_booster/?%24deep_link=true&correlation_id=866ffc1d-a52d-4ad9-8551-1c03ff8b282a&post_fullname=t3_18ybxsa&post_index=1&ref=email_digest&ref_campaign=email_digest&ref_source=email&%243p=e_as&_branch_match_id=1080262788655345442&_branch_referrer=H4sIAAAAAAAAA22QXWrDMBCET%2BO%2B2a4l27iFEAql11hkaZWI6g9pjdPbd900fSpIaPiGnR10Jcr1te8LGuOoUzl33sXPXuZzI0aZTwiqPrFMxV1cVB624k%2FXY6qRb4344LPve%2Fc7r1NgUPhiULryyyRgpEMOy9d6q%2Bphgq85JIOQsdhUgooaYU2pEh4BjeTs0SBmOBo18p3Kho2YdSoFvSKXIjjDfJlna%2FVgWjUJ047KvLTLNA3toJ%2BltcsqFsFL58zJYDfvowp4xEn4a3Q3XTR4Y2dgUNCy4qLOg3EXrHSHoFXIyl3i%2F25NW9H48BhuFECnSPwHTH%2FWkCOP382XFY15AQAA
# /root/.emacs.d/host/pen.el/src/pen-lsp-booster.el
(
cd "$(gc "https://github.com/blahgeek/emacs-lsp-booster")"
cargo install --force --path .
)

e ia olivetti

e ia modus-themes org-modern

agi graphviz

(
cd /root/programs
wget "https://github.com/RangerMauve/hyper-gateway/releases/download/v3.6.0/hyper-gateway-linux"
chmod a+x hyper-gateway-linux
cd /usr/bin
ln -s /root/programs/hyper-gateway-linux hyper-gateway
)

cargo install gitui

e ia path-headerline-mode
e ia org-gtd

agi ledger
agi hledger

v $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
sed -i "/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE/s/fg=8'/fg=8,underline'/" /root/repos/oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

e ia iterator iterators iter2 path-iterator

# This isn't a very useful implementation of an enum
(
cd /root/repos
git clone "https://gitlab.com/emacsos/enum.el"
)

# For arecord: arecord --format=cd file.wav
agi alsa-utils
agi normalize-audio

# This is for showing information on the side
e ia sideline sideline-lsp sideline-flymake sideline-flycheck sideline-blame

# I need transient-20231204 for magit
# But instead I can just load the new one then reload the builtin one

e ia ctable

e ia chezscheme

install-babashka

# This lags a bit
e ia focus

e ia hyperbole

# This is awesome and works quite well
(
cd /root/repos
cd "$(gc "https://github.com/cmang/durdraw")"
bash ./installconf.sh 
)

# Make asciinema into gif
# cargo install --git https://github.com/asciinema/agg
(
cd /root/repos
cd "$(gc "https://github.com/asciinema/agg")"
cargo build --release
cargo install --path .
)
# Then make the wrapper
# mkw -f target/release/agg


# Hmm. If I use this, I would make the models in Blender
# And then display them with Term_GL.
(
cd "$(gc "https://github.com/wojciech-graj/TermGL")"
)

(
cd ~/repos
git clone "https://github.com/TheZoraiz/ascii-image-converter"
)

go install "github.com/TheZoraiz/ascii-image-converter@latest"

# An improvement to 'ed'
(
cd ~/repos
git clone "https://github.com/sidju/hired"
cd hired
cargo build
)

agi pdf2svg

agi sshpass

# This is awesome but I need to get it working.
# Haskell-Emacs interop
# https://github.com/knupfer/haskell-emacs
e ia haskell-emacs haskell-emacs-text haskell-emacs-base

(
mkdir -p ~/.pen/downloads
cd /root
ln -sf ~/.pen/downloads
)

# for j:org-sync-snippets--iterate-org-src
e ia org-sync org-sync-snippets

# Cargo install zellij - it's really slow to compile though
# I'm not a very big fan of zellij
# cargo install --locked zellij

(
cd /root/programs
wget "https://github.com/zellij-org/zellij/releases/download/v0.39.2/zellij-aarch64-unknown-linux-musl.tar.gz"
tar xzf "zellij-aarch64-unknown-linux-musl.tar.gz"
chmod a+x "zellij"
cd /usr/bin
ln -s /root/programs/zellij zellij
)

e ia org-noter org-mind-map org-ivy-search org-superstar org-drill org-auto-tangle org-contacts org-zettelkasten

e ia org-treeusage org-transform-tree-table org-timeline org-tidy org-tag-beautify org-static-blog org-recur org-radiobutton org-projectile

e ia itail

# Run chromium inside of a terminal
(
cd ~/repos
git clone "https://github.com/fathyb/carbonyl"
cd carbonyl
cargo build
)
# npm install --global carbonyl
# wget "https://github.com/fathyb/carbonyl/releases/download/v0.0.3/carbonyl.linux-amd64.zip"

# Instead, run this on the host OS
# docker run -ti fathyb/carbonyl https://youtube.com

# I had lots of problems running carbonyl in Pen.el

# Or use browsh
# wget "https://github.com/browsh-org/browsh/releases/download/v1.8.3/browsh-1.8.3.xpi"
# cd "$MYGIT/browsh-org/browsh"; npm install -g webpack webpack-cli web-ext

mkdir -p ~/.pen/elpa-light
mkdir -p ~/.pen/elpa-full

agi unison
# Couldn't easily compile the latest version
# agi ocaml-nox
# (
# cd ~/repos
# git clone "https://github.com/bcpierce00/unison"
# cd unison
# make
# )

agi rename

agi fontforge

e ia doct

# Espanso seemed cool but I didn't find a tty version
# # For espanso:
# cargo install rust-script --version "0.7.0"
# cargo install --force cargo-make --version 0.37.5
# (
# cd ~/repos
# git clone "http://github.com/espanso/espanso"
# cd espanso
# cargo make --profile release -- build-binary
# )

# https://github.com/sassman/t-rec-rs
# Noone is going to be saved by deeds of the law
agi imagemagick
cargo install -f t-rec --locked 

agi ncurses-term

# Ah, forget it, it needs a newer ruby
# gem install ruby-lsp

gem install youplot

e ia inheritenv

(
cd ~/repos
git clone "https://github.com/Wilfred/difftastic"
cd difftastic
)

# https://invisible-island.net/xterm/xterm.html#download

agi mtools

(
cd ~/repos
git clone "https://github.com/mattn/go-sixel"
cd go-sixel
)

go install github.com/mattn/go-sixel@latest

e ia activities

e ia listen

e ia org-index

# For editing markdown code blocks
e ia edit-indirect

# e:deunicode
plf install Text::Unidecode

(
cd ~/repos
git clone "https://github.com/velorek1/terminalperiodictable"
cd terminalperiodictable
make
)

agi rs
agi datamash

# Latex language server
# https://github.com/latex-lsp/texlab/releases
# https://github.com/latex-lsp/texlab/releases/download/v5.15.0/texlab-x86_64-linux.tar.gz

# (
# cd "$HOME/programs"
# wget "https://github.com/latex-lsp/texlab/releases/download/v5.15.0/texlab-x86_64-linux.tar.gz"
# tar zxf texlab-x86_64-linux.tar.gz
# mkw -f texlab
# )
# I need to compile it myself
# because of the glibc version
# https://github.com/latex-lsp/texlab?tab=readme-ov-file

update-rust
(
cd ~/repos
git clone "https://github.com/latex-lsp/texlab"
cd texlab
cargo build --release
chown a+x target/release/texlab
)

agi texlive-fonts-extra
agi texstudio

agi rename

e ia shrink-path

pip3.8 install AoE2ScenarioParser

e ia discover discover-my-major

e ia tzc

# https://www.muppetlabs.com/~breadbox/software/chd.html
# /root/.local/bin
(
cd /root
wget "http://www.muppetlabs.com/~breadbox/pub/software/chd-1.1.tar.gz"
tar zxf chd-1.1.tar.gz
cd chd-1.1 
make
cp -a chd ~/.local/bin
rm -rf /root/chd-1.1
rm ~/chd-1.1.tar.gz 
)

# sol: A de-minifier (formatter, exploder, beautifier) for shell one-liners.
go install -v github.com/noperator/sol/cmd/sol@latest


I had to upgrade Debian in Pen.el from 10 to 12.
# Unison
# export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/glibc/lib"

# Also, Unison is built on Haskell and to compile it myself requires stack
# Therefore, maybe I need to upgrade my debian distribution.
(
cd ~
mkdir -p unisonlanguage && cd unisonlanguage
curl -L https://github.com/unisonweb/unison/releases/latest/download/ucm-linux.tar.gz \
	| tar -xz
./ucm
)

# Since last docker commit:

agi okular

e ia cursor-flash
e ia buffer-move

agi dict

# Dictionary and definitions
sudo apt install dictd dict-gcide

# Simon's emacs plugin
e ia org-wc

update-rust
cargo install --locked ttysvr

# The emacs version was working perfectly fine.
# But whatever.
# Install clojure-lsp
sudo bash < <(curl -s https://raw.githubusercontent.com/clojure-lsp/clojure-lsp/master/install)

# Emacs-Clojure interop. Write emacs packages in Clojure
# Also added this:
# /root/.emacs.d/host/pen.el/src/pen-cloel.el
(
cd "$(gc "https://github.com/manateelazycat/cloel")"
clojure -X:jar
clojure -X:install
)

e ia peertube

(
cd /root/.sword
wget "https://www.crosswire.org/ftpmirror/pub/sword/packages/rawzip/LXX.zip"
unzip LXX.zip
)


(
cd ~/repos
git clone "https://github.com/babashka/bbin"
)

agi ddgr

(
cd ~/.emacs.d/manual-packages
git clone "https://github.com/clojure-emacs/clj-refactor.el"
)

agi xpra xserver-xephyr

# Hiragana to Romanji converter
pip install cutlet
pip install unidic-lite

agi autossh

ghcup install cabal 3.10.3.0
# cabal install haskellscript

ghcup install stack 2.15.7
stack install turtle

cabal install implicit-hie-cradle

e ia cmake-mode cmake-font-lock eldoc-cmake cpputils-cmake cmake-project cmake-ide

go install -v github.com/rogpeppe/godef@master

# mdBook is a command line tool to create books with Markdown
cargo install mdbook

cargo install rust-script

# Go REPL
go install github.com/x-motemen/gore/cmd/gore@latest
go install github.com/mdempsky/gocode@latest

pip3 install ansi2html

agi tidy

# I want ImageMagick 7 so I have the magick command
# which can nicely compose functions.
(
    cd "$DUMP/programs"

    wget "https://imagemagick.org/archive/ImageMagick.tar.gz"
    tar xvzf ImageMagick.tar.gz
    dn="$(glob "ImageMagick-*" | head -n 1)"
    cd "$dn"
    ./configure
    make -j $(nproc)
    sudo make install 
    sudo -E ldconfig /usr/local/lib

    # Verify by checking the version:
    magick -version
)

agi gimp

e ia geiser-chez

(
cd ~/repos
git clone "https://git.savannah.gnu.org/git/bash.git"
cd bash
./configure
make -j $(nproc)
make install
)

e ia listen mustache

cargo install --locked --git https://github.com/sxyazi/yazi.git yazi-fm yazi-cli

agi mc

e ia org-transclusion hyperdrive-org-transclusion org-transclusion-http

agi nim
e ia nim-mode

agi gnugo
e ia gnugo chess

# For visidata
pip install psutil

go install github.com/ericfreese/rat@latest

e ia xcscope helm-cscope

cargo install datafusion-tui

e ia xcscope helm-cscope

# https://superuser.com/q/619765
(
cd ~/repos
git clone "https://github.com/neovim/neovim"
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
make install
)

(
agi autoconf build-essential pkgconf libncurses-dev
cd "$(gc "https://github.com/blippy/neoleo")"
autoreconf -iv
env LIBS=-lstdc++fs ./configure
sed -i "s/ -std=c++20 / -std=c++2a /" src/Makefile
make -j $(nproc)
)

# Another speadsheet program
(
cargo install --git https://github.com/zaphar/sheetsui
)

# Hmm... I failed to build it. Try prebuilt binaries
# Sadly setting up lsp for Debian10 turns out to be nontrivial
# To explore this:
# /volumes/home/shane/var/smulliga/source/git/msokalski/ascii-patrol/menu.cpp
# I need:j:ccls-executable to work
# (
# cd ~/repos
# test -d ccls || git clone --depth=1 --recursive https://github.com/MaskRay/ccls
# cd ccls
# cmake -S. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/path/to/clang+llvm-xxx
# agi llvm-7 llvm-7-dev
# )

(
cd "$(gc "https://github.com/charmbracelet/gum")"
)

(
cd "$(gc "https://github.com/autotrace/autotrace")"
apt install -y libgraphicsmagick1-dev libpng-dev libexiv2-dev libtiff-dev libjpeg-dev libxml2-dev libbz2-dev libfreetype6-dev libpstoedit-dev autoconf automake libtool intltool autopoint
./autogen.sh
./configure --enable-magick-readers
make -j$(nproc)
make install
)

(
cd ~/repos
mkdir xterm
cd xterm
wget "https://invisible-island.net/datafiles/release/xterm.tar.gz"
tar -xf xterm.tar.gz
cd "$(glob "xterm-*")"
` # I want to enable trace as I can hack on the xterm source`
./configure --enable-trace
make -j$(nproc)
make install
)

# https://braillespecs.github.io/pef/pef-specification.html
agi brailleutils

go install github.com/LeperGnome/bt/cmd/bt@v1.0.0

cargo install binsider

# TTS voice synthesis (xiphos uses it)
agi festival

# Clipboard synchronization over ssh
cargo install clipcast

apt install -y openssh-server
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin /PermitRootLogin /' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 9222/' /etc/ssh/sshd_config
# Set login password for the docker container:
# echo "root:insecure_password" | chpasswd
# service ssh start

e ia helm-rhythmbox

e ia php-mode

pip3.10 install youtube-transcript-api
