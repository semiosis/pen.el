# A warning to any user compiling this container manually.
# This may take 6 hours, and performs compilation, so will chew through CPU.
# The pen script handles pulling the finished container automatically.
# Please consider just using the built container.

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