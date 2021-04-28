FROM debian:stable-slim as gvm-base
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

ENV gvm_libs_version="20.8.1"

RUN useradd --system gvm

# Update software and import Greenbone GPG key
RUN apt-get update && apt-get upgrade --assume-yes && \
        apt-get install --assume-yes \
        curl \
        gnupg && \
        curl https://www.greenbone.net/GBCommunitySigningKey.asc | gpg --import -
        
# Build gvm-libs
RUN apt-get install --assume-yes \
        wget \
        cmake \
        pkg-config \
        libglib2.0-dev \
        libgpgme-dev \
        libgnutls28-dev \
        uuid-dev \
        libssh-gcrypt-dev \
        libldap2-dev \
        libhiredis-dev \
        libxml2-dev \
        libradcli-dev \
        libpcap-dev

RUN mkdir --verbose --parents /root/sources/gvm-libs-"$gvm_libs_version"/build /root/downloads && \
        wget --output-document /root/downloads/gvm-libs.tar.gz https://github.com/greenbone/gvm-libs/archive/v"$gvm_libs_version".tar.gz && \
        wget --output-document /root/downloads/gvm-libs.tar.gz.sig https://github.com/greenbone/gvm-libs/releases/download/v"$gvm_libs_version"/gvm-libs-"$gvm_libs_version".tar.gz.sig && \
        if ! gpg --verify /root/downloads/gvm-libs.tar.gz.sig; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gvm-libs.tar.gz --directory /root/sources/ && \
        cd /root/sources/gvm-libs-"$gvm_libs_version"/build && \
        cmake .. && \
        make install && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build gvm-tools
RUN python3 -m pip install gvm-tools

RUN ldconfig

EXPOSE 9392/tcp
