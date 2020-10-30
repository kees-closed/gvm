#!/bin/bash

service redis-server start
service postgresql start

su -c "createuser --echo --no-createdb --no-createrole --no-superuser gvm" postgres
su -c "createdb --echo --owner=gvm gvmd" postgres
su -c "psql --echo-all --dbname=gvmd --command='CREATE ROLE dba WITH SUPERUSER noinherit;'" postgres
su -c "psql --echo-all --dbname=gvmd --command='GRANT dba TO gvm;'" postgres
su -c "psql --echo-all --dbname=gvmd --command='CREATE EXTENSION \"uuid-ossp\";'" postgres
su -c "psql --echo-all --dbname=gvmd --command='CREATE EXTENSION \"pgcrypto\";'" postgres

su -c "gvm-manage-certs -a" gvm
su -c "gvmd --osp-vt-update=/var/run/ospd/ospd-openvas.sock --listen=0.0.0.0 -p 9390" gvm
gsad --drop-privileges=gvm --verbose --no-redirect --mlisten=127.0.0.1 --mport 9390 -p 9392 --listen 0.0.0.0
su -c "greenbone-nvt-sync" greenbone-sync
su -c "greenbone-feed-sync --type CERT" greenbone-sync
su -c "greenbone-feed-sync --type SCAP" greenbone-sync
su -c "greenbone-feed-sync --type GVMD_DATA" greenbone-sync
openvas -u
