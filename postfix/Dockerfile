FROM debian:stable-slim
MAINTAINER Kees de Jong <kees.dejong+dev@neobits.nl>

ENV TZ="Europe/Amsterdam"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Update software and install Postfix
RUN apt-get update && apt-get upgrade --assume-yes && \
        apt-get install --assume-yes \
        postfix

ENTRYPOINT /entrypoint.sh
EXPOSE 25/tcp
