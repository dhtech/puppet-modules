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

  file { '/etc/etcd/install/':
    ensure => directory,
  }

  exec { 'etcd-download':
    command   => '/usr/bin/curl -L -o /etc/etcd/install/etcd-v3.3.10-linux-amd64.tar.gz https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz',
    creates   => '/etc/etcd/install/etcd-v3.3.10-linux-amd64.tar.gz',
    logoutput => 'on_failure',
    try_sleep => 1,
    notify    => Exec['etcd-unpack'],
  }

  exec { 'etcd-unpack':
    command   => '/usr/bin/tar -xvf /etc/etcd/install/etcd-v3.3.10-linux-amd64.tar.gz -C /etc/etcd/install/',
    creates   => '/etc/etcd/install/etcd-v3.3.10-linux-amd64/etcd',
    logoutput => 'on_failure',
    try_sleep => 1,
    notify    => File['etcd-install'],
  }

  file { 'etcd-install':
    ensure => file,
    source => '/etc/etcd/install/etcd-v3.3.10-linux-amd64/etcd',
    path   => '/usr/bin/etcd',
    mode   => '0700',
  }
}
