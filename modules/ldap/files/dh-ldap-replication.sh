#!/bin/bash

if [ -z $1 ]; then
  echo "Usage: $0 master"
  exit 1
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -euo pipefail

if [ -f /etc/ldap/replication.configured ]; then
  echo "Replication already configured"
  echo "To re-configure, remove '/etc/ldap/replication.configured'"
  exit 0
fi

# TODO(bluecmd): We should use some nicer vault library here
VAULT_ADDR="https://vault.tech.dreamhack.se:1443/"

# Login with our machine account
RESPONSE=$(curl -ks \
  --cert /var/lib/puppet/ssl/certs/$(hostname -f).pem \
  --key /var/lib/puppet/ssl/private_keys/$(hostname -f).pem \
  ${VAULT_ADDR}v1/auth/cert/login -XPOST)

# Extract token
echo "Logging in to vault server $VAULT_ADDR"
TOKEN=$(echo $RESPONSE | python -c "
import sys
import json

print json.loads(sys.stdin.read())['auth']['client_token']")

MASTER=$1
CA='/etc/ssl/ldap-ca.crt'
CERTFILE="/etc/ssl/ldap-$(hostname).crt"
KEYFILE="/etc/ssl/private/ldap-$(hostname).key"

export LDAPTLS_CACERT="$CA"

# Install certificates
if [ "$(hostname -d)" == "tech.dreamhack.se" ]; then
  # Calculate the TTL to 2018-04-28 which is when the LDAP IM cert expires
  TTL="$(python -c 'import time; print int((1840492800 - time.time())/3600)')h"
else
  TTL="720h" # 30d
fi

echo "Using TTL $TTL"

if [ ! -f ${CERTFILE} ]; then
  echo "Installing certificates"
  echo "-H \"X-Vault-Token: $TOKEN\"" |
    curl --data @<(echo "{\"ttl\": \"${TTL}\", \"common_name\": \"$(hostname -f)\"}") \
      -s -X POST -K - ${VAULT_ADDR}v1/ldap-pki/issue/replication | python -c "
import sys
import json

response = sys.stdin.read()
print response
result = json.loads(response)['data']
open('${CERTFILE}', 'w').write(result['certificate'])
open('${KEYFILE}', 'w').write(result['private_key'])
open('${CA}', 'w').write(result['issuing_ca'])
"
fi

# Get the setup stuff
echo "Getting LDAP login info"
$(echo "-H \"X-Vault-Token: $TOKEN\"" | \
  curl -s -K - ${VAULT_ADDR}v1/ldap/replication | python -c "
import sys
import json

result = json.loads(sys.stdin.read())['data']
print 'export ROOTPW=' + result['rootpw']
")

groupadd ssl-cert || true
gpasswd -a openldap ssl-cert
chgrp ssl-cert $CERTFILE $KEYFILE "/etc/ssl/private/"
chmod g+x "/etc/ssl/private/"

# Read in new group membership
systemctl restart slapd

echo "Installing slapd configuration"
touch /tmp/modify_config
chmod 600 /tmp/modify_config
cat << _EOF_ > /tmp/modify_config
dn: cn=config
changetype: modify
replace: olcTLSVerifyClient
olcTLSVerifyClient: allow
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: ${CERTFILE}
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: ${KEYFILE}
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: ${CA}
-
replace: olcTLSCipherSuite
olcTLSCipherSuite: PFS:-VERS-ALL:+VERS-TLS1.2:-MAC-ALL:+AEAD
_EOF_
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/modify_config
shred -zu /tmp/modify_config

# Copy schemas
echo "Copying schemas"
ldapsearch -w $ROOTPW -x -D "cn=admin,dc=dreamhack,dc=se" -b "cn=schema,cn=config" \
  -H ldaps://$MASTER -LLL > /tmp/ldap_schema.ldif
# Schemas might already exist, so ignore exit code
ldapadd -c -Q -Y EXTERNAL -H ldapi:/// -f /tmp/ldap_schema.ldif || true
rm /tmp/ldap_schema.ldif

function copy_ldap
{
  local var=$1
  echo "Copying $var"
  # Modify
  cat << _EOF_ > /tmp/modify_client
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: $var
_EOF_

  ldapsearch -w $ROOTPW -x -D "cn=admin,dc=dreamhack,dc=se" \
    -b "olcDatabase={1}mdb,cn=config" -H ldaps://$MASTER -LLL $var \
    | sed 1d | head -n -2 >> /tmp/modify_client

  ldapmodify -c -Q -Y EXTERNAL -H ldapi:/// -f /tmp/modify_client
  rm /tmp/modify_client
}

copy_ldap olcAccess
copy_ldap olcDbIndex

echo "Installing replication configuration"
touch /tmp/modify_config
chmod 600 /tmp/modify_config
cat << _EOF_ > /tmp/modify_config
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSyncrepl
olcSyncrepl: rid=001
  provider="ldaps://${MASTER}:636/"
  type=refreshAndPersist
  retry="5 10 60 +"
  searchbase="dc=dreamhack,dc=se"
  bindmethod=sasl
  saslmech=EXTERNAL
  tls_cacert=${CA}
  tls_cert=${CERTFILE}
  tls_key=${KEYFILE}
-
replace: olcUpdateRef
olcUpdateRef: ldaps://${MASTER}
_EOF_
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/modify_config
shred -zu /tmp/modify_config

# Regenerate index
echo "Regenerating index"
service slapd stop
su openldap -s /usr/sbin/slapindex
service slapd start

echo "Done"
touch /etc/ldap/replication.configured
