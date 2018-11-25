# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: etcd::install
#
# Used for installing/setting up all dependencies for etcd.
#
# === Parameters
#

class etcd::install {
  # 
  # Install basic packages
  ensure_packages([
      'curl',
  ])

  file { '/etc/etcd':
    ensure => directory,
  }
  
  exec { 'etcd-download':
    command     => '/usr/bin/curl https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['etcd-unpack'],
  }

  exec { 'etcd-unpack':
    command     => '/usr/bin/tar -xvf etcd-v3.3.10-linux-amd64.tar.gz',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => File['etcd-install'],
  }

  file { 'etcd-install':
    path     => '/usr/bin/etcd',
    source   => './etcd-v3.3.10-linux-amd64/etcd',
    ensure   => file,
    notify      => Exec['etcd-clean'],
  }

  exec { 'etcd-clean':
    command     => '/usr/bin/rm -rf ./etcd-v3.3.10-linux-amd64',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
  }
}
