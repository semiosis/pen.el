FROM silex/emacs:26.3-alpine

# I don't want to install docker in this container. I want the emacs container to ssh into the
# host and use the host's docker.
# FROM yobasystems/alpine-docker
# FROM danielguerra/alpine-docker # This one is faster
# But how do you control the host docker from container
# docker run -ti --privileged danielguerra/alpine-docker /bin/sh

RUN apk update

COPY emacs-pkg-install.sh /emacs-pkg-install.sh
COPY docker.el /root/.emacs.d/docker.el

RUN /emacs-pkg-install.sh docker
