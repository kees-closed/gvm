#!/bin/bash

username="admin"
password="${password:-admin}"
ospd_socket="${ospd_socket:-/usr/local/var/run/ospd/ospd-openvas.sock}"
log_level="${log_level:-INFO}"

echo "Start databases"
service redis-server start
service postgresql start

echo "Prepare database"
su --command "createuser --echo --no-createdb --no-createrole --no-superuser gvm" postgres
su --command "createdb --echo --owner=gvm gvmd" postgres
su --command "psql --echo-all --dbname=gvmd --command='CREATE ROLE dba WITH SUPERUSER noinherit;'" postgres
su --command "psql --echo-all --dbname=gvmd --command='GRANT dba TO gvm;'" postgres

if [[ -z $initial_nvt_sync ]]; then
  echo "Start Greenbone feed sync in the background"
  /etc/cron.daily/greenbone-feed-sync &
fi

echo "Start OSP server implementation to allow GVM to remotely control OpenVAS"
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket "$ospd_socket" --socket-mode 766 --log-level "$log_level"

echo "Generate/import GVM certificates"
su --command "gvm-manage-certs -a" gvm

echo "Start Greenbone Vulnerability Manager (GVM)"
su --command "gvmd --migrate" gvm
su --command "gvmd --osp-vt-update=$ospd_socket --listen=0.0.0.0 --port 9390" gvm

echo "Waiting until the service is available"
until su --command "gvmd --get-users 1>/dev/null" gvm; do
  continue
done

echo "Create user $username"
if ! su --command "gvmd --create-user=$username --password=$password" gvm; then
  echo "Updating password for user $username"
  su --command "gvmd --user=$username --new-password=$password" gvm
fi

echo "Start Greenbone Security Assistant (GSA)"
gsad --drop-privileges=gvm --verbose --no-redirect --mlisten=127.0.0.1 --mport 9390 -p 9392 --listen 0.0.0.0
chown --verbose gvm: /usr/local/var/log/gvm/*

# Set GVM feed import owner
while read -r name uid; do
  if [[ "$name" == "$username" ]]; then
    echo "Setting user $name as feed import owner"
    su --command "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $uid" gvm
  fi
done < <(su --command "gvmd --verbose --get-users" gvm)

# Set OSPD scanner UNIX socket
while read -r uid host port type name; do
  if [[ "$name" == "OpenVAS Default" ]]; then
    echo "Setting UNIX socket for scanner '$name' on host $host with port $port and of type $type"
    su --command "gvmd --modify-scanner=$uid --scanner-host=$ospd_socket" gvm
    su --command "gvmd --verify-scanner=$uid" gvm
  fi
done < <(su --command "gvmd --get-scanners" gvm)

# Add remote scanner with certificate verification (for extra remote scanners)
#gvmd --create-scanner="OSP Scanner" --scanner-host=127.0.0.1 --scanner-port=1234 \
#     --scanner-type="OSP" --scanner-ca-pub=/usr/var/lib/gvm/CA/cacert.pem \
#     --scanner-key-pub=/usr/var/lib/gvm/CA/clientcert.pem \
#     --scanner-key-priv=/usr/var/lib/gvm/private/CA/clientkey.pem

echo "Starting cron to ensure continued up-to-date NVTs"
cron

echo "Start monitoring logs"
tail --follow /usr/local/var/log/gvm/*
