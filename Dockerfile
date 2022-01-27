FROM debian:stable-slim
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

ENV gvm_libs_version="21.4.3"
ENV openvas_scanner_version="21.4.3"
ENV ospd_openvas_version="21.4.3"
ENV gvmd_version="21.4.4"
ENV gsa_version="21.4.3"

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
        libhiredis-dev \
        libxml2-dev \
        libpcap-dev \
        libnet1-dev \
        libcgreen1-dev

RUN mkdir --verbose --parents /root/sources/gvm-libs-"$gvm_libs_version"/build /root/downloads && \
        wget --output-document /root/downloads/gvm-libs.tar.gz https://github.com/greenbone/gvm-libs/archive/v"$gvm_libs_version".tar.gz && \
        wget --output-document /root/downloads/gvm-libs.tar.gz.asc https://github.com/greenbone/gvm-libs/releases/download/v"$gvm_libs_version"/gvm-libs-"$gvm_libs_version".tar.gz.asc && \
        if ! gpg --verify /root/downloads/gvm-libs.tar.gz.asc ; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gvm-libs.tar.gz --directory /root/sources/ && \
        cd /root/sources/gvm-libs-"$gvm_libs_version"/build && \
        cmake -DBUILD_TESTS=ON .. && \
        make tests && \
        make install && \
        cmake -DBUILD_TESTS=ON .. && \
        make tests && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build openvas-scanner
RUN apt-get install --assume-yes \
        gcc \
        pkg-config \
        libssh-gcrypt-dev \
        libgnutls28-dev \
        libglib2.0-dev \
        libjson-glib-dev \
        libpcap-dev \
        libgpgme-dev \
        bison \
        libksba-dev \
        libsnmp-dev \
        libgcrypt20-dev \
        redis-server \
        rsync \
        nmap

RUN mkdir --verbose --parents /root/sources/openvas-scanner-"$openvas_scanner_version"/build /root/downloads && \
        wget --output-document /root/downloads/openvas-scanner.tar.gz https://github.com/greenbone/openvas-scanner/archive/v"$openvas_scanner_version".tar.gz && \
        wget --output-document /root/downloads/openvas-scanner.tar.gz.asc https://github.com/greenbone/openvas-scanner/releases/download/v"$openvas_scanner_version"/openvas-scanner-"$openvas_scanner_version".tar.gz.asc && \
        if ! gpg --verify /root/downloads/openvas-scanner.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/openvas-scanner.tar.gz --directory /root/sources/ && \
        cd /root/sources/openvas-scanner-"$openvas_scanner_version"/build && \
        cmake -DBUILD_TESTS=ON .. && \
        make tests && \
        make install && \
        sed --in-place "s/redis-openvas/redis/g" /root/sources/openvas-scanner-"$openvas_scanner_version"/config/redis-openvas.conf && \
        cp --verbose /root/sources/openvas-scanner-"$openvas_scanner_version"/config/redis-openvas.conf /etc/redis/redis.conf && \
        chown --verbose redis:redis /etc/redis/redis.conf && \
        chmod --verbose 640 /etc/redis/redis.conf && \
        echo "db_address = /run/redis/redis.sock" >> /etc/openvas/openvas.conf && \
        sed --in-place "s,OPENVAS_FEED_LOCK_PATH=\"/var/run/feed-update.lock\",OPENVAS_FEED_LOCK_PATH=\"/tmp/feed-update.lock\",g" /usr/local/bin/greenbone-nvt-sync && \
        chown --verbose --recursive gvm:gvm /usr/local/share/openvas && \
        chown --verbose --recursive gvm:gvm /var/lib/openvas && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build ospd (ospd got merged into ospd-openvas, but maybe in version 21.4.4?)
#RUN apt-get install --assume-yes \
#        python3-paramiko \
#        python3-lxml \
#        python3-defusedxml \
#        python3-pip && \
#        python3 -m pip install ospd

# Build ospd-openvas
RUN apt-get install --assume-yes \
        python3-defusedxml \
        python3-lxml \
        python3-packaging \
        python3-paho-mqtt \
        python3-psutil \
        python3-gnupg \
        python3-pip

RUN mkdir --verbose --parents /root/sources/ospd-openvas-"$ospd_openvas_version" /root/downloads && \
        wget --output-document /root/downloads/ospd-openvas.tar.gz https://github.com/greenbone/ospd-openvas/archive/v"$ospd_openvas_version".tar.gz && \
        wget --output-document /root/downloads/ospd-openvas.tar.gz.asc https://github.com/greenbone/ospd-openvas/releases/download/v"$ospd_openvas_version"/ospd-openvas-"$ospd_openvas_version".tar.gz.asc && \
        if ! gpg --verify /root/downloads/ospd-openvas.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/ospd-openvas.tar.gz --directory /root/sources/ && \
        cd /root/sources/ospd-openvas-"$ospd_openvas_version" && \
        python3 setup.py install && \
        cp --verbose /root/sources/ospd-openvas-"$ospd_openvas_version"/config/ospd-openvas.conf /etc/openvas/ospd.conf && \
        sed --in-place "s,<install-prefix>,/usr/local,g" /etc/openvas/ospd.conf && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build gvmd
RUN apt-get install --assume-yes \
        gcc \
        cmake \
        libglib2.0-dev \
        libgnutls28-dev \
        libpq-dev \
        postgresql-server-dev-13 \
        pkg-config \
        libical-dev \
        xsltproc \
        gnutls-bin \
        postgresql \
        postgresql-contrib \
        postgresql-server-dev-all \
        gnupg \
        haveged \
        xml-twig-tools

RUN mkdir --verbose --parents /root/sources/gvmd-"$gvmd_version"/build /root/downloads && \
        wget --output-document /root/downloads/gvmd.tar.gz https://github.com/greenbone/gvmd/archive/v"$gvmd_version".tar.gz && \
        wget --output-document /root/downloads/gvmd.tar.gz.asc https://github.com/greenbone/gvmd/releases/download/v"$gvmd_version"/gvmd-"$gvmd_version".tar.gz.asc && \
        if ! gpg --verify /root/downloads/gvmd.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gvmd.tar.gz --directory /root/sources/ && \
        cd /root/sources/gvmd-"$gvmd_version"/build && \
        cmake -DBUILD_TESTS=ON .. && \
        make tests && \
        make install && \
        chown --verbose gvm:gvm /run/gvm && \
        chown --verbose --recursive gvm:gvm /var/lib/gvm && \
        chown --verbose --recursive gvm:gvm /var/log/gvm && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build GSA
RUN apt-get install --assume-yes \
        libmicrohttpd-dev \
        libxml2-dev \
        git \
        nodejs \
        yarnpkg

RUN mkdir --verbose --parents /root/sources/gsa-"$gsa_version"/build /root/downloads && \
        wget --output-document /root/downloads/gsa.tar.gz https://github.com/greenbone/gsa/archive/v"$gsa_version".tar.gz && \
        wget --output-document /root/downloads/gsa.tar.gz.asc https://github.com/greenbone/gsa/releases/download/v"$gsa_version"/gsa-"$gsa_version".tar.gz.asc && \
        if ! gpg --verify /root/downloads/gsa.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gsa.tar.gz --directory /root/sources/ && \
        cd /root/sources/gsa-"$gsa_version"/build && \
        cmake .. && \
        make install && \
        rm --recursive --force --verbose /root/sources /root/downloads

# Build gvm-tools
RUN python3 -m pip install gvm-tools

RUN ldconfig

COPY entrypoint.sh /entrypoint.sh
COPY greenbone-feed-sync /etc/cron.daily/greenbone-feed-sync
ENTRYPOINT /entrypoint.sh

EXPOSE 9392/tcp
