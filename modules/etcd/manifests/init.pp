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

  $trustedclient =  base64('decode', vault("kube-${variant}:apicert")['certificate'])

  file { 'etcd-trusted-ca':
    ensure  => file,
    path    => '/etc/etcd/trusted-client.crt',
    content => template('etcd/trusted-client.crt.erb'),
    require => File['etcd-install'],
    notify  => Exec['etcd-restart'],
  }

  file { 'dh-etcd-peering':
    ensure  => file,
    path    => '/usr/bin/dh-etcd-peering',
    mode    => '0755',
    source  => 'puppet:///modules/etcd/certs.sh',
    notify  => Exec['etcd-peering-cert'],
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
    notify  => Exec['etcd-systemctl-reload'],
    require => Exec['etcd-peering-cert'],
  }

  exec { 'etcd-systemctl-reload':
    command     =>  '/bin/systemctl daemon-reload',
    refreshonly => true,
    notify      => Exec['etcd-systemctl-enable'],
  }

  exec { 'etcd-systemctl-enable':
    command     =>  '/bin/systemctl enable etcd',
    refreshonly => true,
  }

  exec { 'etcd-restart':
    command     =>  '/bin/systemctl restart etcd',
    refreshonly => true,
  }

  service { 'etcd':
    ensure  => 'running',
    enable  => true,
    require => Exec['etcd-systemctl-enable'],
  }
}
