#!/bin/bash

username="admin"
password="${password:-admin}"
ospd_socket="${ospd_socket:-/run/ospd/ospd.sock}"
log_level="${log_level:-INFO}"
ssl_certificate="${ssl_certificate:-/var/lib/gvm/CA/servercert.pem}"
ssl_private_key="${ssl_private_key:-/var/lib/gvm/private/CA/serverkey.pem}"
tls_ciphers="${tls_ciphers:-SECURE128:-AES-128-CBC:-CAMELLIA-128-CBC:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1}"

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

if [[ -f /var/lib/gvm/feed-update.lock ]]; then
  echo "Remove feed update lock file"
  rm --verbose /var/lib/gvm/feed-update.lock
fi
if [[ -z $initial_nvt_sync ]]; then
  echo "Start Greenbone feed sync in the background"
  /etc/cron.daily/greenbone-feed-sync &
  echo "Wait for the plugin_feed_info.inc file to be synced"
  until [[ -f /var/lib/openvas/plugins/plugin_feed_info.inc ]]; do
    file_count="/var/lib/openvas/plugins/*"
    echo "Found ${#file_count[*]} files so far"
    sleep 60
    continue
  done
  echo "Update NVT (Network Vulnerability Tests) info into redis store from NVT files"
  if ! openvas --update-vt-info; then
    echo "NVT update failed"
    exit 1
  fi
fi

echo "Start OSPD server implementation to allow GVM to remotely control OpenVAS"
mkdir --verbose "$(dirname $ospd_socket)"
chown --verbose gvm:gvm "$(dirname $ospd_socket)"
if ! ospd-openvas --log-file /var/log/gvm/ospd-openvas.log --unix-socket "$ospd_socket" --socket-mode 766 --log-level "$log_level"; then
  echo "Failed to start OSPD server"
  exit 1
fi

echo "Generate/import GVM certificates"
if ! su --command "GVM_CERTIFICATE_SECPARAM=high gvm-manage-certs -vda" gvm; then
  echo "Certificate already exists, skipping"
fi

echo "Start Greenbone Vulnerability Manager (GVM)"
if ! su --command "gvmd --verbose --migrate" gvm; then
  echo "Failed to start Greenbone Vulnerability Manager (GVM)"
  exit 1
fi
if ! su --command "gvmd --verbose --osp-vt-update=$ospd_socket --listen=0.0.0.0 --port 9390" gvm; then
  echo "Failed to start Greenbone Vulnerability Manager (GVM)"
  exit 1
fi

echo "Waiting until the service is available"
until su --command "gvmd --get-users 1>/dev/null" gvm; do
  continue
done

echo "Create user $username"
if ! su --command "gvmd --create-user=$username --password=$password" gvm; then
  echo "Updating password for user $username"
  if ! su --command "gvmd --user=$username --new-password=$password" gvm; then
    echo "Failed updating password for user $username"
    exit 1
  fi
fi

echo "Start Greenbone Security Assistant (GSA)"
if ! gsad --verbose --gnutls-priorities="$tls_ciphers" --ssl-certificate="$ssl_certificate" --ssl-private-key="$ssl_private_key" --drop-privileges=gvm --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392 --listen=0.0.0.0; then
  echo "Failed to start Greenbone Security Assistant (GSA)"
  exit 1
fi

# Set GVM feed import owner
while read -r name uid; do
  if [[ "$name" == "$username" ]]; then
    echo "Setting user $name as feed import owner"
    if ! su --command "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $uid" gvm; then
      echo "Failed setting user $name as feed import owner"
      exit 1
    fi
  fi
done < <(su --command "gvmd --verbose --get-users" gvm)

# Set OSPD scanner UNIX socket
while read -r uid host port type name; do
  if [[ "$name" == "OpenVAS Default" ]]; then
    echo "Setting UNIX socket for scanner '$name' on host $host with port $port and of type $type"
    if ! su --command "gvmd --modify-scanner=$uid --scanner-host=$ospd_socket" gvm; then
      echo "Failed setting UNIX socket for scanner '$name' on host $host with port $port and of type $type"
      exit 1
    fi
    echo "Verify scanner with UID $uid"
    if ! su --command "gvmd --verify-scanner=$uid" gvm; then
      exit 1
    fi
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
tail --follow /var/log/gvm/* /usr/local/var/log/gvm/* # <-- /usr/local might be depricated in the future
#!/bin/bash

# Postfix bit (in progress)
#echo "Verify mandatory variables"
#mydomain=""
#
#
#echo "Setting up Postfix relay"
#postconf -ev compatibility_level = 2
#postconf -ev inet_interfaces = loopback-only
#postconf -ev inet_protocols = all
#postconf -ev masquerade_domains = $mydomain
#postconf -ev mydomain = $mydomain
#postconf -ev myhostname = ws1
#postconf -ev mynetworks = localhost # should be docker network?
#postconf -ev myorigin = $mydomain
#postconf -ev relayhost = [mail.$mydomain]:submission
#postconf -ev smtp_dns_support_level = dnssec
#postconf -ev smtp_generic_maps = hash:$config_directory/smtp_generic
#postconf -ev smtp_sasl_auth_enable = yes
#postconf -ev smtp_sasl_password_maps = hash:$config_directory/sasl_passwd
#postconf -ev smtp_sasl_security_options = noanonymous
#postconf -ev smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt # double check
#postconf -ev smtp_tls_loglevel = 1
#postconf -ev smtp_tls_mandatory_ciphers = high
#postconf -ev smtp_tls_mandatory_protocols = >=TLSv1.3
#postconf -ev smtp_tls_protocols = >=TLSv1.3
#postconf -ev smtp_tls_security_level = dane
#postconf -ev smtp_use_tls = yes
#postconf -ev smtpd_banner = $myhostname ESMTP
