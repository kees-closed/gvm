#!/bin/bash

username=${username:-admin}
password=${password:-admin}

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

echo "Start OSPD"
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /usr/local/var/run/ospd/ospd-openvas.sock --socket-mode 666

echo "Generate/import GVM certificates"
su --command "gvm-manage-certs -a" gvm

echo "Start Greenbone Vulnerability Manager (GVM)"
su --command "gvmd --osp-vt-update=/usr/local/var/run/ospd/ospd-openvas.sock --listen=0.0.0.0 -p 9390" gvm

echo "Waiting until the service is available"
until su --command "gvmd --get-users 1>/dev/null" gvm; do
  continue
done

echo "Create user"
su --command "gvmd --create-user=$username --password=$password" gvm

echo "Start Greenbone Security Assistant"
gsad --drop-privileges=gvm --verbose --no-redirect --mlisten=127.0.0.1 --mport 9390 -p 9392 --listen 0.0.0.0
chown --verbose gvm: /usr/local/var/log/gvm/*

# Set GVM feed import owner
while read -r name uid; do
  if [[ "$name" == "$username" ]]; then
    echo "Setting $name as feed import owner"
    su --command "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $uid" gvm
  fi
done < <(su --command "gvmd --verbose --get-users" gvm)

# Set OSPD scanner UNIX socket
while read -r uid host port type name; do
  if [[ "$name" == "OpenVAS Default" ]]; then
    echo "Setting UNIX socket for scanner $name on $host ($port)"
    su --command "gvmd --modify-scanner=$uid --scanner-host=/usr/local/var/run/ospd/ospd-openvas.sock" gvm
    su --command "gvmd --verify-scanner=$uid" gvm
  fi
done < <(su --command "gvmd --get-scanners" gvm)

# Add remote scanner with certificate verification (for extra remote scanners)
#gvmd --create-scanner="OSP Scanner" --scanner-host=127.0.0.1 --scanner-port=1234 \
#     --scanner-type="OSP" --scanner-ca-pub=/usr/var/lib/gvm/CA/cacert.pem \
#     --scanner-key-pub=/usr/var/lib/gvm/CA/clientcert.pem \
#     --scanner-key-priv=/usr/var/lib/gvm/private/CA/clientkey.pem

echo "Start monitoring logs"
tail -f /usr/local/var/log/gvm/*
