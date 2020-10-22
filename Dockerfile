FROM debian:10
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

ENV gvm_libs_version="20.8.0"
ENV openvas_version="20.8.0"
ENV ospd_openvas_version="20.8.0"
ENV gvmd_version="20.8.0"
ENV gsa_version="20.8.0"

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
        wget --output-document /root/downloads/gvm-libs.tar.gz https://github.com/greenbone/gvm-libs/archive/v"$gvm_libs_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/gvm-libs.tar.gz --directory /root/sources/; \
        cd /root/sources/gvm-libs-"$gvm_libs_version"/build; \
        cmake ..; \
        make install; \
        rm --recursive --force --verbose /root/sources /root/downloads

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
        redis-server \
        rsync

RUN mkdir --verbose --parents /root/sources/openvas-"$openvas_version"/build /root/downloads; \
        wget --output-document /root/downloads/openvas.tar.gz https://github.com/greenbone/openvas/archive/v"$openvas_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/openvas.tar.gz --directory /root/sources/; \
        cd /root/sources/openvas-"$openvas_version"/build; \
        cmake ..; \
        make install; \
        sed --in-place "s/redis-openvas/redis/g" /root/sources/openvas-"$openvas_version"/config/redis-openvas.conf; \
        cp --verbose /root/sources/openvas-"$openvas_version"/config/redis-openvas.conf /etc/redis/; \
        chown --verbose redis:redis /etc/redis/redis.conf; \
        chmod --verbose 640 /etc/redis/redis.conf; \
        echo "db_address = /run/redis/redis-server.sock" > /usr/local/etc/openvas/openvas.conf; \
        rm --recursive --force --verbose /root/sources /root/downloads

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

RUN mkdir --verbose --parents /root/sources/ospd-openvas-"$ospd_openvas_version" /root/downloads; \
        wget --output-document /root/downloads/ospd-openvas.tar.gz https://github.com/greenbone/ospd-openvas/archive/v"$ospd_openvas_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/ospd-openvas.tar.gz --directory /root/sources/; \
        cd /root/sources/ospd-openvas-"$ospd_openvas_version"/build; \
        python3 setup.py install; \
        sed --in-place "s,<install-prefix>,/usr/local,g" /root/sources/ospd-openvas-"$ospd_openvas_version"/config/ospd.conf; \
        cp --verbose /root/sources/ospd-openvas-"$ospd_openvas_version"/config/ospd.conf /usr/local/etc/openvas/; \
        rm --recursive --force --verbose /root/sources /root/downloads

RUN apt-get install --assume-yes \
        python3-paramiko \
        gcc \
        cmake \
        libglib2.0-dev \
        libgnutls28-dev \
        libpq-dev \
        postgresql-server-dev-11 \
        pkg-config \
        libical-dev \
        xsltproc \
        gnutls-bin

RUN mkdir --verbose --parents /root/sources/gvmd-"$gvmd_version"/build /root/downloads; \
        wget --output-document /root/downloads/gvmd.tar.gz https://github.com/greenbone/gvmd/archive/v"$gvmd_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/gvmd.tar.gz --directory /root/sources/; \
        cd /root/sources/gvmd-"$gvmd_version"/build; \
        cmake ..; \
        make install; \
        rm --recursive --force --verbose /root/sources /root/downloads

RUN apt-get install --assume-yes \
        libmicrohttpd-dev \
        libxml2-dev \
        git \
        nodejs \
        yarnpkg

RUN mkdir --verbose --parents /root/sources/gsa-"$gsa_version"/build /root/downloads; \
        wget --output-document /root/downloads/gsa.tar.gz https://github.com/greenbone/gsa/archive/v"$gvmd_version".tar.gz; \
        tar --verbose --extract --file /root/downloads/gsa.tar.gz --directory /root/sources/; \
        cd /root/sources/gsa-"$gvmd_version"/build; \
        cmake ..; \
        make install; \
        rm --recursive --force --verbose /root/sources /root/downloads

RUN ldconfig

RUN useradd --create-home --shell /bin/bash greenbone
RUN useradd --system --no-create-home --shell /sbin/nologin gvm

EXPOSE 443 9390 9391
#USER greenbone
