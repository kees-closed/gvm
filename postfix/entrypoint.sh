#!/bin/bash

echo "Verify mandatory variables"
mydomain=""


echo "Setting up Postfix relay"
postconf -ev compatibility_level = 2
postconf -ev inet_interfaces = loopback-only
postconf -ev inet_protocols = all
postconf -ev masquerade_domains = $mydomain
postconf -ev mydomain = $mydomain
postconf -ev myhostname = ws1
postconf -ev mynetworks = localhost # should be docker network?
postconf -ev myorigin = $mydomain
postconf -ev relayhost = [mail.$mydomain]:submission
postconf -ev smtp_dns_support_level = dnssec
postconf -ev smtp_generic_maps = hash:$config_directory/smtp_generic
postconf -ev smtp_sasl_auth_enable = yes
postconf -ev smtp_sasl_password_maps = hash:$config_directory/sasl_passwd
postconf -ev smtp_sasl_security_options = noanonymous
postconf -ev smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt # double check
postconf -ev smtp_tls_loglevel = 1
postconf -ev smtp_tls_mandatory_ciphers = high
postconf -ev smtp_tls_mandatory_protocols = >=TLSv1.3
postconf -ev smtp_tls_protocols = >=TLSv1.3
postconf -ev smtp_tls_security_level = dane
postconf -ev smtp_use_tls = yes
postconf -ev smtpd_banner = $myhostname ESMTP
