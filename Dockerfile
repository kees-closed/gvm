FROM debian:10
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
ENV gvm_libs_version="20.8.0"
ENV openvas_version="20.8.0"

# Build gvm-libs
RUN apt-get update && apt-get upgrade --assume-yes; \
        apt-get install --assume-yes \
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

RUN mkdir --verbose --parents /root/sources/gvm-libs-"$gvm_libs_version"/build /root/downloads; \
        wget -O /root/downloads/gvm-libs.tar.gz https://github.com/greenbone/gvm-libs/archive/v"$gvm_libs_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/gvm-libs.tar.gz --directory /root/sources/; \
        cd /root/sources/gvm-libs-"$gvm_libs_version"/build; \
        cmake ..; \
        make install

# Build openvas
RUN apt-get install --assume-yes \
        pkg-config \
        libssh-gcrypt-dev \
        libgnutls28-dev \
        libglib2.0-dev \
        libpcap-dev \
        libgpgme-dev \
        bison \
        libksba-dev \
        libsnmp-dev \
        libgcrypt20-dev \
        redis-server

RUN mkdir --verbose --parents /root/sources/openvas-"$openvas_version"/build /root/downloads; \
        wget -O /root/downloads/openvas.tar.gz https://github.com/greenbone/openvas/archive/v"$openvas_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/openvas.tar.gz --directory /root/sources/; \
        cd /root/sources/openvas-"$openvas_version"/build; \
        cmake ..; \
        make install

# Build ospd
RUN apt-get install --assume-yes \
        python3-paramiko \
        python3-lxml \
        python3-defusedxml \
        python3-pip; \
        python3 -m pip install ospd

# Build ospd-openvas
RUN apt-get install --assume-yes \
        python3-redis \
        python3-psutil \
        python3-packaging
