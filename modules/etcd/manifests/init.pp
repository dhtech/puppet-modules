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

class etcd::init($variant = "default", $nodes = []) {
  # TODO (rctl): vault["etcd_${variant}:ca", {}] -> /etc/etcd/ca.crt
  #              vault["etcd_${variant}:client", {}] -> /etc/etcd/client.pem
  #              vault["etcd_${variant}:key", {}] -> /etc/etcd/key.pem
  #              vault["etcd_${variant}:peercert", {}] -> /etc/etcd/peer.pem
  #              vault["etcd_${variant}:peerkey", {}] -> /etc/etcd/key.pem
  
  file { 'dh-etcd-peering':
    ensure  => file,
    path    => '/usr/bin/dh-etcd-peering',
    mode    => '0755',
    source  => 'puppet:///modules/etcd/certs.sh',
    notify  => Exec['etcd-peering-cert'],
  }

  exec { 'etcd-peering-cert':
    command     => '/usr/bin/dh-etcd-peering',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => File['etcd-unit'],
  }

  file { 'etcd-unit':
    path    => '/etc/systemd/system/etcd.service',
    ensure  => file,
    refreshonly => true,
    content => template('etcd/etcd.service.erb'),
    notify  => Service['etcd-server'],
  }

  service { 'etcd-server':
    ensure  => 'running',
    enable  => true,
  }
}
