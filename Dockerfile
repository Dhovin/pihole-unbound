FROM lsiobase/ubuntu:focal
LABEL maintainer="@dhovin"

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -yq && \
	wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/script.sh -O script.sh && \
	chmod +x script.sh  && \
	./script.sh
	# Cleanup
RUN apt-get clean -y && \
    apt-get autoremove -y && \
    rm -rfv /tmp/* /var/lib/apt/lists/* /var/tmp/* 


COPY root/ /
EXPOSE 80 53
VOLUME /config
