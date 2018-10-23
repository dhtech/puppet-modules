#!/bin/bash

if [[ ! -z "${SSH_CONNECTION}" ]] && [[ "${USER}" != "root" ]]; then
  if [[ -z "${SSH_AUTH_SOCK}" ]]; then
    echo
    echo ' **** You must enable SSH agent forwarding ****'
    sleep 3
    exit 1
  fi

  if [[ -z "$(ssh-add -L)" ]]; then
    echo
    echo ' **** No keys detected in your SSH agent ****'
    sleep 3
    exit 1
  fi
fi

alias fallback-ssh='ssh -F /dev/null'
