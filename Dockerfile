FROM debian:buster

COPY scripts/setup.sh /root
COPY scripts/run.sh /root

WORKDIR /root

RUN apt-get update && ./setup.sh

CMD ["./run.sh"]