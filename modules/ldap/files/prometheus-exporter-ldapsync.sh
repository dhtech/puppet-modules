#!/usr/bin/env sh

TEXTFILE_COLLECTOR_DIR=/var/tmp/export

SYNC_STATUS=$(ldapsearch -LLL -Q -Y EXTERNAL -H 'ldapi:///' -s base -b 'dc=dreamhack,dc=se' 'description' 'entryCSN' 'contextCSN')
LAST_SYNC_TIMESTAMP=$(echo "${SYNC_STATUS}" | grep '^description: ' | cut -d' ' -f2 | tr -d '[:blank:]')

cat <<EOF >"${TEXTFILE_COLLECTOR_DIR}/ldap_sync.prom.$$"
ldap_last_sync_timestamp ${LAST_SYNC_TIMESTAMP}
EOF

mv "${TEXTFILE_COLLECTOR_DIR}/ldap_sync.prom.$$" "${TEXTFILE_COLLECTOR_DIR}/ldap_sync.prom"
