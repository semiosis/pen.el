FROM debian:jessie

COPY scripts/setup.sh /root

RUN apt-get update

WORKDIR /root

RUN ./setup.sh

# RUN apt-get install -y git build-essential libncurses5-dev libslang2-dev gettext zlib1g-dev libselinux1-dev debhelper lsb-release pkg-config po-debconf autoconf automake autopoint libtool iptables dnsutils

# RUN cd / && git clone git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git util-linux
# RUN /util-linux/autogen.sh
# RUN /util-linux/configure --without-python --disable-all-programs --enable-nsenter
# RUN make

# RUN cp nsenter /usr/bin/
# ADD start.sh ./

# CMD ["./start.sh"] 

