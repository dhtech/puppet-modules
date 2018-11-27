#!/bin/bash

set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

VAULT_ADDR="https://vault.tech.dreamhack.se:1443"

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


# Upload public cert for apiserver to Vault
echo "-H \"X-Vault-Token:$TOKEN\"" | curl -X POST - -d "{\"fullchain\":\"$(cat /etc/ssl/certs/server-fullchain.crt)\"}" $VAULT_ADDR/v1/<%= @current_event %>-services/kube-<%= @variant %>:apicert

