#!/bin/bash
# AUTOGENERATED BY PUPPET
# All manual changes will be overwritten

# Called by sshd to figure out what users are allowed to act as what users.
# The only argument is the user that is trying to log in that we're
# figuring out.

if [ "$1" == "dhtech" ]; then
  grep -vE '^#' /etc/panic.users | grep -vE '^$'
else
  echo $1
fi
