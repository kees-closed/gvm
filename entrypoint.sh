#!/bin/bash

echo "Start databases"
service redis-server start
service postgresql start

echo "Prepare database"
su --command "createuser --echo --no-createdb --no-createrole --no-superuser gvm" postgres
su --command "createdb --echo --owner=gvm gvmd" postgres
su --command "psql --echo-all --dbname=gvmd --command='CREATE ROLE dba WITH SUPERUSER noinherit;'" postgres
su --command "psql --echo-all --dbname=gvmd --command='GRANT dba TO gvm;'" postgres
su --command "psql --echo-all --dbname=gvmd --command='CREATE EXTENSION \"uuid-ossp\";'" postgres
su --command "psql --echo-all --dbname=gvmd --command='CREATE EXTENSION \"pgcrypto\";'" postgres

echo "Sync GVM feed"
/etc/cron.daily/gvm-sync

echo "Start GVM"
su --command "gvm-manage-certs -a" gvm
su --command "gvmd --osp-vt-update=/var/run/ospd/ospd-openvas.sock --listen=0.0.0.0 -p 9390" gvm
su --command "gvmd --create-user=admin --password=test123123" gvm
gsad --drop-privileges=gvm --verbose --no-redirect --mlisten=127.0.0.1 --mport 9390 -p 9392 --listen 0.0.0.0
chown --verbose gvm: /usr/local/var/log/gvm/*

# Set GVM feed import owner
while read -r username uid; do
  if [[ "$username" == "admin" ]]; then
    echo "Setting $username as feed import owner"
    su --command "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $uid" gvm
  fi
done < <(su --command "gvmd --get-users" gvm)

echo "Start monitoring logs"
tail -f /usr/local/var/log/gvm/*
