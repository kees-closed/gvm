FROM debian:stable-slim
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

ENV gvm_libs_version="21.4.4"
ENV openvas_scanner_version="21.4.4"
ENV ospd_openvas_version="21.4.4"
ENV gvmd_version="21.4.5"
ENV gsa_version="21.4.4"
ENV gsad_version="21.4.4"
ENV nodejs_keyring=/usr/share/keyrings/nodesource.gpg
ENV greenbone_fingerprint="8AE4BE429B60A59B311C2E739823FAA60ED1E580"
ENV install_prefix="/usr/local"

RUN useradd --system --user-group gvm

# Install dependencies to include Greenbone GPG key
RUN apt-get update && apt-get install --assume-yes \
        build-essential \
        curl \
        cmake \
        pkg-config \
        python3 \
        python3-pip \
        gnupg && \
        curl https://www.greenbone.net/GBCommunitySigningKey.asc | gpg --import - && \
        echo -e "5\ny\n" | gpg --no-tty --command-fd 0 --expert --edit-key "$greenbone_fingerprint" trust

# Update software
RUN apt-get update && apt-get upgrade --assume-yes

# Install Postfix
RUN apt-get install --assume-yes \
        postfix
        
# Build gvm-libs
RUN apt-get install --assume-yes \
        libglib2.0-dev \
        libgpgme-dev \
        libgnutls28-dev \
        uuid-dev \
        libssh-gcrypt-dev \
        libhiredis-dev \
        libxml2-dev \
        libpcap-dev \
        libnet1-dev

RUN apt-get install --assume-yes \
        libcgreen1-dev

RUN mkdir --verbose --parents /root/sources/gvm-libs-"$gvm_libs_version"/build /root/downloads && \
        curl --location https://github.com/greenbone/gvm-libs/archive/v"$gvm_libs_version".tar.gz --output /root/downloads/gvm-libs.tar.gz && \
        curl --location https://github.com/greenbone/gvm-libs/releases/download/v"$gvm_libs_version"/gvm-libs-"$gvm_libs_version".tar.gz.asc --output /root/downloads/gvm-libs.tar.gz.asc && \
        if ! gpg --verify /root/downloads/gvm-libs.tar.gz.asc ; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gvm-libs.tar.gz --directory /root/sources/ && \
        cd /root/sources/gvm-libs-"$gvm_libs_version"/build && \
        cmake -DBUILD_TESTS=ON \
                -DCMAKE_INSTALL_PREFIX="$install_prefix" \
                -DCMAKE_BUILD_TYPE=Release \
                -DSYSCONFDIR=/etc \
                -DLOCALSTATEDIR=/var \
                .. && \
        make tests && \
        make install && \
        cmake -DBUILD_TESTS=ON .. && \
        make tests && \
        rm --verbose --recursive --force /root/sources /root/downloads

# Build gvmd
RUN apt-get install --assume-yes \
        libglib2.0-dev \
        libgnutls28-dev \
        libpq-dev \
        postgresql-server-dev-13 \
        libical-dev \
        xsltproc \
        rsync

RUN apt-get install --assume-yes --no-install-recommends \
        postgresql

RUN apt-get install --assume-yes --no-install-recommends \
        texlive-latex-extra \
        texlive-fonts-recommended \
        xmlstarlet \
        zip \
        rpm \
        fakeroot \
        dpkg \
        nsis \
        gnupg \
        gpgsm \
        wget \
        sshpass \
        openssh-client \
        socat \
        snmp \
        python3 \
        smbclient \
        python3-lxml \
        gnutls-bin \
        xml-twig-tools

RUN mkdir --verbose --parents /root/sources/gvmd-"$gvmd_version"/build /root/downloads && \
        curl --location https://github.com/greenbone/gvmd/archive/v"$gvmd_version".tar.gz --output /root/downloads/gvmd.tar.gz && \
        curl --location https://github.com/greenbone/gvmd/releases/download/v"$gvmd_version"/gvmd-"$gvmd_version".tar.gz.asc --output /root/downloads/gvmd.tar.gz.asc && \
        if ! gpg --verify /root/downloads/gvmd.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gvmd.tar.gz --directory /root/sources/ && \
        cd /root/sources/gvmd-"$gvmd_version"/build && \
        cmake -DBUILD_TESTS=ON \
                -DCMAKE_INSTALL_PREFIX="$install_prefix" \
                -DCMAKE_BUILD_TYPE=Release \
                -DLOCALSTATEDIR=/var \
                -DSYSCONFDIR=/etc \
                -DGVM_DATA_DIR=/var \
                -DGVMD_RUN_DIR=/run/gvmd \
                -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
                -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
                -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
                -DDEFAULT_CONFIG_DIR=/etc/default \
                -DLOGROTATE_DIR=/etc/logrotate.d \
                .. && \
        make tests && \
        make install && \
        rm --verbose --recursive --force /root/sources /root/downloads

# Build gsa
RUN apt-get install --assume-yes \
        nodejs \
        yarnpkg

RUN mkdir --verbose --parents /root/sources/gsa-"$gsa_version" /root/downloads && \
        curl --location https://github.com/greenbone/gsa/archive/v"$gsa_version".tar.gz --output /root/downloads/gsa.tar.gz && \
        curl --location https://github.com/greenbone/gsa/releases/download/v"$gsa_version"/gsa-"$gsa_version".tar.gz.asc --output /root/downloads/gsa.tar.gz.asc && \
        if ! gpg --verify /root/downloads/gsa.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gsa.tar.gz --directory /root/sources/ && \
        cd /root/sources/gsa-"$gsa_version" && \
        yarnpkg && \
        yarnpkg build && \
        yarnpkg install && \
        mkdir --verbose --parents "$install_prefix"/share/gvm/gsad/web && \
        cp --verbose --recursive build/* "$install_prefix"/share/gvm/gsad/web/ && \
        rm --verbose --recursive --force /root/sources /root/downloads

# Build gsad
RUN apt-get install --assume-yes \
        libmicrohttpd-dev \
        libxml2-dev \
        libglib2.0-dev \
        libgnutls28-dev

RUN mkdir --verbose --parents /root/sources/gsad-"$gsad_version"/build /root/downloads && \
        curl --location https://github.com/greenbone/gsad/archive/v"$gsad_version".tar.gz --output /root/downloads/gsad.tar.gz && \
        curl --location https://github.com/greenbone/gsad/releases/download/v"$gsad_version"/gsad-"$gsad_version".tar.gz.asc --output /root/downloads/gsad.tar.gz.asc && \
        if ! gpg --verify /root/downloads/gsad.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/gsad.tar.gz --directory /root/sources/ && \
        cd /root/sources/gsad-"$gsad_version"/build && \
        cmake \
                -DCMAKE_INSTALL_PREFIX="$install_prefix" \
                -DCMAKE_BUILD_TYPE=Release \
                -DSYSCONFDIR=/etc \
                -DLOCALSTATEDIR=/var \
                -DGVMD_RUN_DIR=/run/gvmd \
                -DGSAD_RUN_DIR=/run/gsad \
                -DLOGROTATE_DIR=/etc/logrotate.d \
                .. && \
        make install && \
        rm --verbose --recursive --force /root/sources /root/downloads

# Build openvas-scanner
RUN apt-get install --assume-yes \
        bison \
        libglib2.0-dev \
        libgnutls28-dev \
        libgcrypt20-dev \
        libpcap-dev \
        libgpgme-dev \
        libksba-dev \
        rsync \
        nmap

RUN apt-get install --assume-yes \
        redis-server

RUN mkdir --verbose --parents /root/sources/openvas-scanner-"$openvas_scanner_version"/build /root/downloads && \
        curl --location https://github.com/greenbone/openvas-scanner/archive/v"$openvas_scanner_version".tar.gz --output /root/downloads/openvas-scanner.tar.gz && \
        curl --location https://github.com/greenbone/openvas-scanner/releases/download/v"$openvas_scanner_version"/openvas-scanner-"$openvas_scanner_version".tar.gz.asc --output /root/downloads/openvas-scanner.tar.gz.asc && \
        if ! gpg --verify /root/downloads/openvas-scanner.tar.gz.asc; then \
          echo "GPG signature check failed"; \
          exit 1; \
        fi && \
        tar --verbose --extract --file /root/downloads/openvas-scanner.tar.gz --directory /root/sources/ && \
        cd /root/sources/openvas-scanner-"$openvas_scanner_version"/build && \
        cmake -DBUILD_TESTS=ON \
                -DCMAKE_INSTALL_PREFIX="$install_prefix" \
                -DCMAKE_BUILD_TYPE=Release \
                -DSYSCONFDIR=/etc \
                -DLOCALSTATEDIR=/var \
                -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
                -DOPENVAS_RUN_DIR=/run/ospd \
                .. && \
        make tests && \
        make install && \
        sed --in-place "s/redis-openvas/redis/g" /root/sources/openvas-scanner-"$openvas_scanner_version"/config/redis-openvas.conf && \
        cp --verbose /root/sources/openvas-scanner-"$openvas_scanner_version"/config/redis-openvas.conf /etc/redis/redis.conf && \
        chown --verbose redis:redis /etc/redis/redis.conf && \
        echo "db_address = /run/redis/redis.sock" >> /etc/openvas/openvas.conf && \
        rm --verbose --recursive --force /root/sources /root/downloads

# Build spd
RUN apt-get install --assume-yes \
        python3-paramiko \
        python3-lxml \
        python3-defusedxml && \
        python3 -m pip install ospd-openvas

# Build gvm-tools
RUN python3 -m pip install gvm-tools

# Adjusting permissions
RUN chown --verbose --recursive gvm:gvm /var/lib/gvm
RUN chown --verbose --recursive gvm:gvm /var/lib/openvas
RUN chown --verbose --recursive gvm:gvm /var/log/gvm
RUN chown --verbose --recursive gvm:gvm /run/gvmd
RUN chown --verbose --recursive gvm:gvm /run/gsad
#RUN chown --verbose --recursive gvm:gvm /run/ospd not created by build

RUN chmod --verbose --recursive g+srw /var/lib/gvm
RUN chmod --verbose --recursive g+srw /var/lib/openvas
RUN chmod --verbose --recursive g+srw /var/log/gvm

RUN chown gvm:gvm "$install_prefix"/sbin/gvmd
RUN chmod 6750 "$install_prefix"/sbin/gvmd

RUN chown gvm:gvm "$install_prefix"/bin/greenbone-nvt-sync
RUN chmod 740 "$install_prefix"/sbin/greenbone-feed-sync
RUN chown gvm:gvm "$install_prefix"/sbin/greenbone-*-sync
RUN chmod 740 "$install_prefix"/sbin/greenbone-*-sync

RUN ldconfig

COPY entrypoint.sh /entrypoint.sh
COPY greenbone-feed-sync /etc/cron.daily/greenbone-feed-sync
COPY logrotate-gvm /etc/logrotate.d/gvm
ENTRYPOINT /entrypoint.sh
EXPOSE 9392/tcp
