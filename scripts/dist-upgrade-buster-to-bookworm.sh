# Debian 10
apt-get -y update
apt-get -y upgrade --without-new-pkgs
apt-get -y full-upgrade

cat > /etc/apt/sources.list <<"EOF"
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main
deb http://security.debian.org/bullseye-security bullseye-security/updates main
deb-src http://security.debian.org/bullseye-security bullseye-security/updates main
deb http://deb.debian.org/debian/ bullseye-updates main
deb-src http://deb.debian.org/debian/ bullseye-updates main
EOF

# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 605C66F00D6C9793 6ED0E7B82643E131 0E98404D386FA1D9

apt-get clean
apt-get -y update

apt-get -y upgrade --without-new-pkgs
apt-get -y full-upgrade

shutdown -r now

# Debian 11

cat > /etc/apt/sources.list <<"EOF"
deb http://deb.debian.org/debian/ bookworm main
deb-src http://deb.debian.org/debian/ bookworm main
deb http://security.debian.org/bookworm-security bookworm-security/updates main
deb-src http://security.debian.org/bookworm-security bookworm-security/updates main
deb http://deb.debian.org/debian/ bookworm-updates main
deb-src http://deb.debian.org/debian/ bookworm-updates main
EOF

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BDE6D2B9216EC7A8

apt-get clean
apt-get -y update

apt-get -y upgrade --without-new-pkgs
apt-get -y full-upgrade

# issue with libcrypt.so.1
cd /tmp
apt -y download libcrypt1
# dpkg-deb -x libcrypt1_1*a4.4.25-2_amd64.deb .
dpkg-deb -x libcrypt1_1%3a4.4.33-2_amd64.deb .
cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
apt -y --fix-broken install

apt-get -y upgrade --without-new-pkgs
apt-get -y full-upgrade

apt-get -y auto-remove
shutdown -r now