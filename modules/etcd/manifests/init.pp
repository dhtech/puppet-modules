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

  file { 'etcd-trusted-ca':
    ensure  => file,
    path    => '/etc/etcd/trusted-client.crt',
    content => template('etcd/trusted-client.crt.erb'),
    require => Exec['etcd-peering-cert'],
  }

  file { 'dh-etcd-peering':
    ensure => file,
    path   => '/usr/bin/dh-etcd-peering',
    mode   => '0755',
    source => 'puppet:///modules/etcd/certs.sh',
    notify => Exec['etcd-peering-cert'],
    require => File['etcd-trusted-ca'],
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
    notify  => Exec['systemctl-reload'],
    require => Exec['etcd-peering-cert'],
  }

  exec { 'systemctl-reload':
    command     =>  '/bin/systemctl daemon-reload',
    refreshonly => true,
    notify  => Exec['systemctl-enable'],
  }

  exec { 'systemctl-enable':
    command     =>  '/bin/systemctl enable etcd',
    refreshonly => true,
    notify  => Service['etcd-server'],
  }

  service { 'etcd-server':
    ensure => 'running',
    enable => true,
  }
}
