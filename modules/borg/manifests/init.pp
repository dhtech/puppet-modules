# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: borg
#
# Borg backup client
#
# === Parameters
#
# No parameters

class borg {
  ensure_packages(['borgbackup'])

  $machine = vault("login:${::fqdn}")

  file { 'borg.exclude':
    ensure  => present,
    content => template('borg/borg.exclude.erb'),
    mode    => '0644',
    path    => '/etc/borg.exclude',
  }

  file { 'borg.sh':
    ensure  => present,
    content => template('borg/borg.sh.erb'),
    mode    => '0755',
    path    => '/usr/local/bin/borg.sh',
  }

  file { 'borg.passphrase':
    ensure  => present,
    content => $machine['borg_passphrase'],
    mode    => '0400',
    path    => '/etc/borg.passphrase',
  }

  cron { 'borg-cron':
    command => '/usr/local/bin/borg.sh',
    minute  => '19',
    hour    => '*/12',
  }
}
