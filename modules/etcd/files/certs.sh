#!/bin/bash

set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

VAULT_ADDR="https://vault.tech.dreamhack.se:1443/"

# Login with our machine account
RESPONSE=$(curl -ks \
  -H "Content-Type: application/json" \
  --data @<(echo '{"name":"puppet-etcd"}') \
  --cacert /etc/ssl/certs/ca-certificates.crt \
  --cert /var/lib/puppet/ssl/certs/$(hostname -f).pem \
  --key /var/lib/puppet/ssl/private_keys/$(hostname -f).pem \
  ${VAULT_ADDR}v1/auth/cert/login -XPOST)

# Extract token
echo "Logging in to vault server $VAULT_ADDR"
TOKEN=$(echo $RESPONSE | python -c "
import sys
import json

print json.loads(sys.stdin.read())['auth']['client_token']")

CA='/etc/ssl/etcd-ca.crt'
CERTFILE="/etc/ssl/etcd-$(hostname).crt"
KEYFILE="/etc/ssl/private/etcd-$(hostname).key"

# Install certificates
if [ "$(hostname -d)" == "tech.dreamhack.se" ]; then
  TTL="42720h" # 5y
else
  TTL="720h" # 30d
fi

echo "Using TTL $TTL"

if [ ! -f ${CERTFILE} ]; then
  echo "Installing missing certificates"
  echo "-H \"X-Vault-Token: $TOKEN\"" |
    curl --data @<(echo "{\"ttl\": \"${TTL}\", \"common_name\": \"$(hostname -f)\"}") \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      -s -X POST -K - ${VAULT_ADDR}v1/etcd-pki/issue/peering | python -c "
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

# Fullchain
cat $CERTFILE > /etc/ssl/etcd-fullchain.crt
echo "" >> /etc/ssl/etcd-fullchain.crt
cat $CA >> /etc/ssl/etcd-fullchain.crt

# Trusted store
cat $CA > /etc/etcd/ca.pem
echo "" >> /etc/etcd/ca.pem
cat /var/lib/puppet/ssl/certs/ca.pem >> /etc/etcd/ca.pem