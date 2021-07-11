FROM debian:buster

COPY scripts/setup.sh /root
COPY scripts/run.sh /root

RUN apt-get update

WORKDIR /root

RUN ./setup.sh

CMD ["./run.sh"]