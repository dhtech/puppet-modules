#!/usr/bin/env sh

export LDAPTLS_CERT="/etc/ssl/ldap-$(hostname).crt"
export LDAPTLS_KEY="/etc/ssl/private/ldap-$(hostname).key"

ldapmodify -Q -Y EXTERNAL -H ldaps:/// >/dev/null <<EOF
dn: dc=dreamhack,dc=se
changetype: modify
replace: description
description: $(date -u '+%s')
EOF
