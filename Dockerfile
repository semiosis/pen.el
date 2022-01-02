FROM debian:buster

# butterfly
# EXPOSE 5757 

# ttyd
EXPOSE 7681

WORKDIR /root

# These are used initially but replaced by symlinks later
COPY scripts/setup.sh /root
COPY scripts/run.sh /root

RUN apt-get update && ./setup.sh && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD ["/root/run.sh"]