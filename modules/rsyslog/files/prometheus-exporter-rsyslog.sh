#!/bin/bash

now=$(date +"%s")

IFS='
'
for row in $(stat --printf "%n %Y %s\n" /var/log/dh/*/*.log)
do
  filename=$(basename $(dirname $(echo $row | awk '{print $1}')))
  severity=$(basename $(echo $row | awk '{print $1}') | cut -f 1 -d '.')
  stamp=$(echo $row | awk '{print $2}')
  size=$(echo $row | awk '{print $3}')
  if ! echo "${filename}" | grep '\.' -q; then
    # TODO(bluecmd): we probably want full fqdn from servers instead
    host="$filename.event.dreamhack.se"
  else
    host="$filename"
  fi
  echo "syslog_log_bytes{host=\"$host\",severity=\"$severity\"} ${size}"
  echo "syslog_log_updated{host=\"$host\",severity=\"$severity\"} ${stamp}"
done
