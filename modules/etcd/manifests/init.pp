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
  
  file { 'etcd-unit':
    path    => '/etc/systemd/system/etcd.service',
    ensure  => file,
    content => template('etcd/etcd.service.erb'),
    notify  => Exec['daemon-reload'],
  }

  exec { 'daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    notify     => Exec['daemon-enable'],
  }

  exec { 'daemon-enable':
    command     => '/bin/systemctl enable etcd',
    notify     => Exec['daemon-restart'],
  }

  exec { 'daemon-restart':
    command     => '/bin/systemctl restart etcd',
  }
}
