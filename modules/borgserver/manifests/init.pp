# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: borgserver
#
# Borg backup server
#
# === Parameters
#
# [*servers*]
#   List of servers to be allowed to log in. Format:
#     [{'fqdn': 'x.y.z', 'ssh-key': 'ecdsa-sha2-nistp256 AAAA.'}]
#

class borgserver($servers) {
  ensure_packages(['borgbackup'])

  user { 'borg':
    ensure => 'present',
    system => true,
  }

  file { 'borg.authorized':
    ensure  => present,
    content => template('borgserver/borg.authorized.erb'),
    owner   => 'borg',
    group   => 'borg',
    mode    => '0600',
    path    => '/etc/ssh/authorized_keys/borg',
  }

  file { '/home/borg':
    ensure => 'directory',
    owner  => 'borg',
    group  => 'borg',
    mode   => '0700',
  }

  file { '/home/borg/repository':
    ensure => 'directory',
    owner  => 'borg',
    group  => 'borg',
    mode   => '0700',
  }
}
