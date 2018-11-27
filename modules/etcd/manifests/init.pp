# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: etcd::init
#
# Used for initializing etcd cluster.
#
# === Parameters
#

class etcd::init($variant = 'default', $nodes = []) {

  $trustedclient =  vault("kube-${variant}:apicert")

  file { 'dh-etcd-peering':
    ensure  => file,
    path    => '/usr/bin/dh-etcd-peering',
    mode    => '0755',
    source  => 'puppet:///modules/etcd/certs.sh',
    notify  => Exec['etcd-peering-cert'],
    require => File['etcd-install'],
  }

  exec { 'etcd-peering-cert':
    command     => '/usr/bin/dh-etcd-peering',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => File['etcd-unit'],
  }

  file { 'etcd-unit':
    ensure  => file,
    path    => '/etc/systemd/system/etcd.service',
    content => template('etcd/etcd.service.erb'),
    notify  => Service['etcd-server'],
    require => Exec['etcd-peering-cert'],
  }

  service { 'etcd-server':
    ensure => 'running',
    enable => true,
  }
}
