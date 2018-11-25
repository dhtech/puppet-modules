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
    command     => '/usr/bin/curl -L -o /etc/etcd/etcd-v3.3.10-linux-amd64.tar.gz https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    notify      => Exec['etcd-unpack'],
  }

  exec { 'etcd-unpack':
    command     => '/usr/bin/tar -xvf /etc/etcd/etcd-v3.3.10-linux-amd64.tar.gz',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    notify      => File['etcd-install'],
  }

  file { 'etcd-install':
    path     => '/usr/bin/etcd',
    source   => '/etc/etcd/etcd-v3.3.10-linux-amd64/etcd',
    ensure   => file,
    mode     => "0700",
    notify   => Exec['etcd-clean'],
  }

  exec { 'etcd-clean':
    command     => '/usr/bin/rm -r /etc/etcd/etcd-v3.3.10-linux-amd64.tar.gz /etc/etcd/etcd-v3.3.10-linux-amd64',
    logoutput   => 'on_failure',
    try_sleep   => 1,
  }
}
