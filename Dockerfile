FROM debian:buster

COPY scripts/setup.sh /root
COPY scripts/run.sh /root

WORKDIR /root

RUN apt-get update && ./setup.sh && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD ["./run.sh"]