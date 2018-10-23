#!/bin/bash
#
# Copyright (c) 2013, Torbjörn Lönnemark <tobbez@ryara.net>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

if [[ $# -ne 1 ]] || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]
then
  echo "Usage: $0 <name>"
  echo
  echo "Creates a user and a database with the specified name, and gives the"
  echo "user full access to that database. The user is given a randomly"
  echo "generated password that is also printed to stdout."
  exit 0
fi

PASSWORD=`(tr -dc 'A-Za-z0-9' | fold -w 20 | head -n1) < /dev/urandom`

mysql -u root -p`cat /root/mysql_root_password.txt` -e "CREATE DATABASE ${1}; GRANT ALL PRIVILEGES ON ${1}.* TO '${1}'@'%' IDENTIFIED BY '${PASSWORD}';"
echo "${PASSWORD}"
